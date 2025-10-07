import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { AuthProvider } from '@/lib/auth/AuthProvider'
import { Toaster } from '@/components/ui/toast'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: {
    template: '%s | JobPortal101',
    default: 'JobPortal101 - Find Your Dream Job',
  },
  description: 'Discover thousands of job opportunities with our advanced matching system and rewards program.',
  keywords: ['jobs', 'careers', 'recruitment', 'hiring', 'employment'],
  authors: [{ name: 'JobPortal101' }],
  creator: 'JobPortal101',
  publisher: 'JobPortal101',
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'),
  
  // Open Graph
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: process.env.NEXT_PUBLIC_SITE_URL,
    siteName: 'JobPortal101',
    title: 'JobPortal101 - Find Your Dream Job',
    description: 'Discover thousands of job opportunities with our advanced matching system and rewards program.',
    images: [
      {
        url: '/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'JobPortal101 - Professional Job Portal',
      },
    ],
  },
  
  // Twitter
  twitter: {
    card: 'summary_large_image',
    site: process.env.NEXT_PUBLIC_TWITTER_HANDLE,
    creator: process.env.NEXT_PUBLIC_TWITTER_HANDLE,
    title: 'JobPortal101 - Find Your Dream Job',
    description: 'Discover thousands of job opportunities with our advanced matching system and rewards program.',
    images: ['/twitter-image.jpg'],
  },
  
  // Additional metadata
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  
  // Icons
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon-16x16.png',
    apple: '/apple-touch-icon.png',
  },
  
  // Manifest for PWA
  manifest: '/manifest.json',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="h-full">
      <body className={`${inter.className} h-full antialiased`}>
        <div className="min-h-full">
          {children}
        </div>
        
        {/* Service Worker Registration for PWA */}
        {process.env.NEXT_PUBLIC_ENABLE_PWA === 'true' && (
          <script
            dangerouslySetInnerHTML={{
              __html: `
                if ('serviceWorker' in navigator) {
                  navigator.serviceWorker.register('/sw.js')
                    .then((registration) => {
                      console.log('SW registered: ', registration);
                    })
                    .catch((registrationError) => {
                      console.log('SW registration failed: ', registrationError);
                    });
                }
              `,
            }}
          />
        )}
      </body>
    </html>
  )
}
