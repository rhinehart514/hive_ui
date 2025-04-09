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
  
  /// Whether this is a recurring event
  final bool isRecurring;
  
  /// Frequency for recurring events (daily, weekly, monthly, yearly)
  final String? recurrenceFrequency;
  
  /// Interval for recurring events (e.g., every 2 weeks)
  final int? recurrenceInterval;
  
  /// End date for the recurrence
  final DateTime? recurrenceEndDate;
  
  /// Maximum number of occurrences for recurrence
  final int? maxOccurrences;
  
  /// Days of week for weekly recurrence (0-6, where 0 is Sunday)
  final List<int>? daysOfWeek;
  
  /// Day of month for monthly recurrence (1-31)
  final int? dayOfMonth;
  
  /// Week of month for monthly recurrence (1-5, where 5 means last week)
  final int? weekOfMonth;
  
  /// Month of year for yearly recurrence (1-12)
  final int? monthOfYear;
  
  /// Whether monthly recurrence is by day of week rather than day of month
  final bool? byDayOfWeek;

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
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.maxOccurrences,
    this.daysOfWeek,
    this.dayOfMonth,
    this.weekOfMonth,
    this.monthOfYear,
    this.byDayOfWeek,
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

    // Validate recurring event parameters if this is a recurring event
    if (isRecurring) {
      if (recurrenceFrequency == null) {
        return 'Recurrence frequency is required for recurring events';
      }
      
      if (recurrenceInterval == null || recurrenceInterval! <= 0) {
        return 'Recurrence interval must be a positive number';
      }
      
      if (recurrenceFrequency == 'weekly' && (daysOfWeek == null || daysOfWeek!.isEmpty)) {
        return 'Days of week must be specified for weekly recurrence';
      }
      
      if (recurrenceEndDate != null && recurrenceEndDate!.isBefore(startDate)) {
        return 'Recurrence end date must be after event start date';
      }
      
      if (maxOccurrences != null && maxOccurrences! <= 0) {
        return 'Maximum occurrences must be a positive number';
      }
      
      if (recurrenceFrequency == 'monthly' && byDayOfWeek == true) {
        if (weekOfMonth == null || weekOfMonth! < 1 || weekOfMonth! > 5) {
          return 'Week of month must be between 1 and 5 for monthly recurrence by day of week';
        }
      }
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
    bool? isRecurring,
    String? recurrenceFrequency,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    int? maxOccurrences,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? weekOfMonth,
    int? monthOfYear,
    bool? byDayOfWeek,
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
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      byDayOfWeek: byDayOfWeek ?? this.byDayOfWeek,
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
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'weekOfMonth': weekOfMonth,
      'monthOfYear': monthOfYear,
      'byDayOfWeek': byDayOfWeek,
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
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrenceFrequency: json['recurrenceFrequency'] as String?,
      recurrenceInterval: json['recurrenceInterval'] as int?,
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'] as String)
          : null,
      maxOccurrences: json['maxOccurrences'] as int?,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'] as List)
          : null,
      dayOfMonth: json['dayOfMonth'] as int?,
      weekOfMonth: json['weekOfMonth'] as int?,
      monthOfYear: json['monthOfYear'] as int?,
      byDayOfWeek: json['byDayOfWeek'] as bool?,
    );
  }
}
