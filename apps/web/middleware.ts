import { NextRequest, NextResponse } from 'next/server';
import {
  authMiddleware,
  AuthMiddlewareConfig,
} from 'next-firebase-auth-edge';
import { getTokens } from 'next-firebase-auth-edge/lib/next/tokens';

const PROTECTED_PATHS = ['/dashboard', '/profile', '/spaces'];

const config: AuthMiddlewareConfig = {
  loginPath: '/auth/login',
  logoutPath: '/auth/logout',
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY!,
  cookieName: 'AuthToken',
  cookieSignatureKeys: [process.env.COOKIE_SIGNATURE_KEY_A!, process.env.COOKIE_SIGNATURE_KEY_B!],
  cookieSerializeOptions: {
    path: '/',
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 12 * 60 * 60 * 24, // 12 days
  },
  serviceAccount: {
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID!,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
    privateKey: process.env.FIREBASE_PRIVATE_KEY!,
  },
};

export async function middleware(request: NextRequest) {
  return authMiddleware(request, {
    ...config,
    // After a successful login, redirect to the dashboard
    handleValidToken: async ({ token, decodedToken }, headers) => {
      if (request.nextUrl.pathname === config.loginPath) {
        return NextResponse.redirect(new URL('/dashboard', request.url));
      }
      return NextResponse.next({
        request: {
          headers,
        },
      });
    },
    // If the token is invalid or expired, refresh it
    handleInvalidToken: async (error) => {
      console.log('Invalid token', error);
      try {
        const { idToken } = await getTokens(request.cookies, config);
        // This will throw if the refresh token is invalid
        const newDecodedToken = await config.authentication.verifyIdToken(idToken!);
        
        // If successful, a new cookie will be set in the response
        return NextResponse.next();
      } catch (e) {
        console.log('Failed to refresh token', e);
        return NextResponse.redirect(new URL(config.loginPath, request.url));
      }
    },
    // If there is no token and the path is protected, redirect to login
    handleIncompleteToken: async () => {
      if (PROTECTED_PATHS.some(p => request.nextUrl.pathname.startsWith(p))) {
        return NextResponse.redirect(new URL(config.loginPath, request.url));
      }
      return NextResponse.next();
    },
  });
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}; 