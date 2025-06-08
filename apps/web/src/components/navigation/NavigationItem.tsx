'use client';

import React from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

import type { NavigationItemProps } from './types';
import { NAVIGATION_ANIMATIONS, NAVIGATION_COLORS } from './constants';

/**
 * NavigationItem component with HIVE brand aesthetic
 * Supports both desktop sidebar and mobile bottom navigation layouts
 * Follows brand_aesthetic.md specifications for interactions and animations
 */
export function NavigationItem({ 
  item, 
  variant, 
  onClick 
}: NavigationItemProps) {
  const Icon = item.icon;
  const isDesktop = variant === 'desktop';
  const isMobile = variant === 'mobile';

  const handleClick = () => {
    onClick?.(item);
  };

  return (
    <motion.div
      initial={false}
      whileHover={{ 
        scale: parseFloat(NAVIGATION_ANIMATIONS.itemHover.scale),
        transition: { 
          duration: parseFloat(NAVIGATION_ANIMATIONS.itemHover.duration) / 1000 
        }
      }}
      whileTap={{ scale: 0.98 }}
      className={cn(
        // Base styles
        "relative group",
        "transition-all duration-150 ease-out",
        
        // Desktop styles
        isDesktop && [
          "flex items-center gap-3",
          "px-3 py-2.5 rounded-xl",
          "hover:bg-white/5",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#FFD700]/50",
        ],
        
        // Mobile styles  
        isMobile && [
          "flex flex-col items-center justify-center",
          "px-2 py-1.5 rounded-lg",
          "min-h-[48px] min-w-[48px]", // 44pt touch target minimum
          "hover:bg-white/5",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#FFD700]/50",
        ]
      )}
    >
      <Link
        href={item.href}
        onClick={handleClick}
        className={cn(
          "flex items-center gap-3 w-full text-left",
          "transition-colors duration-150",
          
          // Active state styling
          item.isActive && [
            "text-white",
            "before:absolute before:left-0 before:top-0 before:bottom-0",
            "before:w-1 before:bg-[#FFD700] before:rounded-r-full",
            isDesktop && "before:block",
            isMobile && "before:hidden"
          ],
          
          // Inactive state styling
          !item.isActive && [
            "text-white/70 hover:text-white",
          ],
          
          // Mobile specific layout
          isMobile && "flex-col gap-1"
        )}
      >
        {/* Icon with golden glow on active */}
        <div className={cn(
          "relative flex items-center justify-center",
          isDesktop && "w-6 h-6",
          isMobile && "w-5 h-5",
          
          // Active state glow effect
          item.isActive && [
            "before:absolute before:inset-0",
            "before:bg-[#FFD700]/20 before:rounded-lg before:blur-sm",
            "before:scale-110",
          ]
        )}>
          <Icon 
            className={cn(
              "relative z-10 transition-colors duration-150",
              isDesktop && "w-6 h-6",
              isMobile && "w-5 h-5",
              item.isActive ? "text-[#FFD700]" : "text-current"
            )}
          />
        </div>

        {/* Label */}
        <span className={cn(
          "font-medium transition-colors duration-150",
          isDesktop && "text-[17px] leading-[22px]", // SF Pro Text body
          isMobile && "text-[12px] leading-[14px] text-center", // Compact mobile text
          item.isActive ? "text-white" : "text-current"
        )}>
          {item.label}
        </span>

        {/* Badge/Notification indicator */}
        {item.badge && (
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className={cn(
              "absolute flex items-center justify-center",
              "bg-[#FF3B30] text-white text-xs font-semibold",
              "min-w-[20px] h-[20px] px-1.5 rounded-full",
              
              // Position based on variant
              isDesktop && "top-1 right-1",
              isMobile && "-top-1 -right-1",
              
              // Pulsing animation for new notifications
              typeof item.badge === 'number' && item.badge > 0 && [
                "animate-pulse",
                "shadow-lg shadow-[#FF3B30]/50"
              ]
            )}
          >
            {typeof item.badge === 'number' && item.badge > 99 ? '99+' : item.badge}
          </motion.div>
        )}

        {/* Hover glow effect */}
        <div className={cn(
          "absolute inset-0 rounded-xl opacity-0",
          "bg-gradient-to-r from-[#FFD700]/5 to-transparent",
          "transition-opacity duration-150",
          "group-hover:opacity-100",
          "pointer-events-none"
        )} />

        {/* Focus ring */}
        <div className={cn(
          "absolute inset-0 rounded-xl opacity-0",
          "ring-2 ring-[#FFD700]/50",
          "transition-opacity duration-150",
          "group-focus-visible:opacity-100",
          "pointer-events-none"
        )} />
      </Link>
    </motion.div>
  );
}

// Loading skeleton for navigation items
export function NavigationItemSkeleton({ variant }: { variant: 'desktop' | 'mobile' }) {
  const isDesktop = variant === 'desktop';
  const isMobile = variant === 'mobile';

  return (
    <div className={cn(
      "animate-pulse",
      isDesktop && "flex items-center gap-3 px-3 py-2.5",
      isMobile && "flex flex-col items-center justify-center px-2 py-1.5 min-h-[48px]"
    )}>
      {/* Icon skeleton */}
      <div className={cn(
        "bg-white/10 rounded",
        isDesktop && "w-6 h-6",
        isMobile && "w-5 h-5"
      )} />
      
      {/* Label skeleton */}
      <div className={cn(
        "bg-white/10 rounded",
        isDesktop && "h-[17px] w-16",
        isMobile && "h-[12px] w-8 mt-1"
      )} />
    </div>
  );
} 