import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/upload_config.dart';
import '../models/upload_status.dart';
import '../models/upload_progress.dart';
import '../models/upload_result.dart';
import '../models/block_info.dart';
import '../utils/file_utils_web.dart';
import '../utils/debug_logger.dart';

/// Why the block loop stopped.
enum _LoopOutcome { completed, paused, cancelled, failed }

/// Web-specific upload task that works with bytes directly.
class UploadTaskWeb {
  /// Unique task ID.
  final String taskId;

  /// File data as bytes.
  final Uint8List fileData;

  /// File name.
  final String fileName;

  /// Upload configuration.
  final UploadConfig config;

  /// Device ID for file identification.
  final String deviceId;

  /// Stream controller for progress updates.
  final StreamController<UploadProgress> _progressController =
      StreamController<UploadProgress>.broadcast();

  /// Current upload status.
  UploadStatus _status = UploadStatus.notStarted;

  /// File ID generated from device ID and file CRC.
  String? _fileId;

  /// File info from server.
  FileInfoResponse? _fileInfo;

  /// Current block index being uploaded.
  int _currentBlockIndex = 0;

  /// Total bytes uploaded.
  int _totalBytesUploaded = 0;

  /// File size.
  late int _fileSize;

  /// Block size.
  late int _blockSize;

  /// Block count.
  late int _blockCount;

  /// Bytes uploaded in current interval for speed calculation.
  int _bytesInInterval = 0;

  /// Last speed calculation time.
  DateTime _lastSpeedTime = DateTime.now();

  /// Current upload speed.
  double _currentSpeed = 0;

  /// HTTP client.
  final http.Client _httpClient = http.Client();

  /// Whether the upload is paused.
  bool _isPaused = false;

  /// Whether the upload is cancelled.
  bool _isCancelled = false;

  /// Completer for the upload result. start() and resume() return its future,
  /// so it only completes when the upload finishes, fails or is cancelled.
  Completer<UploadResult>? _uploadCompleter;

  /// Whether an upload run (server sync + block loop + finalize) is active.
  bool _runActive = false;

  /// CRC32 of the whole file, computed once.
  int? _fileCrc;

  UploadTaskWeb({
    required this.taskId,
    required this.fileData,
    required this.fileName,
    required this.config,
    required this.deviceId,
  }) {
    _fileSize = fileData.length;
    _blockSize = FileUtilsWeb.getBlockSize(_fileSize);
    _blockCount = FileUtilsWeb.getBlockCount(_fileSize);
    _fileId = FileUtilsWeb.generateFileId(fileData, deviceId);
  }

  /// Gets the progress stream.
  Stream<UploadProgress> get progressStream => _progressController.stream;

  /// Gets the current status.
  UploadStatus get status => _status;

  /// Gets the file ID.
  String? get fileId => _fileId;

  /// Starts the upload.
  ///
  /// The returned future completes when the upload finishes, fails or is
  /// cancelled. Pausing doesn't complete it: call [resume] to continue, and
  /// the same future completes when the upload is done.
  Future<UploadResult> start() async {
    if (_status == UploadStatus.inProgress) {
      return UploadResult.failure(
        fileId: _fileId ?? '',
        errorMessage: 'Upload already in progress',
      );
    }
    if (_status == UploadStatus.paused) return resume();

    final completer = _uploadCompleter = Completer<UploadResult>();
    _isPaused = false;
    _isCancelled = false;
    _status = UploadStatus.inProgress;

    if (_fileSize == 0) {
      _completeWithError('File is empty');
      return completer.future;
    }

    unawaited(_run());
    return completer.future;
  }

  /// Runs the upload until it completes, fails, is cancelled or paused.
  Future<void> _run() async {
    if (_runActive) return; // The active run picks up the new state.
    _runActive = true;
    try {
      // Get file info from server
      final fileInfoResult = await _getFileInfoFromServer();
      if (!fileInfoResult) {
        if (!_isCancelled) {
          _completeWithError('Failed to get file info from server');
        }
        return;
      }

      // Check file status
      if (_fileInfo!.fstatus == FileStatus.completed) {
        await _finalizeUpload();
        return;
      }

      // Upload blocks
      switch (await _uploadBlocks()) {
        case _LoopOutcome.cancelled:
        case _LoopOutcome.paused:
          return; // cancel() completed the result / resume() continues
        case _LoopOutcome.failed:
          _completeWithError('Failed to upload blocks');
          return;
        case _LoopOutcome.completed:
          break;
      }

      // Finalize upload
      await _finalizeUpload();
    } catch (e) {
      _completeWithError(e.toString());
    } finally {
      _runActive = false;
      // resume() was called after the loop saw the pause but before this run
      // ended: continue now.
      if (_status == UploadStatus.inProgress &&
          !_isPaused &&
          !_isCancelled &&
          !(_uploadCompleter?.isCompleted ?? true)) {
        unawaited(_run());
      }
    }
  }

