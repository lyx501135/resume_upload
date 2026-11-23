// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'block_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BlockInfo {

/// Block index (0-based).
 int get index;/// CRC32 checksum of the block.
@JsonKey(fromJson: _intFromJson) int get crc;/// Block status.
@JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson) BlockStatus get status;/// Range of data uploaded (for partial uploads).
 String? get range;/// Size of this block in bytes. Read from [range] when parsing JSON, and
/// not written to JSON.
@JsonKey(readValue: _sizeFromRange, includeToJson: false) int get size;
/// Create a copy of BlockInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockInfoCopyWith<BlockInfo> get copyWith => _$BlockInfoCopyWithImpl<BlockInfo>(this as BlockInfo, _$identity);

  /// Serializes this BlockInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BlockInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockInfo&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.crc, _this.crc) || other.crc == _this.crc)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.size, _this.size) || other.size == _this.size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BlockInfo;
  return Object.hash(runtimeType,_this.index,_this.crc,_this.status,_this.range,_this.size);
}



}

/// @nodoc
abstract mixin class $BlockInfoCopyWith<$Res>  {
  factory $BlockInfoCopyWith(BlockInfo value, $Res Function(BlockInfo) _then) = _$BlockInfoCopyWithImpl;
@useResult
$Res call({
 int index,@JsonKey(fromJson: _intFromJson) int crc,@JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson) BlockStatus status, String? range,@JsonKey(readValue: _sizeFromRange, includeToJson: false) int size
});




}
/// @nodoc
class _$BlockInfoCopyWithImpl<$Res>
    implements $BlockInfoCopyWith<$Res> {
  _$BlockInfoCopyWithImpl(this._self, this._then);

  final BlockInfo _self;
  final $Res Function(BlockInfo) _then;

/// Create a copy of BlockInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? crc = null,Object? status = null,Object? range = freezed,Object? size = null,}) {
  return _then(BlockInfo(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,crc: null == crc ? _self.crc : crc // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BlockStatus,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BlockInfo].
extension BlockInfoPatterns on BlockInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockInfo value)  $default,){
final _that = this;
switch (_that) {
case _BlockInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BlockInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index, @JsonKey(fromJson: _intFromJson)  int crc, @JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson)  BlockStatus status,  String? range, @JsonKey(readValue: _sizeFromRange, includeToJson: false)  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockInfo() when $default != null:
return $default(_that.index,_that.crc,_that.status,_that.range,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index, @JsonKey(fromJson: _intFromJson)  int crc, @JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson)  BlockStatus status,  String? range, @JsonKey(readValue: _sizeFromRange, includeToJson: false)  int size)  $default,) {final _that = this;
switch (_that) {
case _BlockInfo():
return $default(_that.index,_that.crc,_that.status,_that.range,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index, @JsonKey(fromJson: _intFromJson)  int crc, @JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson)  BlockStatus status,  String? range, @JsonKey(readValue: _sizeFromRange, includeToJson: false)  int size)?  $default,) {final _that = this;
switch (_that) {
case _BlockInfo() when $default != null:
return $default(_that.index,_that.crc,_that.status,_that.range,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlockInfo extends BlockInfo {
  const _BlockInfo({required this.index, @JsonKey(fromJson: _intFromJson) required this.crc, @JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson) required this.status, this.range, @JsonKey(readValue: _sizeFromRange, includeToJson: false) this.size = 0}): super._();
  factory _BlockInfo.fromJson(Map<String, dynamic> json) => _$BlockInfoFromJson(json);

/// Block index (0-based).
@override final  int index;
/// CRC32 checksum of the block.
@override@JsonKey(fromJson: _intFromJson) final  int crc;
/// Block status.
@override@JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson) final  BlockStatus status;
/// Range of data uploaded (for partial uploads).
@override final  String? range;
/// Size of this block in bytes. Read from [range] when parsing JSON, and
/// not written to JSON.
@override@JsonKey(readValue: _sizeFromRange, includeToJson: false) final  int size;

/// Create a copy of BlockInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockInfoCopyWith<_BlockInfo> get copyWith => __$BlockInfoCopyWithImpl<_BlockInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlockInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockInfo&&(identical(other.index, index) || other.index == index)&&(identical(other.crc, crc) || other.crc == crc)&&(identical(other.status, status) || other.status == status)&&(identical(other.range, range) || other.range == range)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,crc,status,range,size);
}



}

