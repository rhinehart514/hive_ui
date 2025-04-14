// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_lifecycle_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardLifecycleHistory _$CardLifecycleHistoryFromJson(
        Map<String, dynamic> json) =>
    _CardLifecycleHistory(
      cardId: json['cardId'] as String,
      currentState:
          $enumDecode(_$CardLifecycleStateEnumMap, json['currentState']),
      transitions: (json['transitions'] as List<dynamic>)
          .map((e) =>
              CardLifecycleTransition.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$CardLifecycleHistoryToJson(
        _CardLifecycleHistory instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'currentState': _$CardLifecycleStateEnumMap[instance.currentState]!,
      'transitions': instance.transitions,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
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
