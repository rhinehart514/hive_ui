# HIVE UI Technical Architecture Guide

## 1. Introduction

### 1.1 Purpose
This document outlines the technical architecture, standards, and best practices for developing the HIVE Flutter application. Its goal is to ensure consistency, maintainability, scalability, and high performance across the codebase, facilitating collaboration between developers and AI agents.

### 1.2 Guiding Principles
- **Behavioral Alignment**: Architecture choices must support the core behavioral patterns defined in the HIVE business logic.
- **Clean Architecture**: Maintain a clear separation of concerns between data, domain (business logic), and presentation (UI) layers.
- **Modularity**: Features should be developed as self-contained modules where possible.
- **Testability**: Code should be structured to facilitate unit, widget, and integration testing.
- **Performance**: Prioritize efficient state management, rendering, and data fetching.
- **Readability & Maintainability**: Follow consistent coding styles and documentation practices.

## 2. Core Architectural Pattern: Clean Architecture

HIVE adopts the principles of Clean Architecture to separate concerns and promote modularity. The primary layers are:

- **Data Layer**: Responsible for data retrieval and storage (APIs, local database, device storage). Includes repositories and data sources.
- **Domain Layer**: Contains the core business logic, use cases (interactors), and entities (models). This layer is independent of UI and data fetching details.
- **Presentation Layer**: Handles UI rendering and user interaction. Includes widgets/screens, controllers/notifiers, and UI-specific state management.

### 2.1 Feature Module Structure
Each major feature resides within the `lib/features/` directory and follows this internal structure:

```
lib/features/
  ├── feature_name/
  │   ├── data/
  │   │   ├── repositories/     # Implementations of domain repositories
  │   │   ├── datasources/      # Firebase/API/local data interactions
  │   │   └── models/           # Data Transfer Objects (DTOs) specific to data sources
  │   ├── domain/
  │   │   ├── repositories/     # Abstract repository interfaces
  │   │   ├── usecases/         # Business logic operations
  │   │   └── entities/         # Core business objects (shared models often live in lib/models)
  │   └── presentation/
  │       ├── controllers/      # StateNotifiers or other state management logic
  │       ├── screens/          # Top-level page widgets
  │       ├── widgets/          # Reusable UI components specific to the feature
  │       └── providers.dart    # Riverpod providers specific to this feature
  └── ...
```

### 2.2 Core/Shared Modules
Common functionalities, models, utilities, and UI components used across multiple features reside in top-level directories like:
- `lib/core/`: Fundamental services, error handling, platform abstractions.
- `lib/models/`: Shared domain entities used across features.
- `lib/providers/`: Global or cross-cutting Riverpod providers.
- `lib/widgets/` or `lib/components/`: Globally reusable UI widgets.
- `lib/theme/`: App theme, colors, text styles.
- `lib/utils/`: Common utility functions.
- `lib/constants/`: Application constants.
- `lib/routes/`: Navigation configuration.

## 3. State Management: Riverpod

Riverpod is the primary state management solution.

### 3.1 Provider Types Usage
- **`Provider`**: For dependency injection of services (repositories, API clients) that don't have mutable state.
- **`StateProvider`**: For simple, ephemeral UI state (e.g., toggle states, form input values) that doesn't require complex logic. Use sparingly.
- **`StateNotifierProvider`**: For managing complex state with associated business logic. This is the preferred choice for feature controllers/managers in the presentation layer. State should be immutable.
- **`FutureProvider`**: For simple, one-off asynchronous data fetching where caching and updates aren't complex.
- **`StreamProvider`**: For subscribing to real-time data streams (e.g., Firestore streams).

### 3.2 Provider Scope and Location
- **Global Providers**: Defined in `lib/providers/` for app-wide services (e.g., `firebaseAuthProvider`, `firestoreProvider`).
- **Feature Providers**: Defined within the feature's `presentation/providers.dart` file.
- **Widget-Scoped Providers**: Use `Consumer` or `HookConsumerWidget` to access providers. Avoid declaring providers directly inside build methods.

### 3.3 Immutability
- State managed by `StateNotifierProvider` **must** be immutable.
- Use packages like `freezed` to generate immutable state classes with `copyWith` methods.
- Update state by creating a new instance: `state = state.copyWith(...)`.

