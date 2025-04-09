import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/moderation/data/repositories/firestore_moderation_repository.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Provider for the Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for the ModerationRepository
final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreModerationRepository(firestore: firestore);
}); 