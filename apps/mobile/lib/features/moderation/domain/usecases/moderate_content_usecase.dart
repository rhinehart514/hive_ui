import 'package:hive_ui/features/moderation/domain/entities/moderation_action_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for moderating content
class ModerateContentUseCase {
  final ModerationRepository _repository;

  /// Constructor
  ModerateContentUseCase(this._repository);

  /// Take moderation action on content
  Future<String> takeActionOnContent({
    required String moderatorId,
    required String contentId,
    required ModerationActionType actionType,
    required ModerationSeverity severity,
    List<String> relatedReportIds = const [],
    required String notes,
    DateTime? expiresAt,
  }) async {
    return _repository.createModerationAction(
      moderatorId: moderatorId,
      targetId: contentId,
      isUserTarget: false, // This is content, not a user
      actionType: actionType,
      severity: severity,
      relatedReportIds: relatedReportIds,
      notes: notes,
      expiresAt: expiresAt,
    );
  }

  /// Take moderation action on a user
  Future<String> takeActionOnUser({
    required String moderatorId,
    required String userId,
    required ModerationActionType actionType,
    required ModerationSeverity severity,
    List<String> relatedReportIds = const [],
    required String notes,
    DateTime? expiresAt,
  }) async {
    return _repository.createModerationAction(
      moderatorId: moderatorId,
      targetId: userId,
      isUserTarget: true, // This is a user, not content
      actionType: actionType,
      severity: severity,
      relatedReportIds: relatedReportIds,
      notes: notes,
      expiresAt: expiresAt,
    );
  }

  /// Update a moderation action
  Future<void> updateAction({
    required String actionId,
    ModerationActionType? actionType,
    ModerationSeverity? severity,
    String? notes,
    DateTime? expiresAt,
    bool? isActive,
  }) async {
    await _repository.updateModerationAction(
      actionId: actionId,
      actionType: actionType,
      severity: severity,
      notes: notes,
      expiresAt: expiresAt,
      isActive: isActive,
    );
  }

  /// Get all moderation actions
  Future<List<ModerationActionEntity>> getAllActions() async {
    return _repository.getAllModerationActions();
  }

  /// Get actions for a specific content
  Future<List<ModerationActionEntity>> getActionsForContent(String contentId) async {
    return _repository.getActionsForTarget(contentId, isUserTarget: false);
  }

  /// Get actions for a specific user
  Future<List<ModerationActionEntity>> getActionsForUser(String userId) async {
    return _repository.getActionsForTarget(userId, isUserTarget: true);
  }

  /// Get a specific action by ID
  Future<ModerationActionEntity?> getActionById(String actionId) async {
    return _repository.getActionById(actionId);
  }
} 