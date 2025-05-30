// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accident.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Accident _$AccidentFromJson(Map<String, dynamic> json) => _Accident(
  accidentId: json['accidentId'] as String,
  detectedTime: DateTime.parse(json['detectedTime'] as String),
  location: json['location'] as String,
  contactNum: json['contactNum'] as String,
  contactTime: DateTime.parse(json['contactTime'] as String),
);

Map<String, dynamic> _$AccidentToJson(_Accident instance) => <String, dynamic>{
  'accidentId': instance.accidentId,
  'detectedTime': instance.detectedTime.toIso8601String(),
  'location': instance.location,
  'contactNum': instance.contactNum,
  'contactTime': instance.contactTime.toIso8601String(),
};
