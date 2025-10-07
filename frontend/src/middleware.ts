import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { jwtVerify } from 'jose'

// Paths that require authentication
const protectedPaths = ['/dashboard', '/recruiter', '/admin']
// Admin-only paths
const adminPaths = ['/admin']
// Recruiter paths
const recruiterPaths = ['/recruiter']

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  
  // Check if path requires authentication
  const isProtectedPath = protectedPaths.some(path => pathname.startsWith(path))
  
  if (!isProtectedPath) {
    return NextResponse.next()
  }

  // Get token from cookies
  const token = request.cookies.get('auth-token')?.value

  if (!token) {
    // Redirect to login with return URL
    const loginUrl = new URL('/auth/login', request.url)
    loginUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(loginUrl)
  }

  try {
    // Verify JWT token
    const secret = new TextEncoder().encode(process.env.JWT_SECRET || 'fallback-secret')
    const { payload } = await jwtVerify(token, secret)
    
    const userRole = payload.role as string
    const userId = payload.sub as string

    // Check admin access
    if (adminPaths.some(path => pathname.startsWith(path))) {
      if (userRole !== 'admin') {
        return NextResponse.redirect(new URL('/dashboard', request.url))
      }
    }

    // Check recruiter access
    if (recruiterPaths.some(path => pathname.startsWith(path))) {
      if (userRole !== 'recruiter' && userRole !== 'admin') {
        return NextResponse.redirect(new URL('/dashboard', request.url))
      }
    }

    // Add user info to request headers for API routes
    const requestHeaders = new Headers(request.headers)
    requestHeaders.set('x-user-id', userId)
    requestHeaders.set('x-user-role', userRole)

    return NextResponse.next({
      request: {
        headers: requestHeaders,
      },
    })
  } catch (error) {
    // Invalid token - redirect to login
    const loginUrl = new URL('/auth/login', request.url)
    loginUrl.searchParams.set('redirect', pathname)
    
    // Clear invalid token
    const response = NextResponse.redirect(loginUrl)
    response.cookies.delete('auth-token')
    
    return response
  }
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public assets
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}