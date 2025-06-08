import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/feed/domain/models/feed_intelligence_params.dart';

/// The Trail system tracks a user's progression through HIVE as a narrative of participation
/// This affects feed personalization and content weighting
@immutable
class UserTrail {
  /// Spaces the user has joined
  final List<SpaceActivity> spaces;
  
  /// Events the user has interacted with
  final List<EventActivity> events;
  
  /// Content the user has created or interacted with
  final List<ContentActivity> content;
  
  /// Users the user has interacted with
  final List<String> interactionUserIds;
  
  /// Calculated user archetype based on behavior patterns
  final UserArchetype archetype;
  
  /// When the trail was created
  final DateTime createdAt;
  
  /// When the trail was last updated
  final DateTime lastUpdatedAt;

  /// User's preferred content types based on engagement
  List<String> get preferredContentTypes {
    final types = <String, int>{};
    
    // Count interactions by content type
    for (final activity in content) {
      types[activity.contentType] = (types[activity.contentType] ?? 0) + 1;
    }
    
    // Sort by frequency
    final sorted = types.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top types (limited to 3)
    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Constructor
  UserTrail({
    this.spaces = const [],
    this.events = const [],
    this.content = const [],
    this.interactionUserIds = const [],
    this.archetype = UserArchetype.newUser,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdatedAt = lastUpdatedAt ?? DateTime.now();

  /// Check if user has high engagement with a specific space
  bool hasHighEngagementWithSpace(String spaceId) {
    final space = spaces.where((s) => s.spaceId == spaceId).firstOrNull;
    if (space == null) return false;
    
    // High engagement criteria:
    // 1. Joined space
    // 2. Multiple visits
    // 3. Recent activity
    return space.isJoined && 
           space.visitCount > 3 && 
           DateTime.now().difference(space.lastActivityAt).inDays < 14;
  }

  /// Check if user has interacted with a specific creator
  bool hasInteractedWith(String creatorId) {
    return interactionUserIds.contains(creatorId);
  }

  /// Create empty trail
  factory UserTrail.empty() => UserTrail();

  /// Create a copy with updated values
  UserTrail copyWith({
    List<SpaceActivity>? spaces,
    List<EventActivity>? events,
    List<ContentActivity>? content,
    List<String>? interactionUserIds,
    UserArchetype? archetype,
    DateTime? lastUpdatedAt,
  }) {
    return UserTrail(
      spaces: spaces ?? this.spaces,
      events: events ?? this.events,
      content: content ?? this.content,
      interactionUserIds: interactionUserIds ?? this.interactionUserIds,
      archetype: archetype ?? this.archetype,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
    );
  }
}

/// Represents a user's interaction with a space
@immutable
class SpaceActivity {
  /// Space identifier
  final String spaceId;
  
  /// Space name
  final String spaceName;
  
  /// Whether the user has joined this space
  final bool isJoined;
  
  /// Number of times the user has visited this space
  final int visitCount;
  
  /// Number of interactions within this space (posts, votes, etc.)
  final int interactionCount;
  
  /// When the space was first visited
  final DateTime firstActivityAt;
  
  /// When the space was last visited
  final DateTime lastActivityAt;

  /// Constructor
  SpaceActivity({
    required this.spaceId,
    required this.spaceName,
    this.isJoined = false,
    this.visitCount = 0,
    this.interactionCount = 0,
    DateTime? firstActivityAt,
    DateTime? lastActivityAt,
  })  : firstActivityAt = firstActivityAt ?? DateTime.now(),
        lastActivityAt = lastActivityAt ?? DateTime.now();
}

/// Represents a user's interaction with an event
@immutable
class EventActivity {
  /// Event identifier
  final String eventId;
  
  /// Event title
  final String eventTitle;
  
  /// Whether the user has RSVPed to this event
  final bool hasRsvped;
  
  /// Whether the user has reposted this event
  final bool hasReposted;
  
  /// Number of times the user has viewed this event
  final int viewCount;
  
  /// The event's space ID
  final String? spaceId;
  
  /// When the event was first interacted with
  final DateTime firstActivityAt;
  
  /// When the event was last interacted with
  final DateTime lastActivityAt;

  /// Constructor
  EventActivity({
    required this.eventId,
    required this.eventTitle,
    this.hasRsvped = false,
    this.hasReposted = false,
    this.viewCount = 0,
    this.spaceId,
    DateTime? firstActivityAt,
    DateTime? lastActivityAt,
  })  : firstActivityAt = firstActivityAt ?? DateTime.now(),
        lastActivityAt = lastActivityAt ?? DateTime.now();
}

/// Represents a user's interaction with other content (drops, posts, etc.)
@immutable
class ContentActivity {
  /// Content identifier
  final String contentId;
  
  /// Content creator ID
  final String creatorId;
  
  /// Type of content (drop, quote, post, etc.)
  final String contentType;
  
  /// Whether the user created this content
  final bool isCreator;
  
  /// Whether the user has reposted this content
  final bool hasReposted;
  
  /// Number of times the user has viewed this content
  final int viewCount;
  
  /// Content's space ID (if applicable)
  final String? spaceId;
  
  /// When the content was first interacted with
  final DateTime firstActivityAt;
  
  /// When the content was last interacted with  
  final DateTime lastActivityAt;

  /// Constructor
  ContentActivity({
    required this.contentId,
    required this.creatorId,
    required this.contentType,
    this.isCreator = false,
    this.hasReposted = false,
    this.viewCount = 0,
    this.spaceId,
    DateTime? firstActivityAt,
    DateTime? lastActivityAt,
  })  : firstActivityAt = firstActivityAt ?? DateTime.now(),
        lastActivityAt = lastActivityAt ?? DateTime.now();
} 