# HIVE Clean Architecture Guide

## Overview

This guide outlines the clean architecture approach used in the HIVE application. HIVE follows a layered architecture that separates concerns and ensures a maintainable, testable codebase as the application grows.

## Architectural Layers

HIVE is divided into four main layers:

### 1. Presentation Layer

The presentation layer is responsible for rendering the UI and handling user interactions. It contains:

- **Pages**: Main screens of the application
- **Widgets**: Reusable UI components that are feature-specific
- **Components**: Standardized, reusable UI elements shared across features

The presentation layer:
- Uses standardized components from the component library
- Consumes state from the application layer
- Delegates user actions to the application layer
- Never directly accesses repositories or data sources

### 2. Application Layer

The application layer coordinates between the presentation and domain layers. It contains:

- **Providers**: State management using Riverpod
- **Controllers**: Business logic coordinators
- **State Models**: UI state representations

The application layer:
- Handles UI-related state management
- Orchestrates use cases from the domain layer
- Transforms domain models into presentation-ready data
- Captures and handles errors from the domain layer

### 3. Domain Layer

The domain layer contains the core business logic and entities. It includes:

- **Models**: Core business entities
- **Repositories (Interfaces)**: Contracts for data access
- **Use Cases**: Business logic operations

The domain layer:
- Is independent of UI and data sources
- Defines the core behavior of the application
- Contains business validation rules
- Is highly testable without UI or database dependencies

### 4. Data Layer

The data layer handles data access and persistence. It contains:

- **Repository Implementations**: Concrete implementations of domain repositories
- **Data Sources**: API clients, local storage, etc.
- **DTOs**: Data Transfer Objects for mapping to/from external sources

The data layer:
- Implements the repository interfaces defined in the domain layer
- Handles network requests and database operations
- Maps external data to domain models
- Handles data caching and persistence

## Flow of Control

1. UI events in the presentation layer trigger actions in the application layer
2. The application layer coordinates with the domain layer to execute business logic
3. The domain layer uses repositories to access data
4. The data layer fetches data and returns it to the domain layer
5. Results flow back up through the layers, with each layer transforming the data as needed
6. The presentation layer renders the updated UI based on the new state

## Implementation in HIVE Features

### User Profiles Feature

```
features/
  ├── profiles/
  │    ├── data/              
  │    │    ├── models/       # DTOs for profile data
  │    │    ├── repositories/ # Implementation of profile repos
  │    │    └── sources/      # API and local data sources
  │    │
  │    ├── domain/            
  │    │    ├── models/       # Core profile entities
  │    │    ├── repositories/ # Repository interfaces
  │    │    └── usecases/     # Profile business logic
  │    │
  │    └── presentation/      
  │         ├── screens/      # Profile screens
  │         ├── widgets/      # Profile-specific widgets
  │         └── providers/    # Profile state management
```

#### Domain Layer Example (User Profiles)

```dart
// features/profiles/domain/models/user_profile.dart
class UserProfile {
  final String id;
  final String username;
  final String major;
  final int year;
  final String residence;
  final List<String> interests;
  final VerificationTier verificationTier;
  
  const UserProfile({
    required this.id,
    required this.username,
    required this.major,
    required this.year,
    required this.residence,
    required this.interests,
    this.verificationTier = VerificationTier.public,
  });
}

// features/profiles/domain/repositories/profile_repository.dart
abstract class ProfileRepository {
  Future<UserProfile> getUserProfile(String userId);
  Future<void> updateUserProfile(UserProfile profile);
  Future<List<UserProfile>> searchProfiles({
    String? major,
    int? year,
    String? residence,
  });
}

// features/profiles/domain/usecases/update_profile_usecase.dart
class UpdateProfileUseCase {
  final ProfileRepository repository;
  
  UpdateProfileUseCase(this.repository);
  
  Future<void> execute(UserProfile profile) async {
    // Perform business validation
    if (profile.username.length < 3) {
      throw ValidationException('Username must be at least 3 characters');
    }
    
    // Execute the operation
    await repository.updateUserProfile(profile);
  }
}
```

#### Application Layer Example (User Profiles)

```dart
// features/profiles/presentation/providers/profile_state.dart
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

// features/profiles/presentation/providers/profile_provider.dart
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  final updateProfileUseCase = UpdateProfileUseCase(repository);
  return ProfileNotifier(repository, updateProfileUseCase);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final UpdateProfileUseCase _updateProfileUseCase;
  
  ProfileNotifier(this._repository, this._updateProfileUseCase) 
    : super(const ProfileState());
  
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getUserProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _updateProfileUseCase.execute(profile);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

#### Presentation Layer Example (User Profiles)

```dart
// features/profiles/presentation/screens/profile_page.dart
class ProfilePage extends ConsumerWidget {
  final String userId;
  