### 3.4 Async Operations in Notifiers
- Handle loading and error states explicitly within `StateNotifier`s.
- Define clear state classes/enums (e.g., `Loading`, `Loaded`, `Error`).
- Avoid holding `BuildContext` within Notifiers.

## 4. API Communication & Data Layer

### 4.1 Repository Pattern
- **Abstraction**: Define abstract `Repository` interfaces in the `domain/repositories` directory.
- **Implementation**: Implement these interfaces in the `data/repositories` directory, injecting `DataSource` dependencies.
- **Dependency Injection**: Use Riverpod's `Provider` to provide repository implementations to the domain/presentation layers.

### 4.2 Data Sources
- Encapsulate interactions with specific data sources (Firebase Firestore, Firebase Storage, potential REST APIs).
- Reside in `data/datasources`.
- Handle data serialization/deserialization (mapping between domain entities and data source models/DTOs).

### 4.3 Firebase Interaction (Firestore)
- **Service Layer**: Consider a thin service layer (`lib/services/`) or direct use within data sources for Firestore interactions.
- **Queries**: Encapsulate complex Firestore queries within data sources.
- **Error Handling**: Catch Firebase-specific exceptions (`FirebaseException`) in the data layer and map them to domain-specific errors.
- **Security Rules**: Data access logic must align with Firestore security rules (see Section 9).

### 4.4 Error Handling (Data Layer)
- Define custom exception/failure classes in the `domain` or `core` layer (e.g., `ServerFailure`, `CacheFailure`, `NetworkFailure`).
- Data sources and repositories should catch specific exceptions (e.g., `FirebaseException`, `DioError`, `SocketException`) and return standardized `Failure` objects (often using `Either` from `fpdart` or `dartz`).

### 4.5 Offline Strategy (Placeholder - Needs Definition 📊)
- **Goal**: Provide a seamless experience even with intermittent connectivity.
- **Approach (Needs Verification)**: Likely involves a combination of:
    - **Client-Side Caching**: Using local databases (Hive, Drift) or simple file storage to cache frequently accessed data.
    - **Optimistic Updates**: Updating UI immediately for certain actions (e.g., RSVP, Drop) and syncing with backend later.
    - **Synchronization Queue**: Managing pending writes when offline and syncing upon reconnection.
    - **Conflict Resolution Strategy**: Defining how to handle data conflicts during synchronization.
> **AI Verification Point**: What level of offline support is required for V1? Which specific data/actions need offline capability? What caching and sync strategy is preferred?

## 5. Navigation: GoRouter

`go_router` is used for declarative routing.

### 5.1 Configuration
- **Routes Definition**: Define all route paths and names as constants in `lib/routes/app_routes.dart`.
- **Router Setup**: Configure `GoRouter` instance in `lib/routes/app_router.dart`, including:
    - Initial route.
    - Top-level routes.
    - `ShellRoute` for persistent UI (like the bottom navigation bar).
    - Error handling (e.g., 404 page).
    - Redirects (e.g., for authentication).
    - Transition animations.
- **Provider**: Provide the configured `GoRouter` instance via a Riverpod `Provider`.

### 5.2 Navigation Practices
- **Type-Safe Navigation**: Use generated routes (if using `go_router_builder`) or constants for navigating.
- **Parameter Passing**: Pass parameters through route definitions, not global state where avoidable.
- **Context**: Use `context.go()`, `context.push()`, etc., ensuring `BuildContext` is available (see Async Safety).
- **Deep Linking**: Configure `GoRouter` to handle deep links.

## 6. Error Handling (Application-Wide)

### 6.1 Error Types
- **Domain Failures**: As mentioned in Section 4.4 (e.g., `ServerFailure`). Returned by repositories/use cases.
- **UI Exceptions**: Unexpected errors during widget building or interaction.
- **Platform Exceptions**: Errors from native platform channels.

### 6.2 Reporting
- **Crash Reporting**: Integrate Firebase Crashlytics (or similar) to report unhandled exceptions and crashes.
- **Error Logging**: Implement structured logging (e.g., using the `logging` package) to capture errors with context.
- **Non-Fatal Reporting**: Report handled errors (e.g., API failures) to Crashlytics as non-fatal issues for monitoring.

