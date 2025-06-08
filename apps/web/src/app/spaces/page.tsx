'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { SpaceCard } from '@/components/patterns';

const mockSpaces = [
  {
    id: 'new_students_2025',
    name: 'New Students 2025',
    description: 'Welcome space for incoming students to connect and get oriented',
    category: 'System',
    memberCount: 2847,
    onlineCount: 245,
    isJoined: true,
    recentActivity: {
      type: 'post' as const,
      description: 'Welcome message posted',
      timeAgo: '2 hours ago'
    },
    tags: ['Orientation', 'Welcome', 'New Students']
  },
  {
    id: 'cs_students',
    name: 'CS Students',
    description: 'Connect with Computer Science students, share resources, and collaborate on projects',
    category: 'Academic',
    memberCount: 456,
    onlineCount: 34,
    isJoined: true,
    recentActivity: {
      type: 'post' as const,
      description: 'Sarah shared a new study guide',
      timeAgo: '45 minutes ago'
    },
    tags: ['Programming', 'Study Groups', 'Projects']
  },
  {
    id: 'warren_towers',
    name: 'Warren Towers',
    description: 'Community space for Warren Towers residents',
    category: 'Residential',
    memberCount: 1205,
    onlineCount: 78,
    isJoined: true,
    recentActivity: {
      type: 'post' as const,
      description: 'Floor meeting scheduled',
      timeAgo: '3 hours ago'
    },
    tags: ['Dorm Life', 'Community', 'Events']
  },
  {
    id: 'robotics_club',
    name: 'Robotics Club',
    description: 'Build robots, compete in tournaments, and explore cutting-edge technology',
    category: 'Organization',
    memberCount: 89,
    onlineCount: 12,
    isJoined: false,
    recentActivity: {
      type: 'post' as const,
      description: 'Competition prep meeting',
      timeAgo: '1 day ago'
    },
    tags: ['Robotics', 'Competition', 'Engineering']
  }
];

export default function SpacesPage() {
  const handleJoinSpace = (spaceId: string) => {
    console.log('Join space:', spaceId);
  };

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="space-y-8"
      >
        {/* Page Header */}
        <div>
          <h1 className="text-white text-[34px] font-semibold mb-4">
            Spaces
          </h1>
          <p className="text-white/70 text-[17px] leading-relaxed">
            Connect with your campus communities and discover new groups.
          </p>
        </div>

        {/* Spaces Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {mockSpaces.map((space, index) => (
            <motion.div
              key={space.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <SpaceCard
                name={space.name}
                description={space.description}
                category={space.category}
                memberCount={space.memberCount}
                onlineCount={space.onlineCount}
                isJoined={space.isJoined}
                recentActivity={space.recentActivity}
                tags={space.tags}
                onJoin={() => handleJoinSpace(space.id)}
              />
            </motion.div>
          ))}
        </div>
      </motion.div>
    </div>
  );
} 