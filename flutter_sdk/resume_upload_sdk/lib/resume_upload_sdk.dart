/// A Flutter SDK for resumable file uploads with chunk-based upload support.
///
/// This SDK provides automatic resume capability when uploads are interrupted
/// due to network issues or other reasons.
///
/// Supports iOS, macOS, Android, Windows and Linux. [UploadTaskWeb] uploads
/// in-memory bytes instead of a file path.
library resume_upload_sdk;

export 'src/models/upload_config.dart';
export 'src/models/upload_status.dart';
export 'src/models/upload_progress.dart';
export 'src/models/upload_result.dart';
export 'src/models/block_info.dart';
export 'src/services/upload_manager.dart';
export 'src/services/upload_task.dart';
export 'src/services/upload_task_web.dart' show UploadTaskWeb;
export 'src/utils/file_utils.dart' hide BlockSize;
export 'src/utils/file_utils_web.dart' show FileUtilsWeb;
export 'src/utils/crc32.dart';
export 'src/utils/debug_logger.dart';