/// @nodoc
abstract mixin class _$BlockInfoCopyWith<$Res> implements $BlockInfoCopyWith<$Res> {
  factory _$BlockInfoCopyWith(_BlockInfo value, $Res Function(_BlockInfo) _then) = __$BlockInfoCopyWithImpl;
@override @useResult
$Res call({
 int index,@JsonKey(fromJson: _intFromJson) int crc,@JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson) BlockStatus status, String? range,@JsonKey(readValue: _sizeFromRange, includeToJson: false) int size
});




}
/// @nodoc
class __$BlockInfoCopyWithImpl<$Res>
    implements _$BlockInfoCopyWith<$Res> {
  __$BlockInfoCopyWithImpl(this._self, this._then);

  final _BlockInfo _self;
  final $Res Function(_BlockInfo) _then;

/// Create a copy of BlockInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? crc = null,Object? status = null,Object? range = freezed,Object? size = null,}) {
  return _then(_BlockInfo(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,crc: null == crc ? _self.crc : crc // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BlockStatus,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FileInfoResponse {

/// File unique identifier.
 String get fid;/// File status.
@JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson) FileStatus get fstatus;/// File name.
 String? get fileName;/// File size in bytes.
 int get fileSize;/// Block size used.
 int get blockSize;/// Total block count.
 int get blockCount;/// File CRC.
@JsonKey(fromJson: _intFromJson) int get fcrc;/// File extension.
 String? get fileExt;/// File URL (if completed).
 String? get furl;/// Map of uploaded blocks.
@JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson) Map<String, BlockInfo> get blockMap;/// File creation date timestamp.
 int? get createDate;/// File last modified date timestamp.
 int? get lastModifyDate;
/// Create a copy of FileInfoResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileInfoResponseCopyWith<FileInfoResponse> get copyWith => _$FileInfoResponseCopyWithImpl<FileInfoResponse>(this as FileInfoResponse, _$identity);

  /// Serializes this FileInfoResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FileInfoResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileInfoResponse&&(identical(other.fid, _this.fid) || other.fid == _this.fid)&&(identical(other.fstatus, _this.fstatus) || other.fstatus == _this.fstatus)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.fileSize, _this.fileSize) || other.fileSize == _this.fileSize)&&(identical(other.blockSize, _this.blockSize) || other.blockSize == _this.blockSize)&&(identical(other.blockCount, _this.blockCount) || other.blockCount == _this.blockCount)&&(identical(other.fcrc, _this.fcrc) || other.fcrc == _this.fcrc)&&(identical(other.fileExt, _this.fileExt) || other.fileExt == _this.fileExt)&&(identical(other.furl, _this.furl) || other.furl == _this.furl)&&const DeepCollectionEquality().equals(other.blockMap, _this.blockMap)&&(identical(other.createDate, _this.createDate) || other.createDate == _this.createDate)&&(identical(other.lastModifyDate, _this.lastModifyDate) || other.lastModifyDate == _this.lastModifyDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FileInfoResponse;
  return Object.hash(runtimeType,_this.fid,_this.fstatus,_this.fileName,_this.fileSize,_this.blockSize,_this.blockCount,_this.fcrc,_this.fileExt,_this.furl,const DeepCollectionEquality().hash(_this.blockMap),_this.createDate,_this.lastModifyDate);
}



}

