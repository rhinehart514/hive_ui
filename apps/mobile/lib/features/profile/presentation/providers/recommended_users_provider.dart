import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/domain/entities/recommended_user.dart';

/// Provider for user recommendations
final recommendedUsersProvider = FutureProvider.family<List<RecommendedUser>, int>((ref, limit) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Get recommendations from Firestore
    final snapshot = await firestore
        .collection('user_recommendations')
        .where('isViewed', isEqualTo: false)
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

    // Convert to RecommendedUser objects
    final recommendations = snapshot.docs.map((doc) {
      final data = doc.data();
      return RecommendedUser.fromFirestore(data, data['itemId'] as String);
    }).toList();

    // Mark recommendations as viewed
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isViewed': true});
    }
    await batch.commit();

    return recommendations;
  } catch (e) {
    // Log error and return empty list
    print('Error fetching recommendations: $e');
    return [];
  }
}); 