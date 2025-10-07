'use client'

import { useAuth } from '@/lib/auth/useAuth'
import { DashboardStats } from '@/components/dashboard/DashboardStats'
import { RecentApplications } from '@/components/dashboard/RecentApplications'
import { PointsOverview } from '@/components/dashboard/PointsOverview'
import { RecommendedJobs } from '@/components/dashboard/RecommendedJobs'
import { ProfileCompletionBanner } from '@/components/dashboard/ProfileCompletionBanner'

export default function DashboardPage() {
  const { user } = useAuth()

  if (!user) return null

  return (
    <div className="space-y-8">
      {/* Welcome header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Welcome back, {user.first_name}!
        </h1>
        <p className="text-gray-600 mt-1">
          Here's what's happening with your job search today.
        </p>
      </div>

      {/* Profile completion banner */}
      <ProfileCompletionBanner user={user} />

      {/* Dashboard stats */}
      <DashboardStats />

      {/* Two column layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main content */}
        <div className="lg:col-span-2 space-y-8">
          <RecentApplications />
          <RecommendedJobs />
        </div>

        {/* Sidebar */}
        <div className="lg:col-span-1 space-y-6">
          <PointsOverview />
          
          {/* Quick actions card */}
          <div className="bg-white rounded-lg border p-6">
            <h3 className="font-semibold text-gray-900 mb-4">Quick Actions</h3>
            <div className="space-y-3">
              <button className="w-full text-left px-3 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md transition-colors">
                Update Profile
              </button>
              <button className="w-full text-left px-3 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md transition-colors">
                Upload Resume
              </button>
              <button className="w-full text-left px-3 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md transition-colors">
                View Saved Jobs
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}