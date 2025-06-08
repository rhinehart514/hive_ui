import 'package:hive_ui/models/event.dart';
import 'attendance_record.dart';

/// Defines the frequency of a recurring event
enum RecurrenceFrequency {
  /// Daily recurring events
  daily,
  
  /// Weekly recurring events
  weekly,
  
  /// Monthly recurring events
  monthly,
  
  /// Yearly recurring events
  yearly,
}

/// Defines the days of the week for weekly recurrence
enum RecurrenceDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// Represents a recurring event pattern
class RecurrencePattern {
  /// Frequency of recurrence
  final RecurrenceFrequency frequency;
  
  /// Interval between occurrences (e.g., every 2 weeks)
  final int interval;
  
  /// End date for the recurrence (null means no end date)
  final DateTime? endDate;
  
  /// Maximum number of occurrences (null means no limit)
  final int? maxOccurrences;
  
  /// Days of the week for weekly recurrence
  final List<RecurrenceDay>? daysOfWeek;
  
  /// Day of month for monthly recurrence (1-31)
  final int? dayOfMonth;
  
  /// Week of month for monthly recurrence (1-5, where 5 means last week)
  final int? weekOfMonth;
  
  /// Month of year for yearly recurrence (1-12)
  final int? monthOfYear;
  
  /// Whether the recurrence is based on the day of the week (e.g., "first Monday") rather than day of month
  final bool byDayOfWeek;
  
