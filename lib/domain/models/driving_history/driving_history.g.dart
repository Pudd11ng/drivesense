// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driving_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrivingHistory _$DrivingHistoryFromJson(Map<String, dynamic> json) =>
    _DrivingHistory(
      drivingHistoryId: json['drivingHistoryId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      accident:
          (json['accident'] as List<dynamic>)
              .map((e) => Accident.fromJson(e as Map<String, dynamic>))
              .toList(),
      riskyBehaviour:
          (json['riskyBehaviour'] as List<dynamic>)
              .map((e) => RiskyBehaviour.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$DrivingHistoryToJson(_DrivingHistory instance) =>
    <String, dynamic>{
      'drivingHistoryId': instance.drivingHistoryId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'accident': instance.accident,
      'riskyBehaviour': instance.riskyBehaviour,
    };
