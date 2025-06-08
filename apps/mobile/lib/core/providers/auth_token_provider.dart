import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/auth/auth_token_manager.dart';

/// Provider for the AuthTokenManager
final authTokenManagerProvider = Provider<AuthTokenManager>((ref) {
  final manager = AuthTokenManager();
  
  // Initialize the manager when the provider is first accessed
  manager.initialize();
  
  // Make sure to dispose of resources when no longer needed
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});

/// Stream provider for authentication state changes
final authStateStreamProvider = StreamProvider<bool>((ref) {
  final manager = ref.watch(authTokenManagerProvider);
  return manager.authStateChanges;
});

/// Provider for the current access token
final accessTokenProvider = FutureProvider<String?>((ref) {
  final manager = ref.watch(authTokenManagerProvider);
  return manager.getAccessToken();
});

/// Provider for the current user ID
final tokenUserIdProvider = FutureProvider<String?>((ref) {
  final manager = ref.watch(authTokenManagerProvider);
  return manager.getUserId();
});

/// Action provider to reset the session timer
final resetSessionTimerProvider = Provider<void Function()>((ref) {
  final manager = ref.watch(authTokenManagerProvider);
  return () => manager.resetSessionTimer();
}); 