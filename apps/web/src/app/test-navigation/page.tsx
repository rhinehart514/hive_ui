'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { 
  HiveNavigation,
  type SpaceContext,
  type UserContext
} from '@/components/navigation';

// Mock data for testing
const mockUser: UserContext = {
  id: 'user_1',
  fullName: 'Sarah Chen',
  username: 'sarahc',
  isBuilder: true,
  managedSpaces: ['cs_students', 'study_group_ai'],
  avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b7134b67?w=150',
};

const mockSpaces: SpaceContext[] = [
  {
    id: 'cs_students',
    name: 'CS Students',
    type: 'academic',
    isJoined: true,
    memberCount: 847,
    unreadCount: 3,
  },
  {
    id: 'warren_towers',
    name: 'Warren Towers',
    type: 'residential',
    isJoined: true,
    memberCount: 1205,
    unreadCount: 0,
  },
  {
    id: 'robotics_club',
    name: 'Robotics Club',
    type: 'organization',
    isJoined: true,
    memberCount: 156,
    unreadCount: 7,
  },
  {
    id: 'orientation_2025',
    name: 'Orientation 2025',
    type: 'system',
    isJoined: false,
    memberCount: 2300,
  },
  {
    id: 'math_tutoring',
    name: 'Math Tutoring',
    type: 'academic',
    isJoined: true,
    memberCount: 423,
    unreadCount: 1,
  },
  {
    id: 'gaming_society',
    name: 'Gaming Society',
    type: 'organization',
    isJoined: false,
    memberCount: 891,
  },
];

const mockBreadcrumbs = [
  { label: 'Home', href: '/' },
  { label: 'Navigation', href: '/test-navigation' },
  { label: 'Test Page', isCurrentPage: true },
];

/**
 * Test page for the HIVE navigation system
 * Demonstrates responsive navigation, space switching, and breadcrumbs
 */
