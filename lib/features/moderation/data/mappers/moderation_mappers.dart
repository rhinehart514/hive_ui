import 'package:hive_ui/features/moderation/data/models/content_report_model.dart' as models;
import 'package:hive_ui/features/moderation/data/models/moderation_action_model.dart' as models;
import 'package:hive_ui/features/moderation/data/models/moderation_settings_model.dart' as models;
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/entities/moderation_action_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/entities/moderation_settings_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/entities/reported_content_entity.dart' as entities;

/// Mapper for ContentReport model to entity conversion
class ContentReportMapper {
  /// Map from data model to domain entity
  static entities.ContentReportEntity fromModel(models.ContentReportModel model) {
    return entities.ContentReportEntity(
      id: model.id,
      reporterUserId: model.reporterUserId,
      contentType: _mapReportedContentTypeToEntity(model.contentType),
      contentId: model.contentId,
      reason: _mapReportReasonToEntity(model.reason),
      details: model.details,
      status: _mapReportStatusToEntity(model.status),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      resolvedByUserId: model.resolvedByUserId,
      moderatorNotes: model.moderatorNotes,
      actionTaken: model.actionTaken,
    );
  }
  
  /// Map from domain entity to data model
  static models.ContentReportModel toModel(entities.ContentReportEntity entity) {
    return models.ContentReportModel(
      id: entity.id,
      reporterUserId: entity.reporterUserId,
      contentType: _mapReportedContentTypeToModel(entity.contentType),
      contentId: entity.contentId,
      reason: _mapReportReasonToModel(entity.reason),
      details: entity.details,
      status: _mapReportStatusToModel(entity.status),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      resolvedByUserId: entity.resolvedByUserId,
      moderatorNotes: entity.moderatorNotes,
      actionTaken: entity.actionTaken,
    );
  }
  
  // Private helper methods for enum conversion
  static entities.ReportedContentType _mapReportedContentTypeToEntity(models.ReportedContentType type) {
    switch (type) {
      case models.ReportedContentType.post:
        return entities.ReportedContentType.post;
      case models.ReportedContentType.comment:
        return entities.ReportedContentType.comment;
      case models.ReportedContentType.message:
        return entities.ReportedContentType.message;
      case models.ReportedContentType.profile:
        return entities.ReportedContentType.profile;
      case models.ReportedContentType.space:
        return entities.ReportedContentType.space;
      case models.ReportedContentType.event:
        return entities.ReportedContentType.event;
    }
  }
  
  static models.ReportedContentType _mapReportedContentTypeToModel(entities.ReportedContentType type) {
    switch (type) {
      case entities.ReportedContentType.post:
        return models.ReportedContentType.post;
      case entities.ReportedContentType.comment:
        return models.ReportedContentType.comment;
      case entities.ReportedContentType.message:
        return models.ReportedContentType.message;
      case entities.ReportedContentType.profile:
        return models.ReportedContentType.profile;
      case entities.ReportedContentType.space:
        return models.ReportedContentType.space;
      case entities.ReportedContentType.event:
        return models.ReportedContentType.event;
    }
  }
  
  static entities.ReportReason _mapReportReasonToEntity(models.ReportReason reason) {
    switch (reason) {
      case models.ReportReason.spam:
        return entities.ReportReason.spam;
      case models.ReportReason.harassment:
        return entities.ReportReason.harassment;
      case models.ReportReason.hateSpeech:
        return entities.ReportReason.hateSpeech;
      case models.ReportReason.inappropriateContent:
        return entities.ReportReason.inappropriateContent;
      case models.ReportReason.violatesGuidelines:
        return entities.ReportReason.violatesGuidelines;
      case models.ReportReason.other:
        return entities.ReportReason.other;
    }
  }
  
