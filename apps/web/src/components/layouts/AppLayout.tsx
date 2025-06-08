'use client';

import React, { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { HiveNavigation } from '@/components/navigation';
import { useAuth } from '@/context/AuthContext';
import type { SpaceContext, UserContext } from '@/components/navigation/types';

interface AppLayoutProps {
  children: React.ReactNode;
}

// Mock data for vBETA development - will be replaced with real API calls
const mockSpaces: SpaceContext[] = [
  {
    id: 'new_students_2025',
    name: 'New Students 2025',
    type: 'system',
    isJoined: true,
    memberCount: 2847,
    unreadCount: 0,
  },
  {
    id: 'cs_students',
    name: 'CS Students',
    type: 'academic',
    isJoined: true,
    memberCount: 456,
    unreadCount: 3,
  },
  {
    id: 'warren_towers',
    name: 'Warren Towers',
    type: 'residential',
    isJoined: true,
    memberCount: 1205,
    unreadCount: 1,
  },
];

export function AppLayout({ children }: AppLayoutProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { user: authUser, isLoading } = useAuth();
  
  const [currentSpace, setCurrentSpace] = useState<SpaceContext | undefined>();
  const [userSpaces, setUserSpaces] = useState<SpaceContext[]>([]);

  // Convert auth user to navigation user context
  const navigationUser: UserContext | undefined = authUser ? {
    id: authUser.uid,
    fullName: authUser.displayName || 'Student',
    username: authUser.email?.split('@')[0] || 'student',
    isBuilder: false, // Will be determined from user profile
    managedSpaces: [], // Will be loaded from user data
    avatarUrl: authUser.photoURL || undefined,
  } : undefined;

  // Load user spaces and set current space based on route
  useEffect(() => {
    if (navigationUser) {
      // For vBETA, all users auto-join system spaces
      setUserSpaces(mockSpaces);
      
      // Set current space based on URL
      const spaceIdFromPath = pathname.split('/spaces/')[1];
      if (spaceIdFromPath) {
        const space = mockSpaces.find(s => s.id === spaceIdFromPath);
        setCurrentSpace(space);
      } else {
        // Default to first space if on main pages
        setCurrentSpace(mockSpaces[0]);
      }
    }
  }, [navigationUser, pathname]);

  // Generate breadcrumbs based on current route
  const generateBreadcrumbs = () => {
    const pathSegments = pathname.split('/').filter(Boolean);
    const breadcrumbs = [{ label: 'Profile', href: '/profile' }];

    if (pathSegments.length === 0) {
      return breadcrumbs;
    }

    // Handle specific route patterns
    if (pathSegments[0] === 'spaces' && pathSegments[1]) {
      const space = userSpaces.find(s => s.id === pathSegments[1]);
      breadcrumbs.push(
        { label: 'Spaces', href: '/spaces' },
        { 
          label: space?.name || 'Space', 
          isCurrentPage: pathSegments.length === 2 
        }
      );
      
      if (pathSegments[2]) {
        breadcrumbs.push({
          label: pathSegments[2].charAt(0).toUpperCase() + pathSegments[2].slice(1),
          isCurrentPage: true
        });
      }
    } else if (pathSegments[0] === 'events') {
      breadcrumbs.push({ label: 'Events', isCurrentPage: pathSegments.length === 1 });
    } else if (pathSegments[0] === 'hivelab') {
      breadcrumbs.push({ label: 'HiveLAB', isCurrentPage: pathSegments.length === 1 });
    } else if (pathSegments[0] === 'feed') {
      breadcrumbs.push({ label: 'Feed', isCurrentPage: pathSegments.length === 1 });
    } else {
      // Generic breadcrumb generation
      let currentPath = '';
      pathSegments.forEach((segment, index) => {
        currentPath += `/${segment}`;
        const isLast = index === pathSegments.length - 1;
        
        breadcrumbs.push({
          label: segment.charAt(0).toUpperCase() + segment.slice(1),
          href: isLast ? undefined : currentPath,
          isCurrentPage: isLast,
        });
      });
    }

    return breadcrumbs;
  };

  const handleSpaceSelect = (space: SpaceContext) => {
    setCurrentSpace(space);
    router.push(`/spaces/${space.id}`);
  };

  const handleQuickAction = (actionId: string) => {
    switch (actionId) {
      case 'search':
        // Open search modal/overlay
        break;
      case 'create':
        router.push('/hivelab/create');
        break;
      case 'notifications':
        router.push('/notifications');
        break;
    }
  };

  // Show loading state while auth is initializing
  if (isLoading) {
    return (
      <div className="h-screen bg-[#0D0D0D] flex items-center justify-center">
        <div className="animate-pulse">
          <div className="w-8 h-8 bg-[#FFD700] rounded-full"></div>
        </div>
      </div>
    );
  }

  // Public routes that don't need navigation
  const publicRoutes = ['/', '/auth', '/signup', '/signin'];
  const isPublicRoute = publicRoutes.some(route => 
    pathname === route || pathname.startsWith(`${route}/`)
  );

  if (isPublicRoute || !navigationUser) {
    return <>{children}</>;
  }

  return (
    <HiveNavigation
      user={navigationUser}
      currentSpace={currentSpace}
      spaces={userSpaces}
      breadcrumbItems={generateBreadcrumbs()}
      onSpaceSelect={handleSpaceSelect}
      onQuickAction={handleQuickAction}
    >
      {children}
    </HiveNavigation>
  );
} 