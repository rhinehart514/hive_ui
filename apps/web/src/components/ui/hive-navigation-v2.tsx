'use client'

import * as React from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { cn } from '@/lib/utils'
import { cva, type VariantProps } from 'class-variance-authority'

// Apple-style tab navigation
const hiveTabsVariants = cva(
  "relative flex items-center",
  {
    variants: {
      variant: {
        // Clean Apple-style tabs with sliding indicator
        underline: [
          "border-b border-hive-border/30 bg-transparent"
        ],
        // iOS-style pills
        pills: [
          "bg-hive-bg-surface-1/60 backdrop-blur-xl rounded-xl p-1",
          "border border-hive-border/40 shadow-[0_1px_3px_rgba(0,0,0,0.3)]"
        ],
        // ChatGPT-style segmented control
        segmented: [
          "bg-hive-bg-surface-1/80 backdrop-blur-xl rounded-xl p-1",
          "border border-hive-border/30 shadow-[0_2px_8px_rgba(0,0,0,0.4)]"
        ]
      },
      size: {
        sm: "h-8",
        default: "h-10", 
        lg: "h-12"
      }
    },
    defaultVariants: {
      variant: "underline",
      size: "default"
    }
  }
)

interface HiveTabsV2Props 
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof hiveTabsVariants> {
  value: string
  onValueChange: (value: string) => void
  children: React.ReactNode
}

const HiveTabsV2 = React.forwardRef<HTMLDivElement, HiveTabsV2Props>(
  ({ className, variant, size, value, onValueChange, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(hiveTabsVariants({ variant, size }), className)}
        {...props}
      >
        {React.Children.map(children, (child) => {
          if (React.isValidElement(child)) {
            return React.cloneElement(child, {
              variant,
              size,
              isActive: child.props.value === value,
              onSelect: onValueChange,
            } as any)
          }
          return child
        })}
      </div>
    )
  }
)
HiveTabsV2.displayName = "HiveTabsV2"

// Individual tab item
interface HiveTabV2Props extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  value: string
  isActive?: boolean
  onSelect?: (value: string) => void
  variant?: 'underline' | 'pills' | 'segmented'
  size?: 'sm' | 'default' | 'lg'
  badge?: React.ReactNode
  icon?: React.ReactNode
  physics?: boolean
}

const HiveTabV2 = React.forwardRef<HTMLButtonElement, HiveTabV2Props>(
  ({ 
    className, 
    value, 
    isActive = false, 
    onSelect, 
    variant = 'underline',
    size = 'default',
    badge,
    icon,
    physics = true,
    children, 
    ...props 
  }, ref) => {
    const baseClasses = cn(
      "relative inline-flex items-center justify-center font-medium transition-all duration-300",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-hive-accent focus-visible:ring-offset-2",
      "disabled:pointer-events-none disabled:opacity-50"
    )

    const variantClasses = {
      underline: cn(
        "px-4 py-2 text-sm border-b-2 border-transparent",
        isActive 
          ? "text-hive-text-primary border-hive-accent" 
          : "text-hive-text-secondary hover:text-hive-text-primary hover:border-hive-border"
      ),
      pills: cn(
        "px-3 py-1.5 text-sm rounded-lg mx-0.5",
        isActive 
          ? "bg-hive-accent text-black shadow-[0_1px_3px_rgba(0,0,0,0.4)]" 
          : "text-hive-text-secondary hover:text-hive-text-primary hover:bg-hive-bg-surface-2/60"
      ),
      segmented: cn(
        "px-4 py-1.5 text-sm rounded-lg mx-0.5 relative",
        isActive 
          ? "text-hive-text-primary" 
          : "text-hive-text-secondary hover:text-hive-text-primary"
      )
    }

    const sizeClasses = {
      sm: "h-6 text-xs",
      default: "h-8 text-sm",
      lg: "h-10 text-base"
    }

    const motionProps = physics ? {
      whileHover: !isActive ? { 
        scale: 1.02,
        transition: { 
          type: "spring", 
          stiffness: 400, 
          damping: 25 
        }
      } : {},
      whileTap: { 
        scale: 0.98,
        transition: { 
          type: "spring", 
          stiffness: 500, 
          damping: 30 
        }
      }
    } : {}

    return (
      <motion.button
        ref={ref}
        className={cn(
          baseClasses,
          variantClasses[variant],
          sizeClasses[size],
          className
        )}
        onClick={() => onSelect?.(value)}
        {...motionProps}
        {...props}
      >
        {/* Active background for segmented control */}
        {variant === 'segmented' && isActive && (
          <motion.div
            className="absolute inset-0 bg-hive-accent/10 rounded-lg border border-hive-accent/20"
            layoutId="activeTab"
            transition={{ type: "spring", stiffness: 400, damping: 30 }}
          />
        )}

        {/* Content */}
        <span className="relative z-10 flex items-center gap-2">
          {icon}
          {children}
          {badge && (
            <span className="ml-1 px-1.5 py-0.5 text-xs bg-hive-accent/20 text-hive-accent rounded-full">
              {badge}
            </span>
          )}
        </span>
      </motion.button>
    )
  }
)
HiveTabV2.displayName = "HiveTabV2"

