# Onboarding Architecture Migration Guide

This document outlines how to migrate from the current onboarding implementation to the new clean architecture implementation.

## Overview of New Architecture

The new onboarding architecture follows clean architecture principles with clear separation of concerns:

- **Data Layer**: Handles data sources and repositories implementation
- **Domain Layer**: Contains business logic with entities, repositories interfaces, and use cases
- **Presentation Layer**: Manages UI state and user interactions

## Key Components

### Data Layer
- `OnboardingLocalDataSource`: Interface for local storage operations
- `SharedPreferencesOnboardingDataSource`: Implementation using SharedPreferences
- `OnboardingRemoteDataSource`: Interface for remote data operations
- `FirebaseOnboardingDataSource`: Implementation using Firebase
- `OnboardingProfileModel`: Data model for transferring profile data
- `OnboardingRepositoryImpl`: Implementation of the repository pattern

### Domain Layer
- `OnboardingProfile`: Core domain entity
- `OnboardingRepository`: Repository interface
- Use Cases:
  - `CompleteOnboardingUseCase`: Finalize onboarding
  - `GetOnboardingProfileUseCase`: Retrieve profile data
  - `UpdateOnboardingProgressUseCase`: Save progress
  - `AbandonOnboardingUseCase`: Cancel onboarding

### Presentation Layer
- `OnboardingState`: UI state representation
- `OnboardingController`: StateNotifier for managing state
- Provider definitions for dependency injection

## Migration Steps

### Step 1: Initial Setup
1. Ensure all new files are in place
2. Add necessary dependencies to pubspec.yaml if not already present

### Step 2: Register in Provider Scope
Update the main app's ProviderScope to include the new providers:

```dart
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Step 3: Update Router Configuration
The router configuration remains the same, but update the OnboardingProfilePage to use the new controller:

```dart
// In router_config.dart - no changes needed to path configuration
```

### Step 4: Migrate UI Components
For each onboarding UI component:

1. Update imports to use the new controller
2. Replace state management with the new controller
3. Keep the same UI design and user flows

Example:

```dart
// Before
final controller = ref.watch(onboardingControllerProvider.notifier);
final state = ref.watch(onboardingControllerProvider);

// After
final controller = ref.watch(onboardingControllerProvider.notifier);
final state = ref.watch(onboardingControllerProvider);
// The usage pattern is the same, but the implementation is different
```

### Step 5: Testing
1. Test each screen in isolation
2. Test the complete onboarding flow
3. Verify data persistence and syncing with Firebase

### Step 6: Cutover
1. Update imports in all files that reference the old implementation
2. Remove the old implementation files when no longer referenced

## Benefits of the New Architecture

- **Improved Testability**: With proper separation of concerns
- **Better Maintainability**: Clear boundaries between layers
- **Enhanced Scalability**: Easier to add new features
- **Dependency Injection**: Dependencies explicitly defined through providers
- **Consistency**: Follows the same architectural pattern as the rest of the app

## Timeline

- **Phase 1**: Implement new architecture alongside existing code
- **Phase 2**: Migrate UI components to use new implementation
- **Phase 3**: Test and validate
- **Phase 4**: Remove old implementation 