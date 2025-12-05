import 'upload_status.dart';

/// Information about a file block.
class BlockInfo {
  /// Block index (0-based).
  final int index;

  /// CRC32 checksum of the block.
  final int crc;

  /// Block status.
  final BlockStatus status;

  /// Range of data uploaded (for partial uploads).
  final String? range;

  /// Size of this block in bytes.
  final int size;

  const BlockInfo({
    required this.index,
    required this.crc,
    required this.status,
    this.range,
    required this.size,
  });

  /// Creates from JSON map.
  factory BlockInfo.fromJson(Map<String, dynamic> json) => BlockInfo(
    index: json['index'] as int,
    crc: json['crc'] is String
        ? int.parse(json['crc'] as String)
        : json['crc'] as int,
    status: BlockStatus.fromValue(json['status'] as int),
    range: json['range'] as String?,
    size: _parseSizeFromRange(json['range'] as String?),
  );

  static int _parseSizeFromRange(String? range) {
    if (range == null) return 0;
    final parts = range.split('-');
    if (parts.length == 2) return int.tryParse(parts[1]) ?? 0;
    return 0;
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'index': index,
    'crc': crc,
    'status': status.value,
    'range': range,
  };

  @override
  String toString() =>
      'BlockInfo(index: $index, crc: $crc, status: $status, range: $range)';
}

/// File information response from server.
class FileInfoResponse {
  /// File unique identifier.
  final String fid;

  /// File status.
  final FileStatus fstatus;

  /// File name.
  final String? fileName;

  /// File size in bytes.
  final int fileSize;

  /// Block size used.
  final int blockSize;

  /// Total block count.
  final int blockCount;

  /// File CRC.
  final int fcrc;

  /// File extension.
  final String? fileExt;

  /// File URL (if completed).
  final String? furl;

  /// Map of uploaded blocks.
  final Map<String, BlockInfo> blockMap;

  /// File creation date timestamp.
  final int? createDate;

  /// File last modified date timestamp.
  final int? lastModifyDate;

  const FileInfoResponse({
    required this.fid,
    required this.fstatus,
    this.fileName,
    required this.fileSize,
    required this.blockSize,
    required this.blockCount,
    required this.fcrc,
    this.fileExt,
    this.furl,
    required this.blockMap,
    this.createDate,
    this.lastModifyDate,
  });

  /// Creates from JSON map.
  factory FileInfoResponse.fromJson(Map<String, dynamic> json) {
    final blockMapJson = json['blockMap'] as Map<String, dynamic>? ?? {};
    final blockMap = <String, BlockInfo>{};

    blockMapJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        blockMap[key] = BlockInfo.fromJson(value);
      }
    });

    return FileInfoResponse(
      fid: json['fid'] as String,
      fstatus: FileStatus.fromValue(json['fstatus'] as int),
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int,
      blockSize: json['blockSize'] as int,
      blockCount: json['blockCount'] as int,
      fcrc: json['fcrc'] is String
          ? int.parse(json['fcrc'] as String)
          : json['fcrc'] as int,
      fileExt: json['fileExt'] as String?,
      furl: json['furl'] as String?,
      blockMap: blockMap,
      createDate: json['createDate'] as int?,
      lastModifyDate: json['lastModifyDate'] as int?,
    );
  }

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
