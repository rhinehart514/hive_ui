import 'package:hive_ui/features/recommendation/domain/repositories/recommendation_repository.dart';

/// Use case for getting content similar to a reference item
class GetSimilarContentUseCase {
  /// The recommendation repository
  final RecommendationRepository _repository;
  
  /// Constructor
  GetSimilarContentUseCase(this._repository);
  
  /// Execute the use case to get similar content
  Future<List<RecommendationResult>> execute<T>({
    required String contentId,
    required String contentType,
    int limit = 10,
    List<String>? algorithmIds,
  }) async {
    // Get similar content from repository
    final similarContent = await _repository.getSimilarContent(
      contentId,
      contentType,
      limit: limit,
      algorithmIds: algorithmIds,
    );
    
    // Track this similar content request for analytics
    await _trackSimilarContentRequest(
      contentId: contentId,
      contentType: contentType,
      count: similarContent.length,
      algorithms: algorithmIds,
    );
    
    return similarContent;
  }
  
  /// Track similar content request for analytics
  Future<void> _trackSimilarContentRequest({
    required String contentId,
    required String contentType,
    required int count,
    List<String>? algorithms,
  }) async {
    // Implementation would record metrics about this similar content request
    // This is a placeholder method that would connect to an analytics service
    return;
  }
} 