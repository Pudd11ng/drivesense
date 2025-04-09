import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert.freezed.dart';
part 'alert.g.dart';

@freezed
abstract class Alert with _$Alert {
  factory Alert({
    required String alertId,
    required String alertTypeName,
    required Map<String, dynamic> musicPlayList,
    required Map<String, dynamic> audioFilePath,
  }) = _Alert;

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
}
