-- Company Management Queries

-- name: CreateCompany :one
INSERT INTO companies (
    name, slug, description, website_url, logo_url, industry, 
    company_size, founded_year, headquarters_country, 
    headquarters_state, headquarters_city, is_verified
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
) RETURNING *;

-- name: GetCompanyByID :one
SELECT * FROM companies WHERE id = $1;

-- name: GetCompanyBySlug :one
SELECT * FROM companies WHERE slug = $1;

-- name: UpdateCompany :exec
UPDATE companies SET
    name = COALESCE($2, name),
    description = COALESCE($3, description),
    website_url = COALESCE($4, website_url),
    logo_url = COALESCE($5, logo_url),
    industry = COALESCE($6, industry),
    company_size = COALESCE($7, company_size),
    founded_year = COALESCE($8, founded_year),
    headquarters_country = COALESCE($9, headquarters_country),
    headquarters_state = COALESCE($10, headquarters_state),
    headquarters_city = COALESCE($11, headquarters_city),
    updated_at = NOW()
WHERE id = $1;

-- name: VerifyCompany :exec
UPDATE companies SET is_verified = true, updated_at = NOW() WHERE id = $1;

-- name: ListCompanies :many
SELECT 
    id, name, slug, industry, company_size, headquarters_city, 
    headquarters_country, logo_url, is_verified, created_at
FROM companies
ORDER BY 
    is_verified DESC,
    name ASC
LIMIT $1 OFFSET $2;

-- name: SearchCompanies :many
SELECT 
    id, name, slug, industry, company_size, headquarters_city, 
    headquarters_country, logo_url, is_verified
FROM companies
WHERE name ILIKE $1 OR industry ILIKE $1
ORDER BY 
    CASE WHEN LOWER(name) LIKE LOWER($1) THEN 1 ELSE 2 END,
    is_verified DESC,
    name ASC
LIMIT $2;

-- Company Members (Recruiter Management)

-- name: AddCompanyMember :exec
INSERT INTO company_members (company_id, user_id, role)
VALUES ($1, $2, $3)
ON CONFLICT (company_id, user_id) 
DO UPDATE SET role = EXCLUDED.role;

-- name: RemoveCompanyMember :exec
DELETE FROM company_members 
WHERE company_id = $1 AND user_id = $2;

-- name: GetCompanyMembers :many
SELECT 
    u.id, u.email, u.first_name, u.last_name, u.profile_image_url,
    cm.role, cm.joined_at
FROM company_members cm
JOIN users u ON cm.user_id = u.id
WHERE cm.company_id = $1 AND u.status = 'active'
ORDER BY cm.role, u.first_name;

-- name: GetUserCompanies :many
SELECT 
    c.id, c.name, c.slug, c.logo_url, c.is_verified,
    cm.role, cm.joined_at
FROM company_members cm
JOIN companies c ON cm.company_id = c.id
WHERE cm.user_id = $1
ORDER BY cm.joined_at DESC;

-- name: CheckUserCompanyAccess :one
SELECT EXISTS(
    SELECT 1 FROM company_members 
    WHERE company_id = $1 AND user_id = $2
) as has_access;

-- name: IsCompanyAdmin :one
SELECT EXISTS(
    SELECT 1 FROM company_members 
    WHERE company_id = $1 AND user_id = $2 AND role = 'admin'
) as is_admin;

-- Company Statistics

-- name: GetCompanyStats :one
SELECT 
    (SELECT COUNT(*) FROM jobs WHERE company_id = $1) as total_jobs,
    (SELECT COUNT(*) FROM jobs WHERE company_id = $1 AND status = 'active') as active_jobs,
    (SELECT COUNT(*) FROM job_applications ja JOIN jobs j ON ja.job_id = j.id WHERE j.company_id = $1) as total_applications,
    (SELECT COUNT(*) FROM company_members WHERE company_id = $1) as team_members;

-- name: GetCompanyJobStats :many
SELECT 
    j.id, j.title, j.status, j.posted_at,
    j.application_count, j.view_count
FROM jobs j
WHERE j.company_id = $1
ORDER BY j.posted_at DESC
LIMIT $2;