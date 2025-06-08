// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_lifecycle_transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardLifecycleTransition _$CardLifecycleTransitionFromJson(
        Map<String, dynamic> json) =>
    _CardLifecycleTransition(
      fromState: $enumDecode(_$CardLifecycleStateEnumMap, json['fromState']),
      toState: $enumDecode(_$CardLifecycleStateEnumMap, json['toState']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      reason: json['reason'] as String?,
      initiatedBy: json['initiatedBy'] as String?,
    );

Map<String, dynamic> _$CardLifecycleTransitionToJson(
        _CardLifecycleTransition instance) =>
    <String, dynamic>{
      'fromState': _$CardLifecycleStateEnumMap[instance.fromState]!,
      'toState': _$CardLifecycleStateEnumMap[instance.toState]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'reason': instance.reason,
      'initiatedBy': instance.initiatedBy,
    };

const _$CardLifecycleStateEnumMap = {
  CardLifecycleState.created: 'created',
  CardLifecycleState.processing: 'processing',
  CardLifecycleState.active: 'active',
  CardLifecycleState.suspended: 'suspended',
  CardLifecycleState.deactivated: 'deactivated',
  CardLifecycleState.expired: 'expired',
  CardLifecycleState.error: 'error',
};
