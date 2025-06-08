'use client'

import * as React from 'react'
import * as TabsPrimitive from '@radix-ui/react-tabs'
import { motion, AnimatePresence } from 'framer-motion'
import { cn } from '@/lib/utils'

// HIVE Tabs Root
const HiveTabs = TabsPrimitive.Root

// HIVE Tabs List with sliding underline indicator
interface HiveTabsListProps extends React.ComponentPropsWithoutRef<typeof TabsPrimitive.List> {
  variant?: 'default' | 'pills' | 'underline'
}

const HiveTabsList = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  HiveTabsListProps
>(({ className, variant = 'underline', ...props }, ref) => {
  const [activeTab, setActiveTab] = React.useState<string>('')
  const [tabPositions, setTabPositions] = React.useState<Record<string, { left: number; width: number }>>({})
  
  // Track tab positions for sliding indicator
  const tabRefs = React.useRef<Record<string, HTMLButtonElement | null>>({})
  
  React.useEffect(() => {
    const updatePositions = () => {
      const positions: Record<string, { left: number; width: number }> = {}
      Object.entries(tabRefs.current).forEach(([value, element]) => {
        if (element) {
          const rect = element.getBoundingClientRect()
          const parentRect = element.parentElement?.getBoundingClientRect()
          if (parentRect) {
            positions[value] = {
              left: rect.left - parentRect.left,
              width: rect.width
            }
          }
        }
      })
      setTabPositions(positions)
    }
    
    updatePositions()
    window.addEventListener('resize', updatePositions)
    return () => window.removeEventListener('resize', updatePositions)
  }, [])

  const baseClasses = variant === 'pills' 
    ? "inline-flex items-center justify-center rounded-lg bg-hive-bg-surface-1 p-1"
    : variant === 'underline'
    ? "relative flex items-center border-b border-hive-border"
    : "inline-flex items-center justify-center"

  return (
    <TabsPrimitive.List
      ref={ref}
      className={cn(baseClasses, className)}
      {...props}
      onValueChange={(value) => {
        setActiveTab(value)
        props.onValueChange?.(value)
      }}
    >
      {props.children}
      
      {/* Sliding gold underline indicator */}
      {variant === 'underline' && activeTab && tabPositions[activeTab] && (
        <motion.div
          className="absolute bottom-0 h-0.5 bg-hive-accent rounded-full"
          initial={false}
          animate={{
            left: tabPositions[activeTab].left,
            width: tabPositions[activeTab].width
          }}
          transition={{
            type: "spring",
            stiffness: 400,
            damping: 30,
            mass: 0.8
          }}
          style={{ zIndex: 1 }}
        />
      )}
    </TabsPrimitive.List>
  )
})
HiveTabsList.displayName = TabsPrimitive.List.displayName

// HIVE Tabs Trigger with physics and states
interface HiveTabsTriggerProps extends React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger> {
  variant?: 'default' | 'pills' | 'underline'
  physics?: boolean
}

const HiveTabsTrigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  HiveTabsTriggerProps
>(({ className, variant = 'underline', physics = true, ...props }, ref) => {
  const [isPressed, setIsPressed] = React.useState(false)
  
  // Register tab ref for position tracking
  const triggerRef = React.useCallback((node: HTMLButtonElement | null) => {
    if (ref) {
      if (typeof ref === 'function') ref(node)
      else ref.current = node
    }
    
    const parent = node?.closest('[role="tablist"]') as any
    if (parent && node && props.value) {
      if (!parent.tabRefs) parent.tabRefs = { current: {} }
      parent.tabRefs.current[props.value] = node
    }
  }, [ref, props.value])

  const baseClasses = variant === 'pills'
    ? cn(
        "inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1.5 text-sm font-medium transition-all",
        "text-hive-text-secondary hover:text-hive-text-primary",
        "data-[state=active]:bg-hive-bg-surface-2 data-[state=active]:text-hive-text-primary data-[state=active]:shadow-sm"
      )
    : variant === 'underline'
    ? cn(
        "relative inline-flex items-center justify-center whitespace-nowrap px-4 py-3 text-sm font-medium transition-all",
        "text-hive-text-secondary hover:text-hive-text-primary",
        "data-[state=active]:text-hive-accent focus-visible:outline-none",
        "focus-visible:ring-2 focus-visible:ring-hive-accent focus-visible:ring-offset-2"
      )
    : cn(
        "inline-flex items-center justify-center whitespace-nowrap px-3 py-1.5 text-sm font-medium transition-all",
        "text-hive-text-secondary hover:text-hive-text-primary"
      )

  const motionProps = physics ? {
    whileHover: { 
      scale: 1.02,
      transition: { type: "spring", stiffness: 400, damping: 25 }
    },
    whileTap: { 
      scale: 0.98,
      transition: { type: "spring", stiffness: 500, damping: 30 }
    },
    onTapStart: () => setIsPressed(true),
    onTap: () => setIsPressed(false),
    onTapCancel: () => setIsPressed(false)
  } : {}

  return (
    <motion.div {...motionProps}>
      <TabsPrimitive.Trigger
        ref={triggerRef}
        className={cn(baseClasses, className)}
        {...props}
      >
        {props.children}
        
        {/* Press feedback overlay */}
        <AnimatePresence>
          {isPressed && (
            <motion.div
              className="absolute inset-0 bg-hive-accent/10 rounded-md"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.1 }}
            />
          )}
        </AnimatePresence>
      </TabsPrimitive.Trigger>
    </motion.div>
  )
})
HiveTabsTrigger.displayName = TabsPrimitive.Trigger.displayName

// HIVE Tabs Content with slide animation
interface HiveTabsContentProps extends React.ComponentPropsWithoutRef<typeof TabsPrimitive.Content> {
  slideDirection?: 'horizontal' | 'vertical'
}

const HiveTabsContent = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Content>,
  HiveTabsContentProps
>(({ className, slideDirection = 'horizontal', ...props }, ref) => (
  <TabsPrimitive.Content
    ref={ref}
    className={cn(
      "mt-4 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-hive-accent focus-visible:ring-offset-2",
      "data-[state=active]:animate-in data-[state=active]:fade-in-0",
      slideDirection === 'horizontal' 
        ? "data-[state=active]:slide-in-from-left-2" 
        : "data-[state=active]:slide-in-from-top-2",
      className
    )}
    {...props}
  />
))
HiveTabsContent.displayName = TabsPrimitive.Content.displayName

// Animated Tabs Badge for notifications/counts
interface HiveTabsBadgeProps {
  count?: number
  variant?: 'dot' | 'count'
  className?: string
}

const HiveTabsBadge: React.FC<HiveTabsBadgeProps> = ({ 
  count = 0, 
  variant = 'count', 
  className 
}) => {
  if (count === 0) return null

  return (
    <motion.div
      className={cn(
        "absolute -top-1 -right-1 flex items-center justify-center",
        variant === 'dot' 
          ? "h-2 w-2 rounded-full bg-hive-accent" 
          : "h-5 min-w-[20px] px-1 rounded-full bg-hive-accent text-black text-xs font-semibold",
        className
      )}
      initial={{ scale: 0 }}
      animate={{ scale: 1 }}
      transition={{ 
        type: "spring", 
        stiffness: 500, 
        damping: 25 
      }}
    >
      {variant === 'count' && count > 99 ? '99+' : count > 0 ? count : null}
    </motion.div>
  )
}

// HIVE Tab with Badge wrapper
interface HiveTabWithBadgeProps extends HiveTabsTriggerProps {
  badge?: number
  badgeVariant?: 'dot' | 'count'
}

const HiveTabWithBadge = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  HiveTabWithBadgeProps
>(({ badge, badgeVariant = 'count', children, className, ...props }, ref) => (
  <HiveTabsTrigger
    ref={ref}
    className={cn("relative", className)}
    {...props}
  >
    {children}
    {badge !== undefined && (
      <HiveTabsBadge count={badge} variant={badgeVariant} />
    )}
  </HiveTabsTrigger>
))
HiveTabWithBadge.displayName = "HiveTabWithBadge"

export { 
  HiveTabs, 
  HiveTabsList, 
  HiveTabsTrigger, 
  HiveTabsContent, 
  HiveTabsBadge,
  HiveTabWithBadge
} 