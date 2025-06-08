'use client'

import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useRouter } from 'next/navigation'
import { Button } from '@hive/ui-core'
import { Card, CardContent } from '@/components/ui/card'
import { PartiallyProtectedRoute } from '@/components/auth/AuthGuard'
import { useAuth } from '@/context/AuthContext'
import { updateUserProfile } from '@/lib/auth'
import { 
  ArrowLeft, 
  ArrowRight,
  Users, 
  Calendar, 
  Wrench,
  Zap,
  CheckCircle,
  Play
} from 'lucide-react'

interface TutorialStep {
  id: string
  title: string
  description: string
  icon: React.ReactNode
  content: React.ReactNode
}

const tutorialSteps: TutorialStep[] = [
  {
    id: 'welcome',
    title: 'Welcome to HIVE',
    description: 'Building the future of campus life',
    icon: <Zap className="w-8 h-8 text-[#FFD700]" />,
    content: (
      <div className="space-y-4 text-center">
        <div className="w-20 h-20 bg-[#FFD700]/20 rounded-full flex items-center justify-center mx-auto">
          <Zap className="w-10 h-10 text-[#FFD700]" />
        </div>
        <h3 className="text-white text-2xl font-semibold">
          Welcome to HIVE vBETA
        </h3>
        <p className="text-white/70 text-lg leading-relaxed max-w-md mx-auto">
          You're now part of University at Buffalo's most connected community. 
          Let's show you how to make the most of your HIVE experience.
        </p>
      </div>
    ),
  },
  {
    id: 'spaces',
    title: 'Discover Your Spaces',
    description: 'Find your communities',
    icon: <Users className="w-8 h-8 text-[#FFD700]" />,
    content: (
      <div className="space-y-4">
        <div className="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center mx-auto">
          <Users className="w-8 h-8 text-blue-400" />
        </div>
        <h3 className="text-white text-xl font-semibold text-center">
          Spaces Connect You
        </h3>
        <p className="text-white/70 leading-relaxed">
          Spaces are where your campus communities live. Whether it's your residence hall, 
          academic department, or student organizations - Spaces help you coordinate with 
          the people who matter most.
        </p>
        <div className="bg-white/5 rounded-lg p-4 space-y-3">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-[#FFD700]/20 rounded-full flex items-center justify-center">
              <Users className="w-4 h-4 text-[#FFD700]" />
            </div>
            <div>
              <div className="text-white font-medium text-sm">CS Students</div>
              <div className="text-white/60 text-xs">456 members</div>
            </div>
          </div>
          <p className="text-white/60 text-sm">
            Stay connected with your major, share resources, and coordinate study sessions.
          </p>
        </div>
      </div>
    ),
  },
  {
    id: 'events',
    title: 'Never Miss Events',
    description: 'Stay in the loop',
    icon: <Calendar className="w-8 h-8 text-[#FFD700]" />,
    content: (
      <div className="space-y-4">
        <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mx-auto">
          <Calendar className="w-8 h-8 text-green-400" />
        </div>
        <h3 className="text-white text-xl font-semibold text-center">
          Campus Events, Unified
        </h3>
        <p className="text-white/70 leading-relaxed">
          HIVE automatically pulls events from across campus and lets your Spaces add their own. 
          RSVP, see who's going, and never miss what matters to you.
        </p>
        <div className="bg-white/5 rounded-lg p-4 space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-white font-medium text-sm">CS Club Hackathon</div>
              <div className="text-white/60 text-xs">Tomorrow, 6:00 PM</div>
            </div>
            <div className="text-[#FFD700] text-xs font-medium">24 going</div>
          </div>
          <Button size="sm" variant="accent" className="w-full">
            <Calendar className="w-3 h-3 mr-1" />
            RSVP
          </Button>
        </div>
      </div>
    ),
  },
  {
    id: 'tools',
    title: 'Build Custom Tools',
    description: 'Shape your community',
    icon: <Wrench className="w-8 h-8 text-[#FFD700]" />,
    content: (
      <div className="space-y-4">
        <div className="w-16 h-16 bg-purple-500/20 rounded-full flex items-center justify-center mx-auto">
          <Wrench className="w-8 h-8 text-purple-400" />
        </div>
        <h3 className="text-white text-xl font-semibold text-center">
          Tools for Every Need
        </h3>
        <p className="text-white/70 leading-relaxed">
          As a student leader, you can create custom Tools to solve your community's 
          unique challenges. Polls, resource boards, attendance trackers - if you can 
          imagine it, you can build it.
        </p>
        <div className="bg-white/5 rounded-lg p-4 space-y-3">
          <div className="text-white font-medium text-sm">HiveLAB Tool Composer</div>
          <div className="grid grid-cols-3 gap-2">
            <div className="bg-white/10 rounded px-2 py-1 text-xs text-center">Poll</div>
            <div className="bg-white/10 rounded px-2 py-1 text-xs text-center">Text</div>
            <div className="bg-white/10 rounded px-2 py-1 text-xs text-center">Button</div>
          </div>
          <p className="text-white/60 text-xs">
            Drag and drop Elements to create Tools your community will love.
          </p>
        </div>
      </div>
    ),
  },
  {
    id: 'ready',
    title: "You're Ready!",
    description: 'Start exploring',
    icon: <CheckCircle className="w-8 h-8 text-[#FFD700]" />,
    content: (
      <div className="space-y-4 text-center">
        <div className="w-20 h-20 bg-green-500/20 rounded-full flex items-center justify-center mx-auto">
          <CheckCircle className="w-10 h-10 text-green-400" />
        </div>
        <h3 className="text-white text-2xl font-semibold">
          You're All Set!
        </h3>
        <p className="text-white/70 text-lg leading-relaxed max-w-md mx-auto">
          Welcome to HIVE vBETA. You're now part of building the future of campus life 
          at University at Buffalo. Let's explore your new community.
        </p>
        <div className="bg-[#FFD700]/10 border border-[#FFD700]/20 rounded-lg p-4 mt-6">
          <p className="text-[#FFD700] text-sm font-medium">
            🎉 vBETA Pioneer
          </p>
          <p className="text-white/70 text-xs mt-1">
            You're among the first students to experience HIVE. Your feedback shapes the future!
          </p>
        </div>
      </div>
    ),
  },
]

export default function TutorialPage() {
  const router = useRouter()
  const { user, profile, refreshProfile } = useAuth()
  const [currentStep, setCurrentStep] = useState(0)
  const [isCompleting, setIsCompleting] = useState(false)

  const handleNext = () => {
    if (currentStep < tutorialSteps.length - 1) {
      setCurrentStep(currentStep + 1)
    }
  }

  const handlePrevious = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1)
    }
  }

  const handleComplete = async () => {
    if (!user || !profile) return

    setIsCompleting(true)
    
    try {
      // Mark tutorial as completed
      await updateUserProfile(user.uid, {
        tutorialCompleted: true,
      })

      // Refresh profile to update local state
      await refreshProfile()

      // Navigate to main app
      router.push('/feed')
    } catch (error) {
      console.error('Error completing tutorial:', error)
      // Still navigate if there's an error
      router.push('/feed')
    } finally {
      setIsCompleting(false)
    }
  }

  const handleSkip = async () => {
    if (!user || !profile) return
    await handleComplete()
  }

  const isLastStep = currentStep === tutorialSteps.length - 1
  const currentStepData = tutorialSteps[currentStep]

  return (
    <PartiallyProtectedRoute>
      <div className="min-h-screen bg-[#0A0A0A] relative overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0 bg-dots-pattern opacity-10" />
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/5 to-transparent rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/3 to-transparent rounded-full blur-3xl" />
        
        {/* Skip Button */}
        <button
          onClick={handleSkip}
          className="absolute top-6 right-6 z-10 text-white/60 hover:text-white transition-colors text-sm"
        >
          Skip tutorial
        </button>

        <div className="relative z-10 min-h-screen flex items-center justify-center p-4">
          <div className="w-full max-w-lg">
            {/* Progress Indicator */}
            <div className="mb-8">
              <div className="flex justify-center space-x-2 mb-4">
                {tutorialSteps.map((_, index) => (
                  <div
                    key={index}
                    className={`w-2 h-2 rounded-full transition-all duration-300 ${
                      index <= currentStep 
                        ? 'bg-[#FFD700]' 
                        : 'bg-white/20'
                    }`}
                  />
                ))}
              </div>
              <p className="text-center text-white/60 text-sm">
                {currentStep + 1} of {tutorialSteps.length}
              </p>
            </div>

            {/* Tutorial Content */}
            <AnimatePresence mode="wait">
              <motion.div
                key={currentStep}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.3 }}
              >
                <Card className="bg-[#111]/80 border-white/10 backdrop-blur-sm">
                  <CardContent className="p-8">
                    {currentStepData.content}
                  </CardContent>
                </Card>
              </motion.div>
            </AnimatePresence>

            {/* Navigation */}
            <div className="flex items-center justify-between mt-8">
              <Button
                variant="ghost"
                size="sm"
                onClick={handlePrevious}
                disabled={currentStep === 0}
                className="opacity-60 hover:opacity-100"
              >
                <ArrowLeft className="w-4 h-4 mr-2" />
                Previous
              </Button>

              {isLastStep ? (
                <Button
                  variant="accent"
                  onClick={handleComplete}
                  disabled={isCompleting}
                  className="px-8"
                >
                  {isCompleting ? (
                    <>
                      <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin mr-2" />
                      Setting up...
                    </>
                  ) : (
                    <>
                      <Play className="w-4 h-4 mr-2" />
                      Let's go!
                    </>
                  )}
                </Button>
              ) : (
                <Button
                  variant="accent"
                  onClick={handleNext}
                >
                  Next
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>
    </PartiallyProtectedRoute>
  )
} 