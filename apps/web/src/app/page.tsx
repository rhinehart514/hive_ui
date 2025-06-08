'use client'

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@hive/ui-core';
import { useAuth } from '@/context/AuthContext';
import { PublicRoute } from '@/components/auth/AuthGuard';
import { ArrowRight } from 'lucide-react';

export default function HomePage() {
  const router = useRouter();
  const { user, profile, loading } = useAuth();

  // Redirect authenticated users to feed
  useEffect(() => {
    if (!loading && user && profile?.onboardingCompleted) {
      router.push('/feed');
    }
  }, [user, profile, loading, router]);

  // Show loading state while checking auth
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

  return (
    <PublicRoute>
      <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center relative overflow-hidden">
        {/* Design System Button - Fixed Position */}
        <Link 
          href="/design-system-test"
          className="fixed top-6 right-6 z-50 bg-primary hover:bg-primary/90 text-primary-foreground px-4 py-2 rounded-lg font-medium transition-all duration-200 hover:scale-105"
        >
          🎨 Design System Test
        </Link>
        
        {/* Tech background elements */}
        <div className="absolute inset-0 bg-dots-pattern opacity-30" />
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/5 to-transparent rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/3 to-transparent rounded-full blur-3xl" />
        
        <div className="text-center relative z-10 max-w-4xl mx-auto px-4">
          <h1 className="text-9xl font-black text-white tracking-tight mb-6 tech-slide-up">
            HIVE
          </h1>
          <div className="w-6 h-6 bg-[#FFD700] rounded-full mx-auto tech-pulse shadow-tech-glow mb-8" />
          
          <p className="text-white/80 text-2xl mb-4 font-light tracking-wide">
            The Future of Campus Life
          </p>
          <p className="text-white/60 text-lg mb-12 max-w-2xl mx-auto">
            Connect with your University at Buffalo community through intelligent Spaces, 
            Events, and custom Tools. Join the vBETA and shape the future.
          </p>
          
          <div className="flex flex-col sm:flex-row items-center gap-4">
            <Link href="/auth/signup">
              <Button size="lg" className="w-full sm:w-auto">
                Get Started
                <ArrowRight className="ml-2 h-5 w-5" />
              </Button>
            </Link>
            <Link href="/design-system-test">
              <Button size="lg" variant="secondary" className="w-full sm:w-auto">
                View Design System
              </Button>
            </Link>
          </div>
          
          <p className="text-white/40 text-sm mt-8">
            Currently available for University at Buffalo students
          </p>
        </div>
      </div>
    </PublicRoute>
  );
} 