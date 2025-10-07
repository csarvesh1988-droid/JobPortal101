-- JobPortal101 Database Schema
-- PostgreSQL DDL for high-performance job portal with points economy
-- Optimized for concurrent users and scalability

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fast text search

-- =====================================================
-- CORE USER MANAGEMENT
-- =====================================================

CREATE TYPE user_role AS ENUM ('candidate', 'recruiter', 'admin');
CREATE TYPE user_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE account_verification AS ENUM ('pending', 'verified', 'rejected');

-- Core users table - optimized for fast lookups
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'candidate',
    status user_status NOT NULL DEFAULT 'active',
    verification_status account_verification NOT NULL DEFAULT 'pending',
    
    -- Profile basics
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image_url TEXT,
    
    -- Metadata
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Performance indexes
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- User profiles for detailed candidate information
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- Professional info
    headline VARCHAR(200),
    bio TEXT,
    years_experience INTEGER DEFAULT 0,
    current_salary_min INTEGER,
    current_salary_max INTEGER,
    expected_salary_min INTEGER,
    expected_salary_max INTEGER,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Availability
    notice_period_days INTEGER DEFAULT 30,
    available_for_work BOOLEAN DEFAULT true,
    remote_preference VARCHAR(20) DEFAULT 'hybrid', -- 'remote', 'onsite', 'hybrid'
    
    -- Location
    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    
    -- SEO and visibility
    public_profile_slug VARCHAR(100) UNIQUE,
    profile_visibility VARCHAR(20) DEFAULT 'public', -- 'public', 'private', 'recruiter-only'
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Skills and expertise
CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(50), -- 'programming', 'framework', 'tool', 'soft-skill'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_skills (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    skill_id UUID REFERENCES skills(id) ON DELETE CASCADE,
    proficiency_level INTEGER CHECK (proficiency_level >= 1 AND proficiency_level <= 5),
    years_experience DECIMAL(3,1) DEFAULT 0,
    PRIMARY KEY (user_id, skill_id)
);

-- =====================================================
-- COMPANY AND RECRUITER MANAGEMENT
-- =====================================================

CREATE TYPE company_size AS ENUM ('1-10', '11-50', '51-200', '201-1000', '1000+');

CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description TEXT,
    website_url VARCHAR(500),
    logo_url TEXT,
    
    -- Company details
    industry VARCHAR(100),
    company_size company_size,
    founded_year INTEGER,
    
    -- Location
    headquarters_country VARCHAR(100),
    headquarters_state VARCHAR(100),
    headquarters_city VARCHAR(100),
    
    -- Status
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Link recruiters to companies
CREATE TABLE company_members (
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'recruiter', -- 'admin', 'recruiter', 'member'
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (company_id, user_id)
);

-- =====================================================
-- JOB MANAGEMENT SYSTEM
-- =====================================================

CREATE TYPE job_type AS ENUM ('full-time', 'part-time', 'contract', 'internship', 'freelance');
CREATE TYPE job_status AS ENUM ('draft', 'active', 'paused', 'closed', 'expired');
CREATE TYPE experience_level AS ENUM ('entry', 'junior', 'mid', 'senior', 'lead', 'executive');

CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    recruiter_id UUID NOT NULL REFERENCES users(id),
    
    -- Job basics
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(250) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    requirements TEXT,
    
    -- Job details
    job_type job_type NOT NULL,
    experience_level experience_level NOT NULL,
    salary_min INTEGER,
    salary_max INTEGER,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Location and remote
    is_remote BOOLEAN DEFAULT false,
    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    
    -- Status and visibility
    status job_status NOT NULL DEFAULT 'draft',
    is_featured BOOLEAN DEFAULT false, -- Premium boost
    featured_until TIMESTAMPTZ,
    
    -- SEO and performance
    view_count INTEGER DEFAULT 0,
    application_count INTEGER DEFAULT 0,
    
    -- Timestamps
    posted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure recruiter belongs to company
    CONSTRAINT job_recruiter_company_check 
        CHECK (EXISTS (
            SELECT 1 FROM company_members cm 
            WHERE cm.company_id = jobs.company_id 
            AND cm.user_id = jobs.recruiter_id
        ))
);