  RecurrencePattern({
    required this.frequency,
    this.interval = 1,
    this.endDate,
    this.maxOccurrences,
    this.daysOfWeek,
    this.dayOfMonth,
    this.weekOfMonth,
    this.monthOfYear,
    this.byDayOfWeek = false,
  }) : assert(
          (frequency != RecurrenceFrequency.weekly || daysOfWeek != null),
          'Days of week must be specified for weekly recurrence',
        );
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.toString().split('.').last,
      'interval': interval,
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'daysOfWeek': daysOfWeek?.map((day) => day.toString().split('.').last).toList(),
      'dayOfMonth': dayOfMonth,
      'weekOfMonth': weekOfMonth,
      'monthOfYear': monthOfYear,
      'byDayOfWeek': byDayOfWeek,
    };
  }
  
  /// Create from JSON
  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      frequency: _parseFrequency(json['frequency']),
      interval: json['interval'] as int? ?? 1,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      maxOccurrences: json['maxOccurrences'] as int?,
      daysOfWeek: json['daysOfWeek'] != null
          ? (json['daysOfWeek'] as List)
              .map((day) => _parseRecurrenceDay(day))
              .toList()
          : null,
      dayOfMonth: json['dayOfMonth'] as int?,
      weekOfMonth: json['weekOfMonth'] as int?,
      monthOfYear: json['monthOfYear'] as int?,
      byDayOfWeek: json['byDayOfWeek'] as bool? ?? false,
    );
  }
  
  /// Helper method to parse frequency enum
  static RecurrenceFrequency _parseFrequency(String? value) {
    if (value == null) return RecurrenceFrequency.weekly;
    
    switch (value.toLowerCase()) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      case 'yearly':
        return RecurrenceFrequency.yearly;
      case 'weekly':
      default:
        return RecurrenceFrequency.weekly;
    }
  }
  
  /// Helper method to parse day enum
  static RecurrenceDay _parseRecurrenceDay(String? value) {
    if (value == null) return RecurrenceDay.monday;
    
    switch (value.toLowerCase()) {
      case 'monday':
        return RecurrenceDay.monday;
      case 'tuesday':
        return RecurrenceDay.tuesday;
      case 'wednesday':
        return RecurrenceDay.wednesday;
      case 'thursday':
        return RecurrenceDay.thursday;
      case 'friday':
        return RecurrenceDay.friday;
      case 'saturday':
        return RecurrenceDay.saturday;
      case 'sunday':
        return RecurrenceDay.sunday;
      default:
        return RecurrenceDay.monday;
    }
  }
  
  /// Calculate the next occurrence date after a given date
  DateTime getNextOccurrence(DateTime after, DateTime baseDate) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _getNextDailyOccurrence(after, baseDate);
      case RecurrenceFrequency.weekly:
        return _getNextWeeklyOccurrence(after, baseDate);
      case RecurrenceFrequency.monthly:
        return _getNextMonthlyOccurrence(after, baseDate);
      case RecurrenceFrequency.yearly:
        return _getNextYearlyOccurrence(after, baseDate);
    }
  }
  
  /// Calculate the next daily occurrence
  DateTime _getNextDailyOccurrence(DateTime after, DateTime baseDate) {
    // Start from the baseDate
    DateTime nextDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    
    // Move forward until we find a date after the 'after' parameter
    while (!nextDate.isAfter(after)) {
      nextDate = nextDate.add(Duration(days: interval));
    }
    
    // Return with same time components as the base date
    return DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      baseDate.hour,
      baseDate.minute,
      baseDate.second,
    );
  }
  
  /// Calculate the next weekly occurrence
  DateTime _getNextWeeklyOccurrence(DateTime after, DateTime baseDate) {
    // Ensure we have days of week
    if (daysOfWeek == null || daysOfWeek!.isEmpty) {
      // Default to the day of week of the base date
      final baseDayOfWeek = baseDate.weekday; // 1-7 (Monday-Sunday)
      final recurrenceDay = RecurrenceDay.values[baseDayOfWeek - 1];
      return _getNextWeeklyOccurrenceForDay(after, baseDate, [recurrenceDay]);
    }
    
    // Sort days of week
    final sortedDays = [...daysOfWeek!];
    sortedDays.sort((a, b) => a.index.compareTo(b.index));
    
    // Find the closest day of week after the 'after' date
    return _getNextWeeklyOccurrenceForDay(after, baseDate, sortedDays);
  }
  
  /// Helper for weekly recurrences
  DateTime _getNextWeeklyOccurrenceForDay(
    DateTime after, 
    DateTime baseDate, 
    List<RecurrenceDay> days
  ) {
    // Current day of week (1-7, Monday-Sunday)
    final afterDayOfWeek = after.weekday;
    
    // Find the next day in the recurrence pattern
    RecurrenceDay? nextDay;
    for (final day in days) {
      // Convert RecurrenceDay to weekday (1-7)
      final dayValue = day.index + 1;
      
      if (dayValue > afterDayOfWeek) {
        nextDay = day;
        break;
      }
    }
    
    // If no day found, take the first day but add a week
    DateTime result;
    if (nextDay == null) {
      nextDay = days.first;
      // Add days needed to reach the day of week, plus a week
      final daysToAdd = (nextDay.index + 1 - afterDayOfWeek + 7) % 7;
      result = after.add(Duration(days: daysToAdd + (7 * (interval - 1))));
    } else {
      // Add days needed to reach the next day of week
      final daysToAdd = (nextDay.index + 1 - afterDayOfWeek) % 7;
      result = after.add(Duration(days: daysToAdd));
    }
    
    // Return with same time components as the base date
    return DateTime(
      result.year,
      result.month,
      result.day,
      baseDate.hour,
      baseDate.minute,
      baseDate.second,
    );
  }
  
  /// Calculate the next monthly occurrence
  DateTime _getNextMonthlyOccurrence(DateTime after, DateTime baseDate) {
    if (byDayOfWeek && weekOfMonth != null) {
      // Monthly by week of month and day of week (e.g., "first Monday")
      return _getNextMonthlyByWeekAndDay(after, baseDate);
    } else {
      // Monthly by day of month (e.g., "the 15th of each month")
      return _getNextMonthlyByDay(after, baseDate);
    }
  }
  
  /// Helper for monthly recurrence by day of month
  DateTime _getNextMonthlyByDay(DateTime after, DateTime baseDate) {
    // Use the day of month from either the pattern or the base date
    final targetDayOfMonth = dayOfMonth ?? baseDate.day;
    
    // Start with the month of the 'after' date
    int year = after.year;
    int month = after.month;
    
    // If we're past the target day in the current month, move to next month
    if (after.day >= targetDayOfMonth) {
      month += interval;
      if (month > 12) {
        year += (month - 1) ~/ 12;
        month = ((month - 1) % 12) + 1;
      }
    }
    
    // Adjust for months with fewer days
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final adjustedDay = targetDayOfMonth > daysInMonth ? daysInMonth : targetDayOfMonth;
    
    // Create the result date with the same time components
    return DateTime(
      year,
      month,
      adjustedDay,
      baseDate.hour,
      baseDate.minute,
      baseDate.second,
    );
  }
  
  /// Helper for monthly recurrence by week of month and day of week
  DateTime _getNextMonthlyByWeekAndDay(DateTime after, DateTime baseDate) {
    // Get the day of week from the base date (or first day if daysOfWeek specified)
    final targetDayOfWeek = daysOfWeek != null && daysOfWeek!.isNotEmpty
        ? daysOfWeek!.first.index + 1 // 1-7 (Monday-Sunday)
        : baseDate.weekday;
    
    // Get the week of month (or from base date if not specified)
    final targetWeekOfMonth = weekOfMonth ?? ((baseDate.day - 1) ~/ 7) + 1;
    
    // Start with the month of the 'after' date
    int year = after.year;
    int month = after.month;
    
    // Calculate the occurrence for the current month
    DateTime occurrence = _findDayInMonth(year, month, targetDayOfWeek, targetWeekOfMonth);
    
    // If the occurrence is not after the 'after' date, move to next interval months
    if (!occurrence.isAfter(after)) {
      month += interval;
      if (month > 12) {
        year += (month - 1) ~/ 12;
        month = ((month - 1) % 12) + 1;
      }
      occurrence = _findDayInMonth(year, month, targetDayOfWeek, targetWeekOfMonth);
    }
    
    // Set the time components from the base date
    return DateTime(
      occurrence.year,
      occurrence.month,
      occurrence.day,
      baseDate.hour,
      baseDate.minute,
      baseDate.second,
    );
  }
  
  /// Helper to find a specific day in a month (e.g., "Third Monday")
  DateTime _findDayInMonth(int year, int month, int dayOfWeek, int weekOfMonth) {
    // Find the first day of the month
    final firstOfMonth = DateTime(year, month, 1);
    
    // Calculate days to add to get to the first occurrence of the target day
    final daysToAdd = (dayOfWeek - firstOfMonth.weekday + 7) % 7;
    
    // Calculate the day for the first occurrence of this day in the month
    int targetDay = 1 + daysToAdd;
    
    // Add weeks as needed
    targetDay += (weekOfMonth - 1) * 7;
    
    // Check if this exceeds the month length and handle "last" week
    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (targetDay > daysInMonth) {
      // If weekOfMonth is 5 (last), get the last occurrence of that day
      if (weekOfMonth == 5) {
        targetDay = targetDay - 7;
      } else {
        // Otherwise, this combination doesn't exist in this month
        // Return the first day of next month as a fallback
        return DateTime(year, month + 1, 1);
      }
    }
    
    return DateTime(year, month, targetDay);
  }
  
  /// Calculate the next yearly occurrence
  DateTime _getNextYearlyOccurrence(DateTime after, DateTime baseDate) {
    // Get month and day from pattern or base date
    final targetMonth = monthOfYear ?? baseDate.month;
    final targetDay = dayOfMonth ?? baseDate.day;
    
    // Start with the year of the 'after' date
    int year = after.year;
    
    // Create a date for this year's occurrence
    final occurrence = DateTime(
      year,
      targetMonth,
      targetDay,
      baseDate.hour,
      baseDate.minute,
      baseDate.second,
    );
    
    // If the occurrence is not after the 'after' date, increment the year by the interval
    if (!occurrence.isAfter(after)) {
      year += interval;
      return DateTime(
        year,
        targetMonth,
        targetDay,
        baseDate.hour,
        baseDate.minute,
        baseDate.second,
      );
    }
    
    return occurrence;
  }
  
  /// Generate the next n occurrences after a given date
  List<DateTime> generateNextOccurrences(DateTime after, DateTime baseDate, {int count = 10}) {
    final List<DateTime> occurrences = [];
    DateTime currentDate = after;
    
    while (occurrences.length < count) {
      currentDate = getNextOccurrence(currentDate, baseDate);
      
      // Check if we've reached the end date
      if (endDate != null && currentDate.isAfter(endDate!)) {
        break;
      }
      
      occurrences.add(currentDate);
      
      // Increment current date by a small amount to find the next occurrence
      currentDate = currentDate.add(const Duration(minutes: 1));
    }
    
    return occurrences;
  }
  
  /// Copy with new values
  RecurrencePattern copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    DateTime? endDate,
    int? maxOccurrences,
    List<RecurrenceDay>? daysOfWeek,
    int? dayOfMonth,
    int? weekOfMonth,
    int? monthOfYear,
    bool? byDayOfWeek,
  }) {
    return RecurrencePattern(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      byDayOfWeek: byDayOfWeek ?? this.byDayOfWeek,
    );
  }
}

