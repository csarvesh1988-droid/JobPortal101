import { Metadata } from 'next'
import { HeroSection } from '@/components/layout/HeroSection'
import { FeaturedJobsSection } from '@/components/job/FeaturedJobsSection'
import { StatsSection } from '@/components/layout/StatsSection'
import { CTASection } from '@/components/layout/CTASection'
import { getFeaturedJobs, getJobStats } from '@/lib/api/jobs'

// This page uses SSG for maximum performance
export const metadata: Metadata = {
  title: 'JobPortal101 - Find Your Dream Job Today',
  description: 'Discover thousands of job opportunities with our advanced matching system and rewards program. Join top companies and talented professionals.',
}

// Generate static props at build time
export default async function HomePage() {
  // Fetch data at build time for SSG
  const [featuredJobs, stats] = await Promise.all([
    getFeaturedJobs(),
    getJobStats(),
  ])

  return (
    <div className="min-h-screen">
      {/* Hero section with search */}
      <HeroSection />
      
      {/* Platform statistics */}
      <StatsSection stats={stats} />
      
      {/* Featured jobs carousel */}
      <FeaturedJobsSection jobs={featuredJobs} />
      
      {/* Call-to-action section */}
      <CTASection />
    </div>
  )
}