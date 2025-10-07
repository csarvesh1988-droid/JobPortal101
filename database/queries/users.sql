-- User Management Queries

-- name: CreateUser :one
INSERT INTO users (
    email, password_hash, role, first_name, last_name, phone, profile_image_url
) VALUES (
    $1, $2, $3, $4, $5, $6, $7
) RETURNING *;

-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1 AND status = 'active';

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1 AND status = 'active';

-- name: UpdateUserLastLogin :exec
UPDATE users SET last_login = NOW(), updated_at = NOW() WHERE id = $1;

-- name: UpdateUserProfile :exec
UPDATE users SET 
    first_name = COALESCE($2, first_name),
    last_name = COALESCE($3, last_name),
    phone = COALESCE($4, phone),
    profile_image_url = COALESCE($5, profile_image_url),
    updated_at = NOW()
WHERE id = $1;

-- name: VerifyUser :exec
UPDATE users SET verification_status = 'verified', updated_at = NOW() WHERE id = $1;

-- name: SuspendUser :exec
UPDATE users SET status = 'suspended', updated_at = NOW() WHERE id = $1;

-- name: ListUsers :many
SELECT id, email, first_name, last_name, role, status, verification_status, created_at
FROM users 
WHERE status != 'deleted'
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- User Profile Queries

-- name: CreateUserProfile :one
INSERT INTO user_profiles (
    user_id, headline, bio, years_experience, current_salary_min, current_salary_max,
    expected_salary_min, expected_salary_max, currency, notice_period_days,
    available_for_work, remote_preference, country, state, city, postal_code,
    public_profile_slug, profile_visibility
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18
) RETURNING *;

-- name: GetUserProfile :one
SELECT 
    u.id, u.email, u.first_name, u.last_name, u.profile_image_url, u.created_at,
    up.headline, up.bio, up.years_experience, up.current_salary_min, up.current_salary_max,
    up.expected_salary_min, up.expected_salary_max, up.currency, up.notice_period_days,
    up.available_for_work, up.remote_preference, up.country, up.state, up.city,
    up.public_profile_slug, up.profile_visibility
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE u.id = $1 AND u.status = 'active';

-- name: GetPublicProfile :one
SELECT 
    u.first_name, u.last_name, u.profile_image_url,
    up.headline, up.bio, up.years_experience, up.country, up.state, up.city,
    up.remote_preference, up.available_for_work
FROM users u
JOIN user_profiles up ON u.id = up.user_id
WHERE up.public_profile_slug = $1 
AND u.status = 'active' 
AND up.profile_visibility IN ('public', 'recruiter-only');

-- name: UpdateUserProfile :exec
UPDATE user_profiles SET
    headline = COALESCE($2, headline),
    bio = COALESCE($3, bio),
    years_experience = COALESCE($4, years_experience),
    current_salary_min = COALESCE($5, current_salary_min),
    current_salary_max = COALESCE($6, current_salary_max),
    expected_salary_min = COALESCE($7, expected_salary_min),
    expected_salary_max = COALESCE($8, expected_salary_max),
    notice_period_days = COALESCE($9, notice_period_days),
    available_for_work = COALESCE($10, available_for_work),
    remote_preference = COALESCE($11, remote_preference),
    country = COALESCE($12, country),
    state = COALESCE($13, state),
    city = COALESCE($14, city),
    postal_code = COALESCE($15, postal_code),
    profile_visibility = COALESCE($16, profile_visibility),
    updated_at = NOW()
WHERE user_id = $1;

-- Skills Management

-- name: CreateSkill :one
INSERT INTO skills (name, category) VALUES ($1, $2) RETURNING *;

-- name: GetSkillByName :one
SELECT * FROM skills WHERE LOWER(name) = LOWER($1);

-- name: ListSkills :many
SELECT * FROM skills ORDER BY name LIMIT $1 OFFSET $2;

-- name: SearchSkills :many
SELECT * FROM skills 
WHERE name ILIKE $1 
ORDER BY 
    CASE WHEN LOWER(name) = LOWER($1) THEN 1 ELSE 2 END,
    name
LIMIT $2;

-- name: AddUserSkill :exec
INSERT INTO user_skills (user_id, skill_id, proficiency_level, years_experience)
VALUES ($1, $2, $3, $4)
ON CONFLICT (user_id, skill_id) 
DO UPDATE SET 
    proficiency_level = EXCLUDED.proficiency_level,
    years_experience = EXCLUDED.years_experience;

-- name: GetUserSkills :many
SELECT s.id, s.name, s.category, us.proficiency_level, us.years_experience
FROM skills s
JOIN user_skills us ON s.id = us.skill_id
WHERE us.user_id = $1
ORDER BY us.proficiency_level DESC, s.name;