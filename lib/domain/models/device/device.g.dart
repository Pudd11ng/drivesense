// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Device _$DeviceFromJson(Map<String, dynamic> json) => _Device(
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  deviceSSID: json['deviceSSID'] as String,
);

Map<String, dynamic> _$DeviceToJson(_Device instance) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'deviceName': instance.deviceName,
  'deviceSSID': instance.deviceSSID,
};
