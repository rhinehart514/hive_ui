import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines the source of an event
enum EventSource {
  /// Events fetched from RSS feeds
  external,

  /// Events created by users
  user,

  /// Events created by clubs or organizations
  club,
}

/// Defines the lifecycle state of an event
enum EventLifecycleState {
  /// Event is still being edited and not visible in feeds
  draft,
  
  /// Event is published and visible in feeds
  published,
  
  /// Event is currently happening
  live,
  
  /// Event has finished but is still in engagement window
  completed,
  
  /// Event is archived and only available in search
  archived
}

/// Represents a history entry for event state changes
class EventStateHistoryEntry {
  final EventLifecycleState state;
  final DateTime timestamp;
  final String? updatedBy;
  final String transitionType; // 'automatic', 'manual', 'creation'
  
  const EventStateHistoryEntry({
    required this.state,
    required this.timestamp,
    this.updatedBy,
    required this.transitionType,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
      'transitionType': transitionType,
    };
  }
  
  factory EventStateHistoryEntry.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    if (json['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp']);
    } else if (json['timestamp'] is Timestamp) {
      timestamp = (json['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }
    
    return EventStateHistoryEntry(
      state: EventLifecycleState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => EventLifecycleState.draft
      ),
      timestamp: timestamp,
      updatedBy: json['updatedBy'],
      transitionType: json['transitionType'] ?? 'manual',
    );
  }
}

/// Represents an event organizer
class EventOrganizer {
  final String id;
  final String name;
  final bool isVerified;
  final String? imageUrl;

  const EventOrganizer({
    required this.id,
    required this.name,
    this.isVerified = false,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isVerified': isVerified,
      'imageUrl': imageUrl,
    };
  }
  
  factory EventOrganizer.fromJson(Map<String, dynamic> json) {
    return EventOrganizer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isVerified: json['isVerified'] ?? false,
      imageUrl: json['imageUrl'],
    );
  }
}

