-- Job Management Queries

-- name: CreateJob :one
INSERT INTO jobs (
    company_id, recruiter_id, title, slug, description, requirements,
    job_type, experience_level, salary_min, salary_max, currency,
    is_remote, country, state, city, status, expires_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17
) RETURNING *;

-- name: GetJobByID :one
SELECT 
    j.*,
    c.name as company_name,
    c.slug as company_slug,
    c.logo_url as company_logo,
    u.first_name as recruiter_first_name,
    u.last_name as recruiter_last_name
FROM jobs j
JOIN companies c ON j.company_id = c.id
JOIN users u ON j.recruiter_id = u.id
WHERE j.id = $1;

-- name: GetJobBySlug :one
SELECT 
    j.*,
    c.name as company_name,
    c.slug as company_slug,
    c.logo_url as company_logo,
    c.description as company_description,
    c.website_url as company_website
FROM jobs j
JOIN companies c ON j.company_id = c.id
WHERE j.slug = $1 AND j.status = 'active';

-- name: ListActiveJobs :many
SELECT 
    j.id, j.title, j.slug, j.job_type, j.experience_level,
    j.salary_min, j.salary_max, j.currency, j.is_remote,
    j.country, j.state, j.city, j.posted_at, j.is_featured,
    c.name as company_name, c.slug as company_slug, c.logo_url as company_logo
FROM jobs j
JOIN companies c ON j.company_id = c.id
WHERE j.status = 'active' 
AND (j.expires_at IS NULL OR j.expires_at > NOW())
ORDER BY 
    j.is_featured DESC,
    j.posted_at DESC
LIMIT $1 OFFSET $2;

-- name: SearchJobs :many
SELECT 
    j.id, j.title, j.slug, j.job_type, j.experience_level,
    j.salary_min, j.salary_max, j.currency, j.is_remote,
    j.country, j.state, j.city, j.posted_at, j.is_featured,
    c.name as company_name, c.slug as company_slug, c.logo_url as company_logo,
    ts_rank(to_tsvector('english', j.title || ' ' || j.description), plainto_tsquery('english', $1)) as rank
FROM jobs j
JOIN companies c ON j.company_id = c.id
WHERE j.status = 'active' 
AND (j.expires_at IS NULL OR j.expires_at > NOW())
AND to_tsvector('english', j.title || ' ' || j.description) @@ plainto_tsquery('english', $1)
ORDER BY rank DESC, j.is_featured DESC, j.posted_at DESC
LIMIT $2 OFFSET $3;

-- name: FilterJobs :many
SELECT 
    j.id, j.title, j.slug, j.job_type, j.experience_level,
    j.salary_min, j.salary_max, j.currency, j.is_remote,
    j.country, j.state, j.city, j.posted_at, j.is_featured,
    c.name as company_name, c.slug as company_slug, c.logo_url as company_logo
FROM jobs j
JOIN companies c ON j.company_id = c.id
WHERE j.status = 'active' 
AND (j.expires_at IS NULL OR j.expires_at > NOW())
AND ($1 = '' OR j.job_type = $1::job_type)
AND ($2 = '' OR j.experience_level = $2::experience_level)
AND ($3 = 0 OR j.salary_min >= $3)
AND ($4 = 0 OR j.salary_max <= $4)
AND ($5 = '' OR j.country = $5)
AND ($6 = '' OR j.state = $6)
AND ($7 = '' OR j.city = $7)
AND ($8 = false OR j.is_remote = $8)
ORDER BY 
    j.is_featured DESC,
    j.posted_at DESC
LIMIT $9 OFFSET $10;

-- name: GetCompanyJobs :many
SELECT 
    j.id, j.title, j.slug, j.status, j.job_type, j.experience_level,
    j.application_count, j.view_count, j.posted_at, j.expires_at,
    j.is_featured, j.featured_until
FROM jobs j
WHERE j.company_id = $1
ORDER BY j.created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetRecruiterJobs :many
SELECT 
    j.id, j.title, j.slug, j.status, j.job_type, j.experience_level,
    j.application_count, j.view_count, j.posted_at, j.expires_at,
    c.name as company_name
FROM jobs j
JOIN companies c ON j.company_id = c.id
WHERE j.recruiter_id = $1
ORDER BY j.created_at DESC
LIMIT $2 OFFSET $3;

