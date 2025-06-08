'use client'

import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'
import { motion, AnimatePresence } from 'framer-motion'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const hiveButtonVariants = cva(
  // Apple-inspired base styling with clean lines and subtle shadows
  "inline-flex items-center justify-center font-medium transition-all duration-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-hive-accent focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-60 relative overflow-hidden",
  {
    variants: {
      variant: {
        // Primary Apple-style button - clean gold
        primary: [
          "bg-hive-accent text-black rounded-xl",
          "shadow-[0_1px_3px_rgba(0,0,0,0.3),0_4px_6px_rgba(255,215,0,0.2)]",
          "hover:shadow-[0_4px_8px_rgba(0,0,0,0.4),0_8px_16px_rgba(255,215,0,0.3)]",
          "active:shadow-[0_1px_2px_rgba(0,0,0,0.4)]",
          "hover:bg-hive-accent-hover transform-gpu"
        ],
        
        // Secondary Apple-style button - clean and minimal
        secondary: [
          "bg-hive-bg-surface-1/80 text-hive-text-primary rounded-xl backdrop-blur-xl",
          "border border-hive-border/40 shadow-[0_1px_3px_rgba(0,0,0,0.3)]",
          "hover:bg-hive-bg-surface-2/80 hover:border-hive-border/60",
          "hover:shadow-[0_4px_8px_rgba(0,0,0,0.4)]",
          "active:shadow-[0_1px_2px_rgba(0,0,0,0.4)]"
        ],
        
        // Ghost button - minimal like Apple's navigation
        ghost: [
          "hover:bg-hive-bg-surface-1/60 text-hive-text-secondary rounded-xl",
          "hover:text-hive-text-primary backdrop-blur-xl",
          "hover:shadow-[0_1px_3px_rgba(0,0,0,0.2)]"
        ],
        
        // Outline button - clean border
        outline: [
          "border border-hive-accent/60 text-hive-accent rounded-xl",
          "bg-transparent hover:bg-hive-accent/10 backdrop-blur-xl",
          "shadow-[0_1px_3px_rgba(0,0,0,0.2)]",
          "hover:shadow-[0_4px_8px_rgba(255,215,0,0.2)]",
          "hover:border-hive-accent"
        ],
        
        // ChatGPT send button style
        send: [
          "bg-hive-accent text-black rounded-full p-2",
          "shadow-[0_2px_4px_rgba(0,0,0,0.3)]",
          "hover:shadow-[0_4px_8px_rgba(0,0,0,0.4)]",
          "hover:bg-hive-accent-hover transform-gpu"
        ],
        
        // Destructive button - clean red
        destructive: [
          "bg-hive-error text-white rounded-xl",
          "shadow-[0_1px_3px_rgba(0,0,0,0.3),0_4px_6px_rgba(255,77,79,0.2)]",
          "hover:shadow-[0_4px_8px_rgba(0,0,0,0.4),0_8px_16px_rgba(255,77,79,0.3)]",
          "hover:bg-hive-error/90"
        ],

        // Link style - minimal
        link: "text-hive-accent underline-offset-4 hover:underline font-normal"
      },
      size: {
        sm: "h-8 px-3 text-sm rounded-lg",
        default: "h-10 px-4 text-sm",
        lg: "h-12 px-6 text-base rounded-xl",
        icon: "h-10 w-10",
        send: "h-8 w-8"
      }
    },
    defaultVariants: {
      variant: "primary",
      size: "default"
    }
  }
)

export interface HiveButtonV2Props
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof hiveButtonVariants> {
  asChild?: boolean
  loading?: boolean
  physics?: boolean
  icon?: React.ReactNode
  iconPosition?: 'left' | 'right'
}

