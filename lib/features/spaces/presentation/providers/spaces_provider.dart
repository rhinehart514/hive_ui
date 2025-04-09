import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/auth_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space.dart';

/// Provider for fetching spaces
final allSpacesProvider = StreamProvider<List<Space>>((ref) {
  return FirebaseFirestore.instance
      .collection('spaces')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Space.fromDocument(doc)).toList();
  });
});

/// Provider for fetching spaces a user is a member of
final userSpacesProvider = StreamProvider<List<Space>>((ref) {
  final userId = ref.watch(currentUserProvider).value?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('spaces')
      .where(Filter.or(
        Filter('ownerId', isEqualTo: userId),
        Filter('moderatorIds', arrayContains: userId),
        Filter('memberIds', arrayContains: userId),
      ))
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Space.fromDocument(doc)).toList();
  });
});

/// Provider for fetching a single space by ID
final spaceProvider = StreamProvider.family<Space, String>((ref, spaceId) {
  return FirebaseFirestore.instance
      .collection('spaces')
      .doc(spaceId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return Space.empty();
    }
    return Space.fromDocument(snapshot);
  });
});

/// Provider to check if user can manage a space
final canManageSpaceProvider = Provider.family<bool, String>((ref, spaceId) {
  final userId = ref.watch(currentUserProvider).value?.uid;
  if (userId == null) {
    return false;
  }
  
  final spaceAsync = ref.watch(spaceProvider(spaceId));
  return spaceAsync.when(
    data: (space) => space.isModerator(userId),
    loading: () => false,
    error: (_, __) => false,
  );
}); 