import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
}); 