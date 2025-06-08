'use client'

import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@hive/ui-core'
import { Input } from '@/components/ui/input'
import { HiveCard, HiveCardContent, HiveCardHeader, HiveCardTitle } from '@/components/ui/card'
import { signIn } from '@/lib/auth'
import { useAuth } from '@/context/AuthContext'

interface SigninFormData {
  email: string
  password: string
}

interface FormErrors {
  email?: string
  password?: string
  general?: string
}

export default function SigninPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { user, profile, loading: authLoading } = useAuth()
  const [isLoading, setIsLoading] = useState(false)
  const [formData, setFormData] = useState<SigninFormData>({
    email: '',
    password: ''
  })
  const [errors, setErrors] = useState<FormErrors>({})

  // Get redirect path from URL params
  const redirectPath = searchParams.get('redirect') || '/feed'

  // Redirect if already authenticated
  useEffect(() => {
    if (!authLoading && user && profile?.onboardingCompleted) {
      router.push(redirectPath)
    }
  }, [user, profile, authLoading, router, redirectPath])

  const validateEmail = (email: string): string | undefined => {
    if (!email) return 'Email is required'
    if (!email.includes('@')) return 'Please enter a valid email address'
    return undefined
  }

  const validatePassword = (password: string): string | undefined => {
    if (!password) return 'Password is required'
    return undefined
  }

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {}
    
    newErrors.email = validateEmail(formData.email)
    newErrors.password = validatePassword(formData.password)
    
    setErrors(newErrors)
    return Object.values(newErrors).every(error => !error)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!validateForm()) return
    
    setIsLoading(true)
    setErrors({})
    
    try {
      // Sign in with Firebase
      await signIn(formData.email, formData.password)
      
      // Redirect will be handled by AuthContext
      // But we can also explicitly redirect to the desired path
      router.push(redirectPath)
    } catch (error) {
      console.error('Signin error:', error)
      setErrors({ general: error instanceof Error ? error.message : 'Invalid email or password. Please try again.' })
    } finally {
      setIsLoading(false)
    }
  }

  const updateFormData = (field: keyof SigninFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }))
    }
    if (errors.general) {
      setErrors(prev => ({ ...prev, general: undefined }))
    }
  }

  // Show loading state while checking auth
  if (authLoading) {
    return (
      <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-2 border-[#FFD700]/20 border-t-[#FFD700] rounded-full animate-spin mx-auto" />
          <p className="text-white/60 text-[14px]">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#0A0A0A] relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-dots-pattern opacity-10" />
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/5 to-transparent rounded-full blur-3xl" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/3 to-transparent rounded-full blur-3xl" />
      
      <div className="relative z-10 min-h-screen flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="w-full max-w-md"
        >
          <HiveCard className="bg-card/80 border-border/50 backdrop-blur-sm">
            <HiveCardHeader className="text-center">
              <HiveCardTitle className="text-2xl font-semibold">
                Welcome Back
              </HiveCardTitle>
              <p className="text-muted-foreground mt-2">
                Sign in to your HIVE account
              </p>
              {redirectPath !== '/feed' && (
                <p className="text-primary text-sm mt-1">
                  You'll be redirected to your requested page after signing in
                </p>
              )}
            </HiveCardHeader>
            
            <HiveCardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                {errors.general && (
                  <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-3">
                    <p className="text-destructive text-sm">{errors.general}</p>
                  </div>
                )}
                
                <div className="space-y-4">
                  <div>
                    <Input
                      type="email"
                      placeholder="your.email@buffalo.edu"
                      value={formData.email}
                      onChange={(e) => updateFormData('email', e.target.value)}
                      error={errors.email}
                      autoComplete="email"
                      disabled={isLoading}
                    />
                  </div>
                  
                  <div>
                    <Input
                      type="password"
                      placeholder="Password"
                      value={formData.password}
                      onChange={(e) => updateFormData('password', e.target.value)}
                      error={errors.password}
                      autoComplete="current-password"
                      disabled={isLoading}
                    />
                  </div>
                </div>
                
                <div className="flex items-center justify-between">
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      className="w-4 h-4 text-[#FFD700] bg-[#1A1A1A] border-white/20 rounded focus:ring-[#FFD700] focus:ring-2"
                      disabled={isLoading}
                    />
                    <span className="ml-2 text-sm text-white/60">Remember me</span>
                  </label>
                  
                  <Link 
                    href="/auth/forgot-password" 
                    className="text-sm text-[#FFD700] hover:text-[#FFDF2B] transition-colors"
                  >
                    Forgot password?
                  </Link>
                </div>
                
                <Button
                  type="submit"
                  disabled={isLoading}
                  className="w-full"
                  variant="primary"
                >
                  {isLoading ? 'Signing in...' : 'Sign In'}
                </Button>
              </form>
              
              <div className="mt-6 text-center">
                <p className="text-sm text-muted-foreground">
                  Don't have an account?{' '}
                  <Link 
                    href="/auth/signup" 
                    className="text-primary hover:text-primary/90 transition-colors"
                  >
                    Sign up
                  </Link>
                </p>
              </div>
            </HiveCardContent>
          </HiveCard>
        </motion.div>
      </div>
    </div>
  )
} 




