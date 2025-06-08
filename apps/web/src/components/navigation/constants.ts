// Navigation constants and configuration for HIVE vBETA
// Based on system architecture and user flows from memory-bank

import { 
  Home, 
  Calendar, 
  Users, 
  Settings, 
  Search,
  Plus,
  Bell,
  User,
  Grid3X3,
  BookOpen,
  Building2,
  Zap,
  TrendingUp,
  Construction
} from 'lucide-react';

import type { NavigationSection, NavigationAnimations } from './types';

// Core navigation sections based on HIVE's main systems
export const CORE_NAVIGATION: NavigationSection[] = [
  {
    id: 'main',
    items: [
      {
        id: 'profile',
        label: 'Profile',
        href: '/profile',
        icon: Home,
        requiresAuth: true,
      },
      {
        id: 'spaces',
        label: 'Spaces',
        href: '/spaces',
        icon: Grid3X3,
        requiresAuth: true,
      },
      {
        id: 'events',
        label: 'Events',
        href: '/events',
        icon: Calendar,
        requiresAuth: true,
      },
      {
        id: 'feed',
        label: 'Feed',
        href: '/feed',
        icon: TrendingUp,
        requiresAuth: true,
      },
    ],
  },
  {
    id: 'builder',
    label: 'Builder Tools',
    items: [
      {
        id: 'hivelab',
        label: 'HiveLAB',
        href: '/hivelab',
        icon: Construction,
        requiresAuth: true,
        requiresBuilder: true,
      },
      {
        id: 'analytics',
        label: 'Analytics',
        href: '/analytics',
        icon: TrendingUp,
        requiresAuth: true,
        requiresBuilder: true,
      },
    ],
    collapsible: true,
    defaultCollapsed: false,
  },
  {
    id: 'account',
    items: [
      {
        id: 'settings',
        label: 'Settings',
        href: '/settings',
        icon: Settings,
        requiresAuth: true,
      },
    ],
  },
];

// Space type icons and colors
export const SPACE_TYPE_CONFIG = {
  system: {
    icon: Zap,
    color: '#56CCF2', // Info blue
    label: 'System',
  },
  academic: {
    icon: BookOpen,
    color: '#8CE563', // Success green
    label: 'Academic',
  },
  residential: {
    icon: Building2,
    color: '#FF9500', // Warning orange
    label: 'Residential',
  },
  organization: {
    icon: Users,
    color: '#FFD700', // HIVE accent gold
    label: 'Organization',
  },
} as const;

// Animation configurations following brand_aesthetic.md specifications
export const NAVIGATION_ANIMATIONS: NavigationAnimations = {
  sidebarCollapse: {
    duration: '300ms',
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)', // easeInOut
  },
  itemHover: {
    scale: '1.02',
    duration: '150ms',
  },
  badgePulse: {
    duration: '2s',
    intensity: '1.1',
  },
};

// Responsive breakpoints
export const NAVIGATION_BREAKPOINTS = {
  mobile: 768, // Below this = mobile navigation
  desktop: 1024, // Above this = desktop sidebar
  sidebarCollapsed: 1200, // Above this = expanded sidebar by default
} as const;

// Sidebar dimensions following 16pt/24pt spacing rules
export const SIDEBAR_DIMENSIONS = {
  expanded: {
    width: '280px',
    padding: '24px',
  },
  collapsed: {
    width: '80px',
    padding: '16px',
  },
  mobile: {
    height: '80px',
    padding: '16px',
  },
} as const;

// Color tokens for navigation (following brand_aesthetic.md)
export const NAVIGATION_COLORS = {
  background: '#0D0D0D', // Primary background
  surface: '#1E1E1E', // Secondary surface start
  surfaceEnd: '#2A2A2A', // Secondary surface end
  text: '#FFFFFF', // Pure white text
  textSecondary: 'rgba(255, 255, 255, 0.7)', // 70% opacity
  accent: '#FFD700', // Gold accent - use sparingly
  border: 'rgba(255, 255, 255, 0.06)', // Subtle borders
  hover: 'rgba(255, 255, 255, 0.05)', // Hover backgrounds
  focus: '#FFD700', // Focus ring color
  badge: '#FF3B30', // Error red for notifications
} as const;

// Z-index layers
export const NAVIGATION_Z_INDEX = {
  sidebar: 40,
  mobileNav: 50,
  overlay: 30,
  dropdown: 60,
} as const;

// Search configuration
export const SEARCH_CONFIG = {
  placeholder: 'Search Spaces, Tools, People...',
  debounceMs: 300,
  maxResults: 8,
  recentSearchesMax: 5,
} as const;

// Mobile navigation items (subset of desktop for bottom nav)
export const MOBILE_NAVIGATION_ITEMS = [
  'profile',
  'spaces', 
  'events',
  'feed',
] as const;

// Quick actions for mobile (floating action button style)
export const MOBILE_QUICK_ACTIONS = [
  {
    id: 'search',
    label: 'Search',
    icon: Search,
    href: '/search',
  },
  {
    id: 'create',
    label: 'Create',
    icon: Plus,
    href: '/create',
    requiresBuilder: true,
  },
  {
    id: 'notifications',
    label: 'Notifications', 
    icon: Bell,
    href: '/notifications',
  },
] as const;

// Default space order for navigation
export const SPACE_DISPLAY_ORDER = [
  'system',
  'academic', 
  'residential',
  'organization',
] as const;

// Maximum items to show in space list before "Show more"
export const SPACE_LIST_LIMITS = {
  desktop: 8,
  mobile: 4,
} as const; 