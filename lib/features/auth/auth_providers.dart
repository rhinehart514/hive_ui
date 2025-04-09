import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Stream provider for the current user
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Provider to check if a user is signed in
final isUserSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
}); 