  static models.ReportReason _mapReportReasonToModel(entities.ReportReason reason) {
    switch (reason) {
      case entities.ReportReason.spam:
        return models.ReportReason.spam;
      case entities.ReportReason.harassment:
        return models.ReportReason.harassment;
      case entities.ReportReason.hateSpeech:
        return models.ReportReason.hateSpeech;
      case entities.ReportReason.inappropriateContent:
        return models.ReportReason.inappropriateContent;
      case entities.ReportReason.violatesGuidelines:
        return models.ReportReason.violatesGuidelines;
      case entities.ReportReason.other:
        return models.ReportReason.other;
    }
  }
  
  static entities.ReportStatus _mapReportStatusToEntity(models.ReportStatus status) {
    switch (status) {
      case models.ReportStatus.pending:
        return entities.ReportStatus.pending;
      case models.ReportStatus.underReview:
        return entities.ReportStatus.underReview;
      case models.ReportStatus.resolved:
        return entities.ReportStatus.resolved;
      case models.ReportStatus.dismissed:
        return entities.ReportStatus.dismissed;
    }
  }
  
  static models.ReportStatus _mapReportStatusToModel(entities.ReportStatus status) {
    switch (status) {
      case entities.ReportStatus.pending:
        return models.ReportStatus.pending;
      case entities.ReportStatus.underReview:
        return models.ReportStatus.underReview;
      case entities.ReportStatus.resolved:
        return models.ReportStatus.resolved;
      case entities.ReportStatus.dismissed:
        return models.ReportStatus.dismissed;
    }
  }
}

/// Mapper for ModerationAction model to entity conversion
class ModerationActionMapper {
  /// Map from data model to domain entity
  static entities.ModerationActionEntity fromModel(models.ModerationActionModel model) {
    return entities.ModerationActionEntity(
      id: model.id,
      actionType: _mapActionTypeToEntity(model.actionType),
      moderatorId: model.moderatorId,
      targetId: model.targetId,
      isUserTarget: model.isUserTarget,
      severity: _mapSeverityToEntity(model.severity),
      relatedReportIds: model.relatedReportIds,
      notes: model.notes,
      createdAt: model.createdAt,
      expiresAt: model.expiresAt,
      isActive: model.isActive,
    );
  }
  
  /// Map from domain entity to data model
  static models.ModerationActionModel toModel(entities.ModerationActionEntity entity) {
    return models.ModerationActionModel(
      id: entity.id,
      actionType: _mapActionTypeToModel(entity.actionType),
      moderatorId: entity.moderatorId,
      targetId: entity.targetId,
      isUserTarget: entity.isUserTarget,
      severity: _mapSeverityToModel(entity.severity),
      relatedReportIds: entity.relatedReportIds,
      notes: entity.notes,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      isActive: entity.isActive,
    );
  }
  
  // Private helper methods for enum conversion
  static entities.ModerationActionType _mapActionTypeToEntity(models.ModerationActionType type) {
    switch (type) {
      case models.ModerationActionType.removeContent:
        return entities.ModerationActionType.removeContent;
      case models.ModerationActionType.hideContent:
        return entities.ModerationActionType.hideContent;
      case models.ModerationActionType.warnUser:
        return entities.ModerationActionType.warnUser;
      case models.ModerationActionType.restrictUser:
        return entities.ModerationActionType.restrictUser;
      case models.ModerationActionType.banUser:
        return entities.ModerationActionType.banUser;
      case models.ModerationActionType.escalateToAdmin:
        return entities.ModerationActionType.escalateToAdmin;
      case models.ModerationActionType.markSafe:
        return entities.ModerationActionType.markSafe;
      case models.ModerationActionType.other:
        return entities.ModerationActionType.other;
    }
  }
  
