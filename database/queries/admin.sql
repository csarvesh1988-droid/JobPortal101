-- Admin and System Configuration Queries

-- System Configuration

-- name: GetSystemConfig :one
SELECT value FROM system_config WHERE key = $1;

-- name: SetSystemConfig :exec
INSERT INTO system_config (key, value, description, is_encrypted, updated_by)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (key) 
DO UPDATE SET 
    value = EXCLUDED.value,
    description = COALESCE(EXCLUDED.description, system_config.description),
    is_encrypted = EXCLUDED.is_encrypted,
    updated_by = EXCLUDED.updated_by,
    updated_at = NOW();

-- name: ListSystemConfig :many
SELECT key, value, description, is_encrypted, updated_at
FROM system_config
ORDER BY key;

-- name: GetSMTPConfig :many
SELECT key, value, description
FROM system_config
WHERE key LIKE 'smtp_%'
ORDER BY key;

-- Admin Audit Log

-- name: LogAdminAction :exec
INSERT INTO admin_audit_log (
    admin_id, action, resource_type, resource_id, 
    old_values, new_values, description, ip_address, user_agent
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9
);

-- name: GetAdminAuditLog :many
SELECT 
    aal.*,
    u.first_name || ' ' || u.last_name as admin_name,
    u.email as admin_email
FROM admin_audit_log aal
JOIN users u ON aal.admin_id = u.id
WHERE ($1 = '' OR aal.action ILIKE '%' || $1 || '%')
AND ($2 = '' OR aal.resource_type = $2)
ORDER BY aal.created_at DESC
LIMIT $3 OFFSET $4;

-- name: GetResourceAuditHistory :many
SELECT 
    aal.*,
    u.first_name || ' ' || u.last_name as admin_name
FROM admin_audit_log aal
JOIN users u ON aal.admin_id = u.id
WHERE aal.resource_type = $1 AND aal.resource_id = $2
ORDER BY aal.created_at DESC
LIMIT $3;

-- User Management (Admin)

-- name: GetUserDetails :one
SELECT 
    u.id, u.email, u.first_name, u.last_name, u.role, u.status, 
    u.verification_status, u.last_login, u.created_at,
    up.points_balance, up.total_earned, up.total_spent
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.id = $1;

-- name: AdminUpdateUserStatus :exec
UPDATE users SET 
    status = $2,
    updated_at = NOW()
WHERE id = $1;

-- name: AdminUpdateUserRole :exec
UPDATE users SET 
    role = $2,
    updated_at = NOW()
WHERE id = $1;

-- name: AdminSearchUsers :many
SELECT 
    u.id, u.email, u.first_name, u.last_name, u.role, u.status,
    u.verification_status, u.last_login, u.created_at,
    COALESCE(up.points_balance, 0) as points_balance
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.status != 'deleted'
AND (
    u.email ILIKE '%' || $1 || '%' OR
    u.first_name ILIKE '%' || $1 || '%' OR
    u.last_name ILIKE '%' || $1 || '%'
)
ORDER BY u.created_at DESC
LIMIT $2 OFFSET $3;

-- Points Management (Admin)

-- name: AdminAdjustPoints :one
INSERT INTO points_transactions (
    user_id, change, type, reason, description, admin_id
) VALUES (
    $1, 
    $2, 
    CASE WHEN $2 > 0 THEN 'credit'::transaction_type ELSE 'debit'::transaction_type END,
    'admin_adjustment'::points_reason,
    $3,
    $4
) RETURNING *;

-- name: AdminGetUserPointsHistory :many
SELECT 
    pt.*,
    CASE 
        WHEN pt.admin_id IS NOT NULL THEN 
            au.first_name || ' ' || au.last_name
        ELSE 'System'
    END as source
FROM points_transactions pt
LEFT JOIN users au ON pt.admin_id = au.id
WHERE pt.user_id = $1
ORDER BY pt.created_at DESC
LIMIT $2 OFFSET $3;

-- Premium Filter Management (Admin)

-- name: AdminListPremiumFilters :many
SELECT * FROM premium_filters ORDER BY category, name;

-- name: AdminUpdateFilterPricing :exec
UPDATE premium_filters SET
    points_cost = $2,
    updated_at = NOW()
WHERE id = $1;

-- name: AdminToggleFilter :exec
UPDATE premium_filters SET
    is_active = $2,
    updated_at = NOW()
WHERE id = $1;

-- name: AdminGetFilterUsageStats :many
SELECT 
    pf.name, pf.category, pf.points_cost, pf.is_active,
    COUNT(pfu.id) as total_uses,
    COUNT(DISTINCT pfu.user_id) as unique_users,
    SUM(pf.points_cost) as total_revenue
FROM premium_filters pf
LEFT JOIN premium_filter_usage pfu ON pf.id = pfu.filter_id
GROUP BY pf.id, pf.name, pf.category, pf.points_cost, pf.is_active
ORDER BY total_uses DESC;

-- Job Management (Admin)

-- name: AdminGetJobs :many
SELECT 
    j.id, j.title, j.status, j.posted_at, j.expires_at,
    j.application_count, j.view_count, j.is_featured,
    c.name as company_name,
    u.first_name || ' ' || u.last_name as recruiter_name
FROM jobs j
JOIN companies c ON j.company_id = c.id
JOIN users u ON j.recruiter_id = u.id
WHERE ($1 = '' OR j.status::text = $1)
ORDER BY j.created_at DESC
LIMIT $2 OFFSET $3;

-- name: AdminUpdateJobStatus :exec
UPDATE jobs SET 
    status = $2,
    updated_at = NOW()
WHERE id = $1;

-- Dashboard Analytics

-- name: GetDashboardStats :one
SELECT 
    (SELECT COUNT(*) FROM users WHERE status = 'active') as active_users,
    (SELECT COUNT(*) FROM users WHERE role = 'candidate' AND status = 'active') as candidates,
    (SELECT COUNT(*) FROM users WHERE role = 'recruiter' AND status = 'active') as recruiters,
    (SELECT COUNT(*) FROM jobs WHERE status = 'active') as active_jobs,
    (SELECT COUNT(*) FROM job_applications WHERE applied_at >= CURRENT_DATE - INTERVAL '30 days') as recent_applications,
    (SELECT SUM(points_balance) FROM user_points) as total_points_in_circulation;

-- name: GetRecentActivity :many
SELECT 
    'user_signup' as activity_type,
    u.first_name || ' ' || u.last_name as description,
    u.created_at as timestamp
FROM users u
WHERE u.created_at >= CURRENT_DATE - INTERVAL '7 days'

UNION ALL

SELECT 
    'job_posted' as activity_type,
    'New job: ' || j.title || ' at ' || c.name as description,
    j.created_at as timestamp
FROM jobs j
JOIN companies c ON j.company_id = c.id
WHERE j.created_at >= CURRENT_DATE - INTERVAL '7 days'

UNION ALL

SELECT 
    'application_submitted' as activity_type,
    u.first_name || ' applied to ' || j.title as description,
    ja.applied_at as timestamp
FROM job_applications ja
JOIN users u ON ja.candidate_id = u.id
JOIN jobs j ON ja.job_id = j.id
WHERE ja.applied_at >= CURRENT_DATE - INTERVAL '7 days'

ORDER BY timestamp DESC
LIMIT $1;