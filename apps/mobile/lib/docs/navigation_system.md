# Apple-Inspired Navigation System

This document explains the custom navigation system implemented in the app, which takes inspiration from Apple's iOS fluid interactions and haptic feedback patterns.

## Components

### 1. AppleNavigationBar

Located in `lib/widgets/apple_navigation_bar.dart`, this component provides:

- Fluid animations with spring effects when switching tabs
- Animated pill indicator for the selected tab
- Contextual haptic feedback (lighter for adjacent tabs)
- Blur effect and translucency
- Staggered entrance animations

```dart
// Usage:
MainNavigationBar(
  selectedIndex: _selectedIndex,
  onItemSelected: _onNavItemTapped,
)
```

### 2. Navigation Transitions

Located in `lib/utils/navigation_transitions.dart`, these utilities provide:

- Smooth page transitions with fade and slide effects
- Appropriate haptic feedback for different navigation types
- Custom route class (ApplePageRoute) for consistent transitions

```dart
// Usage for custom routes:
Navigator.of(context).push(
  ApplePageRoute(
    page: YourPage(),
    fullscreenDialog: false, // Set to true for modal presentations
  )
);

// Usage for haptic feedback:
NavigationTransitions.applyNavigationFeedback(
  type: NavigationFeedbackType.pageTransition,
);
```

### 3. Router Integration

The router in `lib/router.dart` uses custom transitions for all routes:

```dart
GoRoute(
  path: '/your-path',
  pageBuilder: (context, state) => buildAppleTransition(
    context: context,
    state: state,
    child: YourScreen(),
  ),
),
```

## Haptic Feedback Types

The system provides different haptic feedback patterns for different navigation actions:

- `tabChange`: Light feedback when switching between tabs (uses HapticFeedback.selectionClick)
- `pageTransition`: Medium-light feedback when navigating to a new screen (uses HapticFeedback.lightImpact)
- `modalPresent`: Medium feedback when presenting a modal (uses HapticFeedback.mediumImpact)
- `modalDismiss`: Light feedback when dismissing a modal (uses HapticFeedback.selectionClick)
- `error`: Strong feedback for error states (uses HapticFeedback.vibrate)

## Animation Parameters

- Tab transitions: 350ms with easeOutCubic curve
- Page transitions: 400ms forward, 300ms reverse with custom curves
- Indicator animations: Use spring physics for natural motion
- Staggered animations: Items animate with slight delays for visual interest

## Best Practices

1. Use the appropriate feedback type for each navigation action
2. Keep animations between 300-500ms for optimal fluidity
3. Combine visual transitions with haptic feedback for immersive experiences
4. Use spring animations for more natural, physical interactions 