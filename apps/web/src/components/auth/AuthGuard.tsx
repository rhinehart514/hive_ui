'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { getRedirectPath } from '@/lib/auth';

interface AuthGuardProps {
  children: React.ReactNode;
  requireAuth?: boolean;
  requireEmailVerification?: boolean;
  requireOnboarding?: boolean;
  redirectTo?: string;
  fallback?: React.ReactNode;
}

export default function AuthGuard({ 
  children, 
  requireAuth = true,
  requireEmailVerification = true,
  requireOnboarding = true,
  redirectTo,
  fallback 
}: AuthGuardProps) {
  const { user, profile, loading, isAuthenticated } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (loading) return; // Wait for auth state to load

    // Handle non-authenticated users
    if (requireAuth && !isAuthenticated) {
      const currentPath = window.location.pathname;
      const signInUrl = `/auth/signin${currentPath !== '/' ? `?redirect=${encodeURIComponent(currentPath)}` : ''}`;
      router.push(signInUrl);
      return;
    }

    // Handle redirects for authenticated users who shouldn't be on auth pages
    if (isAuthenticated && window.location.pathname.startsWith('/auth/signin')) {
      router.push(redirectTo || getRedirectPath(user, profile));
      return;
    }

    // Handle specific requirements
    if (requireAuth && user) {
      // Email not verified - redirect to verification
      if (requireEmailVerification && !user.emailVerified) {
        router.push('/auth/verify-email');
        return;
      }

      // Profile not loaded or onboarding not completed
      if (requireOnboarding && (!profile || !profile.onboardingCompleted)) {
        router.push('/auth/profile-setup');
        return;
      }

      // Tutorial not completed
      if (profile && !profile.tutorialCompleted && window.location.pathname !== '/auth/tutorial') {
        router.push('/auth/tutorial');
        return;
      }
    }
  }, [user, profile, loading, router, requireAuth, requireEmailVerification, requireOnboarding, redirectTo, isAuthenticated]);

  // Show loading state
  if (loading) {
    return fallback || (
      <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-2 border-[#FFD700]/20 border-t-[#FFD700] rounded-full animate-spin mx-auto" />
          <p className="text-white/60 text-[14px]">Loading...</p>
        </div>
      </div>
    );
  }

  // Don't render children until all checks pass
  if (requireAuth) {
    if (!isAuthenticated || 
        (requireEmailVerification && !user?.emailVerified) ||
        !profile ||
        (requireOnboarding && !profile.onboardingCompleted)) {
      return fallback || null;
    }
  }

  return <>{children}</>;
}

// Convenience components for common use cases
export function PublicRoute({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard requireAuth={false} requireEmailVerification={false} requireOnboarding={false}>
      {children}
    </AuthGuard>
  );
}

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard requireAuth={true} requireEmailVerification={true} requireOnboarding={true}>
      {children}
    </AuthGuard>
  );
}

export function PartiallyProtectedRoute({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard requireAuth={true} requireEmailVerification={false} requireOnboarding={false}>
      {children}
    </AuthGuard>
  );
} 