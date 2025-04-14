import 'package:flutter/material.dart';
import 'package:hive_ui/components/card_lifecycle_wrapper.dart';
import 'package:hive_ui/components/cards.dart' hide HiveCard;
import 'package:hive_ui/components/hive_card.dart';

/// Extension methods to add lifecycle visualization to cards
extension HiveCardLifecycle on HiveCard {
  /// Wrap a HiveCard with lifecycle visualization
  Widget withLifecycle({
    required DateTime createdAt,
    CardLifecycleState state = CardLifecycleState.fresh,
    bool autoAge = true,
    bool showIndicator = false,
    Map<CardLifecycleState, Duration>? agingDurations,
  }) {
    return CardLifecycleWrapper(
      createdAt: createdAt,
      state: state,
      autoAge: autoAge,
      showIndicator: showIndicator,
      agingDurations: agingDurations ?? const {
        CardLifecycleState.fresh: Duration(hours: 24),
        CardLifecycleState.aging: Duration(days: 3),
        CardLifecycleState.old: Duration(days: 7),
      },
      child: this,
    );
  }
}

/// Extension methods to add lifecycle visualization to Card widgets
extension CardLifecycle on Card {
  /// Wrap a Card with lifecycle visualization
  Widget withLifecycle({
    required DateTime createdAt,
    CardLifecycleState state = CardLifecycleState.fresh,
    bool autoAge = true,
    bool showIndicator = false,
    Map<CardLifecycleState, Duration>? agingDurations,
  }) {
    return CardLifecycleWrapper(
      createdAt: createdAt,
      state: state,
      autoAge: autoAge,
      showIndicator: showIndicator,
      agingDurations: agingDurations ?? const {
        CardLifecycleState.fresh: Duration(hours: 24),
        CardLifecycleState.aging: Duration(days: 3),
        CardLifecycleState.old: Duration(days: 7),
      },
      child: this,
    );
  }
} 