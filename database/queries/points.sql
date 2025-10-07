-- Points and Rewards Economy Queries

-- name: GetUserPoints :one
SELECT * FROM user_points WHERE user_id = $1;

-- name: CreatePointsTransaction :one
INSERT INTO points_transactions (
    user_id, change, type, reason, description, reference_id, reference_type, admin_id
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
) RETURNING *;

-- name: CreditPoints :exec
SELECT * FROM create_points_transaction($1, $2, $3, $4, $5, $6);

-- name: DebitPoints :exec
SELECT * FROM create_points_transaction($1, $2 * -1, 'debit', $3, $4, $5, NULL);

-- name: GetPointsBalance :one
SELECT COALESCE(points_balance, 0) as points_balance 
FROM user_points 
WHERE user_id = $1;

-- name: CheckSufficientPoints :one
SELECT (COALESCE(points_balance, 0) >= $2) as has_sufficient_points
FROM user_points 
WHERE user_id = $1;

-- name: GetPointsTransactionHistory :many
SELECT 
    pt.*,
    CASE 
        WHEN pt.admin_id IS NOT NULL THEN 
            u.first_name || ' ' || u.last_name
        ELSE NULL
    END as admin_name
FROM points_transactions pt
LEFT JOIN users u ON pt.admin_id = u.id
WHERE pt.user_id = $1
ORDER BY pt.created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetRecentPointsActivity :many
SELECT 
    pt.change, pt.type, pt.reason, pt.description, pt.created_at,
    CASE pt.reference_type
        WHEN 'job' THEN (SELECT title FROM jobs WHERE id = pt.reference_id::uuid)
        WHEN 'application' THEN (SELECT j.title FROM job_applications ja JOIN jobs j ON ja.job_id = j.id WHERE ja.id = pt.reference_id::uuid)
        ELSE NULL
    END as reference_title
FROM points_transactions pt
WHERE pt.user_id = $1
ORDER BY pt.created_at DESC
LIMIT $2;

-- Premium Filters

-- name: ListPremiumFilters :many
SELECT * FROM premium_filters 
WHERE is_active = true
ORDER BY category, name;

-- name: GetPremiumFilter :one
SELECT * FROM premium_filters WHERE id = $1 AND is_active = true;

-- name: GetPremiumFilterByName :one
SELECT * FROM premium_filters WHERE name = $1 AND is_active = true;

-- name: CreatePremiumFilter :one
INSERT INTO premium_filters (
    name, category, description, points_cost, is_premium, daily_limit, monthly_limit, filter_config
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
) RETURNING *;

-- name: UpdatePremiumFilter :exec
UPDATE premium_filters SET
    description = COALESCE($2, description),
    points_cost = COALESCE($3, points_cost),
    is_active = COALESCE($4, is_active),
    is_premium = COALESCE($5, is_premium),
    daily_limit = COALESCE($6, daily_limit),
    monthly_limit = COALESCE($7, monthly_limit),
    filter_config = COALESCE($8, filter_config),
    updated_at = NOW()
WHERE id = $1;

-- name: GetFilterUsageToday :one
SELECT COUNT(*) as usage_count
FROM premium_filter_usage
WHERE user_id = $1 
AND filter_id = $2 
AND used_at::date = CURRENT_DATE;

-- name: GetFilterUsageThisMonth :one
SELECT COUNT(*) as usage_count
FROM premium_filter_usage
WHERE user_id = $1 
AND filter_id = $2 
AND DATE_TRUNC('month', used_at) = DATE_TRUNC('month', CURRENT_DATE);

-- name: RecordFilterUsage :one
INSERT INTO premium_filter_usage (
    user_id, filter_id, transaction_id, filter_params, results_count
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetUserFilterUsageHistory :many
SELECT 
    pfu.used_at, pfu.filter_params, pfu.results_count,
    pf.name as filter_name, pf.points_cost,
    pt.change as points_spent
FROM premium_filter_usage pfu
JOIN premium_filters pf ON pfu.filter_id = pf.id
JOIN points_transactions pt ON pfu.transaction_id = pt.id
WHERE pfu.user_id = $1
ORDER BY pfu.used_at DESC
LIMIT $2 OFFSET $3;

-- Analytics and Reports

-- name: GetPointsStatistics :one
SELECT 
    COUNT(DISTINCT user_id) as active_users,
    SUM(CASE WHEN change > 0 THEN change ELSE 0 END) as total_points_earned,
    SUM(CASE WHEN change < 0 THEN ABS(change) ELSE 0 END) as total_points_spent,
    COUNT(*) FILTER (WHERE reason = 'premium_filter') as premium_filter_uses,
    COUNT(*) FILTER (WHERE reason = 'job_boost') as job_boosts
FROM points_transactions
WHERE created_at >= $1 AND created_at <= $2;

-- name: GetPopularFilters :many
SELECT 
    pf.name, pf.category, pf.points_cost,
    COUNT(pfu.id) as usage_count,
    SUM(pf.points_cost) as total_points_generated
FROM premium_filters pf
JOIN premium_filter_usage pfu ON pf.id = pfu.filter_id
WHERE pfu.used_at >= $1 AND pfu.used_at <= $2
GROUP BY pf.id, pf.name, pf.category, pf.points_cost
ORDER BY usage_count DESC
LIMIT $3;

-- name: GetTopSpenders :many
SELECT 
    u.first_name, u.last_name, u.email,
    up_stats.total_spent, up_stats.points_balance
FROM users u
JOIN user_points up_stats ON u.id = up_stats.user_id
WHERE up_stats.total_spent > 0
ORDER BY up_stats.total_spent DESC
LIMIT $1;

-- Helper function to create points transactions with balance updates
-- This ensures atomic operations for points management