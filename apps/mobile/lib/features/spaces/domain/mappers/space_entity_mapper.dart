import 'package:flutter/material.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart' as entity;
import 'package:hive_ui/models/space_metrics.dart' as models;
import 'package:hive_ui/models/space_type.dart' as model_types;

/// Utility class to map between different space model representations
class SpaceEntityMapper {
  /// Convert a Club to a SpaceEntity
  static SpaceEntity fromClub(Club club) {
    // Map space type from club category
    final spaceType = _mapClubCategoryToSpaceType(club.category);
    
    // Create metrics entity
    final metrics = entity.SpaceMetricsEntity(
      spaceId: club.id,
      memberCount: club.memberCount,
      activeMembers: club.metrics['activeMembers'] as int? ?? 0,
      weeklyEvents: club.eventCount,
      monthlyEngagements: club.metrics['monthlyEngagements'] as int? ?? 0,
      lastActivity: club.updatedAt,
      hasNewContent: club.metrics['hasNewContent'] as bool? ?? false,
      isTrending: club.metrics['isTrending'] as bool? ?? false,
      activeMembers24h: const [],
      activityScores: const {},
      category: entity.SpaceCategory.suggested,
      size: _determineSpaceSize(club.memberCount),
      engagementScore: (club.metrics['engagementScore'] as num?)?.toDouble() ?? 0.0,
    );
    
    // Map icon to code point
    final iconCodePoint = club.icon.codePoint;
    
    return SpaceEntity(
      id: club.id,
      name: club.name,
      description: club.description,
      iconCodePoint: iconCodePoint,
      metrics: metrics,
      imageUrl: club.imageUrl ?? club.logoUrl,
      bannerUrl: club.bannerUrl,
      tags: [...club.tags],
      isPrivate: club.status.toLowerCase() == 'private',
      moderators: [], // Club model doesn't have moderators field
      admins: [], // Club model doesn't have admins field explicitly
      quickActions: {}, // Could map from club resources if needed
      relatedSpaceIds: club.affiliatedClubs,
      createdAt: club.createdAt,
      updatedAt: club.updatedAt,
      spaceType: spaceType,
      eventIds: [...club.upcomingEventIds, ...club.pastEventIds],
      hiveExclusive: club.isVerifiedPlus,
      customData: {
        'mission': club.mission,
        'vision': club.vision,
        'foundedYear': club.foundedYear,
        'socialLinks': club.socialLinks,
        'leaders': club.leaders,
        'isOfficial': club.isOfficial,
        'isUniversityDepartment': club.isUniversityDepartment,
        'meetingTimes': club.meetingTimes,
        'requirements': club.requirements,
        'resources': club.resources,
      },
    );
  }

  /// Convert a Space to a SpaceEntity
  static SpaceEntity fromSpace(Space space) {
    // Map SpaceType enum
    final spaceType = _mapModelSpaceTypeToEntitySpaceType(space.spaceType);
    
    // Create metrics entity from space metrics
    final metrics = entity.SpaceMetricsEntity(
      spaceId: space.id,
      memberCount: space.metrics.memberCount,
      activeMembers: space.metrics.activeMembers,
      weeklyEvents: space.metrics.weeklyEvents,
      monthlyEngagements: space.metrics.monthlyEngagements,
      lastActivity: space.metrics.lastActivity,
      hasNewContent: space.metrics.hasNewContent,
      isTrending: space.metrics.isTrending,
      activeMembers24h: space.metrics.activeMembers24h,
      activityScores: space.metrics.activityScores,
      category: _mapModelCategoryToEntityCategory(space.metrics.category),
      size: _mapModelSizeToEntitySize(space.metrics.size),
      engagementScore: space.metrics.engagementScore,
    );
    
    // Map icon to code point
    final iconCodePoint = space.icon.codePoint;
    
    return SpaceEntity(
      id: space.id,
      name: space.name,
      description: space.description,
      iconCodePoint: iconCodePoint,
      metrics: metrics,
      imageUrl: space.imageUrl,
      bannerUrl: space.bannerUrl,
      tags: [...space.tags],
      isJoined: space.isJoined,
      isPrivate: space.isPrivate,
      moderators: [...space.moderators],
      admins: [...space.admins],
      quickActions: {...space.quickActions},
      relatedSpaceIds: [...space.relatedSpaceIds],
      createdAt: space.createdAt,
      updatedAt: space.updatedAt,
      spaceType: spaceType,
      eventIds: [...space.eventIds],
      hiveExclusive: space.hiveExclusive,
      customData: {...space.customData},
    );
  }

