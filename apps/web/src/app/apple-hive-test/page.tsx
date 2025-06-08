'use client'

import { HiveCard, HiveCardHeader, HiveCardTitle, HiveCardDescription, HiveCardContent } from '@/components/ui/hive-card'
import { HiveButton, CampusActions } from '@/components/ui/hive-button'

export default function AppleHiveTestPage() {
  return (
    <div className="min-h-screen bg-background p-8">
      <div className="max-w-6xl mx-auto space-y-8">
        
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold text-foreground">
            HIVE Apple-Like Design System
          </h1>
          <p className="text-lg text-muted-foreground">
            Polished black glass with crisp rounded corners - no sharp edges
          </p>
        </div>

        {/* Button Showcase */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Apple-Like Buttons</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <HiveButton intent="primary">Primary</HiveButton>
            <HiveButton intent="urgent">Urgent</HiveButton>
            <HiveButton intent="social">Social</HiveButton>
            <HiveButton intent="secondary">Secondary</HiveButton>
            <HiveButton intent="destructive">Destructive</HiveButton>
            <HiveButton intent="ghost">Ghost</HiveButton>
          </div>
          
          {/* Campus Action Presets */}
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <CampusActions.JoinEvent />
            <CampusActions.RSVP />
            <CampusActions.InviteFriends />
            <CampusActions.CreateTool />
            <CampusActions.RequestBuilder />
            <CampusActions.LeaveSpace />
          </div>
        </section>

        {/* Card Showcase */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">Apple-Like Cards</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            
            {/* Default Card */}
            <HiveCard intent="default">
              <HiveCardHeader>
                <HiveCardTitle>CS Department Mixer</HiveCardTitle>
                <HiveCardDescription>
                  Connect with fellow CS students and faculty
                </HiveCardDescription>
              </HiveCardHeader>
              <HiveCardContent>
                <p className="text-sm text-muted-foreground">
                  Friday, 6:00 PM • Davis Hall Atrium
                </p>
              </HiveCardContent>
            </HiveCard>

            {/* Event Card */}
            <HiveCard 
              intent="event" 
              urgency="urgent"
              participantCount={47}
              timeRemaining="2h left"
              onJoin={() => console.log('Joined event')}
            >
              <HiveCardHeader>
                <HiveCardTitle>Study Group - Algorithms</HiveCardTitle>
                <HiveCardDescription>
                  Final exam prep session
                </HiveCardDescription>
              </HiveCardHeader>
              <HiveCardContent>
                <p className="text-sm text-muted-foreground">
                  Tonight, 8:00 PM • Lockwood Library
                </p>
              </HiveCardContent>
            </HiveCard>

            {/* Poll Card */}
            <HiveCard 
              intent="poll"
              liveStatus="live"
              participantCount={23}
              builderName="Sarah K."
            >
              <HiveCardHeader>
                <HiveCardTitle>Best Study Spot on Campus?</HiveCardTitle>
                <HiveCardDescription>
                  Help fellow students find the perfect study environment
                </HiveCardDescription>
              </HiveCardHeader>
              <HiveCardContent>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Lockwood Library</span>
                    <span className="text-primary">45%</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>Student Union</span>
                    <span className="text-primary">32%</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>Capen Hall</span>
                    <span className="text-primary">23%</span>
                  </div>
                </div>
              </HiveCardContent>
            </HiveCard>

          </div>
        </section>

        {/* Color Palette */}
        <section className="space-y-6">
          <h2 className="text-2xl font-semibold text-foreground">HIVE Color Palette</h2>
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="space-y-2">
              <div className="w-full h-16 bg-background rounded-2xl border border-border"></div>
              <p className="text-sm text-center">Background<br/>#0A0A0A</p>
            </div>
            
            <div className="space-y-2">
              <div className="w-full h-16 bg-card rounded-2xl"></div>
              <p className="text-sm text-center">Card<br/>#131313</p>
            </div>
            
            <div className="space-y-2">
              <div className="w-full h-16 bg-primary rounded-2xl"></div>
              <p className="text-sm text-center">Primary<br/>#FFD700</p>
            </div>
            
            <div className="space-y-2">
              <div className="w-full h-16 bg-secondary rounded-2xl"></div>
              <p className="text-sm text-center">Secondary<br/>#1A1A1A</p>
            </div>
          </div>
        </section>

      </div>
    </div>
  )
} 