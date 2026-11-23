import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_result.freezed.dart';

/// Result of a completed upload.
@freezed
abstract class UploadResult with _$UploadResult {
  const UploadResult._();

  const factory UploadResult({
    /// Whether the upload was successful.
    required bool success,

    /// The unique file identifier.
    required String fileId,

    /// The URL where the file can be accessed.
    String? fileUrl,

    /// The server-assigned file ID.
    int? serverId,

    /// Error message if the upload failed.
    String? errorMessage,

    /// Additional metadata from the server.
    Map<String, dynamic>? metadata,
  }) = _UploadResult;

  /// Creates a successful result.
  factory UploadResult.success({
    required String fileId,
    required String fileUrl,
    int? serverId,
    Map<String, dynamic>? metadata,
  }) {
    return UploadResult(
      success: true,
      fileId: fileId,
      fileUrl: fileUrl,
      serverId: serverId,
      metadata: metadata,
    );
  }

  /// Creates a failed result.
  factory UploadResult.failure({
    required String fileId,
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return UploadResult(
      success: false,
      fileId: fileId,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }

  @override
  String toString() =>
      'UploadResult(success: $success, fileId: $fileId, fileUrl: $fileUrl, error: $errorMessage)';
}
