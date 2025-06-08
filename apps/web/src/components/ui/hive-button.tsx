'use client'

import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { motion } from "framer-motion"
import { cn } from "@/lib/utils"

// Apple-like HIVE Button Variants - Rounded, Purposeful
const hiveButtonVariants = cva(
  // Base: Apple-like rounded buttons with proper physics
  "inline-flex items-center justify-center whitespace-nowrap rounded-2xl text-sm font-semibold transition-all duration-150 ease-out focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 active:scale-[0.98]",
  {
    variants: {
      intent: {
        // Primary - Sacred gold for decisive moments
        primary: [
          "bg-primary text-primary-foreground",
          "hover:bg-primary/90",
          "shadow-[0_2px_8px_rgba(255,215,0,0.3)]",
          "hover:shadow-[0_4px_16px_rgba(255,215,0,0.4)]"
        ],
        
        // Urgent - Pulsing gold for time-sensitive actions
        urgent: [
          "bg-primary text-primary-foreground font-bold",
          "hover:bg-primary/90",
          "shadow-[0_4px_20px_rgba(255,215,0,0.5)]",
          "hover:shadow-[0_6px_24px_rgba(255,215,0,0.6)]",
          "animate-pulse-subtle"
        ],
        
        // Social - Blue for community actions
        social: [
          "bg-blue-500/10 text-blue-400 border border-blue-500/30",
          "hover:bg-blue-500/20 hover:border-blue-500/50",
          "shadow-[0_2px_8px_rgba(59,130,246,0.2)]"
        ],
        
        // Secondary - Clean transparent
        secondary: [
          "bg-secondary text-secondary-foreground border border-border",
          "hover:bg-secondary/80",
          "shadow-[0_1px_3px_rgba(0,0,0,0.2)]"
        ],
        
        // Destructive - Red for dangerous actions
        destructive: [
          "bg-destructive/10 text-destructive border border-destructive/30",
          "hover:bg-destructive/20 hover:border-destructive/50",
          "shadow-[0_2px_8px_rgba(255,59,48,0.2)]"
        ],
        
        // Ghost - Minimal for subtle actions
        ghost: [
          "text-foreground",
          "hover:bg-accent hover:text-accent-foreground"
        ]
      },
      
      size: {
        sm: "h-9 px-4 text-xs",
        md: "h-10 px-6 text-sm",
        lg: "h-12 px-8 text-base",
        icon: "h-10 w-10"
      },
      
      // Campus-specific states
      campusState: {
        none: "",
        live: [
          "relative",
          "before:absolute before:-top-1 before:-right-1 before:w-3 before:h-3 before:bg-red-500 before:rounded-full before:animate-pulse"
        ],
        popular: [
          "relative",
          "after:absolute after:-top-2 after:-right-2 after:px-1.5 after:py-0.5 after:bg-green-500 after:text-white after:text-xs after:font-bold after:rounded-full after:content-['🔥']"
        ],
        new: [
          "relative",
          "after:absolute after:-top-2 after:-right-2 after:px-1.5 after:py-0.5 after:bg-primary after:text-primary-foreground after:text-xs after:font-bold after:rounded-full after:content-['NEW']"
        ]
      }
    },
    defaultVariants: {
      intent: "primary",
      size: "md",
      campusState: "none"
    }
  }
)

// Campus-specific button props
export interface HiveButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof hiveButtonVariants> {
  asChild?: boolean
  intent?: 'primary' | 'urgent' | 'social' | 'secondary' | 'destructive' | 'ghost'
  campusState?: 'none' | 'live' | 'popular' | 'new'
  loading?: boolean
}

const HiveButton = React.forwardRef<HTMLButtonElement, HiveButtonProps>(
  ({ className, intent, size, campusState, asChild = false, loading, children, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    
    return (
      <Comp
        className={cn(hiveButtonVariants({ intent, size, campusState, className }))}
        ref={ref}
        disabled={loading || props.disabled}
        {...props}
      >
        {loading ? (
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
            <span>Loading...</span>
          </div>
        ) : (
          children
        )}
      </Comp>
    )
  }
)
HiveButton.displayName = "HiveButton"

// Campus action presets - Apple-like with HIVE context
export const CampusActions = {
  JoinEvent: (props: Partial<HiveButtonProps>) => (
    <HiveButton intent="urgent" {...props}>
      Join Event
    </HiveButton>
  ),
  
  RSVP: (props: Partial<HiveButtonProps>) => (
    <HiveButton intent="primary" {...props}>
      RSVP
    </HiveButton>
  ),
  
  InviteFriends: (props: Partial<HiveButtonProps>) => (
    <HiveButton intent="social" {...props}>
      Invite Friends
    </HiveButton>
  ),
  
  CreateTool: (props: Partial<HiveButtonProps>) => (
    <HiveButton intent="primary" campusState="new" {...props}>
      Create Tool
    </HiveButton>
  ),
  
  RequestBuilder: (props: Partial<HiveButtonProps>) => (
    <HiveButton intent="urgent" {...props}>
      Request Builder Access
    </HiveButton>
  ),
  
  LeaveSpace: (props: Partial<HiveButtonProps>) => (
    <HiveButton intent="destructive" {...props}>
      Leave Space
    </HiveButton>
  )
}

export { HiveButton, hiveButtonVariants } 