import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

/// Authentication status enum
enum AuthStatus {
  /// Initial state
  initial,
  
  /// Loading state during authentication operations
  loading,
  
  /// User is authenticated
  authenticated,
  
  /// User is not authenticated
  unauthenticated,
  
  /// Authentication error
  error,
}

/// State class for authentication
class AuthState {
  /// Current authentication status
  final AuthStatus status;
  
  /// Current authenticated user (or empty if not authenticated)
  final AuthUser user;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Constructor
  const AuthState({
    this.status = AuthStatus.initial,
    required this.user,
    this.errorMessage,
  });
  
  /// Default constructor with empty user
  factory AuthState.initial() => AuthState(
    status: AuthStatus.initial,
    user: AuthUser.empty(),
  );
  
  /// Create a copy with modified fields
  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for auth controller
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});

/// Auth controller class
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  
  /// Constructor
  AuthController(this._authRepository) : super(AuthState.initial());
  
  /// Signs in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _authRepository.signInWithEmailPassword(email, password);
      
      if (user.id.isNotEmpty) {
        // Successfully signed in
        state = state.copyWith(
          user: user,
          status: AuthStatus.authenticated,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Authentication failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Registers a new user with email and password
  Future<void> registerWithEmailPassword(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _authRepository.createUserWithEmailPassword(email, password);
      
      if (user.id.isNotEmpty) {
        // Successfully registered
        state = state.copyWith(
          user: user,
          status: AuthStatus.authenticated,
        );
        
        // Mark user as needing onboarding
        await UserPreferencesService.resetOnboardingStatus();
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Registration failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
} 