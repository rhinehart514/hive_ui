import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart' as legacy_metrics;
import 'package:hive_ui/models/space_type.dart' as legacy_type;

/// Utility class for converting between legacy models and domain entities
class SpaceModelConverters {
  /// Convert legacy SpaceMetrics to SpaceMetricsEntity
  static SpaceMetricsEntity convertLegacyMetricsToEntity(legacy_metrics.SpaceMetrics legacyMetrics) {
    return SpaceMetricsEntity(
      spaceId: legacyMetrics.spaceId,
      memberCount: legacyMetrics.memberCount,
      activeMembers: legacyMetrics.activeMembers,
      weeklyEvents: legacyMetrics.weeklyEvents,
      monthlyEngagements: legacyMetrics.monthlyEngagements,
      lastActivity: legacyMetrics.lastActivity,
      hasNewContent: legacyMetrics.hasNewContent,
      isTrending: legacyMetrics.isTrending,
      activeMembers24h: legacyMetrics.activeMembers24h,
      activityScores: legacyMetrics.activityScores,
      category: _convertLegacyCategory(legacyMetrics.category),
      size: _convertLegacySize(legacyMetrics.size),
      engagementScore: legacyMetrics.engagementScore,
      isTimeSensitive: legacyMetrics.isTimeSensitive,
      expiryDate: legacyMetrics.expiryDate,
      connectedFriends: legacyMetrics.connectedFriends,
      firstActionPrompt: legacyMetrics.firstActionPrompt,
      needsIntroduction: legacyMetrics.needsIntroduction,
    );
  }

  /// Convert legacy Space to SpaceEntity
  static SpaceEntity convertLegacySpaceToEntity(Space legacySpace) {
    return SpaceEntity(
      id: legacySpace.id,
      name: legacySpace.name,
      description: legacySpace.description,
      iconCodePoint: legacySpace.icon.codePoint,
      imageUrl: legacySpace.imageUrl,
      bannerUrl: legacySpace.bannerUrl,
      metrics: convertLegacyMetricsToEntity(legacySpace.metrics),
      tags: legacySpace.tags,
      isJoined: legacySpace.isJoined,
      isPrivate: legacySpace.isPrivate,
      moderators: legacySpace.moderators,
      admins: legacySpace.admins,
      quickActions: legacySpace.quickActions,
      relatedSpaceIds: legacySpace.relatedSpaceIds,
      createdAt: legacySpace.createdAt,
      updatedAt: legacySpace.updatedAt,
      spaceType: _convertLegacySpaceType(legacySpace.spaceType),
      eventIds: legacySpace.eventIds,
      hiveExclusive: legacySpace.hiveExclusive,
    );
  }

  /// Convert legacy SpaceCategory to domain SpaceCategory
  static SpaceCategory _convertLegacyCategory(legacy_metrics.SpaceCategory legacyCategory) {
    switch (legacyCategory) {
      case legacy_metrics.SpaceCategory.active:
        return SpaceCategory.active;
      case legacy_metrics.SpaceCategory.expanding:
        return SpaceCategory.expanding;
      case legacy_metrics.SpaceCategory.emerging:
        return SpaceCategory.emerging;
      case legacy_metrics.SpaceCategory.suggested:
        return SpaceCategory.suggested;
      default:
        return SpaceCategory.suggested;
    }
  }

  /// Convert legacy SpaceSize to domain SpaceSize
  static SpaceSize _convertLegacySize(legacy_metrics.SpaceSize legacySize) {
    switch (legacySize) {
      case legacy_metrics.SpaceSize.large:
        return SpaceSize.large;
      case legacy_metrics.SpaceSize.medium:
        return SpaceSize.medium;
      case legacy_metrics.SpaceSize.small:
        return SpaceSize.small;
      default:
        return SpaceSize.small;
    }
  }

  /// Convert legacy SpaceType to domain SpaceType
  static SpaceType _convertLegacySpaceType(legacy_type.SpaceType legacyType) {
    switch (legacyType) {
      case legacy_type.SpaceType.studentOrg:
        return SpaceType.studentOrg;
      case legacy_type.SpaceType.universityOrg:
        return SpaceType.universityOrg;
      case legacy_type.SpaceType.campusLiving:
        return SpaceType.campusLiving;
      case legacy_type.SpaceType.fraternityAndSorority:
        return SpaceType.fraternityAndSorority;
      case legacy_type.SpaceType.hiveExclusive:
        return SpaceType.hiveExclusive;
      case legacy_type.SpaceType.other:
        return SpaceType.other;
      default:
        return SpaceType.other;
    }
  }
} 