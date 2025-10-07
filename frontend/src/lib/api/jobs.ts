import { api } from './client'
import { Job, JobSearchParams, PaginatedResponse, JobStats, ApiResponse } from '@/lib/types'

// Job API functions
export async function getJobs(params: JobSearchParams = {}) {
  const response = await api.get<ApiResponse<PaginatedResponse<Job>>>('/api/jobs', {
    ...params,
    page: params.page || 1,
    limit: params.limit || 20,
  })
  
  return {
    jobs: response.data?.items || [],
    total: response.data?.total || 0,
    page: response.data?.page || 1,
    limit: response.data?.limit || 20,
    total_pages: response.data?.total_pages || 1,
  }
}

export async function getJobBySlug(slug: string): Promise<Job | null> {
  try {
    const response = await api.get<ApiResponse<Job>>(`/api/jobs/${slug}`)
    return response.data || null
  } catch (error) {
    console.error('Failed to fetch job:', error)
    return null
  }
}

export async function getFeaturedJobs(limit = 10): Promise<Job[]> {
  try {
    const response = await api.get<ApiResponse<Job[]>>('/api/jobs/featured', { limit })
    return response.data || []
  } catch (error) {
    console.error('Failed to fetch featured jobs:', error)
    return []
  }
}

export async function getSimilarJobs(jobSlug: string, limit = 6): Promise<Job[]> {
  try {
    const response = await api.get<ApiResponse<Job[]>>(`/api/jobs/${jobSlug}/similar`, { limit })
    return response.data || []
  } catch (error) {
    console.error('Failed to fetch similar jobs:', error)
    return []
  }
}

export async function searchJobs(query: string, params: JobSearchParams = {}) {
  const response = await api.get<ApiResponse<PaginatedResponse<Job>>>('/api/jobs/search', {
    q: query,
    ...params,
  })
  
  return {
    jobs: response.data?.items || [],
    total: response.data?.total || 0,
    page: response.data?.page || 1,
    limit: response.data?.limit || 20,
    total_pages: response.data?.total_pages || 1,
  }
}

export async function getJobStats(): Promise<JobStats> {
  try {
    const response = await api.get<ApiResponse<JobStats>>('/api/jobs/stats')
    return response.data || {
      total_jobs: 0,
      active_jobs: 0,
      total_applications: 0,
      total_companies: 0,
      new_jobs_this_week: 0,
    }
  } catch (error) {
    console.error('Failed to fetch job stats:', error)
    return {
      total_jobs: 0,
      active_jobs: 0,
      total_applications: 0,
      total_companies: 0,
      new_jobs_this_week: 0,
    }
  }
}

// Job application functions
export async function applyToJob(jobId: string, applicationData: {
  cover_letter?: string
  resume_url?: string
}) {
  return api.post<ApiResponse>(`/api/jobs/${jobId}/apply`, applicationData)
}

export async function checkApplicationStatus(jobId: string) {
  return api.get<ApiResponse<{ hasApplied: boolean, application?: any }>>(
    `/api/jobs/${jobId}/application-status`
  )
}

// Recruiter job functions
export async function createJob(jobData: Partial<Job>) {
  return api.post<ApiResponse<Job>>('/api/recruiter/jobs', jobData)
}

export async function updateJob(jobId: string, jobData: Partial<Job>) {
  return api.put<ApiResponse<Job>>(`/api/recruiter/jobs/${jobId}`, jobData)
}

export async function deleteJob(jobId: string) {
  return api.delete<ApiResponse>(`/api/recruiter/jobs/${jobId}`)
}

export async function publishJob(jobId: string) {
  return api.post<ApiResponse>(`/api/recruiter/jobs/${jobId}/publish`)
}

export async function featureJob(jobId: string) {
  return api.post<ApiResponse>(`/api/recruiter/jobs/${jobId}/feature`)
}

// Job interaction functions
export async function saveJob(jobId: string) {
  return api.post<ApiResponse>(`/api/jobs/${jobId}/save`)
}

export async function unsaveJob(jobId: string) {
  return api.delete<ApiResponse>(`/api/jobs/${jobId}/save`)
}

export async function getSavedJobs(params: { page?: number, limit?: number } = {}) {
  return api.get<ApiResponse<PaginatedResponse<Job>>>('/api/user/saved-jobs', params)
}

// Job view tracking
export async function trackJobView(jobId: string) {
  // This can be called without waiting for response
  api.post(`/api/jobs/${jobId}/view`).catch(() => {
    // Silently fail - view tracking is not critical
  })
}