  static models.ModerationActionType _mapActionTypeToModel(entities.ModerationActionType type) {
    switch (type) {
      case entities.ModerationActionType.removeContent:
        return models.ModerationActionType.removeContent;
      case entities.ModerationActionType.hideContent:
        return models.ModerationActionType.hideContent;
      case entities.ModerationActionType.warnUser:
        return models.ModerationActionType.warnUser;
      case entities.ModerationActionType.restrictUser:
        return models.ModerationActionType.restrictUser;
      case entities.ModerationActionType.banUser:
        return models.ModerationActionType.banUser;
      case entities.ModerationActionType.escalateToAdmin:
        return models.ModerationActionType.escalateToAdmin;
      case entities.ModerationActionType.markSafe:
        return models.ModerationActionType.markSafe;
      case entities.ModerationActionType.other:
        return models.ModerationActionType.other;
    }
  }
  
  static entities.ModerationSeverity _mapSeverityToEntity(models.ModerationSeverity severity) {
    switch (severity) {
      case models.ModerationSeverity.low:
        return entities.ModerationSeverity.low;
      case models.ModerationSeverity.medium:
        return entities.ModerationSeverity.medium;
      case models.ModerationSeverity.high:
        return entities.ModerationSeverity.high;
      case models.ModerationSeverity.critical:
        return entities.ModerationSeverity.critical;
    }
  }
  
  static models.ModerationSeverity _mapSeverityToModel(entities.ModerationSeverity severity) {
    switch (severity) {
      case entities.ModerationSeverity.low:
        return models.ModerationSeverity.low;
      case entities.ModerationSeverity.medium:
        return models.ModerationSeverity.medium;
      case entities.ModerationSeverity.high:
        return models.ModerationSeverity.high;
      case entities.ModerationSeverity.critical:
        return models.ModerationSeverity.critical;
    }
  }
}

/// Mapper for ModerationSettings model to entity conversion
class ModerationSettingsMapper {
  /// Map from data model to domain entity
  static entities.ModerationSettingsEntity fromModel(models.ModerationSettingsModel model) {
    return entities.ModerationSettingsEntity(
      id: model.id,
      autoModerationEnabled: model.autoModerationEnabled,
      blockedKeywords: model.blockedKeywords,
      flaggedKeywords: model.flaggedKeywords,
      moderatorIds: model.moderatorIds,
      reportsThreshold: model.reportsThreshold,
      notifyModeratorsOnReport: model.notifyModeratorsOnReport,
      hideReportedContent: model.hideReportedContent,
      showContentWarnings: model.showContentWarnings,
      customSettings: model.customSettings,
      updatedAt: model.updatedAt,
      spaceId: model.spaceId,
    );
  }
  
  /// Map from domain entity to data model
  static models.ModerationSettingsModel toModel(entities.ModerationSettingsEntity entity) {
    return models.ModerationSettingsModel(
      id: entity.id,
      autoModerationEnabled: entity.autoModerationEnabled,
      blockedKeywords: entity.blockedKeywords,
      flaggedKeywords: entity.flaggedKeywords,
      moderatorIds: entity.moderatorIds,
      reportsThreshold: entity.reportsThreshold,
      notifyModeratorsOnReport: entity.notifyModeratorsOnReport,
      hideReportedContent: entity.hideReportedContent,
      showContentWarnings: entity.showContentWarnings,
      customSettings: entity.customSettings,
      updatedAt: entity.updatedAt,
      spaceId: entity.spaceId,
    );
  }
}

/// Factory for creating a ReportedContentEntity with associated content data
class ReportedContentFactory {
  /// Create a ReportedContentEntity from a ContentReportEntity and content data
  static entities.ReportedContentEntity createFromReport({
    required entities.ContentReportEntity report,
    String? contentTitle,
    String? contentText,
    String? creatorId,
    String? creatorName,
    String? creatorImageUrl,
    DateTime? contentCreatedAt,
    Map<String, dynamic>? contentMetadata,
  }) {
    return entities.ReportedContentEntity(
      report: report,
      contentTitle: contentTitle,
      contentText: contentText,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorImageUrl: creatorImageUrl,
      contentCreatedAt: contentCreatedAt,
      contentMetadata: contentMetadata,
    );
  }
} 