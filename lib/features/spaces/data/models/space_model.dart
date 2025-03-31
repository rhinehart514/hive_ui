import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/data/models/space_metrics_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// Data model representing a Space, corresponds to the Space entity in the domain layer
class SpaceModel {
  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final String? imageUrl;
  final String? bannerUrl;
  final SpaceMetricsModel metrics;
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

  SpaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.metrics,
    this.imageUrl,
    this.bannerUrl,
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

  /// Convert to domain entity
  SpaceEntity toEntity() {
    return SpaceEntity(
      id: id,
      name: name,
      description: description,
      iconCodePoint: iconCodePoint,
      imageUrl: imageUrl,
      bannerUrl: bannerUrl,
      metrics: metrics.toEntity(),
      tags: tags,
      isJoined: isJoined,
      isPrivate: isPrivate,
      moderators: moderators,
      admins: admins,
      quickActions: quickActions,
      relatedSpaceIds: relatedSpaceIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      spaceType: spaceType,
      eventIds: eventIds,
      customData: customData,
      hiveExclusive: hiveExclusive,
    );
  }

  /// Create from Firestore document
  factory SpaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse dates
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      }
    }

    DateTime updatedAt = DateTime.now();
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(data['updatedAt']);
      } else if (data['updatedAt'] is String) {
        updatedAt = DateTime.parse(data['updatedAt']);
      }
    }

    // Parse icon
    int iconCodePoint = Icons.group.codePoint;
    if (data['icon'] != null) {
      if (data['icon'] is int) {
        iconCodePoint = data['icon'];
      }
    }

    // Parse space type
    SpaceType spaceType = SpaceType.other;
    if (data['spaceType'] != null) {
      final spaceTypeStr = data['spaceType'].toString().toLowerCase();
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

    // Parse metrics
    SpaceMetricsModel metrics;
    if (data['metrics'] != null) {
      try {
        metrics = SpaceMetricsModel.fromJson(
            data['metrics'] as Map<String, dynamic>, doc.id);
      } catch (e) {
        metrics = SpaceMetricsModel.initial(doc.id);
      }
    } else {
      metrics = SpaceMetricsModel.initial(doc.id);
    }

    // Safely parse list fields
    List<String> parseTags() {
      if (data['tags'] == null) return const [];
      if (data['tags'] is List) {
        try {
          return List<String>.from(data['tags'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseModerators() {
      if (data['moderators'] == null) return const [];
      if (data['moderators'] is List) {
        try {
          return List<String>.from(data['moderators'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseAdmins() {
      if (data['admins'] == null) return const [];
      if (data['admins'] is List) {
        try {
          return List<String>.from(data['admins'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseRelatedSpaceIds() {
      if (data['relatedSpaceIds'] == null) return const [];
      if (data['relatedSpaceIds'] is List) {
        try {
          return List<String>.from(data['relatedSpaceIds'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    List<String> parseEventIds() {
      if (data['eventIds'] == null) return const [];
      if (data['eventIds'] is List) {
        try {
          return List<String>.from(data['eventIds'] as List);
        } catch (e) {
          return const [];
        }
      }
      return const [];
    }

    // Parse custom data safely
    Map<String, dynamic> parseCustomData() {
      if (data['customData'] == null) return const {};
      if (data['customData'] is Map) {
        try {
          return Map<String, dynamic>.from(data['customData'] as Map);
        } catch (e) {
          return const {};
        }
      }
      return const {};
    }

    // Parse quickActions safely
    Map<String, String> parseQuickActions() {
      if (data['quickActions'] == null) return const {};
      if (data['quickActions'] is Map) {
        try {
          return Map<String, String>.from(data['quickActions'] as Map);
        } catch (e) {
          return const {};
        }
      }
      return const {};
    }

    // Check for hiveExclusive flag
    final bool hiveExclusive = data['hiveExclusive'] == true;

    return SpaceModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Space',
      description: data['description'] ?? '',
      iconCodePoint: iconCodePoint,
      imageUrl: data['imageUrl'],
      bannerUrl: data['bannerUrl'],
      metrics: metrics,
      tags: parseTags(),
      customData: parseCustomData(),
      isJoined: false, // This is determined elsewhere
      isPrivate: data['isPrivate'] == true,
      moderators: parseModerators(),
      admins: parseAdmins(),
      quickActions: parseQuickActions(),
      relatedSpaceIds: parseRelatedSpaceIds(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      spaceType: spaceType,
      eventIds: parseEventIds(),
      hiveExclusive: hiveExclusive,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': iconCodePoint,
      'imageUrl': imageUrl,
      'bannerUrl': bannerUrl,
      'metrics': metrics.toJson(),
      'tags': tags,
      'customData': customData,
      'isPrivate': isPrivate,
      'moderators': moderators,
      'admins': admins,
      'quickActions': quickActions,
      'relatedSpaceIds': relatedSpaceIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'spaceType': spaceType.toString().split('.').last,
      'eventIds': eventIds,
      'hiveExclusive': hiveExclusive,
    };
  }
}
