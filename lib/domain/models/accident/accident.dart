import 'package:freezed_annotation/freezed_annotation.dart';

part 'accident.freezed.dart';
part 'accident.g.dart';

@freezed
abstract class Accident with _$Accident {
  factory Accident({
    required String accidentId,
    required DateTime detectedTime,
    required String location,
    required String contactNum,
    required DateTime contactTime,
  }) = _Accident;

  factory Accident.fromJson(Map<String, dynamic> json) =>
      _$AccidentFromJson(json);
}
