/** @type {import('next').NextConfig} */
const nextConfig = {
  // Performance optimizations for high concurrency
  compress: true,
  poweredByHeader: false,
  
  // Image optimization
  images: {
    formats: ['image/webp', 'image/avif'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    domains: ['localhost', 'your-domain.com'], // Add your production domains
    minimumCacheTTL: 60 * 60 * 24 * 7, // 1 week cache
  },

  // Experimental features for performance
  experimental: {
    // Enable App Router optimizations
    appDir: true,
    
    // Runtime optimizations
    serverComponentsExternalPackages: ['@prisma/client'],
    
    // ISR improvements
    isrMemoryCacheSize: 0, // Disable in-memory cache for serverless
  },

  // API routes optimization
  api: {
    responseLimit: '8mb',
  },

  // Static optimization
  trailingSlash: false,
  
  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ]
  },

  // Redirects for SEO
  async redirects() {
    return [
      {
        source: '/job/:slug',
        destination: '/jobs/:slug',
        permanent: true,
      },
      {
        source: '/company/:slug',
        destination: '/companies/:slug', 
        permanent: true,
      },
    ]
  },

  // Rewrites for API routing
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.NEXT_PUBLIC_API_URL}/api/:path*`,
      },
    ]
  },

  // Bundle analyzer for optimization
  webpack: (config, { dev, isServer }) => {
    // Optimize bundle size
    if (!dev && !isServer) {
      config.resolve.alias = {
        ...config.resolve.alias,
        '@': './src',
      }
    }

    return config
  },
}