/// Represents a recurring event with pattern
class RecurringEvent extends Event {
  /// The recurrence pattern for this event
  final RecurrencePattern recurrencePattern;
  
  /// The ID of the parent recurring event (if this is an instance)
  final String? parentEventId;
  
  /// Whether this instance has been modified from its original pattern
  final bool isModifiedInstance;
  
  /// The original date of this instance (before any modifications)
  final DateTime? originalDate;
  
  /// RecurringEvent constructor
  RecurringEvent({
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
    required String imageUrl,
    required List<String> tags,
    required EventSource source,
    required String? createdBy,
    required DateTime? lastModified,
    required String visibility,
    required List<String> attendees,
    required String? spaceId,
    required List<String> reposts,
    required EventOrganizer? organizer,
    required bool? isAttending,
    required this.recurrencePattern,
    required this.parentEventId,
    required this.isModifiedInstance,
    required this.originalDate,
    required String? originalTitle,
    required Map<String, AttendanceRecord>? attendance,
    required int? capacity,
    required List<String> waitlist,
    required EventLifecycleState state,
    required DateTime stateUpdatedAt,
    required List<EventStateHistoryEntry> stateHistory,
    required bool published,
    bool isBoosted = false,
    DateTime? boostTimestamp,
    bool isHoneyMode = false,
    DateTime? honeyModeTimestamp,
  }) : super(
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
      attendance: attendance,
      capacity: capacity,
      waitlist: waitlist,
      state: state,
      stateUpdatedAt: stateUpdatedAt,
      stateHistory: stateHistory,
      published: published,
      isBoosted: isBoosted,
      boostTimestamp: boostTimestamp,
      isHoneyMode: isHoneyMode,
      honeyModeTimestamp: honeyModeTimestamp,
    );
  
