// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'risky_behaviour.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RiskyBehaviour {

 String get behaviourId; DateTime get delectedTime; String get behaviourType; String get alertTypeName;
/// Create a copy of RiskyBehaviour
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskyBehaviourCopyWith<RiskyBehaviour> get copyWith => _$RiskyBehaviourCopyWithImpl<RiskyBehaviour>(this as RiskyBehaviour, _$identity);

  /// Serializes this RiskyBehaviour to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskyBehaviour&&(identical(other.behaviourId, behaviourId) || other.behaviourId == behaviourId)&&(identical(other.delectedTime, delectedTime) || other.delectedTime == delectedTime)&&(identical(other.behaviourType, behaviourType) || other.behaviourType == behaviourType)&&(identical(other.alertTypeName, alertTypeName) || other.alertTypeName == alertTypeName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,behaviourId,delectedTime,behaviourType,alertTypeName);

@override
String toString() {
  return 'RiskyBehaviour(behaviourId: $behaviourId, delectedTime: $delectedTime, behaviourType: $behaviourType, alertTypeName: $alertTypeName)';
}


}

/// @nodoc
abstract mixin class $RiskyBehaviourCopyWith<$Res>  {
  factory $RiskyBehaviourCopyWith(RiskyBehaviour value, $Res Function(RiskyBehaviour) _then) = _$RiskyBehaviourCopyWithImpl;
@useResult
$Res call({
 String behaviourId, DateTime delectedTime, String behaviourType, String alertTypeName
});




}
/// @nodoc
class _$RiskyBehaviourCopyWithImpl<$Res>
    implements $RiskyBehaviourCopyWith<$Res> {
  _$RiskyBehaviourCopyWithImpl(this._self, this._then);

  final RiskyBehaviour _self;
  final $Res Function(RiskyBehaviour) _then;

/// Create a copy of RiskyBehaviour
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? behaviourId = null,Object? delectedTime = null,Object? behaviourType = null,Object? alertTypeName = null,}) {
  return _then(_self.copyWith(
behaviourId: null == behaviourId ? _self.behaviourId : behaviourId // ignore: cast_nullable_to_non_nullable
as String,delectedTime: null == delectedTime ? _self.delectedTime : delectedTime // ignore: cast_nullable_to_non_nullable
as DateTime,behaviourType: null == behaviourType ? _self.behaviourType : behaviourType // ignore: cast_nullable_to_non_nullable
as String,alertTypeName: null == alertTypeName ? _self.alertTypeName : alertTypeName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _RiskyBehaviour implements RiskyBehaviour {
   _RiskyBehaviour({required this.behaviourId, required this.delectedTime, required this.behaviourType, required this.alertTypeName});
  factory _RiskyBehaviour.fromJson(Map<String, dynamic> json) => _$RiskyBehaviourFromJson(json);

@override final  String behaviourId;
@override final  DateTime delectedTime;
@override final  String behaviourType;
@override final  String alertTypeName;

/// Create a copy of RiskyBehaviour
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiskyBehaviourCopyWith<_RiskyBehaviour> get copyWith => __$RiskyBehaviourCopyWithImpl<_RiskyBehaviour>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiskyBehaviourToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiskyBehaviour&&(identical(other.behaviourId, behaviourId) || other.behaviourId == behaviourId)&&(identical(other.delectedTime, delectedTime) || other.delectedTime == delectedTime)&&(identical(other.behaviourType, behaviourType) || other.behaviourType == behaviourType)&&(identical(other.alertTypeName, alertTypeName) || other.alertTypeName == alertTypeName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,behaviourId,delectedTime,behaviourType,alertTypeName);

@override
String toString() {
  return 'RiskyBehaviour(behaviourId: $behaviourId, delectedTime: $delectedTime, behaviourType: $behaviourType, alertTypeName: $alertTypeName)';
}


}

/// @nodoc
abstract mixin class _$RiskyBehaviourCopyWith<$Res> implements $RiskyBehaviourCopyWith<$Res> {
  factory _$RiskyBehaviourCopyWith(_RiskyBehaviour value, $Res Function(_RiskyBehaviour) _then) = __$RiskyBehaviourCopyWithImpl;
@override @useResult
$Res call({
 String behaviourId, DateTime delectedTime, String behaviourType, String alertTypeName
});




}
/// @nodoc
class __$RiskyBehaviourCopyWithImpl<$Res>
    implements _$RiskyBehaviourCopyWith<$Res> {
  __$RiskyBehaviourCopyWithImpl(this._self, this._then);

  final _RiskyBehaviour _self;
  final $Res Function(_RiskyBehaviour) _then;

/// Create a copy of RiskyBehaviour
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? behaviourId = null,Object? delectedTime = null,Object? behaviourType = null,Object? alertTypeName = null,}) {
  return _then(_RiskyBehaviour(
behaviourId: null == behaviourId ? _self.behaviourId : behaviourId // ignore: cast_nullable_to_non_nullable
as String,delectedTime: null == delectedTime ? _self.delectedTime : delectedTime // ignore: cast_nullable_to_non_nullable
as DateTime,behaviourType: null == behaviourType ? _self.behaviourType : behaviourType // ignore: cast_nullable_to_non_nullable
as String,alertTypeName: null == alertTypeName ? _self.alertTypeName : alertTypeName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
