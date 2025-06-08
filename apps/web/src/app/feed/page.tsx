'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { useAuth } from '@/context/AuthContext'
import { Button } from '@hive/ui-core'
import { Card, CardContent } from '@/components/ui/card'
import { ProtectedRoute } from '@/components/auth/AuthGuard'
import { 
  Home, 
  Users, 
  Calendar, 
  Settings, 
  Bell,
  Search,
  Plus,
  MessageCircle,
  Heart,
  Share
} from 'lucide-react'

export default function FeedPage() {
  const { user, profile, signOut } = useAuth()

  const handleSignOut = async () => {
    try {
      await signOut()
    } catch (error) {
      console.error('Sign out error:', error)
    }
  }

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-[#0A0A0A]">
        {/* Header */}
        <header className="border-b border-white/10 bg-[#0A0A0A]/80 backdrop-blur-sm sticky top-0 z-50">
          <div className="max-w-4xl mx-auto px-4 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="text-[#FFD700] text-[24px] font-bold">
                  HIVE
                </div>
                <div className="text-white/60 text-[14px]">
                  vBETA
                </div>
              </div>

              <div className="flex items-center gap-3">
                <Button variant="ghost" size="sm">
                  <Search className="w-4 h-4" />
                </Button>
                <Button variant="ghost" size="sm">
                  <Bell className="w-4 h-4" />
                </Button>
                <Button variant="ghost" size="sm" onClick={handleSignOut}>
                  <Settings className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </div>
        </header>

        <div className="max-w-4xl mx-auto px-4 py-8">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Main Feed */}
            <div className="lg:col-span-2 space-y-6">
              {/* Welcome Message */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6 }}
              >
                <Card className="bg-gradient-to-r from-[#FFD700]/10 to-[#FFD700]/5 border-[#FFD700]/20">
                  <CardContent className="p-6">
                    <div className="space-y-3">
                      <h1 className="text-white text-[24px] font-semibold">
                        Welcome to HIVE, {profile?.fullName || user?.displayName || 'Student'}! 🎉
                      </h1>
                      <p className="text-white/70 text-[16px] leading-relaxed">
                        You're now part of the University at Buffalo's campus social network. 
                        Discover spaces, join events, and connect with your community.
                      </p>
                      <div className="flex gap-3 pt-2">
                        <Button variant="accent" size="sm">
                          <Users className="w-4 h-4 mr-2" />
                          Explore Spaces
                        </Button>
                        <Button variant="secondary" size="sm">
                          <Calendar className="w-4 h-4 mr-2" />
                          Browse Events
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>

              {/* Feed Content */}
              <div className="space-y-4">
                {/* Sample Post */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.6, delay: 0.1 }}
                >
                  <Card className="bg-white/5 border-white/10">
                    <CardContent className="p-6">
                      <div className="space-y-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-[#FFD700]/20 rounded-full flex items-center justify-center">
                            <Users className="w-5 h-5 text-[#FFD700]" />
                          </div>
                          <div>
                            <div className="text-white font-medium text-[15px]">
                              Computer Science Club
                            </div>
                            <div className="text-white/60 text-[13px]">
                              2 hours ago
                            </div>
                          </div>
                        </div>
                        
                        <div className="text-white text-[16px] leading-relaxed">
                          🚀 Excited to announce our first hackathon of the semester! 
                          Join us this weekend for 48 hours of coding, pizza, and prizes. 
                          All skill levels welcome!
                        </div>

                        <div className="flex items-center gap-6 pt-2">
                          <button className="flex items-center gap-2 text-white/60 hover:text-[#FFD700] transition-colors">
                            <Heart className="w-4 h-4" />
                            <span className="text-[14px]">24</span>
                          </button>
                          <button className="flex items-center gap-2 text-white/60 hover:text-[#FFD700] transition-colors">
                            <MessageCircle className="w-4 h-4" />
                            <span className="text-[14px]">8</span>
                          </button>
                          <button className="flex items-center gap-2 text-white/60 hover:text-[#FFD700] transition-colors">
                            <Share className="w-4 h-4" />
                            <span className="text-[14px]">Share</span>
                          </button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>

                {/* Another Sample Post */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.6, delay: 0.2 }}
                >
                  <Card className="bg-white/5 border-white/10">
                    <CardContent className="p-6">
                      <div className="space-y-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-blue-500/20 rounded-full flex items-center justify-center">
                            <Home className="w-5 h-5 text-blue-400" />
                          </div>
                          <div>
                            <div className="text-white font-medium text-[15px]">
                              Ellicott Complex
                            </div>
                            <div className="text-white/60 text-[13px]">
                              4 hours ago
                            </div>
                          </div>
                        </div>
                        
                        <div className="text-white text-[16px] leading-relaxed">
                          📚 Study rooms in the basement are now available for booking! 
                          Perfect for group projects and exam prep. Book through the 
                          residence portal or stop by the front desk.
                        </div>

                        <div className="flex items-center gap-6 pt-2">
                          <button className="flex items-center gap-2 text-white/60 hover:text-[#FFD700] transition-colors">
                            <Heart className="w-4 h-4" />
                            <span className="text-[14px]">12</span>
                          </button>
                          <button className="flex items-center gap-2 text-white/60 hover:text-[#FFD700] transition-colors">
                            <MessageCircle className="w-4 h-4" />
                            <span className="text-[14px]">3</span>
                          </button>
                          <button className="flex items-center gap-2 text-white/60 hover:text-[#FFD700] transition-colors">
                            <Share className="w-4 h-4" />
                            <span className="text-[14px]">Share</span>
                          </button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>

                {/* Empty State for more content */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.6, delay: 0.3 }}
                >
                  <Card className="bg-white/5 border-white/10 border-dashed">
                    <CardContent className="p-8">
                      <div className="text-center space-y-3">
                        <div className="w-12 h-12 bg-white/10 rounded-full flex items-center justify-center mx-auto">
                          <Plus className="w-6 h-6 text-white/60" />
                        </div>
                        <h3 className="text-white text-[18px] font-medium">
                          That's all for now!
                        </h3>
                        <p className="text-white/60 text-[14px] max-w-sm mx-auto">
                          You're all caught up. Check back later for more updates from your campus community.
                        </p>
                        <Button variant="accent" size="sm" className="mt-4">
                          <Plus className="w-4 h-4 mr-2" />
                          Create Post
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              </div>
            </div>

            {/* Sidebar */}
            <div className="space-y-6">
              {/* Profile Card */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.6 }}
              >
                <Card className="bg-white/5 border-white/10">
                  <CardContent className="p-6">
                    <div className="space-y-4">
                      <div className="text-center">
                        <div className="w-16 h-16 bg-[#FFD700]/20 rounded-full flex items-center justify-center mx-auto mb-3">
                          <span className="text-[#FFD700] text-[20px] font-bold">
                            {profile?.fullName?.[0]?.toUpperCase() || 'U'}
                          </span>
                        </div>
                        <h3 className="text-white text-[16px] font-medium">
                          {profile?.fullName || 'Student'}
                        </h3>
                        <p className="text-white/60 text-[14px]">
                          {profile?.major} • {profile?.academicYear}
                        </p>
                      </div>
                      
                      <div className="space-y-2 pt-2">
                        <div className="flex items-center justify-between text-[14px]">
                          <span className="text-white/60">Spaces</span>
                          <span className="text-white">3</span>
                        </div>
                        <div className="flex items-center justify-between text-[14px]">
                          <span className="text-white/60">Events</span>
                          <span className="text-white">12</span>
                        </div>
                        <div className="flex items-center justify-between text-[14px]">
                          <span className="text-white/60">Friends</span>
                          <span className="text-white">47</span>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>

              {/* Quick Actions */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.6, delay: 0.1 }}
              >
                <Card className="bg-white/5 border-white/10">
                  <CardContent className="p-6">
                    <h3 className="text-white text-[16px] font-medium mb-4">
                      Quick Actions
                    </h3>
                    <div className="space-y-3">
                      <Button variant="ghost" className="w-full justify-start" size="sm">
                        <Calendar className="w-4 h-4 mr-3" />
                        My Events
                      </Button>
                      <Button variant="ghost" className="w-full justify-start" size="sm">
                        <Users className="w-4 h-4 mr-3" />
                        My Spaces
                      </Button>
                      <Button variant="ghost" className="w-full justify-start" size="sm">
                        <Bell className="w-4 h-4 mr-3" />
                        Notifications
                      </Button>
                      <Button variant="ghost" className="w-full justify-start" size="sm">
                        <Settings className="w-4 h-4 mr-3" />
                        Settings
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            </div>
          </div>
        </div>
      </div>
    </ProtectedRoute>
  )
} 