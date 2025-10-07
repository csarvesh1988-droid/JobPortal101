import { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { JobDetailsComponent } from '@/components/job/JobDetailsComponent'
import { CompanyInfoCard } from '@/components/company/CompanyInfoCard'
import { SimilarJobsSection } from '@/components/job/SimilarJobsSection'
import { JobStructuredData } from '@/components/seo/JobStructuredData'
import { getJobBySlug, getSimilarJobs } from '@/lib/api/jobs'

// ISR: Revalidate every 5 minutes for job details
export const revalidate = 300

interface JobPageProps {
  params: {
    slug: string
  }
}

// Dynamic metadata generation for SEO
export async function generateMetadata({ params }: JobPageProps): Promise<Metadata> {
  const job = await getJobBySlug(params.slug)
  
  if (!job) {
    return {
      title: 'Job Not Found',
      description: 'The job you are looking for could not be found.',
    }
  }

  const title = `${job.title} at ${job.company_name} | JobPortal101`
  const description = job.description.length > 160 
    ? job.description.substring(0, 157) + '...'
    : job.description

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: 'article',
      images: job.company_logo ? [{
        url: job.company_logo,
        width: 400,
        height: 400,
        alt: `${job.company_name} logo`,
      }] : [],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: job.company_logo ? [job.company_logo] : [],
    },
  }
}

// Generate static params for popular jobs (optional optimization)
export async function generateStaticParams() {
  // You can pre-generate static pages for most popular/recent jobs
  // This is optional - ISR will handle dynamic generation
  return []
}

export default async function JobDetailsPage({ params }: JobPageProps) {
  // Fetch job details and similar jobs in parallel
  const [job, similarJobs] = await Promise.all([
    getJobBySlug(params.slug),
    getSimilarJobs(params.slug, 6),
  ])

  if (!job) {
    notFound()
  }

  return (
    <>
      {/* SEO: Structured data for job posting */}
      <JobStructuredData job={job} />
      
      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main job details */}
          <div className="lg:col-span-2">
            <JobDetailsComponent job={job} />
          </div>

          {/* Sidebar with company info */}
          <aside className="lg:col-span-1">
            <div className="sticky top-8 space-y-6">
              <CompanyInfoCard company={job.company} />
              
              {/* Quick apply section will be here for authenticated users */}
              <div className="bg-white rounded-lg border p-6">
                <h3 className="font-semibold mb-4">Ready to Apply?</h3>
                {/* Apply button component will go here */}
              </div>
            </div>
          </aside>
        </div>

        {/* Similar jobs section */}
        {similarJobs.length > 0 && (
          <section className="mt-16">
            <SimilarJobsSection jobs={similarJobs} />
          </section>
        )}
      </div>
    </>
  )
}