  /// Pauses the upload. The in-flight block finishes first.
  void pause() {
    if (_status != UploadStatus.inProgress) return;
    _isPaused = true;
    _status = UploadStatus.paused;
    _emitProgress();
  }

  /// Resumes a paused upload.
  ///
  /// Returns the same future as [start], which completes when the upload
  /// finishes, fails or is cancelled.
  Future<UploadResult> resume() async {
    final completer = _uploadCompleter;
    if (_status != UploadStatus.paused || completer == null) {
      return UploadResult.failure(
        fileId: _fileId ?? '',
        errorMessage: 'Upload is not paused',
      );
    }

    _isPaused = false;
    _status = UploadStatus.inProgress;
    _emitProgress();

    unawaited(_run());
    return completer.future;
  }

  /// Cancels the upload.
  void cancel() {
    if (_uploadCompleter?.isCompleted ?? false) return; // already finished
    _isCancelled = true;
    _status = UploadStatus.cancelled;
    _emitProgress();
    _complete(
      UploadResult.failure(
        fileId: _fileId ?? '',
        errorMessage: 'Upload cancelled',
      ),
    );
  }

  /// Completes the upload result once.
  void _complete(UploadResult result) {
    final completer = _uploadCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  /// Gets file info from server.
  Future<bool> _getFileInfoFromServer() async {
    try {
      final fileCrc = _fileCrc ??= FileUtilsWeb.calculateCrc(fileData);
      final timestamp = FileUtilsWeb.getCurrentTimestamp();
      final fileExt = FileUtilsWeb.getFileExtension(fileName);

      final queryParams = {
        'fid': _fileId!,
        'fcrc': fileCrc.toString(),
        'fileSize': _fileSize.toString(),
        'createDate': timestamp.toString(),
        'lastModifyDate': timestamp.toString(),
        'fileExt': fileExt,
        'blockCount': _blockCount.toString(),
        'blockSize': _blockSize.toString(),
      };

      final uri = Uri.parse(
        '${config.baseUrl}/api/v1/large_file/upload_file',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/octet-stream',
              ...?config.headers,
            },
          )
          .timeout(Duration(seconds: config.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['rtnCode'] == '0000000' || json['rtnCode'] == 0) {
          _fileInfo = FileInfoResponse.fromJson(
            json['bizData'] as Map<String, dynamic>,
          );
          _currentBlockIndex = _fileInfo!.getNextBlockIndex();
          _totalBytesUploaded = _uploadedBytes();
          return true;
        }
      }
      return false;
    } catch (e) {
      DebugLogger.error('Error getting file info: $e');
      return false;
    }
  }

  /// Uploads all remaining blocks, skipping the ones the server already has.
  Future<_LoopOutcome> _uploadBlocks() async {
    while (_currentBlockIndex < _blockCount) {
      if (_isCancelled) return _LoopOutcome.cancelled;
      if (_isPaused) return _LoopOutcome.paused;

      if (_isBlockUploaded(_currentBlockIndex)) {
        _currentBlockIndex++;
        continue;
      }

      var success = await _uploadBlock(_currentBlockIndex);
      var retries = 0;
      while (!success && retries < config.maxRetries) {
        await Future<void>.delayed(Duration(milliseconds: config.retryDelayMs));
        if (_isCancelled) return _LoopOutcome.cancelled;
        if (_isPaused) return _LoopOutcome.paused;
        retries++;
        success = await _uploadBlock(_currentBlockIndex);
      }

      if (!success) {
        if (_isCancelled) return _LoopOutcome.cancelled;
        if (_isPaused) return _LoopOutcome.paused;
        _status = UploadStatus.failed;
        _emitProgress(errorMessage: 'Max retries exceeded');
        return _LoopOutcome.failed;
      }

      _currentBlockIndex++;
    }

    return _LoopOutcome.completed;
  }

  /// Whether the server reports block [index] as uploaded.
  bool _isBlockUploaded(int index) =>
      _fileInfo?.blockMap['$index']?.status == BlockStatus.uploaded;

  /// Bytes of the blocks the server reports as uploaded.
  int _uploadedBytes() {
    final info = _fileInfo;
    if (info == null) return 0;
    var total = 0;
    for (final block in info.blockMap.values) {
      if (block.status == BlockStatus.uploaded &&
          block.index >= 0 &&
          block.index < _blockCount) {
        total += FileUtilsWeb.getBlockDataSize(fileData, block.index);
      }
    }
    return total;
  }