### 6.3 UI Display
- **Graceful Handling**: Catch errors at appropriate boundaries (e.g., in `StateNotifier`s, `FutureBuilder`s, `StreamBuilder`s).
- **User-Friendly Messages**: Display clear, concise error messages to the user. Avoid showing technical details.
- **Standard Error Widgets**: Create reusable widgets for displaying common error states (e.g., inline error message, full-screen error page with retry).
- **Snackbars/Toasts**: Use for transient, non-critical errors.

## 7. Testing

### 7.1 Unit Tests
- **Scope**: Test individual functions, methods, and classes in isolation.
- **Targets**: Domain layer (use cases, entities), Data layer (repositories, data sources - with mocked dependencies), Presentation layer (controllers/notifiers).
- **Tools**: `flutter_test`, `mockito` (or `mocktail`).
- **Coverage Goal (Needs Verification 🧪)**: Aim for high coverage (>80%) in the domain layer.

### 7.2 Widget Tests
- **Scope**: Test individual widgets or small groups of widgets.
- **Targets**: Verify UI rendering, interaction, and state changes for specific widgets.
- **Tools**: `flutter_test`.
- **Coverage Goal (Needs Verification 🧪)**: Focus on critical UI components and widgets with complex logic.

### 7.3 Integration Tests
- **Scope**: Test complete features or user flows across multiple layers.
- **Targets**: Verify interactions between UI, state management, and data layers (using mocked backends where appropriate).
- **Tools**: `flutter_test`, `integration_test`.
- **Coverage Goal (Needs Verification 🧪)**: Cover critical user paths (authentication, core loop actions).

### 7.4 Testing Infrastructure
- **Mocking**: Consistently use `mockito` or `mocktail` for mocking dependencies.
- **Fixtures**: Use realistic test data fixtures.
- **CI Integration**: Integrate all test types into the CI pipeline (see Section 10).

## 8. Coding Style & Formatting

- **Effective Dart**: Adhere to the principles outlined in Effective Dart ([https://dart.dev/guides/language/effective-dart](https://dart.dev/guides/language/effective-dart)).
- **Flutter Lints**: Enable and follow recommended Flutter lints (`flutter_lints` package).
- **Formatting**: Use `dart format` consistently. Configure IDEs to format on save.
- **Naming Conventions**: Follow standard Dart naming conventions (PascalCase for classes/types, camelCase for variables/functions, snake_case for files/directories).
- **Documentation**: Write clear dartdoc comments (`///`) for all public APIs (classes, methods, functions). Add implementation comments (`//`) for complex logic.
- **File Structure**: Adhere to the feature module structure (Section 2.1).
- **Line Length**: Aim for a maximum line length of 80-100 characters where practical.

## 9. Security Considerations

- **Input Validation**: Perform validation on user inputs both client-side and server-side (via Firestore Rules).
- **Secrets Management**: Do not commit API keys, credentials, or other secrets directly into the codebase. Use environment variables or a secrets management solution.
- **Secure Dependencies**: Regularly scan dependencies for vulnerabilities (Section 10.3).
- **Firestore Rules**: Implement robust Firestore security rules to prevent unauthorized data access and manipulation.
- **Authentication**: Securely handle authentication tokens and sessions.

## 10. Build & Deployment (CI/CD)

### 10.1 Continuous Integration (CI)
- **Triggers**: Run CI pipeline on every commit/push to main branches and on pull requests.
- **Pipeline Steps**:
    - Checkout code
    - Install dependencies (`flutter pub get`)
    - Run code analysis (`flutter analyze`)
    - Run formatter check (`dart format --output=none --set-exit-if-changed .`)
    - Run unit and widget tests (`flutter test`)
    - (Optional) Build app bundles/APKs.

### 10.2 Continuous Deployment (CD)
- **Environments**: Maintain separate configurations for `development`, `staging`, and `production`.
- **Staging Deployment**: Automatically deploy successful builds from a specific branch (e.g., `develop` or `release/*`) to a staging environment (Firebase App Distribution, TestFlight).
- **Production Deployment**: Trigger production deployment manually (or automatically from `main` branch after approval) to App Store Connect and Google Play Console.
- **Versioning**: Implement a clear versioning strategy (e.g., SemVer) and manage build numbers automatically.

## 11. Conclusion

This guide provides the foundation for building a high-quality, maintainable, and scalable HIVE application. Adherence to these principles and patterns will facilitate efficient development and collaboration. This document should be considered living and updated as the application evolves and new technical challenges arise. 