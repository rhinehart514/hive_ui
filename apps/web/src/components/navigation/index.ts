// HIVE Navigation System
// Web-first React components with sophisticated design aesthetic
// Based on memory-bank architectural specifications

// Main navigation container
export { HiveNavigation, useHiveNavigation } from './NavigationContainer';

// Desktop components
export { DesktopSidebar } from './DesktopSidebar';

// Mobile components
export { MobileBottomNav, MobileNavOverlay } from './MobileBottomNav';

// Navigation items and sections
export { NavigationItem, NavigationItemSkeleton } from './NavigationItem';

// Breadcrumb navigation
export { 
  Breadcrumb, 
  SpaceBreadcrumb, 
  CompactBreadcrumb,
  BreadcrumbSkeleton
} from './Breadcrumb';

// Types and interfaces
export type {
  NavigationItem as NavigationItemType,
  NavigationSection,
  SpaceContext,
  UserContext,
  NavigationState,
  NavigationVariant,
  NavigationContainerProps,
  NavigationItemProps,
  SpaceNavigationProps,
  BreadcrumbProps,
  NavigationSearchResult,
  NavigationSearchProps,
} from './types';

// Constants and configuration
export {
  CORE_NAVIGATION,
  SPACE_TYPE_CONFIG,
  NAVIGATION_ANIMATIONS,
  NAVIGATION_BREAKPOINTS,
  SIDEBAR_DIMENSIONS,
  NAVIGATION_COLORS,
  NAVIGATION_Z_INDEX,
  SEARCH_CONFIG,
  MOBILE_NAVIGATION_ITEMS,
  MOBILE_QUICK_ACTIONS,
  SPACE_DISPLAY_ORDER,
  SPACE_LIST_LIMITS,
} from './constants'; 