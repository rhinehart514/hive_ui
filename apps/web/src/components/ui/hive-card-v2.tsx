'use client'

import * as React from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { cn } from '@/lib/utils'
import { cva, type VariantProps } from 'class-variance-authority'

const hiveCardVariants = cva(
  // Apple-inspired base styling with clean lines and subtle depth
  "relative overflow-hidden transition-all duration-500 ease-out",
  {
    variants: {
      variant: {
        // Clean Apple-style card
        default: [
          "bg-hive-bg-surface-1/90 backdrop-blur-xl",
          "border border-hive-border/40 rounded-2xl",
          "shadow-[0_1px_3px_rgba(0,0,0,0.4)]",
          "hover:shadow-[0_8px_25px_rgba(0,0,0,0.6)]"
        ],
        
        // Premium glass card like Apple's iOS
        glass: [
          "bg-hive-bg-surface-1/60 backdrop-blur-2xl",
          "border border-white/[0.08] rounded-2xl",
          "shadow-[0_1px_3px_rgba(0,0,0,0.3),inset_0_1px_0_rgba(255,255,255,0.1)]",
          "hover:shadow-[0_8px_25px_rgba(0,0,0,0.5)]"
        ],
        
        // ChatGPT conversation bubble style
        conversation: [
          "bg-hive-bg-surface-1/95 backdrop-blur-xl",
          "border border-hive-border/30 rounded-3xl",
          "shadow-[0_2px_8px_rgba(0,0,0,0.4)]",
          "hover:shadow-[0_4px_16px_rgba(0,0,0,0.5)]"
        ],
        
        // AI assistant panel style
        assistant: [
          "bg-gradient-to-br from-hive-bg-surface-1/95 to-hive-bg-surface-2/95",
          "border border-hive-border/20 rounded-2xl backdrop-blur-xl",
          "shadow-[0_1px_3px_rgba(0,0,0,0.4),0_8px_24px_rgba(0,0,0,0.15)]",
          "hover:shadow-[0_8px_32px_rgba(0,0,0,0.25)]"
        ],
        
        // Gold accent card for premium features
        premium: [
          "bg-gradient-to-br from-hive-bg-surface-1/95 to-hive-bg-surface-2/95",
          "border border-hive-accent/20 rounded-2xl backdrop-blur-xl",
          "shadow-[0_1px_3px_rgba(255,215,0,0.1),0_8px_24px_rgba(0,0,0,0.4)]",
          "hover:shadow-[0_8px_32px_rgba(255,215,0,0.15)]"
        ]
      },
      size: {
        sm: "p-4",
        default: "p-6", 
        lg: "p-8",
        xl: "p-10"
      },
      spacing: {
        tight: "space-y-2",
        normal: "space-y-4",
        relaxed: "space-y-6"
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default",
      spacing: "normal"
    }
  }
)

interface HiveCardV2Props 
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof hiveCardVariants> {
  hover?: boolean
  physics?: boolean
  glow?: boolean
  children?: React.ReactNode
}

const HiveCardV2 = React.forwardRef<HTMLDivElement, HiveCardV2Props>(
  ({ className, variant, size, spacing, hover = true, physics = true, glow = false, children, ...props }, ref) => {
    const [isHovered, setIsHovered] = React.useState(false)
    
    const cardMotionProps = physics ? {
      whileHover: { 
        y: -2,
        scale: 1.005,
        transition: { 
          type: "spring", 
          stiffness: 400, 
          damping: 25,
          mass: 0.8
        }
      },
      whileTap: { 
        scale: 0.995,
        transition: { 
          type: "spring", 
          stiffness: 600, 
          damping: 30 
        }
      }
    } : {}

    return (
      <motion.div
        ref={ref}
        className={cn(hiveCardVariants({ variant, size, spacing }), className)}
        onHoverStart={() => setIsHovered(true)}
        onHoverEnd={() => setIsHovered(false)}
        {...cardMotionProps}
        {...props}
      >
        {/* Subtle AI glow effect */}
        <AnimatePresence>
          {glow && isHovered && (
            <motion.div
              className="absolute inset-0 pointer-events-none rounded-2xl"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.4 }}
              style={{
                background: 'radial-gradient(600px circle at var(--mouse-x) var(--mouse-y), rgba(255,215,0,0.06), transparent 40%)',
              }}
            />
          )}
        </AnimatePresence>
        
        {/* Apple-style inner highlight */}
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent" />
        
        {/* Content */}
        <div className="relative z-10">
          {children}
        </div>
      </motion.div>
    )
  }
)
HiveCardV2.displayName = "HiveCardV2"