// Apple-style navigation bar
interface HiveNavBarV2Props extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'top' | 'bottom' | 'floating'
  blur?: boolean
  border?: boolean
}

const HiveNavBarV2 = React.forwardRef<HTMLDivElement, HiveNavBarV2Props>(
  ({ className, variant = 'top', blur = true, border = true, children, ...props }, ref) => {
    const variantClasses = {
      top: "top-0 left-0 right-0",
      bottom: "bottom-0 left-0 right-0 border-t",
      floating: "top-4 left-4 right-4 rounded-xl"
    }

    return (
      <div
        ref={ref}
        className={cn(
          "fixed z-40 h-16 flex items-center justify-between px-4",
          blur && "backdrop-blur-xl",
          variant === 'floating' 
            ? "bg-hive-bg-surface-1/80 border border-hive-border/40 shadow-[0_4px_12px_rgba(0,0,0,0.5)]"
            : "bg-hive-bg-surface-1/90",
          border && variant !== 'floating' && "border-b border-hive-border/30",
          variantClasses[variant],
          className
        )}
        {...props}
      >
        {children}
      </div>
    )
  }
)
HiveNavBarV2.displayName = "HiveNavBarV2"

// Apple-style breadcrumb navigation
interface HiveBreadcrumbV2Props extends React.HTMLAttributes<HTMLDivElement> {
  items: Array<{
    label: string
    href?: string
    icon?: React.ReactNode
    current?: boolean
  }>
  separator?: React.ReactNode
}

const HiveBreadcrumbV2 = React.forwardRef<HTMLDivElement, HiveBreadcrumbV2Props>(
  ({ className, items, separator = "›", ...props }, ref) => {
    return (
      <nav
        ref={ref}
        className={cn("flex items-center space-x-2 text-sm", className)}
        aria-label="Breadcrumb"
        {...props}
      >
        {items.map((item, index) => (
          <React.Fragment key={index}>
            {index > 0 && (
              <span className="text-hive-text-secondary">{separator}</span>
            )}
            <motion.div
              className={cn(
                "flex items-center gap-1.5",
                item.current 
                  ? "text-hive-text-primary font-medium" 
                  : "text-hive-text-secondary hover:text-hive-text-primary",
                item.href && !item.current && "cursor-pointer"
              )}
              whileHover={item.href && !item.current ? { scale: 1.02 } : {}}
              whileTap={item.href && !item.current ? { scale: 0.98 } : {}}
            >
              {item.icon}
              <span>{item.label}</span>
            </motion.div>
          </React.Fragment>
        ))}
      </nav>
    )
  }
)
HiveBreadcrumbV2.displayName = "HiveBreadcrumbV2"

