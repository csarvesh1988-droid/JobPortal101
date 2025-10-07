import { Metadata } from 'next'
import { JobListingComponent } from '@/components/job/JobListingComponent'
import { JobFilters } from '@/components/job/JobFilters'
import { getJobs } from '@/lib/api/jobs'

// ISR: Revalidate every 60 seconds for fresh job listings
export const revalidate = 60

export const metadata: Metadata = {
  title: 'Browse Jobs - Find Your Perfect Match',
  description: 'Explore thousands of job opportunities across various industries and locations. Use our advanced filters to find the perfect job match.',
  openGraph: {
    title: 'Browse Jobs - JobPortal101',
    description: 'Explore thousands of job opportunities across various industries and locations.',
    type: 'website',
  },
}

interface JobsPageProps {
  searchParams: {
    q?: string
    location?: string
    type?: string
    level?: string
    salary_min?: string
    salary_max?: string
    remote?: string
    page?: string
  }
}

export default async function JobsPage({ searchParams }: JobsPageProps) {
  const page = parseInt(searchParams.page || '1')
  const limit = 20
  const offset = (page - 1) * limit

  // Fetch jobs with filters applied - ISR cached
  const jobsData = await getJobs({
    query: searchParams.q,
    location: searchParams.location,
    jobType: searchParams.type,
    experienceLevel: searchParams.level,
    salaryMin: searchParams.salary_min ? parseInt(searchParams.salary_min) : undefined,
    salaryMax: searchParams.salary_max ? parseInt(searchParams.salary_max) : undefined,
    isRemote: searchParams.remote === 'true',
    limit,
    offset,
  })

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          {searchParams.q ? `Jobs matching "${searchParams.q}"` : 'Browse Jobs'}
        </h1>
        <p className="text-gray-600">
          Found {jobsData.total} jobs • Page {page} of {Math.ceil(jobsData.total / limit)}
        </p>
      </div>

      <div className="flex gap-8">
        {/* Filters sidebar */}
        <aside className="w-80 flex-shrink-0">
          <JobFilters searchParams={searchParams} />
        </aside>

        {/* Job listings */}
        <main className="flex-1">
          <JobListingComponent 
            jobs={jobsData.jobs} 
            total={jobsData.total}
            currentPage={page}
            limit={limit}
          />
        </main>
      </div>
    </div>
  )
}