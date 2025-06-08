import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/feed/personalization/personalization_engine.dart';

/// Provider for accessing the personalization engine
final personalizationEngineProvider =
    Provider<FeedPersonalizationEngine>((ref) {
  return FeedPersonalizationEngine();
});

/// Provider for event feature weights used in personalization
final featureWeightsProvider = StateProvider<Map<String, double>>((ref) {
  // Default weights
  return {
    'recency': 5.0,
    'popularity': 3.0,
    'userInterest': 4.0,
    'previousEngagement': 4.5,
    'friendsAttending': 2.0,
    'distance': 1.5,
  };
});

/// Provider for personalized scores for a list of events
final personalizedEventsProvider =
    FutureProvider.family<List<ScoredEvent>, List<Event>>((ref, events) async {
  // Get current user
  final user = ref.watch(currentUserProvider);

  // Get feature weights
  final weights = ref.watch(featureWeightsProvider);

  // Use personalization engine to score events
  return FeedPersonalizationEngine.scoreEvents(
    user.id,
    events,
    featureWeights: weights,
  );
});

/// Provider for user interests
final userInterestsProvider =
    FutureProvider.family<Map<String, double>, String>((ref, userId) async {
  // In a real implementation, this would use the personalization engine
  // to get the user's interests. For now, we return a placeholder.

  // Would be implemented as:
  // return FeedPersonalizationEngine._getUserInterests(userId);

  // Placeholder implementation:
  return {
    'technology': 7.5,
    'networking': 6.0,
    'social': 4.0,
    'education': 8.0,
    'business': 5.0,
  };
});

/// Provider for debugging feature score contributions
final featureScoreContributionsProvider =
    Provider.family<Map<String, double>, ScoredEvent>((ref, scoredEvent) {
  final weights = ref.watch(featureWeightsProvider);
  final scores = scoredEvent.featureScores;

  // Calculate weighted contributions
  final Map<String, double> contributions = {};
  double totalContribution = 0.0;

  scores.forEach((feature, score) {
    final weight = weights[feature] ?? 1.0;
    final contribution = score * weight;
    contributions[feature] = contribution;
    totalContribution += contribution;
  });

  // Normalize to percentages
  if (totalContribution > 0) {
    contributions.forEach((feature, value) {
      contributions[feature] = (value / totalContribution) * 100;
    });
  }

  return contributions;
});
