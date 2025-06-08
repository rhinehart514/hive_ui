/// Event fired when a user's RSVP status for an event changes
class RsvpStatusChangedEvent {
  /// ID of the event
  final String eventId;
  
  /// ID of the user who changed their RSVP status
  final String userId;
  
  /// Whether the user is now attending the event
  final bool isAttending;
  
  /// Whether the user is on the waitlist
  final bool isWaitlisted;
  
  /// Create a new RSVP status changed event
  RsvpStatusChangedEvent({
    required this.eventId,
    required this.userId,
    required this.isAttending,
    required this.isWaitlisted,
  });
} 