-- Job skills requirements
CREATE TABLE job_skills (
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    skill_id UUID REFERENCES skills(id) ON DELETE CASCADE,
    is_required BOOLEAN DEFAULT true,
    minimum_years DECIMAL(3,1) DEFAULT 0,
    PRIMARY KEY (job_id, skill_id)
);

-- Job applications
CREATE TYPE application_status AS ENUM (
    'submitted', 'reviewing', 'shortlisted', 'interview-scheduled', 
    'interviewed', 'offer-extended', 'hired', 'rejected', 'withdrawn'
);

CREATE TABLE job_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Application details
    cover_letter TEXT,
    resume_url TEXT,
    status application_status NOT NULL DEFAULT 'submitted',
    
    -- Tracking
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Prevent duplicate applications
    UNIQUE (job_id, candidate_id)
);

-- =====================================================
-- POINTS AND REWARDS ECONOMY
-- =====================================================

CREATE TYPE transaction_type AS ENUM ('credit', 'debit');
CREATE TYPE points_reason AS ENUM (
    'signup_bonus', 'profile_completion', 'referral_bonus', 'job_application',
    'premium_filter', 'job_boost', 'analytics_export', 'cv_highlight',
    'admin_grant', 'admin_adjustment', 'refund', 'penalty'
);

-- User points balance - separate table for performance
CREATE TABLE user_points (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    points_balance INTEGER NOT NULL DEFAULT 0,
    total_earned INTEGER NOT NULL DEFAULT 0,
    total_spent INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure balance integrity
    CONSTRAINT positive_balance CHECK (points_balance >= 0)
);

-- Immutable transaction ledger - critical for audit trail
CREATE TABLE points_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Transaction details
    change INTEGER NOT NULL, -- Positive for credit, negative for debit
    type transaction_type NOT NULL,
    reason points_reason NOT NULL,
    description TEXT,
    
    -- Reference tracking
    reference_id UUID, -- Job ID, application ID, etc.
    reference_type VARCHAR(50), -- 'job', 'application', 'user'
    
    -- Admin tracking
    admin_id UUID REFERENCES users(id),
    
    -- Immutable timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_credit CHECK (
        (type = 'credit' AND change > 0) OR 
        (type = 'debit' AND change < 0)
    )
);

-- =====================================================
-- PREMIUM FILTERS AND CONFIGURATION
-- =====================================================

CREATE TYPE filter_category AS ENUM (
    'location', 'salary', 'experience', 'skills', 'company', 'job_type', 'remote'
);

