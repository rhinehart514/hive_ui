import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_record.dart';

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
  
  EventStateHistoryEntry({
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

  EventOrganizer({
    required this.id,
    required this.name,
    this.isVerified = false,
    this.imageUrl,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isVerified': isVerified,
      'imageUrl': imageUrl,
    };
  }
  
  /// Create from JSON
  factory EventOrganizer.fromJson(Map<String, dynamic> json) {
    return EventOrganizer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isVerified: json['isVerified'] ?? false,
      imageUrl: json['imageUrl'],
    );
  }
}

@immutable
class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate; // Renamed from startTime
  final DateTime endDate; // Renamed from endTime
  final String organizerEmail;
  final String organizerName;
  final String category;
  final String status; // confirmed, cancelled
  final String link;
  final String? originalTitle; // Original title from RSS feed before parsing
  final String imageUrl; // URL of the event image from RSS feed
  final List<String> tags; // Tags for categorization and interest matching

  // New fields for enhanced event model
  final EventSource source; // Source of the event
  final String? createdBy; // User ID of the creator (for user-created events)
  final DateTime? lastModified; // Last modification time
  final String visibility; // public, friends, private
  final List<String> attendees; // List of attendee user IDs
  final String? spaceId; // Add spaceId field
  final List<String> reposts;
  final EventOrganizer? organizer;
  final bool? isAttending; // Add isAttending parameter
  
  // Guest limits and attendance tracking fields
  final int? capacity; // Maximum number of attendees allowed
  final List<String> waitlist; // Waitlisted users
  final Map<String, AttendanceRecord>? attendance; // Attendance records

  // State management fields
  final EventLifecycleState state; // Current state in the lifecycle
  final DateTime stateUpdatedAt; // When the state was last updated
  final List<EventStateHistoryEntry> stateHistory; // History of state changes
  final bool published; // Whether the event is published (visible)
  
  // Visibility enhancement fields
  final bool isBoosted; // Whether this event has been boosted
  final DateTime? boostTimestamp; // When the boost was applied
  final bool isHoneyMode; // Whether this event is in Honey Mode
  final DateTime? honeyModeTimestamp; // When Honey Mode was activated
  
  Event({
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
    this.attendance,
    this.state = EventLifecycleState.draft,
    DateTime? stateUpdatedAt,
    this.stateHistory = const [],
    this.published = false,
    this.isBoosted = false,
    this.boostTimestamp,
    this.isHoneyMode = false,
    this.honeyModeTimestamp,
  }) : stateUpdatedAt = stateUpdatedAt ?? DateTime.now();

  /// Returns the current state based on time if not manually set
  EventLifecycleState get currentState {
    // If the state was manually set and is not draft or published,
    // respect that state (e.g., admin manually set it to archived)
    if (state != EventLifecycleState.draft && 
        state != EventLifecycleState.published) {
      return state;
    }
    
    final now = DateTime.now();
    
    // Draft state - not published
    if (!published) {
      return EventLifecycleState.draft;
    }
    
    // Determine state based on time
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
  
  /// Returns a safe image URL, never null
  String get safeImageUrl => imageUrl.isNotEmpty ? imageUrl : '';

  /// Convert the event to a map
  Map<String, dynamic> toMap() {
    final stateHistoryJson = stateHistory.map((entry) => entry.toJson()).toList();
    
    return {
      'title': title,
      'description': description,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'organizerEmail': organizerEmail,
      'organizerName': organizerName,
      'category': category,
      'status': status,
      'link': link,
      'originalTitle': originalTitle,
      'imageUrl': imageUrl,
      'tags': tags,
      'source': source.name,
      'createdBy': createdBy,
      'lastModified': lastModified != null ? Timestamp.fromDate(lastModified!) : null,
      'visibility': visibility,
      'attendees': attendees,
      'spaceId': spaceId,
      'reposts': reposts,
      'organizer': organizer?.toJson(),
      'capacity': capacity,
      'waitlist': waitlist,
      'attendance': attendance?.map((key, value) => MapEntry(key, value.toJson())),
      'state': state.name,
      'stateUpdatedAt': Timestamp.fromDate(stateUpdatedAt),
      'stateHistory': stateHistoryJson,
      'published': published,
      'isBoosted': isBoosted,
      'boostTimestamp': boostTimestamp != null ? Timestamp.fromDate(boostTimestamp!) : null,
      'isHoneyMode': isHoneyMode,
      'honeyModeTimestamp': honeyModeTimestamp != null ? Timestamp.fromDate(honeyModeTimestamp!) : null,
    };
  }
  
  /// Alias for toMap() for backward compatibility
  Map<String, dynamic> toJson() => toMap();

  /// Create an Event from a map
  factory Event.fromMap(Map<String, dynamic> json) {
    // Parse event state history
    final List<EventStateHistoryEntry> stateHistory = [];
    if (json['stateHistory'] != null) {
      final List<dynamic> historyList = json['stateHistory'] as List<dynamic>;
      stateHistory.addAll(
        historyList.map((entry) => EventStateHistoryEntry.fromJson(entry as Map<String, dynamic>))
      );
    }
    
    // Parse state
    EventLifecycleState state = EventLifecycleState.draft;
    if (json['state'] != null) {
      try {
        state = EventLifecycleState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => EventLifecycleState.draft
        );
      } catch (e) {
        debugPrint('Error parsing event state: $e');
      }
    }
    
    // Parse or extract other fields
    List<String> tags = [];
    if (json['tags'] != null) {
      tags = List<String>.from(json['tags']);
    }

    List<String> attendees = [];
    if (json['attendees'] != null) {
      attendees = List<String>.from(json['attendees']);
    }

    List<String> reposts = [];
    if (json['reposts'] != null) {
      reposts = List<String>.from(json['reposts']);
    }

    List<String> waitlist = [];
    if (json['waitlist'] != null) {
      waitlist = List<String>.from(json['waitlist']);
    }

    // Parse attendance records
    Map<String, AttendanceRecord>? attendance;
    if (json['attendance'] != null) {
      attendance = Map<String, AttendanceRecord>.from(
        (json['attendance'] as Map).map(
          (key, value) => MapEntry(key.toString(), AttendanceRecord.fromJson(value)),
        ),
      );
    }

    // Convert eventType values to fix old data (backward compatibility)
    EventSource source;
    if (json['source'] != null) {
      try {
        source = EventSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => EventSource.external,
        );
      } catch (e) {
        source = EventSource.external;
      }
    } else if (json['eventType'] != null) {
      // Legacy field - backward compatibility
      source = json['eventType'] == 'user'
          ? EventSource.user
          : json['eventType'] == 'club'
              ? EventSource.club
              : EventSource.external;
    } else {
      source = EventSource.external;
    }

    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] != null
          ? (json['startDate'] is Timestamp 
              ? (json['startDate'] as Timestamp).toDate()
              : (json['startDate'] is String 
                  ? DateTime.parse(json['startDate'])
                  : DateTime.now()))
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (json['endDate'] is Timestamp 
              ? (json['endDate'] as Timestamp).toDate()
              : (json['endDate'] is String 
                  ? DateTime.parse(json['endDate'])
                  : DateTime.now().add(const Duration(hours: 2))))
          : DateTime.now().add(const Duration(hours: 2)),
      organizerEmail: json['organizerEmail'] ?? '',
      organizerName: json['organizerName'] ?? '',
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'confirmed',
      link: json['link'] ?? '',
      originalTitle: json['originalTitle'],
      imageUrl: json['imageUrl'] ?? '',
      tags: tags,
      source: source,
      createdBy: json['createdBy'],
      lastModified: json['lastModified'] != null
          ? (json['lastModified'] is Timestamp 
              ? (json['lastModified'] as Timestamp).toDate()
              : (json['lastModified'] is String 
                  ? DateTime.parse(json['lastModified'])
                  : null))
          : null,
      visibility: json['visibility'] ?? 'public',
      attendees: attendees,
      spaceId: json['spaceId'],
      reposts: reposts,
      organizer: json['organizer'] != null
          ? (json['organizer'] is Map
              ? EventOrganizer.fromJson(Map<String, dynamic>.from(json['organizer']))
              : null)
          : null,
      isAttending: json['isAttending'] as bool?,
      capacity: json['capacity'] as int?,
      waitlist: waitlist,
      attendance: attendance,
      state: state,
      stateUpdatedAt: json['stateUpdatedAt'] != null 
          ? (json['stateUpdatedAt'] is Timestamp 
              ? (json['stateUpdatedAt'] as Timestamp).toDate()
              : (json['stateUpdatedAt'] is String 
                  ? DateTime.parse(json['stateUpdatedAt'])
                  : DateTime.now()))
          : DateTime.now(),
      stateHistory: stateHistory,
      published: json['published'] as bool? ?? false,
      isBoosted: json['isBoosted'] ?? false,
      boostTimestamp: json['boostTimestamp'] != null
          ? (json['boostTimestamp'] is Timestamp
              ? (json['boostTimestamp'] as Timestamp).toDate()
              : (json['boostTimestamp'] is String
                  ? DateTime.parse(json['boostTimestamp'])
                  : null))
          : null,
      isHoneyMode: json['isHoneyMode'] ?? false,
      honeyModeTimestamp: json['honeyModeTimestamp'] != null
          ? (json['honeyModeTimestamp'] is Timestamp
              ? (json['honeyModeTimestamp'] as Timestamp).toDate()
              : (json['honeyModeTimestamp'] is String
                  ? DateTime.parse(json['honeyModeTimestamp'])
                  : null))
          : null,
    );
  }

  /// Create an Event from a JSON object
  /// This is used by repositories and providers that need to parse JSON data
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event.fromMap(json);
  }

  /// Factory for creating a user event
  factory Event.createUserEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String userId, // Creator ID
    required String organizerName, // User name or preferred display name
    String category = 'Social',
    String organizerEmail = '',
    String visibility = 'public',
    List<String> tags = const [],
    String imageUrl = '',
    bool published = false,
  }) {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}_$userId';
    final now = DateTime.now();
    
    // Initial state based on published flag
    final initialState = published ? EventLifecycleState.published : EventLifecycleState.draft;
    
    // Create initial state history entry
    final stateHistory = [
      EventStateHistoryEntry(
        state: initialState,
        timestamp: now,
        updatedBy: userId,
        transitionType: 'creation',
      )
    ];

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
      status: 'confirmed',
      link: '',
      imageUrl: imageUrl,
      tags: tags,
      source: EventSource.user,
      createdBy: userId,
      lastModified: now,
      visibility: visibility,
      attendees: [userId], // Creator is automatically attending
      spaceId: null, // No spaceId for user event
      reposts: const [],
      organizer: null,
      isAttending: null,
      capacity: null,
      waitlist: const [],
      attendance: null,
      state: initialState,
      stateUpdatedAt: now,
      stateHistory: stateHistory,
      published: published,
      isBoosted: false,
      boostTimestamp: null,
      isHoneyMode: false,
      honeyModeTimestamp: null,
    );
  }

  /// Factory for creating a club event
  factory Event.createClubEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String clubId,
    required String clubName,
    required String creatorId,
    String category = 'Club',
    String organizerEmail = '',
    String visibility = 'public',
    List<String> tags = const [],
    String imageUrl = '',
    bool published = false,
  }) {
    final id = 'club_${DateTime.now().millisecondsSinceEpoch}_$clubId';
    final now = DateTime.now();
    
    // Initial state based on published flag
    final initialState = published ? EventLifecycleState.published : EventLifecycleState.draft;
    
    // Create initial state history entry
    final stateHistory = [
      EventStateHistoryEntry(
        state: initialState,
        timestamp: now,
        updatedBy: creatorId,
        transitionType: 'creation',
      )
    ];

    return Event(
      id: id,
      title: title,
      description: description,
      location: location,
      startDate: startDate,
      endDate: endDate,
      organizerEmail: organizerEmail,
      organizerName: clubName,
      category: category,
      status: 'confirmed',
      link: '',
      imageUrl: imageUrl,
      tags: tags,
      source: EventSource.club,
      createdBy: creatorId,
      lastModified: now,
      visibility: visibility,
      attendees: [creatorId], // Creator is automatically attending
      spaceId: clubId, // Link to the club
      reposts: const [],
      organizer: EventOrganizer(
        id: clubId,
        name: clubName,
        isVerified: true, // Clubs are auto-verified
      ),
      isAttending: null,
      capacity: null,
      waitlist: const [],
      attendance: null,
      state: initialState,
      stateUpdatedAt: now,
      stateHistory: stateHistory,
      published: published,
      isBoosted: false,
      boostTimestamp: null,
      isHoneyMode: false,
      honeyModeTimestamp: null,
    );
  }

  /// Factory for creating a space event (similar to club event but with explicit space)
  factory Event.createSpaceEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String spaceId,
    required String spaceName,
    required String creatorId,
    String category = 'Space',
    String organizerEmail = '',
    String visibility = 'public',
    List<String> tags = const [],
    String imageUrl = '',
    bool published = false,
  }) {
    final id = 'space_${DateTime.now().millisecondsSinceEpoch}_$spaceId';
    final now = DateTime.now();
    
    // Initial state based on published flag
    final initialState = published ? EventLifecycleState.published : EventLifecycleState.draft;
    
    // Create initial state history entry
    final stateHistory = [
      EventStateHistoryEntry(
        state: initialState,
        timestamp: now,
        updatedBy: creatorId,
        transitionType: 'creation',
      )
    ];

    return Event(
      id: id,
      title: title,
      description: description,
      location: location,
      startDate: startDate,
      endDate: endDate,
      organizerEmail: organizerEmail,
      organizerName: spaceName,
      category: category,
      status: 'confirmed',
      link: '',
      imageUrl: imageUrl,
      tags: tags,
      source: EventSource.club, // Use club source for space events for now
      createdBy: creatorId,
      lastModified: now,
      visibility: visibility,
      attendees: [creatorId], // Creator is automatically attending
      spaceId: spaceId,
      reposts: const [],
      organizer: EventOrganizer(
        id: spaceId,
        name: spaceName,
        isVerified: true,
        imageUrl: null,
      ),
      isAttending: null,
      capacity: null,
      waitlist: const [],
      attendance: null,
      state: initialState,
      stateUpdatedAt: now,
      stateHistory: stateHistory,
      published: published,
      isBoosted: false,
      boostTimestamp: null,
      isHoneyMode: false,
      honeyModeTimestamp: null,
    );
  }

  // Helper method to format the event time range
  String get formattedTimeRange {
    // Convert to local time zone for display
    final localStartDate = _convertToLocalTime(startDate);
    final localEndDate = _convertToLocalTime(endDate);
    
    final startFormat = '${_formatTime(localStartDate)} ${_formatDate(localStartDate)}';
    final endFormat = '${_formatTime(localEndDate)} ${_formatDate(localEndDate)}';
    return '$startFormat - $endFormat';
  }

  // Helper method to convert EDT times to local time zone
  DateTime _convertToLocalTime(DateTime dateTime) {
    // All dates are stored in UTC or local, just ensure they're in local time zone for display
    return dateTime.isUtc ? dateTime.toLocal() : dateTime;
  }

  // Helper method to format the time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final hourStr = hour == 0 ? '12' : hour.toString(); // Handle midnight (0 hour)
    final minuteStr = dateTime.minute.toString().padLeft(2, '0');
    
    return '$hourStr:$minuteStr $period';
  }

  // Helper method to format the date
  String _formatDate(DateTime dateTime) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day;
    
    return '$month $day';
  }

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
    Map<String, AttendanceRecord>? attendance,
    EventLifecycleState? state,
    DateTime? stateUpdatedAt,
    List<EventStateHistoryEntry>? stateHistory,
    bool? published,
    bool? isBoosted,
    DateTime? boostTimestamp,
    bool? isHoneyMode,
    DateTime? honeyModeTimestamp,
  }) {
    // Create state history entry if state is changing
    List<EventStateHistoryEntry> updatedStateHistory = stateHistory ?? this.stateHistory;
    if (state != null && state != this.state) {
      final stateEntry = EventStateHistoryEntry(
        state: state,
        timestamp: DateTime.now(),
        updatedBy: null, // No user ID available here
        transitionType: 'manual',
      );
      updatedStateHistory = [...this.stateHistory, stateEntry];
    }
    
    return Event(
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
      attendance: attendance ?? this.attendance,
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

  /// Create a published version of this event
  Event publish({required String userId}) {
    return copyWith(
      published: true,
      state: EventLifecycleState.published,
      stateUpdatedAt: DateTime.now(),
      lastModified: DateTime.now(),
      stateHistory: [
        ...stateHistory,
        EventStateHistoryEntry(
          state: EventLifecycleState.published,
          timestamp: DateTime.now(),
          updatedBy: userId,
          transitionType: 'manual',
        ),
      ],
    );
  }
  
  /// Check if this event is editable by the given user
  bool isEditableBy(String userId) {
    // Creators can always edit draft events
    if (state == EventLifecycleState.draft && createdBy == userId) {
      return true;
    }
    
    // In published state, creators can edit most fields
    if (state == EventLifecycleState.published && createdBy == userId) {
      return true;
    }
    
    // In live state, only minor edits allowed by creator
    if (state == EventLifecycleState.live && createdBy == userId) {
      return true; // Client code should restrict which fields can be edited
    }
    
    // In completed or archived state, no edits allowed
    return false;
  }
  
  /// Check if a specific field can be edited
  bool canEditField(String fieldName, String userId) {
    // Always allow admins to edit anything (client should check this separately)
    
    // Get list of fields that can't be edited after publishing
    final coreFields = ['startDate', 'endDate', 'location', 'title'];
    
    // Apply business logic based on state
    switch (state) {
      case EventLifecycleState.draft:
        // In draft, everything can be edited by creator
        return createdBy == userId;
      case EventLifecycleState.published:
        // In published state, core details are restricted
        if (coreFields.contains(fieldName)) {
          return false; // Only admins can edit core details after publishing
        }
        return createdBy == userId; // Creator can edit non-core details
      case EventLifecycleState.live:
        // In live state, only certain fields can be edited
        final editableFields = ['description', 'imageUrl', 'tags', 'capacity'];
        return createdBy == userId && editableFields.contains(fieldName);
      case EventLifecycleState.completed:
      case EventLifecycleState.archived:
        // No edits allowed in completed or archived state
        return false;
    }
  }
  
  /// Update the event state based on the current time
  Event updateStateBasedOnTime() {
    final calculatedState = currentState;
    
    // Only update if the calculated state is different from the stored state
    if (calculatedState != state) {
      final now = DateTime.now();
      return copyWith(
        state: calculatedState,
        stateUpdatedAt: now,
        stateHistory: [
          ...stateHistory,
          EventStateHistoryEntry(
            state: calculatedState,
            timestamp: now,
            transitionType: 'automatic',
          ),
        ],
      );
    }
    
    return this;
  }

  /// Returns true if the event is currently happening
  bool get isLive {
      final now = DateTime.now();
      return now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  /// Returns true if the event has finished
  bool get isPast {
      final now = DateTime.now();
      return now.isAfter(endDate);
  }
}
