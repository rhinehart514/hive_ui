import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/features/feed/data/models/scheduled_content_model.dart';

/// Event emitted when content is published
class ContentPublishedEvent extends AppEvent {
  /// ID of the content
  final String contentId;
  
  /// Type of content
  final String contentType;
  
  /// ID of the schedule
  final String scheduleId;
  
  /// Time of publication
  final DateTime publishedAt;
  
  /// Constructor
  const ContentPublishedEvent({
    required this.contentId,
    required this.contentType,
    required this.scheduleId,
    required this.publishedAt,
  });
}

/// Event emitted when content publication fails
class ContentPublicationFailedEvent extends AppEvent {
  /// ID of the content
  final String contentId;
  
  /// ID of the schedule
  final String scheduleId;
  
  /// Error message
  final String errorMessage;
  
  /// Constructor
  const ContentPublicationFailedEvent({
    required this.contentId,
    required this.scheduleId,
    required this.errorMessage,
  });
}

/// Service for managing scheduled content
class ContentSchedulingService {
  final FirebaseFirestore _firestore;
  final AppEventBus _eventBus;
  
  Timer? _pollingTimer;
  bool _isProcessing = false;
  
  /// The collection where scheduled content is stored
  static const String scheduledContentCollection = 'scheduled_content';
  
  /// Constructor
  ContentSchedulingService({
    FirebaseFirestore? firestore,
    AppEventBus? eventBus,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _eventBus = eventBus ?? AppEventBus();
  
  /// Initialize the service and start polling
  Future<void> initialize() async {
    debugPrint('🕒 Content Scheduling Service: Initializing...');
    
    // Start polling for scheduled content
    _startPolling();
  }
  
  /// Dispose of resources
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
  
  /// Start polling for scheduled content
  void _startPolling() {
    // Cancel any existing timer
    _pollingTimer?.cancel();
    
    // Check every minute for content ready to publish
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkForReadyContent();
    });
    
    // Do an immediate check
    _checkForReadyContent();
  }
  
