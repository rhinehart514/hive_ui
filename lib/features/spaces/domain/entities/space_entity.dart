import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';

/// SpaceType represents the category or type of space
enum SpaceType {
  studentOrg,
  universityOrg,
  campusLiving,
  fraternityAndSorority,
  hiveExclusive,
  other,
  organization,
  project,
  event,
  community
}

/// Represents the lifecycle state of a space
enum SpaceLifecycleState {
  /// Space has been created but has little or no activity
  created,
  
  /// Space has regular activity and engagement
  active,
  
  /// Space has no activity for 30+ days
  dormant,
  
  /// Space has been archived (manually or due to long inactivity)
  archived,
}

/// Represents the claim status of a space
enum SpaceClaimStatus {
  /// Space is unclaimed (no leader)
  unclaimed,
  
  /// Claim is pending verification
  pending,
  
  /// Space has been claimed by a verified leader
  claimed,
  
  /// Space doesn't require a claim (HIVE-exclusive)
  notRequired,
}

/// Entity representing a Space in the domain layer
class SpaceEntity {
  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final String? imageUrl;
  final String? bannerUrl;
  final SpaceMetricsEntity metrics;
  final List<String> tags;
  final bool isJoined;
  final bool isPrivate;
  final List<String> moderators;
  final List<String> admins;
  final Map<String, String> quickActions;
  final List<String> relatedSpaceIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SpaceType spaceType;
  final List<String> eventIds;
  final bool hiveExclusive;
  final Map<String, dynamic> customData;
  final bool hasMessageBoard;
  final SpaceLifecycleState lifecycleState;
  final SpaceClaimStatus claimStatus;
  final String? claimId;
  final DateTime? lastActivityAt;
  final bool isFeatured;

  const SpaceEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.metrics,
    this.imageUrl,
    this.bannerUrl,
    this.tags = const [],
    this.isJoined = false,
    this.isPrivate = false,
    this.moderators = const [],
    this.admins = const [],
    this.quickActions = const {},
    this.relatedSpaceIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.spaceType = SpaceType.other,
    this.eventIds = const [],
    this.hiveExclusive = false,
    this.customData = const {},
    this.hasMessageBoard = true,
    this.lifecycleState = SpaceLifecycleState.active,
    this.claimStatus = SpaceClaimStatus.notRequired,
    this.claimId,
    this.lastActivityAt,
    this.isFeatured = false,
  });

  /// Returns the icon data for this space
  IconData get icon => IconData(
        iconCodePoint,
        fontFamily: 'MaterialIcons',
      );

  /// Get the appropriate color for this space based on its name
  Color get primaryColor {
    // Default color scheme based on name hash
    final hash = name.hashCode.abs();
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }

  /// Get the appropriate background gradient for this space
  List<Color> get gradientColors {
    final base = primaryColor;
    return [
      base,
      base.withOpacity(0.8),
      base.withOpacity(0.6),
    ];
  }
  
  /// Check if the space is a pre-seeded space
  bool get isPreSeeded {
    return !hiveExclusive && 
        spaceType != SpaceType.hiveExclusive && 
        spaceType != SpaceType.other;
  }
  
  /// Check if the space requires a leadership claim
  bool get requiresLeadershipClaim {
    return isPreSeeded;
  }
  
  /// Check if the space is inactive
  bool get isInactive {
    if (lastActivityAt == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastActivityAt!);
    
    return difference.inDays > 30;
  }
  
  /// Get a human-readable description of the lifecycle state
  String get lifecycleStateDescription {
    switch (lifecycleState) {
      case SpaceLifecycleState.created:
        return 'Getting Started';
      case SpaceLifecycleState.active:
        return 'Active';
      case SpaceLifecycleState.dormant:
        return 'Inactive';
      case SpaceLifecycleState.archived:
        return 'Archived';
    }
  }
  
  /// Get a human-readable description of the claim status
  String get claimStatusDescription {
    switch (claimStatus) {
      case SpaceClaimStatus.unclaimed:
        return 'Unclaimed';
      case SpaceClaimStatus.pending:
        return 'Claim Pending';
      case SpaceClaimStatus.claimed:
        return 'Claimed';
      case SpaceClaimStatus.notRequired:
        return '';
    }
  }
  
  /// Creates a copy of this SpaceEntity with the given fields replaced with new values
  SpaceEntity copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCodePoint,
    String? imageUrl,
    String? bannerUrl,
    SpaceMetricsEntity? metrics,
    List<String>? tags,
    bool? isJoined,
    bool? isPrivate,
    List<String>? moderators,
    List<String>? admins,
    Map<String, String>? quickActions,
    List<String>? relatedSpaceIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    SpaceType? spaceType,
    List<String>? eventIds,
    bool? hiveExclusive,
    Map<String, dynamic>? customData,
    bool? hasMessageBoard,
    SpaceLifecycleState? lifecycleState,
    SpaceClaimStatus? claimStatus,
    String? claimId,
    DateTime? lastActivityAt,
    bool? isFeatured,
  }) {
    return SpaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      metrics: metrics ?? this.metrics,
      tags: tags ?? this.tags,
      isJoined: isJoined ?? this.isJoined,
      isPrivate: isPrivate ?? this.isPrivate,
      moderators: moderators ?? this.moderators,
      admins: admins ?? this.admins,
      quickActions: quickActions ?? this.quickActions,
      relatedSpaceIds: relatedSpaceIds ?? this.relatedSpaceIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spaceType: spaceType ?? this.spaceType,
      eventIds: eventIds ?? this.eventIds,
      hiveExclusive: hiveExclusive ?? this.hiveExclusive,
      customData: customData ?? this.customData,
      hasMessageBoard: hasMessageBoard ?? this.hasMessageBoard,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      claimStatus: claimStatus ?? this.claimStatus,
      claimId: claimId ?? this.claimId,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
  
  /// Update the space's lifecycle state based on activity
  SpaceEntity updateLifecycleState() {
    if (lifecycleState == SpaceLifecycleState.archived) {
      // Archived spaces stay archived unless manually changed
      return this;
    }
    
    if (lastActivityAt == null) {
      // No activity data, default to created if new or active if it has events
      return copyWith(
        lifecycleState: eventIds.isEmpty ? 
            SpaceLifecycleState.created : 
            SpaceLifecycleState.active
      );
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastActivityAt!);
    
    if (difference.inDays > 180) {
      // Auto-archive after 6 months of inactivity
      return copyWith(lifecycleState: SpaceLifecycleState.archived);
    } else if (difference.inDays > 30) {
      // Dormant after 1 month of inactivity
      return copyWith(lifecycleState: SpaceLifecycleState.dormant);
    } else {
      // Otherwise active
      return copyWith(lifecycleState: SpaceLifecycleState.active);
    }
  }
}
