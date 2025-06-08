import 'package:equatable/equatable.dart';

/// Base class for all feed-related failures
abstract class FeedFailure extends Equatable {
  /// Error message
  final String message;
  
  /// Original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  const FeedFailure({
    required this.message,
    this.originalException,
  });
  
  @override
  List<Object?> get props => [message, originalException];
  
  @override
  bool? get stringify => true;
}

/// Failure when loading events
class EventsLoadFailure extends FeedFailure {
  /// Optional additional context about the failure
  final String? context;
  
  /// Constructor
  const EventsLoadFailure({
    Object? originalException,
    this.context,
  }) : super(
    message: 'Could not load events. Please try again later.',
    originalException: originalException,
  );
  
  @override
  List<Object?> get props => [...super.props, context];
}

/// Failure related to RSVP operations
class RsvpFailure extends FeedFailure {
  /// The ID of the event for which the RSVP operation failed
  final String eventId;
  
  /// The intended RSVP status
  final bool wasAttending;
  
  /// Constructor
  const RsvpFailure({
    required this.eventId,
    required this.wasAttending,
    Object? originalException,
  }) : super(
    message: wasAttending 
      ? 'Failed to RSVP to event'
      : 'Failed to cancel RSVP to event',
    originalException: originalException,
  );
  
  @override
  List<Object?> get props => [...super.props, eventId, wasAttending];
}

/// Failure related to reposting content
class RepostFailure extends FeedFailure {
  /// The ID of the content being reposted
  final String contentId;
  
  /// The type of content being reposted
  final String contentType;
  
  /// Constructor
  const RepostFailure({
    required this.contentId,
    required this.contentType,
    Object? originalException,
  }) : super(
    message: 'Could not repost this $contentType. Please try again.',
    originalException: originalException,
  );
  
  @override
  List<Object?> get props => [...super.props, contentId, contentType];
}

/// Failure related to feed personalization
class PersonalizationFailure extends FeedFailure {
  /// Constructor
  const PersonalizationFailure({
    Object? originalException,
  }) : super(
    message: 'Could not personalize your feed. Showing default content instead.',
    originalException: originalException,
  );
}

/// Failure related to authentication
class AuthFailure extends FeedFailure {
  /// Constructor
  const AuthFailure({
    required String message,
    Object? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );
}

/// Failure related to network issues
class NetworkFailure extends FeedFailure {
  /// Constructor
  const NetworkFailure({
    Object? originalException,
  }) : super(
    message: 'Network connection issue. Please check your connection and try again.',
    originalException: originalException,
  );
}

/// Failure related to authentication issues
class AuthenticationFailure extends FeedFailure {
  /// Constructor
  const AuthenticationFailure({
    String? message,
    Object? originalException,
  }) : super(
    message: message ?? 'Please sign in to perform this action.',
    originalException: originalException,
  );
}

/// Failure related to offline operations
class OfflineAccessFailure extends FeedFailure {
  /// The operation that was attempted while offline
  final String operation;
  
  /// Constructor
  const OfflineAccessFailure({
    required this.operation,
    Object? originalException,
  }) : super(
    message: 'This feature is not available offline. Please connect to the internet and try again.',
    originalException: originalException,
  );
  
  @override
  List<Object?> get props => [...super.props, operation];
}

/// Failure when an event is not found
class EventNotFoundFailure extends FeedFailure {
  /// The event ID that wasn't found
  final String eventId;
  
  /// Constructor
  const EventNotFoundFailure({
    required this.eventId,
    Object? originalException,
  }) : super(
    message: 'Event not found. It may have been deleted.',
    originalException: originalException,
  );
  
  @override
  List<Object?> get props => [...super.props, eventId];
}

/// Failure when a reposter profile cannot be loaded
class ReposterProfileFailure extends FeedFailure {
  /// Constructor
  const ReposterProfileFailure({
    Object? originalException,
  }) : super(
    message: 'Could not complete this repost. Please try again.',
    originalException: originalException,
  );
} 