  /// Check for content that is ready to be published
  Future<void> _checkForReadyContent() async {
    // Avoid overlapping processing
    if (_isProcessing) return;
    _isProcessing = true;
    
    try {
      final now = DateTime.now();
      
      // Query for scheduled content that is ready to publish
      final snapshot = await _firestore
          .collection(scheduledContentCollection)
          .where('status', isEqualTo: SchedulingStatus.scheduled.toString().split('.').last)
          .where('scheduledTime', isLessThanOrEqualTo: now)
          .limit(10) // Process in batches for efficiency
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        debugPrint('🕒 Content Scheduling Service: Found ${snapshot.docs.length} items ready to publish');
        
        // Process each scheduled item
        for (final doc in snapshot.docs) {
          await _processScheduledContent(
            ScheduledContentModel.fromFirestore(doc),
          );
        }
      }
    } catch (e) {
      debugPrint('🕒 Content Scheduling Service Error: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Process a single scheduled content item
  Future<void> _processScheduledContent(ScheduledContentModel scheduledContent) async {
    // Update status to publishing
    await _updateScheduleStatus(
      scheduledContent.id, 
      SchedulingStatus.publishing,
    );
    
    try {
      // Publish the content
      await _publishContent(scheduledContent);
      
      // Update schedule with published status
      await _updateScheduleStatus(
        scheduledContent.id,
        SchedulingStatus.published,
        publishedTime: DateTime.now(),
      );
      
      // If this is a recurring schedule, create the next scheduled content
      if (scheduledContent.shouldContinueRecurrence()) {
        await _createNextRecurrence(scheduledContent);
      }
      
      // Emit publication event
      _eventBus.emit(ContentPublishedEvent(
        contentId: scheduledContent.contentId,
        contentType: scheduledContent.contentType,
        scheduleId: scheduledContent.id,
        publishedAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('🕒 Publication Error: $e');
      
      // Update with failure status
      await _updateScheduleStatus(
        scheduledContent.id,
        SchedulingStatus.failed,
        errorMessage: e.toString(),
      );
      
      // Emit failure event
      _eventBus.emit(ContentPublicationFailedEvent(
        contentId: scheduledContent.contentId,
        scheduleId: scheduledContent.id,
        errorMessage: e.toString(),
      ));
    }
  }
  
  /// Update the status of a scheduled content
  Future<void> _updateScheduleStatus(
    String scheduleId,
    SchedulingStatus status, {
    DateTime? publishedTime,
    String? errorMessage,
  }) async {
    final updates = <String, dynamic>{
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (publishedTime != null) {
      updates['publishedTime'] = Timestamp.fromDate(publishedTime);
    }
    
    if (errorMessage != null) {
      updates['errorMessage'] = errorMessage;
    }
    
    await _firestore
        .collection(scheduledContentCollection)
        .doc(scheduleId)
        .update(updates);
  }
  
  /// Publish the content by updating its status
  Future<void> _publishContent(ScheduledContentModel schedule) async {
    // Implementation will vary depending on content type
    switch (schedule.contentType) {
      case 'post':
        await _publishPost(schedule);
        break;
      case 'event':
        await _publishEvent(schedule);
        break;
      case 'announcement':
        await _publishAnnouncement(schedule);
        break;
      default:
        throw Exception('Unsupported content type: ${schedule.contentType}');
    }
    
    // Send notifications if configured
    if (schedule.sendNotification) {
      await _sendPublicationNotifications(schedule);
    }
  }
  
  /// Publish a post
  Future<void> _publishPost(ScheduledContentModel schedule) async {
    // Update the post's visibility status
    await _firestore
        .collection('posts')
        .doc(schedule.contentId)
        .update({
          'isPublished': true,
          'publishedAt': FieldValue.serverTimestamp(),
        });
  }
  
  /// Publish an event
  Future<void> _publishEvent(ScheduledContentModel schedule) async {
    // Update the event's visibility status
    await _firestore
        .collection('events')
        .doc(schedule.contentId)
        .update({
          'isPublished': true,
          'publishedAt': FieldValue.serverTimestamp(),
        });
  }
  
  /// Publish an announcement
  Future<void> _publishAnnouncement(ScheduledContentModel schedule) async {
    // Update the announcement's visibility status
    await _firestore
        .collection('announcements')
        .doc(schedule.contentId)
        .update({
          'isPublished': true,
          'publishedAt': FieldValue.serverTimestamp(),
        });
  }
  
  /// Send notifications for published content
  Future<void> _sendPublicationNotifications(ScheduledContentModel schedule) async {
    // Implementation will depend on your notification system
    // This is a placeholder
    debugPrint('🔔 Sending notifications for ${schedule.contentType} (${schedule.contentId})');
    
    // Example implementation:
    // 1. Determine notification target audience (based on targeting options)
    // 2. Create notification payload
    // 3. Send FCM notifications or in-app notifications
    
    // TODO: Implement notification logic
  }
  
  /// Create the next occurrence for a recurring schedule
  Future<void> _createNextRecurrence(ScheduledContentModel currentSchedule) async {
    final nextOccurrence = currentSchedule.calculateNextOccurrence();
    
    if (nextOccurrence == null) return;
    
    // Create a new scheduled content for the next occurrence
    final nextScheduleId = '${currentSchedule.contentId}_${nextOccurrence.millisecondsSinceEpoch}';
    
    final newSchedule = ScheduledContentModel(
      id: nextScheduleId,
      contentId: currentSchedule.contentId,
      contentType: currentSchedule.contentType,
      creatorId: currentSchedule.creatorId,
      spaceId: currentSchedule.spaceId,
      status: SchedulingStatus.scheduled,
      scheduledTime: nextOccurrence,
      sendNotification: currentSchedule.sendNotification,
      notificationText: currentSchedule.notificationText,
      targetingOptions: currentSchedule.targetingOptions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recurrencePattern: currentSchedule.recurrencePattern,
      recurrenceEndDate: currentSchedule.recurrenceEndDate,
      recurrenceCount: currentSchedule.recurrenceCount,
      parentScheduleId: currentSchedule.id,
    );
    
    // Save the new schedule
    await _firestore
        .collection(scheduledContentCollection)
        .doc(nextScheduleId)
        .set(newSchedule.toFirestore());
    
    debugPrint('🔄 Created next recurrence for ${currentSchedule.contentType} at ${nextOccurrence.toIso8601String()}');
  }
  
  /// Schedule content for future publication
  Future<String> scheduleContent({
    required String contentId,
    required String contentType,
    required String creatorId,
    String? spaceId,
    required DateTime scheduledTime,
    bool sendNotification = true,
    String? notificationText,
    Map<String, dynamic> targetingOptions = const {},
    RecurrencePattern? recurrencePattern,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
  }) async {
    final now = DateTime.now();
    
    // Validate scheduled time is in the future
    if (scheduledTime.isBefore(now)) {
      throw Exception('Scheduled time must be in the future');
    }
    
    // Generate a unique ID for the schedule
    final scheduleId = '${contentId}_${now.millisecondsSinceEpoch}';
    
    // Create schedule model
    final schedule = ScheduledContentModel(
      id: scheduleId,
      contentId: contentId,
      contentType: contentType,
      creatorId: creatorId,
      spaceId: spaceId,
      status: SchedulingStatus.scheduled,
      scheduledTime: scheduledTime,
      sendNotification: sendNotification,
      notificationText: notificationText,
      targetingOptions: targetingOptions,
      createdAt: now,
      updatedAt: now,
      recurrencePattern: recurrencePattern,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceCount: recurrenceCount,
    );
    
    // Save to Firestore
    await _firestore
        .collection(scheduledContentCollection)
        .doc(scheduleId)
        .set(schedule.toFirestore());
    
    debugPrint('📅 Scheduled $contentType content for ${scheduledTime.toIso8601String()}');
    
    return scheduleId;
  }
  
  /// Cancel a scheduled content
  Future<void> cancelSchedule(String scheduleId) async {
    await _updateScheduleStatus(
      scheduleId,
      SchedulingStatus.cancelled,
    );
    
    debugPrint('❌ Cancelled schedule $scheduleId');
  }
  
  /// Get scheduled content for a specific content
  Future<List<ScheduledContentModel>> getSchedulesForContent(String contentId) async {
    final snapshot = await _firestore
        .collection(scheduledContentCollection)
        .where('contentId', isEqualTo: contentId)
        .get();
    
    return snapshot.docs
        .map((doc) => ScheduledContentModel.fromFirestore(doc))
        .toList();
  }
  
  /// Get all scheduled content for a creator
  Future<List<ScheduledContentModel>> getSchedulesForCreator(String creatorId) async {
    final snapshot = await _firestore
        .collection(scheduledContentCollection)
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: SchedulingStatus.scheduled.toString().split('.').last)
        .get();
    
    return snapshot.docs
        .map((doc) => ScheduledContentModel.fromFirestore(doc))
        .toList();
  }
} 