'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@hive/ui-core';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';

interface UserProfileProps {
  name: string;
  username: string;
  avatar?: string;
  major: string;
  year: string;
  isBuilder?: boolean;
  builderLevel?: 'Bronze' | 'Silver' | 'Gold' | 'Platinum';
  toolsCreated?: number;
  spacesJoined?: number;
  eventsAttended?: number;
  bio?: string;
  isOnline?: boolean;
  onMessage?: () => void;
  onFollow?: () => void;
  onViewProfile?: () => void;
  className?: string;
}

export function UserProfile({ 
  name,
  username,
  avatar,
  major,
  year,
  isBuilder = false,
  builderLevel,
  toolsCreated = 0,
  spacesJoined = 0,
  eventsAttended = 0,
  bio,
  isOnline = false,
  onMessage,
  onFollow,
  onViewProfile,
  className 
}: UserProfileProps) {
  const getBuilderBadgeVariant = (level?: string) => {
    switch (level) {
      case 'Bronze': return 'outline';
      case 'Silver': return 'ghost';
      case 'Gold': return 'accent';
      case 'Platinum': return 'success';
      default: return 'default';
    }
  };

  return (
    <Card 
      interactive 
      elevation="medium" 
      className={`group transition-all duration-standard hover:scale-[1.01] ${className}`}
    >
      <CardHeader className="space-y-4">
        {/* Avatar and Basic Info */}
        <div className="flex items-start gap-4">
          <div className="relative">
            <Avatar className="w-16 h-16 border-2 border-white/10">
              <AvatarImage src={avatar} alt={name} />
              <AvatarFallback className="bg-surface-2 text-text-primary font-semibold">
                {name.split(' ').map(n => n[0]).join('')}
              </AvatarFallback>
            </Avatar>
            {isOnline && (
              <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-success-500 border-2 border-surface-1 rounded-full" />
            )}
          </div>
          
          <div className="flex-1 space-y-2">
            <div>
              <CardTitle className="text-text-primary group-hover:text-brand-gold-500 transition-colors duration-micro">
                {name}
              </CardTitle>
              <CardDescription>@{username}</CardDescription>
            </div>
            
            <div className="flex items-center gap-2 flex-wrap">
              <Badge variant="outline" size="sm">
                {major}
              </Badge>
              <Badge variant="ghost" size="sm">
                {year}
              </Badge>
              {isBuilder && builderLevel && (
                <Badge variant={getBuilderBadgeVariant(builderLevel)} size="sm">
                  {builderLevel} Builder
                </Badge>
              )}
            </div>
          </div>
        </div>

        {/* Bio */}
        {bio && (
          <CardDescription className="line-clamp-2 text-text-secondary">
            {bio}
          </CardDescription>
        )}
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 py-3 border-y border-white/10">
          <div className="text-center">
            <div className="text-h3 font-semibold text-text-primary">
              {spacesJoined}
            </div>
            <div className="text-caption text-text-secondary">
              Spaces
            </div>
          </div>
          
          <div className="text-center">
            <div className="text-h3 font-semibold text-text-primary">
              {eventsAttended}
            </div>
            <div className="text-caption text-text-secondary">
              Events
            </div>
          </div>
          
          {isBuilder && (
            <div className="text-center">
              <div className="text-h3 font-semibold text-brand-gold-500">
                {toolsCreated}
              </div>
              <div className="text-caption text-text-secondary">
                Tools
              </div>
            </div>
          )}
          
          {!isBuilder && (
            <div className="text-center">
              <div className="text-h3 font-semibold text-text-primary">
                {Math.floor(Math.random() * 50) + 10}
              </div>
              <div className="text-caption text-text-secondary">
                Activity
              </div>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="flex gap-2">
          <Button 
            variant="accent" 
            size="sm" 
            onClick={onViewProfile}
            className="flex-1"
          >
            View Profile
          </Button>
          <Button 
            variant="ghost" 
            size="sm" 
            onClick={onMessage}
          >
            Message
          </Button>
          <Button 
            variant="ghost" 
            size="sm" 
            onClick={onFollow}
          >
            Follow
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

// Usage example component for testing
export function UserProfileShowcase() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
      <UserProfile
        name="Sarah Chen"
        username="sarah_builds"
        major="Computer Science"
        year="Junior"
        isBuilder={true}
        builderLevel="Gold"
        toolsCreated={12}
        spacesJoined={8}
        eventsAttended={24}
        bio="Building tools to help students connect and learn together. Always down for a good hackathon!"
        isOnline={true}
        onMessage={() => console.log('Message Sarah')}
        onFollow={() => console.log('Follow Sarah')}
        onViewProfile={() => console.log('View Sarah\'s profile')}
      />
      
      <UserProfile
        name="Mike Rodriguez"
        username="mike_studies"
        major="Mechanical Engineering"
        year="Sophomore"
        isBuilder={true}
        builderLevel="Silver"
        toolsCreated={5}
        spacesJoined={12}
        eventsAttended={18}
        bio="Engineering student passionate about sustainable design and study group coordination."
        isOnline={false}
        onMessage={() => console.log('Message Mike')}
        onFollow={() => console.log('Follow Mike')}
        onViewProfile={() => console.log('View Mike\'s profile')}
      />
      
      <UserProfile
        name="Emma Thompson"
        username="emma_events"
        major="Business Administration"
        year="Senior"
        spacesJoined={15}
        eventsAttended={42}
        bio="Event coordinator and campus community builder. Let's make college memorable!"
        isOnline={true}
        onMessage={() => console.log('Message Emma')}
        onFollow={() => console.log('Follow Emma')}
        onViewProfile={() => console.log('View Emma\'s profile')}
      />
      
      <UserProfile
        name="Alex Kim"
        username="alex_dev"
        major="Data Science"
        year="Freshman"
        isBuilder={true}
        builderLevel="Bronze"
        toolsCreated={2}
        spacesJoined={6}
        eventsAttended={8}
        bio="New to campus but excited to build tools that help students succeed."
        isOnline={true}
        onMessage={() => console.log('Message Alex')}
        onFollow={() => console.log('Follow Alex')}
        onViewProfile={() => console.log('View Alex\'s profile')}
      />
    </div>
  );
} 
 