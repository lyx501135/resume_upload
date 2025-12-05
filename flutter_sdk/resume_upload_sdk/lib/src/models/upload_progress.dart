import 'upload_status.dart';

/// Progress information for an upload.
class UploadProgress {
  /// The unique file identifier.
  final String fileId;

  /// The file name.
  final String fileName;

  /// Total size of the file in bytes.
  final int totalBytes;

  /// Number of bytes uploaded so far.
  final int uploadedBytes;

  /// Upload progress as a fraction (0.0 to 1.0).
  final double progress;

  /// Upload speed in bytes per second.
  final double speed;

  /// Current block index being uploaded.
  final int currentBlockIndex;

  /// Total number of blocks.
  final int totalBlocks;

  /// Current upload status.
  final UploadStatus status;

  /// Error message if any.
  final String? errorMessage;

  const UploadProgress({
    required this.fileId,
    required this.fileName,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.progress,
    required this.speed,
    required this.currentBlockIndex,
    required this.totalBlocks,
    required this.status,
    this.errorMessage,
  });

  /// Creates a copy with modified fields.
  UploadProgress copyWith({
    String? fileId,
    String? fileName,
    int? totalBytes,
    int? uploadedBytes,
    double? progress,
    double? speed,
    int? currentBlockIndex,
    int? totalBlocks,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return UploadProgress(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      currentBlockIndex: currentBlockIndex ?? this.currentBlockIndex,
      totalBlocks: totalBlocks ?? this.totalBlocks,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Returns the upload progress as a percentage string.
  String get progressPercentage => '${(progress * 100).toStringAsFixed(1)}%';

  /// Returns a human-readable speed string.
  String get speedString {
    if (speed < 1024) {
      return '${speed.toStringAsFixed(0)} B/s';
    } else if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  @override
  String toString() =>
      'UploadProgress(fileId: $fileId, progress: $progressPercentage, speed: $speedString, status: $status)';
}