-- name: UpdateJobStatus :exec
UPDATE jobs SET 
    status = $2,
    updated_at = NOW()
WHERE id = $1;

-- name: PublishJob :exec
UPDATE jobs SET 
    status = 'active',
    posted_at = CASE WHEN posted_at IS NULL THEN NOW() ELSE posted_at END,
    updated_at = NOW()
WHERE id = $1;

-- name: FeatureJob :exec
UPDATE jobs SET 
    is_featured = true,
    featured_until = NOW() + INTERVAL '30 days',
    updated_at = NOW()
WHERE id = $1;

-- name: IncrementJobViews :exec
UPDATE jobs SET 
    view_count = view_count + 1,
    updated_at = NOW()
WHERE id = $1;

-- name: UpdateJobApplicationCount :exec
UPDATE jobs SET 
    application_count = application_count + $2,
    updated_at = NOW()
WHERE id = $1;

-- Job Skills

-- name: AddJobSkill :exec
INSERT INTO job_skills (job_id, skill_id, is_required, minimum_years)
VALUES ($1, $2, $3, $4)
ON CONFLICT (job_id, skill_id) 
DO UPDATE SET 
    is_required = EXCLUDED.is_required,
    minimum_years = EXCLUDED.minimum_years;

-- name: GetJobSkills :many
SELECT s.id, s.name, s.category, js.is_required, js.minimum_years
FROM skills s
JOIN job_skills js ON s.id = js.skill_id
WHERE js.job_id = $1
ORDER BY js.is_required DESC, s.name;

-- name: DeleteJobSkills :exec
DELETE FROM job_skills WHERE job_id = $1;

-- Job Applications

-- name: CreateJobApplication :one
INSERT INTO job_applications (
    job_id, candidate_id, cover_letter, resume_url, status
) VALUES (
    $1, $2, $3, $4, 'submitted'
) RETURNING *;

-- name: GetJobApplication :one
SELECT 
    ja.*,
    u.first_name, u.last_name, u.email, u.profile_image_url,
    up.headline, up.years_experience, up.country, up.state, up.city
FROM job_applications ja
JOIN users u ON ja.candidate_id = u.id
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE ja.id = $1;

-- name: GetUserJobApplication :one
SELECT * FROM job_applications 
WHERE job_id = $1 AND candidate_id = $2;

-- name: ListJobApplications :many
SELECT 
    ja.id, ja.status, ja.applied_at, ja.cover_letter,
    u.first_name, u.last_name, u.email, u.profile_image_url,
    up.headline, up.years_experience
FROM job_applications ja
JOIN users u ON ja.candidate_id = u.id
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE ja.job_id = $1
ORDER BY 
    CASE ja.status 
        WHEN 'submitted' THEN 1 
        WHEN 'reviewing' THEN 2 
        WHEN 'shortlisted' THEN 3 
        ELSE 4 
    END,
    ja.applied_at DESC
LIMIT $2 OFFSET $3;

-- name: ListUserApplications :many
SELECT 
    ja.id, ja.status, ja.applied_at,
    j.id as job_id, j.title as job_title, j.slug as job_slug,
    c.name as company_name, c.logo_url as company_logo
FROM job_applications ja
JOIN jobs j ON ja.job_id = j.id
JOIN companies c ON j.company_id = c.id
WHERE ja.candidate_id = $1
ORDER BY ja.applied_at DESC
LIMIT $2 OFFSET $3;

-- name: UpdateApplicationStatus :exec
UPDATE job_applications SET 
    status = $2,
    last_updated = NOW()
WHERE id = $1;

-- name: GetApplicationStats :one
SELECT 
    COUNT(*) as total_applications,
    COUNT(*) FILTER (WHERE status = 'submitted') as submitted,
    COUNT(*) FILTER (WHERE status = 'reviewing') as reviewing,
    COUNT(*) FILTER (WHERE status = 'shortlisted') as shortlisted,
    COUNT(*) FILTER (WHERE status IN ('interviewed', 'offer-extended', 'hired')) as advanced,
    COUNT(*) FILTER (WHERE status = 'rejected') as rejected
FROM job_applications
WHERE job_id = $1;