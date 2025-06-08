import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Model for moderation actions in the data layer
class ModerationActionModel {
  /// Unique identifier for the action
  final String id;
  
  /// Type of action taken
  final ModerationActionType actionType;
  
  /// ID of the user who performed the moderation action
  final String moderatorId;
  
  /// ID of the content or user being moderated
  final String targetId;
  
  /// Whether the target is content or a user
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
  ModerationActionModel({
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
  ModerationActionModel copyWith({
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
    return ModerationActionModel(
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
  
  /// Create from Firestore document
  factory ModerationActionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse action type
    final actionTypeStr = data['actionType'] as String? ?? 'other';
    final actionType = ModerationActionType.values.firstWhere(
      (e) => e.toString().split('.').last == actionTypeStr,
      orElse: () => ModerationActionType.other,
    );
    
    // Parse severity
    final severityStr = data['severity'] as String? ?? 'medium';
    final severity = ModerationSeverity.values.firstWhere(
      (e) => e.toString().split('.').last == severityStr,
      orElse: () => ModerationSeverity.medium,
    );
    
    return ModerationActionModel(
      id: doc.id,
      actionType: actionType,
      moderatorId: data['moderatorId'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      isUserTarget: data['isUserTarget'] as bool? ?? false,
      severity: severity,
      relatedReportIds: List<String>.from(data['relatedReportIds'] ?? []),
      notes: data['notes'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'actionType': actionType.toString().split('.').last,
      'moderatorId': moderatorId,
      'targetId': targetId,
      'isUserTarget': isUserTarget,
      'severity': severity.toString().split('.').last,
      'relatedReportIds': relatedReportIds,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
    };
  }
} 