  /// Convert a SpaceEntity to a Club
  static Club toClub(SpaceEntity entity) {
    // Create a generic icon based on space type
    IconData icon = _getIconForSpaceType(entity.spaceType);
    
    return Club(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      category: _spaceTypeToCategory(entity.spaceType),
      memberCount: entity.metrics.memberCount,
      status: entity.isPrivate ? 'private' : 'active',
      icon: icon,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      logoUrl: entity.imageUrl,
      bannerUrl: entity.bannerUrl,
      tags: entity.tags,
      eventCount: entity.metrics.weeklyEvents,
      isOfficial: entity.customData['isOfficial'] as bool? ?? false,
      mission: entity.customData['mission'] as String?,
      vision: entity.customData['vision'] as String?,
      foundedYear: entity.customData['foundedYear'] as int?,
      socialLinks: _extractSocialLinks(entity),
      leaders: _extractLeaders(entity),
      followersCount: entity.metrics.memberCount,
      upcomingEventIds: entity.eventIds.take(5).toList(), // Taking first 5 as upcoming
      pastEventIds: entity.eventIds.length > 5 ? entity.eventIds.sublist(5) : [],
      metrics: {
        'activeMembers': entity.metrics.activeMembers,
        'monthlyEngagements': entity.metrics.monthlyEngagements,
        'hasNewContent': entity.metrics.hasNewContent,
        'isTrending': entity.metrics.isTrending,
        'engagementScore': entity.metrics.engagementScore,
      },
      isUniversityDepartment: entity.customData['isUniversityDepartment'] as bool? ?? false,
      isVerifiedPlus: entity.hiveExclusive,
      affiliatedClubs: entity.relatedSpaceIds,
      meetingTimes: entity.customData['meetingTimes'] != null
          ? List<String>.from(entity.customData['meetingTimes'] as List)
          : [],
      requirements: entity.customData['requirements'] != null
          ? List<String>.from(entity.customData['requirements'] as List)
          : [],
      resources: entity.customData['resources'] != null
          ? Map<String, String>.from(entity.customData['resources'] as Map)
          : {},
    );
  }

  /// Convert a SpaceEntity to a Space
  static Space toSpace(SpaceEntity entity) {
    // Convert SpaceEntity's SpaceType to model's SpaceType
    final modelSpaceType = _mapEntitySpaceTypeToModelSpaceType(entity.spaceType);
    
    // Create SpaceMetrics from SpaceMetricsEntity
    final metrics = models.SpaceMetrics(
      spaceId: entity.metrics.spaceId,
      memberCount: entity.metrics.memberCount,
      activeMembers: entity.metrics.activeMembers,
      weeklyEvents: entity.metrics.weeklyEvents,
      monthlyEngagements: entity.metrics.monthlyEngagements,
      lastActivity: entity.metrics.lastActivity,
      hasNewContent: entity.metrics.hasNewContent,
      isTrending: entity.metrics.isTrending,
      activeMembers24h: entity.metrics.activeMembers24h,
      activityScores: entity.metrics.activityScores,
      category: _mapEntityCategoryToModelCategory(entity.metrics.category),
      size: _mapEntitySizeToModelSize(entity.metrics.size),
      engagementScore: entity.metrics.engagementScore,
    );
    
    return Space(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      metrics: metrics,
      imageUrl: entity.imageUrl,
      bannerUrl: entity.bannerUrl,
      tags: [...entity.tags],
      customData: {...entity.customData},
      isJoined: entity.isJoined,
      isPrivate: entity.isPrivate,
      moderators: [...entity.moderators],
      admins: [...entity.admins],
      quickActions: {...entity.quickActions},
      relatedSpaceIds: [...entity.relatedSpaceIds],
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      spaceType: modelSpaceType,
      eventIds: [...entity.eventIds],
      hiveExclusive: entity.hiveExclusive,
    );
  }

  // HELPER METHODS

  /// Map club category to SpaceType
  static SpaceType _mapClubCategoryToSpaceType(String category) {
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('student')) return SpaceType.studentOrg;
    if (lowerCategory.contains('universit') || lowerCategory.contains('academic')) return SpaceType.universityOrg;
    if (lowerCategory.contains('housing') || lowerCategory.contains('living')) return SpaceType.campusLiving;
    if (lowerCategory.contains('frat') || lowerCategory.contains('soror')) return SpaceType.fraternityAndSorority;
    if (lowerCategory.contains('exclusive') || lowerCategory.contains('hive')) return SpaceType.hiveExclusive;
    
