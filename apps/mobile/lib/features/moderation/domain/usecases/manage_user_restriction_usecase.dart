import 'package:hive_ui/features/moderation/domain/entities/user_restriction_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for managing user restrictions
class ManageUserRestrictionUseCase {
  final ModerationRepository _repository;

  /// Constructor
  ManageUserRestrictionUseCase(this._repository);

  /// Create a new restriction for a user
  Future<String> restrictUser({
    required String userId,
    required String reason,
    required String restrictedBy,
    Duration? duration,
    String? notes,
  }) async {
    // Calculate expiration date if duration is provided
    DateTime? expiresAt;
    if (duration != null) {
      expiresAt = DateTime.now().add(duration);
    }

    // Create the restriction
    return _repository.createUserRestriction(
      userId: userId,
      reason: reason,
      restrictedBy: restrictedBy,
      expiresAt: expiresAt,
      notes: notes,
    );
  }

  /// Update an existing restriction
  Future<void> updateRestriction({
    required String restrictionId,
    bool? isActive,
    String? reason,
    Duration? newDuration,
    String? notes,
  }) async {
    // Calculate new expiration date if duration is provided
    DateTime? expiresAt;
    if (newDuration != null) {
      expiresAt = DateTime.now().add(newDuration);
    }

    await _repository.updateUserRestriction(
      restrictionId: restrictionId,
      isActive: isActive,
      reason: reason,
      expiresAt: expiresAt,
      notes: notes,
    );
  }

  /// Remove a restriction (mark as inactive)
  Future<void> removeRestriction({
    required String restrictionId,
    required String removedBy,
    String? removalReason,
  }) async {
    await _repository.removeUserRestriction(
      restrictionId: restrictionId,
      removedBy: removedBy,
      removalReason: removalReason,
    );
  }

  /// Get a specific restriction by ID
  Future<UserRestrictionEntity?> getRestriction(String restrictionId) async {
    return _repository.getUserRestrictionById(restrictionId);
  }

  /// Get all restrictions
  Future<List<UserRestrictionEntity>> getAllRestrictions() async {
    return _repository.getAllUserRestrictions();
  }
} 