  /// Create a recurring event from a regular event
  factory RecurringEvent.fromEvent(
    Event event, 
    RecurrencePattern recurrencePattern
  ) {
    return RecurringEvent(
      id: event.id,
      title: event.title,
      description: event.description,
      location: event.location,
      startDate: event.startDate,
      endDate: event.endDate,
      organizerEmail: event.organizerEmail,
      organizerName: event.organizerName,
      category: event.category,
      status: event.status,
      link: event.link,
      imageUrl: event.imageUrl,
      tags: event.tags,
      source: event.source,
      createdBy: event.createdBy,
      lastModified: event.lastModified,
      visibility: event.visibility,
      attendees: event.attendees,
      spaceId: event.spaceId,
      reposts: event.reposts,
      organizer: event.organizer,
      recurrencePattern: recurrencePattern,
      parentEventId: null,
      isModifiedInstance: false,
      originalDate: null,
      attendance: event.attendance,
      capacity: event.capacity,
      waitlist: event.waitlist,
      state: event.state,
      stateUpdatedAt: event.stateUpdatedAt,
      stateHistory: event.stateHistory,
      published: event.published,
      isAttending: event.isAttending,
      originalTitle: event.originalTitle,
      isBoosted: event.isBoosted,
      boostTimestamp: event.boostTimestamp,
      isHoneyMode: event.isHoneyMode,
      honeyModeTimestamp: event.honeyModeTimestamp,
    );
  }
  
