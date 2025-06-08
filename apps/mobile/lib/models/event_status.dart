/// Status of an event
enum EventStatus {
  /// Event is confirmed/active
  confirmed,
  
  /// Event is cancelled
  cancelled,
  
  /// Event is draft/pending
  draft,
  
  /// Event is rescheduled
  rescheduled;
  
  /// Get string representation of the status
  String get value {
    switch (this) {
      case EventStatus.confirmed:
        return 'confirmed';
      case EventStatus.cancelled:
        return 'cancelled';
      case EventStatus.draft:
        return 'draft';
      case EventStatus.rescheduled:
        return 'rescheduled';
    }
  }
  
  /// Create an EventStatus from a string
  static EventStatus fromString(String? status) {
    if (status == null) return EventStatus.confirmed;
    
    switch (status.toLowerCase()) {
      case 'cancelled':
        return EventStatus.cancelled;
      case 'draft':
        return EventStatus.draft;
      case 'rescheduled':
        return EventStatus.rescheduled;
      case 'confirmed':
      default:
        return EventStatus.confirmed;
    }
  }
} 