'use client'

import {
  HiveCard,
  HiveCardContent,
  HiveCardDescription,
  HiveCardFooter,
  HiveCardHeader,
  HiveCardTitle,
} from '@/components/ui/card'
import { Button } from '@hive/ui-core'
import { Check, Plus, Rocket } from 'lucide-react'

export default function DesignSystemV2Page() {
  return (
    <div className="bg-background min-h-screen p-8 text-foreground">
      <div className="max-w-6xl mx-auto space-y-16">
        <header className="text-center space-y-2">
          <h1 className="text-4xl font-semibold text-primary">
            HIVE Design System v2
          </h1>
          <p className="text-lg text-muted-foreground">
            AI-Native Presence & Pill-First Language
          </p>
        </header>

        {/* Button Showcase */}
        <section className="space-y-8">
          <h2 className="text-2xl font-medium border-b border-border pb-2">
            Buttons
          </h2>
          <div className="flex flex-wrap gap-6 items-center">
            <Button>Primary</Button>
            <Button variant="secondary">Secondary</Button>
            <Button variant="destructive">Destructive</Button>
            <Button variant="ghost">Ghost</Button>
            <Button variant="link">Link</Button>
            <Button size="lg">Large Button</Button>
            <Button size="sm">Small Button</Button>
            <Button>
              <Plus className="mr-2 h-4 w-4" /> Add Tool
            </Button>
            <Button disabled>
              <Rocket className="mr-2 h-4 w-4" /> Surging
            </Button>
          </div>
        </section>

        {/* Card Showcase */}
        <section className="space-y-8">
          <h2 className="text-2xl font-medium border-b border-border pb-2">
            Cards
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <HiveCard>
              <HiveCardHeader>
                <HiveCardTitle>Standard Card</HiveCardTitle>
                <HiveCardDescription>
                  Surface-1 for tool blocks & content
                </HiveCardDescription>
              </HiveCardHeader>
              <HiveCardContent>
                <p>
                  This is the default card style, using the base surface color
                  and shadow tokens.
                </p>
              </HiveCardContent>
              <HiveCardFooter>
                <Button className="w-full">
                  <Check className="mr-2 h-4 w-4" /> Commit Action
                </Button>
              </HiveCardFooter>
            </HiveCard>

            <HiveCard className="shadow-md">
              <HiveCardHeader>
                <HiveCardTitle>Elevated Card</HiveCardTitle>
                <HiveCardDescription>
                  Surface-2 for modals & dialogs
                </HiveCardDescription>
              </HiveCardHeader>
              <HiveCardContent>
                <p>
                  This card uses a higher elevation shadow to appear more
                  prominently.
                </p>
              </HiveCardContent>
              <HiveCardFooter>
                <Button variant="secondary" className="w-full">
                  Secondary Action
                </Button>
              </HiveCardFooter>
            </HiveCard>

            <HiveCard intent="glass">
              <HiveCardHeader>
                <HiveCardTitle>Glass Card</HiveCardTitle>
                <HiveCardDescription>
                  Optional holographic AI vibe
                </HiveCardDescription>
              </HiveCardHeader>
              <HiveCardContent>
                <p>
                  Used for special ritual banners to create a futuristic,
                  semi-transparent feel.
                </p>
              </HiveCardContent>
              <HiveCardFooter>
                <Button variant="ghost" className="w-full">
                  Ghost Action
                </Button>
              </HiveCardFooter>
            </HiveCard>
          </div>
        </section>
      </div>
    </div>
  )
} 