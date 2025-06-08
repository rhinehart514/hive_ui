'use client';

import { HiveButton } from '@/components/ui/hive-button';
import { HiveCard } from '@/components/ui/hive-card';
import { HiveInput } from '@/components/ui/hive-input';
import { Badge } from '@/components/ui/badge';
import { HiveAvatar } from '@/components/ui/hive-avatar';

export default function DesignSystemPage() {
  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-6xl mx-auto space-y-12">
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold text-foreground">
            HIVE Design System
          </h1>
          <p className="text-muted-foreground max-w-2xl mx-auto text-lg">
            Real campus social components. Built on shadcn/ui + Radix + Framer Motion.
            Every component solves actual student problems.
          </p>
        </div>

        {/* Foundation Check */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Foundation Check</h2>
          <div className="grid grid-cols-4 gap-4 text-center">
            <div className="space-y-2">
              <div className="w-16 h-16 bg-background border rounded-xl mx-auto"></div>
              <p className="text-sm text-muted-foreground">Background</p>
                    </div>
            <div className="space-y-2">
              <div className="w-16 h-16 bg-card rounded-xl mx-auto"></div>
              <p className="text-sm text-muted-foreground">Card</p>
                  </div>
            <div className="space-y-2">
              <div className="w-16 h-16 bg-primary rounded-xl mx-auto"></div>
              <p className="text-sm text-muted-foreground">Primary (Gold)</p>
                    </div>
            <div className="space-y-2">
              <div className="w-16 h-16 bg-secondary rounded-xl mx-auto"></div>
              <p className="text-sm text-muted-foreground">Secondary</p>
                </div>
          </div>
        </section>

        {/* Campus Action Buttons */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Campus Action Buttons</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <HiveCard>
              <h3 className="font-semibold mb-4">Essential Actions</h3>
              <div className="space-y-3">
                <HiveButton intent="primary" size="lg" className="w-full">
                  Join This Space
                </HiveButton>
                <HiveButton intent="urgent" className="w-full">
                  RSVP NOW - 3 Spots Left
                </HiveButton>
                <HiveButton intent="secondary" className="w-full">
                  View Details
                </HiveButton>
              </div>
            </HiveCard>

            <HiveCard>
              <h3 className="font-semibold mb-4">Social Actions</h3>
              <div className="space-y-3">
                <HiveButton intent="social" className="w-full">
                  Invite Friends
                </HiveButton>
                <HiveButton intent="social" size="sm" className="w-full">
                  Share Event
                </HiveButton>
                <HiveButton intent="destructive" size="sm" className="w-full">
                  Leave Space
                </HiveButton>
              </div>
            </HiveCard>

            <HiveCard>
              <h3 className="font-semibold mb-4">Loading States</h3>
              <div className="space-y-3">
                <HiveButton intent="primary" loading className="w-full">
                  Creating Event
                </HiveButton>
                <HiveButton intent="urgent" loading className="w-full">
                  Joining Queue
                </HiveButton>
                <HiveButton intent="secondary" loading className="w-full">
                  Loading
                </HiveButton>
              </div>
            </HiveCard>
          </div>
        </section>

        {/* Campus Content Cards */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Campus Content Cards</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Live Event */}
            <HiveCard context="event" status="live" onClick={() => alert('Opening event')}>
              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <HiveAvatar 
                    fallback="CS"
                    role="builder"
                    status="online"
                    size="default"
                  />
                <div>
                    <h3 className="font-semibold">Study Group Tonight</h3>
                    <p className="text-sm text-muted-foreground">Computer Science Building</p>
                </div>
                </div>
                <p className="text-muted-foreground">
                  Finals prep session for CS-101. Bring your laptop and charger!
                </p>
                <div className="flex items-center justify-between">
                  <Badge variant="secondary" className="bg-green-500/10 text-green-400">
                    23 going
                  </Badge>
                  <span className="text-sm text-muted-foreground">7:00 PM</span>
                </div>
              </div>
            </HiveCard>

            {/* Community Poll */}
            <HiveCard context="poll" status="new">
              <div className="space-y-4">
                <h3 className="font-semibold">Where should we eat?</h3>
                <div className="space-y-2">
                  <div className="flex justify-between items-center p-3 bg-background rounded-lg border">
                    <span>Campus Dining</span>
                    <span className="text-sm text-muted-foreground">12 votes</span>
                </div>
                  <div className="flex justify-between items-center p-3 bg-background rounded-lg border">
                    <span>Downtown</span>
                    <span className="text-sm text-muted-foreground">8 votes</span>
                </div>
                </div>
                <HiveButton intent="social" size="sm">Cast Vote</HiveButton>
              </div>
            </HiveCard>

            {/* Student Group */}
            <HiveCard context="group" status="popular">
                <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold">Photography Club</h3>
                  <Badge className="bg-blue-500/10 text-blue-400">Official</Badge>
                </div>
                <p className="text-muted-foreground">
                  Weekly photo walks around campus and downtown
                </p>
                <div className="flex items-center gap-2">
                  <div className="flex -space-x-2">
                    <HiveAvatar fallback="A" size="sm" />
                    <HiveAvatar fallback="B" size="sm" />
                    <HiveAvatar fallback="C" size="sm" />
                  </div>
                  <span className="text-sm text-muted-foreground">+47 members</span>
                </div>
              </div>
            </HiveCard>
          </div>
        </section>

        {/* Student Expression Inputs */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Student Expression</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-6">
              <HiveInput 
                label="Event Title"
                placeholder="What's happening on campus?"
                helper="Make it catchy and descriptive"
              />
              <HiveInput 
                variant="poll-option"
                placeholder="Add a poll option..."
              />
            </div>
            <div className="space-y-6">
              <HiveInput 
                variant="anonymous"
                placeholder="Share feedback anonymously..."
                helper="Your identity is completely protected"
              />
              <HiveInput 
                variant="live-chat"
                placeholder="Type a message..."
              />
              </div>
          </div>
        </section>

        {/* Campus Identity & Status */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Campus Identity</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <HiveCard>
              <h3 className="font-semibold mb-4">Student Leadership</h3>
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <HiveAvatar 
                    fallback="SC"
                    role="ra"
                    status="online"
                    src="https://images.unsplash.com/photo-1494790108755-2616b332c371?w=64&h=64&fit=crop&crop=face"
                  />
                  <div>
                    <p className="font-medium">Sarah Chen</p>
                    <Badge className="bg-blue-500/10 text-blue-400">Resident Advisor</Badge>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <HiveAvatar 
                    fallback="AK"
                    role="builder"
                    status="busy"
                  />
                  <div>
                    <p className="font-medium">Alex Kim</p>
                    <Badge className="bg-primary/10 text-primary">Space Builder</Badge>
                  </div>
                </div>
              </div>
            </HiveCard>

            <HiveCard>
              <h3 className="font-semibold mb-4">Event Status</h3>
              <div className="space-y-3">
                <Badge className="hive-status-live">LIVE NOW</Badge>
                <Badge className="hive-status-ending-soon">ENDING SOON</Badge>
                <Badge className="hive-status-popular">TRENDING</Badge>
                <Badge className="hive-status-full">FULL</Badge>
              </div>
            </HiveCard>

            <HiveCard context="announcement" status="ending-soon">
              <h3 className="font-semibold mb-2">Housing Applications</h3>
              <p className="text-muted-foreground mb-4">
                Priority deadline is tomorrow! Complete your application to secure your spot.
              </p>
              <HiveButton intent="urgent" size="sm">Apply Now</HiveButton>
            </HiveCard>
          </div>
        </section>

        {/* Real Campus Scenarios */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Real Campus Scenarios</h2>
          <div className="space-y-4">
            {/* Urgent Campus Event */}
            <HiveCard context="event" status="full">
              <div className="flex items-center justify-between">
                <div className="space-y-2">
                  <h3 className="font-semibold">Free Pizza in Student Union</h3>
                  <p className="text-muted-foreground">First 50 students - bring your student ID</p>
                  <div className="flex items-center gap-2">
                    <Badge className="hive-status-full">FULL</Badge>
                    <span className="text-sm text-muted-foreground">Waitlist available</span>
                  </div>
                </div>
                <HiveButton intent="secondary" size="sm">Join Waitlist</HiveButton>
                  </div>
            </HiveCard>

            {/* Group Formation */}
            <HiveCard context="group" status="new">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-semibold">Need 2 more for intramural volleyball team</h3>
                  <Badge className="bg-green-500/10 text-green-400">4/6 spots filled</Badge>
                </div>
                <p className="text-muted-foreground">
                  Casual competitive team for spring season. Practice Tuesday & Thursday evenings.
                  All skill levels welcome!
                  </p>
                <div className="flex justify-between items-center">
                  <div className="flex items-center gap-2">
                    <HiveAvatar fallback="MJ" status="online" size="sm" />
                    <span className="text-sm text-muted-foreground">Posted by Mike Johnson</span>
                  </div>
                  <HiveButton intent="social" size="sm">I'm Interested</HiveButton>
                </div>
              </div>
            </HiveCard>
          </div>
        </section>
      </div>
    </div>
  );
} 