import 'package:hive_ui/features/recommendation/domain/entities/recommendation_algorithm_entity.dart';
import 'package:hive_ui/features/recommendation/domain/entities/user_context_entity.dart';

/// Repository interface for recommendation system
abstract class RecommendationRepository {
  /// Get available recommendation algorithms
  Future<List<RecommendationAlgorithmEntity>> getAvailableAlgorithms();
  
  /// Get active recommendation algorithms for a specific content type
  Future<List<RecommendationAlgorithmEntity>> getActiveAlgorithms(String contentType);
  
  /// Get a specific algorithm by ID
  Future<RecommendationAlgorithmEntity?> getAlgorithmById(String algorithmId);
  
  /// Create a new recommendation algorithm configuration
  Future<String> createAlgorithm(RecommendationAlgorithmEntity algorithm);
  
  /// Update an existing algorithm configuration
  Future<void> updateAlgorithm(RecommendationAlgorithmEntity algorithm);
  
  /// Delete an algorithm configuration
  Future<void> deleteAlgorithm(String algorithmId);
  
  /// Toggle an algorithm's active status
  Future<void> setAlgorithmActiveStatus(String algorithmId, bool isActive);
  
  /// Get user context for recommendation purposes
  Future<UserContextEntity> getUserContext(String userId);
  
  /// Update user context with new data
  Future<void> updateUserContext(UserContextEntity userContext);
  
  /// Add a user interaction to the system
  Future<void> recordUserInteraction(UserInteractionEntity interaction);
  
  /// Get user interactions for a specific user
  Future<List<UserInteractionEntity>> getUserInteractions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? contentType,
    InteractionType? interactionType,
  });
  
  /// Get recommended content items for a user
  /// Returns a list of content items with their scores
  Future<List<RecommendationResult>> getRecommendedContent(
    String userId,
    String contentType, {
    int limit = 10,
    List<String>? algorithmIds,
    Map<String, dynamic>? filters,
  });
  
  /// Get similar content items to a reference item
  Future<List<RecommendationResult>> getSimilarContent(
    String contentId,
    String contentType, {
    int limit = 10,
    List<String>? algorithmIds,
  });
  
  /// Get recommendation analytics and performance metrics
  Future<Map<String, dynamic>> getRecommendationMetrics({
    DateTime? startDate,
    DateTime? endDate,
    String? algorithmId,
    String? contentType,
  });
  
  /// Train or update recommendation models
  Future<void> trainRecommendationModels({
    String? contentType,
    String? algorithmId,
    bool forceRetrain = false,
  });
}

/// Class representing a recommendation result with item and score
class RecommendationResult<T> {
  /// The recommended item
  final T item;
  
  /// The recommendation score (higher is better)
  final double score;
  
  /// The algorithm used for this recommendation
  final String algorithmId;
  
  /// Explanations for why this item was recommended
  final List<String> explanations;
  
  /// Constructor
  const RecommendationResult({
    required this.item,
    required this.score,
    required this.algorithmId,
    required this.explanations,
  });
} 