// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UploadConfig {

/// Base URL for the upload server.
 String get baseUrl;/// Timeout for HTTP requests in seconds.
 int get timeoutSeconds;/// Maximum number of retry attempts for failed uploads.
 int get maxRetries;/// Delay between retries in milliseconds.
 int get retryDelayMs;/// Custom headers to include in requests.
 Map<String, String>? get headers;/// User ID for the upload (optional).
 String? get userId;/// Product code (optional).
 String? get productCode;/// Business system identifier (optional).
 String? get bizSystem;/// Directory ID for storage (optional).
 String? get dirId;/// Whether to use random file names.
 bool get isRandomName;
/// Create a copy of UploadConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadConfigCopyWith<UploadConfig> get copyWith => _$UploadConfigCopyWithImpl<UploadConfig>(this as UploadConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UploadConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadConfig&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.timeoutSeconds, _this.timeoutSeconds) || other.timeoutSeconds == _this.timeoutSeconds)&&(identical(other.maxRetries, _this.maxRetries) || other.maxRetries == _this.maxRetries)&&(identical(other.retryDelayMs, _this.retryDelayMs) || other.retryDelayMs == _this.retryDelayMs)&&const DeepCollectionEquality().equals(other.headers, _this.headers)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.productCode, _this.productCode) || other.productCode == _this.productCode)&&(identical(other.bizSystem, _this.bizSystem) || other.bizSystem == _this.bizSystem)&&(identical(other.dirId, _this.dirId) || other.dirId == _this.dirId)&&(identical(other.isRandomName, _this.isRandomName) || other.isRandomName == _this.isRandomName));
}


@override
int get hashCode {
  final _this = this as UploadConfig;
  return Object.hash(runtimeType,_this.baseUrl,_this.timeoutSeconds,_this.maxRetries,_this.retryDelayMs,const DeepCollectionEquality().hash(_this.headers),_this.userId,_this.productCode,_this.bizSystem,_this.dirId,_this.isRandomName);
}

@override
String toString() {
  final _this = this as UploadConfig;
  return 'UploadConfig(baseUrl: ${_this.baseUrl}, timeoutSeconds: ${_this.timeoutSeconds}, maxRetries: ${_this.maxRetries}, retryDelayMs: ${_this.retryDelayMs}, headers: ${_this.headers}, userId: ${_this.userId}, productCode: ${_this.productCode}, bizSystem: ${_this.bizSystem}, dirId: ${_this.dirId}, isRandomName: ${_this.isRandomName})';
}


}

