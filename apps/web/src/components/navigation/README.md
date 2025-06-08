# HIVE Navigation System

A sophisticated, responsive navigation system for the HIVE platform that adapts seamlessly between desktop sidebar and mobile bottom navigation layouts while maintaining the premium brand aesthetic.

## 🎯 Overview

The navigation system is built with:
- **Web-first architecture** using React/Next.js
- **Responsive design** that adapts from desktop sidebar to mobile bottom nav
- **HIVE brand aesthetic** with dark theme and gold accents
- **Smooth animations** following brand specifications
- **TypeScript** for full type safety
- **Framer Motion** for sophisticated animations

## 📱 Responsive Behavior

| Screen Size | Layout | Features |
|-------------|--------|----------|
| **Desktop** (1024px+) | Left sidebar | Collapsible, search, space list, user profile |
| **Mobile** (<768px) | Bottom navigation | Tab bar, floating actions, pull-up overlay |

## 🏗️ Architecture

```
navigation/
├── types.ts                 # TypeScript interfaces
├── constants.ts            # Configuration and constants
├── NavigationItem.tsx      # Core navigation item component
├── DesktopSidebar.tsx     # Desktop sidebar container
├── MobileBottomNav.tsx    # Mobile bottom navigation
├── Breadcrumb.tsx         # Breadcrumb components
├── NavigationContainer.tsx # Main orchestrator
└── index.ts               # Public exports
```

## 🚀 Quick Start

### Basic Usage

```tsx
import { HiveNavigation } from '@/components/navigation';

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <HiveNavigation
      user={currentUser}
      currentSpace={currentSpace}
      spaces={userSpaces}
      onSpaceSelect={handleSpaceSelect}
      onQuickAction={handleQuickAction}
    >
      {children}
    </HiveNavigation>
  );
}
```

### With Breadcrumbs

```tsx
const breadcrumbs = [
  { label: 'Home', href: '/' },
  { label: 'Spaces', href: '/spaces' },
  { label: 'CS Students', isCurrentPage: true },
];

<HiveNavigation
  breadcrumbItems={breadcrumbs}
  // ... other props
>
  {children}
</HiveNavigation>
```

## 📋 Component API

### HiveNavigation

Main navigation container that handles responsive layout switching.

```tsx
interface HiveNavigationProps {
  user?: UserContext;
  currentSpace?: SpaceContext;
  spaces?: SpaceContext[];
  breadcrumbItems?: BreadcrumbProps['items'];
  children: React.ReactNode;
  onSpaceSelect?: (space: SpaceContext) => void;
  onQuickAction?: (actionId: string) => void;
}
```

### UserContext

```tsx
interface UserContext {
  id: string;
  fullName: string;
  username: string;
  isBuilder: boolean;
  managedSpaces: string[];
  avatarUrl?: string;
}
```

### SpaceContext

```tsx
interface SpaceContext {
  id: string;
  name: string;
  type: 'system' | 'academic' | 'residential' | 'organization';
  isJoined: boolean;
  memberCount: number;
  unreadCount?: number;
}
```

## 🎨 Design Tokens

### Colors

```ts
const NAVIGATION_COLORS = {
  background: '#0D0D0D',      // Primary background
  surface: '#1E1E1E',         // Secondary surface start
  text: '#FFFFFF',            // Pure white text
  accent: '#FFD700',          // Gold accent (use sparingly)
  focus: '#FFD700',           // Focus ring color
  badge: '#FF3B30',           // Error red for notifications
};
```

### Animations

```ts
const NAVIGATION_ANIMATIONS = {
  sidebarCollapse: { duration: '300ms', easing: 'cubic-bezier(0.4, 0, 0.2, 1)' },
  itemHover: { scale: '1.02', duration: '150ms' },
  badgePulse: { duration: '2s', intensity: '1.1' },
};
```

### Breakpoints

```ts
const NAVIGATION_BREAKPOINTS = {
  mobile: 768,           // Below this = mobile navigation
  desktop: 1024,         // Above this = desktop sidebar
  sidebarCollapsed: 1200 // Above this = expanded sidebar by default
};
```

## 🔧 Customization

### Adding Navigation Items

```tsx
// In constants.ts
const CUSTOM_NAVIGATION: NavigationSection[] = [
  {
    id: 'custom',
    label: 'Custom Section',
    items: [
      {
        id: 'custom_item',
        label: 'Custom Item',
        href: '/custom',
        icon: CustomIcon,
        requiresAuth: true,
      },
    ],
  },
];
```

### Custom Space Types

```tsx
// Add to SPACE_TYPE_CONFIG in constants.ts
const SPACE_TYPE_CONFIG = {
  custom: {
    icon: CustomIcon,
    color: '#CUSTOM_COLOR',
    label: 'Custom Type',
  },
};
```

## 📱 Mobile Features

### Quick Actions

Floating action buttons for common tasks:
- **Search**: Opens search overlay
- **Create**: Navigate to tool creation (Builder only)
- **Notifications**: Navigate to notifications

### Touch Interactions

- **44pt minimum touch targets** for accessibility
- **Haptic feedback** on interactions
- **Swipe gestures** for natural navigation
- **Pull-up overlay** for search and menu

## 🎯 Navigation Items

### Core Navigation

- **Profile**: User dashboard and settings
- **Spaces**: Browse and manage Spaces
- **Events**: Campus events and calendar
- **Feed**: Activity feed and updates

### Builder Tools (Requires Builder Role)

- **HiveLAB**: Tool creation and management
- **Analytics**: Usage and engagement metrics

## 🔍 Search Functionality

- **Debounced search** (300ms) for performance
- **Multi-type results**: Spaces, Tools, Users, Pages
- **Recent searches** saved locally
- **Context-aware results** based on current Space

## 🚦 State Management

The navigation system manages:
- **Current path** tracking
- **Space context** with breadcrumbs
- **User permissions** for conditional features
- **Mobile menu state** for overlays
- **Recent spaces** for quick access

## ♿ Accessibility

- **ARIA labels** for screen readers
- **Keyboard navigation** support
- **Focus management** with visible indicators
- **High contrast** ratios (4.5:1 minimum)
- **Reduced motion** support

## 🧪 Testing

Visit `/test-navigation` to see the navigation system in action with:
- **Mock user data** with Builder/Student roles
- **Sample spaces** of different types
- **Interactive state switching**
- **Responsive layout demonstration

## 🎭 Animation Guidelines

All animations follow HIVE brand specifications:
- **Physics-based** motion with spring animations
- **300-400ms** for major transitions
- **150ms** for micro-interactions
- **Cubic-bezier easing** for premium feel

## 🔗 Integration

The navigation system integrates with:
- **Next.js routing** for seamless navigation
- **User authentication** for permission-based features
- **Space management** for context-aware navigation
- **Real-time updates** for notifications and unread counts

## 🛠️ Development

### Adding New Navigation Features

1. **Define types** in `types.ts`
2. **Add constants** in `constants.ts`
3. **Create components** following existing patterns
4. **Update exports** in `index.ts`
5. **Test responsively** on desktop and mobile

### Best Practices

- Use **semantic HTML** for accessibility
- Follow **brand color tokens** exactly
- Implement **smooth animations** for all interactions
- Test on **various screen sizes**
- Maintain **TypeScript compliance**

---

The HIVE navigation system embodies the platform's sophisticated aesthetic while providing intuitive, accessible navigation across all device types. 