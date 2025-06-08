# HIVE Navigation Standards

> "Navigation shouldn't be noticed—it should be intuitive enough to disappear."

## Core Navigation Philosophy

Navigation in HIVE provides intuitive, predictable pathways through the app while maintaining the premium aesthetic. Our navigation system:

1. **Guides users naturally** through logical workflows
2. **Maintains context** across transitions
3. **Responds immediately** to user input
4. **Adapts appropriately** to different platforms
5. **Preserves state** when navigating back

## Navigation Types

### Primary Navigation

The main navigation system that provides access to core app sections.

#### Specifications:
- **Component**: HiveBottomBar (mobile) or HiveSideNav (tablet/desktop)
- **Appearance**: Dark background with subtle separation from content
- **Active indicator**: Gold underline or highlight
- **Icons**: Consistent style, recognizable metaphors
- **Labels**: Concise, clear section names
- **Haptics**: Subtle feedback on selection

```dart
// Bottom navigation implementation
HiveBottomBar(
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
  items: [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Discover',
    ),
    // Additional items...
  ],
)
```

### Secondary Navigation

Used for navigation within sections or features.

#### Specifications:
- **Component**: HiveTabBar
- **Appearance**: Subtle, contextual to current section
- **Selection indicator**: Animated gold underline
- **Gesture support**: Horizontal swipe between tabs
- **Transitions**: Smooth cross-fade or slide

### Hierarchical Navigation

Used for drilling down into content or multi-level flows.

#### Specifications:
- **Implementation**: go_router with custom transitions
- **Back behavior**: Platform-appropriate back gesture/button
- **Transitions**: Push/pop with appropriate physics
- **History**: Maintain logical history stack

### Modal Navigation

Used for temporary, focused contexts that overlay the main interface.

#### Specifications:
- **Implementation**: HiveModalSheet or HiveDialog
- **Entrance**: Bottom-up slide or centered zoom
- **Dismissal**: Swipe down, tap outside, or explicit button
- **Nesting**: Avoid deeply nested modals

## Navigation Patterns

### Home to Detail Flow

```
Home Feed → Content Detail → Related Content
   ↑                 ↓
   └─────────────────┘
          Back
```

- **Forward transitions**: Slide from right (iOS-style)
- **Back transitions**: Slide to right with edge swipe support
- **State preservation**: Maintain scroll position when returning

### Authentication Flow

```
Login/Register → Form Steps → Verification → Success
      ↓              ↓           ↓
     Back           Back        Back
```

- **Forward transitions**: Simple fade or subtle zoom
- **Validation**: Block navigation if required fields incomplete
- **Back behavior**: Confirm if data would be lost

### Creation Flows

```
List/Feed → Creation Modal → Success Confirmation
              ↓
    Cancel (Confirm if data)
```

- **Modal approach**: Use modal presentation
- **Step indicators**: For multi-step creation
- **Confirmation**: Before discarding changes

## Implementation Guidelines

### Using go_router

HIVE uses go_router for declarative routing with the following structure:

```dart
// Example router configuration
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => customTransition(
            child: HomePage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/profile/:userId',
          pageBuilder: (context, state) => customTransition(
            child: ProfilePage(
              userId: state.pathParameters['userId']!,
            ),
            state: state,
          ),
        ),
        // Additional routes...
      ],
    ),
  ],
);

// Custom transition implementation
CustomTransitionPage customTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}
```

### Navigation State Management

```dart
// Example navigation with state preservation
class HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Restore scroll position if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedPosition = ref.read(scrollPositionProvider)['home'];
      if (savedPosition != null) {
        _scrollController.jumpTo(savedPosition);
      }
    });
  }
  
  @override
  void dispose() {
    // Save scroll position before leaving
    ref.read(scrollPositionProvider.notifier).update((state) => {
      ...state,
      'home': _scrollController.position.pixels,
    });
    _scrollController.dispose();
    super.dispose();
  }
  
  // Widget implementation...
}
```

## Platform-Specific Considerations

| Platform | Adaptation |
|----------|------------|
| iOS | Edge swipe for back, bottom tab bar |
| Android | Back button support, Material transitions |
| Web | Browser history integration, hover states |
| Desktop | Sidebar navigation option, keyboard shortcuts |

## Transition Specifications

| Transition | Duration | Curve | Usage |
|------------|----------|-------|-------|
| Push/Pop | 320ms | cubic-bezier(0.25, 0.8, 0.30, 1) | Primary navigation |
| Tab switch | 300ms | Curves.easeInOut | Tab navigation |
| Modal show | 350ms | cubic-bezier(0.0, 0, 0.2, 1) | Modal presentation |
| Modal hide | 250ms | cubic-bezier(0.4, 0, 0.2, 1) | Modal dismissal |

## Navigation Accessibility

- **Voice control**: Support for voice navigation
- **Keyboard navigation**: Full support for tab/enter/arrow keys
- **Screen readers**: Proper labeling of navigation elements
- **Reduced motion**: Simpler transitions when enabled

## Technical Implementation

### DeepLink Handling

```dart
// Deep link configuration in router
final router = GoRouter(
  initialLocation: '/home',
  routes: [...],
  redirect: (context, state) {
    // Handle authentication, feature flags, etc.
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn && state.fullPath != '/login') {
      return '/login?redirect=${state.fullPath}';
    }
    return null;
  },
);

// In main.dart
Widget build(BuildContext context) {
  return MaterialApp.router(
    routerConfig: router,
    // ...
  );
}
```

### Path Parameters & Query Parameters

```dart
// Defining route with parameters
GoRoute(
  path: '/event/:eventId',
  pageBuilder: (context, state) {
    final eventId = state.pathParameters['eventId']!;
    final showDetails = state.queryParameters['details'] == 'true';
    
    return customTransition(
      child: EventDetailsPage(
        eventId: eventId,
        showDetails: showDetails,
      ),
      state: state,
    );
  },
),

// Navigating with parameters
context.go('/event/123?details=true');
```

## Decision Matrix: Navigation Method Selection

| Scenario | Navigation Type | Component/Method |
|----------|----------------|-------------------|
| Main sections | Primary | HiveBottomBar / HiveSideNav |
| Within section | Secondary | HiveTabBar |
| Drill down | Hierarchical | go_router.push() |
| Temporary view | Modal | HiveModalSheet.show() |
| Action selection | Action sheet | HiveActionSheet.show() |
| Critical info | Dialog | HiveDialog.show() |

## Error Handling & Edge Cases

### Handling Navigation Errors

- **Invalid routes**: Redirect to 404 page or home
- **Permission issues**: Proper authorization checks before navigation
- **Network failures**: Graceful handling with retry options
- **Deeplink resolution**: Fallback for outdated or malformed links

### State Restoration

- **Form data**: Preserve across navigation events
- **Scroll position**: Maintain across the same type of screens
- **Selected tabs**: Remember when navigating back to sections
- **View preferences**: Persist user's view choices

## Testing Guidelines

- **Deeplink testing**: Verify all entry points work correctly
- **History testing**: Ensure back navigation works properly
- **Platform testing**: Verify iOS/Android specific patterns
- **Transition testing**: Check performance and correctness of animations

---

For implementation help, see the following references:
- [Navigation Implementation Examples](mdc:lib/core/navigation/examples/)
- [go_router Documentation](https://pub.dev/documentation/go_router/latest/)
- [Platform Navigation Patterns](mdc:lib/docs/platform_navigation_patterns.md) 