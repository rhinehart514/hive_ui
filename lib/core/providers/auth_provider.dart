import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The authentication state that can be used throughout the app
sealed class AuthState {
  const AuthState();
}

/// The user is authenticated
class AuthStateAuthenticated extends AuthState {
  final User user;
  
  const AuthStateAuthenticated(this.user);
}

/// The user is not authenticated
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// The authentication state is being determined
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// The authentication process encountered an error
class AuthStateError extends AuthState {
  final Object error;
  final StackTrace stackTrace;
  
  const AuthStateError(this.error, this.stackTrace);
}

/// Provider that exposes the FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider that exposes the current authentication state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  
  return auth.authStateChanges().map((user) {
    if (user != null) {
      return AuthStateAuthenticated(user);
    } else {
      return const AuthStateUnauthenticated();
    }
  });
});

/// Provider that exposes the current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).when(
    data: (state) => state is AuthStateAuthenticated ? state.user : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider that simplifies access to the current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
}); 