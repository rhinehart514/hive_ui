import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/data/services/feed_intelligence_service_impl.dart';
import 'package:hive_ui/features/feed/domain/models/feed_intelligence_params.dart';
import 'package:hive_ui/features/feed/domain/models/user_trail.dart';
import 'package:hive_ui/features/feed/domain/services/feed_intelligence_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for the feed intelligence service
final feedIntelligenceServiceProvider = Provider<FeedIntelligenceService>((ref) {
  return FeedIntelligenceServiceImpl(
    firestore: FirebaseFirestore.instance,
  );
});

/// Provider for the current user's trail data
final userTrailProvider = FutureProvider.family<UserTrail, String>((ref, userId) async {
  final service = ref.watch(feedIntelligenceServiceProvider);
  final result = await service.getUserTrail(userId);
  
  return result.fold(
    (failure) => UserTrail.empty(),
    (trail) => trail,
  );
});

/// Provider for feed intelligence parameters based on user archetype
final feedIntelligenceParamsProvider = FutureProvider.family<FeedIntelligenceParams, String>((ref, userId) async {
  final service = ref.watch(feedIntelligenceServiceProvider);
  final trailResult = await ref.watch(userTrailProvider(userId).future);
  
  final result = await service.getIntelligenceParams(userId, trailResult);
  
  return result.fold(
    (failure) => const FeedIntelligenceParams(),
    (params) => params,
  );
});

/// Provider for applying feed intelligence to a feed
final intelligentFeedProvider = FutureProvider.family<List<Map<String, dynamic>>, FeedIntelligenceArgs>((ref, args) async {
  final service = ref.watch(feedIntelligenceServiceProvider);
  final result = await service.applyFeedIntelligence(args.feedItems, args.userId);
  
  return result.fold(
    (failure) => args.feedItems, // Return original items on failure
    (items) => items,
  );
});

/// Arguments for the intelligent feed provider
class FeedIntelligenceArgs {
  /// The feed items to apply intelligence to
  final List<Map<String, dynamic>> feedItems;
  
  /// The user ID
  final String userId;

  /// Constructor
  const FeedIntelligenceArgs({
    required this.feedItems,
    required this.userId,
  });

  /// Returns a new instance with the specified fields replaced
  FeedIntelligenceArgs copyWith({
    List<Map<String, dynamic>>? feedItems,
    String? userId,
  }) {
    return FeedIntelligenceArgs(
      feedItems: feedItems ?? this.feedItems,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedIntelligenceArgs &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
} 