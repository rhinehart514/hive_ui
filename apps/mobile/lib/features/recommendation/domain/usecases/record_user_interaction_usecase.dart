import 'package:hive_ui/features/recommendation/domain/entities/user_context_entity.dart';
import 'package:hive_ui/features/recommendation/domain/repositories/recommendation_repository.dart';

/// Use case for recording user interactions with content
class RecordUserInteractionUseCase {
  /// The recommendation repository
  final RecommendationRepository _repository;
  
  /// Constructor
  RecordUserInteractionUseCase(this._repository);
  
  /// Execute the use case to record a user interaction
  Future<void> execute({
    required String userId,
    required String contentId,
    required String contentType,
    required InteractionType interactionType,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    // Create a unique interaction ID
    final id = _generateInteractionId(userId, contentId, interactionType);
    
    // Create the interaction entity
    final interaction = UserInteractionEntity(
      id: id,
      userId: userId,
      contentId: contentId,
      contentType: contentType,
      interactionType: interactionType,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: metadata,
    );
    
    // Record the interaction in the repository
    await _repository.recordUserInteraction(interaction);
  }
  
  /// Generate a unique ID for an interaction
  String _generateInteractionId(
    String userId,
    String contentId,
    InteractionType interactionType,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$userId-$contentId-${interactionType.toString()}-$timestamp';
  }
} 