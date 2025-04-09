import 'package:hive_ui/features/recommendation/domain/repositories/recommendation_repository.dart';

/// Use case for getting personalized recommendations for a user
class GetPersonalizedRecommendationsUseCase {
  /// The recommendation repository
  final RecommendationRepository _repository;
  
  /// Constructor
  GetPersonalizedRecommendationsUseCase(this._repository);
  
  /// Execute the use case to get personalized recommendations
  Future<List<RecommendationResult>> execute<T>({
    required String userId,
    required String contentType,
    int limit = 10,
    List<String>? algorithmIds,
    Map<String, dynamic>? filters,
  }) async {
    // Get recommendations from repository
    final recommendations = await _repository.getRecommendedContent(
      userId,
      contentType,
      limit: limit,
      algorithmIds: algorithmIds,
      filters: filters,
    );
    
    // Track this recommendation request for analytics
    await _trackRecommendationRequest(
      userId: userId,
      contentType: contentType,
      count: recommendations.length,
      algorithms: algorithmIds,
    );
    
    return recommendations;
  }
  
  /// Track recommendation request for analytics
  Future<void> _trackRecommendationRequest({
    required String userId,
    required String contentType,
    required int count,
    List<String>? algorithms,
  }) async {
    // Implementation would record metrics about this recommendation request
    // This is a placeholder method that would connect to an analytics service
    return;
  }
} 