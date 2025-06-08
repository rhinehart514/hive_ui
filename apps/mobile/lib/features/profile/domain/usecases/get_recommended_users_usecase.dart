import '../entities/recommended_user.dart';
import '../repositories/profile_repository.dart';
// TODO: Add dependency injection for repository

/// Use case for getting recommended users.
class GetRecommendedUsersUseCase {
  final ProfileRepository _repository;

  GetRecommendedUsersUseCase(this._repository);

  /// Executes the use case.
  Future<List<RecommendedUser>> execute({
    String? basedOnUserId,
    int limit = 10,
  }) {
    return _repository.getRecommendedUsers(
      basedOnUserId: basedOnUserId,
      limit: limit,
    );
  }
} 