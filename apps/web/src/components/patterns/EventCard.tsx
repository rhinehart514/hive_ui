'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@hive/ui-core';

interface EventCardProps {
  title: string;
  description: string;
  location: string;
  date: string;
  time: string;
  organizer: string;
  attendeeCount: number;
  maxAttendees?: number;
  isLive?: boolean;
  isRSVPed?: boolean;
  tags?: string[];
  onRSVP?: () => void;
  onShare?: () => void;
  className?: string;
}

export function EventCard({ 
  title, 
  description, 
  location, 
  date, 
  time, 
  organizer, 
  attendeeCount, 
  maxAttendees,
  isLive = false,
  isRSVPed = false,
  tags = [],
  onRSVP, 
  onShare,
  className 
}: EventCardProps) {
  const isAtCapacity = maxAttendees && attendeeCount >= maxAttendees;
  
  return (
    <Card 
      interactive 
      elevation="medium" 
      className={`group transition-all duration-standard hover:scale-[1.01] ${className}`}
    >
      <CardHeader className="space-y-3">
        <div className="flex items-start justify-between">
          <div className="space-y-2 flex-1">
            <div className="flex items-center gap-2">
              <CardTitle className="group-hover:text-brand-gold-500 transition-colors duration-micro">
                {title}
              </CardTitle>
              {isLive && (
                <div className="flex items-center gap-1">
                  <div className="w-2 h-2 bg-error-500 rounded-full animate-pulse" />
                  <Badge variant="error" size="sm">
                    Live Now
                  </Badge>
                </div>
              )}
            </div>
            <CardDescription className="line-clamp-2">
              {description}
            </CardDescription>
          </div>
        </div>
        
        {/* Date, Time, Location */}
        <div className="space-y-2">
          <div className="flex items-center gap-4 text-caption text-text-secondary">
            <div className="flex items-center gap-1">
              <span>📅</span>
              <span>{date}</span>
            </div>
            <div className="flex items-center gap-1">
              <span>⏰</span>
              <span>{time}</span>
            </div>
          </div>
          <div className="flex items-center gap-1 text-caption text-text-secondary">
            <span>📍</span>
            <span>{location}</span>
          </div>
        </div>

        {/* Tags */}
        {tags.length > 0 && (
          <div className="flex gap-2 flex-wrap">
            {tags.slice(0, 3).map((tag, index) => (
              <Badge key={index} variant="ghost" size="sm">
                {tag}
              </Badge>
            ))}
            {tags.length > 3 && (
              <Badge variant="ghost" size="sm">
                +{tags.length - 3} more
              </Badge>
            )}
          </div>
        )}
      </CardHeader>

      <CardContent className="space-y-3">
        <div className="text-caption text-text-secondary">
          Hosted by <span className="text-text-primary font-medium">{organizer}</span>
        </div>
        
        <div className="flex items-center justify-between">
          <div className="text-caption text-text-secondary">
            {attendeeCount} {attendeeCount === 1 ? 'person' : 'people'} attending
            {maxAttendees && ` • ${maxAttendees - attendeeCount} spots left`}
          </div>
          {isAtCapacity && (
            <Badge variant="warning" size="sm">
              Full
            </Badge>
          )}
        </div>
        
        {/* Progress bar for capacity */}
        {maxAttendees && (
          <div className="w-full bg-surface-2 rounded-full h-1.5">
            <div 
              className="bg-brand-gold-500 h-1.5 rounded-full transition-all duration-standard"
              style={{ 
                width: `${Math.min((attendeeCount / maxAttendees) * 100, 100)}%` 
              }}
            />
          </div>
        )}
      </CardContent>

      <CardFooter className="flex gap-2">
        <Button 
          variant={isRSVPed ? "accent" : "primary"}
          size="sm" 
          onClick={onRSVP}
          disabled={isAtCapacity && !isRSVPed}
          className="flex-1"
        >
          {isRSVPed ? '✓ RSVP\'d' : isAtCapacity ? 'Full' : 'RSVP'}
        </Button>
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={onShare}
        >
          Share
        </Button>
      </CardFooter>
    </Card>
  );
}

// Usage example component for testing
export function EventCardShowcase() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
      <EventCard
        title="CS Study Session"
        description="Group study session for upcoming algorithms exam. Bring your laptops and questions!"
        location="Library Study Room 204"
        date="Today"
        time="7:00 PM"
        organizer="Computer Science Club"
        attendeeCount={12}
        maxAttendees={15}
        tags={["Study", "CS", "Algorithms"]}
        onRSVP={() => console.log('RSVP to CS Study Session')}
        onShare={() => console.log('Share CS Study Session')}
      />
      
      <EventCard
        title="Campus Mixer"
        description="Meet new people, enjoy food, and connect with students across all majors."
        location="Student Union Building"
        date="Friday, Dec 8"
        time="6:30 PM"
        organizer="Student Activities"
        attendeeCount={89}
        maxAttendees={100}
        isLive={true}
        tags={["Social", "Networking", "Food"]}
        onRSVP={() => console.log('RSVP to Campus Mixer')}
        onShare={() => console.log('Share Campus Mixer')}
      />
      
      <EventCard
        title="React Workshop"
        description="Learn modern React patterns and build a real project with industry professionals."
        location="Engineering Hall 301"
        date="Next Monday"
        time="4:00 PM"
        organizer="@sarah_dev"
        attendeeCount={24}
        maxAttendees={25}
        isRSVPed={true}
        tags={["Tech", "React", "Workshop", "Beginner-Friendly"]}
        onRSVP={() => console.log('Update RSVP for React Workshop')}
        onShare={() => console.log('Share React Workshop')}
      />
      
      <EventCard
        title="Orientation Q&A"
        description="Ask questions about campus life, academics, and get insider tips from current students."
        location="Virtual (Zoom link in description)"
        date="Tomorrow"
        time="12:00 PM"
        organizer="Orientation Team"
        attendeeCount={45}
        tags={["Orientation", "Q&A", "Virtual"]}
        onRSVP={() => console.log('RSVP to Orientation Q&A')}
        onShare={() => console.log('Share Orientation Q&A')}
      />
    </div>
  );
} 
 