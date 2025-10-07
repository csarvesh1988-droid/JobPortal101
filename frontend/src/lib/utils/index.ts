import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

// Utility for merging Tailwind classes
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Format currency
export function formatCurrency(amount: number, currency = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount)
}

// Format salary range
export function formatSalaryRange(
  min?: number, 
  max?: number, 
  currency = 'USD'
): string {
  if (!min && !max) return 'Salary not disclosed'
  if (min && max) {
    return `${formatCurrency(min, currency)} - ${formatCurrency(max, currency)}`
  }
  if (min) return `From ${formatCurrency(min, currency)}`
  if (max) return `Up to ${formatCurrency(max, currency)}`
  return 'Salary not disclosed'
}

// Format date
export function formatDate(date: string | Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long', 
    day: 'numeric',
  }).format(new Date(date))
}

// Format relative time
export function formatRelativeTime(date: string | Date): string {
  const now = new Date()
  const targetDate = new Date(date)
  const diffInMs = now.getTime() - targetDate.getTime()
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
  
  if (diffInDays === 0) return 'Today'
  if (diffInDays === 1) return 'Yesterday'
  if (diffInDays < 7) return `${diffInDays} days ago`
  if (diffInDays < 30) return `${Math.floor(diffInDays / 7)} weeks ago`
  if (diffInDays < 365) return `${Math.floor(diffInDays / 30)} months ago`
  return `${Math.floor(diffInDays / 365)} years ago`
}

// Truncate text
export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength).trim() + '...'
}

// Generate slug from title
export function generateSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}

// Validate email
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// Format file size
export function formatFileSize(bytes: number): string {
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  if (bytes === 0) return '0 Bytes'
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i]
}

// Debounce function
export function debounce<T extends (...args: any[]) => void>(
  func: T,
  delay: number
): T {
  let timeoutId: NodeJS.Timeout
  return ((...args: any[]) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => func.apply(null, args), delay)
  }) as T
}

// Local storage helpers
export const storage = {
  get: (key: string) => {
    if (typeof window === 'undefined') return null
    try {
      const item = localStorage.getItem(key)
      return item ? JSON.parse(item) : null
    } catch {
      return null
    }
  },
  
  set: (key: string, value: any) => {
    if (typeof window === 'undefined') return
    try {
      localStorage.setItem(key, JSON.stringify(value))
    } catch {
      // Handle quota exceeded or other errors
    }
  },
  
  remove: (key: string) => {
    if (typeof window === 'undefined') return
    localStorage.removeItem(key)
  },
}

// URL helpers
export function buildSearchParams(params: Record<string, any>): URLSearchParams {
  const searchParams = new URLSearchParams()
  
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      if (Array.isArray(value)) {
        value.forEach(item => searchParams.append(key, item.toString()))
      } else {
        searchParams.append(key, value.toString())
      }
    }
  })
  
  return searchParams
}

// Experience level formatting
export function formatExperienceLevel(level: string): string {
  const levels = {
    'entry': 'Entry Level',
    'junior': 'Junior',
    'mid': 'Mid Level', 
    'senior': 'Senior',
    'lead': 'Lead',
    'executive': 'Executive'
  }
  return levels[level as keyof typeof levels] || level
}

// Job type formatting
export function formatJobType(type: string): string {
  const types = {
    'full-time': 'Full Time',
    'part-time': 'Part Time',
    'contract': 'Contract',
    'internship': 'Internship',
    'freelance': 'Freelance'
  }
  return types[type as keyof typeof types] || type
}

// Points formatting
export function formatPoints(points: number): string {
  return new Intl.NumberFormat('en-US').format(points)
}

// Application status formatting
export function formatApplicationStatus(status: string): {
  label: string
  color: string
} {
  const statusMap = {
    'submitted': { label: 'Submitted', color: 'blue' },
    'reviewing': { label: 'Under Review', color: 'yellow' },
    'shortlisted': { label: 'Shortlisted', color: 'green' },
    'interview-scheduled': { label: 'Interview Scheduled', color: 'purple' },
    'interviewed': { label: 'Interviewed', color: 'indigo' },
    'offer-extended': { label: 'Offer Extended', color: 'green' },
    'hired': { label: 'Hired', color: 'green' },
    'rejected': { label: 'Rejected', color: 'red' },
    'withdrawn': { label: 'Withdrawn', color: 'gray' },
  }
  
  return statusMap[status as keyof typeof statusMap] || {
    label: status,
    color: 'gray'
  }
}