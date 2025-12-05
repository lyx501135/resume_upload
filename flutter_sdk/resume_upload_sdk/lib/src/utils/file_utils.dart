import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'crc32.dart';

/// Block size constants with tiered approach based on file size.
///
/// Tier system optimizes for different scenarios:
/// - Tiny files: Smaller blocks for quick uploads
/// - Small files: Balanced block size
/// - Medium files: Standard block size
/// - Large files: Larger blocks to reduce HTTP overhead
class BlockSize {
  /// Tiny block size (2MB) for very small files.
  static const int tiny = 2 * 1024 * 1024;

  /// Small block size (4MB) for small files.
  static const int small = 4 * 1024 * 1024;

  /// Medium block size (8MB) for medium files.
  static const int medium = 8 * 1024 * 1024;

  /// Large block size (16MB) for large files.
  static const int large = 16 * 1024 * 1024;

  /// Threshold for tiny blocks: files under 10MB use 2MB blocks.
  static const int tinyThreshold = 10 * 1024 * 1024; // 10MB

  /// Threshold for small blocks: files 10MB-100MB use 4MB blocks.
  static const int smallThreshold = 100 * 1024 * 1024; // 100MB

  /// Threshold for medium blocks: files 100MB-1GB use 8MB blocks.
  static const int mediumThreshold = 1024 * 1024 * 1024; // 1GB

  /// Files over 1GB use 16MB blocks for efficiency.

  /// Gets the appropriate block size for a given file size.
  static int getBlockSizeForFileSize(int fileSize) {
    if (fileSize < tinyThreshold) {
      return tiny; // 2MB for files < 10MB
    } else if (fileSize < smallThreshold) {
      return small; // 4MB for files 10MB - 100MB
    } else if (fileSize < mediumThreshold) {
      return medium; // 8MB for files 100MB - 1GB
    } else {
      return large; // 16MB for files > 1GB
    }
  }
}

/// Utility class for file operations.
class FileUtils {
  static const _uuid = Uuid();

  /// Gets device ID or generates a unique ID.
  static String getDeviceId() {
    // In production, use device_info_plus to get actual device ID
    // For now, generate a consistent UUID based on platform
    return _uuid.v4();
  }

  /// Gets the file size in bytes.
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Gets the file extension.
  static String getFileExtension(String filePath) =>
      path.extension(filePath).replaceFirst('.', '');

  /// Gets the file name.
  static String getFileName(String filePath) => path.basename(filePath);

  /// Gets the file creation time as Unix timestamp.
  static Future<int> getFileCreateDate(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final stat = await file.stat();
      return stat.changed.millisecondsSinceEpoch ~/ 1000;
    }
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// Gets the file modification time as Unix timestamp.
  static Future<int> getFileModifyDate(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final stat = await file.stat();
      return stat.modified.millisecondsSinceEpoch ~/ 1000;
    }
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// Calculates the block size for a file using tiered approach.
  ///
  /// | File Size     | Block Size |
  /// |---------------|------------|
  /// | < 10MB        | 2MB        |
  /// | 10MB - 100MB  | 4MB        |
  /// | 100MB - 1GB   | 8MB        |
  /// | > 1GB         | 16MB       |
  static Future<int> getBlockSize(String filePath) async {
    final fileSize = await getFileSize(filePath);
    return BlockSize.getBlockSizeForFileSize(fileSize);
  }

  /// Calculates the number of blocks for a file.
  static Future<int> getBlockCount(String filePath) async {
    final fileSize = await getFileSize(filePath);
    final blockSize = await getBlockSize(filePath);
    return (fileSize / blockSize).ceil();
  }

  /// Calculates CRC32 for the entire file.
  static Future<int> getFileCrc(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;

    var crc = 0xFFFFFFFF;
    final stream = file.openRead();

    await for (final chunk in stream) {
      for (final byte in chunk) {
        crc = (crc >> 8) ^ Crc32.table[(crc ^ byte) & 0xFF];
      }
    }

    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  /// Generates the file ID using MD5(deviceId + fileCrc).
  static Future<String> generateFileId(
    String filePath,
    String deviceId,
  ) async => fileIdFromCrc(deviceId, await getFileCrc(filePath));

  /// The file ID for a file whose CRC32 is already known: MD5(deviceId + fileCrc).
  static String fileIdFromCrc(String deviceId, int fileCrc) =>
      md5.convert('$deviceId$fileCrc'.codeUnits).toString();

  /// Reads a specific block from a file.
  static Future<Uint8List> readBlock(String filePath, int blockIndex) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final blockSize = await getBlockSize(filePath);
    final blockCount = await getBlockCount(filePath);

    final startOffset = blockIndex * blockSize;
    final isLastBlock = blockIndex == blockCount - 1;

    int length;
    if (isLastBlock) {
      length = fileSize - startOffset;
    } else {
      length = blockSize;
    }

    final raf = await file.open();
    try {
      await raf.setPosition(startOffset);
      return await raf.read(length);
    } finally {
      await raf.close();
    }
  }

  /// Reads a partial block from a file (for resume).
  static Future<Uint8List> readBlockRange(
    String filePath,
    int blockIndex,
    int fromOffset,
  ) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final blockSize = await getBlockSize(filePath);
    final blockCount = await getBlockCount(filePath);

    final blockStartOffset = blockIndex * blockSize;
    final absoluteOffset = blockStartOffset + fromOffset;

    final isLastBlock = blockIndex == blockCount - 1;
    int length;
    if (isLastBlock) {
      length = fileSize - absoluteOffset;
    } else {
      length = blockSize - fromOffset;
    }

    final raf = await file.open();
    try {
      await raf.setPosition(absoluteOffset);
      return await raf.read(length);
    } finally {
      await raf.close();
    }
  }

  /// Calculates CRC32 for a specific block.
  static Future<int> getBlockCrc(String filePath, int blockIndex) async {
    final blockData = await readBlock(filePath, blockIndex);
    return Crc32.calculate(blockData);
  }

  /// Gets the size of a specific block.
  static Future<int> getBlockDataSize(String filePath, int blockIndex) async {
    final fileSize = await getFileSize(filePath);
    final blockSize = await getBlockSize(filePath);
    final blockCount = await getBlockCount(filePath);

    if (blockIndex == blockCount - 1) {
      return fileSize - (blockIndex * blockSize);
    }
    return blockSize;
  }

  /// Formats byte size to human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
