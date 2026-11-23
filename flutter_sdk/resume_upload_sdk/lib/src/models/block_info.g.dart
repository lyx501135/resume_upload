// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BlockInfo _$BlockInfoFromJson(Map<String, dynamic> json) => _BlockInfo(
  index: (json['index'] as num).toInt(),
  crc: _intFromJson(json['crc']),
  status: _blockStatusFromJson(json['status']),
  range: json['range'] as String?,
  size: (_sizeFromRange(json, 'size') as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BlockInfoToJson(_BlockInfo instance) =>
    <String, dynamic>{
      'index': instance.index,
      'crc': instance.crc,
      'status': _blockStatusToJson(instance.status),
      'range': instance.range,
    };

_FileInfoResponse _$FileInfoResponseFromJson(Map<String, dynamic> json) =>
    _FileInfoResponse(
      fid: json['fid'] as String,
      fstatus: _fileStatusFromJson(json['fstatus']),
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num).toInt(),
      blockSize: (json['blockSize'] as num).toInt(),
      blockCount: (json['blockCount'] as num).toInt(),
      fcrc: _intFromJson(json['fcrc']),
      fileExt: json['fileExt'] as String?,
      furl: json['furl'] as String?,
      blockMap: _blockMapFromJson(json['blockMap']),
      createDate: (json['createDate'] as num?)?.toInt(),
      lastModifyDate: (json['lastModifyDate'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FileInfoResponseToJson(_FileInfoResponse instance) =>
    <String, dynamic>{
      'fid': instance.fid,
      'fstatus': _fileStatusToJson(instance.fstatus),
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'blockSize': instance.blockSize,
      'blockCount': instance.blockCount,
      'fcrc': instance.fcrc,
      'fileExt': instance.fileExt,
      'furl': instance.furl,
      'blockMap': _blockMapToJson(instance.blockMap),
      'createDate': instance.createDate,
      'lastModifyDate': instance.lastModifyDate,
    };
