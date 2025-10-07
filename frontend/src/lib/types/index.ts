// Core types for JobPortal101

export interface User {
  id: string
  email: string
  first_name: string
  last_name: string
  role: 'candidate' | 'recruiter' | 'admin'
  status: 'active' | 'suspended' | 'deleted'
  verification_status: 'pending' | 'verified' | 'rejected'
  profile_image_url?: string
  phone?: string
  created_at: string
  last_login?: string
}

export interface UserProfile {
  user_id: string
  headline?: string
  bio?: string
  years_experience: number
  current_salary_min?: number
  current_salary_max?: number
  expected_salary_min?: number
  expected_salary_max?: number
  currency: string
  notice_period_days: number
  available_for_work: boolean
  remote_preference: 'remote' | 'onsite' | 'hybrid'
  country?: string
  state?: string
  city?: string
  postal_code?: string
  public_profile_slug?: string
  profile_visibility: 'public' | 'private' | 'recruiter-only'
}

export interface Job {
  id: string
  company_id: string
  recruiter_id: string
  title: string
  slug: string
  description: string
  requirements?: string
  job_type: 'full-time' | 'part-time' | 'contract' | 'internship' | 'freelance'
  experience_level: 'entry' | 'junior' | 'mid' | 'senior' | 'lead' | 'executive'
  salary_min?: number
  salary_max?: number
  currency: string
  is_remote: boolean
  country?: string
  state?: string
  city?: string
  status: 'draft' | 'active' | 'paused' | 'closed' | 'expired'
  is_featured: boolean
  featured_until?: string
  view_count: number
  application_count: number
  posted_at?: string
  expires_at?: string
  created_at: string
  updated_at: string
  // Joined fields
  company_name?: string
  company_slug?: string
  company_logo?: string
  company_description?: string
  recruiter_name?: string
}

export interface Company {
  id: string
  name: string
  slug: string
  description?: string
  website_url?: string
  logo_url?: string
  industry?: string
  company_size?: '1-10' | '11-50' | '51-200' | '201-1000' | '1000+'
  founded_year?: number
  headquarters_country?: string
  headquarters_state?: string
  headquarters_city?: string
  is_verified: boolean
  created_at: string
  updated_at: string
}

export interface JobApplication {
  id: string
  job_id: string
  candidate_id: string
  cover_letter?: string
  resume_url?: string
  status: 'submitted' | 'reviewing' | 'shortlisted' | 'interview-scheduled' | 'interviewed' | 'offer-extended' | 'hired' | 'rejected' | 'withdrawn'
  applied_at: string
  last_updated: string
  // Joined fields
  job_title?: string
  job_slug?: string
  company_name?: string
  company_logo?: string
  candidate_name?: string
  candidate_email?: string
}

export interface Skill {
  id: string
  name: string
  category?: string
  created_at: string
}

export interface UserSkill extends Skill {
  proficiency_level: number // 1-5
  years_experience: number
}

export interface UserPoints {
  user_id: string
  points_balance: number
  total_earned: number
  total_spent: number
  last_updated: string
}

export interface PointsTransaction {
  id: string
  user_id: string
  change: number
  type: 'credit' | 'debit'
  reason: 'signup_bonus' | 'profile_completion' | 'referral_bonus' | 'job_application' | 'premium_filter' | 'job_boost' | 'analytics_export' | 'cv_highlight' | 'admin_grant' | 'admin_adjustment' | 'refund' | 'penalty'
  description?: string
  reference_id?: string
  reference_type?: string
  admin_id?: string
  created_at: string
  // Joined fields
  admin_name?: string
  reference_title?: string
}

export interface PremiumFilter {
  id: string
  name: string
  category: 'location' | 'salary' | 'experience' | 'skills' | 'company' | 'job_type' | 'remote'
  description?: string
  points_cost: number
  is_active: boolean
  is_premium: boolean
  daily_limit?: number
  monthly_limit?: number
  filter_config?: Record<string, any>
  created_at: string
  updated_at: string
}

// API Response types
export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
  total_pages: number
}

// Form types
export interface LoginForm {
  email: string
  password: string
}

export interface RegisterForm {
  email: string
  password: string
  first_name: string
  last_name: string
  role: 'candidate' | 'recruiter'
}

export interface JobSearchFilters {
  query?: string
  location?: string
  jobType?: string
  experienceLevel?: string
  salaryMin?: number
  salaryMax?: number
  isRemote?: boolean
  companySize?: string
  industry?: string
  skills?: string[]
}

export interface JobSearchParams extends JobSearchFilters {
  page?: number
  limit?: number
  offset?: number
  sortBy?: 'relevance' | 'date' | 'salary' | 'company'
  sortOrder?: 'asc' | 'desc'
}

// Dashboard types
export interface DashboardStats {
  total_applications: number
  pending_applications: number
  interview_scheduled: number
  offers_received: number
  profile_views: number
  saved_jobs: number
}

export interface JobStats {
  total_jobs: number
  active_jobs: number
  total_applications: number
  total_companies: number
  new_jobs_this_week: number
}

// Notification types
export interface Notification {
  id: string
  user_id: string
  type: 'application_status' | 'new_message' | 'job_match' | 'points_earned' | 'system'
  title: string
  message: string
  is_read: boolean
  action_url?: string
  created_at: string
}

// File upload types
export interface FileUpload {
  file: File
  type: 'resume' | 'profile_image' | 'company_logo'
  max_size: number
  allowed_types: string[]
}

export interface UploadedFile {
  url: string
  filename: string
  size: number
  type: string
  uploaded_at: string
}