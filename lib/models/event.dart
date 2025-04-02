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

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate, // Renamed from startTime
    required this.endDate, // Renamed from endTime
    required this.organizerEmail,
    required this.organizerName,
    required this.category,
    required this.status,
    required this.link,
    this.originalTitle,
    String? imageUrl = '', // Changed to nullable parameter with default empty string
    this.tags = const [], // Default to empty list
    this.source = EventSource.external, // Default to external
    this.createdBy,
    this.lastModified,
    this.visibility = 'public', // Default to public
    this.attendees = const [], // Default to empty list
    this.spaceId, // Add spaceId parameter
    this.reposts = const [],
    this.organizer,
  }) : imageUrl = (imageUrl ?? '').trim(); // Ensure imageUrl is never null and is trimmed

  // This will be used when we receive data from the backend
  factory Event.fromJson(Map<String, dynamic> json) {
    // Parse tags if they exist, otherwise use empty list
    final List<String> tags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tags.addAll((json['tags'] as List).map((tag) => tag.toString()));
      } else if (json['tags'] is String) {
        // Handle case where tags might be a comma-separated string
        tags.addAll(
            (json['tags'] as String).split(',').map((tag) => tag.trim()));
      }
    }

    // Extract tags from category if no explicit tags
    if (tags.isEmpty && json['category'] != null) {
      tags.add(json['category'] as String);
    }

    // Parse attendees list
    final List<String> attendees = [];
    if (json['attendees'] != null && json['attendees'] is List) {
      attendees.addAll((json['attendees'] as List).map((id) => id.toString()));
    }

    // Parse event source
    EventSource source = EventSource.external;
    if (json['source'] != null) {
      final sourceStr = json['source'].toString().toLowerCase();
      if (sourceStr == 'user') {
        source = EventSource.user;
      } else if (sourceStr == 'club') {
        source = EventSource.club;
      }
    }
    
    // Sanitize the imageUrl to prevent issues
    String? imageUrl = json['imageUrl'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = '';
    }

    // Helper function to parse dates that could be Timestamp or String
    DateTime parseDateField(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          debugPrint('Error parsing date string: $value');
          return DateTime.now();
        }
      }
      debugPrint('Unhandled date format: ${value.runtimeType}');
      return DateTime.now();
    }

    return Event(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startDate: parseDateField(json['startDate'] ?? json['startTime']),
      endDate: parseDateField(json['endDate'] ?? json['endTime']),
      organizerEmail: json['organizerEmail'] as String? ?? '',
      organizerName: json['organizerName'] as String? ?? 'Unknown Organizer',
      category: json['category'] as String? ?? 'Event',
      status: json['status'] as String? ?? 'confirmed',
      link: json['link'] as String? ?? '',
      originalTitle: json['originalTitle'] as String?,
      imageUrl: imageUrl,
      tags: tags,
      source: source,
      createdBy: json['createdBy'] as String?,
      lastModified: json['lastModified'] != null 
          ? parseDateField(json['lastModified'])
          : null,
      visibility: json['visibility'] as String? ?? 'public',
      attendees: attendees,
      spaceId: json['spaceId'] as String?,
      reposts: json['reposts'] != null && json['reposts'] is List
          ? (json['reposts'] as List).map((e) => e.toString()).toList()
          : [],
      organizer: json['organizer'] != null
          ? EventOrganizer(
              id: json['organizer']['id'] as String,
              name: json['organizer']['name'] as String,
              isVerified: json['organizer']['isVerified'] as bool? ?? false,
              imageUrl: json['organizer']['imageUrl'] as String?,
            )
          : null,
    );
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
    String? imageUrl = '',
  }) {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}_$userId';

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
      imageUrl: imageUrl, // Will be trimmed in constructor
      tags: tags,
      source: EventSource.user,
      createdBy: userId,
      lastModified: DateTime.now(),
      visibility: visibility,
      attendees: [userId], // Creator is automatically attending
      spaceId: null, // No spaceId for user event
      reposts: [],
      organizer: null,
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
    String? imageUrl = '',
  }) {
    final id = 'club_${DateTime.now().millisecondsSinceEpoch}_$clubId';

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
      imageUrl: imageUrl, // Will be trimmed in constructor
      tags: tags,
      source: EventSource.club,
      createdBy: creatorId,
      lastModified: DateTime.now(),
      visibility: visibility,
      attendees: [creatorId], // Creator is automatically attending
      spaceId: null, // No spaceId for club event
      reposts: [],
      organizer: EventOrganizer(
        id: creatorId,
        name: clubName,
        isVerified: true,
        imageUrl: null,
      ),
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
    // The events are stored in EDT time, so we need to convert to local time
    // First, ensure the DateTime is treated as EDT
    const edtOffset = Duration(hours: -4); // EDT is UTC-4
    final utcTime = dateTime.toUtc().add(-edtOffset); // Convert EDT to UTC
    return utcTime.toLocal(); // Convert UTC to local time
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Helper method to format date
  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  // Check if event is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  // Check if event is happening today
  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }

  // Check if event is in the past
  bool get isPast {
    return startDate.isBefore(DateTime.now());
  }

  // Check if event is cancelled based on status field or title/description
  bool get isCancelled {
    // Check explicit status field first
    if (status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'canceled') {
      return true;
    }

    // Check title for cancelled/canceled keywords
    final titleLower = title.toLowerCase();
    if (titleLower.contains('cancelled') ||
        titleLower.contains('canceled') ||
        titleLower.contains('cancel:')) {
      return true;
    }

    // Check description for cancelled/canceled keywords
    final descLower = description.toLowerCase();
    if (descLower.contains('event cancelled') ||
        descLower.contains('event canceled') ||
        descLower.contains('has been cancelled') ||
        descLower.contains('has been canceled')) {
      return true;
    }

    return false;
  }

  // Check if event is happening this week
  bool get isThisWeek {
    final now = DateTime.now();
    final thisWeekEnd = DateTime(now.year, now.month, now.day + 7);
    return startDate.isAfter(now) && startDate.isBefore(thisWeekEnd);
  }

  // Type-specific helper properties
  bool get isUserCreated => source == EventSource.user;
  bool get isClubCreated => source == EventSource.club;
  bool get isExternal => source == EventSource.external;

  // Get keywords from the event for interest matching
  List<String> get keywords {
    final List<String> result = [...tags];

    // Add category as a keyword if not already in tags
    if (!result.contains(category)) {
      result.add(category);
    }

    // Add organizer name as a keyword
    result.add(organizerName);

    return result;
  }

  // Convert event to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'organizerEmail': organizerEmail,
      'organizerName': organizerName,
      'category': category,
      'status': status,
      'link': link,
      'originalTitle': originalTitle,
      'imageUrl': imageUrl,
      'tags': tags,
      'source': source.toString().split('.').last,
      'createdBy': createdBy,
      'lastModified': lastModified?.toIso8601String(),
      'visibility': visibility,
      'attendees': attendees,
      'spaceId': spaceId, // Add spaceId to toJson
      'reposts': reposts,
      'organizer': organizer?.toJson(),
    };
  }

  // Create a copy of the event with updated fields
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
  }) {
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
      lastModified: lastModified ?? this.lastModified,
      visibility: visibility ?? this.visibility,
      attendees: attendees ?? this.attendees,
      spaceId: spaceId ?? this.spaceId,
      reposts: reposts ?? this.reposts,
      organizer: organizer ?? this.organizer,
    );
  }

  /// Create a copy of this event marked as user-modified
  Event asUserModified({String? modifiedBy}) {
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
      source: source, // Keep original source
      createdBy: modifiedBy ?? createdBy, // Set the modifier if provided
      lastModified: DateTime.now(), // Update modification time
      visibility: visibility,
      attendees: attendees,
      spaceId: spaceId,
      reposts: reposts,
      organizer: organizer,
    );
  }

  /// Get a safe image URL for display, filtering known problematic patterns
  String get safeImageUrl {
    // Return empty string if URL is empty, null, or just whitespace
    if (imageUrl.isEmpty || imageUrl.trim().isEmpty) {
      return '';
    }

    // Detect and block problematic patterns
    if (imageUrl.contains("C:/Users") ||
        imageUrl.contains("C:\\Users") ||
        imageUrl.toLowerCase().startsWith("file:///") ||
        imageUrl.startsWith("//") || // Protocol-relative URLs
        (!imageUrl.toLowerCase().startsWith("http://") && 
         !imageUrl.toLowerCase().startsWith("https://"))) {
      return '';
    }

    // Ensure URL is properly encoded
    try {
      final uri = Uri.parse(imageUrl.trim());
      if (uri.scheme.isEmpty || (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https'))) {
        return '';
      }
      return uri.toString();
    } catch (e) {
      debugPrint('Invalid image URL: $imageUrl');
      return '';
    }
  }

  /// Check if the event has a valid image URL
  bool get hasValidImage => safeImageUrl.isNotEmpty;
}
