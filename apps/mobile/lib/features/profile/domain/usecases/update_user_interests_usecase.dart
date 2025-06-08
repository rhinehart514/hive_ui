import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';

/// Use case for updating a user's interests
class UpdateUserInterestsUseCase {
  final ProfileRepository _repository;

  /// Constructor
  UpdateUserInterestsUseCase(this._repository);

  /// Execute the use case
  /// 
  /// Updates only the interests field for a user, which is more efficient
  /// than updating the entire profile when only interests change
  Future<void> execute(String userId, List<String> interests) async {
    try {
      await _repository.updateUserInterests(userId, interests);
    } catch (e) {
      debugPrint('UpdateUserInterestsUseCase: Error updating interests: $e');
      throw Exception('Failed to update interests: $e');
    }
  }
} 