/// Domain entity representing an event
@immutable
class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String organizerEmail;
  final String organizerName;
  final String category;
  final String status;
  final String link;
  final String? originalTitle;
  final String imageUrl;
  final List<String> tags;
  final EventSource source;
  final String? createdBy;
  final DateTime? lastModified;
  final String visibility;
  final List<String> attendees;
  final String? spaceId;
  final List<String> reposts;
  final EventOrganizer? organizer;
  final bool? isAttending;
  final int? capacity;
  final List<String> waitlist;
  final EventLifecycleState state;
  final DateTime stateUpdatedAt;
  final List<EventStateHistoryEntry> stateHistory;
  final bool published;
  final bool isBoosted;
  final DateTime? boostTimestamp;
  final bool isHoneyMode;
  final DateTime? honeyModeTimestamp;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.organizerEmail,
    required this.organizerName,
    required this.category,
    required this.status,
    required this.link,
    this.originalTitle,
    required this.imageUrl,
    this.tags = const [],
    required this.source,
    this.createdBy,
    this.lastModified,
    this.visibility = 'public',
    this.attendees = const [],
    this.spaceId,
    this.reposts = const [],
    this.organizer,
    this.isAttending,
    this.capacity,
    this.waitlist = const [],
    this.state = EventLifecycleState.draft,
    required this.stateUpdatedAt,
    this.stateHistory = const [],
    this.published = false,
    this.isBoosted = false,
    this.boostTimestamp,
    this.isHoneyMode = false,
    this.honeyModeTimestamp,
  });
  
  /// Factory constructor that handles setting default stateUpdatedAt
  factory Event.create({
    required String id,
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String organizerEmail,
    required String organizerName,
    required String category,
    required String status,
    required String link,
    String? originalTitle,
    required String imageUrl,
    List<String> tags = const [],
    required EventSource source,
    String? createdBy,
    DateTime? lastModified,
    String visibility = 'public',
    List<String> attendees = const [],
    String? spaceId,
    List<String> reposts = const [],
    EventOrganizer? organizer,
    bool? isAttending,
    int? capacity,
    List<String> waitlist = const [],
    EventLifecycleState state = EventLifecycleState.draft,
    DateTime? stateUpdatedAt,
    List<EventStateHistoryEntry> stateHistory = const [],
    bool published = false,
    bool isBoosted = false,
    DateTime? boostTimestamp,
    bool isHoneyMode = false,
    DateTime? honeyModeTimestamp,
  }) {
    return Event(
      id: id,
      title: title,
      description: description,
      location: location,
      startDate: startDate,
      endDate: endDate,
      organizerEmail: organizerEmail,
      organizerName: organizerName,
      category: category,
      status: status,
      link: link,
      originalTitle: originalTitle,
      imageUrl: imageUrl,
      tags: tags,
      source: source,
      createdBy: createdBy,
      lastModified: lastModified,
      visibility: visibility,
      attendees: attendees,
      spaceId: spaceId,
      reposts: reposts,
      organizer: organizer,
      isAttending: isAttending,
      capacity: capacity,
      waitlist: waitlist,
      state: state,
      stateUpdatedAt: stateUpdatedAt ?? DateTime.now(),
      stateHistory: stateHistory,
      published: published,
      isBoosted: isBoosted,
      boostTimestamp: boostTimestamp,
      isHoneyMode: isHoneyMode,
      honeyModeTimestamp: honeyModeTimestamp,
    );
  }

  /// Returns the current state based on time if not manually set
  EventLifecycleState get currentState {
    if (state != EventLifecycleState.draft && 
        state != EventLifecycleState.published) {
      return state;
    }
    
    final now = DateTime.now();
    
    if (!published) {
      return EventLifecycleState.draft;
    }
    
    final postEventWindow = endDate.add(const Duration(hours: 12));
    
    if (now.isBefore(startDate)) {
      return EventLifecycleState.published;
    } else if (now.isAfter(startDate) && now.isBefore(endDate)) {
      return EventLifecycleState.live;
    } else if (now.isAfter(endDate) && now.isBefore(postEventWindow)) {
      return EventLifecycleState.completed;
    } else {
      return EventLifecycleState.archived;
    }
  }

  /// Returns true if the event has been cancelled
  bool get isCancelled => status == 'cancelled';
  
  /// Returns true if the event is today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(startDate.year, startDate.month, startDate.day);
    return eventDate.isAtSameMomentAs(today);
  }
  
  /// Returns true if the event is this week (within the next 7 days)
  bool get isThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));
    final eventDate = DateTime(startDate.year, startDate.month, startDate.day);
    return eventDate.isAfter(today) && eventDate.isBefore(endOfWeek) || eventDate.isAtSameMomentAs(today);
  }
  
  /// Returns true if the event was created by a club/organization
  bool get isClubCreated => source == EventSource.club;

  /// Create a copy of this event with some changes
  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? organizerEmail,
    String? organizerName,
    String? category,
    String? status,
    String? link,
    String? originalTitle,
    String? imageUrl,
    List<String>? tags,
    EventSource? source,
    String? createdBy,
    DateTime? lastModified,
    String? visibility,
    List<String>? attendees,
    String? spaceId,
    List<String>? reposts,
    EventOrganizer? organizer,
    bool? isAttending,
    int? capacity,
    List<String>? waitlist,
    EventLifecycleState? state,
    DateTime? stateUpdatedAt,
    List<EventStateHistoryEntry>? stateHistory,
    bool? published,
    bool? isBoosted,
    DateTime? boostTimestamp,
    bool? isHoneyMode,
    DateTime? honeyModeTimestamp,
  }) {
    List<EventStateHistoryEntry> updatedStateHistory = stateHistory ?? this.stateHistory;
    if (state != null && state != this.state) {
      final stateEntry = EventStateHistoryEntry(
        state: state,
        timestamp: DateTime.now(),
        updatedBy: null,
        transitionType: 'manual',
      );
      updatedStateHistory = [...this.stateHistory, stateEntry];
    }
    
    return Event.create(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerName: organizerName ?? this.organizerName,
      category: category ?? this.category,
      status: status ?? this.status,
      link: link ?? this.link,
      originalTitle: originalTitle ?? this.originalTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      createdBy: createdBy ?? this.createdBy,
      lastModified: lastModified ?? DateTime.now(),
      visibility: visibility ?? this.visibility,
      attendees: attendees ?? this.attendees,
      spaceId: spaceId ?? this.spaceId,
      reposts: reposts ?? this.reposts,
      organizer: organizer ?? this.organizer,
      isAttending: isAttending ?? this.isAttending,
      capacity: capacity ?? this.capacity,
      waitlist: waitlist ?? this.waitlist,
      state: state ?? this.state,
      stateUpdatedAt: stateUpdatedAt ?? (state != null ? DateTime.now() : this.stateUpdatedAt),
      stateHistory: updatedStateHistory,
      published: published ?? this.published,
      isBoosted: isBoosted ?? this.isBoosted,
      boostTimestamp: boostTimestamp ?? this.boostTimestamp,
      isHoneyMode: isHoneyMode ?? this.isHoneyMode,
      honeyModeTimestamp: honeyModeTimestamp ?? this.honeyModeTimestamp,
    );
  }
} 