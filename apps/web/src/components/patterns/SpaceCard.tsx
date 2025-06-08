'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Button } from '@hive/ui-core';
import { cn } from '@/lib/utils';

interface SpaceCardProps {
  name: string;
  description: string;
  category: 'Academic' | 'Social' | 'Professional' | 'Residential' | 'Organization';
  memberCount: number;
  onlineCount?: number;
  isJoined?: boolean;
  isPrivate?: boolean;
  recentActivity?: {
    type: 'post' | 'event' | 'tool';
    description: string;
    timeAgo: string;
  };
  tags?: string[];
  coverImage?: string;
  onJoin?: () => void;
  onView?: () => void;
  className?: string;
}

export function SpaceCard({ 
  name, 
  description, 
  category, 
  memberCount, 
  onlineCount,
  isJoined = false,
  isPrivate = false,
  recentActivity,
  tags = [],
  coverImage,
  onJoin, 
  onView,
  className 
}: SpaceCardProps) {
  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'Academic': return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
      case 'Social': return 'bg-purple-500/20 text-purple-400 border-purple-500/30';
      case 'Professional': return 'bg-green-500/20 text-green-400 border-green-500/30';
      case 'Residential': return 'bg-orange-500/20 text-orange-400 border-orange-500/30';
      case 'Organization': return 'bg-[#FFD700]/20 text-[#FFD700] border-[#FFD700]/30';
      default: return 'bg-white/10 text-white/60 border-white/10';
    }
  };

  const getActivityIcon = (type?: string) => {
    switch (type) {
      case 'post': return '💬';
      case 'event': return '📅';
      case 'tool': return '🛠️';
      default: return '📝';
    }
  };

  return (
    <Card className={cn(
      "group transition-all duration-200 hover:scale-[1.02] cursor-pointer",
      "bg-white/5 border-white/10 hover:border-[#FFD700]/30",
      className
    )}>
      {/* Cover Image */}
      {coverImage && (
        <div className="relative h-32 overflow-hidden rounded-t-lg">
          <img 
            src={coverImage} 
            alt={`${name} cover`}
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
        </div>
      )}

      <CardHeader className="space-y-3">
        <div className="flex items-start justify-between">
          <div className="space-y-2 flex-1">
            <div className="flex items-center gap-2">
              <CardTitle className="group-hover:text-[#FFD700] transition-colors duration-200 text-white">
                {name}
              </CardTitle>
              {isPrivate && (
                <span className="text-xs px-2 py-1 bg-white/10 rounded text-white/60">
                  🔒 Private
                </span>
              )}
            </div>
            <CardDescription className="line-clamp-2 text-white/70">
              {description}
            </CardDescription>
          </div>
        </div>
        
        <div className="flex items-center justify-between">
          <span className={cn(
            "text-xs px-2 py-1 rounded border",
            getCategoryColor(category)
          )}>
            {category}
          </span>
          <div className="flex items-center gap-3 text-xs text-white/60">
            <span>{memberCount} members</span>
            {onlineCount && onlineCount > 0 && (
              <>
                <span>•</span>
                <span className="text-green-400">{onlineCount} online</span>
              </>
            )}
          </div>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Recent Activity */}
        {recentActivity && (
          <div className="p-3 bg-white/5 rounded-lg border border-white/10">
            <div className="flex items-start gap-2">
              <span className="text-lg">{getActivityIcon(recentActivity.type)}</span>
              <div className="flex-1">
                <p className="text-sm text-white">
                  {recentActivity.description}
                </p>
                <p className="text-xs text-white/60 mt-1">
                  {recentActivity.timeAgo}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Tags */}
        {tags.length > 0 && (
          <div className="flex gap-2 flex-wrap">
            {tags.slice(0, 3).map((tag, index) => (
              <span key={index} className="text-xs px-2 py-1 bg-white/10 rounded text-white/70">
                {tag}
              </span>
            ))}
            {tags.length > 3 && (
              <span className="text-xs px-2 py-1 bg-white/10 rounded text-white/70">
                +{tags.length - 3} more
              </span>
            )}
          </div>
        )}
      </CardContent>

      <CardFooter className="flex gap-2">
        <Button 
          variant={isJoined ? "accent" : "default"}
          size="sm" 
          onClick={onJoin}
          className="flex-1"
        >
          {isJoined ? '✓ Joined' : isPrivate ? 'Request Access' : 'Join Space'}
        </Button>
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={onView}
        >
          View
        </Button>
      </CardFooter>
    </Card>
  );
}

