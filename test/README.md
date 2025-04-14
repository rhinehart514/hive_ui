# HIVE UI Testing Guide

This directory contains tests for the HIVE UI application. Follow these guidelines when creating new tests.

## Test Structure

Tests are organized to mirror the application structure:

```
test/
├── core/                 # Tests for core utilities and helpers
├── features/             # Tests for feature modules (matching lib/features structure)
│   ├── auth/             # Auth feature tests
│   ├── events/           # Events feature tests
│   ├── feed/             # Feed feature tests
│   └── ...               # Other feature tests
├── mocks/                # Shared mock objects and helpers
├── services/             # Tests for application services
└── widgets/              # Widget tests for shared components
```

## Test Types

### 1. Unit Tests

Unit tests verify individual classes and functions work correctly in isolation.

- **Repository Tests**: Test repository interfaces with mocked data sources
- **UseCase Tests**: Test domain use cases with mocked repositories
- **Provider Tests**: Test provider logic with mocked dependencies

Example: [test/features/test_mockito_example.dart](features/test_mockito_example.dart)

### 2. Widget Tests

Widget tests verify UI components render correctly and respond to user interactions.

- Test widgets with stubbed callbacks
- Verify text and UI elements are displayed
- Test widget interactions (taps, scrolls, etc.)

### 3. Integration Tests

Integration tests verify that multiple components work together correctly.

- Test complete user flows (e.g., sign up, create event, RSVP)
- Use real or fake repositories instead of mocks
- Run in a simulated environment

## Testing Approach

### Using Mocks

We use Mockito for creating test doubles. There are two approaches:

#### 1. Manual Mocks

For simple cases, create a manual mock class:

```dart
class MockCounterRepository extends Mock implements CounterRepository {}
```

#### 2. Generated Mocks (Recommended)

For complex classes, use generated mocks:

1. Add the `@GenerateMocks` annotation:

```dart
@GenerateMocks([CounterRepository])
void main() {
  // Test code
}
```

2. Run the build_runner to generate mocks:

```bash
flutter pub run build_runner build
```

#### 3. Fake Implementations

If you encounter issues with Mockito and build_runner, consider using fake implementations instead:

```dart
// Instead of a mock
class FakeAuthRepository implements AuthRepository {
  User? _currentUser;
  
  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }
  
  @override
  Future<User?> login(String email, String password) async {
    // Implement test behavior
  }
}
```

See [test/features/test_without_mocks.dart](features/test_without_mocks.dart) for a complete example.

### Troubleshooting Mock Generation

If you encounter issues with build_runner:

1. **Syntax Errors**: Ensure there are no syntax errors in the tested interfaces.
2. **Invalid UTF-8**: Some files may contain invalid characters. Use `--delete-conflicting-outputs` flag.
3. **Alternative Approach**: Use manual mocks or fake implementations if generation issues persist.

```bash
# Try with delete-conflicting-outputs flag
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing Guidelines

1. **Follow AAA Pattern**: Arrange, Act, Assert
   ```dart
   // Arrange
   when(mockRepository.getCount()).thenAnswer((_) async => 42);
   
   // Act
   final result = await service.getCurrentCount();
   
   // Assert
   expect(result, equals(42));
   ```

2. **Use Descriptive Test Names**: Describe what's being tested and expected outcome
   ```dart
   test('incrementAndGet increases count and returns new value', () async {
     // Test code
   });
   ```

3. **Group Related Tests**: Use `group()` to organize related tests
   ```dart
   group('CounterService', () {
     test('getCurrentCount returns current count', () async {/* */});
     test('incrementAndGet increases count', () async {/* */});
   });
   ```

4. **Setup in setUp()**: Common setup code should be in the `setUp()` function
   ```dart
   setUp(() {
     mockRepository = MockCounterRepository();
     service = CounterService(mockRepository);
   });
   ```

5. **Verify Mock Interactions**: Check that mocks were called correctly
   ```dart
   verify(mockRepository.getCount()).called(1);
   ```

## Continuous Integration

Tests run automatically on pull requests through GitHub Actions. The workflow is configured in `.github/workflows/flutter-test.yml`.

To run tests locally:

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/features/events/domain/repositories/event_repository_test.dart

# Run tests with coverage
flutter test --coverage
```

## Examples

For examples of how to structure tests, see:

- [test/features/test_setup_example.dart](features/test_setup_example.dart) - Basic test with real implementation
- [test/features/test_mockito_example.dart](features/test_mockito_example.dart) - Tests using Mockito mocks
- [test/features/test_without_mocks.dart](features/test_without_mocks.dart) - Testing without using build_runner
- [test/features/events/test_helpers.dart](features/events/test_helpers.dart) - Helper functions for creating test objects

## Test Object Creation

### Factory Methods

For complex models with many required fields, use factory methods to simplify test object creation:

```dart
// Example from test_helpers.dart
TestEventFactory.createTestEvent(
  id: 'event-123',
  title: 'Custom Title',
  // Other fields use default values
);
```

This approach:
1. Reduces test code duplication
2. Makes tests more readable
3. Centralizes changes to model structure
4. Provides sensible defaults for all required fields

### Test Data Sets

For tests requiring specific data scenarios:

```dart
// Create multiple test events
final testEvents = TestEventFactory.createTestEventList(count: 5);

// Create a mock pagination response
final mockResponse = TestEventFactory.createEventPaginationResponse(
  events: testEvents,
  hasMore: true,
  total: 20,
);
```

## Running the Tests

The tests are set up to run in the GitHub Actions CI pipeline, but you can also run them locally:

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/features/test_without_mocks.dart

# Run tests with coverage
flutter test --coverage
flutter pub run test_coverage
``` 