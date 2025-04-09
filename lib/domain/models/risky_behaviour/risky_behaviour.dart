import 'package:freezed_annotation/freezed_annotation.dart';

part 'risky_behaviour.freezed.dart';
part 'risky_behaviour.g.dart';

@freezed
abstract class RiskyBehaviour with _$RiskyBehaviour {
  factory RiskyBehaviour({
    required String behaviourId,
    required DateTime delectedTime,
    required String behaviourType,
    required String alertTypeName,
  }) = _RiskyBehaviour;

  factory RiskyBehaviour.fromJson(Map<String, dynamic> json) =>
      _$RiskyBehaviourFromJson(json);
}
