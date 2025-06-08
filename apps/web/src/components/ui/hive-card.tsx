'use client'

import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'

// HIVE Card Variants - Infused with glassmorphism, gradients, and physics.
const hiveCardVariants = cva(
  "relative rounded-2xl border p-6 transition-all duration-300 ease-out overflow-hidden group glass-card gradient-card",
  {
    variants: {
      intent: {
        default: "border-white/10",
        event: "border-primary/20",
        poll: "border-blue-500/20",
        announcement: "border-orange-500/20",
        group: "border-green-500/20",
      },
      urgency: {
        standard: "",
        urgent: "ring-2 ring-primary/50 glow-accent animate-pulse-subtle",
      },
      liveStatus: {
        none: "",
        live: "ring-2 ring-red-500/50",
      },
    },
    defaultVariants: {
      intent: "default",
      urgency: "standard",
      liveStatus: "none",
    },
  }
)

export interface HiveCardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof hiveCardVariants> {
  interactive?: boolean;
}

const HiveCard = React.forwardRef<HTMLDivElement, HiveCardProps>(
  ({ className, intent, urgency, liveStatus, interactive = true, children, ...props }, ref) => {
    return (
      <motion.div
        ref={ref}
        className={cn(hiveCardVariants({ intent, urgency, liveStatus }), className)}
        whileHover={interactive ? { y: -4, scale: 1.02, transition: { type: 'spring', stiffness: 300, damping: 20 } } : {}}
        whileTap={interactive ? { scale: 0.98, transition: { type: 'spring', stiffness: 400, damping: 25 } } : {}}
        {...props}
      >
        {liveStatus === 'live' && (
           <div className="absolute top-4 right-4 flex items-center gap-2">
             <span className="relative flex h-3 w-3">
               <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
               <span className="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
             </span>
             <span className="text-xs font-semibold uppercase text-red-400">LIVE</span>
           </div>
        )}
        {children}
      </motion.div>
    )
  }
)
HiveCard.displayName = "HiveCard"

// Sub-components remain largely the same, but benefit from the parent's new look and feel.

const HiveCardHeader = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn("flex flex-col space-y-1.5", className)}
      {...props}
    />
  )
)
HiveCardHeader.displayName = "HiveCardHeader"

const HiveCardTitle = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, ...props }, ref) => (
    <h3
      ref={ref}
      className={cn("text-lg font-semibold leading-none tracking-tight text-foreground", className)}
      {...props}
    />
  )
)
HiveCardTitle.displayName = "HiveCardTitle"

const HiveCardDescription = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLParagraphElement>>(
  ({ className, ...props }, ref) => (
    <p
      ref={ref}
      className={cn("text-sm text-muted-foreground", className)}
      {...props}
    />
  )
)
HiveCardDescription.displayName = "HiveCardDescription"

const HiveCardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("pt-4", className)} {...props} />
  )
)
HiveCardContent.displayName = "HiveCardContent"

const HiveCardFooter = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn("flex items-center pt-4", className)}
      {...props}
    />
  )
)
HiveCardFooter.displayName = "HiveCardFooter"

export {
  HiveCard,
  HiveCardHeader,
  HiveCardTitle,
  HiveCardDescription,
  HiveCardContent,
  HiveCardFooter,
  hiveCardVariants,
} 