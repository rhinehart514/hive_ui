import 'package:freezed_annotation/freezed_annotation.dart';
import 'card_lifecycle_state.dart';

part 'card_lifecycle_transition.freezed.dart';
part 'card_lifecycle_transition.g.dart';

/// Represents a transition between two card lifecycle states
@freezed
abstract class CardLifecycleTransition with _$CardLifecycleTransition {
  const factory CardLifecycleTransition({
    /// The state before the transition
    required CardLifecycleState fromState,

    /// The state after the transition
    required CardLifecycleState toState,

    /// Timestamp when the transition occurred
    required DateTime timestamp,

    /// Optional reason for the transition
    String? reason,

    /// Optional user ID who initiated the transition
    String? initiatedBy,
  }) = _CardLifecycleTransition;

  factory CardLifecycleTransition.fromJson(Map<String, dynamic> json) =>
      _$CardLifecycleTransitionFromJson(json);
} 