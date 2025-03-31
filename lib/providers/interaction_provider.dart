import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/interactions/interaction.dart';
import 'package:hive_ui/models/interactions/interaction_stats.dart';
import 'package:hive_ui/services/interactions/interaction_service.dart';

/// Provider for the interaction service
final interactionServiceProvider = Provider<InteractionService>((ref) {
  // Initialize the interaction service
  InteractionService.initialize();

  // Return the service instance (singleton)
  return InteractionService();
});

/// Provider for entity interaction stats
final entityStatsProvider = FutureProvider.family<InteractionStats,
    ({String entityId, EntityType entityType})>(
  (ref, params) async {
    // Fetch stats for the specified entity
    return InteractionService.getEntityStats(
      params.entityId,
      params.entityType,
    );
  },
);

/// Provider for entity interactions list
final entityInteractionsProvider = FutureProvider.family<List<Interaction>,
    ({String entityId, int limit, String? userId})>(
  (ref, params) async {
    // Fetch interactions for the specified entity
    return InteractionService.getEntityInteractions(
      params.entityId,
      limit: params.limit,
      userId: params.userId,
    );
  },
);

/// Logs an interaction with an entity
Future<void> logInteraction({
  required String userId,
  required String entityId,
  required EntityType entityType,
  required InteractionAction action,
  Map<String, dynamic>? metadata,
  bool highPriority = false,
}) async {
  return InteractionService.logInteraction(
    userId: userId,
    entityId: entityId,
    entityType: entityType,
    action: action,
    metadata: metadata,
    highPriority: highPriority,
  );
}