  /// Uploads a single block.
  Future<bool> _uploadBlock(int blockIndex) async {
    try {
      final blockData = FileUtilsWeb.readBlock(fileData, blockIndex);
      final blockCrc = FileUtilsWeb.getBlockCrc(fileData, blockIndex);
      final blockDataSize = FileUtilsWeb.getBlockDataSize(fileData, blockIndex);

      final queryParams = {
        'fid': _fileId!,
        'index': blockIndex.toString(),
        'range': '0-$blockDataSize',
        'crc': blockCrc.toString(),
      };

      final uri = Uri.parse(
        '${config.baseUrl}/api/v1/large_file/upload_block',
      ).replace(queryParameters: queryParams);

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/octet-stream';
      if (config.headers != null) request.headers.addAll(config.headers!);
      request.bodyBytes = blockData;

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(Duration(seconds: config.timeoutSeconds * 2));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['rtnCode'] == '0000000' || json['rtnCode'] == 0) {
          _fileInfo = FileInfoResponse.fromJson(
            json['bizData'] as Map<String, dynamic>,
          );
          _totalBytesUploaded = _uploadedBytes();
          _updateSpeedAndProgress(blockDataSize);
          return true;
        }
      }

      return false;
    } catch (e) {
      DebugLogger.error('Error uploading block $blockIndex: $e');
      return false;
    }
  }

  /// Finalizes the upload.
  Future<UploadResult> _finalizeUpload() async {
    try {
      final queryParams = <String, String>{
        'fid': _fileId!,
        'dirId': config.dirId ?? '0',
        'isRandomName': config.isRandomName.toString(),
      };

      if (config.userId != null) queryParams['userId'] = config.userId!;
      if (config.productCode != null) {
        queryParams['productCode'] = config.productCode!;
      }
      if (config.bizSystem != null) {
        queryParams['bizSystem'] = config.bizSystem!;
      }

      final uri = Uri.parse(
        '${config.baseUrl}/api/v1/uploadFileForLargeFile',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/octet-stream',
              ...?config.headers,
            },
          )
          .timeout(Duration(seconds: config.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['rtnCode'] == '0000000' || json['rtnCode'] == 0) {
          final bizData = json['bizData'] as Map<String, dynamic>;
          final fileData = bizData['file'] as Map<String, dynamic>;

          _status = UploadStatus.completed;
          _emitProgress();

          final result = UploadResult.success(
            fileId: _fileId!,
            fileUrl: fileData['fileUrl'] as String,
            serverId: fileData['id'] as int?,
            metadata: fileData,
          );

          _complete(result);
          return result;
        }
      }

      return _completeWithError('Failed to finalize upload');
    } catch (e) {
      return _completeWithError(e.toString());
    }
  }

  /// Updates speed calculation and emits progress.
  void _updateSpeedAndProgress(int bytesUploaded) {
    _bytesInInterval += bytesUploaded;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastSpeedTime).inMilliseconds;

    if (timeDiff >= 1000) {
      _currentSpeed = (_bytesInInterval / timeDiff) * 1000;
      _bytesInInterval = 0;
      _lastSpeedTime = now;
    }

    _emitProgress();
  }

  /// Emits current progress.
  void _emitProgress({String? errorMessage}) {
    if (_progressController.isClosed) return;
    final progress = _fileSize > 0
        ? (_totalBytesUploaded / _fileSize).clamp(0.0, 1.0)
        : 0.0;

    _progressController.add(
      UploadProgress(
        fileId: _fileId ?? '',
        fileName: fileName,
        totalBytes: _fileSize,
        uploadedBytes: _totalBytesUploaded,
        progress: progress,
        speed: _currentSpeed,
        currentBlockIndex: _currentBlockIndex,
        totalBlocks: _blockCount,
        status: _status,
        errorMessage: errorMessage,
      ),
    );
  }

  /// Completes with error.
  UploadResult _completeWithError(String message) {
    final result = UploadResult.failure(
      fileId: _fileId ?? '',
      errorMessage: message,
    );
    // Already finished (e.g. cancelled): keep that status and result.
    if (_uploadCompleter?.isCompleted ?? false) return result;

    _status = UploadStatus.failed;
    _emitProgress(errorMessage: message);
    _complete(result);
    return result;
  }

  /// Disposes resources.
  void dispose() {
    // Stop a running upload and resolve anyone still waiting on start()/resume().
    _isCancelled = true;
    _complete(
      UploadResult.failure(
        fileId: _fileId ?? '',
        errorMessage: 'Upload task disposed',
      ),
    );
    _progressController.close();
    _httpClient.close();
  }
}
