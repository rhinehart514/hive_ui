# HIVE UI Component Standardization Guide

## Overview

This guide outlines the process for standardizing and consolidating UI components in the HIVE UI codebase. The goal is to reduce duplication, improve consistency, and enhance maintainability by creating a cohesive component library.

## Current Status

The HIVE UI currently has multiple implementations of similar components:

### Already Standardized
- ✅ **Buttons**: Consolidated into `HiveButton` in `lib/components/buttons.dart`
- ✅ **Cards**: Consolidated into `HiveCard` in `lib/components/cards.dart`
- ✅ **Text Fields**: Consolidated into `HiveTextField` in `lib/components/inputs.dart`
- ✅ **Navigation Bars**: Consolidated into `HiveNavigationBar` in `lib/components/navigation_bar.dart`

### Need Standardization
- ❌ **Text Fields**: Multiple implementations (`SmoothTextField`, `HiveTextField`, `CustomTextField`)
- ❌ **Modal Dialogs**: No standardized implementation
- ❌ **Headers/App Bars**: Multiple implementations
- ❌ **Transitions/Animations**: Need consolidation into reusable patterns

## Standardization Process

1. **Inventory**: Identify all implementations of a component type
2. **Analysis**: Determine the common patterns and unique requirements
3. **Design**: Create a flexible, standardized component that meets all needs
4. **Implementation**: Build the standardized component
5. **Migration**: Replace custom implementations with the standard component
6. **Documentation**: Update documentation and examples

## Clean Architecture Compatibility

The HIVE component library is designed to fit within the clean architecture approach:

### Presentation Layer Only

Our standardized components live exclusively in the presentation layer, maintaining clean architecture boundaries:

- They consume data via parameters, not by accessing repositories directly
- They emit events via callbacks, not by modifying business state directly
- They focus solely on rendering and user interaction

### State Management Guidelines

To maintain clean architecture separation:

1. **Component State vs. App State**
   - Internal component state (animations, focus, etc.) belongs in the component
   - Business state belongs in the application/domain layers

2. **Communication Pattern**
   - Data flows down: Pass data to components via parameters
   - Events flow up: Use callbacks to notify of user interactions

3. **Presentation Logic Only**
   - Keep validation logic in the domain layer
   - Keep data transformation in the application layer
   - Keep rendering logic in the components

### Example Pattern

```dart
// Proper separation of concerns
final profileState = ref.watch(profileProvider);

HiveButton(
  text: 'Save Profile',
  variant: HiveButtonVariant.primary,
  isLoading: profileState.isLoading,
  onPressed: profileState.isValid
      ? () => ref.read(profileProvider.notifier).saveProfile()
      : null,
)
```

For more details on implementing clean architecture with our component library, see the [Clean Architecture Guide](clean_architecture_guide.md).

## Navigation Bar Standardization

### Current Implementations
- `lib/components/bottom_nav_bar.dart`
- `lib/widgets/hive_navigation_bar.dart`
- `lib/widgets/apple_navigation_bar.dart`
- `lib/widgets/custom_navigation_bar.dart`
- `lib/widgets/profile_nav_bar.dart`

### Standardization Plan
1. Create a unified `HiveNavigationBar` with:
   - Support for different styles (standard, minimal, iOS-inspired)
   - Consistent animation patterns
   - Standardized haptic feedback
   - Support for badges and notifications
   - Proper glassmorphism effects

2. Implementation in `lib/components/navigation_bar.dart`

3. Migration strategy:
   - Update routes to use the new component
   - Ensure backward compatibility during transition

## Modal Component Standardization

### Current Implementations
- Action sheets in `lib/theme/ios_style.dart`
- Custom modals scattered throughout the codebase
- Bottom sheets with varying implementations

### Standardization Plan
1. Create standardized components:
   - `HiveBottomSheet`
   - `HiveDialog`
   - `HiveActionSheet`
   - `HiveModal`

2. Implementation in `lib/components/modals.dart`

3. Common features:
   - Consistent animations and transitions
   - Glassmorphism styling
   - Haptic feedback
   - Accessibility support

## Text Field Consolidation

### Current Implementations
- `lib/components/inputs.dart` (HiveTextField)
- `lib/widgets/smooth_text_field.dart`
- `lib/widgets/custom_text_field.dart`
- Various form fields in `lib/widgets/form_fields/`

### Standardization Plan
1. Enhance `HiveTextField` to incorporate features from other implementations
2. Create specialized variants for specific use cases
3. Ensure consistent styling, animations, and behavior

## Header/App Bar Standardization

### Current Implementations
- `lib/widgets/app_header.dart`
- `lib/widgets/profile_header.dart`
- Other custom headers

### Standardization Plan
1. Create a unified `HiveAppBar` component with:
   - Support for different styles and configurations
   - Consistent back navigation
   - Title/subtitle handling
   - Action buttons
   - Search integration
   - Glassmorphism effects

## Transition/Animation Standardization

### Current Implementations
- `lib/widgets/page_transitions.dart`
- Custom animations throughout the codebase

### Standardization Plan
1. Create a standardized animation system:
   - Page transitions
   - Micro-interactions
   - Loading states
   - Feedback animations

2. Document standard durations, curves, and patterns

## Implementation Priorities

1. **High Priority**:
   - Modal component standardization
   - Header/app bar standardization

2. **Medium Priority**:
   - Text field consolidation
   - Animation standardization

3. **Lower Priority**:
   - List component standardization
   - Form component standardization

## Best Practices for New Components

1. **Design for Flexibility**: Components should be configurable for different use cases
2. **Maintain Consistency**: Follow the established design system
3. **Document Thoroughly**: Include examples and usage guidelines
4. **Test Different Scenarios**: Ensure components work in various contexts
5. **Performance**: Optimize for minimal rebuilds and efficient rendering

## How to Contribute

When standardizing a component:

1. Create an issue describing the component to be standardized
2. Document current implementations and their unique features
3. Design the standardized component API
4. Implement the component in the appropriate file
5. Create examples in documentation
6. Update the refactoring checklist

## Conclusion

Standardizing components will greatly improve the maintainability and consistency of the HIVE UI. This is an ongoing process that will evolve as the application grows and requirements change. 