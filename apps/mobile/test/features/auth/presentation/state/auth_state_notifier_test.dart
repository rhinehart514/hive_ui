import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/auth_service.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/entities/auth_challenge.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/features/auth/presentation/state/auth_state_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks
import 'auth_state_notifier_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  late MockAuthService mockAuthService;
  late AuthStateNotifier authStateNotifier;
  late List<AuthState> states;

  setUp(() {
    // This initial setUp is now redundant due to redefinition below
    // mockAuthService = MockAuthService();
    // authStateNotifier = AuthStateNotifier(mockAuthService);
    // states = []; // Initialize the list for each test
    // listener = Listener<AuthState>();
    // // Add listener
    // authStateNotifier.addListener(listener, fireImmediately: true); // Remove
  });

  tearDown(() {
    // authStateNotifier.removeListener(listener); // Remove
    // authStateNotifier might be null if the second setup fails, handle disposal carefully
    // Or just rely on test runner tearing down state?
    // Let's keep dispose for now, assuming the second setup runs.
    authStateNotifier.dispose(); 
  });

  group('AuthStateNotifier Tests', () {
    const testEmail = 'test@example.com';
    const testToken = 'magic-token-123';
    const testUserId = 'user-id-456';
    final testChallenge = AuthChallenge.create(testEmail); // Assuming AuthChallenge.create is usable
    const testFailure = ServerFailure('Auth Service Error');

    // Redefine listener setup to capture states
    setUp(() {
       mockAuthService = MockAuthService();
       authStateNotifier = AuthStateNotifier(mockAuthService);
       states = []; // Reset states list for each test
       // Add listener directly to the list
       authStateNotifier.addListener((state) {
         states.add(state);
       }, fireImmediately: false); 
    });


    test('initial state is unauthenticated', () {
      // Access state directly via debugState, no listener verification needed here
      expect(authStateNotifier.debugState.status, AuthStatus.unauthenticated);
      expect(authStateNotifier.debugState.userId, isNull);
      expect(authStateNotifier.debugState.error, isNull);
    });

    group('requestMagicLink', () {
      test('should transition to authenticating, then pendingVerification on success', () async {
        // Arrange
        when(mockAuthService.requestMagicLink(testEmail))
            .thenAnswer((_) async => const Result.right(testEmail));
        when(mockAuthService.createAuthChallenge(testEmail))
            .thenReturn(testChallenge);
        
        // Act
        await authStateNotifier.requestMagicLink(testEmail);
        
        // Assert
        expect(states.length, 2);
        // State 1: Authenticating
        expect(states[0].status, AuthStatus.authenticating);
        expect(states[0].email, testEmail);
        // State 2: PendingVerification
        expect(states[1].status, AuthStatus.pendingVerification);
        expect(states[1].email, testEmail);
        expect(states[1].challenge, testChallenge);
        expect(states[1].error, isNull);
        verify(mockAuthService.requestMagicLink(testEmail)).called(1);
        verify(mockAuthService.createAuthChallenge(testEmail)).called(1);
      });

      test('should transition to authenticating, then error on failure', () async {
        // Arrange
        when(mockAuthService.requestMagicLink(testEmail))
            .thenAnswer((_) async => const Result.left(testFailure));
        
        // Act
        await authStateNotifier.requestMagicLink(testEmail);
        
        // Assert
        expect(states.length, 2);
        // State 1: Authenticating
        expect(states[0].status, AuthStatus.authenticating);
        expect(states[0].email, testEmail);
        // State 2: Error
        expect(states[1].status, AuthStatus.error);
        expect(states[1].email, testEmail);
        expect(states[1].error, testFailure);
        verify(mockAuthService.requestMagicLink(testEmail)).called(1);
         verifyNever(mockAuthService.createAuthChallenge(any));
      });
    });

    group('verifyMagicLink', () {
      test('should transition to authenticating, then authenticated on success', () async {
        // Arrange
        when(mockAuthService.verifyMagicLink(testToken))
            .thenAnswer((_) async => const Result.right(testUserId));
        
        // Act
        await authStateNotifier.verifyMagicLink(testToken);
        
        // Assert
        expect(states.length, 2);
        // State 1: Authenticating
        expect(states[0].status, AuthStatus.authenticating);
        // State 2: Authenticated
        expect(states[1].status, AuthStatus.authenticated);
        expect(states[1].userId, testUserId);
        expect(states[1].error, isNull);
        verify(mockAuthService.verifyMagicLink(testToken)).called(1);
      });

      test('should transition to authenticating, then error on failure', () async {
        // Arrange
        when(mockAuthService.verifyMagicLink(testToken))
            .thenAnswer((_) async => const Result.left(testFailure));
        
        // Act
        await authStateNotifier.verifyMagicLink(testToken);
        
        // Assert
        expect(states.length, 2);
        // State 1: Authenticating
        expect(states[0].status, AuthStatus.authenticating);
        // State 2: Error
        expect(states[1].status, AuthStatus.error);
        expect(states[1].error, testFailure);
        verify(mockAuthService.verifyMagicLink(testToken)).called(1);
      });
    });

    group('signOut', () {
      test('should transition to authenticating, then initial state on success', () async {
        // Arrange: Set initial state to authenticated for sign out test
        authStateNotifier.state = const AuthState(status: AuthStatus.authenticated, userId: testUserId);
        states.clear(); // Clear initial state set by setup

        when(mockAuthService.signOut())
            .thenAnswer((_) async => const Result.right(null));
        
        // Act
        await authStateNotifier.signOut();
        
        // Assert
        expect(states.length, 2);
        // State 1: Authenticating
        expect(states[0].status, AuthStatus.authenticating);
        // State 2: Initial (Unauthenticated)
        expect(states[1].status, AuthStatus.unauthenticated);
        expect(states[1].userId, isNull);
        expect(states[1].email, isNull);
        expect(states[1].challenge, isNull);
        expect(states[1].error, isNull);
        verify(mockAuthService.signOut()).called(1);
      });

      test('should transition to authenticating, then error on failure', () async {
        // Arrange: Set initial state to authenticated
        authStateNotifier.state = const AuthState(status: AuthStatus.authenticated, userId: testUserId);
        states.clear();

        when(mockAuthService.signOut())
            .thenAnswer((_) async => const Result.left(testFailure));
        
        // Act
        await authStateNotifier.signOut();
        
        // Assert
        expect(states.length, 2);
        // State 1: Authenticating
        expect(states[0].status, AuthStatus.authenticating);
        // State 2: Error (state before error is preserved, error added)
        expect(states[1].status, AuthStatus.error);
        expect(states[1].userId, testUserId); // User ID should still be there
        expect(states[1].error, testFailure);
        verify(mockAuthService.signOut()).called(1);
      });
    });

    group('clearError', () {
      test('should transition to unauthenticated and clear error', () {
        // Arrange: Set initial state to error
        authStateNotifier.state = const AuthState(status: AuthStatus.error, error: testFailure);
        states.clear();

        // Act
        authStateNotifier.clearError();

        // Assert
        expect(states.length, 1);
        expect(states[0].status, AuthStatus.unauthenticated);
        expect(states[0].error, isNull);
      });
    });
  });
}

// Remove Listener class
// class Listener<T> extends Mock {
//   void call(T? previous, T next);
// } 