// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accident.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Accident _$AccidentFromJson(Map<String, dynamic> json) => _Accident(
  accidentId: json['accidentId'] as String,
  delectedTime: DateTime.parse(json['delectedTime'] as String),
  location: json['location'] as String,
  contactNum: json['contactNum'] as String,
  contactTime: json['contactTime'] as String,
);

Map<String, dynamic> _$AccidentToJson(_Accident instance) => <String, dynamic>{
  'accidentId': instance.accidentId,
  'delectedTime': instance.delectedTime.toIso8601String(),
  'location': instance.location,
  'contactNum': instance.contactNum,
  'contactTime': instance.contactTime,
};
