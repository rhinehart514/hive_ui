/// Types of visibility boosts that can be applied to content
enum BoostType {
  /// Standard boost (temporary visibility increase)
  standard,
  
  /// Honey Mode (premium monthly boost)
  honeyMode,
  
  /// Administrative boost
  admin,
}

/// Entity representing a visibility boost for content
class VisibilityBoostEntity {
  /// Unique identifier for the boost
  final String id;
  
  /// The content ID being boosted
  final String contentId;
  
  /// Type of content being boosted
  final String contentType;
  
  /// The Space ID that owns this content 
  final String spaceId;
  
  /// The user who applied the boost
  final String appliedByUserId;
  
  /// The boost type (standard, honey mode, admin)
  final BoostType boostType;
  
  /// Timestamp when boost was applied
  final DateTime appliedAt;
  
  /// When the boost expires
  final DateTime expiresAt;
  
  /// Additional boost magnitude (multiplier)
  final double magnitude;
  
  /// Justification or reason for the boost
  final String? justification;
  
  /// Is the boost currently active
  final bool isActive;
  
  /// Constructor
  const VisibilityBoostEntity({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.spaceId,
    required this.appliedByUserId,
    required this.boostType,
    required this.appliedAt,
    required this.expiresAt,
    required this.magnitude,
    this.justification,
    required this.isActive,
  });
  
  /// Create a copy with modified fields
  VisibilityBoostEntity copyWith({
    String? id,
    String? contentId,
    String? contentType,
    String? spaceId,
    String? appliedByUserId,
    BoostType? boostType, 
    DateTime? appliedAt,
    DateTime? expiresAt,
    double? magnitude,
    String? justification,
    bool? isActive,
  }) {
    return VisibilityBoostEntity(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      spaceId: spaceId ?? this.spaceId,
      appliedByUserId: appliedByUserId ?? this.appliedByUserId,
      boostType: boostType ?? this.boostType,
      appliedAt: appliedAt ?? this.appliedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      magnitude: magnitude ?? this.magnitude,
      justification: justification ?? this.justification,
      isActive: isActive ?? this.isActive,
    );
  }
  
  /// Is the boost currently expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// Get the remaining duration of the boost
  Duration get remainingDuration {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }
  
  /// Get the total duration of the boost
  Duration get totalDuration => expiresAt.difference(appliedAt);
  
  /// Get boost score to be added to feed item score
  double getBoostScore() {
    // If expired or inactive, no boost
    if (isExpired || !isActive) return 0.0;
    
    // Base score by boost type
    double baseScore;
    switch (boostType) {
      case BoostType.standard:
        baseScore = 300.0;
        break;
      case BoostType.honeyMode:
        baseScore = 500.0;
        break;
      case BoostType.admin:
        baseScore = 1000.0;
        break;
    }
    
    // Apply magnitude multiplier
    return baseScore * magnitude;
  }
}

/// Entity for tracking Space boost quotas and usage
class SpaceBoostQuotaEntity {
  /// Space identifier
  final String spaceId;
  
  /// Quota period start date
  final DateTime periodStartDate;
  
  /// Quota period end date
  final DateTime periodEndDate;
  
  /// Total standard boosts allowed in this period
  final int standardBoostQuota;
  
  /// Standard boosts used in this period
  final int standardBoostsUsed;
  
  /// Is Honey Mode available in this period
  final bool honeyModeAvailable;
  
  /// Has Honey Mode been used this period
  final bool honeyModeUsed;
  
  /// When Honey Mode was last used
  final DateTime? lastHoneyModeUse;
  
  /// Constructor
  const SpaceBoostQuotaEntity({
    required this.spaceId,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.standardBoostQuota,
    required this.standardBoostsUsed,
    required this.honeyModeAvailable,
    required this.honeyModeUsed,
    this.lastHoneyModeUse,
  });
  
  /// Create a copy with modified fields
  SpaceBoostQuotaEntity copyWith({
    String? spaceId,
    DateTime? periodStartDate,
    DateTime? periodEndDate,
    int? standardBoostQuota,
    int? standardBoostsUsed,
    bool? honeyModeAvailable,
    bool? honeyModeUsed,
    DateTime? lastHoneyModeUse,
  }) {
    return SpaceBoostQuotaEntity(
      spaceId: spaceId ?? this.spaceId,
      periodStartDate: periodStartDate ?? this.periodStartDate,
      periodEndDate: periodEndDate ?? this.periodEndDate,
      standardBoostQuota: standardBoostQuota ?? this.standardBoostQuota,
      standardBoostsUsed: standardBoostsUsed ?? this.standardBoostsUsed,
      honeyModeAvailable: honeyModeAvailable ?? this.honeyModeAvailable,
      honeyModeUsed: honeyModeUsed ?? this.honeyModeUsed,
      lastHoneyModeUse: lastHoneyModeUse ?? this.lastHoneyModeUse,
    );
  }
  
  /// Get remaining standard boosts
  int get remainingStandardBoosts => standardBoostQuota - standardBoostsUsed;
  
  /// Is the quota period active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(periodStartDate) && now.isBefore(periodEndDate);
  }
  
  /// Can the space use Honey Mode now
  bool get canUseHoneyMode {
    if (!honeyModeAvailable || honeyModeUsed) return false;
    
    // If Honey Mode has never been used before or was used in a previous period
    if (lastHoneyModeUse == null) return true;
    
    // Check if last use was in the current period
    return !lastHoneyModeUse!.isAfter(periodStartDate) && 
           !lastHoneyModeUse!.isBefore(periodEndDate);
  }
}

/// Entity for Honey Mode content enrichment requirements
class HoneyModeRequirementsEntity {
  /// Minimum image count required
  final int minimumImageCount;
  
  /// Minimum description length
  final int minimumDescriptionLength;
  
  /// Is a location required
  final bool requiresLocation;
  
  /// Is a call-to-action required
  final bool requiresCallToAction;
  
  /// Disallowed content types 
  final List<String> disallowedContentTypes;
  
  /// Constructor
  const HoneyModeRequirementsEntity({
    required this.minimumImageCount,
    required this.minimumDescriptionLength,
    required this.requiresLocation,
    required this.requiresCallToAction,
    required this.disallowedContentTypes,
  });
  
  /// Validate if content meets Honey Mode requirements
  bool validateContent({
    required int imageCount,
    required int descriptionLength,
    required bool hasLocation,
    required bool hasCallToAction,
    required String contentType,
  }) {
    // Check if content type is allowed
    if (disallowedContentTypes.contains(contentType)) {
      return false;
    }
    
    // Check all requirements
    return imageCount >= minimumImageCount &&
           descriptionLength >= minimumDescriptionLength &&
           (!requiresLocation || hasLocation) &&
           (!requiresCallToAction || hasCallToAction);
  }
} 