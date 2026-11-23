// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UploadProgress {

/// The unique file identifier.
 String get fileId;/// The file name.
 String get fileName;/// Total size of the file in bytes.
 int get totalBytes;/// Number of bytes uploaded so far.
 int get uploadedBytes;/// Upload progress as a fraction (0.0 to 1.0).
 double get progress;/// Upload speed in bytes per second.
 double get speed;/// Current block index being uploaded.
 int get currentBlockIndex;/// Total number of blocks.
 int get totalBlocks;/// Current upload status.
 UploadStatus get status;/// Error message if any.
 String? get errorMessage;
/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadProgressCopyWith<UploadProgress> get copyWith => _$UploadProgressCopyWithImpl<UploadProgress>(this as UploadProgress, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UploadProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadProgress&&(identical(other.fileId, _this.fileId) || other.fileId == _this.fileId)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.totalBytes, _this.totalBytes) || other.totalBytes == _this.totalBytes)&&(identical(other.uploadedBytes, _this.uploadedBytes) || other.uploadedBytes == _this.uploadedBytes)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.currentBlockIndex, _this.currentBlockIndex) || other.currentBlockIndex == _this.currentBlockIndex)&&(identical(other.totalBlocks, _this.totalBlocks) || other.totalBlocks == _this.totalBlocks)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as UploadProgress;
  return Object.hash(runtimeType,_this.fileId,_this.fileName,_this.totalBytes,_this.uploadedBytes,_this.progress,_this.speed,_this.currentBlockIndex,_this.totalBlocks,_this.status,_this.errorMessage);
}



}

/// @nodoc
abstract mixin class $UploadProgressCopyWith<$Res>  {
  factory $UploadProgressCopyWith(UploadProgress value, $Res Function(UploadProgress) _then) = _$UploadProgressCopyWithImpl;
@useResult
$Res call({
 String fileId, String fileName, int totalBytes, int uploadedBytes, double progress, double speed, int currentBlockIndex, int totalBlocks, UploadStatus status, String? errorMessage
});




}
/// @nodoc
class _$UploadProgressCopyWithImpl<$Res>
    implements $UploadProgressCopyWith<$Res> {
  _$UploadProgressCopyWithImpl(this._self, this._then);

  final UploadProgress _self;
  final $Res Function(UploadProgress) _then;

/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,Object? fileName = null,Object? totalBytes = null,Object? uploadedBytes = null,Object? progress = null,Object? speed = null,Object? currentBlockIndex = null,Object? totalBlocks = null,Object? status = null,Object? errorMessage = freezed,}) {
  return _then(UploadProgress(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedBytes: null == uploadedBytes ? _self.uploadedBytes : uploadedBytes // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,currentBlockIndex: null == currentBlockIndex ? _self.currentBlockIndex : currentBlockIndex // ignore: cast_nullable_to_non_nullable
as int,totalBlocks: null == totalBlocks ? _self.totalBlocks : totalBlocks // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UploadStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadProgress].
extension UploadProgressPatterns on UploadProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadProgress value)  $default,){
final _that = this;
switch (_that) {
case _UploadProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadProgress value)?  $default,){
final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileId,  String fileName,  int totalBytes,  int uploadedBytes,  double progress,  double speed,  int currentBlockIndex,  int totalBlocks,  UploadStatus status,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
return $default(_that.fileId,_that.fileName,_that.totalBytes,_that.uploadedBytes,_that.progress,_that.speed,_that.currentBlockIndex,_that.totalBlocks,_that.status,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileId,  String fileName,  int totalBytes,  int uploadedBytes,  double progress,  double speed,  int currentBlockIndex,  int totalBlocks,  UploadStatus status,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _UploadProgress():
return $default(_that.fileId,_that.fileName,_that.totalBytes,_that.uploadedBytes,_that.progress,_that.speed,_that.currentBlockIndex,_that.totalBlocks,_that.status,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileId,  String fileName,  int totalBytes,  int uploadedBytes,  double progress,  double speed,  int currentBlockIndex,  int totalBlocks,  UploadStatus status,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
return $default(_that.fileId,_that.fileName,_that.totalBytes,_that.uploadedBytes,_that.progress,_that.speed,_that.currentBlockIndex,_that.totalBlocks,_that.status,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _UploadProgress extends UploadProgress {
  const _UploadProgress({required this.fileId, required this.fileName, required this.totalBytes, required this.uploadedBytes, required this.progress, required this.speed, required this.currentBlockIndex, required this.totalBlocks, required this.status, this.errorMessage}): super._();
  

/// The unique file identifier.
@override final  String fileId;
/// The file name.
@override final  String fileName;
/// Total size of the file in bytes.
@override final  int totalBytes;
/// Number of bytes uploaded so far.
@override final  int uploadedBytes;
/// Upload progress as a fraction (0.0 to 1.0).
@override final  double progress;
/// Upload speed in bytes per second.
@override final  double speed;
/// Current block index being uploaded.
@override final  int currentBlockIndex;
/// Total number of blocks.
@override final  int totalBlocks;
/// Current upload status.
@override final  UploadStatus status;
/// Error message if any.
@override final  String? errorMessage;

/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadProgressCopyWith<_UploadProgress> get copyWith => __$UploadProgressCopyWithImpl<_UploadProgress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadProgress&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.uploadedBytes, uploadedBytes) || other.uploadedBytes == uploadedBytes)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.currentBlockIndex, currentBlockIndex) || other.currentBlockIndex == currentBlockIndex)&&(identical(other.totalBlocks, totalBlocks) || other.totalBlocks == totalBlocks)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fileId,fileName,totalBytes,uploadedBytes,progress,speed,currentBlockIndex,totalBlocks,status,errorMessage);
}



}

/// @nodoc
abstract mixin class _$UploadProgressCopyWith<$Res> implements $UploadProgressCopyWith<$Res> {
  factory _$UploadProgressCopyWith(_UploadProgress value, $Res Function(_UploadProgress) _then) = __$UploadProgressCopyWithImpl;
@override @useResult
$Res call({
 String fileId, String fileName, int totalBytes, int uploadedBytes, double progress, double speed, int currentBlockIndex, int totalBlocks, UploadStatus status, String? errorMessage
});




}
/// @nodoc
class __$UploadProgressCopyWithImpl<$Res>
    implements _$UploadProgressCopyWith<$Res> {
  __$UploadProgressCopyWithImpl(this._self, this._then);

  final _UploadProgress _self;
  final $Res Function(_UploadProgress) _then;

/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,Object? fileName = null,Object? totalBytes = null,Object? uploadedBytes = null,Object? progress = null,Object? speed = null,Object? currentBlockIndex = null,Object? totalBlocks = null,Object? status = null,Object? errorMessage = freezed,}) {
  return _then(_UploadProgress(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedBytes: null == uploadedBytes ? _self.uploadedBytes : uploadedBytes // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,currentBlockIndex: null == currentBlockIndex ? _self.currentBlockIndex : currentBlockIndex // ignore: cast_nullable_to_non_nullable
as int,totalBlocks: null == totalBlocks ? _self.totalBlocks : totalBlocks // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UploadStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