CREATE TABLE premium_filters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category filter_category NOT NULL,
    description TEXT,
    
    -- Pricing
    points_cost INTEGER NOT NULL DEFAULT 0,
    
    -- Availability
    is_active BOOLEAN DEFAULT true,
    is_premium BOOLEAN DEFAULT true, -- false = free filter
    
    -- Usage limits
    daily_limit INTEGER, -- NULL = unlimited
    monthly_limit INTEGER,
    
    -- Configuration
    filter_config JSONB, -- Store filter-specific settings
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Track premium filter usage
CREATE TABLE premium_filter_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    filter_id UUID NOT NULL REFERENCES premium_filters(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES points_transactions(id),
    
    -- Usage details
    filter_params JSONB, -- Store actual filter parameters used
    results_count INTEGER,
    
    used_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- ADMIN AND CONFIGURATION
-- =====================================================

-- System configuration - SMTP, feature flags, etc.
CREATE TABLE system_config (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Admin audit log - track all admin actions
CREATE TABLE admin_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES users(id),
    
    -- Action details
    action VARCHAR(100) NOT NULL, -- 'update_smtp', 'change_filter_price', 'suspend_user'
    resource_type VARCHAR(50) NOT NULL, -- 'user', 'job', 'filter', 'config'
    resource_id UUID,
    
    -- Change tracking
    old_values JSONB,
    new_values JSONB,
    description TEXT,
    
    -- Metadata
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- PERFORMANCE INDEXES
-- =====================================================

-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role_status ON users(role, status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Profile indexes
CREATE INDEX idx_profiles_slug ON user_profiles(public_profile_slug);
CREATE INDEX idx_profiles_location ON user_profiles(country, state, city);
CREATE INDEX idx_profiles_availability ON user_profiles(available_for_work);

-- Job indexes
CREATE INDEX idx_jobs_status_posted ON jobs(status, posted_at DESC);
CREATE INDEX idx_jobs_company ON jobs(company_id);
CREATE INDEX idx_jobs_location ON jobs(country, state, city);
CREATE INDEX idx_jobs_salary ON jobs(salary_min, salary_max);
CREATE INDEX idx_jobs_type_level ON jobs(job_type, experience_level);
CREATE INDEX idx_jobs_featured ON jobs(is_featured, featured_until);
CREATE INDEX idx_jobs_text_search ON jobs USING gin(to_tsvector('english', title || ' ' || description));

-- Application indexes
CREATE INDEX idx_applications_candidate ON job_applications(candidate_id, applied_at DESC);
CREATE INDEX idx_applications_job ON job_applications(job_id, status);

-- Points indexes
CREATE INDEX idx_points_user ON user_points(user_id);
CREATE INDEX idx_transactions_user_time ON points_transactions(user_id, created_at DESC);
CREATE INDEX idx_transactions_reference ON points_transactions(reference_id, reference_type);

-- Filter usage indexes
CREATE INDEX idx_filter_usage_user ON premium_filter_usage(user_id, used_at DESC);
CREATE INDEX idx_filter_usage_filter ON premium_filter_usage(filter_id);

-- Audit log indexes
CREATE INDEX idx_audit_admin ON admin_audit_log(admin_id, created_at DESC);
CREATE INDEX idx_audit_resource ON admin_audit_log(resource_type, resource_id);

-- =====================================================
-- TRIGGERS AND FUNCTIONS
-- =====================================================

-- Update timestamps automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to relevant tables
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at 
    BEFORE UPDATE ON companies 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_jobs_updated_at 
    BEFORE UPDATE ON jobs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Points balance trigger - ensure consistency
CREATE OR REPLACE FUNCTION update_points_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update user points balance
    INSERT INTO user_points (user_id, points_balance, total_earned, total_spent, last_updated)
    VALUES (
        NEW.user_id, 
        NEW.change,
        CASE WHEN NEW.change > 0 THEN NEW.change ELSE 0 END,
        CASE WHEN NEW.change < 0 THEN ABS(NEW.change) ELSE 0 END,
        NOW()
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET
        points_balance = user_points.points_balance + NEW.change,
        total_earned = user_points.total_earned + CASE WHEN NEW.change > 0 THEN NEW.change ELSE 0 END,
        total_spent = user_points.total_spent + CASE WHEN NEW.change < 0 THEN ABS(NEW.change) ELSE 0 END,
        last_updated = NOW();
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER points_balance_trigger
    AFTER INSERT ON points_transactions
    FOR EACH ROW EXECUTE FUNCTION update_points_balance();

-- =====================================================
-- INITIAL DATA SEEDING
-- =====================================================

-- Insert default premium filters
INSERT INTO premium_filters (name, category, description, points_cost, is_premium) VALUES
('Advanced Salary Filter', 'salary', 'Filter jobs by exact salary ranges with benefits breakdown', 0, true),
('Skills Match Score', 'skills', 'Show percentage match between your skills and job requirements', 0, true),
('Company Culture Insights', 'company', 'Access detailed company culture and review data', 0, true),
('Location Radius Search', 'location', 'Search jobs within custom radius of your location', 0, true),
('Remote Work Options', 'remote', 'Filter by remote work flexibility and hybrid options', 0, true),
('Experience Level Matching', 'experience', 'Find jobs that match your exact experience level', 0, true);

-- Insert system configuration defaults
INSERT INTO system_config (key, value, description) VALUES
('smtp_enabled', 'false', 'Enable/disable email notifications'),
('max_applications_per_day', '10', 'Maximum job applications per user per day'),
('featured_job_duration_days', '30', 'How long featured jobs stay highlighted'),
('signup_bonus_points', '50', 'Points awarded for account creation'),
('profile_completion_points', '100', 'Points awarded for completing profile'),
('referral_bonus_points', '200', 'Points awarded for successful referrals'),
('premium_filter_daily_limit', '5', 'Default daily limit for premium filters');

-- Create initial admin user (password: admin123 - CHANGE IN PRODUCTION!)
INSERT INTO users (email, password_hash, role, first_name, last_name, verification_status) VALUES
('admin@jobportal101.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'System', 'Admin', 'verified');

COMMIT;