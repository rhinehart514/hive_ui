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
  final bool hasMessageBoard;
  final SpaceLifecycleState lifecycleState;
  final SpaceClaimStatus claimStatus;
  final String? claimId;
  final DateTime? lastActivityAt;

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
    this.hasMessageBoard = true,
    this.lifecycleState = SpaceLifecycleState.active,
    this.claimStatus = SpaceClaimStatus.notRequired,
    this.claimId,
    this.lastActivityAt,
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
      hasMessageBoard: hasMessageBoard,
      lifecycleState: lifecycleState,
      claimStatus: claimStatus,
      claimId: claimId,
      lastActivityAt: lastActivityAt,
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
    
    DateTime? lastActivityAt;
    if (data['lastActivityAt'] != null) {
      if (data['lastActivityAt'] is Timestamp) {
        lastActivityAt = (data['lastActivityAt'] as Timestamp).toDate();
      } else if (data['lastActivityAt'] is int) {
        lastActivityAt = DateTime.fromMillisecondsSinceEpoch(data['lastActivityAt']);
      } else if (data['lastActivityAt'] is String) {
        lastActivityAt = DateTime.parse(data['lastActivityAt']);
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
      if (data['spaceType'] is String) {
        switch (data['spaceType']) {
          case 'studentOrg':
            spaceType = SpaceType.studentOrg;
            break;
          case 'universityOrg':
            spaceType = SpaceType.universityOrg;
            break;
          case 'campusLiving':
            spaceType = SpaceType.campusLiving;
            break;
          case 'fraternityAndSorority':
            spaceType = SpaceType.fraternityAndSorority;
            break;
          case 'hiveExclusive':
            spaceType = SpaceType.hiveExclusive;
            break;
          default:
            spaceType = SpaceType.other;
        }
      }
    }
    
    // Parse lifecycle state
    SpaceLifecycleState lifecycleState = SpaceLifecycleState.active;
    if (data['lifecycleState'] != null) {
      if (data['lifecycleState'] is String) {
        switch (data['lifecycleState']) {
          case 'created':
            lifecycleState = SpaceLifecycleState.created;
            break;
          case 'active':
            lifecycleState = SpaceLifecycleState.active;
            break;
          case 'dormant':
            lifecycleState = SpaceLifecycleState.dormant;
            break;
          case 'archived':
            lifecycleState = SpaceLifecycleState.archived;
            break;
        }
      }
    }
    
    // Parse claim status
    SpaceClaimStatus claimStatus = SpaceClaimStatus.notRequired;
    if (data['claimStatus'] != null) {
      if (data['claimStatus'] is String) {
        switch (data['claimStatus']) {
          case 'unclaimed':
            claimStatus = SpaceClaimStatus.unclaimed;
            break;
          case 'pending':
            claimStatus = SpaceClaimStatus.pending;
            break;
          case 'claimed':
            claimStatus = SpaceClaimStatus.claimed;
            break;
          case 'notRequired':
            claimStatus = SpaceClaimStatus.notRequired;
            break;
        }
      }
    } else {
      // Determine default claim status based on space type
      final bool isHiveExclusive = data['hiveExclusive'] == true || 
                                   spaceType == SpaceType.hiveExclusive;
      claimStatus = isHiveExclusive ? SpaceClaimStatus.notRequired : SpaceClaimStatus.unclaimed;
    }

    // Parse lists
    List<String> tags = [];
    if (data['tags'] != null && data['tags'] is List) {
      tags = List<String>.from(data['tags'] as List);
    }

    List<String> moderators = [];
    if (data['moderators'] != null && data['moderators'] is List) {
      moderators = List<String>.from(data['moderators'] as List);
    }

    List<String> admins = [];
    if (data['admins'] != null && data['admins'] is List) {
      admins = List<String>.from(data['admins'] as List);
    }

    List<String> relatedSpaceIds = [];
    if (data['relatedSpaceIds'] != null && data['relatedSpaceIds'] is List) {
      relatedSpaceIds = List<String>.from(data['relatedSpaceIds'] as List);
    }

    List<String> eventIds = [];
    if (data['eventIds'] != null && data['eventIds'] is List) {
      eventIds = List<String>.from(data['eventIds'] as List);
    }

    // Parse maps
    Map<String, String> quickActions = {};
    if (data['quickActions'] != null && data['quickActions'] is Map) {
      quickActions = Map<String, String>.from(data['quickActions'] as Map);
    }

    // Parse metrics
    final metricsData = data['metrics'] as Map<String, dynamic>? ?? {};
    final metrics = SpaceMetricsModel.fromMap(doc.id, metricsData);

    return SpaceModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Space',
      description: data['description'] as String? ?? '',
      iconCodePoint: iconCodePoint,
      imageUrl: data['imageUrl'] as String?,
      bannerUrl: data['bannerUrl'] as String?,
      metrics: metrics,
      tags: tags,
      customData: data['customData'] as Map<String, dynamic>? ?? {},
      isJoined: data['isJoined'] as bool? ?? false,
      isPrivate: data['isPrivate'] as bool? ?? false,
      moderators: moderators,
      admins: admins,
      quickActions: quickActions,
      relatedSpaceIds: relatedSpaceIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      spaceType: spaceType,
      eventIds: eventIds,
      hiveExclusive: data['hiveExclusive'] as bool? ?? false,
      hasMessageBoard: data['hasMessageBoard'] as bool? ?? true,
      lifecycleState: lifecycleState,
      claimStatus: claimStatus,
      claimId: data['claimId'] as String?,
      lastActivityAt: lastActivityAt,
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
      'metrics': metrics.toMap(),
      'tags': tags,
      'customData': customData,
      'isJoined': isJoined,
      'isPrivate': isPrivate,
      'moderators': moderators,
      'admins': admins,
      'quickActions': quickActions,
      'relatedSpaceIds': relatedSpaceIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'spaceType': _spaceTypeToString(spaceType),
      'eventIds': eventIds,
      'hiveExclusive': hiveExclusive,
      'hasMessageBoard': hasMessageBoard,
      'lifecycleState': _lifecycleStateToString(lifecycleState),
      'claimStatus': _claimStatusToString(claimStatus),
      'claimId': claimId,
      'lastActivityAt': lastActivityAt != null ? Timestamp.fromDate(lastActivityAt!) : null,
    };
  }
  
  /// Convert SpaceType enum to string
  String _spaceTypeToString(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return 'studentOrg';
      case SpaceType.universityOrg:
        return 'universityOrg';
      case SpaceType.campusLiving:
        return 'campusLiving';
      case SpaceType.fraternityAndSorority:
        return 'fraternityAndSorority';
      case SpaceType.hiveExclusive:
        return 'hiveExclusive';
      case SpaceType.other:
        return 'other';
    }
  }
  
  /// Convert SpaceLifecycleState enum to string
  String _lifecycleStateToString(SpaceLifecycleState state) {
    switch (state) {
      case SpaceLifecycleState.created:
        return 'created';
      case SpaceLifecycleState.active:
        return 'active';
      case SpaceLifecycleState.dormant:
        return 'dormant';
      case SpaceLifecycleState.archived:
        return 'archived';
    }
  }
  
  /// Convert SpaceClaimStatus enum to string
  String _claimStatusToString(SpaceClaimStatus status) {
    switch (status) {
      case SpaceClaimStatus.unclaimed:
        return 'unclaimed';
      case SpaceClaimStatus.pending:
        return 'pending';
      case SpaceClaimStatus.claimed:
        return 'claimed';
      case SpaceClaimStatus.notRequired:
        return 'notRequired';
    }
  }
}
