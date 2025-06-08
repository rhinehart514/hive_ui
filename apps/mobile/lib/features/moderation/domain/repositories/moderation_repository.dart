import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/moderation_action_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/moderation_settings_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/reported_content_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/user_restriction_entity.dart';

/// Interface for the moderation repository
abstract class ModerationRepository {
  /// Get all content reports
  Future<List<ContentReportEntity>> getAllReports();
  
  /// Get reports by status
  Future<List<ContentReportEntity>> getReportsByStatus(ReportStatus status);
  
  /// Get reports for a specific piece of content
  Future<List<ContentReportEntity>> getReportsForContent(String contentId, ReportedContentType contentType);
  
  /// Get a specific report by ID
  Future<ContentReportEntity?> getReportById(String reportId);
  
  /// Submit a new content report
  Future<String> submitReport({
    required String reporterUserId,
    required ReportedContentType contentType,
    required String contentId,
    required ReportReason reason,
    String? details,
  });
  
  /// Update the status of a report
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? moderatorId,
    String? moderatorNotes,
    String? actionTaken,
  });
  
  /// Get detailed information about reported content
  Future<ReportedContentEntity?> getReportedContentDetails(ContentReportEntity report);
  
  /// Get all moderation actions
  Future<List<ModerationActionEntity>> getAllModerationActions();
  
  /// Get actions for a specific target (content or user)
  Future<List<ModerationActionEntity>> getActionsForTarget(String targetId, {bool isUserTarget = false});
  
  /// Get a specific action by ID
  Future<ModerationActionEntity?> getActionById(String actionId);
  
  /// Create a new moderation action
  Future<String> createModerationAction({
    required ModerationActionType actionType,
    required String moderatorId,
    required String targetId,
    required bool isUserTarget,
    required ModerationSeverity severity,
    List<String> relatedReportIds = const [],
    required String notes,
    DateTime? expiresAt,
  });
  
  /// Update an existing moderation action
  Future<void> updateModerationAction({
    required String actionId,
    ModerationActionType? actionType,
    ModerationSeverity? severity,
    String? notes,
    DateTime? expiresAt,
    bool? isActive,
  });
  
  /// Get global moderation settings
  Future<ModerationSettingsEntity> getGlobalModerationSettings();
  
  /// Get moderation settings for a specific space
  Future<ModerationSettingsEntity> getSpaceModerationSettings(String spaceId);
  
  /// Update moderation settings
  Future<void> updateModerationSettings({
    required String settingsId,
    bool? autoModerationEnabled,
    List<String>? blockedKeywords,
    List<String>? flaggedKeywords,
    List<String>? moderatorIds,
    int? reportsThreshold,
    bool? notifyModeratorsOnReport,
    bool? hideReportedContent,
    bool? showContentWarnings,
    Map<String, dynamic>? customSettings,
  });
  
  /// Scan text content for moderation issues
  Future<bool> scanContent({
    required String content,
    required String spaceId,
  });
  
  /// Get statistics about reports and moderation actions
  Future<Map<String, dynamic>> getModerationStats({
    DateTime? startDate,
    DateTime? endDate,
    String? spaceId,
  });
  
  /// Get all user restrictions
  Future<List<UserRestrictionEntity>> getAllUserRestrictions();
  
  /// Get active user restrictions only
  Future<List<UserRestrictionEntity>> getActiveUserRestrictions();
  
  /// Get user restriction by ID
  Future<UserRestrictionEntity?> getUserRestrictionById(String restrictionId);
  
  /// Get restriction for a specific user
  Future<UserRestrictionEntity?> getUserRestrictionByUserId(String userId);
  
  /// Create a new user restriction
  Future<String> createUserRestriction({
    required String userId,
    required String reason,
    required String restrictedBy,
    DateTime? expiresAt,
    String? notes,
  });
  
  /// Update an existing user restriction
  Future<void> updateUserRestriction({
    required String restrictionId,
    bool? isActive,
    String? reason,
    DateTime? expiresAt,
    String? notes,
  });
  
  /// Remove a user restriction (deactivate it)
  Future<void> removeUserRestriction({
    required String restrictionId,
    required String removedBy,
    String? removalReason,
  });
  
  /// Check if a user is currently restricted
  Future<bool> isUserRestricted(String userId);
} 