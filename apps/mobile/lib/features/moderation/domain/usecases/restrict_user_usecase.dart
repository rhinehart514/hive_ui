import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for restricting or un-restricting a user.
class RestrictUserUseCase {
  final ModerationRepository _repository;

  RestrictUserUseCase(this._repository);

  /// Executes the use case.
  Future<void> call(String userId, {
    required bool isRestricted,
    String? reason,
    DateTime? endDate,
    required String restrictedBy, // Admin/System ID applying the restriction
  }) async {
    try {
      if (isRestricted) {
        // Create a new restriction
        await _repository.createUserRestriction(
          userId: userId,
          reason: reason ?? 'No reason provided',
          restrictedBy: restrictedBy,
          expiresAt: endDate,
        );
      } else {
        // Find and remove any active restrictions
        final restriction = await _repository.getUserRestrictionByUserId(userId);
        if (restriction != null) {
          await _repository.removeUserRestriction(
            restrictionId: restriction.id,
            removedBy: restrictedBy,
            removalReason: 'Restriction removed',
          );
        }
      }
    } catch (e) {
      // Handle or rethrow the error as appropriate for the application
      print('Error in RestrictUserUseCase: $e');
      rethrow;
    }
  }
} 