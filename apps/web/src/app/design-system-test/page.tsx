'use client'

import {
  HiveCard,
  HiveCardContent,
  HiveCardDescription,
  HiveCardFooter,
  HiveCardHeader,
  HiveCardTitle,
} from '@/components/ui/hive-card'
import { HiveInput } from '@/components/ui/hive-input'
import { HiveButton } from '@/components/ui/hive-button'
import { HiveModal, HiveModalContent, HiveModalTrigger, HiveModalHeader, HiveModalTitle } from '@/components/ui/hive-modal'
import { HiveTabsA, HiveTabsB, HiveTabsC } from '@/components/ui/hive-tabs-variants'
import { Check, Plus, Rocket } from 'lucide-react'

export default function DesignSystemTestPage() {
  return (
    <div className="bg-background min-h-screen p-8 sm:p-16 text-foreground font-body">
      <div className="max-w-7xl mx-auto space-y-24">
        <header className="text-center space-y-4">
          <h1 className="text-5xl font-display font-bold text-primary tracking-tight">
            HIVE Design System
          </h1>
          <p className="text-lg text-muted-foreground">
            A showcase of our core components, infused with the HIVE aesthetic.
          </p>
        </header>

        {/* ================================================================== */}
        {/* TABS SHOWCASE */}
        {/* ================================================================== */}
        <section className="space-y-8">
          <h2 className="text-3xl font-display font-semibold border-b border-border pb-4">
            Tabs Variants
          </h2>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-12 items-start">

            {/* Variant A */}
            <div className="space-y-4">
              <h3 className="text-xl font-display font-medium">Variant A: Sliding Underline</h3>
              <HiveTabsA.Root defaultValue="account">
                <HiveTabsA.List>
                  <HiveTabsA.Trigger value="account">Account</HiveTabsA.Trigger>
                  <HiveTabsA.Trigger value="password">Password</HiveTabsA.Trigger>
                  <HiveTabsA.Trigger value="notifications">Notifications</HiveTabsA.Trigger>
                </HiveTabsA.List>
                <HiveTabsA.Content value="account" className="mt-4 text-sm text-muted-foreground">
                  Variant A uses a simple, clean underline that slides into place with a spring animation.
                </HiveTabsA.Content>
              </HiveTabsA.Root>
            </div>

            {/* Variant B */}
            <div className="space-y-4">
              <h3 className="text-xl font-display font-medium">Variant B: Moving Pill</h3>
              <HiveTabsB.Root defaultValue="spaces">
                <HiveTabsB.List>
                  <HiveTabsB.Trigger value="spaces">Spaces</HiveTabsB.Trigger>
                  <HiveTabsB.Trigger value="events">Events</HiveTabsB.Trigger>
                  <HiveTabsB.Trigger value="rituals">Rituals</HiveTabsB.Trigger>
                </HiveTabsB.List>
                 <HiveTabsB.Content value="spaces" className="mt-4 text-sm text-muted-foreground">
                  Variant B uses a "pill" shape that moves behind the active tab, providing a modern feel.
                </HiveTabsB.Content>
              </HiveTabsB.Root>
            </div>
            
            {/* Variant C */}
            <div className="space-y-4">
              <h3 className="text-xl font-display font-medium">Variant C: Glass Buttons</h3>
              <HiveTabsC.Root defaultValue="profile">
                <HiveTabsC.List>
                  <HiveTabsC.Trigger value="profile">Profile</HiveTabsC.Trigger>
                  <HiveTabsC.Trigger value="tools">My Tools</HiveTabsC.Trigger>
                  <HiveTabsC.Trigger value="settings">Settings</HiveTabsC.Trigger>
                </HiveTabsC.List>
                <HiveTabsC.Content value="profile" className="mt-4 text-sm text-muted-foreground">
                  Variant C has a glowing underline, giving it a more futuristic, "glass" aesthetic.
                </HiveTabsC.Content>
              </HiveTabsC.Root>
            </div>
            
          </div>
        </section>

        {/* ================================================================== */}
        {/* CARD SHOWCASE */}
        {/* ================================================================== */}
        <section className="space-y-8">
          <h2 className="text-3xl font-display font-semibold border-b border-border pb-4">
            Cards
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <HiveCard intent="default">
              <HiveCardHeader>
                <HiveCardTitle>Default Card</HiveCardTitle>
              </HiveCardHeader>
              <HiveCardContent>
                <p>The base card component with a subtle gradient and border.</p>
              </HiveCardContent>
            </HiveCard>

            <HiveCard intent="event">
              <HiveCardHeader>
                <HiveCardTitle>Event Card</HiveCardTitle>
              </HiveCardHeader>
              <HiveCardContent>
                <p>An event-specific card, highlighted with a primary color border.</p>
              </HiveCardContent>
            </HiveCard>

            <HiveCard intent="default" urgency="urgent">
              <HiveCardHeader>
                <HiveCardTitle>Urgent Card</HiveCardTitle>
              </HiveCardHeader>
              <HiveCardContent>
                <p>A card with an urgent state, signified by a glowing ring.</p>
              </HiveCardContent>
            </HiveCard>
          </div>
        </section>

        {/* ================================================================== */}
        {/* BUTTON & INPUT SHOWCASE */}
        {/* ================================================================== */}
        <section className="space-y-8">
          <h2 className="text-3xl font-display font-semibold border-b border-border pb-4">
            Buttons & Inputs
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
            <div className="space-y-6">
              <h3 className="text-xl font-display font-medium">Buttons</h3>
               <div className="flex flex-wrap gap-4 items-center">
                <HiveButton>Primary</HiveButton>
                <HiveButton intent="secondary">Secondary</HiveButton>
                <HiveButton intent="destructive">Destructive</HiveButton>
                <HiveButton intent="social">Social</HiveButton>
                <HiveButton loading>Loading</HiveButton>
                <HiveButton size="lg">Large</HiveButton>
              </div>
            </div>
             <div className="space-y-6">
              <h3 className="text-xl font-display font-medium">Inputs</h3>
              <div className="space-y-4">
                <HiveInput label="Default" placeholder="Enter your email..." />
                <HiveInput intent="live-chat" label="Live Chat" placeholder="Type your message..." />
                <HiveInput intent="anonymous" label="Anonymous" placeholder="Your anonymous feedback" />
                <HiveInput label="With Error" placeholder="Enter valid data" error="This field is required." />
              </div>
            </div>
          </div>
        </section>

        {/* ================================================================== */}
        {/* MODAL SHOWCASE */}
        {/* ================================================================== */}
        <section className="space-y-8">
          <h2 className="text-3xl font-display font-semibold border-b border-border pb-4">
            Modal
          </h2>
          <HiveModal>
            <HiveModalTrigger asChild>
              <HiveButton>Open Modal</HiveButton>
            </HiveModalTrigger>
            <HiveModalContent>
              <HiveModalHeader>
                <HiveModalTitle>Modal Title</HiveModalTitle>
              </HiveModalHeader>
              <div className="p-4">This is the modal content area.</div>
            </HiveModalContent>
          </HiveModal>
        </section>

      </div>
    </div>
  )
} 