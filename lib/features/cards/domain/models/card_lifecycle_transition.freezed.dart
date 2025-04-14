// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_lifecycle_transition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardLifecycleTransition {
  /// The state before the transition
  CardLifecycleState get fromState;

  /// The state after the transition
  CardLifecycleState get toState;

  /// Timestamp when the transition occurred
  DateTime get timestamp;

  /// Optional reason for the transition
  String? get reason;

  /// Optional user ID who initiated the transition
  String? get initiatedBy;

  /// Create a copy of CardLifecycleTransition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CardLifecycleTransitionCopyWith<CardLifecycleTransition> get copyWith =>
      _$CardLifecycleTransitionCopyWithImpl<CardLifecycleTransition>(
          this as CardLifecycleTransition, _$identity);

  /// Serializes this CardLifecycleTransition to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CardLifecycleTransition &&
            (identical(other.fromState, fromState) ||
                other.fromState == fromState) &&
            (identical(other.toState, toState) || other.toState == toState) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.initiatedBy, initiatedBy) ||
                other.initiatedBy == initiatedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, fromState, toState, timestamp, reason, initiatedBy);

  @override
  String toString() {
    return 'CardLifecycleTransition(fromState: $fromState, toState: $toState, timestamp: $timestamp, reason: $reason, initiatedBy: $initiatedBy)';
  }
}

/// @nodoc
abstract mixin class $CardLifecycleTransitionCopyWith<$Res> {
  factory $CardLifecycleTransitionCopyWith(CardLifecycleTransition value,
          $Res Function(CardLifecycleTransition) _then) =
      _$CardLifecycleTransitionCopyWithImpl;
  @useResult
  $Res call(
      {CardLifecycleState fromState,
      CardLifecycleState toState,
      DateTime timestamp,
      String? reason,
      String? initiatedBy});
}

/// @nodoc
class _$CardLifecycleTransitionCopyWithImpl<$Res>
    implements $CardLifecycleTransitionCopyWith<$Res> {
  _$CardLifecycleTransitionCopyWithImpl(this._self, this._then);

  final CardLifecycleTransition _self;
  final $Res Function(CardLifecycleTransition) _then;

  /// Create a copy of CardLifecycleTransition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromState = null,
    Object? toState = null,
    Object? timestamp = null,
    Object? reason = freezed,
    Object? initiatedBy = freezed,
  }) {
    return _then(_self.copyWith(
      fromState: null == fromState
          ? _self.fromState
          : fromState // ignore: cast_nullable_to_non_nullable
              as CardLifecycleState,
      toState: null == toState
          ? _self.toState
          : toState // ignore: cast_nullable_to_non_nullable
              as CardLifecycleState,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      initiatedBy: freezed == initiatedBy
          ? _self.initiatedBy
          : initiatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CardLifecycleTransition implements CardLifecycleTransition {
  const _CardLifecycleTransition(
      {required this.fromState,
      required this.toState,
      required this.timestamp,
      this.reason,
      this.initiatedBy});
  factory _CardLifecycleTransition.fromJson(Map<String, dynamic> json) =>
      _$CardLifecycleTransitionFromJson(json);

  /// The state before the transition
  @override
  final CardLifecycleState fromState;

  /// The state after the transition
  @override
  final CardLifecycleState toState;

  /// Timestamp when the transition occurred
  @override
  final DateTime timestamp;

  /// Optional reason for the transition
  @override
  final String? reason;

  /// Optional user ID who initiated the transition
  @override
  final String? initiatedBy;

  /// Create a copy of CardLifecycleTransition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CardLifecycleTransitionCopyWith<_CardLifecycleTransition> get copyWith =>
      __$CardLifecycleTransitionCopyWithImpl<_CardLifecycleTransition>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CardLifecycleTransitionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CardLifecycleTransition &&
            (identical(other.fromState, fromState) ||
                other.fromState == fromState) &&
            (identical(other.toState, toState) || other.toState == toState) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.initiatedBy, initiatedBy) ||
                other.initiatedBy == initiatedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, fromState, toState, timestamp, reason, initiatedBy);

  @override
  String toString() {
    return 'CardLifecycleTransition(fromState: $fromState, toState: $toState, timestamp: $timestamp, reason: $reason, initiatedBy: $initiatedBy)';
  }
}

/// @nodoc
abstract mixin class _$CardLifecycleTransitionCopyWith<$Res>
    implements $CardLifecycleTransitionCopyWith<$Res> {
  factory _$CardLifecycleTransitionCopyWith(_CardLifecycleTransition value,
          $Res Function(_CardLifecycleTransition) _then) =
      __$CardLifecycleTransitionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {CardLifecycleState fromState,
      CardLifecycleState toState,
      DateTime timestamp,
      String? reason,
      String? initiatedBy});
}

/// @nodoc
class __$CardLifecycleTransitionCopyWithImpl<$Res>
    implements _$CardLifecycleTransitionCopyWith<$Res> {
  __$CardLifecycleTransitionCopyWithImpl(this._self, this._then);

  final _CardLifecycleTransition _self;
  final $Res Function(_CardLifecycleTransition) _then;

  /// Create a copy of CardLifecycleTransition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fromState = null,
    Object? toState = null,
    Object? timestamp = null,
    Object? reason = freezed,
    Object? initiatedBy = freezed,
  }) {
    return _then(_CardLifecycleTransition(
      fromState: null == fromState
          ? _self.fromState
          : fromState // ignore: cast_nullable_to_non_nullable
              as CardLifecycleState,
      toState: null == toState
          ? _self.toState
          : toState // ignore: cast_nullable_to_non_nullable
              as CardLifecycleState,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      initiatedBy: freezed == initiatedBy
          ? _self.initiatedBy
          : initiatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