const HiveButtonV2 = React.forwardRef<HTMLButtonElement, HiveButtonV2Props>(
  ({ 
    className, 
    variant, 
    size, 
    asChild = false, 
    loading = false, 
    physics = true,
    icon,
    iconPosition = 'left',
    disabled, 
    children, 
    ...props 
  }, ref) => {
    const Comp = asChild ? Slot : "button"
    const [isPressed, setIsPressed] = React.useState(false)
    const isDisabled = disabled || loading

    // Apple-style physics with subtle movement
    const motionProps = physics ? {
      whileHover: !isDisabled ? { 
        scale: 1.02,
        y: -1,
        transition: { 
          type: "spring", 
          stiffness: 500, 
          damping: 30,
          mass: 0.8
        }
      } : {},
      whileTap: !isDisabled ? { 
        scale: 0.98,
        y: 0,
        transition: { 
          type: "spring", 
          stiffness: 600, 
          damping: 35 
        }
      } : {},
      onTapStart: () => setIsPressed(true),
      onTap: () => setIsPressed(false),
      onTapCancel: () => setIsPressed(false)
    } : {}

    const renderContent = () => {
      if (loading) {
        return (
          <div className="flex items-center gap-2">
            <motion.div
              className="h-4 w-4 rounded-full border-2 border-current border-t-transparent"
              animate={{ rotate: 360 }}
              transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
            />
            {children && <span>{children}</span>}
          </div>
        )
      }

      if (icon && children) {
        return (
          <div className="flex items-center gap-2">
            {iconPosition === 'left' && icon}
            <span>{children}</span>
            {iconPosition === 'right' && icon}
          </div>
        )
      }

      return icon || children
    }

    return (
      <motion.div {...motionProps} className="inline-flex">
        <Comp
          className={cn(hiveButtonVariants({ variant, size, className }))}
          ref={ref}
          disabled={isDisabled}
          {...props}
        >
          {/* Apple-style inner highlight */}
          {variant !== 'ghost' && variant !== 'link' && (
            <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-white/20 to-transparent" />
          )}
          
          {/* Content */}
          <span className="relative z-10">
            {renderContent()}
          </span>

          {/* Subtle press feedback overlay */}
          <AnimatePresence>
            {isPressed && variant !== 'link' && (
              <motion.div
                className="absolute inset-0 bg-black/10 rounded-xl"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.1 }}
              />
            )}
          </AnimatePresence>
        </Comp>
      </motion.div>
    )
  }
)
HiveButtonV2.displayName = "HiveButtonV2"

// Apple-style button group
interface HiveButtonGroupV2Props extends React.HTMLAttributes<HTMLDivElement> {
  orientation?: 'horizontal' | 'vertical'
  spacing?: 'tight' | 'normal' | 'relaxed'
  variant?: 'segmented' | 'toolbar' | 'stack'
}

const HiveButtonGroupV2 = React.forwardRef<HTMLDivElement, HiveButtonGroupV2Props>(
  ({ className, orientation = 'horizontal', spacing = 'normal', variant = 'stack', children, ...props }, ref) => {
    const spacingClasses = {
      tight: orientation === 'horizontal' ? 'gap-1' : 'gap-1',
      normal: orientation === 'horizontal' ? 'gap-2' : 'gap-2', 
      relaxed: orientation === 'horizontal' ? 'gap-4' : 'gap-3'
    }

    const variantClasses = {
      segmented: cn(
        "bg-hive-bg-surface-1/60 backdrop-blur-xl rounded-xl p-1 border border-hive-border/40",
        "shadow-[0_1px_3px_rgba(0,0,0,0.3)]"
      ),
      toolbar: cn(
        "bg-hive-bg-surface-1/80 backdrop-blur-xl rounded-xl p-2 border border-hive-border/30",
        "shadow-[0_2px_8px_rgba(0,0,0,0.4)]"
      ),
      stack: ""
    }

    return (
      <div
        ref={ref}
        className={cn(
          "flex",
          orientation === 'horizontal' ? 'flex-row items-center' : 'flex-col items-stretch',
          spacingClasses[spacing],
          variantClasses[variant],
          className
        )}
        role="group"
        {...props}
      >
        {children}
      </div>
    )
  }
)
HiveButtonGroupV2.displayName = "HiveButtonGroupV2"

// ChatGPT-style floating action button
interface HiveFABProps extends Omit<HiveButtonV2Props, 'variant' | 'size'> {
  position?: 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left'
}

const HiveFAB = React.forwardRef<HTMLButtonElement, HiveFABProps>(
  ({ className, position = 'bottom-right', children, ...props }, ref) => {
    const positionClasses = {
      'bottom-right': 'fixed bottom-6 right-6',
      'bottom-left': 'fixed bottom-6 left-6',
      'top-right': 'fixed top-6 right-6',
      'top-left': 'fixed top-6 left-6'
    }

    return (
      <HiveButtonV2
        ref={ref}
        variant="primary"
        size="icon"
        className={cn(
          positionClasses[position],
          "rounded-full shadow-[0_4px_12px_rgba(0,0,0,0.5),0_8px_24px_rgba(255,215,0,0.2)]",
          "hover:shadow-[0_8px_24px_rgba(0,0,0,0.6),0_16px_32px_rgba(255,215,0,0.3)]",
          "z-50",
          className
        )}
        {...props}
      >
        {children}
      </HiveButtonV2>
    )
  }
)
HiveFAB.displayName = "HiveFAB"

export { 
  HiveButtonV2, 
  HiveButtonGroupV2, 
  HiveFAB,
  hiveButtonVariants 
} 