'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { Button } from '@hive/ui-core';
import { Card, CardContent } from '@/components/ui/card';
import { Mail, RefreshCw, CheckCircle, ExternalLink } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import { resendEmailVerification } from '@/lib/auth';

export default function VerifyEmailPage() {
  const router = useRouter();
  const { user, refreshProfile } = useAuth();
  const [isResending, setIsResending] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);
  const [verificationChecking, setVerificationChecking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Redirect if no user or already verified
  useEffect(() => {
    if (!user) {
      router.push('/auth/signin');
      return;
    }

    if (user.emailVerified) {
      router.push('/auth/profile-setup');
      return;
    }
  }, [user, router]);

  // Auto-check verification status every 5 seconds
  useEffect(() => {
    if (!user || user.emailVerified) return;

    const checkVerification = async () => {
      setVerificationChecking(true);
      try {
        await user.reload();
        if (user.emailVerified) {
          await refreshProfile();
          router.push('/auth/profile-setup');
        }
      } catch (error) {
        console.error('Error checking verification:', error);
      } finally {
        setVerificationChecking(false);
      }
    };

    const interval = setInterval(checkVerification, 5000);
    return () => clearInterval(interval);
  }, [user, refreshProfile, router]);

  // Resend cooldown timer
  useEffect(() => {
    if (resendCooldown > 0) {
      const timer = setTimeout(() => setResendCooldown(resendCooldown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [resendCooldown]);

  const handleResendEmail = async () => {
    if (resendCooldown > 0) return;

    setIsResending(true);
    setError(null);

    try {
      await resendEmailVerification();
      setResendCooldown(60); // 60 second cooldown
    } catch (error) {
      console.error('Resend error:', error);
      setError(error instanceof Error ? error.message : 'Failed to resend email');
    } finally {
      setIsResending(false);
    }
  };

  const handleOpenEmailApp = () => {
    // Try to open common email apps
    const emailDomain = user?.email?.split('@')[1];
    const emailUrls = {
      'gmail.com': 'https://mail.google.com',
      'buffalo.edu': 'https://mail.google.com', // UB uses Gmail
      'student.buffalo.edu': 'https://mail.google.com',
      'outlook.com': 'https://outlook.live.com',
      'hotmail.com': 'https://outlook.live.com',
      'yahoo.com': 'https://mail.yahoo.com'
    };

    const emailUrl = emailDomain ? emailUrls[emailDomain as keyof typeof emailUrls] : 'https://mail.google.com';
    window.open(emailUrl, '_blank');
  };

  const handleManualRefresh = async () => {
    if (!user) return;

    setVerificationChecking(true);
    try {
      await user.reload();
      if (user.emailVerified) {
        await refreshProfile();
        router.push('/auth/profile-setup');
      } else {
        setError('Email not verified yet. Please check your email and click the verification link.');
      }
    } catch (error) {
      console.error('Manual refresh error:', error);
      setError('Failed to check verification status. Please try again.');
    } finally {
      setVerificationChecking(false);
    }
  };

  if (!user) {
    return null; // Will redirect
  }

  return (
    <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center p-8">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-md space-y-8"
      >
        {/* Header */}
        <div className="text-center space-y-6">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="flex justify-center"
          >
            <div className="w-20 h-20 bg-[#FFD700]/10 rounded-full flex items-center justify-center">
              <Mail className="w-10 h-10 text-[#FFD700]" />
            </div>
          </motion.div>
          
          <div className="space-y-2">
            <h1 className="text-white text-[34px] font-semibold">
              Check your email
            </h1>
            <p className="text-white/70 text-[17px] leading-relaxed">
              We sent a verification link to:
            </p>
            <div className="bg-white/5 rounded-lg px-4 py-2 inline-block">
              <p className="text-[#FFD700] text-[16px] font-medium">
                {user.email}
              </p>
            </div>
          </div>
        </div>

        {/* Info Card */}
        <Card className="bg-white/5 border-white/10">
          <CardContent className="p-6 space-y-6">
            <div className="text-center space-y-4">
              <div className="space-y-2">
                <p className="text-white/80 text-[15px] leading-relaxed">
                  This helps us keep HIVE campus-only and secure.
                </p>
                <p className="text-white/60 text-[14px] leading-relaxed">
                  Check your inbox (and spam folder) for our verification email. 
                  Click the link to continue setting up your account.
                </p>
              </div>

              {/* Auto-checking indicator */}
              {verificationChecking && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="flex items-center justify-center space-x-2 text-[#FFD700] text-sm"
                >
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  <span>Checking verification status...</span>
                </motion.div>
              )}
            </div>

            {/* Action Buttons */}
            <div className="space-y-4">
              <Button
                onClick={handleOpenEmailApp}
                variant="accent"
                className="w-full"
              >
                <ExternalLink className="w-4 h-4 mr-2" />
                Open Email App
              </Button>

              <div className="flex space-x-3">
                <Button
                  onClick={handleResendEmail}
                  variant="secondary"
                  className="flex-1"
                  disabled={isResending || resendCooldown > 0}
                >
                  {isResending ? (
                    <>
                      <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                      Sending...
                    </>
                  ) : resendCooldown > 0 ? (
                    `Resend in ${resendCooldown}s`
                  ) : (
                    'Resend Email'
                  )}
                </Button>

                <Button
                  onClick={handleManualRefresh}
                  variant="ghost"
                  className="flex-1"
                  disabled={verificationChecking}
                >
                  {verificationChecking ? (
                    <RefreshCw className="w-4 h-4 animate-spin" />
                  ) : (
                    'Refresh'
                  )}
                </Button>
              </div>
            </div>

            {/* Error Display */}
            {error && (
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-[#FF3B30]/10 border border-[#FF3B30]/20 rounded-lg p-3"
              >
                <p className="text-[#FF3B30] text-sm text-center">{error}</p>
              </motion.div>
            )}

            {/* Help Text */}
            <div className="text-center space-y-2">
              <p className="text-white/40 text-[12px]">
                Didn't receive an email? Check your spam folder or{' '}
                <button
                  onClick={handleResendEmail}
                  disabled={resendCooldown > 0}
                  className="text-[#FFD700] hover:text-[#FFD700]/80 underline"
                >
                  request a new one
                </button>
              </p>
              
              <p className="text-white/40 text-[12px]">
                Wrong email?{' '}
                <button
                  onClick={() => router.push('/auth/signup')}
                  className="text-[#FFD700] hover:text-[#FFD700]/80 underline"
                >
                  Start over
                </button>
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Auto-refresh notice */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1 }}
          className="text-center"
        >
          <p className="text-white/40 text-[12px] flex items-center justify-center space-x-1">
            <CheckCircle className="w-3 h-3" />
            <span>Auto-checking for verification every 5 seconds</span>
          </p>
        </motion.div>
      </motion.div>
    </div>
  );
} 