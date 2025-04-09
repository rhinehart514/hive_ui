import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for getting moderation statistics
class GetModerationStatsUseCase {
  final ModerationRepository _repository;

  /// Constructor
  GetModerationStatsUseCase(this._repository);

  /// Get moderation statistics
  Future<Map<String, dynamic>> execute({
    DateTime? startDate,
    DateTime? endDate,
    String? spaceId,
  }) async {
    return _repository.getModerationStats(
      startDate: startDate,
      endDate: endDate,
      spaceId: spaceId,
    );
  }
} 