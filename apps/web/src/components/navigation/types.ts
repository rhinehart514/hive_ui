// Navigation system types for HIVE vBETA
// Based on memory-bank/spaces_system.md and system architecture

export interface NavigationItem {
  id: string;
  label: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: number | string;
  isActive?: boolean;
  requiresAuth?: boolean;
  requiresBuilder?: boolean;
}

export interface NavigationSection {
  id: string;
  label?: string;
  items: NavigationItem[];
  collapsible?: boolean;
  defaultCollapsed?: boolean;
}

export interface SpaceContext {
  id: string;
  name: string;
  type: 'system' | 'academic' | 'residential' | 'organization';
  isJoined: boolean;
  memberCount: number;
  unreadCount?: number;
}

export interface UserContext {
  id: string;
  fullName: string;
  username: string;
  isBuilder: boolean;
  managedSpaces: string[];
  avatarUrl?: string;
}

export interface NavigationState {
  currentPath: string;
  currentSpace?: SpaceContext;
  user?: UserContext;
  isLoading: boolean;
  isMobileMenuOpen: boolean;
  searchQuery: string;
  recentSpaces: SpaceContext[];
}

export type NavigationVariant = 'desktop' | 'mobile';
export type NavigationPosition = 'left' | 'bottom';

// Component prop interfaces
export interface NavigationContainerProps {
  variant: NavigationVariant;
  children: React.ReactNode;
  user?: UserContext;
  currentSpace?: SpaceContext;
}

export interface NavigationItemProps {
  item: NavigationItem;
  variant: NavigationVariant;
  onClick?: (item: NavigationItem) => void;
}

export interface SpaceNavigationProps {
  spaces: SpaceContext[];
  currentSpace?: SpaceContext;
  onSpaceSelect: (space: SpaceContext) => void;
  variant: NavigationVariant;
}

export interface BreadcrumbProps {
  items: Array<{
    label: string;
    href?: string;
    isCurrentPage?: boolean;
  }>;
  maxItems?: number;
}

// Animation and interaction types
export interface NavigationAnimations {
  sidebarCollapse: {
    duration: string;
    easing: string;
  };
  itemHover: {
    scale: string;
    duration: string;
  };
  badgePulse: {
    duration: string;
    intensity: string;
  };
}

// Search and filtering
export interface NavigationSearchResult {
  type: 'space' | 'tool' | 'user' | 'page';
  id: string;
  title: string;
  subtitle?: string;
  href: string;
  icon?: React.ComponentType<{ className?: string }>;
  context?: string; // "in CS Students" or "by Sarah Chen"
}

export interface NavigationSearchProps {
  onSearch: (query: string) => void;
  results: NavigationSearchResult[];
  isLoading: boolean;
  variant: NavigationVariant;
} 