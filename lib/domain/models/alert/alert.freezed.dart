// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Alert {

 String get alertId; String get alertTypeName; Map<String, dynamic> get musicPlayList; Map<String, dynamic> get audioFilePath;
/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlertCopyWith<Alert> get copyWith => _$AlertCopyWithImpl<Alert>(this as Alert, _$identity);

  /// Serializes this Alert to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Alert&&(identical(other.alertId, alertId) || other.alertId == alertId)&&(identical(other.alertTypeName, alertTypeName) || other.alertTypeName == alertTypeName)&&const DeepCollectionEquality().equals(other.musicPlayList, musicPlayList)&&const DeepCollectionEquality().equals(other.audioFilePath, audioFilePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alertId,alertTypeName,const DeepCollectionEquality().hash(musicPlayList),const DeepCollectionEquality().hash(audioFilePath));

@override
String toString() {
  return 'Alert(alertId: $alertId, alertTypeName: $alertTypeName, musicPlayList: $musicPlayList, audioFilePath: $audioFilePath)';
}


}

/// @nodoc
abstract mixin class $AlertCopyWith<$Res>  {
  factory $AlertCopyWith(Alert value, $Res Function(Alert) _then) = _$AlertCopyWithImpl;
@useResult
$Res call({
 String alertId, String alertTypeName, Map<String, dynamic> musicPlayList, Map<String, dynamic> audioFilePath
});




}
/// @nodoc
class _$AlertCopyWithImpl<$Res>
    implements $AlertCopyWith<$Res> {
  _$AlertCopyWithImpl(this._self, this._then);

  final Alert _self;
  final $Res Function(Alert) _then;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? alertId = null,Object? alertTypeName = null,Object? musicPlayList = null,Object? audioFilePath = null,}) {
  return _then(_self.copyWith(
alertId: null == alertId ? _self.alertId : alertId // ignore: cast_nullable_to_non_nullable
as String,alertTypeName: null == alertTypeName ? _self.alertTypeName : alertTypeName // ignore: cast_nullable_to_non_nullable
as String,musicPlayList: null == musicPlayList ? _self.musicPlayList : musicPlayList // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,audioFilePath: null == audioFilePath ? _self.audioFilePath : audioFilePath // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Alert implements Alert {
   _Alert({required this.alertId, required this.alertTypeName, required final  Map<String, dynamic> musicPlayList, required final  Map<String, dynamic> audioFilePath}): _musicPlayList = musicPlayList,_audioFilePath = audioFilePath;
  factory _Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);

@override final  String alertId;
@override final  String alertTypeName;
 final  Map<String, dynamic> _musicPlayList;
@override Map<String, dynamic> get musicPlayList {
  if (_musicPlayList is EqualUnmodifiableMapView) return _musicPlayList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_musicPlayList);
}

 final  Map<String, dynamic> _audioFilePath;
@override Map<String, dynamic> get audioFilePath {
  if (_audioFilePath is EqualUnmodifiableMapView) return _audioFilePath;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_audioFilePath);
}


/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlertCopyWith<_Alert> get copyWith => __$AlertCopyWithImpl<_Alert>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlertToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Alert&&(identical(other.alertId, alertId) || other.alertId == alertId)&&(identical(other.alertTypeName, alertTypeName) || other.alertTypeName == alertTypeName)&&const DeepCollectionEquality().equals(other._musicPlayList, _musicPlayList)&&const DeepCollectionEquality().equals(other._audioFilePath, _audioFilePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alertId,alertTypeName,const DeepCollectionEquality().hash(_musicPlayList),const DeepCollectionEquality().hash(_audioFilePath));

@override
String toString() {
  return 'Alert(alertId: $alertId, alertTypeName: $alertTypeName, musicPlayList: $musicPlayList, audioFilePath: $audioFilePath)';
}


}

/// @nodoc
abstract mixin class _$AlertCopyWith<$Res> implements $AlertCopyWith<$Res> {
  factory _$AlertCopyWith(_Alert value, $Res Function(_Alert) _then) = __$AlertCopyWithImpl;
@override @useResult
$Res call({
 String alertId, String alertTypeName, Map<String, dynamic> musicPlayList, Map<String, dynamic> audioFilePath
});




}
/// @nodoc
class __$AlertCopyWithImpl<$Res>
    implements _$AlertCopyWith<$Res> {
  __$AlertCopyWithImpl(this._self, this._then);

  final _Alert _self;
  final $Res Function(_Alert) _then;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? alertId = null,Object? alertTypeName = null,Object? musicPlayList = null,Object? audioFilePath = null,}) {
  return _then(_Alert(
alertId: null == alertId ? _self.alertId : alertId // ignore: cast_nullable_to_non_nullable
as String,alertTypeName: null == alertTypeName ? _self.alertTypeName : alertTypeName // ignore: cast_nullable_to_non_nullable
as String,musicPlayList: null == musicPlayList ? _self._musicPlayList : musicPlayList // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,audioFilePath: null == audioFilePath ? _self._audioFilePath : audioFilePath // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
