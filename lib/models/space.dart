import 'package:flutter/material.dart';
import 'package:hive_ui/models/organization.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class Space {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String? imageUrl;
  final String? bannerUrl;
  final SpaceMetrics metrics;
  final Organization? organization;
  final List<String> tags;
  final Map<String, dynamic> customData;
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

  const Space({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.metrics,
    this.imageUrl,
    this.bannerUrl,
    this.organization,
    this.tags = const [],
    this.customData = const {},
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
  });

  factory Space.fromOrganization(Organization org,
      {SpaceMetrics? metrics, SpaceType? spaceType}) {
    return Space(
      id: org.id,
      name: org.name,
      description: org.description,
      icon: org.icon,
      imageUrl: org.imageUrl,
      bannerUrl: org.bannerUrl,
      metrics: metrics ?? SpaceMetrics.initial(org.id),
      organization: org,
      tags: [...org.categories, ...org.tags],
      createdAt: org.createdAt,
      updatedAt: org.updatedAt,
      spaceType: spaceType ?? SpaceType.other,
    );
  }

  /// Convert Space from JSON
  factory Space.fromJson(Map<String, dynamic> json) {
    // Parse metrics
    SpaceMetrics metrics = SpaceMetrics.empty();
    if (json['metrics'] != null) {
      try {
        metrics =
            SpaceMetrics.fromJson(json['metrics'] as Map<String, dynamic>);
      } catch (e) {
        metrics = SpaceMetrics.initial(json['id'] as String);
      }
    } else {
      metrics = SpaceMetrics.initial(json['id'] as String);
    }

    // Parse organization if available
    Organization? organization;
    if (json['organization'] != null) {
      try {
        organization =
            Organization.fromJson(json['organization'] as Map<String, dynamic>);
      } catch (e) {
        // Ignore parsing errors for organization
      }
    }

    // Parse dates
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        createdAt = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
      } else if (json['createdAt'] is String) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    }

    DateTime updatedAt = DateTime.now();
    if (json['updatedAt'] != null) {
      if (json['updatedAt'] is Timestamp) {
        updatedAt = (json['updatedAt'] as Timestamp).toDate();
      } else if (json['updatedAt'] is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(json['updatedAt']);
      } else if (json['updatedAt'] is String) {
        updatedAt = DateTime.parse(json['updatedAt']);
      }
    }

    // Parse icon
    IconData icon = Icons.group;
    if (json['icon'] != null) {
      if (json['icon'] is int) {
        // Use predefined Material icons instead of creating new IconData
        final int codePoint = json['icon'] as int;
        switch (codePoint) {
          case 0xe318:
            icon = Icons.group;
            break;
          case 0xe1a5:
            icon = Icons.business;
            break;
          case 0xe332:
            icon = Icons.home;
            break;
          case 0xe30e:
            icon = Icons.forum;
            break;
          case 0xe0c9:
            icon = Icons.computer;
            break;
          case 0xe8f8:
            icon = Icons.school;
            break;
          case 0xe3ab:
            icon = Icons.people;
            break;
          case 0xe639:
            icon = Icons.sports;
            break;
          case 0xe430:
            icon = Icons.music_note;
            break;
          case 0xe40a:
            icon = Icons.palette;
            break;
          case 0xe465:
            icon = Icons.science;
            break;
          default:
            icon = Icons.group;
            break;
        }
      }
    }

    // Parse space type
    SpaceType spaceType = SpaceType.other;
    if (json['spaceType'] != null) {
      final spaceTypeStr = json['spaceType'].toString().toLowerCase();
      if (spaceTypeStr.contains('student')) {
        spaceType = SpaceType.studentOrg;
      } else if (spaceTypeStr.contains('universit')) {
        spaceType = SpaceType.universityOrg;
      } else if (spaceTypeStr.contains('living')) {
        spaceType = SpaceType.campusLiving;
      } else if (spaceTypeStr.contains('frat') ||
          spaceTypeStr.contains('soror')) {
        spaceType = SpaceType.fraternityAndSorority;
      }
    }

    // Safely parse list fields to prevent type errors
    List<String> parseTags() {
      if (json['tags'] == null) return const [];
      if (json['tags'] is List) {
        try {
          return List<String>.from(json['tags'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseModerators() {
      if (json['moderators'] == null) return const [];
      if (json['moderators'] is List) {
        try {
          return List<String>.from(json['moderators'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseAdmins() {
      if (json['admins'] == null) return const [];
      if (json['admins'] is List) {
        try {
          return List<String>.from(json['admins'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseRelatedSpaceIds() {
      if (json['relatedSpaceIds'] == null) return const [];
      if (json['relatedSpaceIds'] is List) {
        try {
          return List<String>.from(json['relatedSpaceIds'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseEventIds() {
      if (json['eventIds'] == null) return const [];
      if (json['eventIds'] is List) {
        try {
          return List<String>.from(json['eventIds'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    // Parse custom data safely
    Map<String, dynamic> parseCustomData() {
      if (json['customData'] == null) return const {};
      if (json['customData'] is Map) {
        try {
          return Map<String, dynamic>.from(json['customData'] as Map);
        } catch (e) {
          return const {};
        }
      }
      return const {};
    }

    // Parse quickActions safely
    Map<String, String> parseQuickActions() {
      if (json['quickActions'] == null) return const {};
      if (json['quickActions'] is Map) {
        try {
          return Map<String, String>.from(json['quickActions'] as Map);
        } catch (e) {
          return const {};
        }
      }
      return const {};
    }

    return Space(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: icon,
      imageUrl: json['imageUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      metrics: metrics,
      organization: organization,
      tags: parseTags(),
      customData: parseCustomData(),
      isJoined: json['isJoined'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
      moderators: parseModerators(),
      admins: parseAdmins(),
      quickActions: parseQuickActions(),
      relatedSpaceIds: parseRelatedSpaceIds(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      spaceType: spaceType,
      eventIds: parseEventIds(),
      hiveExclusive: json['hiveExclusive'] as bool? ?? false,
    );
  }

  /// Convert Space to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon.codePoint,
      'imageUrl': imageUrl,
      'bannerUrl': bannerUrl,
      'metrics': metrics.toJson(),
      'organization': organization?.toJson(),
      'tags': tags,
      'customData': customData,
      'isJoined': isJoined,
      'isPrivate': isPrivate,
      'moderators': moderators,
      'admins': admins,
      'quickActions': quickActions,
      'relatedSpaceIds': relatedSpaceIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'spaceType': spaceType.toString().split('.').last,
      'eventIds': eventIds,
      'hiveExclusive': hiveExclusive,
    };
  }

  Space copyWith({
    String? name,
    String? description,
    IconData? icon,
    String? imageUrl,
    String? bannerUrl,
    SpaceMetrics? metrics,
    Organization? organization,
    List<String>? tags,
    Map<String, dynamic>? customData,
    bool? isJoined,
    bool? isPrivate,
    List<String>? moderators,
    List<String>? admins,
    Map<String, String>? quickActions,
    List<String>? relatedSpaceIds,
    DateTime? updatedAt,
    SpaceType? spaceType,
    List<String>? eventIds,
    bool? hiveExclusive,
  }) {
    return Space(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      metrics: metrics ?? this.metrics,
      organization: organization ?? this.organization,
      tags: tags ?? this.tags,
      customData: customData ?? this.customData,
      isJoined: isJoined ?? this.isJoined,
      isPrivate: isPrivate ?? this.isPrivate,
      moderators: moderators ?? this.moderators,
      admins: admins ?? this.admins,
      quickActions: quickActions ?? this.quickActions,
      relatedSpaceIds: relatedSpaceIds ?? this.relatedSpaceIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spaceType: spaceType ?? this.spaceType,
      eventIds: eventIds ?? this.eventIds,
      hiveExclusive: hiveExclusive ?? this.hiveExclusive,
    );
  }

  /// Get the appropriate color scheme for this space
  Color get primaryColor {
    if (organization != null) {
      return organization!.avatarColor;
    }

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

  /// Get the next action prompt for this space
  String? get nextActionPrompt {
    if (metrics.needsIntroduction) {
      return 'Introduce yourself to the community';
    }
    if (metrics.hasNewContent) {
      return 'Check out what\'s new';
    }
    if (metrics.weeklyEvents > 0) {
      return 'See upcoming events';
    }
    if (metrics.connectedFriends.isNotEmpty) {
      return '${metrics.connectedFriends.length} friends are active here';
    }
    return metrics.firstActionPrompt;
  }

  /// Get the appropriate call-to-action for this space
  String get callToAction {
    if (!isJoined) return 'Join Space';
    if (metrics.hasNewContent) return 'View Updates';
    if (metrics.weeklyEvents > 0) return 'View Events';
    return 'Open Space';
  }

  /// Check if the space needs attention
  bool get needsAttention {
    return metrics.hasNewContent ||
        metrics.isTrending ||
        metrics.connectedFriends.isNotEmpty;
  }

  /// Get the appropriate size for the space tile
  Size getTileSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseSize = (screenWidth - 48) / 2; // Account for padding

    switch (metrics.size) {
      case SpaceSize.large:
        return Size(baseSize * 2 + 16, baseSize); // Full width
      case SpaceSize.medium:
        return Size(baseSize, baseSize); // Half width
      case SpaceSize.small:
        return Size(baseSize, baseSize * 0.75); // Compact height
    }
  }
}
