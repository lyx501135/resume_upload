import 'package:freezed_annotation/freezed_annotation.dart';

import 'upload_status.dart';

part 'upload_progress.freezed.dart';

/// Progress information for an upload.
@freezed
abstract class UploadProgress with _$UploadProgress {
  const UploadProgress._();

  const factory UploadProgress({
    /// The unique file identifier.
    required String fileId,

    /// The file name.
    required String fileName,

    /// Total size of the file in bytes.
    required int totalBytes,

    /// Number of bytes uploaded so far.
    required int uploadedBytes,

    /// Upload progress as a fraction (0.0 to 1.0).
    required double progress,

    /// Upload speed in bytes per second.
    required double speed,

    /// Current block index being uploaded.
    required int currentBlockIndex,

    /// Total number of blocks.
    required int totalBlocks,

    /// Current upload status.
    required UploadStatus status,

    /// Error message if any.
    String? errorMessage,
  }) = _UploadProgress;

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
