// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accident.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Accident {

 String get accidentId; DateTime get detectedTime; String get location; String get contactNum; DateTime get contactTime;
/// Create a copy of Accident
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccidentCopyWith<Accident> get copyWith => _$AccidentCopyWithImpl<Accident>(this as Accident, _$identity);

  /// Serializes this Accident to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Accident&&(identical(other.accidentId, accidentId) || other.accidentId == accidentId)&&(identical(other.detectedTime, detectedTime) || other.detectedTime == detectedTime)&&(identical(other.location, location) || other.location == location)&&(identical(other.contactNum, contactNum) || other.contactNum == contactNum)&&(identical(other.contactTime, contactTime) || other.contactTime == contactTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accidentId,detectedTime,location,contactNum,contactTime);

@override
String toString() {
  return 'Accident(accidentId: $accidentId, detectedTime: $detectedTime, location: $location, contactNum: $contactNum, contactTime: $contactTime)';
}


}

/// @nodoc
abstract mixin class $AccidentCopyWith<$Res>  {
  factory $AccidentCopyWith(Accident value, $Res Function(Accident) _then) = _$AccidentCopyWithImpl;
@useResult
$Res call({
 String accidentId, DateTime detectedTime, String location, String contactNum, DateTime contactTime
});




}
/// @nodoc
class _$AccidentCopyWithImpl<$Res>
    implements $AccidentCopyWith<$Res> {
  _$AccidentCopyWithImpl(this._self, this._then);

  final Accident _self;
  final $Res Function(Accident) _then;

/// Create a copy of Accident
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accidentId = null,Object? detectedTime = null,Object? location = null,Object? contactNum = null,Object? contactTime = null,}) {
  return _then(_self.copyWith(
accidentId: null == accidentId ? _self.accidentId : accidentId // ignore: cast_nullable_to_non_nullable
as String,detectedTime: null == detectedTime ? _self.detectedTime : detectedTime // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,contactNum: null == contactNum ? _self.contactNum : contactNum // ignore: cast_nullable_to_non_nullable
as String,contactTime: null == contactTime ? _self.contactTime : contactTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Accident implements Accident {
   _Accident({required this.accidentId, required this.detectedTime, required this.location, required this.contactNum, required this.contactTime});
  factory _Accident.fromJson(Map<String, dynamic> json) => _$AccidentFromJson(json);

@override final  String accidentId;
@override final  DateTime detectedTime;
@override final  String location;
@override final  String contactNum;
@override final  DateTime contactTime;

/// Create a copy of Accident
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccidentCopyWith<_Accident> get copyWith => __$AccidentCopyWithImpl<_Accident>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccidentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Accident&&(identical(other.accidentId, accidentId) || other.accidentId == accidentId)&&(identical(other.detectedTime, detectedTime) || other.detectedTime == detectedTime)&&(identical(other.location, location) || other.location == location)&&(identical(other.contactNum, contactNum) || other.contactNum == contactNum)&&(identical(other.contactTime, contactTime) || other.contactTime == contactTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accidentId,detectedTime,location,contactNum,contactTime);

@override
String toString() {
  return 'Accident(accidentId: $accidentId, detectedTime: $detectedTime, location: $location, contactNum: $contactNum, contactTime: $contactTime)';
}


}

/// @nodoc
abstract mixin class _$AccidentCopyWith<$Res> implements $AccidentCopyWith<$Res> {
  factory _$AccidentCopyWith(_Accident value, $Res Function(_Accident) _then) = __$AccidentCopyWithImpl;
@override @useResult
$Res call({
 String accidentId, DateTime detectedTime, String location, String contactNum, DateTime contactTime
});




}
/// @nodoc
class __$AccidentCopyWithImpl<$Res>
    implements _$AccidentCopyWith<$Res> {
  __$AccidentCopyWithImpl(this._self, this._then);

  final _Accident _self;
  final $Res Function(_Accident) _then;

/// Create a copy of Accident
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accidentId = null,Object? detectedTime = null,Object? location = null,Object? contactNum = null,Object? contactTime = null,}) {
  return _then(_Accident(
accidentId: null == accidentId ? _self.accidentId : accidentId // ignore: cast_nullable_to_non_nullable
as String,detectedTime: null == detectedTime ? _self.detectedTime : detectedTime // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,contactNum: null == contactNum ? _self.contactNum : contactNum // ignore: cast_nullable_to_non_nullable
as String,contactTime: null == contactTime ? _self.contactTime : contactTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
