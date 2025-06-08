# Hive UI Coding Standards

This document outlines the coding standards and best practices for the Hive UI project, based on lessons learned from successful refactoring efforts.

## Table of Contents

1. [Code Organization](#code-organization)
2. [Component Design](#component-design)
3. [State Management](#state-management)
4. [Styling](#styling)
5. [Error Handling](#error-handling)
6. [Documentation](#documentation)
7. [Testing](#testing)
8. [Performance](#performance)

## Code Organization

### Directory Structure

```
lib/
  ├── pages/           # Full screens/pages
  ├── widgets/         # Reusable UI components
  │   └── feature/     # Feature-specific widgets
  ├── models/          # Data structures
  ├── providers/       # State management
  ├── services/        # Business logic and API interactions
  ├── extensions/      # Extension methods
  ├── theme/           # Styling constants and themes
  ├── utils/           # Utility functions
  └── docs/            # Documentation
```

### File Naming

- Use **snake_case** for all file names
- Use **singular** for files with a single export (e.g., `user_profile.dart`, not `user_profiles.dart`)
- Group related files in feature-specific directories
- Use descriptive names that indicate functionality

### Import Organization

Organize imports in the following order, with a blank line between each group:

```dart
// Dart and Flutter imports
import 'dart:async';
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

// Project imports by category
// Models
import 'package:hive_ui/models/user_profile.dart';

// Providers
import 'package:hive_ui/providers/profile_provider.dart';

// Services
import 'package:hive_ui/services/user_service.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';

// Widgets
import 'package:hive_ui/widgets/profile/profile_card.dart';
```

### File Size

- **Maximum 300 lines** per file
- Extract complex components into separate files
- Split large classes into smaller, focused classes

## Component Design

### Widget Structure

- Use **StatelessWidget** when possible
- Use **ConsumerWidget** for components that need to access providers
- Only use **StatefulWidget** when necessary for local UI state
- Use **ConsumerStatefulWidget** when combining local state with providers

### Parameter Design

- Use **required** for mandatory parameters
- Provide sensible defaults for optional parameters
- Use **named parameters** for widgets with more than 2 parameters
- Add documentation for each parameter

```dart
/// A widget that displays user profile information
class ProfileCard extends StatelessWidget {
  /// The user profile to display
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when the edit button is pressed
  final void Function(UserProfile profile)? onEditPressed;
  
  /// Height of the card (defaults to 200)
  final double height;

  const ProfileCard({
    super.key,
    required this.profile,
    this.isCurrentUser = false,
    this.onEditPressed,
    this.height = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

### Widget Nesting

- Limit nesting to **5 levels maximum**
- Extract nested widgets into named methods or separate widget classes
- Use **extract method/widget** refactoring to improve readability

### Component Reusability

- Design components for reuse across multiple screens
- Avoid hard-coding values that might change
- Use callbacks for interaction rather than direct state manipulation
- Provide sensible defaults for appearance

## State Management

### Riverpod Provider Design

- Use **StateProvider** for simple state
- Use **StateNotifierProvider** for complex state
- Use **FutureProvider** for async data
- Use **Provider** for computed values

### Provider Organization

- Place providers at the top of files or in dedicated provider files
- Use explicit typing for all providers
- Add documentation for each provider

```dart
/// Provider for user profile data
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile>>((ref) {
  return UserProfileNotifier(ref);
});

/// Notifier for managing user profile data
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final Ref _ref;
  
  UserProfileNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadProfile();
  }
  
  // Implementation
}
```

### AsyncValue Pattern

Always follow this pattern for async operations:

```dart
Future<void> loadData() async {
  // Set loading state
  state = const AsyncValue.loading();
  
  try {
    // Perform async operation
    final data = await _apiService.fetchData();
    
    // Set success state
    state = AsyncValue.data(data);
  } catch (error, stackTrace) {
    // Set error state
    state = AsyncValue.error(error, stackTrace);
  }
}
```

### UI State Handling

Always handle all three states in UI:

```dart
profileProvider.when(
  loading: () => const LoadingIndicator(),
  error: (error, stackTrace) => ErrorDisplay(error: error.toString()),
  data: (profile) => ProfileContent(profile: profile),
);
```

## Styling

### Theme Usage

- Use **AppColors** for all colors
- Use **Theme.of(context)** for text styles
- Avoid hard-coded colors or text styles

### Glassmorphism

- Use the glassmorphism extension for card-like UI elements
- Follow the GlassmorphismGuide constants for consistent blur and opacity

```dart
Container(
  // Container styling
).addGlassmorphism(
  blur: GlassmorphismGuide.kCardBlur,
  opacity: GlassmorphismGuide.kCardGlassOpacity,
  addGoldAccent: true,
);
```

### Spacing and Layout

- Use **SizedBox** for spacing rather than Padding with zero on some sides
- Use **EdgeInsets.symmetric** or **EdgeInsets.all** when padding is symmetrical
- Follow a consistent spacing scale (8, 16, 24, 32, etc.)

### Responsive Design

- Use **MediaQuery** to access screen dimensions
- Use **LayoutBuilder** for complex responsive layouts
- Prefer fractional sizes (e.g., `width: MediaQuery.of(context).size.width * 0.8`)
- Test layouts on different screen sizes

## Error Handling

### UI Error States

- Always provide user-friendly error messages
- Include retry functionality where appropriate
- Design consistent error visuals

```dart
Widget _buildErrorState(String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(error, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(dataProvider),
          child: const Text('Try Again'),
        ),
      ],
    ),
  );
}
```

### Error Logging

- Log errors with enough context to debug
- Avoid exposing sensitive information in user-facing error messages
- Consider implementing error reporting to a monitoring service

## Documentation

### Class and Method Documentation

- Add documentation for all public classes and methods
- Use `///` format for documentation
- Include parameter descriptions and return value information

```dart
/// Fetches user profile data from the API
/// 
/// [userId] The ID of the user to fetch
/// [forceRefresh] Whether to bypass cache and force a fresh fetch
/// 
/// Returns a Future that completes with the user profile or throws an exception
Future<UserProfile> fetchUserProfile(String userId, {bool forceRefresh = false}) async {
  // Implementation
}
```

### Code Comments

- Focus on explaining **why**, not **what**
- Comment complex logic or business rules
- Use `//` for implementation comments

### Example Usage

- Add example usage in documentation for complex components
- Consider creating a UI showcase for component variants

## Testing

### Unit Testing

- Test all business logic and providers
- Mock dependencies for isolated testing
- Use `test` and `mockito` packages

### Widget Testing

- Test key UI components in isolation
- Verify user interactions work as expected
- Use `flutter_test` package

### Integration Testing

- Test critical user flows
- Verify navigation and state persistence
- Use `integration_test` package

## Performance

### Widget Optimization

- Use `const` constructors when possible
- Implement `==` and `hashCode` for custom classes
- Use `RepaintBoundary` for complex animations
- Avoid rebuilding large widget trees

### Memory Management

- Dispose controllers and listeners in `dispose` method
- Avoid storing large data structures in memory
- Use pagination for large lists

### Build Performance

- Use the Flutter DevTools performance view to identify bottlenecks
- Consider using `Visibility` widget instead of conditional rendering for complex widgets
- Use `ListView.builder` instead of `ListView` for long lists

---

These standards should evolve based on team feedback and project needs. Regular code reviews should enforce these standards and identify areas for improvement. 