import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_config.freezed.dart';

/// Configuration for the upload SDK.
@freezed
abstract class UploadConfig with _$UploadConfig {
  const UploadConfig._();

  const factory UploadConfig({
    /// Base URL for the upload server.
    required String baseUrl,

    /// Timeout for HTTP requests in seconds.
    @Default(30) int timeoutSeconds,

    /// Maximum number of retry attempts for failed uploads.
    @Default(3) int maxRetries,

    /// Delay between retries in milliseconds.
    @Default(1000) int retryDelayMs,

    /// Custom headers to include in requests.
    Map<String, String>? headers,

    /// User ID for the upload (optional).
    String? userId,

    /// Product code (optional).
    String? productCode,

    /// Business system identifier (optional).
    String? bizSystem,

    /// Directory ID for storage (optional).
    String? dirId,

    /// Whether to use random file names.
    @Default(false) bool isRandomName,
  }) = _UploadConfig;
}
