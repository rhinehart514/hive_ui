'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@hive/ui-core';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';

interface FeedItemProps {
  author: {
    name: string;
    username: string;
    avatar?: string;
    isBuilder?: boolean;
    builderLevel?: 'Bronze' | 'Silver' | 'Gold' | 'Platinum';
  };
  content: string;
  timestamp: string;
  spaceContext?: {
    name: string;
    type: 'Academic' | 'Social' | 'Professional' | 'Residential';
  };
  interactions: {
    likes: number;
    comments: number;
    shares: number;
  };
  isLiked?: boolean;
  isPinned?: boolean;
  hasImage?: boolean;
  imageUrl?: string;
  onLike?: () => void;
  onComment?: () => void;
  onShare?: () => void;
  onProfileClick?: () => void;
  className?: string;
}

export function FeedItem({ 
  author,
  content,
  timestamp,
  spaceContext,
  interactions,
  isLiked = false,
  isPinned = false,
  hasImage = false,
  imageUrl,
  onLike,
  onComment,
  onShare,
  onProfileClick,
  className 
}: FeedItemProps) {
  const getBuilderBadgeVariant = (level?: string) => {
    switch (level) {
      case 'Bronze': return 'outline';
      case 'Silver': return 'ghost';
      case 'Gold': return 'accent';
      case 'Platinum': return 'success';
      default: return 'default';
    }
  };

  const getSpaceTypeColor = (type?: string) => {
    switch (type) {
      case 'Academic': return 'text-blue-400';
      case 'Social': return 'text-purple-400';
      case 'Professional': return 'text-green-400';
      case 'Residential': return 'text-orange-400';
      default: return 'text-text-secondary';
    }
  };

  return (
    <Card 
      className={`transition-all duration-standard hover:bg-surface-1/50 ${className}`}
    >
      <CardHeader className="space-y-3">
        {/* Post Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-3 flex-1">
            <Avatar 
              className="w-10 h-10 cursor-pointer hover:scale-105 transition-transform duration-micro" 
              onClick={onProfileClick}
            >
              <AvatarImage src={author.avatar} alt={author.name} />
              <AvatarFallback className="bg-surface-2 text-text-primary text-sm font-medium">
                {author.name.split(' ').map(n => n[0]).join('')}
              </AvatarFallback>
            </Avatar>
            
            <div className="flex-1 space-y-1">
              <div className="flex items-center gap-2 flex-wrap">
                <button 
                  onClick={onProfileClick}
                  className="text-body font-semibold text-text-primary hover:text-brand-gold-500 transition-colors duration-micro"
                >
                  {author.name}
                </button>
                <span className="text-caption text-text-secondary">@{author.username}</span>
                
                {author.isBuilder && author.builderLevel && (
                  <Badge variant={getBuilderBadgeVariant(author.builderLevel)} size="sm">
                    {author.builderLevel}
                  </Badge>
                )}
              </div>
              
              <div className="flex items-center gap-2 text-caption text-text-secondary">
                <span>{timestamp}</span>
                {spaceContext && (
                  <>
                    <span>•</span>
                    <span className={getSpaceTypeColor(spaceContext.type)}>
                      {spaceContext.name}
                    </span>
                  </>
                )}
              </div>
            </div>
          </div>
          
          {isPinned && (
            <Badge variant="accent" size="sm" className="flex items-center gap-1">
              📌 Pinned
            </Badge>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Post Content */}
        <div className="text-body text-text-primary leading-relaxed">
          {content}
        </div>
        
        {/* Image Attachment */}
        {hasImage && imageUrl && (
          <div className="rounded-lg overflow-hidden border border-white/10">
            <img 
              src={imageUrl} 
              alt="Post attachment" 
              className="w-full h-auto max-h-80 object-cover"
            />
          </div>
        )}
        
        {/* Interaction Bar */}
        <div className="flex items-center justify-between pt-3 border-t border-white/10">
          <div className="flex items-center gap-6">
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={onLike}
              className={`flex items-center gap-2 hover:scale-105 transition-all duration-micro ${
                isLiked ? 'text-error-500 hover:text-error-400' : 'text-text-secondary hover:text-text-primary'
              }`}
            >
              <span className="text-lg">{isLiked ? '❤️' : '🤍'}</span>
              <span className="text-caption">{interactions.likes}</span>
            </Button>
            
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={onComment}
              className="flex items-center gap-2 text-text-secondary hover:text-text-primary hover:scale-105 transition-all duration-micro"
            >
              <span className="text-lg">💬</span>
              <span className="text-caption">{interactions.comments}</span>
            </Button>
            
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={onShare}
              className="flex items-center gap-2 text-text-secondary hover:text-text-primary hover:scale-105 transition-all duration-micro"
            >
              <span className="text-lg">↗️</span>
              <span className="text-caption">{interactions.shares}</span>
            </Button>
          </div>
          
          <div className="text-caption text-text-secondary">
            {interactions.likes + interactions.comments + interactions.shares} interactions
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// Usage example component for testing
export function FeedItemShowcase() {
  return (
    <div className="max-w-2xl mx-auto space-y-4 p-6">
      <FeedItem
        author={{
          name: "Sarah Chen",
          username: "sarah_builds",
          isBuilder: true,
          builderLevel: "Gold"
        }}
        content="Just launched a new study session coordination tool! 🚀 It helps you find study buddies for any class and automatically schedules group sessions based on everyone's availability. Who wants to try it out for upcoming finals?"
        timestamp="2 hours ago"
        spaceContext={{
          name: "CS Students",
          type: "Academic"
        }}
        interactions={{
          likes: 24,
          comments: 8,
          shares: 3
        }}
        isLiked={true}
        isPinned={true}
        onLike={() => console.log('Liked Sarah\'s post')}
        onComment={() => console.log('Comment on Sarah\'s post')}
        onShare={() => console.log('Share Sarah\'s post')}
        onProfileClick={() => console.log('View Sarah\'s profile')}
      />
      
      <FeedItem
        author={{
          name: "Campus Events",
          username: "ub_events",
        }}
        content="🎉 Spring Festival is happening this Saturday at the Student Union! Food trucks, live music, and student org showcases. Come discover new communities and enjoy some amazing food. Event starts at 12 PM."
        timestamp="5 hours ago"
        spaceContext={{
          name: "UB Community",
          type: "Social"
        }}
        interactions={{
          likes: 156,
          comments: 32,
          shares: 18
        }}
        hasImage={true}
        imageUrl="/api/placeholder/600/300"
        onLike={() => console.log('Liked events post')}
        onComment={() => console.log('Comment on events post')}
        onShare={() => console.log('Share events post')}
        onProfileClick={() => console.log('View events profile')}
      />
      
      <FeedItem
        author={{
          name: "Mike Rodriguez",
          username: "mike_studies",
          isBuilder: true,
          builderLevel: "Silver"
        }}
        content="Quick tip for fellow engineering students: Khan Academy's linear algebra course is perfect for reviewing before our midterm. The visual explanations really help with eigenvectors and matrix transformations."
        timestamp="1 day ago"
        spaceContext={{
          name: "Engineering Study Group",
          type: "Academic"
        }}
        interactions={{
          likes: 45,
          comments: 12,
          shares: 7
        }}
        onLike={() => console.log('Liked Mike\'s post')}
        onComment={() => console.log('Comment on Mike\'s post')}
        onShare={() => console.log('Share Mike\'s post')}
        onProfileClick={() => console.log('View Mike\'s profile')}
      />
      
      <FeedItem
        author={{
          name: "Emma Thompson",
          username: "emma_events",
        }}
        content="Looking for 2 more people to join our weekend hiking group! We're planning to hit some trails in the Finger Lakes region. All skill levels welcome - it's more about the company than the challenge 🥾"
        timestamp="2 days ago"
        spaceContext={{
          name: "Outdoor Adventures",
          type: "Social"
        }}
        interactions={{
          likes: 18,
          comments: 9,
          shares: 2
        }}
        onLike={() => console.log('Liked Emma\'s post')}
        onComment={() => console.log('Comment on Emma\'s post')}
        onShare={() => console.log('Share Emma\'s post')}
        onProfileClick={() => console.log('View Emma\'s profile')}
      />
    </div>
  );
} 
 