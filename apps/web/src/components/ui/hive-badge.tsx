import React from 'react';
import { cn } from '@/lib/utils';

export interface HiveBadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  intent?: 'event-status' | 'social-proof' | 'role' | 'urgency';
  size?: 'sm' | 'default' | 'lg';
  children: React.ReactNode;
}

export const HiveBadge = React.forwardRef<HTMLSpanElement, HiveBadgeProps>(
  ({ className, intent = 'event-status', size = 'default', children, ...props }, ref) => {
    return (
      <span
        className={cn(
          // Base sophisticated styling
          'inline-flex items-center justify-center font-medium font-hive',
          'rounded-full transition-all duration-200 ease-out',
          
          // Size variants for different contexts
          {
            'px-2 py-0.5 text-xs': size === 'sm',
            'px-3 py-1 text-sm': size === 'default',
            'px-4 py-1.5 text-base': size === 'lg',
          },
          
          // Intent-based styling for campus social scenarios
          {
            // Event Status: Live, Full, Ending Soon
            'bg-hive-gold/10 text-hive-gold border border-hive-gold/30': intent === 'event-status',
            
            // Social Proof: Popular, Trending, New
            'bg-hive-success/10 text-hive-success border border-hive-success/30': intent === 'social-proof',
            
            // Role: Builder, RA, Org Leader
            'bg-hive-info/10 text-hive-info border border-hive-info/30': intent === 'role',
            
            // Urgency: RSVP Closing, Spots Running Out
            'bg-hive-error/10 text-hive-error border border-hive-error/30 animate-pulse': intent === 'urgency',
          },
          
          className
        )}
        ref={ref}
        {...props}
      >
        {children}
      </span>
    );
  }
);

HiveBadge.displayName = 'HiveBadge'; 