  const ProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Connect to application layer via provider
    final profileState = ref.watch(profileProvider);
    
    // Using standardized components from the component library
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: profileState.profile != null
                ? ProfileHeader(profile: profileState.profile!)
                : const ProfileHeaderSkeleton(),
          ),
          SliverToBoxAdapter(
            child: HiveCard(
              type: HiveCardType.profile,
              child: profileState.isLoading
                  ? const ProfileDetailsSkeleton()
                  : ProfileDetails(profile: profileState.profile!),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: HiveButton(
                text: 'Edit Profile',
                variant: HiveButtonVariant.primary,
                onPressed: profileState.isLoading
                    ? null
                    : () => _navigateToEditProfile(context, profileState.profile!),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToEditProfile(BuildContext context, UserProfile profile) {
    // Navigation logic
  }
}
```

### Clubs & Organizations Feature

```
features/
  ├── clubs/
  │    ├── data/              
  │    │    ├── models/       # DTOs for club data
  │    │    ├── repositories/ # Implementation of club repos
  │    │    └── sources/      # Club API and local data sources
  │    │
  │    ├── domain/            
  │    │    ├── models/       # Core club entities
  │    │    ├── repositories/ # Club repository interfaces
  │    │    └── usecases/     # Club business logic
  │    │
  │    └── presentation/      
  │         ├── screens/      # Club screens
  │         ├── widgets/      # Club-specific widgets
  │         └── providers/    # Club state management
```

### Events Feature

```
features/
  ├── events/
  │    ├── data/              
  │    │    ├── models/       # DTOs for event data
  │    │    ├── repositories/ # Implementation of event repos
  │    │    └── sources/      # Event API and local data sources
  │    │
  │    ├── domain/            
  │    │    ├── models/       # Core event entities
  │    │    ├── repositories/ # Event repository interfaces
  │    │    └── usecases/     # Event business logic
  │    │
  │    └── presentation/      
  │         ├── screens/      # Event screens
  │         ├── widgets/      # Event-specific widgets
  │         └── providers/    # Event state management
```

## Using Standardized Components with Clean Architecture

Our standardized component library supports clean architecture by:

1. **Keeping UI Logic in the Presentation Layer**
   - Components handle only UI concerns (rendering, animation, interaction)
   - They don't contain business logic or data fetching

2. **Receiving Data via Parameters**
   - Components accept data through parameters, not by accessing repositories directly
   - This maintains separation between presentation and data layers

3. **Emitting Events through Callbacks**
   - Components use callbacks to communicate user actions
   - Business logic is handled in the application/domain layers, not in components

Example of proper integration:

```dart
// GOOD: Clean separation of concerns
HiveCard(
  type: HiveCardType.event,
  child: EventContent(event: event),
  onPressed: () => ref.read(eventProvider.notifier).viewEventDetails(event.id),
)

// BAD: Component directly fetches data or contains business logic
HiveCard(
  type: HiveCardType.event,
  child: FutureBuilder(
    future: APIClient().fetchEventDetails(eventId),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return EventContent(event: snapshot.data!);
      }
      return const CircularProgressIndicator();
    },
  ),
)
```

## Testing Strategy by Layer

### Presentation Layer
- **Widget tests**: Test UI components in isolation
- **Golden tests**: Verify visual appearance of components
- **Integration tests**: Test user flows through the UI

### Application Layer
- **Unit tests**: Test state management logic
- **Integration tests**: Verify interaction between providers and domain layer

### Domain Layer
- **Unit tests**: Test business logic in isolation
- **Property-based tests**: Verify business rules hold across various inputs

### Data Layer
- **Unit tests**: Test mapping logic and repository implementations
- **Integration tests**: Test interactions with external APIs or databases
- **Mock tests**: Verify error handling and edge cases

## Conclusion

Following clean architecture principles allows HIVE to:

1. **Scale efficiently** as new features are added
2. **Replace implementations** without affecting other layers
3. **Test components in isolation** without complex setup
4. **Maintain separation of concerns** for easier debugging and maintenance

As you continue refactoring and implementing new features, use this guide to ensure proper architectural boundaries are maintained across the codebase. 