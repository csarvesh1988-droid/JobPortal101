'use client'

import { useAuth } from '@/lib/auth/useAuth'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'
import { DashboardSidebar } from '@/components/dashboard/DashboardSidebar'
import { DashboardHeader } from '@/components/dashboard/DashboardHeader'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !user) {
      router.push('/auth/login')
    }
  }, [user, loading, router])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!user) {
    return null // Redirecting...
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <DashboardHeader user={user} />
      
      <div className="flex">
        <DashboardSidebar user={user} />
        
        <main className="flex-1 p-8">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}