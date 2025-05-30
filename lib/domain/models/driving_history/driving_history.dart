import 'package:drivesense/domain/models/accident/accident.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'driving_history.freezed.dart';
part 'driving_history.g.dart';

@freezed
abstract class DrivingHistory with _$DrivingHistory {
  factory DrivingHistory({
    String? drivingHistoryId,
    required DateTime startTime,
    required DateTime endTime,
    required List<Accident> accident,
    required List<RiskyBehaviour> riskyBehaviour,
  }) = _DrivingHistory;

  factory DrivingHistory.fromJson(Map<String, dynamic> json) =>
      _$DrivingHistoryFromJson(json);
}
