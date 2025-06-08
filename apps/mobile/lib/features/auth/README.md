# HIVE Authentication Module

This module handles all authentication-related functionality for the HIVE app, following clean architecture principles with separation of data, domain, and presentation layers.

## Optimization Guidelines

### Firebase Billing Optimizations

1. **User Data Caching**
   - The auth repository implements user caching to reduce unnecessary Firebase Auth calls
   - The cache is invalidated on auth state changes or after a configurable duration
   - Always use the repository methods instead of direct Firebase calls to benefit from caching

2. **Minimal Firestore Operations**
   - We use a "fire-and-forget" approach for non-critical profile updates
   - Login operations only update the login timestamp, not the entire profile
   - Profile creation is more thorough but has timeouts to prevent blocking the UI

3. **Reduced Network Traffic**
   - Firebase connections are minimized by batching operations
   - Auth state is cached locally to prevent redundant network requests
   - Optimistic UI updates are used to improve perceived performance

4. **Error Recovery**
   - Implemented graceful fallbacks to local storage when Firebase operations fail
   - Platform-specific handling for Windows which has known Firebase plugin issues
   - Appropriate error message mapping for better user experience

## Component Structure

1. **Data Layer**
   - `AuthRepository` interface defines auth operations contract
   - `FirebaseAuthRepository` implements Firebase-specific authentication
   - `MockAuthRepository` provides testing capabilities

2. **Domain Layer**
   - `AuthUser` entity encapsulates user data for domain logic
   - Use cases/services implement business logic

3. **Presentation Layer**
   - Components: Reusable UI elements (forms, buttons, modals)
   - Pages: Full screen auth interfaces
   - Controllers: Handle UI state and user interactions

## Best Practices

1. **Prefer AuthController Over Direct Repository Access**
   - The `authControllerProvider` handles loading states and error management
   - Always use this provider in the UI rather than calling repository methods directly

2. **Offline First**
   - Auth data is persisted locally for offline functionality
   - Account for network latency in auth flows (e.g., redirects after login)

3. **Security**
   - Never store sensitive auth data in local storage
   - Validate email and passwords on client side before making auth requests
   - Implement proper error handling for auth failures

4. **Code Organization**
   - Keep files under 300 lines
   - Extract reusable components
   - Follow naming conventions (snake_case for files, PascalCase for classes)

## Performance Tips

1. Use `FieldValue.serverTimestamp()` for consistent timestamps
2. Keep Firestore documents small with only essential fields
3. Implement proper cache invalidation to ensure data freshness
4. Use the cache-first approach when possible

## Testing Authentication

1. Use `MockAuthRepository` for unit and widget tests
2. Test both success and failure scenarios
3. Verify proper loading states during authentication processes

## Auth Flow UX Guidelines

1. Provide haptic feedback for important auth events
2. Show clear, user-friendly error messages (already mapped in the repository)
3. Minimize redirection delays after successful authentication
4. Always indicate loading states during auth operations 