// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_lifecycle_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardLifecycleHistory {
  /// The card ID this history belongs to
  String get cardId;

  /// The current state of the card
  CardLifecycleState get currentState;

  /// List of all transitions in chronological order
  List<CardLifecycleTransition> get transitions;

  /// Last updated timestamp
  DateTime get lastUpdated;

  /// Create a copy of CardLifecycleHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CardLifecycleHistoryCopyWith<CardLifecycleHistory> get copyWith =>
      _$CardLifecycleHistoryCopyWithImpl<CardLifecycleHistory>(
          this as CardLifecycleHistory, _$identity);

  /// Serializes this CardLifecycleHistory to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CardLifecycleHistory &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.currentState, currentState) ||
                other.currentState == currentState) &&
            const DeepCollectionEquality()
                .equals(other.transitions, transitions) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cardId, currentState,
      const DeepCollectionEquality().hash(transitions), lastUpdated);

  @override
  String toString() {
    return 'CardLifecycleHistory(cardId: $cardId, currentState: $currentState, transitions: $transitions, lastUpdated: $lastUpdated)';
  }
}

/// @nodoc
abstract mixin class $CardLifecycleHistoryCopyWith<$Res> {
  factory $CardLifecycleHistoryCopyWith(CardLifecycleHistory value,
          $Res Function(CardLifecycleHistory) _then) =
      _$CardLifecycleHistoryCopyWithImpl;
  @useResult
  $Res call(
      {String cardId,
      CardLifecycleState currentState,
      List<CardLifecycleTransition> transitions,
      DateTime lastUpdated});
}

/// @nodoc
class _$CardLifecycleHistoryCopyWithImpl<$Res>
    implements $CardLifecycleHistoryCopyWith<$Res> {
  _$CardLifecycleHistoryCopyWithImpl(this._self, this._then);

  final CardLifecycleHistory _self;
  final $Res Function(CardLifecycleHistory) _then;

  /// Create a copy of CardLifecycleHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? currentState = null,
    Object? transitions = null,
    Object? lastUpdated = null,
  }) {
    return _then(_self.copyWith(
      cardId: null == cardId
          ? _self.cardId
          : cardId // ignore: cast_nullable_to_non_nullable
              as String,
      currentState: null == currentState
          ? _self.currentState
          : currentState // ignore: cast_nullable_to_non_nullable
              as CardLifecycleState,
      transitions: null == transitions
          ? _self.transitions
          : transitions // ignore: cast_nullable_to_non_nullable
              as List<CardLifecycleTransition>,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CardLifecycleHistory implements CardLifecycleHistory {
  const _CardLifecycleHistory(
      {required this.cardId,
      required this.currentState,
      required final List<CardLifecycleTransition> transitions,
      required this.lastUpdated})
      : _transitions = transitions;
  factory _CardLifecycleHistory.fromJson(Map<String, dynamic> json) =>
      _$CardLifecycleHistoryFromJson(json);

  /// The card ID this history belongs to
  @override
  final String cardId;

  /// The current state of the card
  @override
  final CardLifecycleState currentState;

  /// List of all transitions in chronological order
  final List<CardLifecycleTransition> _transitions;

  /// List of all transitions in chronological order
  @override
  List<CardLifecycleTransition> get transitions {
    if (_transitions is EqualUnmodifiableListView) return _transitions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transitions);
  }

  /// Last updated timestamp
  @override
  final DateTime lastUpdated;

  /// Create a copy of CardLifecycleHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CardLifecycleHistoryCopyWith<_CardLifecycleHistory> get copyWith =>
      __$CardLifecycleHistoryCopyWithImpl<_CardLifecycleHistory>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CardLifecycleHistoryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CardLifecycleHistory &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.currentState, currentState) ||
                other.currentState == currentState) &&
            const DeepCollectionEquality()
                .equals(other._transitions, _transitions) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cardId, currentState,
      const DeepCollectionEquality().hash(_transitions), lastUpdated);

  @override
  String toString() {
    return 'CardLifecycleHistory(cardId: $cardId, currentState: $currentState, transitions: $transitions, lastUpdated: $lastUpdated)';
  }
}

/// @nodoc
abstract mixin class _$CardLifecycleHistoryCopyWith<$Res>
    implements $CardLifecycleHistoryCopyWith<$Res> {
  factory _$CardLifecycleHistoryCopyWith(_CardLifecycleHistory value,
          $Res Function(_CardLifecycleHistory) _then) =
      __$CardLifecycleHistoryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String cardId,
      CardLifecycleState currentState,
      List<CardLifecycleTransition> transitions,
      DateTime lastUpdated});
}

/// @nodoc
class __$CardLifecycleHistoryCopyWithImpl<$Res>
    implements _$CardLifecycleHistoryCopyWith<$Res> {
  __$CardLifecycleHistoryCopyWithImpl(this._self, this._then);

  final _CardLifecycleHistory _self;
  final $Res Function(_CardLifecycleHistory) _then;

  /// Create a copy of CardLifecycleHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cardId = null,
    Object? currentState = null,
    Object? transitions = null,
    Object? lastUpdated = null,
  }) {
    return _then(_CardLifecycleHistory(
      cardId: null == cardId
          ? _self.cardId
          : cardId // ignore: cast_nullable_to_non_nullable
              as String,
      currentState: null == currentState
          ? _self.currentState
          : currentState // ignore: cast_nullable_to_non_nullable
              as CardLifecycleState,
      transitions: null == transitions
          ? _self._transitions
          : transitions // ignore: cast_nullable_to_non_nullable
              as List<CardLifecycleTransition>,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
