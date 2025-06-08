'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { Button } from '@hive/ui-core';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { 
  User, 
  GraduationCap, 
  Home, 
  Crown, 
  Search,
  ChevronDown,
  Check,
  ArrowRight,
  Building2,
  Users
} from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import { updateUserProfile } from '@/lib/auth';

// UB Data from mobile app
const UB_MAJORS = [
  // UNDERGRADUATE PROGRAMS
  'Accounting BS', 'Aerospace Engineering BS', 'African-American Studies BA', 'American Studies BA',
  'Anthropology BA', 'Architecture BS', 'Art History BA', 'Asian Studies BA', 'Biochemistry BS',
  'Bioinformatics and Computational Biology BS', 'Biological Sciences BA', 'Biological Sciences BS',
  'Biomedical Engineering BS', 'Biomedical Sciences BS', 'Biotechnology BS', 'Business Administration BS',
  'Chemical Engineering BS', 'Chemistry BA', 'Chemistry BS', 'Civil Engineering BS', 'Classics BA',
  'Cognitive Science BA', 'Communication BA', 'Computational Linguistics BS', 'Computational Physics BS',
  'Computer Engineering BS', 'Computer Science BA', 'Computer Science BS', 'Criminology BA',
  'Dance BA', 'Dance BFA', 'Economics BA', 'Economics BS', 'Electrical Engineering BS',
  'Engineering Physics BS', 'Engineering Science BS', 'English BA', 'Environmental Design BA',
  'Environmental Engineering BS', 'Environmental Science BS', 'Environmental Studies BS',
  'Environmental Sustainability BA', 'Exercise Science BS', 'Film Studies BA', 'Fine Arts BFA',
  'French BA', 'Geographic Information Science BS', 'Geography BA', 'Geological Sciences BA',
  'Geological Sciences BS', 'German BA', 'Global Affairs BA', 'Global Gender Studies BA',
  'Health and Human Services BA', 'History BA', 'Indigenous Studies BA', 'Industrial Engineering BS',
  'Information Technology and Management BS', 'International Studies BA', 'International Trade BA',
  'Italian BA', 'Jewish Studies BA', 'Law BA', 'Legal Studies BA', 'Linguistics BA',
  'Material Science and Engineering BS', 'Mathematical Physics BS', 'Mathematics BA', 'Mathematics BS',
  'Mathematics-Economics BA', 'Mechanical Engineering BS', 'Media Study BA', 'Medical Laboratory Science BS',
  'Medicinal Chemistry BS', 'Music BA', 'Music Performance BMus', 'Music Theatre BFA',
  'Neuroscience BS', 'Nuclear Medicine Technology BS', 'Nursing BS', 'Nutrition Science BS',
  'Occupational Therapy BS', 'Pharmaceutical Sciences BS', 'Pharmacology and Toxicology BS',
  'Pharmacy PharmD', 'Philosophy BA', 'Philosophy, Politics and Economics BA', 'Physics BA',
  'Physics BS', 'Political Science BA', 'Psychology BA', 'Psychology BS', 'Public Health BS',
  'Sociology BA', 'Spanish BA', 'Special Studies BA', 'Special Studies BS', 'Speech and Hearing Science BA',
  'Statistics BA', 'Studio Art BA', 'Theatre BA', 'Theatre BFA', 'Urban and Public Policy Studies BA',
  
  // MASTERS PROGRAMS
  'Accounting MS', 'Adult/Gerontology Nurse Practitioner DNP', 'Aerospace Engineering MS',
  'American Studies MA', 'Anthropology MA', 'Architecture MArch', 'Arts Management MA',
  'Athletic Training MS', 'Biochemistry MA', 'Bioinformatics and Biostatistics MS',
  'Biological Sciences MA', 'Biological Sciences MS', 'Biomedical Engineering MS',
  'Biomedical Informatics MS', 'Biophysics MS', 'Biostatistics MA', 'Biotechnology MS',
  'Business Administration MBA', 'Business Analytics MS', 'Cancer Sciences MS',
  'Chemical Engineering MS', 'Chemistry MS', 'Civil Engineering MS', 'Classics MA',
  'Clinical Nutrition MS', 'Communication MA', 'Communicative Disorders and Sciences MA',
  'Computer Science and Engineering MS', 'Economics MA', 'Electrical Engineering MS',
  'Engineering Science MS', 'English MA', 'Environmental Health Sciences MS',
  'Epidemiology MS', 'Exercise Science MS', 'Finance MS', 'Fine Arts MFA',
  'Geography MS', 'Geological Sciences MS', 'Global Affairs MA', 'History MA',
  'Industrial Engineering MS', 'Information and Library Science MS', 'Law LLM',
  'Linguistics MA', 'Mathematics MA', 'Mechanical Engineering MS', 'Media Arts and Sciences MS',
  'Medical Physics MS', 'Medicinal Chemistry MS', 'Mental Health Counseling MS',
  'Music Performance MM', 'Neuroscience MS', 'Nutrition MS', 'Occupational Therapy MS',
  'Pharmaceutical Sciences MS', 'Philosophy MA', 'Physics MS', 'Political Science MA',
  'Psychology MA', 'Public Health MPH', 'Rehabilitation Science MS', 'Social Work MSW',
  
  // PHD PROGRAMS
  'American Studies PhD', 'Anthropology PhD', 'Biological Sciences PhD', 'Biophysics PhD',
  'Biostatistics PhD', 'Chemistry PhD', 'Classics PhD', 'Comparative Literature PhD',
  'English PhD', 'Geography PhD', 'History PhD', 'Linguistics PhD', 'Mathematics PhD',
  'Philosophy PhD', 'Physics PhD', 'Political Science PhD', 'Psychology PhD',
  'Sociology PhD', 'Aerospace Engineering PhD', 'Biomedical Engineering PhD',
  'Chemical Engineering PhD', 'Civil Engineering PhD', 'Electrical Engineering PhD',
  'Industrial Engineering PhD', 'Mechanical Engineering PhD', 'Engineering Science PhD',
  'Business Administration PhD', 'Biomedical Sciences PhD', 'Nursing PhD',
  'Pharmaceutical Sciences PhD', 'Epidemiology PhD', 'Nutrition Science PhD'
];

