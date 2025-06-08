import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The type of activity a trail entry represents
enum TrailActivityType {
  /// User joined a space
  spaceJoin,
  
  /// User attended an event
  eventAttendance,
  
  /// User created content
  creation,
  
  /// User sent a signal (like RSVP, boost, etc.)
  signal,
  
  /// User received a badge or achievement
  achievement
}

/// Model representing a single entry in a user's activity trail
class TrailEntry {
  /// Unique identifier for this trail entry
  final String id;
  
  /// User ID this trail entry belongs to
  final String userId;
  
  /// When this activity occurred
  final DateTime timestamp;
  
  /// Type of activity
  final TrailActivityType activityType;
  
  /// Title of the activity (e.g., "Joined UB Creatives")
  final String title;
  
  /// Description of the activity (optional)
  final String? description;
  
  /// Icon to display for this activity type
  final IconData? icon;
  
  /// Related entity ID (like space ID, event ID, etc.)
  final String? relatedEntityId;
  
  /// Related entity type (like "space", "event", etc.)
  final String? relatedEntityType;
  
  /// Image URL for visual representation (optional)
  final String? imageUrl;
  
  /// Custom data relevant to this activity
  final Map<String, dynamic>? metadata;

  const TrailEntry({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.activityType,
    required this.title,
    this.description,
    this.icon,
    this.relatedEntityId,
    this.relatedEntityType,
    this.imageUrl,
    this.metadata,
  });

  /// Create a TrailEntry from Firestore document
  factory TrailEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert string activity type to enum
    TrailActivityType getActivityType(String? type) {
      switch (type) {
        case 'spaceJoin':
          return TrailActivityType.spaceJoin;
        case 'eventAttendance':
          return TrailActivityType.eventAttendance;
        case 'creation':
          return TrailActivityType.creation;
        case 'signal':
          return TrailActivityType.signal;
        case 'achievement':
          return TrailActivityType.achievement;
        default:
          return TrailActivityType.signal;
      }
    }
    
    // Convert timestamp to DateTime
    DateTime getTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return DateTime.now();
    }
    
    return TrailEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: getTimestamp(data['timestamp']),
      activityType: getActivityType(data['activityType']),
      title: data['title'] ?? 'Activity',
      description: data['description'],
      relatedEntityId: data['relatedEntityId'],
      relatedEntityType: data['relatedEntityType'],
      imageUrl: data['imageUrl'],
      metadata: data['metadata'],
    );
  }
  
  /// Convert TrailEntry to Firestore document
  Map<String, dynamic> toFirestore() {
    // Convert enum activity type to string
    String getActivityTypeString(TrailActivityType type) {
      switch (type) {
        case TrailActivityType.spaceJoin:
          return 'spaceJoin';
        case TrailActivityType.eventAttendance:
          return 'eventAttendance';
        case TrailActivityType.creation:
          return 'creation';
        case TrailActivityType.signal:
          return 'signal';
        case TrailActivityType.achievement:
          return 'achievement';
      }
    }
    
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'activityType': getActivityTypeString(activityType),
      'title': title,
      'description': description,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }
} 