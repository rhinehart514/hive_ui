import 'package:cloud_firestore/cloud_firestore.dart';

/// Scheduling status for content
enum SchedulingStatus {
  /// Content is scheduled for future publication
  scheduled,
  
  /// Content is currently being published
  publishing,
  
  /// Content has been published
  published,
  
  /// Content publication failed
  failed,
  
  /// Content publication was cancelled
  cancelled,
}

/// Recurrence pattern for scheduled content
enum RecurrencePattern {
  /// Content is published once
  once,
  
  /// Content is published daily
  daily,
  
  /// Content is published weekly
  weekly,
  
  /// Content is published monthly
  monthly,
}

/// Model for scheduled content in the data layer
class ScheduledContentModel {
  /// Unique identifier for the scheduled content
  final String id;
  
  /// Reference to the content document ID
  final String contentId;
  
  /// The type of content (post, event, announcement, etc.)
  final String contentType;
  
  /// User ID of the content creator
  final String creatorId;
  
  /// Space ID if posted to a space
  final String? spaceId;
  
  /// Current status of the scheduled content
  final SchedulingStatus status;
  
  /// When to publish the content
  final DateTime scheduledTime;
  
  /// When the content was actually published (if it was)
  final DateTime? publishedTime;
  
  /// Whether to notify users when published
  final bool sendNotification;
  
  /// Custom notification text
  final String? notificationText;
  
  /// Audience targeting options
  final Map<String, dynamic> targetingOptions;
  
  /// Error message if publication failed
  final String? errorMessage;
  
  /// When the scheduled content was created
  final DateTime createdAt;
  
  /// When the scheduled content was last updated
  final DateTime updatedAt;
  
  /// For recurring content, the pattern of recurrence
  final RecurrencePattern? recurrencePattern;
  
  /// For recurring content, when to end recurrence (null for indefinite)
  final DateTime? recurrenceEndDate;
  
  /// For recurring content, how many times to repeat (null for indefinite)
  final int? recurrenceCount;
  
  /// For recurring content, the parent scheduled content ID
  final String? parentScheduleId;
  
  /// Constructor
  ScheduledContentModel({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.creatorId,
    this.spaceId,
    required this.status,
    required this.scheduledTime,
    this.publishedTime,
    this.sendNotification = true,
    this.notificationText,
    this.targetingOptions = const {},
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.recurrencePattern,
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.parentScheduleId,
  });
  
  /// Create a copy with modified fields
  ScheduledContentModel copyWith({
    String? id,
    String? contentId,
    String? contentType,
    String? creatorId,
    String? spaceId,
    SchedulingStatus? status,
    DateTime? scheduledTime,
    DateTime? publishedTime,
    bool? sendNotification,
    String? notificationText,
    Map<String, dynamic>? targetingOptions,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    RecurrencePattern? recurrencePattern,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
    String? parentScheduleId,
  }) {
    return ScheduledContentModel(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      creatorId: creatorId ?? this.creatorId,
      spaceId: spaceId ?? this.spaceId,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      publishedTime: publishedTime ?? this.publishedTime,
      sendNotification: sendNotification ?? this.sendNotification,
      notificationText: notificationText ?? this.notificationText,
      targetingOptions: targetingOptions ?? this.targetingOptions,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
      parentScheduleId: parentScheduleId ?? this.parentScheduleId,
    );
  }
  
  /// Create from Firestore document
  factory ScheduledContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse status
    final statusStr = data['status'] as String? ?? 'scheduled';
    final status = SchedulingStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => SchedulingStatus.scheduled,
    );
    
    // Parse recurrence pattern if present
    RecurrencePattern? recurrencePattern;
    if (data['recurrencePattern'] != null) {
      final patternStr = data['recurrencePattern'] as String;
      recurrencePattern = RecurrencePattern.values.firstWhere(
        (e) => e.toString().split('.').last == patternStr,
        orElse: () => RecurrencePattern.once,
      );
    }
    
    return ScheduledContentModel(
      id: doc.id,
      contentId: data['contentId'] as String? ?? '',
      contentType: data['contentType'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      spaceId: data['spaceId'] as String?,
      status: status,
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedTime: (data['publishedTime'] as Timestamp?)?.toDate(),
      sendNotification: data['sendNotification'] as bool? ?? true,
      notificationText: data['notificationText'] as String?,
      targetingOptions: data['targetingOptions'] as Map<String, dynamic>? ?? {},
      errorMessage: data['errorMessage'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recurrencePattern: recurrencePattern,
      recurrenceEndDate: (data['recurrenceEndDate'] as Timestamp?)?.toDate(),
      recurrenceCount: data['recurrenceCount'] as int?,
      parentScheduleId: data['parentScheduleId'] as String?,
    );
  }
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> result = {
      'contentId': contentId,
      'contentType': contentType,
      'creatorId': creatorId,
      'status': status.toString().split('.').last,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'sendNotification': sendNotification,
      'targetingOptions': targetingOptions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    
    // Add optional fields if present
    if (spaceId != null) result['spaceId'] = spaceId;
    if (publishedTime != null) result['publishedTime'] = Timestamp.fromDate(publishedTime!);
    if (notificationText != null) result['notificationText'] = notificationText;
    if (errorMessage != null) result['errorMessage'] = errorMessage;
    if (recurrencePattern != null) result['recurrencePattern'] = recurrencePattern.toString().split('.').last;
    if (recurrenceEndDate != null) result['recurrenceEndDate'] = Timestamp.fromDate(recurrenceEndDate!);
    if (recurrenceCount != null) result['recurrenceCount'] = recurrenceCount;
    if (parentScheduleId != null) result['parentScheduleId'] = parentScheduleId;
    
    return result;
  }
  
  /// Check if this scheduled content is ready to publish
  bool get isReadyToPublish => 
      status == SchedulingStatus.scheduled && 
      scheduledTime.isBefore(DateTime.now());
  
  /// Check if this is a recurring schedule
  bool get isRecurring => recurrencePattern != null && recurrencePattern != RecurrencePattern.once;
  
  /// Check if recurrence should continue
  bool shouldContinueRecurrence() {
    if (!isRecurring) return false;
    
    final now = DateTime.now();
    
    // Check end date
    if (recurrenceEndDate != null && recurrenceEndDate!.isBefore(now)) {
      return false;
    }
    
    // Check count (implementation would need to track how many instances have been created)
    // This would require additional logic in a service to track recurrence count
    
    return true;
  }
  
  /// Calculate the next occurrence date based on recurrence pattern
  DateTime? calculateNextOccurrence() {
    if (!isRecurring) return null;
    
    final DateTime baseDate = publishedTime ?? scheduledTime;
    
    switch (recurrencePattern!) {
      case RecurrencePattern.once:
        return null;
      case RecurrencePattern.daily:
        return baseDate.add(const Duration(days: 1));
      case RecurrencePattern.weekly:
        return baseDate.add(const Duration(days: 7));
      case RecurrencePattern.monthly:
        // Simple approach - same day next month (with adjustments for month lengths)
        final nextMonth = baseDate.month < 12 
            ? DateTime(baseDate.year, baseDate.month + 1, 1)
            : DateTime(baseDate.year + 1, 1, 1);
        
        // Calculate the max days in the next month
        final daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final targetDay = baseDate.day > daysInNextMonth ? daysInNextMonth : baseDate.day;
        
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          targetDay,
          baseDate.hour,
          baseDate.minute,
          baseDate.second,
        );
    }
  }
} 