import 'package:hive_ui/features/shared/domain/failures/failure.dart';

/// Abstract base class for all feed-related failures
abstract class FeedFailure extends Failure {
  @override
  String get message;
  
  @override
  String get reason;
}

/// Failure that occurs when events cannot be loaded
class EventsLoadFailure implements FeedFailure {
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Optional additional context about the failure
  final String? context;
  
  /// Constructor
  EventsLoadFailure({
    this.originalException,
    this.context,
  });
  
  @override
  String get message => 'Could not load events. Please try again later.';
  
  @override
  String get reason => 'Failed to load events: ${originalException?.toString() ?? "Unknown error"} ${context != null ? '($context)' : ''}';
  
  @override
  String toString() => reason;
}

/// Failure that occurs when RSVP operations fail
class RsvpFailure implements FeedFailure {
  /// The event ID for which the RSVP failed
  final String eventId;
  
  /// Whether the user was attempting to RSVP or cancel RSVP
  final bool wasAttending;
  
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  RsvpFailure({
    required this.eventId,
    required this.wasAttending,
    this.originalException,
  });
  
  @override
  String get message => wasAttending 
      ? 'Could not RSVP to this event. Please try again.'
      : 'Could not cancel your RSVP. Please try again.';
  
  @override
  String get reason => 'RSVP operation failed for event $eventId (attending: $wasAttending): ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  String toString() => reason;
}

/// Failure that occurs when repost operations fail
class RepostFailure implements FeedFailure {
  /// The content ID that failed to repost
  final String contentId;
  
  /// Type of content (e.g., "event", "post")
  final String contentType;
  
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  RepostFailure({
    required this.contentId,
    required this.contentType,
    this.originalException,
  });
  
  @override
  String get message => 'Could not repost this $contentType. Please try again.';
  
  @override
  String get reason => 'Repost operation failed for $contentType $contentId: ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  String toString() => reason;
}

/// Failure that occurs when feed personalization fails
class PersonalizationFailure implements FeedFailure {
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  PersonalizationFailure({
    this.originalException,
  });
  
  @override
  String get message => 'Could not personalize your feed. Showing default content instead.';
  
  @override
  String get reason => 'Feed personalization failed: ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  String toString() => reason;
}

/// Failure that occurs due to network issues
class NetworkFailure implements FeedFailure {
  /// Constructor
  NetworkFailure();
  
  @override
  String get message => 'Network connection issue. Please check your connection and try again.';
  
  @override
  String get reason => 'Network connection failure detected while accessing feed data';
  
  @override
  String toString() => reason;
}

/// Failure that occurs when an operation fails due to authentication issues
class AuthenticationFailure implements FeedFailure {
  /// Constructor
  AuthenticationFailure();
  
  @override
  String get message => 'Please sign in to perform this action.';
  
  @override
  String get reason => 'Authentication required for this feed operation';
  
  @override
  String toString() => reason;
}

/// Failure that occurs when offline access fails
class OfflineAccessFailure implements FeedFailure {
  /// The operation that was attempted while offline
  final String operation;
  
  /// Constructor
  OfflineAccessFailure({
    required this.operation,
  });
  
  @override
  String get message => 'This feature is not available offline. Please connect to the internet and try again.';
  
  @override
  String get reason => 'Offline access failed for operation: $operation';
  
  @override
  String toString() => reason;
}

/// Failure that occurs when an event is not found
class EventNotFoundFailure implements FeedFailure {
  /// The event ID that wasn't found
  final String eventId;
  
  /// Constructor
  EventNotFoundFailure({
    required this.eventId,
  });
  
  @override
  String get message => 'Event not found. It may have been deleted.';
  
  @override
  String get reason => 'Event with ID $eventId not found';
  
  @override
  String toString() => reason;
}

/// Failure that occurs when a reposter profile cannot be loaded
class ReposterProfileFailure implements FeedFailure {
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  ReposterProfileFailure({
    this.originalException,
  });
  
  @override
  String get message => 'Could not complete this repost. Please try again.';
  
  @override
  String get reason => 'Reposter profile failure: ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  String toString() => reason;
} 