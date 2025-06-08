import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/shared/infrastructure/platform_integration_manager.dart';

/// Provider for the PlatformIntegrationManager
final platformIntegrationManagerProvider = Provider<PlatformIntegrationManager>((ref) {
  return PlatformIntegrationManager(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
}); 