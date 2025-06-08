'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@hive/ui-core';

interface ToolCardProps {
  title: string;
  description: string;
  category: string;
  author: string;
  usageCount: number;
  isLive?: boolean;
  isNew?: boolean;
  onUse?: () => void;
  onFork?: () => void;
  className?: string;
}

export function ToolCard({ 
  title, 
  description, 
  category, 
  author, 
  usageCount, 
  isLive = false,
  isNew = false,
  onUse, 
  onFork,
  className 
}: ToolCardProps) {
  return (
    <Card 
      interactive 
      elevation="medium" 
      className={`group transition-all duration-standard hover:scale-[1.02] ${className}`}
    >
      <CardHeader className="space-y-3">
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <CardTitle className="group-hover:text-brand-gold-500 transition-colors duration-micro">
              {title}
            </CardTitle>
            <CardDescription className="line-clamp-2">
              {description}
            </CardDescription>
          </div>
          <div className="flex gap-2">
            {isLive && (
              <Badge variant="accent" size="sm" className="animate-pulse">
                Live
              </Badge>
            )}
            {isNew && (
              <Badge variant="success" size="sm">
                New
              </Badge>
            )}
          </div>
        </div>
        
        <div className="flex items-center justify-between">
          <Badge variant="outline" size="sm">
            {category}
          </Badge>
          <div className="text-caption text-text-secondary">
            {usageCount} uses
          </div>
        </div>
      </CardHeader>

      <CardContent>
        <div className="text-caption text-text-secondary">
          Created by <span className="text-text-primary font-medium">{author}</span>
        </div>
      </CardContent>

      <CardFooter className="flex gap-2">
        <Button 
          variant="accent" 
          size="sm" 
          onClick={onUse}
          className="flex-1"
        >
          Use Tool
        </Button>
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={onFork}
        >
          Fork
        </Button>
      </CardFooter>
    </Card>
  );
}

// Usage example component for testing
export function ToolCardShowcase() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
      <ToolCard
        title="Quick Poll"
        description="Create instant polls for your Space members to vote on ideas, events, or decisions."
        category="Engagement"
        author="@sarah_builds"
        usageCount={142}
        isLive={true}
        onUse={() => console.log('Using Quick Poll')}
        onFork={() => console.log('Forking Quick Poll')}
      />
      
      <ToolCard
        title="Study Tracker"
        description="Track study sessions and goals across your academic community."
        category="Academic"
        author="@mike_studies"
        usageCount={89}
        isNew={true}
        onUse={() => console.log('Using Study Tracker')}
        onFork={() => console.log('Forking Study Tracker')}
      />
      
      <ToolCard
        title="Event RSVP"
        description="Manage event attendance with sophisticated RSVP tracking and reminders."
        category="Events"
        author="@events_master"
        usageCount={267}
        onUse={() => console.log('Using Event RSVP')}
        onFork={() => console.log('Forking Event RSVP')}
      />
      
      <ToolCard
        title="Anonymous Suggestions"
        description="Collect anonymous feedback and suggestions from Space members safely."
        category="Feedback"
        author="@community_helper"
        usageCount={94}
        isLive={true}
        isNew={true}
        onUse={() => console.log('Using Anonymous Suggestions')}
        onFork={() => console.log('Forking Anonymous Suggestions')}
      />
    </div>
  );
} 

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@hive/ui-core';

interface ToolCardProps {
  title: string;
  description: string;
  category: string;
  author: string;
  usageCount: number;
  isLive?: boolean;
  isNew?: boolean;
  onUse?: () => void;
  onFork?: () => void;
  className?: string;
}

export function ToolCard({ 
  title, 
  description, 
  category, 
  author, 
  usageCount, 
  isLive = false,
  isNew = false,
  onUse, 
  onFork,
  className 
}: ToolCardProps) {
  return (
    <Card 
      interactive 
      elevation="medium" 
      className={`group transition-all duration-standard hover:scale-[1.02] ${className}`}
    >
      <CardHeader className="space-y-3">
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <CardTitle className="group-hover:text-brand-gold-500 transition-colors duration-micro">
              {title}
            </CardTitle>
            <CardDescription className="line-clamp-2">
              {description}
            </CardDescription>
          </div>
          <div className="flex gap-2">
            {isLive && (
              <Badge variant="accent" size="sm" className="animate-pulse">
                Live
              </Badge>
            )}
            {isNew && (
              <Badge variant="success" size="sm">
                New
              </Badge>
            )}
          </div>
        </div>
        
        <div className="flex items-center justify-between">
          <Badge variant="outline" size="sm">
            {category}
          </Badge>
          <div className="text-caption text-text-secondary">
            {usageCount} uses
          </div>
        </div>
      </CardHeader>

      <CardContent>
        <div className="text-caption text-text-secondary">
          Created by <span className="text-text-primary font-medium">{author}</span>
        </div>
      </CardContent>

      <CardFooter className="flex gap-2">
        <Button 
          variant="accent" 
          size="sm" 
          onClick={onUse}
          className="flex-1"
        >
          Use Tool
        </Button>
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={onFork}
        >
          Fork
        </Button>
      </CardFooter>
    </Card>
  );
}

// Usage example component for testing
export function ToolCardShowcase() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
      <ToolCard
        title="Quick Poll"
        description="Create instant polls for your Space members to vote on ideas, events, or decisions."
        category="Engagement"
        author="@sarah_builds"
        usageCount={142}
        isLive={true}
        onUse={() => console.log('Using Quick Poll')}
        onFork={() => console.log('Forking Quick Poll')}
      />
      
      <ToolCard
        title="Study Tracker"
        description="Track study sessions and goals across your academic community."
        category="Academic"
        author="@mike_studies"
        usageCount={89}
        isNew={true}
        onUse={() => console.log('Using Study Tracker')}
        onFork={() => console.log('Forking Study Tracker')}
      />
      
      <ToolCard
        title="Event RSVP"
        description="Manage event attendance with sophisticated RSVP tracking and reminders."
        category="Events"
        author="@events_master"
        usageCount={267}
        onUse={() => console.log('Using Event RSVP')}
        onFork={() => console.log('Forking Event RSVP')}
      />
      
      <ToolCard
        title="Anonymous Suggestions"
        description="Collect anonymous feedback and suggestions from Space members safely."
        category="Feedback"
        author="@community_helper"
        usageCount={94}
        isLive={true}
        isNew={true}
        onUse={() => console.log('Using Anonymous Suggestions')}
        onFork={() => console.log('Forking Anonymous Suggestions')}
      />
    </div>
  );
} 
 