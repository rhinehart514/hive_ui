'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { Button } from '@hive/ui-core';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { MapPin, ArrowLeft, CheckCircle } from 'lucide-react';

interface WaitlistData {
  schoolName: string;
  email: string;
  graduationYear: string;
}

export default function SchoolSelectionPage() {
  const router = useRouter();
  const [showWaitlist, setShowWaitlist] = useState(false);
  const [waitlistData, setWaitlistData] = useState<WaitlistData>({
    schoolName: '',
    email: '',
    graduationYear: '2025'
  });
  const [isSubmittingWaitlist, setIsSubmittingWaitlist] = useState(false);
  const [waitlistSubmitted, setWaitlistSubmitted] = useState(false);

  const handleSelectUB = () => {
    router.push('/auth/signup');
  };

  const handleShowWaitlist = () => {
    setShowWaitlist(true);
  };

  const handleBackToSelection = () => {
    setShowWaitlist(false);
    setWaitlistSubmitted(false);
  };

  const handleWaitlistSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmittingWaitlist(true);

    try {
      // TODO: Implement actual waitlist submission to Firebase
      console.log('Waitlist submission:', waitlistData);
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setWaitlistSubmitted(true);
    } catch (error) {
      console.error('Waitlist submission error:', error);
    } finally {
      setIsSubmittingWaitlist(false);
    }
  };

  const graduationYears = ['2025', '2026', '2027', '2028', 'Graduate Student'];

  if (waitlistSubmitted) {
    return (
      <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center p-8">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5 }}
          className="text-center space-y-6 max-w-md"
        >
          <div className="flex justify-center">
            <CheckCircle className="w-16 h-16 text-[#8CE563]" />
          </div>
          
          <h1 className="text-white text-[28px] font-semibold">
            You're on the waitlist!
          </h1>
          
          <p className="text-white/70 text-[17px] leading-relaxed">
            We'll let you know when HIVE arrives at {waitlistData.schoolName}. 
            Thanks for your interest in building the future of campus life!
          </p>
          
          <Button
            onClick={() => router.push('/')}
            variant="secondary"
            className="mt-8"
          >
            Back to Home
          </Button>
        </motion.div>
      </div>
    );
  }

  if (showWaitlist) {
    return (
      <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center p-8">
        <motion.div
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5 }}
          className="w-full max-w-md space-y-8"
        >
          {/* Header */}
          <div className="text-center space-y-4">
            <Button
              onClick={handleBackToSelection}
              variant="ghost"
              size="sm"
              className="mb-4 text-white/60 hover:text-white"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back
            </Button>
            
            <h1 className="text-white text-[34px] font-semibold">
              Join the waitlist
            </h1>
            <p className="text-white/70 text-[17px]">
              We're expanding to new campuses regularly. Be the first to know 
              when HIVE arrives at your school.
            </p>
          </div>

          {/* Waitlist Form */}
          <Card className="bg-white/5 border-white/10">
            <CardContent className="p-6">
              <form onSubmit={handleWaitlistSubmit} className="space-y-6">
                <div>
                  <label htmlFor="schoolName" className="block text-white text-sm font-medium mb-2">
                    School Name
                  </label>
                  <Input
                    id="schoolName"
                    type="text"
                    value={waitlistData.schoolName}
                    onChange={(e) => setWaitlistData(prev => ({ ...prev, schoolName: e.target.value }))}
                    placeholder="e.g., Cornell University"
                    required
                    className="bg-white/5 border-white/20 text-white placeholder:text-white/40"
                  />
                </div>

                <div>
                  <label htmlFor="email" className="block text-white text-sm font-medium mb-2">
                    Email Address
                  </label>
                  <Input
                    id="email"
                    type="email"
                    value={waitlistData.email}
                    onChange={(e) => setWaitlistData(prev => ({ ...prev, email: e.target.value }))}
                    placeholder="your.email@student.edu"
                    required
                    className="bg-white/5 border-white/20 text-white placeholder:text-white/40"
                  />
                </div>

                <div>
                  <label htmlFor="graduationYear" className="block text-white text-sm font-medium mb-2">
                    Expected Graduation
                  </label>
                  <select
                    id="graduationYear"
                    value={waitlistData.graduationYear}
                    onChange={(e) => setWaitlistData(prev => ({ ...prev, graduationYear: e.target.value }))}
                    className="w-full bg-white/5 border border-white/20 rounded-lg px-3 py-2 text-white"
                  >
                    {graduationYears.map(year => (
                      <option key={year} value={year} className="bg-[#1E1E1E] text-white">
                        {year}
                      </option>
                    ))}
                  </select>
                </div>

                <Button
                  type="submit"
                  variant="accent"
                  className="w-full"
                  disabled={isSubmittingWaitlist}
                >
                  {isSubmittingWaitlist ? 'Joining waitlist...' : 'Join Waitlist'}
                </Button>
              </form>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center p-8">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-2xl space-y-8"
      >
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-white text-[34px] font-semibold">
            Choose your school
          </h1>
          <p className="text-white/70 text-[17px] max-w-md mx-auto">
            HIVE is launching at select universities. Join the movement at your campus.
          </p>
        </div>

        {/* University at Buffalo Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          <Card 
            className="bg-gradient-to-br from-white/8 to-white/4 border-white/10 hover:border-[#FFD700]/30 transition-all duration-300 cursor-pointer group"
            onClick={handleSelectUB}
          >
            <CardContent className="p-8">
              <div className="flex items-start justify-between">
                <div className="space-y-4 flex-1">
                  <div className="space-y-2">
                    <h2 className="text-white text-[22px] font-semibold group-hover:text-[#FFD700] transition-colors">
                      University at Buffalo
                    </h2>
                    <div className="flex items-center text-white/60 text-[14px]">
                      <MapPin className="w-4 h-4 mr-1" />
                      Buffalo, NY
                    </div>
                  </div>
                  
                  <Badge variant="accent" className="bg-[#FFD700]/20 text-[#FFD700] border-[#FFD700]/30">
                    Ready for HIVE
                  </Badge>
                  
                  <p className="text-white/60 text-[15px] leading-relaxed">
                    Join thousands of UB students already building the future of campus life.
                  </p>
                </div>
                
                <div className="ml-6 opacity-60 group-hover:opacity-100 transition-opacity">
                  <div className="w-16 h-16 bg-[#003875]/20 rounded-lg flex items-center justify-center">
                    <span className="text-[#003875] font-bold text-lg">UB</span>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Waitlist Option */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="text-center"
        >
          <Button
            onClick={handleShowWaitlist}
            variant="ghost"
            className="text-white/60 hover:text-white hover:bg-white/5"
          >
            My school isn't listed
          </Button>
          <p className="text-white/40 text-[14px] mt-2">
            Join the waitlist for your campus
          </p>
        </motion.div>
      </motion.div>
    </div>
  );
} 