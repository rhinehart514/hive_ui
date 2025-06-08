'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { cn } from '@/lib/utils';

import { DesktopSidebar } from './DesktopSidebar';
import { MobileBottomNav, MobileNavOverlay } from './MobileBottomNav';
import { Breadcrumb, SpaceBreadcrumb, CompactBreadcrumb } from './Breadcrumb';
import type { 
  NavigationContainerProps, 
  NavigationState, 
  SpaceContext,
  UserContext,
  BreadcrumbProps
} from './types';
import { NAVIGATION_BREAKPOINTS } from './constants';

interface HiveNavigationProps {
  user?: UserContext;
  currentSpace?: SpaceContext;
  spaces?: SpaceContext[];
  breadcrumbItems?: BreadcrumbProps['items'];
  children: React.ReactNode;
  onSpaceSelect?: (space: SpaceContext) => void;
  onQuickAction?: (actionId: string) => void;
}

/**
 * Main navigation container for HIVE
 * Handles responsive layout switching and navigation state
 * Integrates desktop sidebar, mobile bottom nav, and breadcrumbs
 */
export function HiveNavigation({
  user,
  currentSpace,
  spaces = [],
  breadcrumbItems = [],
  children,
  onSpaceSelect,
  onQuickAction,
}: HiveNavigationProps) {
  const router = useRouter();
  const pathname = usePathname();
  
  // Navigation state management
  const [navigationState, setNavigationState] = useState<NavigationState>({
    currentPath: pathname,
    currentSpace,
    user,
    isLoading: false,
    isMobileMenuOpen: false,
    searchQuery: '',
    recentSpaces: [],
  });

  // Responsive state
  const [isMobile, setIsMobile] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  // Handle responsive layout changes
  useEffect(() => {
    const checkIsMobile = () => {
      const mobile = window.innerWidth < NAVIGATION_BREAKPOINTS.mobile;
      setIsMobile(mobile);
      
      // Auto-collapse sidebar on medium screens
      if (window.innerWidth < NAVIGATION_BREAKPOINTS.sidebarCollapsed && !mobile) {
        setSidebarCollapsed(true);
      }
    };

    checkIsMobile();
    window.addEventListener('resize', checkIsMobile);
    
    return () => window.removeEventListener('resize', checkIsMobile);
  }, []);

  // Update navigation state when props change
  useEffect(() => {
    setNavigationState(prev => ({
      ...prev,
      currentPath: pathname,
      currentSpace,
      user,
    }));
  }, [pathname, currentSpace, user]);

  // Handle space selection
  const handleSpaceSelect = (space: SpaceContext) => {
    setNavigationState(prev => ({
      ...prev,
      currentSpace: space,
      recentSpaces: [
        space,
        ...prev.recentSpaces.filter(s => s.id !== space.id).slice(0, 4)
      ],
    }));
    
    onSpaceSelect?.(space);
    router.push(`/spaces/${space.id}`);
  };

  // Handle quick actions (mobile)
  const handleQuickAction = (actionId: string) => {
    switch (actionId) {
      case 'search':
        setNavigationState(prev => ({ ...prev, isMobileMenuOpen: true }));
        break;
      case 'create':
        router.push('/hivelab/create');
        break;
      case 'notifications':
        router.push('/notifications');
        break;
      default:
        onQuickAction?.(actionId);
    }
  };

  // Generate breadcrumb items if not provided
  const getBreadcrumbItems = (): BreadcrumbProps['items'] => {
    if (breadcrumbItems.length > 0) {
      return breadcrumbItems;
    }

    // Auto-generate from pathname
    const pathSegments = pathname.split('/').filter(Boolean);
    const items: BreadcrumbProps['items'] = [
      { label: 'Home', href: '/' }
    ];

    let currentPath = '';
    pathSegments.forEach((segment, index) => {
      currentPath += `/${segment}`;
      const isLast = index === pathSegments.length - 1;
      
      items.push({
        label: segment.charAt(0).toUpperCase() + segment.slice(1),
        href: isLast ? undefined : currentPath,
        isCurrentPage: isLast,
      });
    });

    return items;
  };

  const breadcrumbs = getBreadcrumbItems();
  const showBreadcrumbs = breadcrumbs.length > 1 && pathname !== '/';

  return (
    <div className="flex h-screen bg-[#0D0D0D] overflow-hidden">
      {/* Desktop Sidebar */}
      <AnimatePresence>
        {!isMobile && (
          <motion.div
            initial={{ x: -280 }}
            animate={{ x: 0 }}
            exit={{ x: -280 }}
            transition={{ duration: 0.3, ease: 'easeInOut' }}
          >
            <DesktopSidebar
              variant="desktop"
              user={navigationState.user}
              currentSpace={navigationState.currentSpace}
              spaces={spaces}
              onSpaceSelect={handleSpaceSelect}
              isCollapsed={sidebarCollapsed}
              onToggleCollapse={() => setSidebarCollapsed(!sidebarCollapsed)}
            >
              {children}
            </DesktopSidebar>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Content Area */}
      <div className={cn(
        "flex-1 flex flex-col",
        "overflow-hidden",
        isMobile && "pb-20" // Space for mobile bottom nav
      )}>
        
        {/* Top Bar with Breadcrumbs */}
        {showBreadcrumbs && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className={cn(
              "px-6 py-4",
              "border-b border-white/6",
              "bg-[#0D0D0D]/95 backdrop-blur-lg",
              "sticky top-0 z-30"
            )}
          >
            {isMobile ? (
              <CompactBreadcrumb items={breadcrumbs} />
            ) : currentSpace ? (
              <SpaceBreadcrumb
                spaceName={currentSpace.name}
                spaceType={currentSpace.type}
                items={breadcrumbs}
              />
            ) : (
              <Breadcrumb items={breadcrumbs} />
            )}
          </motion.div>
        )}

        {/* Page Content */}
        <div className="flex-1 overflow-auto">
          <motion.div
            key={pathname}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.2 }}
            className="h-full"
          >
            {children}
          </motion.div>
        </div>
      </div>

      {/* Mobile Bottom Navigation */}
      <AnimatePresence>
        {isMobile && (
          <MobileBottomNav
            variant="mobile"
            user={navigationState.user}
            currentSpace={navigationState.currentSpace}
            onQuickAction={handleQuickAction}
          >
            {children}
          </MobileBottomNav>
        )}
      </AnimatePresence>

      {/* Mobile Search/Menu Overlay */}
      <MobileNavOverlay
        isOpen={navigationState.isMobileMenuOpen}
        onClose={() => setNavigationState(prev => ({ 
          ...prev, 
          isMobileMenuOpen: false 
        }))}
      >
        <div className="p-6">
          <h2 className="text-white text-[22px] font-semibold mb-4">
            Search HIVE
          </h2>
          
          {/* Search input */}
          <div className="relative mb-6">
            <input
              type="text"
              placeholder="Search Spaces, Tools, People..."
              className={cn(
                "w-full px-4 py-3 pl-12",
                "bg-white/5 border border-white/10 rounded-lg",
                "text-white placeholder:text-white/50",
                "focus:outline-none focus:ring-2 focus:ring-[#FFD700]/50"
              )}
              autoFocus
            />
            <div className="absolute left-4 top-1/2 transform -translate-y-1/2">
              <span className="text-white/50">🔍</span>
            </div>
          </div>

          {/* Recent Spaces */}
          {navigationState.recentSpaces.length > 0 && (
            <div className="mb-6">
              <h3 className="text-white/70 text-[14px] font-medium mb-3 uppercase tracking-wide">
                Recent Spaces
              </h3>
              <div className="space-y-2">
                {navigationState.recentSpaces.map((space) => (
                  <button
                    key={space.id}
                    onClick={() => handleSpaceSelect(space)}
                    className={cn(
                      "w-full flex items-center gap-3 p-3",
                      "text-left rounded-lg",
                      "hover:bg-white/5 transition-colors"
                    )}
                  >
                    <div className="w-8 h-8 rounded bg-white/10 flex items-center justify-center">
                      <span className="text-sm text-white/70">
                        {space.name.charAt(0).toUpperCase()}
                      </span>
                    </div>
                    <div>
                      <div className="text-white font-medium">{space.name}</div>
                      <div className="text-white/50 text-sm capitalize">{space.type}</div>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Quick Actions */}
          {user?.isBuilder && (
            <div>
              <h3 className="text-white/70 text-[14px] font-medium mb-3 uppercase tracking-wide">
                Quick Actions
              </h3>
              <div className="grid grid-cols-2 gap-3">
                <button
                  onClick={() => router.push('/hivelab/create')}
                  className={cn(
                    "p-4 rounded-lg bg-white/5 hover:bg-white/10",
                    "flex flex-col items-center gap-2",
                    "transition-colors"
                  )}
                >
                  <span className="text-2xl">🛠️</span>
                  <span className="text-white text-sm font-medium">Create Tool</span>
                </button>
                
                <button
                  onClick={() => router.push('/analytics')}
                  className={cn(
                    "p-4 rounded-lg bg-white/5 hover:bg-white/10",
                    "flex flex-col items-center gap-2",
                    "transition-colors"
                  )}
                >
                  <span className="text-2xl">📊</span>
                  <span className="text-white text-sm font-medium">Analytics</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </MobileNavOverlay>
    </div>
  );
}

// Hook for using navigation context
export function useHiveNavigation() {
  const pathname = usePathname();
  
  return {
    currentPath: pathname,
    isInSpace: pathname.startsWith('/spaces/'),
    isBuilder: pathname.startsWith('/hivelab') || pathname.startsWith('/analytics'),
  };
} 