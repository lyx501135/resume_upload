import 'package:freezed_annotation/freezed_annotation.dart';

import 'upload_status.dart';

part 'block_info.freezed.dart';
part 'block_info.g.dart';

/// Information about a file block.
@freezed
abstract class BlockInfo with _$BlockInfo {
  const BlockInfo._();

  const factory BlockInfo({
    /// Block index (0-based).
    required int index,

    /// CRC32 checksum of the block.
    @JsonKey(fromJson: _intFromJson) required int crc,

    /// Block status.
    @JsonKey(fromJson: _blockStatusFromJson, toJson: _blockStatusToJson)
    required BlockStatus status,

    /// Range of data uploaded (for partial uploads).
    String? range,

    /// Size of this block in bytes. Read from [range] when parsing JSON, and
    /// not written to JSON.
    @JsonKey(readValue: _sizeFromRange, includeToJson: false)
    @Default(0)
    int size,
  }) = _BlockInfo;

  /// Creates from JSON map.
  factory BlockInfo.fromJson(Map<String, dynamic> json) =>
      _$BlockInfoFromJson(json);

  @override
  String toString() =>
      'BlockInfo(index: $index, crc: $crc, status: $status, range: $range)';
}

/// File information response from server.
@freezed
abstract class FileInfoResponse with _$FileInfoResponse {
  const FileInfoResponse._();

  const factory FileInfoResponse({
    /// File unique identifier.
    required String fid,

    /// File status.
    @JsonKey(fromJson: _fileStatusFromJson, toJson: _fileStatusToJson)
    required FileStatus fstatus,

    /// File name.
    String? fileName,

    /// File size in bytes.
    required int fileSize,

    /// Block size used.
    required int blockSize,

    /// Total block count.
    required int blockCount,

    /// File CRC.
    @JsonKey(fromJson: _intFromJson) required int fcrc,

    /// File extension.
    String? fileExt,

    /// File URL (if completed).
    String? furl,

    /// Map of uploaded blocks.
    @JsonKey(fromJson: _blockMapFromJson, toJson: _blockMapToJson)
    required Map<String, BlockInfo> blockMap,

    /// File creation date timestamp.
    int? createDate,

    /// File last modified date timestamp.
    int? lastModifyDate,
  }) = _FileInfoResponse;

  /// Creates from JSON map.
  factory FileInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$FileInfoResponseFromJson(json);

  /// Gets the next block index to upload.
  int getNextBlockIndex() {
    if (blockMap.isEmpty) return 0;

    final uploadedIndices = blockMap.values
        .where((b) => b.status == BlockStatus.uploaded)
        .map((b) => b.index)
        .toSet();

    for (int i = 0; i < blockCount; i++) {
      if (!uploadedIndices.contains(i)) {
        return i;
      }
    }

    return blockCount;
  }

  /// Gets the count of uploaded blocks.
  int getUploadedBlockCount() =>
      blockMap.values.where((b) => b.status == BlockStatus.uploaded).length;

  @override
  String toString() =>
      'FileInfoResponse(fid: $fid, fstatus: $fstatus, uploadedBlocks: ${getUploadedBlockCount()}/$blockCount)';
}

// The size is the second half of "start-end" in range, or 0 if there is none.
Object? _sizeFromRange(Map<dynamic, dynamic> json, String key) {
  final range = json['range'] as String?;
  if (range == null) return 0;
  final parts = range.split('-');
  if (parts.length == 2) return int.tryParse(parts[1]) ?? 0;
  return 0;
}

// The server sends some numbers as strings and some as numbers.
int _intFromJson(Object? value) =>
    value is String ? int.parse(value) : value as int;

// Unknown values map to the enum's default, as fromValue always did.
BlockStatus _blockStatusFromJson(Object? value) =>
    BlockStatus.fromValue(value as int);

int _blockStatusToJson(BlockStatus status) => status.value;

FileStatus _fileStatusFromJson(Object? value) =>
    FileStatus.fromValue(value as int);

int _fileStatusToJson(FileStatus status) => status.value;

// A missing or null blockMap is empty, and entries that are not objects are skipped.
Map<String, BlockInfo> _blockMapFromJson(Object? value) {
  final blockMapJson = value as Map<String, dynamic>? ?? {};
  final blockMap = <String, BlockInfo>{};

  blockMapJson.forEach((key, entry) {
    if (entry is Map<String, dynamic>) {
      blockMap[key] = BlockInfo.fromJson(entry);
    }
  });

  return blockMap;
}

Map<String, dynamic> _blockMapToJson(Map<String, BlockInfo> blockMap) => {
  for (final entry in blockMap.entries) entry.key: entry.value.toJson(),
};
