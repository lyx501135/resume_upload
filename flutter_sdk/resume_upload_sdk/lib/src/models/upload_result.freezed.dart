// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UploadResult {

/// Whether the upload was successful.
 bool get success;/// The unique file identifier.
 String get fileId;/// The URL where the file can be accessed.
 String? get fileUrl;/// The server-assigned file ID.
 int? get serverId;/// Error message if the upload failed.
 String? get errorMessage;/// Additional metadata from the server.
 Map<String, dynamic>? get metadata;
/// Create a copy of UploadResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadResultCopyWith<UploadResult> get copyWith => _$UploadResultCopyWithImpl<UploadResult>(this as UploadResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UploadResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadResult&&(identical(other.success, _this.success) || other.success == _this.success)&&(identical(other.fileId, _this.fileId) || other.fileId == _this.fileId)&&(identical(other.fileUrl, _this.fileUrl) || other.fileUrl == _this.fileUrl)&&(identical(other.serverId, _this.serverId) || other.serverId == _this.serverId)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&const DeepCollectionEquality().equals(other.metadata, _this.metadata));
}


@override
int get hashCode {
  final _this = this as UploadResult;
  return Object.hash(runtimeType,_this.success,_this.fileId,_this.fileUrl,_this.serverId,_this.errorMessage,const DeepCollectionEquality().hash(_this.metadata));
}



}

/// @nodoc
abstract mixin class $UploadResultCopyWith<$Res>  {
  factory $UploadResultCopyWith(UploadResult value, $Res Function(UploadResult) _then) = _$UploadResultCopyWithImpl;
@useResult
$Res call({
 bool success, String fileId, String? fileUrl, int? serverId, String? errorMessage, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$UploadResultCopyWithImpl<$Res>
    implements $UploadResultCopyWith<$Res> {
  _$UploadResultCopyWithImpl(this._self, this._then);

  final UploadResult _self;
  final $Res Function(UploadResult) _then;

/// Create a copy of UploadResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? fileId = null,Object? fileUrl = freezed,Object? serverId = freezed,Object? errorMessage = freezed,Object? metadata = freezed,}) {
  return _then(UploadResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as int?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadResult].
extension UploadResultPatterns on UploadResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadResult value)  $default,){
final _that = this;
switch (_that) {
case _UploadResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadResult value)?  $default,){
final _that = this;
switch (_that) {
case _UploadResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  String fileId,  String? fileUrl,  int? serverId,  String? errorMessage,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadResult() when $default != null:
return $default(_that.success,_that.fileId,_that.fileUrl,_that.serverId,_that.errorMessage,_that.metadata);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  String fileId,  String? fileUrl,  int? serverId,  String? errorMessage,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _UploadResult():
return $default(_that.success,_that.fileId,_that.fileUrl,_that.serverId,_that.errorMessage,_that.metadata);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  String fileId,  String? fileUrl,  int? serverId,  String? errorMessage,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _UploadResult() when $default != null:
return $default(_that.success,_that.fileId,_that.fileUrl,_that.serverId,_that.errorMessage,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _UploadResult extends UploadResult {
  const _UploadResult({required this.success, required this.fileId, this.fileUrl, this.serverId, this.errorMessage,  Map<String, dynamic>? metadata}): _metadata = metadata,super._();
  

/// Whether the upload was successful.
@override final  bool success;
/// The unique file identifier.
@override final  String fileId;
/// The URL where the file can be accessed.
@override final  String? fileUrl;
/// The server-assigned file ID.
@override final  int? serverId;
/// Error message if the upload failed.
@override final  String? errorMessage;
/// Additional metadata from the server.
 final  Map<String, dynamic>? _metadata;
/// Additional metadata from the server.
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of UploadResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadResultCopyWith<_UploadResult> get copyWith => __$UploadResultCopyWithImpl<_UploadResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadResult&&(identical(other.success, success) || other.success == success)&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other.metadata, _metadata));
}


@override
int get hashCode {
    return Object.hash(runtimeType,success,fileId,fileUrl,serverId,errorMessage,const DeepCollectionEquality().hash(_metadata));
}



}

/// @nodoc
abstract mixin class _$UploadResultCopyWith<$Res> implements $UploadResultCopyWith<$Res> {
  factory _$UploadResultCopyWith(_UploadResult value, $Res Function(_UploadResult) _then) = __$UploadResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, String fileId, String? fileUrl, int? serverId, String? errorMessage, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$UploadResultCopyWithImpl<$Res>
    implements _$UploadResultCopyWith<$Res> {
  __$UploadResultCopyWithImpl(this._self, this._then);

  final _UploadResult _self;
  final $Res Function(_UploadResult) _then;

/// Create a copy of UploadResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? fileId = null,Object? fileUrl = freezed,Object? serverId = freezed,Object? errorMessage = freezed,Object? metadata = freezed,}) {
  return _then(_UploadResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as int?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
