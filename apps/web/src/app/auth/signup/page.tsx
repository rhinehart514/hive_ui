'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@hive/ui-core';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { UB_MAJORS, ACADEMIC_YEARS, RESIDENCE_OPTIONS } from '@/lib/constants/ub-data';
import type { UBMajor, AcademicYear, ResidenceOption } from '@/lib/constants/ub-data';
import { signUp } from '@/lib/auth';

interface SignupFormData {
  email: string;
  password: string;
  confirmPassword: string;
  fullName: string;
  major: UBMajor | '';
  academicYear: AcademicYear | '';
  residentialStatus: ResidenceOption | '';
}

interface FormErrors {
  email?: string;
  password?: string;
  confirmPassword?: string;
  fullName?: string;
  major?: string;
  academicYear?: string;
  residentialStatus?: string;
}

export default function SignupPage() {
  const router = useRouter();
  const [currentStep, setCurrentStep] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState<SignupFormData>({
    email: '',
    password: '',
    confirmPassword: '',
    fullName: '',
    major: '',
    academicYear: '',
    residentialStatus: ''
  });
  const [errors, setErrors] = useState<FormErrors>({});

  const validateEmail = (email: string): string | undefined => {
    if (!email) return 'Email is required';
    if (!email.includes('@')) return 'Please enter a valid email address';
    
    const domain = email.split('@')[1]?.toLowerCase();
    if (!domain?.endsWith('buffalo.edu')) {
      return 'Please use your UB .edu email address';
    }
    
    return undefined;
  };

  const validatePassword = (password: string): string | undefined => {
    if (!password) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return undefined;
  };

  const validateStep1 = (): boolean => {
    const newErrors: FormErrors = {};
    
    newErrors.email = validateEmail(formData.email);
    newErrors.password = validatePassword(formData.password);
    
    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const validateStep2 = (): boolean => {
    const newErrors: FormErrors = {};
    
    if (!formData.fullName.trim()) {
      newErrors.fullName = 'Full name is required';
    }
    
    if (!formData.major) {
      newErrors.major = 'Please select your major';
    }
    
    if (!formData.academicYear) {
      newErrors.academicYear = 'Please select your academic year';
    }
    
    if (!formData.residentialStatus) {
      newErrors.residentialStatus = 'Please select your residential status';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNext = () => {
    if (currentStep === 1 && validateStep1()) {
      setCurrentStep(2);
    } else if (currentStep === 2 && validateStep2()) {
      handleSubmit();
    }
  };

  const handleSubmit = async () => {
    setIsLoading(true);
    
    try {
      // Create account with Firebase
      const signUpData = {
        email: formData.email,
        password: formData.password,
        fullName: formData.fullName,
        major: formData.major,
        academicYear: formData.academicYear,
        residentialStatus: formData.residentialStatus
      };

      await signUp(signUpData);
      
      // Navigate to email verification
      router.push('/auth/verify-email');
    } catch (error) {
      console.error('Signup error:', error);
      setErrors({ email: error instanceof Error ? error.message : 'An error occurred. Please try again.' });
    } finally {
      setIsLoading(false);
    }
  };

  const updateFormData = (field: keyof SignupFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }));
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A] relative overflow-hidden">
      {/* Dynamic Background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-dots-pattern opacity-10" />
        
        {/* Subtle ambient lighting */}
        <motion.div
          className="absolute w-96 h-96 bg-gradient-radial from-white/2 to-transparent rounded-full blur-3xl"
          animate={{
            scale: [1, 1.1, 1],
            opacity: [0.3, 0.5, 0.3],
          }}
          transition={{
            duration: 6,
            repeat: Infinity,
            ease: "easeInOut",
          }}
          style={{ left: '5%', top: '15%' }}
        />
        
        <motion.div
          className="absolute w-80 h-80 bg-gradient-radial from-white/1 to-transparent rounded-full blur-3xl"
          animate={{
            scale: [1.1, 1, 1.1],
            opacity: [0.2, 0.4, 0.2],
          }}
          transition={{
            duration: 7,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 2,
          }}
          style={{ right: '5%', bottom: '15%' }}
        />
        
        {/* Floating elements */}
        {Array.from({ length: 8 }).map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 bg-[#FFD700]/40 rounded-full"
            animate={{
              y: [0, -30, 0],
              opacity: [0.2, 0.8, 0.2],
              scale: [1, 1.5, 1],
            }}
            transition={{
              duration: 3 + i * 0.3,
              repeat: Infinity,
              ease: "easeInOut",
              delay: i * 0.4,
            }}
            style={{
              left: `${15 + i * 10}%`,
              top: `${30 + (i % 2) * 40}%`,
            }}
          />
        ))}
      </div>
      
      <div className="relative z-10 min-h-screen flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, y: 30, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ 
            duration: 0.6,
            ease: [0.25, 0.8, 0.30, 1],
            scale: { duration: 0.4 }
          }}
          className="w-full max-w-md"
        >
          <motion.div
            whileHover={{ 
              scale: 1.02,
              boxShadow: "0 20px 40px rgba(255, 215, 0, 0.1)"
            }}
            transition={{ type: "spring", damping: 20, stiffness: 300 }}
          >
            <Card className="relative overflow-hidden border-white/10 bg-[#111]/80 backdrop-blur-sm">
            <CardHeader className="text-center">
              <CardTitle className="text-white text-[28px] font-semibold">
                {currentStep === 1 ? 'Create Your Account' : 'Complete Your Profile'}
              </CardTitle>
              <p className="text-white/70 text-[16px] mt-2">
                {currentStep === 1 
                  ? 'Join HIVE at University at Buffalo'
                  : 'Tell us about yourself'
                }
              </p>
              
              {/* Progress Indicator */}
              <div className="flex justify-center mt-4">
                <div className="flex space-x-3">
                  {[1, 2].map((step) => (
                    <motion.div
                      key={step}
                      className="relative"
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ delay: step * 0.1, type: "spring", damping: 15 }}
                    >
                      <motion.div
                        className={`w-3 h-3 rounded-full ${
                          currentStep >= step ? 'bg-[#FFD700]' : 'bg-[#1A1A1A]'
                        }`}
                        animate={{
                          scale: currentStep === step ? [1, 1.3, 1] : 1,
                          boxShadow: currentStep >= step 
                            ? "0 0 10px rgba(255, 215, 0, 0.5)" 
                            : "none"
                        }}
                        transition={{ 
                          scale: { duration: 0.6, ease: "easeInOut" },
                          boxShadow: { duration: 0.3 }
                        }}
                      />
                      
                      {/* Ripple effect for active step */}
                      {currentStep === step && (
                        <motion.div
                          className="absolute inset-0 rounded-full border-2 border-[#FFD700]/30"
                          initial={{ scale: 1, opacity: 1 }}
                          animate={{ scale: 2, opacity: 0 }}
                          transition={{ duration: 1.5, repeat: Infinity }}
                        />
                      )}
                    </motion.div>
                  ))}
                </div>
              </div>
            </CardHeader>
            
            <CardContent className="space-y-6">
              <AnimatePresence mode="wait">
                {currentStep === 1 ? (
                  <motion.div
                    key="step1"
                    initial={{ opacity: 0, x: 30, scale: 0.95 }}
                    animate={{ opacity: 1, x: 0, scale: 1 }}
                    exit={{ opacity: 0, x: -30, scale: 1.05 }}
                    transition={{ 
                      duration: 0.4,
                      ease: [0.25, 0.8, 0.30, 1]
                    }}
                    className="space-y-4"
                  >
                  <div>
                    <Input
                      type="email"
                      placeholder="your.email@buffalo.edu"
                      value={formData.email}
                      onChange={(e) => updateFormData('email', e.target.value)}
                      error={errors.email}
                    />
                  </div>
                  
                  <div>
                    <Input
                      type="password"
                      placeholder="Password (8+ characters)"
                      value={formData.password}
                      onChange={(e) => updateFormData('password', e.target.value)}
                      error={errors.password}
                    />
                  </div>
                  
                  <div>
                    <Input
                      type="password"
                      placeholder="Confirm password"
                      value={formData.confirmPassword}
                      onChange={(e) => updateFormData('confirmPassword', e.target.value)}
                      error={errors.confirmPassword}
                    />
                  </div>
                </motion.div>
                              ) : (
                  <motion.div
                    key="step2"
                    initial={{ opacity: 0, x: 30, scale: 0.95 }}
                    animate={{ opacity: 1, x: 0, scale: 1 }}
                    exit={{ opacity: 0, x: -30, scale: 1.05 }}
                    transition={{ 
                      duration: 0.4,
                      ease: [0.25, 0.8, 0.30, 1]
                    }}
                    className="space-y-4"
                  >
                  <div>
                    <Input
                      type="text"
                      placeholder="Full Name"
                      value={formData.fullName}
                      onChange={(e) => updateFormData('fullName', e.target.value)}
                      error={errors.fullName}
                    />
                  </div>
                  
                  <div>
                    <select
                      className="w-full px-3 py-2 bg-surface-2 border border-[var(--c-border)] rounded-input text-high focus:border-accent focus:outline-none"
                      value={formData.major}
                      onChange={(e) => updateFormData('major', e.target.value)}
                    >
                      <option value="">Select your major</option>
                      {UB_MAJORS.map((major) => (
                        <option key={major} value={major}>{major}</option>
                      ))}
                    </select>
                    {errors.major && (
                      <p className="text-error text-sm mt-1">{errors.major}</p>
                    )}
                  </div>
                  
                  <div>
                    <select
                      className="w-full px-3 py-2 bg-surface-2 border border-[var(--c-border)] rounded-input text-high focus:border-accent focus:outline-none"
                      value={formData.academicYear}
                      onChange={(e) => updateFormData('academicYear', e.target.value)}
                    >
                      <option value="">Select your year</option>
                      {ACADEMIC_YEARS.map((year) => (
                        <option key={year} value={year}>{year}</option>
                      ))}
                    </select>
                    {errors.academicYear && (
                      <p className="text-error text-sm mt-1">{errors.academicYear}</p>
                    )}
                  </div>
                  
                  <div>
                    <select
                      className="w-full px-3 py-2 bg-surface-2 border border-[var(--c-border)] rounded-input text-high focus:border-accent focus:outline-none"
                      value={formData.residentialStatus}
                      onChange={(e) => updateFormData('residentialStatus', e.target.value)}
                    >
                      <option value="">Select your housing</option>
                      {RESIDENCE_OPTIONS.map((residence) => (
                        <option key={residence} value={residence}>{residence}</option>
                      ))}
                    </select>
                    {errors.residentialStatus && (
                      <p className="text-error text-sm mt-1">{errors.residentialStatus}</p>
                    )}
                  </div>
                                  </motion.div>
                )}
              </AnimatePresence>
              
              <motion.div 
                className="flex gap-3"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
              >
                {currentStep === 2 && (
                  <Button
                    variant="outline"
                    onClick={() => setCurrentStep(1)}
                    className="flex-1"
                  >
                    Back
                  </Button>
                )}
                
                <Button
                  onClick={handleNext}
                  disabled={isLoading}
                  className="flex-1"
                  glow
                >
                  {isLoading ? 'Creating Account...' : currentStep === 1 ? 'Next' : 'Create Account'}
                </Button>
              </motion.div>
              
              <div className="text-center">
                <p className="text-sm text-low">
                  Already have an account?{' '}
                  <Link href="/auth/signin" className="text-accent hover:text-[var(--c-accent-hover)]">
                    Sign in
                  </Link>
                </p>
              </div>
            </CardContent>
            
            {/* Subtle animated border */}
            <motion.div
              className="absolute inset-0 rounded-card border border-accent/20 pointer-events-none"
              initial={{ opacity: 0 }}
              animate={{ opacity: [0, 0.5, 0] }}
              transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
            />
          </Card>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
} 