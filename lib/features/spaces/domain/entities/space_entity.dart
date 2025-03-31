import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';

/// SpaceType represents the category or type of space
enum SpaceType {
  studentOrg,
  universityOrg,
  campusLiving,
  fraternityAndSorority,
  other
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
    );
  }
}
