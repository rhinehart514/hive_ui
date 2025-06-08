'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { Button } from '@hive/ui-core';

const WELCOME_STEPS = [
  {
    title: "Welcome to HIVE",
    subtitle: "The future of campus life",
    description: "Connect with your University at Buffalo community through intelligent Spaces, Events, and custom Tools.",
    action: "Continue"
  },
  {
    title: "Spaces That Live",
    subtitle: "Dynamic communities",
    description: "Join student organizations, campus living communities, and interest groups that adapt to your engagement.",
    action: "Next"
  },
  {
    title: "Events That Matter",
    subtitle: "Curated for you",
    description: "Discover campus events, activities, and opportunities tailored to your interests and academic journey.",
    action: "Next"
  },
  {
    title: "Tools You Build",
    subtitle: "Shape your experience",
    description: "Create custom tools for your communities. Polls, resource boards, study trackers - built by students, for students.",
    action: "Get Started"
  }
];

export default function WelcomePage() {
  const router = useRouter();
  const [currentStep, setCurrentStep] = useState(0);
  const [isAnimating, setIsAnimating] = useState(false);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  const handleNext = () => {
    if (isAnimating) return;
    
    setIsAnimating(true);
    
    if (currentStep < WELCOME_STEPS.length - 1) {
      setTimeout(() => {
        setCurrentStep(prev => prev + 1);
        setIsAnimating(false);
      }, 300);
    } else {
      // Navigate to signup
      router.push('/auth/signup');
    }
  };

  const currentWelcome = WELCOME_STEPS[currentStep];

  return (
    <div className="min-h-screen bg-[#0A0A0A] relative overflow-hidden">
      {/* Dynamic Background */}
      <div className="absolute inset-0">
        {/* Noise texture */}
        <div className="absolute inset-0 bg-noise opacity-20" />
        
        {/* Subtle ambient lighting */}
        <motion.div
          className="absolute w-96 h-96 bg-gradient-radial from-white/2 to-transparent rounded-full blur-3xl"
          animate={{
            x: mousePosition.x * 0.01,
            y: mousePosition.y * 0.01,
            scale: [1, 1.1, 1],
          }}
          transition={{ 
            x: { type: "spring", damping: 50, stiffness: 100 },
            y: { type: "spring", damping: 50, stiffness: 100 },
            scale: { duration: 8, repeat: Infinity, ease: "easeInOut" }
          }}
          style={{
            left: '10%',
            top: '15%',
          }}
        />
        
        <motion.div
          className="absolute w-80 h-80 bg-gradient-radial from-white/1 to-transparent rounded-full blur-3xl"
          animate={{
            x: mousePosition.x * -0.005,
            y: mousePosition.y * -0.005,
            scale: [1.2, 1, 1.2],
          }}
          transition={{ 
            x: { type: "spring", damping: 60, stiffness: 80 },
            y: { type: "spring", damping: 60, stiffness: 80 },
            scale: { duration: 10, repeat: Infinity, ease: "easeInOut", delay: 2 }
          }}
          style={{
            right: '15%',
            bottom: '20%',
          }}
        />
        
        {/* Floating particles */}
        {Array.from({ length: 12 }).map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 bg-[#FFD700]/30 rounded-full"
            animate={{
              y: [0, -20, 0],
              opacity: [0.3, 0.8, 0.3],
            }}
            transition={{
              duration: 3 + i * 0.5,
              repeat: Infinity,
              ease: "easeInOut",
              delay: i * 0.2,
            }}
            style={{
              left: `${10 + i * 7}%`,
              top: `${20 + (i % 3) * 20}%`,
            }}
          />
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 min-h-screen flex items-center justify-center p-4">
        <div className="w-full max-w-2xl text-center">
          {/* Progress Indicator */}
          <div className="mb-12">
            <div className="flex justify-center space-x-2 mb-4">
              {WELCOME_STEPS.map((_, index) => (
                <motion.div
                  key={index}
                  className={`h-1 rounded-full ${
                    index <= currentStep ? 'bg-[#FFD700]' : 'bg-[#1A1A1A]'
                  }`}
                  initial={{ width: 20 }}
                  animate={{ 
                    width: index === currentStep ? 40 : 20,
                    backgroundColor: index <= currentStep ? '#FFD700' : '#1A1A1A'
                  }}
                  transition={{ duration: 0.3, ease: "easeOut" }}
                />
              ))}
            </div>
            <motion.p 
              className="text-sm text-white/60"
              key={`progress-${currentStep}`}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.2 }}
            >
              {currentStep + 1} of {WELCOME_STEPS.length}
            </motion.p>
          </div>

          {/* Main Content */}
          <AnimatePresence mode="wait">
            <motion.div
              key={currentStep}
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -20, scale: 1.05 }}
              transition={{ 
                duration: 0.4, 
                ease: [0.25, 0.8, 0.30, 1],
                scale: { duration: 0.3 }
              }}
              className="space-y-8"
            >
              {/* Icon/Visual */}
              <motion.div
                className="w-24 h-24 mx-auto mb-8 relative"
                whileHover={{ scale: 1.05 }}
                transition={{ type: "spring", damping: 15 }}
              >
                <div className="w-full h-full bg-gradient-to-br from-[#FFD700]/20 to-[#FFD700]/5 rounded-lg flex items-center justify-center relative overflow-hidden">
                  {/* Animated background */}
                  <motion.div
                    className="absolute inset-0 bg-gradient-to-r from-transparent via-[#FFD700]/10 to-transparent"
                    animate={{ x: [-100, 100] }}
                    transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                  />
                  
                  {/* Step-specific icons */}
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: 0.3, type: "spring", damping: 10 }}
                    className="text-[#FFD700] text-3xl relative z-10"
                  >
                    {currentStep === 0 && '🏛️'}
                    {currentStep === 1 && '🏠'}
                    {currentStep === 2 && '📅'}
                    {currentStep === 3 && '🛠️'}
                  </motion.div>
                </div>
              </motion.div>

              {/* Text Content */}
              <div className="space-y-4">
                <motion.h1 
                  className="text-4xl md:text-5xl font-semibold text-white"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1 }}
                >
                  {currentWelcome.title}
                </motion.h1>
                
                <motion.p 
                  className="text-xl text-[#FFD700] font-medium"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.2 }}
                >
                  {currentWelcome.subtitle}
                </motion.p>
                
                <motion.p 
                  className="text-lg text-white/70 max-w-xl mx-auto leading-relaxed"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                >
                  {currentWelcome.description}
                </motion.p>
              </div>

              {/* Action Button */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="pt-8"
              >
                <Button
                  size="lg"
                  glow
                  onClick={handleNext}
                  disabled={isAnimating}
                  className="px-12 py-4 text-lg relative overflow-hidden group"
                >
                  {/* Button shimmer effect */}
                  <motion.div
                    className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent"
                    animate={{ x: [-100, 300] }}
                    transition={{ 
                      duration: 2, 
                      repeat: Infinity, 
                      ease: "linear",
                      repeatDelay: 3 
                    }}
                  />
                  
                  <span className="relative z-10">
                    {isAnimating ? 'Loading...' : currentWelcome.action}
                  </span>
                </Button>
              </motion.div>
            </motion.div>
          </AnimatePresence>

          {/* Skip Option */}
          <motion.div
            className="mt-12"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1 }}
          >
            <button
              onClick={() => router.push('/auth/signup')}
              className="text-sm text-white/60 hover:text-white transition-colors duration-200"
            >
              Skip introduction
            </button>
          </motion.div>
        </div>
      </div>

      {/* Ambient Sound Trigger (Visual Only) */}
      <motion.div
        className="fixed bottom-6 right-6 w-12 h-12 bg-[#111]/50 backdrop-blur-sm rounded-full flex items-center justify-center cursor-pointer"
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.95 }}
        initial={{ opacity: 0, scale: 0 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 2 }}
      >
        <motion.div
          className="w-2 h-2 bg-[#FFD700] rounded-full"
          animate={{ scale: [1, 1.5, 1] }}
          transition={{ duration: 2, repeat: Infinity }}
        />
      </motion.div>
    </div>
  );
} 