// Usage example component for testing
export function SpaceCardShowcase() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
      <SpaceCard
        name="Computer Science Hub"
        description="Connect with CS students, share resources, collaborate on projects, and stay updated on department events."
        category="Academic"
        memberCount={234}
        onlineCount={18}
        isJoined={true}
        recentActivity={{
          type: 'post',
          description: 'Sarah shared a new study guide for Data Structures',
          timeAgo: '2 hours ago'
        }}
        tags={["Programming", "Study Groups", "Internships", "Career Prep"]}
        onJoin={() => console.log('Toggle CS Hub membership')}
        onView={() => console.log('View CS Hub')}
      />
      
      <SpaceCard
        name="Orientation Leaders 2024"
        description="Official space for UB Orientation Leaders. Coordinate sessions, share resources, and support new students."
        category="Organization"
        memberCount={45}
        onlineCount={12}
        isPrivate={true}
        recentActivity={{
          type: 'event',
          description: 'Next orientation session: July 14-15 prep meeting',
          timeAgo: '4 hours ago'
        }}
        tags={["Leadership", "New Students", "Events"]}
        onJoin={() => console.log('Request OL access')}
        onView={() => console.log('View OL space')}
      />
      
      <SpaceCard
        name="Campus Foodies"
        description="Discover the best food spots around campus, share reviews, and organize group dining experiences."
        category="Social"
        memberCount={156}
        onlineCount={23}
        recentActivity={{
          type: 'post',
          description: 'New Korean BBQ place opened on Elmwood Ave!',
          timeAgo: '1 day ago'
        }}
        tags={["Food", "Reviews", "Local", "Social"]}
        onJoin={() => console.log('Join Campus Foodies')}
        onView={() => console.log('View Campus Foodies')}
      />
      
      <SpaceCard
        name="Business Network"
        description="Professional networking for business students. Industry connections, career advice, and internship opportunities."
        category="Professional"
        memberCount={89}
        onlineCount={7}
        recentActivity={{
          type: 'tool',
          description: 'New networking tracker tool added by Mike',
          timeAgo: '3 days ago'
        }}
        tags={["Networking", "Career", "Business", "Mentorship"]}
        onJoin={() => console.log('Join Business Network')}
        onView={() => console.log('View Business Network')}
      />
      
      <SpaceCard
        name="Greiner Hall Residents"
        description="Connect with fellow Greiner residents. Plan floor events, share resources, and build community."
        category="Residential"
        memberCount={78}
        onlineCount={5}
        isJoined={true}
        recentActivity={{
          type: 'event',
          description: 'Floor 3 movie night this Friday at 8 PM',
          timeAgo: '6 hours ago'
        }}
        tags={["Dorm Life", "Events", "Community"]}
        onJoin={() => console.log('Toggle Greiner membership')}
        onView={() => console.log('View Greiner space')}
      />
      
      <SpaceCard
        name="Hackathon Team"
        description="Build innovative solutions to real-world problems. All skill levels welcome for weekend coding sprints."
        category="Academic"
        memberCount={42}
        onlineCount={9}
        recentActivity={{
          type: 'post',
          description: 'Team registration open for next hackathon!',
          timeAgo: '5 hours ago'
        }}
        tags={["Coding", "Innovation", "Teams", "Competition"]}
        onJoin={() => console.log('Join Hackathon Team')}
        onView={() => console.log('View Hackathon space')}
      />
    </div>
  );
} 
 