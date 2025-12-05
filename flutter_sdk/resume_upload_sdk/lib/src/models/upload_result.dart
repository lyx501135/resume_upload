/// Result of a completed upload.
class UploadResult {
  /// Whether the upload was successful.
  final bool success;

  /// The unique file identifier.
  final String fileId;

  /// The URL where the file can be accessed.
  final String? fileUrl;

  /// The server-assigned file ID.
  final int? serverId;

  /// Error message if the upload failed.
  final String? errorMessage;

  /// Additional metadata from the server.
  final Map<String, dynamic>? metadata;

  const UploadResult({
    required this.success,
    required this.fileId,
    this.fileUrl,
    this.serverId,
    this.errorMessage,
    this.metadata,
  });

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
