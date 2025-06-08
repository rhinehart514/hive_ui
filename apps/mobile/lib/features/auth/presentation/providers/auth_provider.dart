import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:hive_ui/features/auth/providers/new_onboarding_providers.dart' hide firebaseAuthProvider;

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuthInstance = ref.watch(firebaseAuthProvider);
  final firestoreInstance = ref.watch(firestoreProvider);
  return FirebaseAuthRepository(
    firebaseAuth: firebaseAuthInstance,
    firestore: firestoreInstance,
  );
}); 