const YEAR_OPTIONS = [
  'Freshman',
  'Sophomore', 
  'Junior',
  'Senior',
  'Masters',
  'PhD',
  'Non-Degree Seeking'
];

const RESIDENCE_OPTIONS = [
  'Ellicott',
  'Governors', 
  'Greiner',
  'On Campus Apartments',
  'Commuter'
];

const SPACE_TYPES = [
  'Student Organization',
  'University Organization', 
  'Campus Living',
  'Academic Department',
  'Greek Life',
  'Sports Team',
  'Cultural Group',
  'Professional Society',
  'Service Organization',
  'Special Interest'
];

interface ProfileData {
  firstName: string;
  lastName: string;
  major: string;
  year: string;
  residence: string;
  isStudentLeader: boolean;
  leadershipRole?: string;
  spaceName?: string;
  spaceType?: string;
  requestBuilderAccess?: boolean;
}

export default function ProfileSetupPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [currentStep, setCurrentStep] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // Form data
  const [profileData, setProfileData] = useState<ProfileData>({
    firstName: '',
    lastName: '',
    major: '',
    year: '',
    residence: '',
    isStudentLeader: false
  });

  // Search states
  const [majorSearch, setMajorSearch] = useState('');
  const [showMajorDropdown, setShowMajorDropdown] = useState(false);
  const [filteredMajors, setFilteredMajors] = useState(UB_MAJORS);

  // Redirect if no user
  useEffect(() => {
    if (!user) {
      router.push('/auth/signin');
      return;
    }

    if (!user.emailVerified) {
      router.push('/auth/verify-email');
      return;
    }
  }, [user, router]);

  // Filter majors based on search
  useEffect(() => {
    if (majorSearch.trim() === '') {
      setFilteredMajors(UB_MAJORS);
    } else {
      const filtered = UB_MAJORS.filter(major =>
        major.toLowerCase().includes(majorSearch.toLowerCase())
      );
      setFilteredMajors(filtered);
    }
  }, [majorSearch]);

  const updateProfileData = (updates: Partial<ProfileData>) => {
    setProfileData(prev => ({ ...prev, ...updates }));
  };

  const canProceedToNext = () => {
    switch (currentStep) {
      case 0: // Name
        return profileData.firstName.trim() && profileData.lastName.trim();
      case 1: // Academic info
        return profileData.major && profileData.year && profileData.residence;
      case 2: // Leadership check
        return true; // Always can proceed from leadership question
      case 3: // Builder request (only if student leader)
        return !profileData.isStudentLeader || 
               (profileData.leadershipRole && profileData.spaceName && profileData.spaceType);
      default:
        return false;
    }
  };

  const handleNext = () => {
    if (!canProceedToNext()) return;
    
    if (currentStep === 2 && !profileData.isStudentLeader) {
      // Skip builder request step if not a student leader
      handleSubmit();
    } else if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
    } else {
      handleSubmit();
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSubmit = async () => {
    setIsSubmitting(true);
    setError(null);

    try {
      if (!user) throw new Error('No user found');

      // Save profile data to Firebase
      const profileUpdates = {
        fullName: `${profileData.firstName} ${profileData.lastName}`,
        major: profileData.major,
        academicYear: profileData.year,
        residentialStatus: profileData.residence,
        onboardingCompleted: true,
        // Add builder request data if applicable
        ...(profileData.isStudentLeader && {
          leadershipRole: profileData.leadershipRole,
          spaceName: profileData.spaceName,
          spaceType: profileData.spaceType,
          requestBuilderAccess: true
        })
      };

      await updateUserProfile(user.uid, profileUpdates);
      
      // Navigate to main app
      router.push('/feed');
    } catch (error) {
      console.error('Profile setup error:', error);
      setError(error instanceof Error ? error.message : 'Failed to save profile. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const selectMajor = (major: string) => {
    updateProfileData({ major });
    setMajorSearch(major);
    setShowMajorDropdown(false);
  };

  if (!user) {
    return null; // Will redirect
  }

  const totalSteps = profileData.isStudentLeader ? 4 : 3;
  const progress = ((currentStep + 1) / totalSteps) * 100;

  return (
    <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center p-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-lg space-y-8"
      >
        {/* Header */}
        <div className="text-center space-y-4">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="flex justify-center"
          >
            <div className="w-16 h-16 bg-[#FFD700]/10 rounded-full flex items-center justify-center">
              <User className="w-8 h-8 text-[#FFD700]" />
            </div>
          </motion.div>
          
          <div className="space-y-2">
            <h1 className="text-white text-[28px] font-semibold">
              Complete Your Profile
            </h1>
            <p className="text-white/70 text-[16px]">
              Step {currentStep + 1} of {totalSteps}
            </p>
          </div>

          {/* Progress Bar */}
          <div className="w-full bg-white/10 rounded-full h-2">
            <motion.div
              className="bg-[#FFD700] h-2 rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.5 }}
            />
          </div>
        </div>

        {/* Form Steps */}
        <Card className="bg-white/5 border-white/10">
          <CardContent className="p-8">
            <AnimatePresence mode="wait">
              {/* Step 0: Name */}
              {currentStep === 0 && (
                <motion.div
                  key="name"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-6"
                >
                  <div className="text-center space-y-2">
                    <h2 className="text-white text-[22px] font-medium">
                      What's your name?
                    </h2>
                    <p className="text-white/60 text-[15px]">
                      This will be shown on your HIVE profile
                    </p>
                  </div>

                  <div className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="firstName" className="text-white/80">
                        First Name
                      </Label>
                      <Input
                        id="firstName"
                        value={profileData.firstName}
                        onChange={(e) => updateProfileData({ firstName: e.target.value })}
                        placeholder="Enter your first name"
                        className="bg-white/5 border-white/20 text-white placeholder:text-white/40"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="lastName" className="text-white/80">
                        Last Name
                      </Label>
                      <Input
                        id="lastName"
                        value={profileData.lastName}
                        onChange={(e) => updateProfileData({ lastName: e.target.value })}
                        placeholder="Enter your last name"
                        className="bg-white/5 border-white/20 text-white placeholder:text-white/40"
                      />
                    </div>
                  </div>
                </motion.div>
              )}

              {/* Step 1: Academic Info */}
              {currentStep === 1 && (
                <motion.div
                  key="academic"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-6"
                >
                  <div className="text-center space-y-2">
                    <h2 className="text-white text-[22px] font-medium">
                      Academic Details
                    </h2>
                    <p className="text-white/60 text-[15px]">
                      Help us connect you with relevant spaces and events
                    </p>
                  </div>

                  <div className="space-y-6">
                    {/* Major Search */}
                    <div className="space-y-2">
                      <Label className="text-white/80 flex items-center gap-2">
                        <GraduationCap className="w-4 h-4" />
                        Major / Program
                      </Label>
                      <div className="relative">
                        <Input
                          value={majorSearch}
                          onChange={(e) => {
                            setMajorSearch(e.target.value);
                            setShowMajorDropdown(true);
                          }}
                          onFocus={() => setShowMajorDropdown(true)}
                          placeholder="Search for your major..."
                          className="bg-white/5 border-white/20 text-white placeholder:text-white/40 pr-10"
                        />
                        <Search className="absolute right-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-white/40" />
                        
                        {showMajorDropdown && filteredMajors.length > 0 && (
                          <motion.div
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="absolute z-50 w-full mt-1 bg-[#1A1A1A] border border-white/20 rounded-lg max-h-60 overflow-y-auto"
                          >
                            {filteredMajors.slice(0, 10).map((major) => (
                              <button
                                key={major}
                                onClick={() => selectMajor(major)}
                                className="w-full px-4 py-3 text-left text-white hover:bg-white/10 transition-colors border-b border-white/5 last:border-b-0"
                              >
                                <div className="flex items-center justify-between">
                                  <span className="text-[14px]">{major}</span>
                                  {profileData.major === major && (
                                    <Check className="w-4 h-4 text-[#FFD700]" />
                                  )}
                                </div>
                              </button>
                            ))}
                            {filteredMajors.length > 10 && (
                              <div className="px-4 py-2 text-white/60 text-[12px] border-t border-white/10">
                                {filteredMajors.length - 10} more results...
                              </div>
                            )}
                          </motion.div>
                        )}
                      </div>
                    </div>

                    {/* Year Selection */}
                    <div className="space-y-2">
                      <Label className="text-white/80">Academic Year</Label>
                      <div className="grid grid-cols-2 gap-3">
                        {YEAR_OPTIONS.map((year) => (
                          <button
                            key={year}
                            onClick={() => updateProfileData({ year })}
                            className={`p-3 rounded-lg border transition-all ${
                              profileData.year === year
                                ? 'bg-[#FFD700]/10 border-[#FFD700] text-[#FFD700]'
                                : 'bg-white/5 border-white/20 text-white hover:bg-white/10'
                            }`}
                          >
                            <span className="text-[14px] font-medium">{year}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Residence Selection */}
                    <div className="space-y-2">
                      <Label className="text-white/80 flex items-center gap-2">
                        <Home className="w-4 h-4" />
                        Residential Status
                      </Label>
                      <div className="grid grid-cols-1 gap-2">
                        {RESIDENCE_OPTIONS.map((residence) => (
                          <button
                            key={residence}
                            onClick={() => updateProfileData({ residence })}
                            className={`p-3 rounded-lg border transition-all text-left ${
                              profileData.residence === residence
                                ? 'bg-[#FFD700]/10 border-[#FFD700] text-[#FFD700]'
                                : 'bg-white/5 border-white/20 text-white hover:bg-white/10'
                            }`}
                          >
                            <span className="text-[14px] font-medium">{residence}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                </motion.div>
              )}

              {/* Step 2: Leadership Check */}
              {currentStep === 2 && (
                <motion.div
                  key="leadership"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-6"
                >
                  <div className="text-center space-y-2">
                    <Crown className="w-12 h-12 text-[#FFD700] mx-auto" />
                    <h2 className="text-white text-[22px] font-medium">
                      Are you a student leader?
                    </h2>
                    <p className="text-white/60 text-[15px]">
                      Leaders can request to manage spaces for their organizations
                    </p>
                  </div>

                  <div className="space-y-4">
                    <button
                      onClick={() => updateProfileData({ isStudentLeader: true })}
                      className={`w-full p-4 rounded-lg border transition-all ${
                        profileData.isStudentLeader === true
                          ? 'bg-[#FFD700]/10 border-[#FFD700] text-[#FFD700]'
                          : 'bg-white/5 border-white/20 text-white hover:bg-white/10'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <Crown className="w-5 h-5" />
                        <div className="text-left">
                          <div className="font-medium">Yes, I'm a student leader</div>
                          <div className="text-[13px] opacity-70">
                            Officer, RA, Orientation Leader, etc.
                          </div>
                        </div>
                      </div>
                    </button>

                    <button
                      onClick={() => updateProfileData({ isStudentLeader: false })}
                      className={`w-full p-4 rounded-lg border transition-all ${
                        profileData.isStudentLeader === false
                          ? 'bg-[#FFD700]/10 border-[#FFD700] text-[#FFD700]'
                          : 'bg-white/5 border-white/20 text-white hover:bg-white/10'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <Users className="w-5 h-5" />
                        <div className="text-left">
                          <div className="font-medium">No, just a regular student</div>
                          <div className="text-[13px] opacity-70">
                            I'll join and participate in spaces
                          </div>
                        </div>
                      </div>
                    </button>
                  </div>
                </motion.div>
              )}

              {/* Step 3: Builder Request (only if student leader) */}
              {currentStep === 3 && profileData.isStudentLeader && (
                <motion.div
                  key="builder"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-6"
                >
                  <div className="text-center space-y-2">
                    <Building2 className="w-12 h-12 text-[#FFD700] mx-auto" />
                    <h2 className="text-white text-[22px] font-medium">
                      Request Builder Access
                    </h2>
                    <p className="text-white/60 text-[15px]">
                      Tell us about your leadership role to manage a space
                    </p>
                  </div>

                  <div className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="leadershipRole" className="text-white/80">
                        Your Leadership Role
                      </Label>
                      <Input
                        id="leadershipRole"
                        value={profileData.leadershipRole || ''}
                        onChange={(e) => updateProfileData({ leadershipRole: e.target.value })}
                        placeholder="e.g., President, Vice President, RA, Orientation Leader"
                        className="bg-white/5 border-white/20 text-white placeholder:text-white/40"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="spaceName" className="text-white/80">
                        Organization/Space Name
                      </Label>
                      <Input
                        id="spaceName"
                        value={profileData.spaceName || ''}
                        onChange={(e) => updateProfileData({ spaceName: e.target.value })}
                        placeholder="e.g., Computer Science Club, Ellicott Complex"
                        className="bg-white/5 border-white/20 text-white placeholder:text-white/40"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label className="text-white/80">Space Type</Label>
                      <div className="grid grid-cols-2 gap-2">
                        {SPACE_TYPES.map((type) => (
                          <button
                            key={type}
                            onClick={() => updateProfileData({ spaceType: type })}
                            className={`p-2 rounded-lg border transition-all text-[13px] ${
                              profileData.spaceType === type
                                ? 'bg-[#FFD700]/10 border-[#FFD700] text-[#FFD700]'
                                : 'bg-white/5 border-white/20 text-white hover:bg-white/10'
                            }`}
                          >
                            {type}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div className="bg-white/5 rounded-lg p-4 space-y-2">
                      <div className="text-white/80 text-[14px] font-medium">
                        What happens next?
                      </div>
                      <div className="text-white/60 text-[13px] leading-relaxed">
                        Your request will be reviewed by the HIVE team. If approved, 
                        you'll be able to manage your space, create custom tools, and 
                        moderate content. This usually takes 1-2 business days.
                      </div>
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Error Message */}
            {error && (
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="mt-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg"
              >
                <p className="text-red-400 text-[14px]">{error}</p>
              </motion.div>
            )}

            {/* Navigation Buttons */}
            <div className="flex gap-3 mt-8">
              {currentStep > 0 && (
                <Button
                  onClick={handleBack}
                  variant="secondary"
                  className="flex-1"
                  disabled={isSubmitting}
                >
                  Back
                </Button>
              )}
              
              <Button
                onClick={handleNext}
                variant="accent"
                className="flex-1"
                disabled={!canProceedToNext() || isSubmitting}
              >
                {isSubmitting ? (
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 border-2 border-black/20 border-t-black rounded-full animate-spin" />
                    Setting up...
                  </div>
                ) : currentStep === totalSteps - 1 ? (
                  'Complete Setup'
                ) : (
                  <div className="flex items-center gap-2">
                    Next
                    <ArrowRight className="w-4 h-4" />
                  </div>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  );
}