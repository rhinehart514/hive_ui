import 'package:hive_ui/features/moderation/domain/entities/moderation_settings_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for managing moderation settings
class ManageModerationSettingsUseCase {
  final ModerationRepository _repository;

  /// Constructor
  ManageModerationSettingsUseCase(this._repository);

  /// Get global moderation settings
  Future<ModerationSettingsEntity> getGlobalSettings() async {
    return _repository.getGlobalModerationSettings();
  }

  /// Get space-specific moderation settings
  Future<ModerationSettingsEntity> getSpaceSettings(String spaceId) async {
    return _repository.getSpaceModerationSettings(spaceId);
  }

  /// Update global moderation settings
  Future<void> updateGlobalSettings({
    bool? autoModerationEnabled,
    List<String>? blockedKeywords,
    List<String>? flaggedKeywords,
    List<String>? moderatorIds,
    int? reportsThreshold,
    bool? notifyModeratorsOnReport,
    bool? hideReportedContent,
    bool? showContentWarnings,
    Map<String, dynamic>? customSettings,
  }) async {
    await _repository.updateModerationSettings(
      settingsId: 'global',
      autoModerationEnabled: autoModerationEnabled,
      blockedKeywords: blockedKeywords,
      flaggedKeywords: flaggedKeywords,
      moderatorIds: moderatorIds,
      reportsThreshold: reportsThreshold,
      notifyModeratorsOnReport: notifyModeratorsOnReport,
      hideReportedContent: hideReportedContent,
      showContentWarnings: showContentWarnings,
      customSettings: customSettings,
    );
  }

  /// Update space-specific moderation settings
  Future<void> updateSpaceSettings({
    required String spaceId,
    bool? autoModerationEnabled,
    List<String>? blockedKeywords,
    List<String>? flaggedKeywords,
    List<String>? moderatorIds,
    int? reportsThreshold,
    bool? notifyModeratorsOnReport,
    bool? hideReportedContent,
    bool? showContentWarnings,
    Map<String, dynamic>? customSettings,
  }) async {
    final settingsId = 'space_$spaceId';
    await _repository.updateModerationSettings(
      settingsId: settingsId,
      autoModerationEnabled: autoModerationEnabled,
      blockedKeywords: blockedKeywords,
      flaggedKeywords: flaggedKeywords,
      moderatorIds: moderatorIds,
      reportsThreshold: reportsThreshold,
      notifyModeratorsOnReport: notifyModeratorsOnReport,
      hideReportedContent: hideReportedContent,
      showContentWarnings: showContentWarnings,
      customSettings: customSettings,
    );
  }

  /// Check if content violates moderation rules
  Future<bool> checkContentViolation({
    required String content,
    required String spaceId,
  }) async {
    return _repository.scanContent(
      content: content,
      spaceId: spaceId,
    );
  }
} 