    return SpaceType.other;
  }

  /// Map SpaceType to category string
  static String _spaceTypeToCategory(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return 'Student Organization';
      case SpaceType.universityOrg:
        return 'University Organization';
      case SpaceType.campusLiving:
        return 'Campus Living';
      case SpaceType.fraternityAndSorority:
        return 'Fraternity & Sorority';
      case SpaceType.hiveExclusive:
        return 'HIVE Exclusive';
      case SpaceType.organization:
        return 'Organization';
      case SpaceType.project:
        return 'Project';
      case SpaceType.event:
        return 'Event';
      case SpaceType.community:
        return 'Community';
      case SpaceType.other:
        return 'Other';
    }
  }

  /// Get appropriate icon for space type
  static IconData _getIconForSpaceType(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return Icons.group;
      case SpaceType.universityOrg:
        return Icons.school;
      case SpaceType.campusLiving:
        return Icons.home;
      case SpaceType.fraternityAndSorority:
        return Icons.people;
      case SpaceType.hiveExclusive:
        return Icons.verified;
      case SpaceType.organization:
        return Icons.business;
      case SpaceType.project:
        return Icons.assignment;
      case SpaceType.event:
        return Icons.event;
      case SpaceType.community:
        return Icons.forum;
      case SpaceType.other:
        return Icons.group;
    }
  }

  /// Determine space size based on member count
  static entity.SpaceSize _determineSpaceSize(int memberCount) {
    if (memberCount > 100) return entity.SpaceSize.large;
    if (memberCount > 30) return entity.SpaceSize.medium;
    return entity.SpaceSize.small;
  }

  /// Extract social links from entity's custom data
  static List<String> _extractSocialLinks(SpaceEntity entity) {
    if (entity.customData['socialLinks'] != null) {
      try {
        return List<String>.from(entity.customData['socialLinks'] as List);
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Extract leaders from entity's custom data
  static Map<String, String> _extractLeaders(SpaceEntity entity) {
    if (entity.customData['leaders'] != null) {
      try {
        return Map<String, String>.from(entity.customData['leaders'] as Map);
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  /// Map model SpaceType to entity SpaceType
  static SpaceType _mapModelSpaceTypeToEntitySpaceType(model_types.SpaceType type) {
    switch (type) {
      case model_types.SpaceType.studentOrg:
        return SpaceType.studentOrg;
      case model_types.SpaceType.universityOrg:
        return SpaceType.universityOrg;
      case model_types.SpaceType.campusLiving:
        return SpaceType.campusLiving;
      case model_types.SpaceType.fraternityAndSorority:
        return SpaceType.fraternityAndSorority;
      case model_types.SpaceType.hiveExclusive:
        return SpaceType.hiveExclusive;
      case model_types.SpaceType.other:
        return SpaceType.other;
    }
  }

  /// Map entity SpaceType to model SpaceType
  static model_types.SpaceType _mapEntitySpaceTypeToModelSpaceType(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return model_types.SpaceType.studentOrg;
      case SpaceType.universityOrg:
        return model_types.SpaceType.universityOrg;
      case SpaceType.campusLiving:
        return model_types.SpaceType.campusLiving;
      case SpaceType.fraternityAndSorority:
        return model_types.SpaceType.fraternityAndSorority;
      case SpaceType.hiveExclusive:
        return model_types.SpaceType.hiveExclusive;
      case SpaceType.organization:
      case SpaceType.project:
      case SpaceType.event:
      case SpaceType.community:
        return model_types.SpaceType.other;
      case SpaceType.other:
        return model_types.SpaceType.other;
    }
  }

  /// Map model SpaceCategory to entity SpaceCategory
  static entity.SpaceCategory _mapModelCategoryToEntityCategory(models.SpaceCategory category) {
    switch (category) {
      case models.SpaceCategory.active:
        return entity.SpaceCategory.active;
      case models.SpaceCategory.expanding:
        return entity.SpaceCategory.expanding;
      case models.SpaceCategory.emerging:
        return entity.SpaceCategory.emerging;
      case models.SpaceCategory.suggested:
        return entity.SpaceCategory.suggested;
    }
  }

  /// Map entity SpaceCategory to model SpaceCategory
  static models.SpaceCategory _mapEntityCategoryToModelCategory(entity.SpaceCategory category) {
    switch (category) {
      case entity.SpaceCategory.active:
        return models.SpaceCategory.active;
      case entity.SpaceCategory.expanding:
        return models.SpaceCategory.expanding;
      case entity.SpaceCategory.emerging:
        return models.SpaceCategory.emerging;
      case entity.SpaceCategory.suggested:
        return models.SpaceCategory.suggested;
    }
  }

  /// Map model SpaceSize to entity SpaceSize
  static entity.SpaceSize _mapModelSizeToEntitySize(models.SpaceSize size) {
    switch (size) {
      case models.SpaceSize.large:
        return entity.SpaceSize.large;
      case models.SpaceSize.medium:
        return entity.SpaceSize.medium;
      case models.SpaceSize.small:
        return entity.SpaceSize.small;
    }
  }

  /// Map entity SpaceSize to model SpaceSize
  static models.SpaceSize _mapEntitySizeToModelSize(entity.SpaceSize size) {
    switch (size) {
      case entity.SpaceSize.large:
        return models.SpaceSize.large;
      case entity.SpaceSize.medium:
        return models.SpaceSize.medium;
      case entity.SpaceSize.small:
        return models.SpaceSize.small;
    }
  }
} 