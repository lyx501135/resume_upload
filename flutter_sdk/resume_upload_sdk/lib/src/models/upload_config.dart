/// Configuration for the upload SDK.
class UploadConfig {
  /// Base URL for the upload server.
  final String baseUrl;

  /// Timeout for HTTP requests in seconds.
  final int timeoutSeconds;

  /// Maximum number of retry attempts for failed uploads.
  final int maxRetries;

  /// Delay between retries in milliseconds.
  final int retryDelayMs;

  /// Custom headers to include in requests.
  final Map<String, String>? headers;

  /// User ID for the upload (optional).
  final String? userId;

  /// Product code (optional).
  final String? productCode;

  /// Business system identifier (optional).
  final String? bizSystem;

  /// Directory ID for storage (optional).
  final String? dirId;

  /// Whether to use random file names.
  final bool isRandomName;

  const UploadConfig({
    required this.baseUrl,
    this.timeoutSeconds = 30,
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
    this.headers,
    this.userId,
    this.productCode,
    this.bizSystem,
    this.dirId,
    this.isRandomName = false,
  });

  /// Creates a copy with modified fields.
  UploadConfig copyWith({
    String? baseUrl,
    int? timeoutSeconds,
    int? maxRetries,
    int? retryDelayMs,
    Map<String, String>? headers,
    String? userId,
    String? productCode,
    String? bizSystem,
    String? dirId,
    bool? isRandomName,
  }) {
    return UploadConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelayMs: retryDelayMs ?? this.retryDelayMs,
      headers: headers ?? this.headers,
      userId: userId ?? this.userId,
      productCode: productCode ?? this.productCode,
      bizSystem: bizSystem ?? this.bizSystem,
      dirId: dirId ?? this.dirId,
      isRandomName: isRandomName ?? this.isRandomName,
    );
  }
}
