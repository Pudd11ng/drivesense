// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risky_behaviour.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RiskyBehaviour _$RiskyBehaviourFromJson(Map<String, dynamic> json) =>
    _RiskyBehaviour(
      behaviourId: json['behaviourId'] as String,
      delectedTime: DateTime.parse(json['delectedTime'] as String),
      behaviourType: json['behaviourType'] as String,
      alertTypeName: json['alertTypeName'] as String,
    );

Map<String, dynamic> _$RiskyBehaviourToJson(_RiskyBehaviour instance) =>
    <String, dynamic>{
      'behaviourId': instance.behaviourId,
      'delectedTime': instance.delectedTime.toIso8601String(),
      'behaviourType': instance.behaviourType,
      'alertTypeName': instance.alertTypeName,
    };
