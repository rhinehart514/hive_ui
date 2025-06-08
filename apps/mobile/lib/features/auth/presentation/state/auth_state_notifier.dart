import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/application/services/auth_service.dart';
import 'package:hive_ui/domain/entities/auth_challenge.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// The possible states of the authentication process.
enum AuthStatus {
  /// The user is not authenticated.
  unauthenticated,
  
  /// The user is in the process of authenticating.
  authenticating,
  
  /// The user has successfully authenticated.
  authenticated,
  
  /// The user has an auth challenge (magic link) pending verification.
  pendingVerification,
  
  /// The user has encountered an error during authentication.
  error,
}

/// The state for the authentication process.
class AuthState {
  /// The current status of the authentication process.
  final AuthStatus status;
  
  /// The ID of the authenticated user, if any.
  final String? userId;
  
  /// The email of the user in the authentication process.
  final String? email;
  
  /// The current auth challenge, if any.
  final AuthChallenge? challenge;
  
  /// The error that occurred during authentication, if any.
  final Failure? error;

  /// Creates a new authentication state.
  const AuthState({
    required this.status,
    this.userId,
    this.email,
    this.challenge,
    this.error,
  });

  /// The initial state for the authentication process.
  factory AuthState.initial() {
    return const AuthState(
      status: AuthStatus.unauthenticated,
    );
  }

  /// Creates a copy of this state with the given fields replaced.
  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    AuthChallenge? challenge,
    Failure? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      challenge: challenge ?? this.challenge,
      error: error ?? this.error,
    );
  }
}

/// Manages the authentication state and provides methods to interact with it.
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  /// Creates a new auth state notifier with the given dependencies.
  AuthStateNotifier(this._authService) : super(AuthState.initial());

  /// Requests a magic link to be sent to the provided email.
  Future<void> requestMagicLink(String email) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      email: email,
    );

    final result = await _authService.requestMagicLink(email);
    
    result.fold(
      onSuccess: (email) {
        // Create an auth challenge for the email
        final challenge = _authService.createAuthChallenge(email);
        
        state = state.copyWith(
          status: AuthStatus.pendingVerification,
          challenge: challenge,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          error: failure,
        );
      },
    );
  }

  /// Verifies a magic link token and signs the user in.
  Future<void> verifyMagicLink(String token) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
    );

    final result = await _authService.verifyMagicLink(token);
    
    result.fold(
      onSuccess: (userId) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userId: userId,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          error: failure,
        );
      },
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
    );

    final result = await _authService.signOut();
    
    result.fold(
      onSuccess: (_) {
        state = AuthState.initial();
      },
      onFailure: (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          error: failure,
        );
      },
    );
  }

  /// Clears any errors in the current state.
  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: null,
    );
  }
} 