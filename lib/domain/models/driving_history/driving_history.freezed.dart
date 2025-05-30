// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driving_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrivingHistory {

 String? get drivingHistoryId; DateTime get startTime; DateTime get endTime; List<Accident> get accident; List<RiskyBehaviour> get riskyBehaviour;
/// Create a copy of DrivingHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrivingHistoryCopyWith<DrivingHistory> get copyWith => _$DrivingHistoryCopyWithImpl<DrivingHistory>(this as DrivingHistory, _$identity);

  /// Serializes this DrivingHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrivingHistory&&(identical(other.drivingHistoryId, drivingHistoryId) || other.drivingHistoryId == drivingHistoryId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&const DeepCollectionEquality().equals(other.accident, accident)&&const DeepCollectionEquality().equals(other.riskyBehaviour, riskyBehaviour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,drivingHistoryId,startTime,endTime,const DeepCollectionEquality().hash(accident),const DeepCollectionEquality().hash(riskyBehaviour));

@override
String toString() {
  return 'DrivingHistory(drivingHistoryId: $drivingHistoryId, startTime: $startTime, endTime: $endTime, accident: $accident, riskyBehaviour: $riskyBehaviour)';
}


}

/// @nodoc
abstract mixin class $DrivingHistoryCopyWith<$Res>  {
  factory $DrivingHistoryCopyWith(DrivingHistory value, $Res Function(DrivingHistory) _then) = _$DrivingHistoryCopyWithImpl;
@useResult
$Res call({
 String? drivingHistoryId, DateTime startTime, DateTime endTime, List<Accident> accident, List<RiskyBehaviour> riskyBehaviour
});




}
/// @nodoc
class _$DrivingHistoryCopyWithImpl<$Res>
    implements $DrivingHistoryCopyWith<$Res> {
  _$DrivingHistoryCopyWithImpl(this._self, this._then);

  final DrivingHistory _self;
  final $Res Function(DrivingHistory) _then;

/// Create a copy of DrivingHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? drivingHistoryId = freezed,Object? startTime = null,Object? endTime = null,Object? accident = null,Object? riskyBehaviour = null,}) {
  return _then(_self.copyWith(
drivingHistoryId: freezed == drivingHistoryId ? _self.drivingHistoryId : drivingHistoryId // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,accident: null == accident ? _self.accident : accident // ignore: cast_nullable_to_non_nullable
as List<Accident>,riskyBehaviour: null == riskyBehaviour ? _self.riskyBehaviour : riskyBehaviour // ignore: cast_nullable_to_non_nullable
as List<RiskyBehaviour>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _DrivingHistory implements DrivingHistory {
   _DrivingHistory({this.drivingHistoryId, required this.startTime, required this.endTime, required final  List<Accident> accident, required final  List<RiskyBehaviour> riskyBehaviour}): _accident = accident,_riskyBehaviour = riskyBehaviour;
  factory _DrivingHistory.fromJson(Map<String, dynamic> json) => _$DrivingHistoryFromJson(json);

@override final  String? drivingHistoryId;
@override final  DateTime startTime;
@override final  DateTime endTime;
 final  List<Accident> _accident;
@override List<Accident> get accident {
  if (_accident is EqualUnmodifiableListView) return _accident;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accident);
}

 final  List<RiskyBehaviour> _riskyBehaviour;
@override List<RiskyBehaviour> get riskyBehaviour {
  if (_riskyBehaviour is EqualUnmodifiableListView) return _riskyBehaviour;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_riskyBehaviour);
}


/// Create a copy of DrivingHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrivingHistoryCopyWith<_DrivingHistory> get copyWith => __$DrivingHistoryCopyWithImpl<_DrivingHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrivingHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrivingHistory&&(identical(other.drivingHistoryId, drivingHistoryId) || other.drivingHistoryId == drivingHistoryId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&const DeepCollectionEquality().equals(other._accident, _accident)&&const DeepCollectionEquality().equals(other._riskyBehaviour, _riskyBehaviour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,drivingHistoryId,startTime,endTime,const DeepCollectionEquality().hash(_accident),const DeepCollectionEquality().hash(_riskyBehaviour));

@override
String toString() {
  return 'DrivingHistory(drivingHistoryId: $drivingHistoryId, startTime: $startTime, endTime: $endTime, accident: $accident, riskyBehaviour: $riskyBehaviour)';
}


}

/// @nodoc
abstract mixin class _$DrivingHistoryCopyWith<$Res> implements $DrivingHistoryCopyWith<$Res> {
  factory _$DrivingHistoryCopyWith(_DrivingHistory value, $Res Function(_DrivingHistory) _then) = __$DrivingHistoryCopyWithImpl;
@override @useResult
$Res call({
 String? drivingHistoryId, DateTime startTime, DateTime endTime, List<Accident> accident, List<RiskyBehaviour> riskyBehaviour
});




}
/// @nodoc
class __$DrivingHistoryCopyWithImpl<$Res>
    implements _$DrivingHistoryCopyWith<$Res> {
  __$DrivingHistoryCopyWithImpl(this._self, this._then);

  final _DrivingHistory _self;
  final $Res Function(_DrivingHistory) _then;

/// Create a copy of DrivingHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drivingHistoryId = freezed,Object? startTime = null,Object? endTime = null,Object? accident = null,Object? riskyBehaviour = null,}) {
  return _then(_DrivingHistory(
drivingHistoryId: freezed == drivingHistoryId ? _self.drivingHistoryId : drivingHistoryId // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,accident: null == accident ? _self._accident : accident // ignore: cast_nullable_to_non_nullable
as List<Accident>,riskyBehaviour: null == riskyBehaviour ? _self._riskyBehaviour : riskyBehaviour // ignore: cast_nullable_to_non_nullable
as List<RiskyBehaviour>,
  ));
}


}

// dart format on
