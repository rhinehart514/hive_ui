/// Domain entity for user restrictions in the moderation system
class UserRestrictionEntity {
  /// Unique identifier for the restriction record
  final String id;
  
  /// ID of the restricted user
  final String userId;
  
  /// Whether the user is currently restricted
  final bool isActive;
  
  /// Reason for the restriction
  final String reason;
  
  /// ID of the moderator who applied the restriction
  final String restrictedBy;
  
  /// When the restriction was created
  final DateTime createdAt;
  
  /// When the restriction will end (null for permanent restrictions)
  final DateTime? expiresAt;
  
  /// Additional notes or context about the restriction
  final String? notes;
  
  /// History of previous restrictions for this user
  final List<PreviousRestriction>? restrictionHistory;
  
  /// Constructor
  const UserRestrictionEntity({
    required this.id,
    required this.userId,
    required this.isActive,
    required this.reason,
    required this.restrictedBy,
    required this.createdAt,
    this.expiresAt,
    this.notes,
    this.restrictionHistory,
  });
  
  /// Create a copy with modified fields
  UserRestrictionEntity copyWith({
    String? id,
    String? userId,
    bool? isActive,
    String? reason,
    String? restrictedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? notes,
    List<PreviousRestriction>? restrictionHistory,
  }) {
    return UserRestrictionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      reason: reason ?? this.reason,
      restrictedBy: restrictedBy ?? this.restrictedBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      notes: notes ?? this.notes,
      restrictionHistory: restrictionHistory ?? this.restrictionHistory,
    );
  }
  
  /// Check if the restriction is temporary
  bool get isTemporary => expiresAt != null;
  
  /// Check if the restriction has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  /// Check if the restriction is currently in effect
  bool get isCurrentlyRestricted => isActive && !isExpired;
  
  /// Get remaining duration for temporary restrictions
  Duration? get remainingDuration {
    if (expiresAt == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    
    return expiresAt!.difference(now);
  }
  
  /// Get user-friendly description of the restriction status
  String getStatusDescription() {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isTemporary) {
      final days = remainingDuration!.inDays;
      if (days > 0) {
        return 'Restricted for $days more days';
      } else {
        final hours = remainingDuration!.inHours;
        return 'Restricted for $hours more hours';
      }
    }
    return 'Permanently restricted';
  }
}

/// Class to represent previous restrictions in the user history
class PreviousRestriction {
  /// When the restriction was created
  final DateTime createdAt;
  
  /// When the restriction ended (if applicable)
  final DateTime? endedAt;
  
  /// Reason for the restriction
  final String reason;
  
  /// ID of the moderator who applied the restriction
  final String restrictedBy;
  
  /// ID of the moderator who removed the restriction (if applicable)
  final String? removedBy;
  
  /// Reason for removing the restriction (if applicable)
  final String? removalReason;
  
  /// Constructor
  const PreviousRestriction({
    required this.createdAt,
    this.endedAt,
    required this.reason,
    required this.restrictedBy,
    this.removedBy,
    this.removalReason,
  });
  
  /// Create a copy with modified fields
  PreviousRestriction copyWith({
    DateTime? createdAt,
    DateTime? endedAt,
    String? reason,
    String? restrictedBy,
    String? removedBy,
    String? removalReason,
  }) {
    return PreviousRestriction(
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      reason: reason ?? this.reason,
      restrictedBy: restrictedBy ?? this.restrictedBy,
      removedBy: removedBy ?? this.removedBy,
      removalReason: removalReason ?? this.removalReason,
    );
  }
  
  /// Duration of the restriction
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(createdAt);
  }
  
  /// Whether the restriction was removed early
  bool get wasRemovedEarly => removedBy != null;
} 