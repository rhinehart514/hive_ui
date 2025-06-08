import '../repositories/profile_repository.dart';
// TODO: Add dependency injection for repository

/// Use case for recording an interaction on a user profile.
class RecordProfileInteractionUseCase {
  final ProfileRepository _repository;

  RecordProfileInteractionUseCase(this._repository);

  /// Executes the use case.
  Future<void> execute({
    required String viewedUserId,
    required String viewerId,
    required String interactionType,
  }) {
    // Add validation if necessary (e.g., check interactionType)
    return _repository.recordProfileInteraction(
      viewedUserId: viewedUserId,
      viewerId: viewerId,
      interactionType: interactionType,
    );
  }
} 