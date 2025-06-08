'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { usePathname } from 'next/navigation';
import { Plus, Search, Bell } from 'lucide-react';
import { cn } from '@/lib/utils';

import { NavigationItem } from './NavigationItem';
import type { NavigationContainerProps, NavigationItem as NavItem } from './types';
import { 
  CORE_NAVIGATION, 
  MOBILE_NAVIGATION_ITEMS,
  MOBILE_QUICK_ACTIONS,
  SIDEBAR_DIMENSIONS,
  NAVIGATION_Z_INDEX
} from './constants';

interface MobileBottomNavProps extends NavigationContainerProps {
  showQuickActions?: boolean;
  onQuickAction?: (actionId: string) => void;
}

/**
 * Mobile bottom navigation component
 * Features tab-style navigation with quick action buttons
 * Optimized for touch interactions and 44pt minimum touch targets
 */
export function MobileBottomNav({
  variant,
  children,
  user,
  currentSpace,
  showQuickActions = true,
  onQuickAction,
}: MobileBottomNavProps) {
  const pathname = usePathname();

  // Get filtered main navigation items for mobile
  const getMobileNavigation = (): NavItem[] => {
    const allItems = CORE_NAVIGATION.flatMap(section => section.items);
    
    return MOBILE_NAVIGATION_ITEMS.map(itemId => {
      const item = allItems.find(navItem => navItem.id === itemId);
      if (!item) return null;
      
      return {
        ...item,
        isActive: pathname.startsWith(item.href),
      };
    }).filter(Boolean) as NavItem[];
  };

  // Filter items based on user permissions
  const getFilteredMobileNavigation = (): NavItem[] => {
    const items = getMobileNavigation();
    
    if (!user) {
      return items.filter(item => !item.requiresAuth);
    }

    return items.filter(item => {
      if (item.requiresAuth && !user) return false;
      if (item.requiresBuilder && !user.isBuilder) return false;
      return true;
    });
  };

  // Get quick actions for current user
  const getQuickActions = () => {
    if (!user || !showQuickActions) return [];
    
    return MOBILE_QUICK_ACTIONS.filter(action => {
      if (action.requiresBuilder && !user.isBuilder) return false;
      return true;
    });
  };

  const navigationItems = getFilteredMobileNavigation();
  const quickActions = getQuickActions();

  return (
    <>
      {/* Bottom Navigation Bar */}
      <motion.div
        initial={{ y: 100 }}
        animate={{ y: 0 }}
        className={cn(
          "fixed bottom-0 left-0 right-0",
          `z-${NAVIGATION_Z_INDEX.mobileNav}`,
          "bg-[#0D0D0D]/95 backdrop-blur-lg",
          "border-t border-white/6",
          "safe-area-inset-bottom", // Handle device safe areas
          SIDEBAR_DIMENSIONS.mobile.padding
        )}
        style={{
          height: SIDEBAR_DIMENSIONS.mobile.height,
        }}
      >
        <div className="flex items-center justify-around h-full">
          {navigationItems.map((item) => (
            <div key={item.id} className="flex-1 flex justify-center">
              <NavigationItem
                item={item}
                variant="mobile"
              />
            </div>
          ))}
        </div>

        {/* Active Tab Indicator */}
        <AnimatePresence>
          {navigationItems.map((item) => 
            item.isActive && (
              <motion.div
                key={`indicator-${item.id}`}
                layoutId="mobile-nav-indicator"
                className={cn(
                  "absolute top-0 left-0 right-0",
                  "h-1 bg-[#FFD700]",
                  "rounded-b-full"
                )}
                style={{
                  width: `${100 / navigationItems.length}%`,
                  left: `${(navigationItems.findIndex(nav => nav.id === item.id) * 100) / navigationItems.length}%`,
                }}
                transition={{
                  type: "spring",
                  stiffness: 500,
                  damping: 30,
                }}
              />
            )
          )}
        </AnimatePresence>
      </motion.div>

      {/* Quick Action Floating Buttons */}
      <AnimatePresence>
        {quickActions.length > 0 && (
          <motion.div
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0, opacity: 0 }}
            className={cn(
              "fixed bottom-24 right-4", // Above bottom nav
              `z-${NAVIGATION_Z_INDEX.mobileNav + 1}`,
              "flex flex-col gap-3"
            )}
          >
            {quickActions.map((action, index) => (
              <motion.button
                key={action.id}
                initial={{ scale: 0, opacity: 0 }}
                animate={{ 
                  scale: 1, 
                  opacity: 1,
                  transition: { delay: index * 0.1 } 
                }}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => onQuickAction?.(action.id)}
                className={cn(
                  "w-14 h-14 rounded-full",
                  "bg-gradient-to-br from-[#FFD700] to-[#FFA500]",
                  "flex items-center justify-center",
                  "shadow-lg shadow-[#FFD700]/25",
                  "transition-all duration-150",
                  "focus:outline-none focus:ring-2 focus:ring-[#FFD700]/50"
                )}
                aria-label={action.label}
              >
                <action.icon className="w-6 h-6 text-black" />
                
                {/* Badge for notifications */}
                {action.id === 'notifications' && (
                  <div className="absolute -top-1 -right-1 w-5 h-5 bg-[#FF3B30] rounded-full flex items-center justify-center">
                    <span className="text-white text-xs font-semibold">3</span>
                  </div>
                )}
              </motion.button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Swipe Indicator (for gesture hints) */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 0.3 }}
        className={cn(
          "fixed bottom-1 left-1/2 transform -translate-x-1/2",
          "w-8 h-1 bg-white/30 rounded-full",
          "pointer-events-none"
        )}
      />
    </>
  );
}

// Mobile navigation overlay for search/menu
export function MobileNavOverlay({ 
  isOpen, 
  onClose,
  children 
}: {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className={cn(
              "fixed inset-0",
              `z-${NAVIGATION_Z_INDEX.overlay}`,
              "bg-black/50 backdrop-blur-sm"
            )}
          />
          
          {/* Overlay Content */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{
              type: "spring",
              stiffness: 300,
              damping: 30,
            }}
            className={cn(
              "fixed bottom-0 left-0 right-0",
              `z-${NAVIGATION_Z_INDEX.overlay + 1}`,
              "bg-[#0D0D0D] rounded-t-xl",
              "max-h-[80vh] overflow-y-auto",
              "safe-area-inset-bottom"
            )}
          >
            {/* Handle Bar */}
            <div className="flex justify-center pt-3 pb-4">
              <div className="w-8 h-1 bg-white/30 rounded-full" />
            </div>
            
            {children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
} 