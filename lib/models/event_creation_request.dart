
/// Request model for creating events
class EventCreationRequest {
  /// Title of the event
  final String title;

  /// Description of the event
  final String description;

  /// Location where the event will take place
  final String location;

  /// Start date and time of the event
  final DateTime startDate;

  /// End date and time of the event
  final DateTime endDate;

  /// Category of the event (e.g., Social, Academic, etc.)
  final String category;

  /// Email of the organizer
  final String organizerEmail;

  /// Name of the organizer (person or club)
  final String organizerName;

  /// Visibility of the event (public, friends, private)
  final String visibility;

  /// Tags for the event
  final List<String> tags;

  /// URL to an image representing the event
  final String imageUrl;

  /// Whether this is a club event
  final bool isClubEvent;

  /// ID of the club if it's a club event
  final String? clubId;

  /// Constructor for EventCreationRequest
  const EventCreationRequest({
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.category = 'Social',
    this.organizerEmail = '',
    this.organizerName = '',
    this.visibility = 'public',
    this.tags = const [],
    this.imageUrl = '',
    this.isClubEvent = false,
    this.clubId,
  });

  /// Validates that the request contains all required fields
  /// Returns an error message if validation fails, or null if validation passes
  String? validate() {
    if (title.isEmpty) {
      return 'Event title is required';
    }

    if (description.isEmpty) {
      return 'Event description is required';
    }

    if (location.isEmpty) {
      return 'Event location is required';
    }

    if (startDate.isAfter(endDate)) {
      return 'Start time must be before end time';
    }

    if (startDate.isBefore(DateTime.now())) {
      return 'Start time must be in the future';
    }

    if (isClubEvent && (clubId == null || clubId!.isEmpty)) {
      return 'Club ID is required for club events';
    }

    return null;
  }

  /// Creates a copy of this request with the given fields replaced with new values
  EventCreationRequest copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? organizerEmail,
    String? organizerName,
    String? visibility,
    List<String>? tags,
    String? imageUrl,
    bool? isClubEvent,
    String? clubId,
  }) {
    return EventCreationRequest(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerName: organizerName ?? this.organizerName,
      visibility: visibility ?? this.visibility,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      isClubEvent: isClubEvent ?? this.isClubEvent,
      clubId: clubId ?? this.clubId,
    );
  }

  /// Converts the request to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': category,
      'organizerEmail': organizerEmail,
      'organizerName': organizerName,
      'visibility': visibility,
      'tags': tags,
      'imageUrl': imageUrl,
      'isClubEvent': isClubEvent,
      'clubId': clubId,
    };
  }

  /// Creates an EventCreationRequest from a JSON object
  factory EventCreationRequest.fromJson(Map<String, dynamic> json) {
    return EventCreationRequest(
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      category: json['category'] as String? ?? 'Social',
      organizerEmail: json['organizerEmail'] as String? ?? '',
      organizerName: json['organizerName'] as String? ?? '',
      visibility: json['visibility'] as String? ?? 'public',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      imageUrl: json['imageUrl'] as String? ?? '',
      isClubEvent: json['isClubEvent'] as bool? ?? false,
      clubId: json['clubId'] as String?,
    );
  }
}