// Apple-style card header
interface HiveCardHeaderV2Props extends React.HTMLAttributes<HTMLDivElement> {
  subtitle?: string
  badge?: React.ReactNode
}

const HiveCardHeaderV2 = React.forwardRef<HTMLDivElement, HiveCardHeaderV2Props>(
  ({ className, subtitle, badge, children, ...props }, ref) => (
    <div
      ref={ref}
      className={cn("flex items-start justify-between mb-6", className)}
      {...props}
    >
      <div className="flex-1 min-w-0">
        {children}
        {subtitle && (
          <p className="text-sm text-hive-text-secondary mt-1 leading-relaxed">
            {subtitle}
          </p>
        )}
      </div>
      {badge && (
        <div className="ml-4 flex-shrink-0">
          {badge}
        </div>
      )}
    </div>
  )
)
HiveCardHeaderV2.displayName = "HiveCardHeaderV2"

// Clean Apple-style title
const HiveCardTitleV2 = React.forwardRef<HTMLHeadingElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, children, ...props }, ref) => (
    <h3
      ref={ref}
      className={cn(
        "text-lg font-semibold text-hive-text-primary leading-tight tracking-[-0.01em]",
        className
      )}
      {...props}
    >
      {children}
    </h3>
  )
)
HiveCardTitleV2.displayName = "HiveCardTitleV2"

// Clean content area
const HiveCardContentV2 = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div 
      ref={ref} 
      className={cn("text-hive-text-primary space-y-4", className)} 
      {...props} 
    />
  )
)
HiveCardContentV2.displayName = "HiveCardContentV2"

// Apple-style footer with clean actions
interface HiveCardFooterV2Props extends React.HTMLAttributes<HTMLDivElement> {
  border?: boolean
}

const HiveCardFooterV2 = React.forwardRef<HTMLDivElement, HiveCardFooterV2Props>(
  ({ className, border = false, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        "flex items-center justify-between mt-6 pt-4",
        border && "border-t border-hive-border/30",
        className
      )}
      {...props}
    />
  )
)
HiveCardFooterV2.displayName = "HiveCardFooterV2"

// ChatGPT-style message bubble
interface HiveChatBubbleProps extends React.HTMLAttributes<HTMLDivElement> {
  role?: 'user' | 'assistant' | 'system'
  avatar?: React.ReactNode
  timestamp?: string
}

const HiveChatBubble = React.forwardRef<HTMLDivElement, HiveChatBubbleProps>(
  ({ className, role = 'assistant', avatar, timestamp, children, ...props }, ref) => {
    const isUser = role === 'user'
    
    return (
      <motion.div
        ref={ref}
        className={cn(
          "flex gap-3 max-w-4xl",
          isUser ? "flex-row-reverse ml-auto" : "mr-auto",
          className
        )}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        {...props}
      >
        {/* Avatar */}
        <div className={cn(
          "flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-xs font-medium",
          isUser 
            ? "bg-hive-accent text-black" 
            : "bg-hive-bg-surface-2 text-hive-text-secondary border border-hive-border/40"
        )}>
          {avatar || (isUser ? "You" : "AI")}
        </div>
        
        {/* Message content */}
        <div className={cn(
          "flex-1 min-w-0 bg-hive-bg-surface-1/60 backdrop-blur-xl rounded-2xl p-4",
          "border border-hive-border/30 shadow-[0_1px_3px_rgba(0,0,0,0.3)]",
          isUser && "bg-hive-accent/10 border-hive-accent/20"
        )}>
          <div className="prose prose-invert prose-sm max-w-none">
            {children}
          </div>
          {timestamp && (
            <div className="mt-2 text-xs text-hive-text-secondary">
              {timestamp}
            </div>
          )}
        </div>
      </motion.div>
    )
  }
)
HiveChatBubble.displayName = "HiveChatBubble"

export { 
  HiveCardV2, 
  HiveCardHeaderV2, 
  HiveCardTitleV2, 
  HiveCardContentV2, 
  HiveCardFooterV2,
  HiveChatBubble,
  hiveCardVariants 
} 