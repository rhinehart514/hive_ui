import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Define public routes that don't require authentication
const publicRoutes = [
  '/',
  '/auth/signin',
  '/auth/signup',
  '/auth/welcome',
  '/auth/forgot-password',
  '/auth/verify-email',
  '/auth/school-selection',
  '/design-system',
  '/api', // Allow all API routes
]

// Routes that require authentication
const protectedRoutes = [
  '/feed',
  '/spaces',
  '/profile',
  '/auth/profile-setup',
  '/auth/onboarding',
  '/auth/tutorial',
  '/modular-system',
]

// Routes that should redirect authenticated users away
const authRoutes = [
  '/auth/signin',
  '/auth/signup',
  '/auth/welcome',
]

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  
  // Allow static files and API routes
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.includes('.') ||
    pathname.startsWith('/static')
  ) {
    return NextResponse.next()
  }

  // Get the authentication token from cookies
  const authToken = request.cookies.get('__session')?.value || 
                   request.cookies.get('firebase-auth-token')?.value

  const isAuthenticated = !!authToken
  // Clean pathname (remove trailing slash for matching)
  const cleanPathname = pathname.endsWith('/') && pathname !== '/' ? pathname.slice(0, -1) : pathname
  const isPublicRoute = publicRoutes.includes(cleanPathname) || 
                       publicRoutes.some(route => cleanPathname.startsWith(route))
  const isProtectedRoute = protectedRoutes.some(route => cleanPathname.startsWith(route))
  const isAuthRoute = authRoutes.includes(cleanPathname)

  // Redirect authenticated users away from auth pages
  if (isAuthenticated && isAuthRoute) {
    return NextResponse.redirect(new URL('/feed', request.url))
  }

  // Redirect unauthenticated users to sign in
  if (!isAuthenticated && isProtectedRoute) {
    const signInUrl = new URL('/auth/signin', request.url)
    signInUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(signInUrl)
  }

  // Allow the request to continue
  return NextResponse.next()
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public (public files)
     */
    '/((?!_next/static|_next/image|favicon.ico|public).*)',
  ],
} 