// ChatGPT-style sidebar navigation
interface HiveSidebarV2Props extends React.HTMLAttributes<HTMLDivElement> {
  isOpen?: boolean
  onClose?: () => void
  width?: 'sm' | 'default' | 'lg'
  position?: 'left' | 'right'
}

const HiveSidebarV2 = React.forwardRef<HTMLDivElement, HiveSidebarV2Props>(
  ({ 
    className, 
    isOpen = false, 
    onClose, 
    width = 'default',
    position = 'left',
    children, 
    ...props 
  }, ref) => {
    const widthClasses = {
      sm: 'w-64',
      default: 'w-80',
      lg: 'w-96'
    }

    const positionClasses = {
      left: 'left-0',
      right: 'right-0'
    }

    return (
      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              onClick={onClose}
            />

            {/* Sidebar */}
            <motion.div
              ref={ref}
              className={cn(
                "fixed top-0 bottom-0 z-50 bg-hive-bg-surface-1/95 backdrop-blur-xl",
                "border-r border-hive-border/30 shadow-[0_8px_32px_rgba(0,0,0,0.6)]",
                widthClasses[width],
                positionClasses[position],
                className
              )}
              initial={{ 
                x: position === 'left' ? '-100%' : '100%',
                opacity: 0 
              }}
              animate={{ 
                x: 0,
                opacity: 1 
              }}
              exit={{ 
                x: position === 'left' ? '-100%' : '100%',
                opacity: 0 
              }}
              transition={{ 
                type: "spring", 
                stiffness: 300, 
                damping: 30 
              }}
              {...props}
            >
              {children}
            </motion.div>
          </>
        )}
      </AnimatePresence>
    )
  }
)
HiveSidebarV2.displayName = "HiveSidebarV2"

// Apple-style bottom tab bar (iOS inspired)
interface HiveBottomTabsV2Props extends React.HTMLAttributes<HTMLDivElement> {
  value: string
  onValueChange: (value: string) => void
  items: Array<{
    value: string
    label: string
    icon: React.ReactNode
    badge?: string | number
  }>
}

const HiveBottomTabsV2 = React.forwardRef<HTMLDivElement, HiveBottomTabsV2Props>(
  ({ className, value, onValueChange, items, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          "fixed bottom-0 left-0 right-0 z-40",
          "bg-hive-bg-surface-1/95 backdrop-blur-xl",
          "border-t border-hive-border/30",
          "px-4 pb-safe pt-2",
          className
        )}
        {...props}
      >
        <div className="flex items-center justify-around">
          {items.map((item) => {
            const isActive = item.value === value
            
            return (
              <motion.button
                key={item.value}
                className={cn(
                  "flex flex-col items-center justify-center p-2 min-w-0 flex-1",
                  "transition-colors duration-200"
                )}
                onClick={() => onValueChange(item.value)}
                whileTap={{ scale: 0.95 }}
              >
                <div className="relative mb-1">
                  <div className={cn(
                    "transition-colors duration-200",
                    isActive ? "text-hive-accent" : "text-hive-text-secondary"
                  )}>
                    {item.icon}
                  </div>
                  
                  {item.badge && (
                    <div className="absolute -top-1 -right-1 bg-hive-accent text-black text-xs font-medium rounded-full min-w-[16px] h-4 flex items-center justify-center px-1">
                      {item.badge}
                    </div>
                  )}
                </div>
                
                <span className={cn(
                  "text-xs font-medium transition-colors duration-200 leading-none",
                  isActive ? "text-hive-accent" : "text-hive-text-secondary"
                )}>
                  {item.label}
                </span>
              </motion.button>
            )
          })}
        </div>
      </div>
    )
  }
)
HiveBottomTabsV2.displayName = "HiveBottomTabsV2"

export { 
  HiveTabsV2, 
  HiveTabV2, 
  HiveNavBarV2, 
  HiveBreadcrumbV2, 
  HiveSidebarV2,
  HiveBottomTabsV2,
  hiveTabsVariants 
} 