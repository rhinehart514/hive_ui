import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Types of entities that can be interacted with
enum EntityType { event, space, profile, post }

/// Types of actions a user can perform
enum InteractionAction { view, rsvp, share, comment, save, click }

/// Model representing a user's interaction with an entity in the app
@immutable
class Interaction {
  /// Unique ID for the interaction
  final String id;

  /// ID of the user who performed the interaction
  final String userId;

  /// ID of the entity being interacted with
  final String entityId;

  /// Type of entity (event, space, profile, etc.)
  final EntityType entityType;

  /// Type of action performed
  final InteractionAction action;

  /// Timestamp of the interaction
  final DateTime timestamp;

  /// Session ID to group related interactions
  final String? sessionId;

  /// Optional metadata related to the interaction
  final Map<String, dynamic>? metadata;

  /// Device information
  final DeviceInfo? deviceInfo;

  const Interaction({
    required this.id,
    required this.userId,
    required this.entityId,
    required this.entityType,
    required this.action,
    required this.timestamp,
    this.sessionId,
    this.metadata,
    this.deviceInfo,
  });

  /// Create an Interaction from Firestore document
  factory Interaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Interaction(
      id: doc.id,
      userId: data['userId'] as String,
      entityId: data['entityId'] as String,
      entityType: _parseEntityType(data['entityType'] as String),
      action: _parseInteractionAction(data['action'] as String),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      sessionId: data['sessionId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      deviceInfo: data['deviceInfo'] != null
          ? DeviceInfo.fromMap(data['deviceInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert this interaction to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'entityId': entityId,
      'entityType': entityType.toString().split('.').last,
      'action': action.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
      'sessionId': sessionId,
      'metadata': metadata,
      'deviceInfo': deviceInfo?.toMap(),
    };
  }

  /// Helper method to parse EntityType from string
  static EntityType _parseEntityType(String value) {
    switch (value) {
      case 'event':
        return EntityType.event;
      case 'space':
        return EntityType.space;
      case 'profile':
        return EntityType.profile;
      case 'post':
        return EntityType.post;
      default:
        throw ArgumentError('Unknown entity type: $value');
    }
  }

  /// Helper method to parse InteractionAction from string
  static InteractionAction _parseInteractionAction(String value) {
    switch (value) {
      case 'view':
        return InteractionAction.view;
      case 'rsvp':
        return InteractionAction.rsvp;
      case 'share':
        return InteractionAction.share;
      case 'comment':
        return InteractionAction.comment;
      case 'save':
        return InteractionAction.save;
      case 'click':
        return InteractionAction.click;
      default:
        throw ArgumentError('Unknown interaction action: $value');
    }
  }

  /// Create a copy of this interaction with some fields replaced
  Interaction copyWith({
    String? id,
    String? userId,
    String? entityId,
    EntityType? entityType,
    InteractionAction? action,
    DateTime? timestamp,
    String? sessionId,
    Map<String, dynamic>? metadata,
    DeviceInfo? deviceInfo,
  }) {
    return Interaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      metadata: metadata ?? this.metadata,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}

/// Device information captured with interactions
class DeviceInfo {
  final String platform;
  final bool isNative;
  final String osVersion;
  final String appVersion;

  const DeviceInfo({
    required this.platform,
    required this.isNative,
    required this.osVersion,
    required this.appVersion,
  });

  /// Creates a DeviceInfo instance from a map
  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      platform: map['platform'] as String,
      isNative: map['isNative'] as bool,
      osVersion: map['osVersion'] as String,
      appVersion: map['appVersion'] as String,
    );
  }

  /// Creates a map from this DeviceInfo instance
  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'isNative': isNative,
      'osVersion': osVersion,
      'appVersion': appVersion,
    };
  }

  /// Creates a DeviceInfo instance with the current device information
  static DeviceInfo current() {
    // Determine platform and related info
    // This would normally use something like Platform.isIOS or kIsWeb
    // For simplicity, we're using a basic implementation

    // In a real implementation, you would use:
    // - dart:io Platform for native platforms
    // - package_info_plus for app version
    // - flutter/foundation.dart kIsWeb for web detection

    String platform;
    bool isNative;
    String osVersion;
    String appVersion;

    // Basic platform detection (improve with proper detection in production)
    if (kIsWeb) {
      platform = 'web';
      isNative = false;
      osVersion = 'unknown';
      appVersion = '1.0.0'; // Replace with actual version from package_info
    } else {
      // This is a simplification - use Platform class in production
      platform = 'mobile'; // or 'android', 'ios', etc.
      isNative = true;
      osVersion =
          'unknown'; // Use Platform.operatingSystemVersion in production
      appVersion = '1.0.0'; // Replace with actual version from package_info
    }

    return DeviceInfo(
      platform: platform,
      isNative: isNative,
      osVersion: osVersion,
      appVersion: appVersion,
    );
  }
}