  /// Factory for creating a user recurring event
  factory RecurringEvent.createUserRecurringEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
    required RecurrencePattern recurrencePattern,
    String category = 'User',
    String organizerEmail = '',
    String organizerName = '',
    String visibility = 'public',
    List<String> tags = const [],
    String imageUrl = '',
  }) {
    final id = 'recurring_user_${DateTime.now().millisecondsSinceEpoch}_$userId';

    return RecurringEvent(
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
      lastModified: DateTime.now(),
      visibility: visibility,
      attendees: [userId],
      spaceId: null,
      reposts: const [],
      organizer: null,
      isAttending: true,
      recurrencePattern: recurrencePattern,
      parentEventId: null,
      isModifiedInstance: false,
      originalDate: null,
      attendance: const {},
      capacity: 0,
      waitlist: const [],
      state: EventLifecycleState.draft,
      stateUpdatedAt: DateTime.now(),
      stateHistory: const [],
      published: false,
      originalTitle: null,
      isBoosted: false,
      boostTimestamp: null,
      isHoneyMode: false,
      honeyModeTimestamp: null,
    );
  }
  
  /// Factory for creating a club recurring event
  factory RecurringEvent.createClubRecurringEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String clubId,
    required String clubName,
    required String creatorId,
    required RecurrencePattern recurrencePattern,
    String category = 'Club',
    String organizerEmail = '',
    String visibility = 'public',
    List<String> tags = const [],
    String imageUrl = '',
  }) {
    final id = 'recurring_club_${DateTime.now().millisecondsSinceEpoch}_$clubId';

    return RecurringEvent(
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
      lastModified: DateTime.now(),
      visibility: visibility,
      attendees: [creatorId],
      spaceId: clubId,
      reposts: const [],
      organizer: EventOrganizer(
        id: clubId,
        name: clubName,
        isVerified: true,
      ),
      recurrencePattern: recurrencePattern,
      parentEventId: null,
      isModifiedInstance: false,
      originalDate: null,
      attendance: const {},
      capacity: 0,
      waitlist: const [],
      state: EventLifecycleState.draft,
      stateUpdatedAt: DateTime.now(),
      stateHistory: const [],
      published: false,
      originalTitle: null,
      isAttending: true,
      isBoosted: false,
      boostTimestamp: null,
      isHoneyMode: false,
      honeyModeTimestamp: null,
    );
  }
  
  /// Create an instance of a recurring event series
  RecurringEvent createInstance(DateTime instanceDate) {
    // Calculate the duration of the event
    final duration = endDate.difference(startDate);
    
    // Create start and end dates for the instance
    final instanceStartDate = DateTime(
      instanceDate.year,
      instanceDate.month,
      instanceDate.day,
      startDate.hour,
      startDate.minute,
      startDate.second,
    );
    
    final instanceEndDate = instanceStartDate.add(duration);
    
    // Generate an ID for the instance
    final instanceId = 'instance_${id}_${instanceDate.millisecondsSinceEpoch}';
    
    return RecurringEvent(
      id: instanceId,
      title: title,
      description: description,
      location: location,
      startDate: instanceStartDate,
      endDate: instanceEndDate,
      organizerEmail: organizerEmail,
      organizerName: organizerName,
      category: category,
      status: status,
      link: link,
      imageUrl: imageUrl,
      tags: tags,
      source: source,
      createdBy: createdBy,
      lastModified: DateTime.now(),
      visibility: visibility,
      attendees: attendees,
      spaceId: spaceId,
      reposts: reposts,
      organizer: organizer,
      recurrencePattern: recurrencePattern,
      parentEventId: id,
      isModifiedInstance: false,
      originalDate: instanceDate,
      attendance: attendance,
      capacity: capacity,
      waitlist: waitlist,
      state: state,
      stateUpdatedAt: stateUpdatedAt,
      stateHistory: stateHistory,
      published: published,
      isAttending: isAttending,
      originalTitle: originalTitle,
      isBoosted: isBoosted,
      boostTimestamp: boostTimestamp,
      isHoneyMode: isHoneyMode,
      honeyModeTimestamp: honeyModeTimestamp,
    );
  }

  /// Generate the next N instances of this recurring event
  List<RecurringEvent> generateNextInstances({int count = 10}) {
    final now = DateTime.now();
    final occurrences = recurrencePattern.generateNextOccurrences(now, startDate, count: count);
    
    return occurrences.map((date) => createInstance(date)).toList();
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toMap();
    
    // Add recurring event fields
    json['recurrencePattern'] = recurrencePattern.toJson();
    json['isRecurring'] = true;
    json['parentEventId'] = parentEventId;
    json['isModifiedInstance'] = isModifiedInstance;
    if (originalDate != null) {
      json['originalDate'] = originalDate!.toIso8601String();
    }
    
    return json;
  }
  
  /// Create from JSON
  static RecurringEvent fromJson(Map<String, dynamic> json) {
    // Extract basic event data
    final event = Event.fromJson(json);
    
    // Extract recurrence pattern
    final recurrencePatternJson = json['recurrencePattern'] as Map<String, dynamic>;
    final recurrencePattern = RecurrencePattern.fromJson(recurrencePatternJson);
    
    return RecurringEvent(
      id: event.id,
      title: event.title,
      description: event.description,
      location: event.location,
      startDate: event.startDate,
      endDate: event.endDate,
      organizerEmail: event.organizerEmail,
      organizerName: event.organizerName,
      category: event.category,
      status: event.status,
      link: event.link,
      imageUrl: event.imageUrl,
      tags: event.tags,
      source: event.source,
      createdBy: event.createdBy,
      lastModified: event.lastModified,
      visibility: event.visibility,
      attendees: event.attendees,
      spaceId: event.spaceId,
      reposts: event.reposts,
      organizer: event.organizer,
      recurrencePattern: recurrencePattern,
      parentEventId: json['parentEventId'] as String?,
      isModifiedInstance: json['isModifiedInstance'] as bool? ?? false,
      originalDate: json['originalDate'] != null 
          ? DateTime.parse(json['originalDate'] as String) 
          : null,
      attendance: event.attendance,
      capacity: event.capacity,
      waitlist: event.waitlist,
      state: event.state,
      stateUpdatedAt: event.stateUpdatedAt,
      stateHistory: event.stateHistory,
      published: event.published,
      isAttending: event.isAttending,
      originalTitle: event.originalTitle,
      isBoosted: event.isBoosted,
      boostTimestamp: event.boostTimestamp,
      isHoneyMode: event.isHoneyMode,
      honeyModeTimestamp: event.honeyModeTimestamp,
    );
  }
  
  @override
  RecurringEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? link,
    String? imageUrl,
    List<String>? tags,
    String? status,
    String? visibility,
    EventOrganizer? organizer,
    String? organizerName,
    String? organizerEmail,
    List<String>? attendees,
    List<String>? reposts,
    String? createdBy,
    String? spaceId,
    DateTime? lastModified,
    bool? isAttending,
    String? originalTitle,
    bool? isModifiedInstance,
    DateTime? originalDate,
    String? parentEventId,
    RecurrencePattern? recurrencePattern,
    Map<String, AttendanceRecord>? attendance,
    int? capacity,
    List<String>? waitlist,
    EventSource? source,
    EventLifecycleState? state,
    DateTime? stateUpdatedAt,
    List<EventStateHistoryEntry>? stateHistory,
    bool? published,
    bool? isBoosted,
    DateTime? boostTimestamp,
    bool? isHoneyMode,
    DateTime? honeyModeTimestamp,
  }) {
    return RecurringEvent(
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
      isAttending: isAttending ?? this.isAttending,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      parentEventId: parentEventId ?? this.parentEventId,
      isModifiedInstance: isModifiedInstance ?? this.isModifiedInstance,
      originalDate: originalDate ?? this.originalDate,
      originalTitle: originalTitle ?? this.originalTitle,
      attendance: attendance ?? this.attendance,
      capacity: capacity ?? this.capacity,
      waitlist: waitlist ?? this.waitlist,
      state: state ?? this.state,
      stateUpdatedAt: stateUpdatedAt ?? this.stateUpdatedAt,
      stateHistory: stateHistory ?? this.stateHistory,
      published: published ?? this.published,
      isBoosted: isBoosted ?? this.isBoosted,
      boostTimestamp: boostTimestamp ?? this.boostTimestamp,
      isHoneyMode: isHoneyMode ?? this.isHoneyMode,
      honeyModeTimestamp: honeyModeTimestamp ?? this.honeyModeTimestamp,
    );
  }
  
  /// Check if this event is a master/parent recurring event
  bool get isMasterEvent => parentEventId == null;
  
  /// Check if this event is an instance of a recurring series
  bool get isRecurrenceInstance => parentEventId != null;
} 