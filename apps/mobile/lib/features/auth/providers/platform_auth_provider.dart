import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:hive_ui/features/auth/data/repositories/windows_auth_repository.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';

/// Provider for the platform-specific auth repository
/// This automatically selects between Firebase and Windows implementations
final platformAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  // Check if we're on Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
    debugPrint('Using Windows-specific auth repository');
    return WindowsAuthRepository();
  }
  
  // For all other platforms, use Firebase
  debugPrint('Using Firebase auth repository');
  return FirebaseAuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
}); 