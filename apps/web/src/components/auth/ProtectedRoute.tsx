'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requireEmailVerification?: boolean;
  requireOnboarding?: boolean;
}

export default function ProtectedRoute({ 
  children, 
  requireEmailVerification = true,
  requireOnboarding = true 
}: ProtectedRouteProps) {
  const { user, profile, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (loading) return; // Wait for auth state to load

    // Not authenticated - redirect to signin
    if (!user) {
      router.push('/auth/signin');
      return;
    }

    // Email not verified - redirect to verification
    if (requireEmailVerification && !user.emailVerified) {
      router.push('/auth/verify-email');
      return;
    }

    // Profile not loaded yet
    if (!profile) {
      return;
    }

    // Onboarding not completed - redirect to profile setup
    if (requireOnboarding && !profile.onboardingCompleted) {
      router.push('/auth/profile-setup');
      return;
    }
  }, [user, profile, loading, router, requireEmailVerification, requireOnboarding]);

  // Show loading state
  if (loading) {
    return (
      <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-2 border-[#FFD700]/20 border-t-[#FFD700] rounded-full animate-spin mx-auto" />
          <p className="text-white/60 text-[14px]">Loading...</p>
        </div>
      </div>
    );
  }

  // Don't render children until all checks pass
  if (!user || 
      (requireEmailVerification && !user.emailVerified) ||
      !profile ||
      (requireOnboarding && !profile.onboardingCompleted)) {
    return null;
  }

  return <>{children}</>;
} 