# HIVE Application Overview

## What is HIVE?

HIVE is a premium social networking platform designed specifically for university students. The application serves as a centralized hub for campus life, connecting students with clubs, organizations, events, and each other. The name "HIVE" represents the buzzing activity of a university campus and the interconnected nature of student life.

## Core Features

### 1. User Profiles
- Academic information (major, year, residence)
- Interests and activities
- Profile customization
- Activity feed
- Verification tiers (public, verified, verifiedPlus)

### 2. Clubs & Organizations
- Discovery of campus organizations
- Club spaces with details and membership information
- Club roles and permissions
- Event hosting capabilities
- Member management

### 3. Events
- Campus event discovery
- RSVP functionality
- Event details (location, time, description)
- Club-hosted and campus-wide events
- Calendar integration

### 4. Messaging
- Direct messaging between users
- Group chats for clubs and events
- Rich media sharing
- Read receipts and typing indicators

### 5. Feed & Content
- Personalized activity feed
- Campus news and announcements
- Club and event updates
- Friend activities

## Technical Architecture

### Frontend Architecture
HIVE UI is built with Flutter and follows a clean architecture approach:

#### 1. Presentation Layer
- **Pages**: Main screens of the application
- **Widgets**: Reusable UI components
- **Components**: Complex, composition-based UI elements

#### 2. Application Layer
- **Providers**: State management using Riverpod
- **Controllers**: Business logic coordinators

#### 3. Domain Layer
- **Models**: Core data structures
- **Services**: Business logic and operations

#### 4. Data Layer
- **Repositories**: Data access abstraction
- **Data Sources**: API clients and local storage

## Architecture Implementation Guidelines

### Feature-Based Organization

HIVE organizes code using a feature-first approach within the clean architecture paradigm:

```
features/
  ├── feature_name/
  │    ├── data/           # Data sources, repositories, and DTOs
  │    ├── domain/         # Entities and use cases  
  │    └── presentation/   # UI components, controllers, and screens
```

### Layer Responsibilities

1. **Presentation Layer**
   - Renders UI using standardized components
   - Manages UI state and user interactions
   - Delegates business operations to application layer
   - Uses Riverpod's Consumer widgets to access state

2. **Application Layer**
   - Orchestrates use cases from domain layer
   - Manages application state using Riverpod providers
   - Transforms domain data for presentation
   - Handles errors and loading states

3. **Domain Layer**
   - Defines business entities with immutable data structures
   - Contains use cases that encapsulate business operations
   - Defines repository interfaces that abstract data access
   - Has no dependencies on UI or external data sources

4. **Data Layer**
   - Implements repository interfaces from domain layer
   - Handles network requests, caching, and persistence
   - Maps DTOs to domain entities and vice versa
   - Manages error handling for external services

### Implementation Patterns

#### Providers

Use different provider types based on state complexity:

```dart
// Simple state
final selectedTabProvider = StateProvider<int>((ref) => 0);

// Complex state with operations
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

// Async data
final eventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final repository = ref.read(eventRepositoryProvider);
  return repository.getUpcomingEvents();
});
```

#### State Classes

Use immutable state classes with copyWith methods:

```dart
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });
  
  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

#### Standard UI Patterns

For presentation layer implementation:

```dart
// Feature screen with proper clean architecture boundaries
class ClubDetailsScreen extends ConsumerWidget {
  final String clubId;
  
  const ClubDetailsScreen({required this.clubId, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Connect to application layer
    final clubState = ref.watch(clubDetailsProvider(clubId));
    
    return Scaffold(
      appBar: HiveAppBar(
        title: clubState.maybeWhen(
          data: (club) => club.name,
          orElse: () => 'Club Details',
        ),
      ),
      body: clubState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplay(message: error.toString()),
        data: (club) => _buildClubDetails(context, ref, club),
      ),
    );
  }
  