/// @nodoc
abstract mixin class $FileInfoResponseCopyWith<$Res>  {
  factory $FileInfoResponseCopyWith(FileInfoResponse value, $Res Function(FileInfoResponse) _then) = _$FileInfoResponseCopyWithImpl;
@useResult
$Res call({
 String fid,@JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson) FileStatus fstatus, String? fileName, int fileSize, int blockSize, int blockCount,@JsonKey(fromJson: _intFromJson) int fcrc, String? fileExt, String? furl,@JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson) Map<String, BlockInfo> blockMap, int? createDate, int? lastModifyDate
});




}
/// @nodoc
class _$FileInfoResponseCopyWithImpl<$Res>
    implements $FileInfoResponseCopyWith<$Res> {
  _$FileInfoResponseCopyWithImpl(this._self, this._then);

  final FileInfoResponse _self;
  final $Res Function(FileInfoResponse) _then;

/// Create a copy of FileInfoResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fid = null,Object? fstatus = null,Object? fileName = freezed,Object? fileSize = null,Object? blockSize = null,Object? blockCount = null,Object? fcrc = null,Object? fileExt = freezed,Object? furl = freezed,Object? blockMap = null,Object? createDate = freezed,Object? lastModifyDate = freezed,}) {
  return _then(FileInfoResponse(
fid: null == fid ? _self.fid : fid // ignore: cast_nullable_to_non_nullable
as String,fstatus: null == fstatus ? _self.fstatus : fstatus // ignore: cast_nullable_to_non_nullable
as FileStatus,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,blockSize: null == blockSize ? _self.blockSize : blockSize // ignore: cast_nullable_to_non_nullable
as int,blockCount: null == blockCount ? _self.blockCount : blockCount // ignore: cast_nullable_to_non_nullable
as int,fcrc: null == fcrc ? _self.fcrc : fcrc // ignore: cast_nullable_to_non_nullable
as int,fileExt: freezed == fileExt ? _self.fileExt : fileExt // ignore: cast_nullable_to_non_nullable
as String?,furl: freezed == furl ? _self.furl : furl // ignore: cast_nullable_to_non_nullable
as String?,blockMap: null == blockMap ? _self.blockMap : blockMap // ignore: cast_nullable_to_non_nullable
as Map<String, BlockInfo>,createDate: freezed == createDate ? _self.createDate : createDate // ignore: cast_nullable_to_non_nullable
as int?,lastModifyDate: freezed == lastModifyDate ? _self.lastModifyDate : lastModifyDate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileInfoResponse].
extension FileInfoResponsePatterns on FileInfoResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileInfoResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileInfoResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileInfoResponse value)  $default,){
final _that = this;
switch (_that) {
case _FileInfoResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileInfoResponse value)?  $default,){
final _that = this;
switch (_that) {
case _FileInfoResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fid, @JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson)  FileStatus fstatus,  String? fileName,  int fileSize,  int blockSize,  int blockCount, @JsonKey(fromJson: _intFromJson)  int fcrc,  String? fileExt,  String? furl, @JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson)  Map<String, BlockInfo> blockMap,  int? createDate,  int? lastModifyDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileInfoResponse() when $default != null:
return $default(_that.fid,_that.fstatus,_that.fileName,_that.fileSize,_that.blockSize,_that.blockCount,_that.fcrc,_that.fileExt,_that.furl,_that.blockMap,_that.createDate,_that.lastModifyDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fid, @JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson)  FileStatus fstatus,  String? fileName,  int fileSize,  int blockSize,  int blockCount, @JsonKey(fromJson: _intFromJson)  int fcrc,  String? fileExt,  String? furl, @JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson)  Map<String, BlockInfo> blockMap,  int? createDate,  int? lastModifyDate)  $default,) {final _that = this;
switch (_that) {
case _FileInfoResponse():
return $default(_that.fid,_that.fstatus,_that.fileName,_that.fileSize,_that.blockSize,_that.blockCount,_that.fcrc,_that.fileExt,_that.furl,_that.blockMap,_that.createDate,_that.lastModifyDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fid, @JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson)  FileStatus fstatus,  String? fileName,  int fileSize,  int blockSize,  int blockCount, @JsonKey(fromJson: _intFromJson)  int fcrc,  String? fileExt,  String? furl, @JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson)  Map<String, BlockInfo> blockMap,  int? createDate,  int? lastModifyDate)?  $default,) {final _that = this;
switch (_that) {
case _FileInfoResponse() when $default != null:
return $default(_that.fid,_that.fstatus,_that.fileName,_that.fileSize,_that.blockSize,_that.blockCount,_that.fcrc,_that.fileExt,_that.furl,_that.blockMap,_that.createDate,_that.lastModifyDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileInfoResponse extends FileInfoResponse {
  const _FileInfoResponse({required this.fid, @JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson) required this.fstatus, this.fileName, required this.fileSize, required this.blockSize, required this.blockCount, @JsonKey(fromJson: _intFromJson) required this.fcrc, this.fileExt, this.furl, @JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson) required  Map<String, BlockInfo> blockMap, this.createDate, this.lastModifyDate}): _blockMap = blockMap,super._();
  factory _FileInfoResponse.fromJson(Map<String, dynamic> json) => _$FileInfoResponseFromJson(json);

/// File unique identifier.
@override final  String fid;
/// File status.
@override@JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson) final  FileStatus fstatus;
/// File name.
@override final  String? fileName;
/// File size in bytes.
@override final  int fileSize;
/// Block size used.
@override final  int blockSize;
/// Total block count.
@override final  int blockCount;
/// File CRC.
@override@JsonKey(fromJson: _intFromJson) final  int fcrc;
/// File extension.
@override final  String? fileExt;
/// File URL (if completed).
@override final  String? furl;
/// Map of uploaded blocks.
 final  Map<String, BlockInfo> _blockMap;
/// Map of uploaded blocks.
@override@JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson) Map<String, BlockInfo> get blockMap {
  if (_blockMap is EqualUnmodifiableMapView) return _blockMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_blockMap);
}

