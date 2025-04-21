enum SpaceMembershipStatus {
  initial,
  loading,
  joined,
  notJoined,
  error
}

class SpaceMembershipState {
  final SpaceMembershipStatus status;
  final String? errorMessage;
  final bool canCreateEvents; // Store creation permission here

  const SpaceMembershipState({
    this.status = SpaceMembershipStatus.initial,
    this.errorMessage,
    this.canCreateEvents = false,
  });

  SpaceMembershipState copyWith({
    SpaceMembershipStatus? status,
    String? errorMessage,
    bool? canCreateEvents,
  }) {
    return SpaceMembershipState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      canCreateEvents: canCreateEvents ?? this.canCreateEvents,
    );
  }
} 