  Widget _buildClubDetails(BuildContext context, WidgetRef ref, Club club) {
    return ListView(
      children: [
        // Use standardized components
        HiveCard(
          type: HiveCardType.club,
          child: ClubHeaderContent(club: club),
        ),
        
        // Event calls application layer methods through callbacks
        HiveButton(
          text: club.isMember ? 'Leave Club' : 'Join Club',
          variant: club.isMember ? HiveButtonVariant.secondary : HiveButtonVariant.primary,
          onPressed: () => ref.read(clubDetailsProvider(clubId).notifier).toggleMembership(),
        ),
      ],
    );
  }
}
```

### Standardized Components Usage

Always use standardized components from the component library:

- Use `HiveButton` instead of raw ElevatedButton or TextButton
- Use `HiveTextField` instead of raw TextField 
- Use `HiveCard` for all card containers
- Use `HiveNavigationBar` for navigation instead of BottomNavigationBar

This ensures UI consistency and properly maintains separation of concerns.

### For More Information

For detailed guidance on implementing clean architecture in HIVE, refer to:
- [Clean Architecture Guide](clean_architecture_guide.md)
- [Component Standardization Guide](component_standardization_guide.md)

### Design System

HIVE features a premium, minimalistic design with:

1. **Dark Theme**: A sophisticated dark color scheme with:
   - Pure black backgrounds (AppColors.black)
   - White text (AppColors.white)
   - Gold accents (AppColors.gold)

2. **Glassmorphism**: Frosted glass effects for:
   - Cards
   - Modal dialogs
   - Bottom sheets
   - Headers

3. **Animation System**:
   - Page transitions (400ms duration)
   - State changes (300ms duration)
   - Micro-interactions (150-200ms duration)
   - Spring physics for natural movement

4. **Haptic Feedback**:
   - Light feedback for selection
   - Medium feedback for confirmation
   - Heavy feedback for errors or important actions

5. **Typography**:
   - Google Fonts: Outfit for headings and titles
   - Google Fonts: Inter for body text and smaller elements

## State Management

HIVE uses Riverpod for state management:

1. **State Providers**: Simple state variables
2. **State Notifier Providers**: Complex state with operations
3. **Future Providers**: Asynchronous data fetching
4. **Family Providers**: Parameterized providers

## Navigation

The application uses go_router for navigation:

1. **Routes**: Defined in router.dart
2. **Transitions**: Apple-inspired transitions with haptic feedback
3. **Deep Linking**: Support for deep links to specific content

## User Flow

1. **Onboarding**:
   - Landing page
   - Sign in / Create account
   - Profile creation
   - Interest selection

2. **Main Experience**:
   - Home feed
   - Club/organization discovery
   - Event discovery
   - Messaging
   - Profile viewing and editing

## Performance Optimization

1. **Image Optimization**:
   - Cached network images
   - Image resizing and quality adjustment

2. **UI Performance**:
   - Judicious use of const constructors
   - Minimized rebuilds
   - Flat widget hierarchies

3. **Lazy Loading**:
   - Data pagination
   - On-demand asset loading

## Current Development Status

HIVE is under active development, with the following areas of focus:

1. **Refactoring**: Breaking down large files into modular components
2. **Performance**: Optimizing UI rendering and data loading
3. **Features**: Implementing and refining core functionality
4. **Testing**: Building comprehensive test coverage

## Getting Involved

New developers can contribute by:

1. Following the coding standards in .cursorrules
2. Referring to the README.md for project structure
3. Helping with current refactoring efforts
4. Participating in code reviews

## Technical Decisions

### Why Flutter?
Flutter was chosen for its cross-platform capabilities, rich UI toolkit, and performance, allowing HIVE to deliver a premium experience across iOS and Android with a single codebase.

### Why Riverpod?
Riverpod provides a flexible, type-safe state management solution that integrates well with Flutter's widget system and enables efficient dependency injection.

### Why Clean Architecture?
The clean architecture approach ensures the codebase remains maintainable, testable, and adaptable to changing requirements as HIVE grows. 