/// File creation date timestamp.
@override final  int? createDate;
/// File last modified date timestamp.
@override final  int? lastModifyDate;

/// Create a copy of FileInfoResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileInfoResponseCopyWith<_FileInfoResponse> get copyWith => __$FileInfoResponseCopyWithImpl<_FileInfoResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileInfoResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileInfoResponse&&(identical(other.fid, fid) || other.fid == fid)&&(identical(other.fstatus, fstatus) || other.fstatus == fstatus)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.blockSize, blockSize) || other.blockSize == blockSize)&&(identical(other.blockCount, blockCount) || other.blockCount == blockCount)&&(identical(other.fcrc, fcrc) || other.fcrc == fcrc)&&(identical(other.fileExt, fileExt) || other.fileExt == fileExt)&&(identical(other.furl, furl) || other.furl == furl)&&const DeepCollectionEquality().equals(other.blockMap, _blockMap)&&(identical(other.createDate, createDate) || other.createDate == createDate)&&(identical(other.lastModifyDate, lastModifyDate) || other.lastModifyDate == lastModifyDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fid,fstatus,fileName,fileSize,blockSize,blockCount,fcrc,fileExt,furl,const DeepCollectionEquality().hash(_blockMap),createDate,lastModifyDate);
}



}

/// @nodoc
abstract mixin class _$FileInfoResponseCopyWith<$Res> implements $FileInfoResponseCopyWith<$Res> {
  factory _$FileInfoResponseCopyWith(_FileInfoResponse value, $Res Function(_FileInfoResponse) _then) = __$FileInfoResponseCopyWithImpl;
@override @useResult
$Res call({
 String fid,@JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson) FileStatus fstatus, String? fileName, int fileSize, int blockSize, int blockCount,@JsonKey(fromJson: _intFromJson) int fcrc, String? fileExt, String? furl,@JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson) Map<String, BlockInfo> blockMap, int? createDate, int? lastModifyDate
});




}
/// @nodoc
class __$FileInfoResponseCopyWithImpl<$Res>
    implements _$FileInfoResponseCopyWith<$Res> {
  __$FileInfoResponseCopyWithImpl(this._self, this._then);

  final _FileInfoResponse _self;
  final $Res Function(_FileInfoResponse) _then;

/// Create a copy of FileInfoResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fid = null,Object? fstatus = null,Object? fileName = freezed,Object? fileSize = null,Object? blockSize = null,Object? blockCount = null,Object? fcrc = null,Object? fileExt = freezed,Object? furl = freezed,Object? blockMap = null,Object? createDate = freezed,Object? lastModifyDate = freezed,}) {
  return _then(_FileInfoResponse(
fid: null == fid ? _self.fid : fid // ignore: cast_nullable_to_non_nullable
as String,fstatus: null == fstatus ? _self.fstatus : fstatus // ignore: cast_nullable_to_non_nullable
as FileStatus,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,blockSize: null == blockSize ? _self.blockSize : blockSize // ignore: cast_nullable_to_non_nullable
as int,blockCount: null == blockCount ? _self.blockCount : blockCount // ignore: cast_nullable_to_non_nullable
as int,fcrc: null == fcrc ? _self.fcrc : fcrc // ignore: cast_nullable_to_non_nullable
as int,fileExt: freezed == fileExt ? _self.fileExt : fileExt // ignore: cast_nullable_to_non_nullable
as String?,furl: freezed == furl ? _self.furl : furl // ignore: cast_nullable_to_non_nullable
as String?,blockMap: null == blockMap ? _self._blockMap : blockMap // ignore: cast_nullable_to_non_nullable
as Map<String, BlockInfo>,createDate: freezed == createDate ? _self.createDate : createDate // ignore: cast_nullable_to_non_nullable
as int?,lastModifyDate: freezed == lastModifyDate ? _self.lastModifyDate : lastModifyDate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
