import 'package:freezed_annotation/freezed_annotation.dart';
import 'card_lifecycle_state.dart';
import 'card_lifecycle_transition.dart';

part 'card_lifecycle_history.freezed.dart';
part 'card_lifecycle_history.g.dart';

/// Represents the complete lifecycle history of a card
@freezed
abstract class CardLifecycleHistory with _$CardLifecycleHistory {
  const factory CardLifecycleHistory({
    /// The card ID this history belongs to
    required String cardId,

    /// The current state of the card
    required CardLifecycleState currentState,

    /// List of all transitions in chronological order
    required List<CardLifecycleTransition> transitions,

    /// Last updated timestamp
    required DateTime lastUpdated,
  }) = _CardLifecycleHistory;

  factory CardLifecycleHistory.fromJson(Map<String, dynamic> json) =>
      _$CardLifecycleHistoryFromJson(json);
} 