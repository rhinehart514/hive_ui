/// Represents the different states a card can be in during its lifecycle.
enum CardLifecycleState {
  /// Card is newly created and hasn't been processed yet
  created,

  /// Card is currently being processed by the system
  processing,

  /// Card has been successfully processed and is active
  active,

  /// Card has been temporarily suspended
  suspended,

  /// Card has been permanently deactivated
  deactivated,

  /// Card has expired
  expired,

  /// Card is in an error state
  error;

  /// Returns true if this is a terminal state
  bool get isTerminal => this == expired || this == deactivated;

  /// Returns true if the card is usable in this state
  bool get isUsable => this == active;

  /// Returns a user-friendly string representation of the state
  String get displayName {
    switch (this) {
      case CardLifecycleState.created:
        return 'Created';
      case CardLifecycleState.processing:
        return 'Processing';
      case CardLifecycleState.active:
        return 'Active';
      case CardLifecycleState.suspended:
        return 'Suspended';
      case CardLifecycleState.deactivated:
        return 'Deactivated';
      case CardLifecycleState.expired:
        return 'Expired';
      case CardLifecycleState.error:
        return 'Error';
    }
  }
} 