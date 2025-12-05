import 'dart:typed_data';
import 'package:crypto/crypto.dart';
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

/// Web-specific file utilities.
///
/// On web, file operations work with bytes directly since we don't have
/// filesystem access. Files are read through the browser's file picker.
class FileUtilsWeb {
  static const _uuid = Uuid();

  /// Gets device ID or generates a unique ID.
  static String getDeviceId() => _uuid.v4();

  /// Gets the file size in bytes from data.
  static int getFileSize(Uint8List data) => data.length;

  /// Gets the file extension from filename.
  static String getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Gets the file name.
  static String getFileName(String path) {
    final parts = path.split('/');
    return parts.last;
  }

  /// Gets current timestamp.
  static int getCurrentTimestamp() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Calculates the block size for given file size using tiered approach.
  ///
  /// | File Size     | Block Size |
  /// |---------------|------------|
  /// | < 10MB        | 2MB        |
  /// | 10MB - 100MB  | 4MB        |
  /// | 100MB - 1GB   | 8MB        |
  /// | > 1GB         | 16MB       |
  static int getBlockSize(int fileSize) =>
      BlockSize.getBlockSizeForFileSize(fileSize);

  /// Calculates the number of blocks.
  static int getBlockCount(int fileSize) {
    final blockSize = getBlockSize(fileSize);
    return (fileSize / blockSize).ceil();
  }

  /// Calculates CRC32 for the data.
  static int calculateCrc(Uint8List data) => Crc32.calculate(data);

  /// Generates the file ID using MD5(deviceId + fileCrc).
  static String generateFileId(Uint8List data, String deviceId) {
    final fileCrc = calculateCrc(data);
    final combined = '$deviceId$fileCrc';
    final bytes = combined.codeUnits;
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Reads a specific block from data.
  static Uint8List readBlock(Uint8List data, int blockIndex) {
    final fileSize = data.length;
    final blockSize = getBlockSize(fileSize);
    final blockCount = getBlockCount(fileSize);

    final startOffset = blockIndex * blockSize;
    final isLastBlock = blockIndex == blockCount - 1;

    int endOffset;
    if (isLastBlock) {
      endOffset = fileSize;
    } else {
      endOffset = startOffset + blockSize;
    }

    return data.sublist(startOffset, endOffset);
  }

  /// Calculates CRC32 for a specific block.
  static int getBlockCrc(Uint8List data, int blockIndex) {
    final blockData = readBlock(data, blockIndex);
    return Crc32.calculate(blockData);
  }

  /// Gets the size of a specific block.
  static int getBlockDataSize(Uint8List data, int blockIndex) {
    final fileSize = data.length;
    final blockSize = getBlockSize(fileSize);
    final blockCount = getBlockCount(fileSize);

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
