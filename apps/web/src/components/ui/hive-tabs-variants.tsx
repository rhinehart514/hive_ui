'use client'

import * as React from 'react'
import * as TabsPrimitive from '@radix-ui/react-tabs'
import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'

//=========== VARIANT A: SLIDING UNDERLINE ===========//

const HiveTabsA_Root = TabsPrimitive.Root
const HiveTabsA_List = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.List>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={cn('relative inline-flex h-10 items-center justify-center rounded-md bg-secondary p-1 text-muted-foreground', className)}
    {...props}
  />
))
HiveTabsA_List.displayName = TabsPrimitive.List.displayName

const HiveTabsA_Trigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>
>(({ className, children, ...props }, ref) => {
  const [isActive, setIsActive] = React.useState(false)
  return (
    <TabsPrimitive.Trigger
      ref={ref}
      onFocus={() => setIsActive(true)}
      onBlur={() => setIsActive(false)}
      className={cn(
        'relative inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:text-foreground',
        className
      )}
      {...props}
    >
      {children}
      {isActive && <motion.div layoutId="underline" className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />}
    </TabsPrimitive.Trigger>
  )
})
HiveTabsA_Trigger.displayName = TabsPrimitive.Trigger.displayName

const HiveTabsA_Content = TabsPrimitive.Content

export const HiveTabsA = { Root: HiveTabsA_Root, List: HiveTabsA_List, Trigger: HiveTabsA_Trigger, Content: HiveTabsA_Content }


//=========== VARIANT B: MOVING PILL ===========//

const HiveTabsB_Root = TabsPrimitive.Root

const HiveTabsB_List = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.List>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={cn('relative flex items-center gap-2', className)}
    {...props}
  />
))
HiveTabsB_List.displayName = TabsPrimitive.List.displayName

const HiveTabsB_Trigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>
>(({ className, children, ...props }, ref) => (
    <TabsPrimitive.Trigger
      ref={ref}
      className={cn(
        'relative group rounded-full px-4 py-2 text-sm font-semibold text-muted-foreground transition-colors duration-300 hover:text-foreground',
        'data-[state=active]:text-primary-foreground',
        className
      )}
      {...props}
    >
        <span className="relative z-10">{children}</span>
        {props['data-state'] === 'active' && (
            <motion.div
                layoutId="pill"
                className="absolute inset-0 z-0 rounded-full bg-primary"
                transition={{ type: 'spring', stiffness: 400, damping: 30 }}
            />
        )}
    </TabsPrimitive.Trigger>
))
HiveTabsB_Trigger.displayName = TabsPrimitive.Trigger.displayName

const HiveTabsB_Content = TabsPrimitive.Content

export const HiveTabsB = { Root: HiveTabsB_Root, List: HiveTabsB_List, Trigger: HiveTabsB_Trigger, Content: HiveTabsB_Content }

//=========== VARIANT C: GLASS BUTTONS ===========//

const HiveTabsC_Root = TabsPrimitive.Root

const HiveTabsC_List = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.List>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={cn('flex items-center gap-4 border-b border-border', className)}
    {...props}
  />
))
HiveTabsC_List.displayName = TabsPrimitive.List.displayName

const HiveTabsC_Trigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>
>(({ className, children, ...props }, ref) => (
    <TabsPrimitive.Trigger
      ref={ref}
      className={cn(
        'relative group pb-3 text-sm font-semibold text-muted-foreground transition-colors duration-200',
        'hover:text-foreground data-[state=active]:text-foreground',
        className
      )}
      {...props}
    >
        {children}
        {props['data-state'] === 'active' && (
            <motion.div
                layoutId="glass-underline"
                className="absolute bottom-[-1px] left-0 right-0 h-0.5 bg-primary glow-accent"
                transition={{ type: 'spring', stiffness: 350, damping: 30 }}
            />
        )}
    </TabsPrimitive.Trigger>
))
HiveTabsC_Trigger.displayName = TabsPrimitive.Trigger.displayName

const HiveTabsC_Content = TabsPrimitive.Content

export const HiveTabsC = { Root: HiveTabsC_Root, List: HiveTabsC_List, Trigger: HiveTabsC_Trigger, Content: HiveTabsC_Content } 