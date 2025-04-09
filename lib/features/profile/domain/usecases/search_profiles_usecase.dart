import '../entities/user_profile.dart';
import '../entities/user_search_filters.dart';
import '../repositories/profile_repository.dart';
// TODO: Add dependency injection for repository

/// Use case for searching user profiles.
class SearchProfilesUseCase {
  final ProfileRepository _repository;

  SearchProfilesUseCase(this._repository);

  /// Executes the search.
  Future<List<UserProfile>> execute({
    required String query,
    UserSearchFilters? filters,
    int limit = 20,
  }) {
    return _repository.searchProfiles(
      query: query,
      filters: filters,
      limit: limit,
    );
  }
} 