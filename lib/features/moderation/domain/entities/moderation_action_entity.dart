/// Types of moderation actions that can be taken on content or users
enum ModerationActionType {
  removeContent,
  hideContent,
  warnUser,
  restrictUser,
  banUser,
  escalateToAdmin,
  markSafe,
  other,
}

/// Severity levels for moderation actions
enum ModerationSeverity {
  low,
  medium,
  high,
  critical,
}

/// Domain entity for moderation actions
class ModerationActionEntity {
  /// Unique identifier for the action
  final String id;
  
  /// Type of action taken
  final ModerationActionType actionType;
  
  /// ID of the user who performed the moderation action
  final String moderatorId;
  
  /// ID of the content or user being moderated
  final String targetId;
  
  /// Whether the target is a user (true) or content (false)
  final bool isUserTarget;
  
  /// Severity level of the action
  final ModerationSeverity severity;
  
  /// Related report IDs that led to this action
  final List<String> relatedReportIds;
  
  /// Reason/notes for the action
  final String notes;
  
  /// When the action was taken
  final DateTime createdAt;
  
  /// Expiration date for temporary actions (e.g., temporary bans)
  final DateTime? expiresAt;
  
  /// Whether the action is still active
  final bool isActive;
  
  /// Constructor
  const ModerationActionEntity({
    required this.id,
    required this.actionType,
    required this.moderatorId,
    required this.targetId,
    required this.isUserTarget,
    required this.severity,
    this.relatedReportIds = const [],
    required this.notes,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });
  
  /// Create a copy with modified fields
  ModerationActionEntity copyWith({
    String? id,
    ModerationActionType? actionType,
    String? moderatorId,
    String? targetId,
    bool? isUserTarget,
    ModerationSeverity? severity,
    List<String>? relatedReportIds,
    String? notes,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return ModerationActionEntity(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      moderatorId: moderatorId ?? this.moderatorId,
      targetId: targetId ?? this.targetId,
      isUserTarget: isUserTarget ?? this.isUserTarget,
      severity: severity ?? this.severity,
      relatedReportIds: relatedReportIds ?? this.relatedReportIds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }
  
  /// Check if the action is temporary
  bool get isTemporary => expiresAt != null;
  
  /// Check if the action has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  /// Check if the action is currently in effect
  bool get isInEffect => isActive && !isExpired;
  
  /// Get remaining duration for temporary actions
  Duration? get remainingDuration {
    if (expiresAt == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    
    return expiresAt!.difference(now);
  }
  
  /// Get a human-readable description of the action
  String getActionDescription() {
    String actionStr = '';
    switch (actionType) {
      case ModerationActionType.removeContent:
        actionStr = 'Content removed';
        break;
      case ModerationActionType.hideContent:
        actionStr = 'Content hidden';
        break;
      case ModerationActionType.warnUser:
        actionStr = 'User warned';
        break;
      case ModerationActionType.restrictUser:
        actionStr = 'User restricted';
        break;
      case ModerationActionType.banUser:
        actionStr = 'User banned';
        break;
      case ModerationActionType.escalateToAdmin:
        actionStr = 'Escalated to admin';
        break;
      case ModerationActionType.markSafe:
        actionStr = 'Marked as safe';
        break;
      case ModerationActionType.other:
        actionStr = 'Other action taken';
        break;
    }
    
    if (isTemporary) {
      actionStr += ' (temporary)';
    }
    
    if (isExpired) {
      actionStr += ' - expired';
    } else if (!isActive) {
      actionStr += ' - inactive';
    }
    
    return actionStr;
  }
  
  /// Get severity description
  String getSeverityDescription() {
    switch (severity) {
      case ModerationSeverity.low:
        return 'Low';
      case ModerationSeverity.medium:
        return 'Medium';
      case ModerationSeverity.high:
        return 'High';
      case ModerationSeverity.critical:
        return 'Critical';
    }
  }
} 