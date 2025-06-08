import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import will be uncommented when implementation is available
// import 'package:hive_ui/features/recommendation/data/repositories/recommendation_repository_impl.dart';
import 'package:hive_ui/features/recommendation/domain/repositories/recommendation_repository.dart';
import 'package:hive_ui/features/recommendation/domain/usecases/get_personalized_recommendations_usecase.dart';
import 'package:hive_ui/features/recommendation/domain/usecases/get_similar_content_usecase.dart';
import 'package:hive_ui/features/recommendation/domain/usecases/record_user_interaction_usecase.dart';

/// Provider for the recommendation repository
final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  // This should return the actual implementation once it's available
  throw UnimplementedError('Recommendation repository implementation not available yet');
  // Will be implemented as:
  // return RecommendationRepositoryImpl(
  //   firestore: ref.watch(firestoreProvider),
  //   auth: ref.watch(authProvider),
  // );
});

/// Provider for the GetPersonalizedRecommendationsUseCase
final getPersonalizedRecommendationsUseCaseProvider = Provider<GetPersonalizedRecommendationsUseCase>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return GetPersonalizedRecommendationsUseCase(repository);
});

/// Provider for the GetSimilarContentUseCase
final getSimilarContentUseCaseProvider = Provider<GetSimilarContentUseCase>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return GetSimilarContentUseCase(repository);
});

/// Provider for the RecordUserInteractionUseCase
final recordUserInteractionUseCaseProvider = Provider<RecordUserInteractionUseCase>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return RecordUserInteractionUseCase(repository);
}); 