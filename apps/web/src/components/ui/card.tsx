'use client'

import * as React from 'react'

import { cn } from '@/lib/utils'
import { cva, type VariantProps } from 'class-variance-authority'

const cardVariants = cva(
  'rounded-md bg-card text-card-foreground shadow-xs transition-all hover:shadow-sm',
  {
    variants: {
      intent: {
        default: '',
        glass: 'bg-glass-card-bg/80 backdrop-blur-lg border border-gray-700',
      },
    },
    defaultVariants: {
      intent: 'default',
    },
  },
)

interface HiveCardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> {}

const HiveCard = React.forwardRef<HTMLDivElement, HiveCardProps>(
  ({ className, intent, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(cardVariants({ intent, className }))}
      {...props}
    />
  ),
)
HiveCard.displayName = 'HiveCard'

const HiveCardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex flex-col space-y-1.5 p-6', className)}
    {...props}
  />
))
HiveCardHeader.displayName = 'HiveCardHeader'

const HiveCardTitle = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn(
      'text-lg font-semibold leading-none tracking-tight',
      className,
    )}
    {...props}
  />
))
HiveCardTitle.displayName = 'HiveCardTitle'

const HiveCardDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn('text-sm text-muted-foreground', className)}
    {...props}
  />
))
HiveCardDescription.displayName = 'HiveCardDescription'

const HiveCardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn('p-6 pt-0', className)} {...props} />
))
HiveCardContent.displayName = 'HiveCardContent'

const HiveCardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex items-center p-6 pt-0', className)}
    {...props}
  />
))
HiveCardFooter.displayName = 'HiveCardFooter'

export {
  HiveCard,
  HiveCardHeader,
  HiveCardFooter,
  HiveCardTitle,
  HiveCardDescription,
  HiveCardContent,
}

