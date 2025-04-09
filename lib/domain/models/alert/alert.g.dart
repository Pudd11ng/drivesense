// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Alert _$AlertFromJson(Map<String, dynamic> json) => _Alert(
  alertId: json['alertId'] as String,
  alertTypeName: json['alertTypeName'] as String,
  musicPlayList: json['musicPlayList'] as Map<String, dynamic>,
  audioFilePath: json['audioFilePath'] as Map<String, dynamic>,
);

Map<String, dynamic> _$AlertToJson(_Alert instance) => <String, dynamic>{
  'alertId': instance.alertId,
  'alertTypeName': instance.alertTypeName,
  'musicPlayList': instance.musicPlayList,
  'audioFilePath': instance.audioFilePath,
};
