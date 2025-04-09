import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/moderation/domain/entities/user_restriction_entity.dart';
import 'package:hive_ui/features/moderation/domain/usecases/check_user_restriction_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/manage_user_restriction_usecase.dart';

/// Controller for user restrictions
class UserRestrictionController extends StateNotifier<AsyncValue<List<UserRestrictionEntity>>> {
  final CheckUserRestrictionUseCase _checkUserRestrictionUseCase;
  final ManageUserRestrictionUseCase _manageUserRestrictionUseCase;

  /// Constructor
  UserRestrictionController(
    this._checkUserRestrictionUseCase,
    this._manageUserRestrictionUseCase,
  ) : super(const AsyncValue.loading()) {
    loadActiveRestrictions();
  }

  /// Load all active user restrictions
  Future<void> loadActiveRestrictions() async {
    try {
      state = const AsyncValue.loading();
      final restrictions = await _checkUserRestrictionUseCase.getAllActiveRestrictions();
      state = AsyncValue.data(restrictions);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  /// Load all user restrictions (active and inactive)
  Future<void> loadAllRestrictions() async {
    try {
      state = const AsyncValue.loading();
      final restrictions = await _manageUserRestrictionUseCase.getAllRestrictions();
      state = AsyncValue.data(restrictions);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  /// Create a new user restriction
  Future<String> restrictUser({
    required String userId,
    required String reason,
    required String restrictedBy,
    Duration? duration,
    String? notes,
  }) async {
    try {
      final restrictionId = await _manageUserRestrictionUseCase.restrictUser(
        userId: userId,
        reason: reason,
        restrictedBy: restrictedBy,
        duration: duration,
        notes: notes,
      );

      // Refresh the list after adding
      await loadActiveRestrictions();
      
      return restrictionId;
    } catch (error) {
      rethrow;
    }
  }

  /// Update an existing restriction
  Future<void> updateRestriction({
    required String restrictionId,
    bool? isActive,
    String? reason,
    Duration? newDuration,
    String? notes,
  }) async {
    try {
      await _manageUserRestrictionUseCase.updateRestriction(
        restrictionId: restrictionId,
        isActive: isActive,
        reason: reason,
        newDuration: newDuration,
        notes: notes,
      );

      // Refresh the list after updating
      await loadActiveRestrictions();
    } catch (error) {
      rethrow;
    }
  }

  /// Remove a restriction (deactivate it)
  Future<void> removeRestriction({
    required String restrictionId,
    required String removedBy,
    String? removalReason,
  }) async {
    try {
      await _manageUserRestrictionUseCase.removeRestriction(
        restrictionId: restrictionId,
        removedBy: removedBy,
        removalReason: removalReason,
      );

      // Refresh the list after removing
      await loadActiveRestrictions();
    } catch (error) {
      rethrow;
    }
  }

  /// Check if a user is currently restricted
  Future<bool> isUserRestricted(String userId) async {
    return _checkUserRestrictionUseCase.isRestricted(userId);
  }

  /// Get details about a user's restriction
  Future<UserRestrictionEntity?> getUserRestrictionDetails(String userId) async {
    return _checkUserRestrictionUseCase.getRestrictionDetails(userId);
  }
} 