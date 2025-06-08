'use client';

import React from 'react';
import Link from 'next/link';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronRight, Home, MoreHorizontal } from 'lucide-react';
import { cn } from '@/lib/utils';

import type { BreadcrumbProps } from './types';

/**
 * Breadcrumb navigation component with HIVE aesthetic
 * Features smart truncation, Space context, and smooth animations
 * Follows brand guidelines for spacing and typography
 */
export function Breadcrumb({ 
  items, 
  maxItems = 4 
}: BreadcrumbProps) {
  // Handle truncation for long breadcrumb chains
  const getDisplayItems = () => {
    if (items.length <= maxItems) {
      return items;
    }

    // Always show first and last items, truncate middle
    const firstItem = items[0];
    const lastItems = items.slice(-2); // Last 2 items
    const hiddenCount = items.length - 3;

    return [
      firstItem,
      {
        label: `${hiddenCount} more`,
        isEllipsis: true,
      },
      ...lastItems,
    ];
  };

  const displayItems = getDisplayItems();

  return (
    <nav 
      aria-label="Breadcrumb"
      className="flex items-center space-x-2 py-2"
    >
      <ol className="flex items-center space-x-2">
        {displayItems.map((item, index) => (
          <li key={`${item.label}-${index}`} className="flex items-center">
            <AnimatePresence mode="wait">
              {item.isEllipsis ? (
                <motion.button
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.8 }}
                  className={cn(
                    "flex items-center gap-1 px-2 py-1 rounded-lg",
                    "text-white/50 hover:text-white/70",
                    "text-[14px] font-medium",
                    "transition-colors duration-150",
                    "focus:outline-none focus:ring-2 focus:ring-[#FFD700]/50"
                  )}
                  aria-label={`Show ${item.label}`}
                >
                  <MoreHorizontal className="w-4 h-4" />
                  <span className="sr-only">{item.label}</span>
                </motion.button>
              ) : (
                <motion.div
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 10 }}
                  transition={{ duration: 0.2 }}
                  className="flex items-center"
                >
                  {/* Home icon for first item if it's root */}
                  {index === 0 && item.href === '/' && (
                    <Home className="w-4 h-4 text-white/50 mr-2" />
                  )}
                  
                  {item.href && !item.isCurrentPage ? (
                    <Link
                      href={item.href}
                      className={cn(
                        "text-white/70 hover:text-white",
                        "text-[14px] font-medium",
                        "transition-colors duration-150",
                        "focus:outline-none focus:ring-2 focus:ring-[#FFD700]/50",
                        "rounded px-1 py-0.5"
                      )}
                    >
                      {item.label}
                    </Link>
                  ) : (
                    <span
                      className={cn(
                        "text-white font-medium",
                        "text-[14px]",
                        item.isCurrentPage && "text-[#FFD700]"
                      )}
                      aria-current={item.isCurrentPage ? "page" : undefined}
                    >
                      {item.label}
                    </span>
                  )}
                </motion.div>
              )}
            </AnimatePresence>

            {/* Separator */}
            {index < displayItems.length - 1 && (
              <motion.div
                initial={{ opacity: 0, scale: 0.5 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: index * 0.05 }}
                className="ml-2"
              >
                <ChevronRight className="w-4 h-4 text-white/30" />
              </motion.div>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}

// Space-aware breadcrumb that includes Space context
export function SpaceBreadcrumb({
  spaceName,
  spaceType,
  items,
  maxItems = 3, // Reduced for space context
}: BreadcrumbProps & {
  spaceName?: string;
  spaceType?: 'system' | 'academic' | 'residential' | 'organization';
}) {
  // Build items with Space context
  const getSpaceAwareBreadcrumb = () => {
    const breadcrumbItems = [...items];
    
    // Add Space context if provided
    if (spaceName) {
      // Insert Space item after root but before current location
      const spaceItem = {
        label: spaceName,
        href: `/spaces/${spaceName.toLowerCase().replace(/\s+/g, '-')}`,
      };
      
      if (breadcrumbItems.length > 1) {
        breadcrumbItems.splice(1, 0, spaceItem);
      } else {
        breadcrumbItems.push(spaceItem);
      }
    }
    
    return breadcrumbItems;
  };

  const spaceTypeColors = {
    system: '#56CCF2',
    academic: '#8CE563', 
    residential: '#FF9500',
    organization: '#FFD700',
  };

  return (
    <div className="flex items-center gap-3">
      {/* Space Type Indicator */}
      {spaceName && spaceType && (
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          className="flex items-center gap-2"
        >
          <div 
            className="w-2 h-2 rounded-full"
            style={{ backgroundColor: spaceTypeColors[spaceType] }}
          />
          <span className="text-white/50 text-[12px] font-medium uppercase tracking-wide">
            {spaceType}
          </span>
        </motion.div>
      )}
      
      {/* Breadcrumb */}
      <Breadcrumb 
        items={getSpaceAwareBreadcrumb()} 
        maxItems={maxItems} 
      />
    </div>
  );
}

// Loading skeleton for breadcrumbs
export function BreadcrumbSkeleton({ itemCount = 3 }: { itemCount?: number }) {
  return (
    <div className="flex items-center space-x-2 py-2">
      {Array.from({ length: itemCount }).map((_, index) => (
        <div key={index} className="flex items-center">
          {/* Item skeleton */}
          <div className="h-[14px] bg-white/10 rounded animate-pulse w-16" />
          
          {/* Separator skeleton */}
          {index < itemCount - 1 && (
            <div className="ml-2">
              <ChevronRight className="w-4 h-4 text-white/10" />
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

// Compact mobile breadcrumb variant
export function CompactBreadcrumb({ items }: { items: BreadcrumbProps['items'] }) {
  const currentItem = items[items.length - 1];
  const parentItem = items[items.length - 2];

  return (
    <nav aria-label="Breadcrumb" className="flex items-center">
      {parentItem && (
        <Link
          href={parentItem.href || '#'}
          className={cn(
            "flex items-center gap-1",
            "text-white/50 hover:text-white/70",
            "text-[14px] font-medium",
            "transition-colors duration-150",
            "focus:outline-none focus:ring-2 focus:ring-[#FFD700]/50",
            "rounded px-1 py-0.5"
          )}
        >
          <ChevronRight className="w-4 h-4 rotate-180" />
          <span className="truncate max-w-[120px]">{parentItem.label}</span>
        </Link>
      )}
      
      <span className="text-white font-medium text-[16px] ml-2">
        {currentItem.label}
      </span>
    </nav>
  );
} 