/// @nodoc
abstract mixin class $UploadConfigCopyWith<$Res>  {
  factory $UploadConfigCopyWith(UploadConfig value, $Res Function(UploadConfig) _then) = _$UploadConfigCopyWithImpl;
@useResult
$Res call({
 String baseUrl, int timeoutSeconds, int maxRetries, int retryDelayMs, Map<String, String>? headers, String? userId, String? productCode, String? bizSystem, String? dirId, bool isRandomName
});




}
/// @nodoc
class _$UploadConfigCopyWithImpl<$Res>
    implements $UploadConfigCopyWith<$Res> {
  _$UploadConfigCopyWithImpl(this._self, this._then);

  final UploadConfig _self;
  final $Res Function(UploadConfig) _then;

/// Create a copy of UploadConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseUrl = null,Object? timeoutSeconds = null,Object? maxRetries = null,Object? retryDelayMs = null,Object? headers = freezed,Object? userId = freezed,Object? productCode = freezed,Object? bizSystem = freezed,Object? dirId = freezed,Object? isRandomName = null,}) {
  return _then(UploadConfig(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,timeoutSeconds: null == timeoutSeconds ? _self.timeoutSeconds : timeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,maxRetries: null == maxRetries ? _self.maxRetries : maxRetries // ignore: cast_nullable_to_non_nullable
as int,retryDelayMs: null == retryDelayMs ? _self.retryDelayMs : retryDelayMs // ignore: cast_nullable_to_non_nullable
as int,headers: freezed == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,productCode: freezed == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String?,bizSystem: freezed == bizSystem ? _self.bizSystem : bizSystem // ignore: cast_nullable_to_non_nullable
as String?,dirId: freezed == dirId ? _self.dirId : dirId // ignore: cast_nullable_to_non_nullable
as String?,isRandomName: null == isRandomName ? _self.isRandomName : isRandomName // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadConfig].
extension UploadConfigPatterns on UploadConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadConfig value)  $default,){
final _that = this;
switch (_that) {
case _UploadConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadConfig value)?  $default,){
final _that = this;
switch (_that) {
case _UploadConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String baseUrl,  int timeoutSeconds,  int maxRetries,  int retryDelayMs,  Map<String, String>? headers,  String? userId,  String? productCode,  String? bizSystem,  String? dirId,  bool isRandomName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadConfig() when $default != null:
return $default(_that.baseUrl,_that.timeoutSeconds,_that.maxRetries,_that.retryDelayMs,_that.headers,_that.userId,_that.productCode,_that.bizSystem,_that.dirId,_that.isRandomName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String baseUrl,  int timeoutSeconds,  int maxRetries,  int retryDelayMs,  Map<String, String>? headers,  String? userId,  String? productCode,  String? bizSystem,  String? dirId,  bool isRandomName)  $default,) {final _that = this;
switch (_that) {
case _UploadConfig():
return $default(_that.baseUrl,_that.timeoutSeconds,_that.maxRetries,_that.retryDelayMs,_that.headers,_that.userId,_that.productCode,_that.bizSystem,_that.dirId,_that.isRandomName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String baseUrl,  int timeoutSeconds,  int maxRetries,  int retryDelayMs,  Map<String, String>? headers,  String? userId,  String? productCode,  String? bizSystem,  String? dirId,  bool isRandomName)?  $default,) {final _that = this;
switch (_that) {
case _UploadConfig() when $default != null:
return $default(_that.baseUrl,_that.timeoutSeconds,_that.maxRetries,_that.retryDelayMs,_that.headers,_that.userId,_that.productCode,_that.bizSystem,_that.dirId,_that.isRandomName);case _:
  return null;

}
}

}

/// @nodoc


class _UploadConfig extends UploadConfig {
  const _UploadConfig({required this.baseUrl, this.timeoutSeconds = 30, this.maxRetries = 3, this.retryDelayMs = 1000,  Map<String, String>? headers, this.userId, this.productCode, this.bizSystem, this.dirId, this.isRandomName = false}): _headers = headers,super._();
  

/// Base URL for the upload server.
@override final  String baseUrl;
/// Timeout for HTTP requests in seconds.
@override@JsonKey() final  int timeoutSeconds;
/// Maximum number of retry attempts for failed uploads.
@override@JsonKey() final  int maxRetries;
/// Delay between retries in milliseconds.
@override@JsonKey() final  int retryDelayMs;
/// Custom headers to include in requests.
 final  Map<String, String>? _headers;
/// Custom headers to include in requests.
@override Map<String, String>? get headers {
  final value = _headers;
  if (value == null) return null;
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// User ID for the upload (optional).
@override final  String? userId;
/// Product code (optional).
@override final  String? productCode;
/// Business system identifier (optional).
@override final  String? bizSystem;
/// Directory ID for storage (optional).
@override final  String? dirId;
/// Whether to use random file names.
@override@JsonKey() final  bool isRandomName;

/// Create a copy of UploadConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadConfigCopyWith<_UploadConfig> get copyWith => __$UploadConfigCopyWithImpl<_UploadConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadConfig&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.timeoutSeconds, timeoutSeconds) || other.timeoutSeconds == timeoutSeconds)&&(identical(other.maxRetries, maxRetries) || other.maxRetries == maxRetries)&&(identical(other.retryDelayMs, retryDelayMs) || other.retryDelayMs == retryDelayMs)&&const DeepCollectionEquality().equals(other.headers, _headers)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.productCode, productCode) || other.productCode == productCode)&&(identical(other.bizSystem, bizSystem) || other.bizSystem == bizSystem)&&(identical(other.dirId, dirId) || other.dirId == dirId)&&(identical(other.isRandomName, isRandomName) || other.isRandomName == isRandomName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,baseUrl,timeoutSeconds,maxRetries,retryDelayMs,const DeepCollectionEquality().hash(_headers),userId,productCode,bizSystem,dirId,isRandomName);
}

@override
String toString() {
    return 'UploadConfig(baseUrl: $baseUrl, timeoutSeconds: $timeoutSeconds, maxRetries: $maxRetries, retryDelayMs: $retryDelayMs, headers: $headers, userId: $userId, productCode: $productCode, bizSystem: $bizSystem, dirId: $dirId, isRandomName: $isRandomName)';
}


}

/// @nodoc
abstract mixin class _$UploadConfigCopyWith<$Res> implements $UploadConfigCopyWith<$Res> {
  factory _$UploadConfigCopyWith(_UploadConfig value, $Res Function(_UploadConfig) _then) = __$UploadConfigCopyWithImpl;
@override @useResult
$Res call({
 String baseUrl, int timeoutSeconds, int maxRetries, int retryDelayMs, Map<String, String>? headers, String? userId, String? productCode, String? bizSystem, String? dirId, bool isRandomName
});




}
/// @nodoc
class __$UploadConfigCopyWithImpl<$Res>
    implements _$UploadConfigCopyWith<$Res> {
  __$UploadConfigCopyWithImpl(this._self, this._then);

  final _UploadConfig _self;
  final $Res Function(_UploadConfig) _then;

/// Create a copy of UploadConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseUrl = null,Object? timeoutSeconds = null,Object? maxRetries = null,Object? retryDelayMs = null,Object? headers = freezed,Object? userId = freezed,Object? productCode = freezed,Object? bizSystem = freezed,Object? dirId = freezed,Object? isRandomName = null,}) {
  return _then(_UploadConfig(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,timeoutSeconds: null == timeoutSeconds ? _self.timeoutSeconds : timeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,maxRetries: null == maxRetries ? _self.maxRetries : maxRetries // ignore: cast_nullable_to_non_nullable
as int,retryDelayMs: null == retryDelayMs ? _self.retryDelayMs : retryDelayMs // ignore: cast_nullable_to_non_nullable
as int,headers: freezed == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,productCode: freezed == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String?,bizSystem: freezed == bizSystem ? _self.bizSystem : bizSystem // ignore: cast_nullable_to_non_nullable
as String?,dirId: freezed == dirId ? _self.dirId : dirId // ignore: cast_nullable_to_non_nullable
as String?,isRandomName: null == isRandomName ? _self.isRandomName : isRandomName // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