export default function TestNavigationPage() {
  const [currentSpace, setCurrentSpace] = useState<SpaceContext | undefined>(
    mockSpaces[0]
  );
  const [user, setUser] = useState<UserContext | undefined>(mockUser);

  const handleSpaceSelect = (space: SpaceContext) => {
    setCurrentSpace(space);
    console.log('Selected space:', space);
  };

  const handleQuickAction = (actionId: string) => {
    console.log('Quick action:', actionId);
  };

  return (
    <HiveNavigation
      user={user}
      currentSpace={currentSpace}
      spaces={mockSpaces}
      breadcrumbItems={mockBreadcrumbs}
      onSpaceSelect={handleSpaceSelect}
      onQuickAction={handleQuickAction}
    >
      <div className="p-8 max-w-4xl mx-auto">
        {/* Page Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <h1 className="text-white text-[34px] font-semibold mb-4">
            Navigation System Test
          </h1>
          <p className="text-white/70 text-[17px] leading-relaxed">
            This page demonstrates the HIVE navigation system with responsive 
            desktop sidebar and mobile bottom navigation. The navigation adapts 
            based on screen size and user permissions.
          </p>
        </motion.div>

        {/* Current State Display */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8"
        >
          {/* Current User */}
          <div className="bg-white/5 rounded-xl p-6 border border-white/10">
            <h2 className="text-white text-[22px] font-semibold mb-4">
              Current User
            </h2>
            {user ? (
              <div className="space-y-3">
                <div>
                  <span className="text-white/50 text-sm">Name:</span>
                  <div className="text-white font-medium">{user.fullName}</div>
                </div>
                <div>
                  <span className="text-white/50 text-sm">Username:</span>
                  <div className="text-white font-medium">@{user.username}</div>
                </div>
                <div>
                  <span className="text-white/50 text-sm">Role:</span>
                  <div className={`font-medium ${user.isBuilder ? 'text-[#FFD700]' : 'text-white'}`}>
                    {user.isBuilder ? 'Builder' : 'Student'}
                  </div>
                </div>
                <div>
                  <span className="text-white/50 text-sm">Managed Spaces:</span>
                  <div className="text-white font-medium">{user.managedSpaces.length}</div>
                </div>
              </div>
            ) : (
              <div className="text-white/50">No user logged in</div>
            )}
            
            <button
              onClick={() => setUser(user ? undefined : mockUser)}
              className="mt-4 px-4 py-2 bg-[#FFD700] text-black rounded-lg font-medium hover:bg-[#FFD700]/90 transition-colors"
            >
              {user ? 'Sign Out' : 'Sign In'}
            </button>
          </div>

          {/* Current Space */}
          <div className="bg-white/5 rounded-xl p-6 border border-white/10">
            <h2 className="text-white text-[22px] font-semibold mb-4">
              Current Space
            </h2>
            {currentSpace ? (
              <div className="space-y-3">
                <div>
                  <span className="text-white/50 text-sm">Name:</span>
                  <div className="text-white font-medium">{currentSpace.name}</div>
                </div>
                <div>
                  <span className="text-white/50 text-sm">Type:</span>
                  <div className="text-white font-medium capitalize">{currentSpace.type}</div>
                </div>
                <div>
                  <span className="text-white/50 text-sm">Members:</span>
                  <div className="text-white font-medium">{currentSpace.memberCount}</div>
                </div>
                <div>
                  <span className="text-white/50 text-sm">Status:</span>
                  <div className={`font-medium ${currentSpace.isJoined ? 'text-[#8CE563]' : 'text-white/50'}`}>
                    {currentSpace.isJoined ? 'Joined' : 'Not Joined'}
                  </div>
                </div>
                {currentSpace.unreadCount !== undefined && currentSpace.unreadCount > 0 && (
                  <div>
                    <span className="text-white/50 text-sm">Unread:</span>
                    <div className="text-[#FF3B30] font-medium">{currentSpace.unreadCount}</div>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-white/50">No space selected</div>
            )}
          </div>
        </motion.div>

        {/* Available Spaces */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white/5 rounded-xl p-6 border border-white/10 mb-8"
        >
          <h2 className="text-white text-[22px] font-semibold mb-4">
            Available Spaces
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {mockSpaces.map((space) => (
              <button
                key={space.id}
                onClick={() => handleSpaceSelect(space)}
                className={`p-4 rounded-lg border transition-all text-left ${
                  currentSpace?.id === space.id
                    ? 'bg-[#FFD700]/10 border-[#FFD700]/30'
                    : 'bg-white/5 border-white/10 hover:bg-white/10'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="text-white font-medium">{space.name}</div>
                  {space.unreadCount !== undefined && space.unreadCount > 0 && (
                    <div className="bg-[#FF3B30] text-white text-xs px-2 py-1 rounded-full">
                      {space.unreadCount}
                    </div>
                  )}
                </div>
                <div className="text-white/50 text-sm capitalize mb-1">{space.type}</div>
                <div className="text-white/50 text-sm">{space.memberCount} members</div>
                <div className={`text-sm mt-2 ${space.isJoined ? 'text-[#8CE563]' : 'text-white/50'}`}>
                  {space.isJoined ? '✓ Joined' : '○ Not joined'}
                </div>
              </button>
            ))}
          </div>
        </motion.div>

        {/* Navigation Features */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white/5 rounded-xl p-6 border border-white/10"
        >
          <h2 className="text-white text-[22px] font-semibold mb-4">
            Navigation Features
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-white text-[17px] font-medium mb-3">Desktop</h3>
              <ul className="space-y-2 text-white/70">
                <li>• Collapsible sidebar with smooth animations</li>
                <li>• Space navigation with unread indicators</li>
                <li>• Builder tools section (when user is Builder)</li>
                <li>• Search functionality</li>
                <li>• User profile display</li>
              </ul>
            </div>
            <div>
              <h3 className="text-white text-[17px] font-medium mb-3">Mobile</h3>
              <ul className="space-y-2 text-white/70">
                <li>• Bottom tab navigation</li>
                <li>• Floating action buttons</li>
                <li>• Pull-up search overlay</li>
                <li>• Touch-optimized interactions</li>
                <li>• Compact breadcrumbs</li>
              </ul>
            </div>
          </div>
        </motion.div>
      </div>
    </HiveNavigation>
  );
} 