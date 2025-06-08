'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { usePathname } from 'next/navigation';
import { 
  ChevronLeft, 
  ChevronRight, 
  Search,
  Plus,
  MoreHorizontal,
  Home
} from 'lucide-react';
import { cn } from '@/lib/utils';

import { NavigationItem, NavigationItemSkeleton } from './NavigationItem';
import { SpaceNavigationList } from './SpaceNavigationList';
import type { NavigationContainerProps, SpaceContext, NavigationItem as NavItem } from './types';
import { 
  CORE_NAVIGATION, 
  SIDEBAR_DIMENSIONS, 
  NAVIGATION_ANIMATIONS,
  NAVIGATION_BREAKPOINTS,
  SPACE_LIST_LIMITS
} from './constants';

interface DesktopSidebarProps extends NavigationContainerProps {
  spaces?: SpaceContext[];
  onSpaceSelect?: (space: SpaceContext) => void;
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
}

/**
 * Desktop sidebar navigation component
 * Features collapsible layout, space navigation, and Builder tools
 * Follows HIVE brand aesthetic with smooth animations
 */
export function DesktopSidebar({
  variant,
  children,
  user,
  currentSpace,
  spaces = [],
  onSpaceSelect,
  isCollapsed = false,
  onToggleCollapse,
}: DesktopSidebarProps) {
  const pathname = usePathname();
  const [showAllSpaces, setShowAllSpaces] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Mark navigation items as active based on current path
  const getActiveNavigation = () => {
    return CORE_NAVIGATION.map(section => ({
      ...section,
      items: section.items.map(item => ({
        ...item,
        isActive: pathname.startsWith(item.href)
      }))
    }));
  };

  // Filter navigation items based on user permissions
  const getFilteredNavigation = () => {
    if (!user) {
      return getActiveNavigation().map(section => ({
        ...section,
        items: section.items.filter(item => !item.requiresAuth)
      }));
    }

    return getActiveNavigation().map(section => ({
      ...section,
      items: section.items.filter(item => {
        if (item.requiresAuth && !user) return false;
        if (item.requiresBuilder && !user.isBuilder) return false;
        return true;
      })
    }));
  };

  // Filter spaces for display
  const getDisplaySpaces = () => {
    const filteredSpaces = spaces.filter(space => 
      space.name.toLowerCase().includes(searchQuery.toLowerCase())
    );

    if (showAllSpaces) {
      return filteredSpaces;
    }

    return filteredSpaces.slice(0, SPACE_LIST_LIMITS.desktop);
  };

  const sidebarVariants = {
    expanded: {
      width: SIDEBAR_DIMENSIONS.expanded.width,
      transition: {
        duration: parseFloat(NAVIGATION_ANIMATIONS.sidebarCollapse.duration) / 1000,
        ease: NAVIGATION_ANIMATIONS.sidebarCollapse.easing,
      },
    },
    collapsed: {
      width: SIDEBAR_DIMENSIONS.collapsed.width,
      transition: {
        duration: parseFloat(NAVIGATION_ANIMATIONS.sidebarCollapse.duration) / 1000,
        ease: NAVIGATION_ANIMATIONS.sidebarCollapse.easing,
      },
    },
  };

  return (
    <motion.div
      initial={false}
      animate={isCollapsed ? 'collapsed' : 'expanded'}
      variants={sidebarVariants}
      className={cn(
        "relative h-screen bg-[#0D0D0D]",
        "border-r border-white/6",
        "flex flex-col",
        "overflow-hidden"
      )}
    >
      {/* Sidebar Header */}
      <div className={cn(
        "flex items-center justify-between",
        "px-6 py-6",
        "border-b border-white/6"
      )}>
        <AnimatePresence mode="wait">
          {!isCollapsed && (
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.2 }}
              className="flex items-center gap-3"
            >
              {/* HIVE Logo */}
              <div className="w-8 h-8 bg-gradient-to-br from-[#FFD700] to-[#FFA500] rounded-lg flex items-center justify-center">
                <Home className="w-5 h-5 text-black" />
              </div>
              <span className="text-white font-semibold text-[22px] leading-[28px]">
                HIVE
              </span>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Collapse Toggle */}
        <button
          onClick={onToggleCollapse}
          className={cn(
            "w-8 h-8 rounded-lg",
            "bg-white/5 hover:bg-white/10",
            "flex items-center justify-center",
            "transition-colors duration-150",
            "focus:outline-none focus:ring-2 focus:ring-[#FFD700]/50"
          )}
        >
          {isCollapsed ? (
            <ChevronRight className="w-4 h-4 text-white/70" />
          ) : (
            <ChevronLeft className="w-4 h-4 text-white/70" />
          )}
        </button>
      </div>

      {/* Search (when expanded) */}
      <AnimatePresence>
        {!isCollapsed && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
            className="px-6 py-4 border-b border-white/6"
          >
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-white/50" />
              <input
                type="text"
                placeholder="Search..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className={cn(
                  "w-full pl-10 pr-4 py-2.5",
                  "bg-white/5 border border-white/10 rounded-lg",
                  "text-white placeholder:text-white/50",
                  "focus:outline-none focus:ring-2 focus:ring-[#FFD700]/50",
                  "transition-all duration-150"
                )}
              />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Navigation Content */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-6">
        
        {/* Main Navigation Sections */}
        {getFilteredNavigation().map((section) => (
          <div key={section.id} className="space-y-1">
            {/* Section Label (when expanded) */}
            <AnimatePresence>
              {!isCollapsed && section.label && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="px-3 py-1"
                >
                  <span className="text-white/50 text-[14px] font-medium uppercase tracking-wide">
                    {section.label}
                  </span>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Navigation Items */}
            <div className="space-y-1">
              {section.items.map((item) => (
                <NavigationItem
                  key={item.id}
                  item={item}
                  variant="desktop"
                />
              ))}
            </div>
          </div>
        ))}

        {/* Spaces Section */}
        {user && (
          <div className="space-y-2">
            {/* Spaces Header */}
            <AnimatePresence>
              {!isCollapsed && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="flex items-center justify-between px-3 py-1"
                >
                  <span className="text-white/50 text-[14px] font-medium uppercase tracking-wide">
                    Spaces
                  </span>
                  {user.isBuilder && (
                    <button className="w-5 h-5 rounded bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors">
                      <Plus className="w-3 h-3 text-white/70" />
                    </button>
                  )}
                </motion.div>
              )}
            </AnimatePresence>

            {/* Current Space (if in a space) */}
            {currentSpace && !isCollapsed && (
              <div className="px-3 py-2 bg-[#FFD700]/10 rounded-lg border border-[#FFD700]/20">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 bg-[#FFD700] rounded-full animate-pulse" />
                  <span className="text-[#FFD700] text-sm font-medium">
                    {currentSpace.name}
                  </span>
                </div>
              </div>
            )}

            {/* Spaces List - Placeholder for now */}
            <div className="space-y-1">
              {getDisplaySpaces().map((space) => (
                <div
                  key={space.id}
                  className="px-3 py-2 rounded-lg hover:bg-white/5 cursor-pointer transition-colors"
                  onClick={() => onSpaceSelect?.(space)}
                >
                  <div className="flex items-center gap-3">
                    <div className="w-6 h-6 rounded bg-white/10 flex items-center justify-center">
                      <span className="text-xs text-white/70">
                        {space.name.charAt(0).toUpperCase()}
                      </span>
                    </div>
                    {!isCollapsed && (
                      <span className="text-white/80 text-sm truncate">
                        {space.name}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Show More Button */}
            <AnimatePresence>
              {!isCollapsed && spaces.length > SPACE_LIST_LIMITS.desktop && (
                <motion.button
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  onClick={() => setShowAllSpaces(!showAllSpaces)}
                  className={cn(
                    "w-full px-3 py-2 text-left",
                    "text-white/50 hover:text-white/70",
                    "text-[14px] font-medium",
                    "transition-colors duration-150"
                  )}
                >
                  {showAllSpaces ? 'Show Less' : `Show ${spaces.length - SPACE_LIST_LIMITS.desktop} More`}
                </motion.button>
              )}
            </AnimatePresence>
          </div>
        )}
      </div>

      {/* User Profile (Bottom) */}
      {user && (
        <div className={cn(
          "px-4 py-4",
          "border-t border-white/6"
        )}>
          <AnimatePresence>
            {!isCollapsed ? (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-white/5 transition-colors cursor-pointer"
              >
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#FFD700] to-[#FFA500] flex items-center justify-center">
                  <span className="text-black font-semibold text-sm">
                    {user.fullName.charAt(0).toUpperCase()}
                  </span>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-white font-medium text-[14px] truncate">
                    {user.fullName}
                  </div>
                  <div className="text-white/50 text-[12px] truncate">
                    @{user.username}
                  </div>
                </div>
                <MoreHorizontal className="w-4 h-4 text-white/50" />
              </motion.div>
            ) : (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="flex justify-center"
              >
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#FFD700] to-[#FFA500] flex items-center justify-center">
                  <span className="text-black font-semibold text-sm">
                    {user.fullName.charAt(0).toUpperCase()}
                  </span>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      )}
    </motion.div>
  );
} 