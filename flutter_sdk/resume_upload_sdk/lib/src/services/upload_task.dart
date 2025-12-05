import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/upload_config.dart';
import '../models/upload_status.dart';
import '../models/upload_progress.dart';
import '../models/upload_result.dart';
import '../models/block_info.dart';
import '../utils/file_utils.dart';
import '../utils/crc32.dart';
import '../utils/debug_logger.dart';

/// Memory info for monitoring.
class MemoryInfo {
  final int usedMemoryMB;
  final int rssMemoryMB;
  final int peakMemoryMB;
  final DateTime timestamp;

  MemoryInfo({
    required this.usedMemoryMB,
    required this.rssMemoryMB,
    required this.peakMemoryMB,
    required this.timestamp,
  });

  /// Creates a visual memory bar.
  /// Example: [████████░░░░░░░░] 45MB/120MB
  String toVisualBar({int barWidth = 20, int maxMemoryMB = 200}) {
    final percentage = (usedMemoryMB / maxMemoryMB).clamp(0.0, 1.0);
    final filledCount = (percentage * barWidth).round();
    final emptyCount = barWidth - filledCount;

    final filled = '█' * filledCount;
    final empty = '░' * emptyCount;

    return '[$filled$empty] ${usedMemoryMB}MB';
  }

  /// Creates a compact visual representation.
  String toCompactVisual() {
    // Create a small spark line representation
    final percentage = ((usedMemoryMB / 200) * 100).round().clamp(0, 100);
    String indicator;
    if (percentage < 25) {
      indicator = '▁';
    } else if (percentage < 50) {
      indicator = '▃';
    } else if (percentage < 75) {
      indicator = '▅';
    } else {
      indicator = '▇';
    }
    return '$indicator${usedMemoryMB}MB';
  }

  @override
  String toString() =>
      'Memory[Used: ${usedMemoryMB}MB, RSS: ${rssMemoryMB}MB, Peak: ${peakMemoryMB}MB]';
}

/// Memory trend indicator.
enum MemoryTrend {
  /// Memory is increasing (potential concern if sustained).
  rising,

  /// Memory is stable (healthy).
  stable,

  /// Memory is decreasing (healthy, GC working).
  falling,

  /// Not enough data to determine trend.
  unknown,
}

/// Memory snapshot with comprehensive metrics for external monitoring.
///
/// This class provides actionable memory information that developers
/// can use to monitor the SDK's memory behavior during uploads.
class MemorySnapshot {
  /// Current process memory (RSS) in MB.
  final int currentMB;

  /// Peak memory observed during this upload session in MB.
  final int peakMB;

  /// Baseline memory before upload started in MB.
  final int baselineMB;

  /// Current block size being used in MB.
  final int blockSizeMB;

  /// Memory trend based on recent samples.
  final MemoryTrend trend;

  /// Number of blocks completed.
  final int blocksCompleted;

  /// Total blocks to upload.
  final int totalBlocks;

  /// Timestamp of this snapshot.
  final DateTime timestamp;

  /// Recent memory samples for trend analysis (last 10 readings).
  final List<int> recentSamples;

  MemorySnapshot({
    required this.currentMB,
    required this.peakMB,
    required this.baselineMB,
    required this.blockSizeMB,
    required this.trend,
    required this.blocksCompleted,
    required this.totalBlocks,
    required this.timestamp,
    required this.recentSamples,
  });

  /// Memory delta from baseline (can be negative if GC reclaimed memory).
  int get deltaFromBaselineMB => currentMB - baselineMB;

  /// Upload progress as percentage (0-100).
  double get uploadProgress =>
      totalBlocks > 0 ? (blocksCompleted / totalBlocks) * 100 : 0;

  /// Whether memory usage looks healthy (not continuously rising).
  bool get isHealthy =>
      trend != MemoryTrend.rising || deltaFromBaselineMB < blockSizeMB * 3;

  /// Get trend icon for display.
  String get trendIcon {
    switch (trend) {
      case MemoryTrend.rising:
        return '📈';
      case MemoryTrend.stable:
        return '➡️';
      case MemoryTrend.falling:
        return '📉';
      case MemoryTrend.unknown:
        return '❓';
    }
  }

  /// Get trend description.
  String get trendDescription {
    switch (trend) {
      case MemoryTrend.rising:
        return 'Rising';
      case MemoryTrend.stable:
        return 'Stable';
      case MemoryTrend.falling:
        return 'Falling';
      case MemoryTrend.unknown:
        return 'Measuring...';
    }
  }

  /// Get health status icon.
  String get healthIcon => isHealthy ? '✅' : '⚠️';

  /// Get a visual memory bar.
  String toVisualBar({int maxMB = 500}) {
    const barWidth = 20;
    final percentage = (currentMB / maxMB).clamp(0.0, 1.0);
    final filledCount = (percentage * barWidth).round();
    final emptyCount = barWidth - filledCount;

    final filled = '█' * filledCount;
    final empty = '░' * emptyCount;

    return '[$filled$empty] ${currentMB}MB';
  }

  @override
  String toString() {
    return 'MemorySnapshot(current: ${currentMB}MB, peak: ${peakMB}MB, '
        'baseline: ${baselineMB}MB, trend: $trendDescription, '
        'blocks: $blocksCompleted/$totalBlocks)';
  }
}

/// Log entry for upload process.
class UploadLog {
  final DateTime timestamp;
  final String level;
  final String message;
  final MemoryInfo? memoryInfo;
  final double? progressPercent;
  final int? blockIndex;
  final int? totalBlocks;

  UploadLog({
    required this.timestamp,
    required this.level,
    required this.message,
    this.memoryInfo,
    this.progressPercent,
    this.blockIndex,
    this.totalBlocks,
  });

  /// Get level icon
  String get _levelIcon {
    switch (level) {
      case 'INFO':
        return '✓';
      case 'DEBUG':
        return '○';
      case 'ERROR':
        return '✗';
      case 'WARN':
        return '⚠';
      default:
        return '•';
    }
  }

  /// Get level color code for terminal (ANSI)
  String get _levelColor {
    switch (level) {
      case 'INFO':
        return '\x1B[32m'; // Green
      case 'DEBUG':
        return '\x1B[36m'; // Cyan
      case 'ERROR':
        return '\x1B[31m'; // Red
      case 'WARN':
        return '\x1B[33m'; // Yellow
      default:
        return '\x1B[0m'; // Reset
    }
  }

  String get _resetColor => '\x1B[0m';

  @override
  String toString() {
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.write('$_levelColor$_levelIcon$_resetColor ');
    buffer.write('[$time] ');
    buffer.write(message);

    if (memoryInfo != null) {
      buffer.write(
        ' │ ${memoryInfo!.toVisualBar(barWidth: 12, maxMemoryMB: 200)}',
      );
    }

    return buffer.toString();
  }

  /// Plain text version without ANSI colors (for UI display)
  String toPlainString() {
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.write('$_levelIcon ');
    buffer.write('[$time] ');
    buffer.write(message);

    if (memoryInfo != null) {
      buffer.write(
        ' │ ${memoryInfo!.toVisualBar(barWidth: 12, maxMemoryMB: 200)}',
      );
    }

    return buffer.toString();
  }
}

/// Why the block loop stopped.
enum _LoopOutcome { completed, paused, cancelled, failed }

/// Represents a single upload task.
class UploadTask {
  /// Unique task ID.
  final String taskId;

  /// File path to upload.
  final String filePath;

  /// Upload configuration.
  final UploadConfig config;

  /// Device ID for file identification.
  final String deviceId;

  /// Stream controller for progress updates.
  final StreamController<UploadProgress> _progressController =
      StreamController<UploadProgress>.broadcast();

  /// Stream controller for log updates.
  final StreamController<UploadLog> _logController =
      StreamController<UploadLog>.broadcast();

  /// Stream controller for memory snapshots.
  final StreamController<MemorySnapshot> _memoryController =
      StreamController<MemorySnapshot>.broadcast();

  /// List of all logs.
  final List<UploadLog> _logs = [];

  /// Recent memory samples for trend analysis.
  final List<int> _memorySamples = [];

  /// Baseline memory before upload started.
  int _baselineMemoryMB = 0;

  /// Whether to enable verbose logging.
  bool enableLogging = true;

  /// Whether to enable memory monitoring stream.
  bool enableMemoryMonitoring = true;

  /// Peak memory tracking.
  int _peakMemoryMB = 0;

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
  int _fileSize = 0;

  /// Block size.
  int _blockSize = 0;

  /// Block count.
  int _blockCount = 0;

  /// Upload start time for speed calculation.
  DateTime? _uploadStartTime;

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

  /// Whether the upload was paused due to network loss (for auto-resume).
  bool _pausedDueToNetwork = false;

  /// Connectivity subscription for network monitoring.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Whether to enable automatic network monitoring.
  bool enableNetworkMonitoring = true;

  /// Completer for the upload result. start() and resume() return its future,
  /// so it only completes when the upload finishes, fails or is cancelled.
  Completer<UploadResult>? _uploadCompleter;

  /// Whether an upload run (server sync + block loop + finalize) is active.
  bool _runActive = false;

  /// CRC32 of the whole file, computed once per start().
  int? _fileCrc;

  UploadTask({
    required this.taskId,
    required this.filePath,
    required this.config,
    required this.deviceId,
  });

  /// Gets the progress stream.
  Stream<UploadProgress> get progressStream => _progressController.stream;

  /// Gets the log stream.
  Stream<UploadLog> get logStream => _logController.stream;

  /// Gets the memory snapshot stream.
  ///
  /// This stream emits [MemorySnapshot] objects during upload, providing
  /// real-time memory monitoring data including:
  /// - Current process memory usage
  /// - Peak memory during this session
  /// - Memory trend (rising/stable/falling)
  /// - Upload progress context
  ///
  /// Example usage:
  /// ```dart
  /// task.memoryStream.listen((snapshot) {
  ///   print('Memory: ${snapshot.currentMB}MB, Trend: ${snapshot.trendDescription}');
  ///   if (!snapshot.isHealthy) {
  ///     print('Warning: Memory may be accumulating!');
  ///   }
  /// });
  /// ```
  Stream<MemorySnapshot> get memoryStream => _memoryController.stream;

  /// Gets all logs.
  List<UploadLog> get logs => List.unmodifiable(_logs);

  /// Gets the current status.
  UploadStatus get status => _status;

  /// Gets the file ID.
  String? get fileId => _fileId;

  /// Gets current memory info.
  MemoryInfo _getMemoryInfo() {
    final info = ProcessInfo.currentRss;
    final maxRss = ProcessInfo.maxRss;
    final currentMB = (info / (1024 * 1024)).round();

    // Track peak memory
    if (currentMB > _peakMemoryMB) _peakMemoryMB = currentMB;

    return MemoryInfo(
      usedMemoryMB: currentMB,
      rssMemoryMB: (maxRss / (1024 * 1024)).round(),
      peakMemoryMB: _peakMemoryMB,
      timestamp: DateTime.now(),
    );
  }

  /// Calculates memory trend from recent samples.
  MemoryTrend _calculateMemoryTrend() {
    if (_memorySamples.length < 3) return MemoryTrend.unknown;

    // Look at the last 5 samples (or all if less than 5)
    final samplesToAnalyze = _memorySamples.length >= 5
        ? _memorySamples.sublist(_memorySamples.length - 5)
        : _memorySamples;

    // Calculate average change between consecutive samples
    double totalChange = 0;
    for (int i = 1; i < samplesToAnalyze.length; i++) {
      totalChange += samplesToAnalyze[i] - samplesToAnalyze[i - 1];
    }
    final avgChange = totalChange / (samplesToAnalyze.length - 1);

    // Determine trend based on average change
    // Using 2MB threshold to account for normal fluctuation
    if (avgChange > 2) {
      return MemoryTrend.rising;
    } else if (avgChange < -2) {
      return MemoryTrend.falling;
    } else {
      return MemoryTrend.stable;
    }
  }

  /// Emits a memory snapshot to the memory stream.
  void _emitMemorySnapshot() {
    if (!enableMemoryMonitoring || _memoryController.isClosed) return;

    final currentMB = (ProcessInfo.currentRss / (1024 * 1024)).round();

    // Add to samples (keep last 20)
    _memorySamples.add(currentMB);
    if (_memorySamples.length > 20) _memorySamples.removeAt(0);

    // Update peak
    if (currentMB > _peakMemoryMB) _peakMemoryMB = currentMB;

    final snapshot = MemorySnapshot(
      currentMB: currentMB,
      peakMB: _peakMemoryMB,
      baselineMB: _baselineMemoryMB,
      blockSizeMB: (_blockSize / (1024 * 1024)).round(),
      trend: _calculateMemoryTrend(),
      blocksCompleted: _currentBlockIndex,
      totalBlocks: _blockCount,
      timestamp: DateTime.now(),
      recentSamples: List.from(_memorySamples),
    );

    _memoryController.add(snapshot);
  }

  /// Initializes baseline memory measurement.
  void _initializeMemoryBaseline() {
    _baselineMemoryMB = (ProcessInfo.currentRss / (1024 * 1024)).round();
    _peakMemoryMB = _baselineMemoryMB;
    _memorySamples.clear();
    _memorySamples.add(_baselineMemoryMB);
  }

  /// Logs a message with optional memory and progress info.
  void _log(
    String level,
    String message, {
    bool includeMemory = false,
    bool includeProgress = false,
  }) {
    if (!enableLogging) return;

    final memInfo = includeMemory ? _getMemoryInfo() : null;
    final log = UploadLog(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      memoryInfo: memInfo,
      blockIndex: includeProgress ? _currentBlockIndex : null,
      totalBlocks: includeProgress ? _blockCount : null,
    );

    _logs.add(log);
    if (!_logController.isClosed) _logController.add(log);
    DebugLogger.log(log.toString());
  }

  /// Logs info message.
  void _logInfo(
    String message, {
    bool includeMemory = false,
    bool includeProgress = false,
  }) => _log(
    'INFO',
    message,
    includeMemory: includeMemory,
    includeProgress: includeProgress,
  );

  /// Logs debug message.
  void _logDebug(
    String message, {
    bool includeMemory = false,
    bool includeProgress = false,
  }) => _log(
    'DEBUG',
    message,
    includeMemory: includeMemory,
    includeProgress: includeProgress,
  );

  /// Logs error message.
  void _logError(
    String message, {
    bool includeMemory = false,
    bool includeProgress = false,
  }) => _log(
    'ERROR',
    message,
    includeMemory: includeMemory,
    includeProgress: includeProgress,
  );

  /// Logs a block progress summary.
  void _logBlockProgress() {
    if (!enableLogging) return;

    final progress = _blockCount > 0
        ? (_currentBlockIndex / _blockCount * 100).toStringAsFixed(1)
        : '0';
    final uploadedSize = FileUtils.formatBytes(_totalBytesUploaded);
    final totalSize = FileUtils.formatBytes(_fileSize);

    const barWidth = 25;
    final filledCount = _blockCount > 0
        ? ((_currentBlockIndex / _blockCount) * barWidth).round()
        : 0;
    final emptyCount = barWidth - filledCount;

    final progressBar = '▓' * filledCount + '░' * emptyCount;

    DebugLogger.log('');
    DebugLogger.log('  ┌${'─' * 40}┐');
    DebugLogger.log('  │  Upload Progress                      │');
    DebugLogger.log('  ├${'─' * 40}┤');
    DebugLogger.log('${'  │  [$progressBar] $progress%'.padRight(42)}│');
    DebugLogger.log(
      '${'  │  Blocks: $_currentBlockIndex / $_blockCount'.padRight(42)}│',
    );
    DebugLogger.log('${'  │  Size: $uploadedSize / $totalSize'.padRight(42)}│');
    DebugLogger.log(
      '${'  │  Memory: ${_getMemoryInfo().toVisualBar(barWidth: 15, maxMemoryMB: 200)}'.padRight(42)}│',
    );
    DebugLogger.log('  └${'─' * 40}┘');
    DebugLogger.log('');
  }

  /// Starts monitoring network connectivity.
  void _startNetworkMonitoring() {
    if (!enableNetworkMonitoring) return;

    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });
    _logDebug('🌐 Network monitoring started');
  }

  /// Stops network monitoring.
  void _stopNetworkMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Handles connectivity changes.
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (!hasConnection && _status == UploadStatus.inProgress && !_isPaused) {
      // Network lost while uploading - auto-pause
      _pausedDueToNetwork = true;
      _isPaused = true;
      _status = UploadStatus.paused;

      DebugLogger.log('');
      DebugLogger.log(
        '  ╔════════════════════════════════════════════════════╗',
      );
      DebugLogger.log(
        '  ║  ⚠️  NETWORK LOST - Upload Auto-Paused             ║',
      );
      DebugLogger.log(
        '  ║  Upload will automatically resume when connected   ║',
      );
      DebugLogger.log(
        '  ╚════════════════════════════════════════════════════╝',
      );
      DebugLogger.log('');

      _logInfo(
        '⚠️ Network lost - auto-paused at block $_currentBlockIndex/$_blockCount',
        includeMemory: true,
      );

      _emitProgress();
    } else if (hasConnection && _pausedDueToNetwork) {
      // Network restored - auto-resume
      _pausedDueToNetwork = false;

      DebugLogger.log('');
      DebugLogger.log(
        '  ╔════════════════════════════════════════════════════╗',
      );
      DebugLogger.log(
        '  ║  ✅ NETWORK RESTORED - Auto-Resuming Upload        ║',
      );
      DebugLogger.log(
        '  ╚════════════════════════════════════════════════════╝',
      );
      DebugLogger.log('');

      _logInfo(
        '✅ Network restored - auto-resuming from block $_currentBlockIndex',
        includeMemory: true,
      );

      // Auto-resume the upload
      resume();
    }
  }

  /// Feeds a connectivity change to the task, as the network monitor does.
  @visibleForTesting
  void handleConnectivityChangeForTesting(List<ConnectivityResult> results) =>
      _handleConnectivityChange(results);

  /// Starts the upload.
  ///
  /// The returned future completes when the upload finishes, fails or is
  /// cancelled. Pausing doesn't complete it: call [resume] to continue, and
  /// the same future completes when the upload is done.
  Future<UploadResult> start() async {
    if (_status == UploadStatus.inProgress) {
      _logError('Upload already in progress');
      return UploadResult.failure(
        fileId: _fileId ?? '',
        errorMessage: 'Upload already in progress',
      );
    }
    if (_status == UploadStatus.paused) return resume();

    _pausedDueToNetwork = false; // Reset network pause flag

    // Initialize memory monitoring
    _initializeMemoryBaseline();

    // Start network monitoring
    _startNetworkMonitoring();

    DebugLogger.log('');
    DebugLogger.log('  ╔════════════════════════════════════════════════════╗');
    DebugLogger.log('  ║          RESUMABLE UPLOAD SDK - Starting           ║');
    DebugLogger.log('  ╚════════════════════════════════════════════════════╝');
    DebugLogger.log('');
    _logInfo('📁 File: $filePath', includeMemory: true);

    final completer = _uploadCompleter = Completer<UploadResult>();
    _isPaused = false;
    _isCancelled = false;
    _fileCrc = null;
    _status = UploadStatus.inProgress;
    _uploadStartTime = DateTime.now();

    unawaited(_run(initial: true));
    return completer.future;
  }

  /// Runs the upload until it completes, fails, is cancelled or paused.
  Future<void> _run({required bool initial}) async {
    if (_runActive) return; // The active run picks up the new state.
    _runActive = true;
    try {
      if (initial) {
        // Initialize file info
        _logInfo('Initializing file info...', includeMemory: true);
        await _initializeFileInfo();
        if (_fileSize == 0) {
          _logError('File is empty or does not exist');
          _completeWithError('File is empty or does not exist');
          return;
        }
        _logInfo(
          'File initialized: ID=$_fileId, Size=${FileUtils.formatBytes(_fileSize)}, Blocks=$_blockCount',
        );
      }
      if (_isCancelled) return;

      // Get file info from server
      _logInfo('Getting file info from server...');
      final fileInfoResult = await _getFileInfoFromServer();
      if (!fileInfoResult) {
        if (_isCancelled) return;
        _logError('Failed to get file info from server');
        _completeWithError('Failed to get file info from server');
        return;
      }
      _logInfo(
        'Server response: fstatus=${_fileInfo!.fstatus}, uploaded blocks=${_fileInfo!.getUploadedBlockCount()}/$_blockCount',
      );

      // Check file status
      if (_fileInfo!.fstatus == FileStatus.completed) {
        _logInfo('File already uploaded, finalizing...');
        await _finalizeUpload();
        return;
      }

      // Upload blocks
      _logInfo(
        'Starting block uploads from index $_currentBlockIndex',
        includeMemory: true,
      );
      switch (await _uploadBlocks()) {
        case _LoopOutcome.cancelled:
          _logInfo('Upload cancelled by user');
          return; // cancel() already completed the result
        case _LoopOutcome.paused:
          _logInfo('Upload paused at block $_currentBlockIndex/$_blockCount');
          return; // resume() continues and completes the same result
        case _LoopOutcome.failed:
          _logError('Failed to upload blocks');
          _completeWithError('Failed to upload blocks');
          return;
        case _LoopOutcome.completed:
          break;
      }

      // Finalize upload
      _logInfo('All blocks uploaded, finalizing...', includeMemory: true);
      await _finalizeUpload();
    } catch (e) {
      _logError('Exception during upload: $e', includeMemory: true);
      _completeWithError(e.toString());
    } finally {
      _runActive = false;
      // resume() was called after the loop saw the pause but before this run
      // ended: continue now.
      if (_status == UploadStatus.inProgress &&
          !_isPaused &&
          !_isCancelled &&
          !(_uploadCompleter?.isCompleted ?? true)) {
        unawaited(_run(initial: false));
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
    _pausedDueToNetwork = false;
    _status = UploadStatus.inProgress;
    _uploadStartTime = DateTime.now();
    _emitProgress();

    unawaited(_run(initial: false));
    return completer.future;
  }

  /// Cancels the upload.
  void cancel() {
    if (_uploadCompleter?.isCompleted ?? false) return; // already finished
    _isCancelled = true;
    _status = UploadStatus.cancelled;
    _stopNetworkMonitoring(); // Stop monitoring on cancel
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

  /// Initializes file information.
  Future<void> _initializeFileInfo() async {
    _fileSize = await FileUtils.getFileSize(filePath);
    _blockSize = await FileUtils.getBlockSize(filePath);
    _blockCount = await FileUtils.getBlockCount(filePath);
    if (_fileSize == 0) return;
    // One pass over the file: the CRC is reused for the file ID and the server.
    final fileCrc = _fileCrc = await FileUtils.getFileCrc(filePath);
    _fileId = FileUtils.fileIdFromCrc(deviceId, fileCrc);
  }

  /// Gets file info from server.
  Future<bool> _getFileInfoFromServer() async {
    try {
      final fileCrc = _fileCrc ??= await FileUtils.getFileCrc(filePath);
      final createDate = await FileUtils.getFileCreateDate(filePath);
      final modifyDate = await FileUtils.getFileModifyDate(filePath);
      final fileExt = FileUtils.getFileExtension(filePath);

      final queryParams = {
        'fid': _fileId!,
        'fcrc': fileCrc.toString(),
        'fileSize': _fileSize.toString(),
        'createDate': createDate.toString(),
        'lastModifyDate': modifyDate.toString(),
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
        // A network loss auto-pauses; that's not a failure.
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

  /// Size of block [index] (the last block is usually smaller).
  int _blockDataSize(int index) =>
      index == _blockCount - 1 ? _fileSize - index * _blockSize : _blockSize;

  /// Bytes of the blocks the server reports as uploaded.
  int _uploadedBytes() {
    final info = _fileInfo;
    if (info == null) return 0;
    var total = 0;
    for (final block in info.blockMap.values) {
      if (block.status == BlockStatus.uploaded &&
          block.index >= 0 &&
          block.index < _blockCount) {
        total += _blockDataSize(block.index);
      }
    }
    return total;
  }

  /// Uploads a single block.
  /// Memory management: Block data is read once, used, then released.
  Future<bool> _uploadBlock(int blockIndex) async {
    final blockStartTime = DateTime.now();
    _logDebug(
      '--- Block $blockIndex/$_blockCount upload starting ---',
      includeMemory: true,
    );

    // Variables to track block data lifecycle
    Uint8List? blockData;
    int blockDataSize = 0;
    int blockCrc = 0;

    try {
      // Step 1: Read block data (only once!)
      _logDebug('Reading block $blockIndex from file...');
      blockData = await FileUtils.readBlock(filePath, blockIndex);
      blockDataSize = blockData.length;
      _logDebug(
        'Block $blockIndex read: ${FileUtils.formatBytes(blockDataSize)}',
        includeMemory: true,
      );

      // Step 2: Calculate CRC from already-loaded data (no second read!)
      blockCrc = Crc32.calculate(blockData);
      _logDebug('Block $blockIndex CRC: $blockCrc, Size: $blockDataSize');

      final queryParams = {
        'fid': _fileId!,
        'index': blockIndex.toString(),
        'range': '0-$blockDataSize',
        'crc': blockCrc.toString(),
      };

      final uri = Uri.parse(
        '${config.baseUrl}/api/v1/large_file/upload_block',
      ).replace(queryParameters: queryParams);

      _logDebug('Uploading block $blockIndex to server...');
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/octet-stream';
      if (config.headers != null) request.headers.addAll(config.headers!);

      // Step 3: Assign block data to request
      request.bodyBytes = blockData;

      // Step 4: Send request
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(Duration(seconds: config.timeoutSeconds * 2));

      // Step 5: Clear local reference to allow GC (request has its own copy)
      blockData = null;
      _logDebug(
        'Block $blockIndex data sent, local reference cleared',
        includeMemory: true,
      );

      final response = await http.Response.fromStream(streamedResponse);
      final blockDuration = DateTime.now().difference(blockStartTime);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['rtnCode'] == '0000000' || json['rtnCode'] == 0) {
          _fileInfo = FileInfoResponse.fromJson(
            json['bizData'] as Map<String, dynamic>,
          );
          _totalBytesUploaded = _uploadedBytes();
          _updateSpeedAndProgress(blockDataSize);

          final speedMBps =
              (blockDataSize /
                      blockDuration.inMilliseconds *
                      1000 /
                      (1024 * 1024))
                  .toStringAsFixed(2);
          _logInfo(
            '✅ Block $blockIndex complete (${blockDuration.inMilliseconds}ms @ $speedMBps MB/s)',
            includeMemory: true,
          );

          // Emit memory snapshot for external monitoring
          _emitMemorySnapshot();

          // Show visual progress every block
          _logBlockProgress();
          return true;
        } else {
          _logError('Block $blockIndex server error: ${json['rtnCode']}');
        }
      } else {
        _logError('Block $blockIndex HTTP error: ${response.statusCode}');
      }

      return false;
    } catch (e) {
      _logError('Block $blockIndex exception: $e', includeMemory: true);
      return false;
    } finally {
      // Step 6: Ensure block data is cleared even on error
      blockData = null;
      _logDebug(
        'Block $blockIndex memory cleanup complete',
        includeMemory: true,
      );
    }
  }

  /// Finalizes the upload.
  Future<UploadResult> _finalizeUpload() async {
    _logInfo('Finalizing upload...', includeMemory: true);

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

      _logDebug('Sending finalize request...');
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
          _stopNetworkMonitoring(); // Stop monitoring on success
          _emitProgress();

          final totalDuration = DateTime.now().difference(_uploadStartTime!);
          final avgSpeed = totalDuration.inSeconds > 0
              ? _fileSize / totalDuration.inSeconds
              : _fileSize.toDouble();

          DebugLogger.log('');
          DebugLogger.log(
            '  ╔════════════════════════════════════════════════════╗',
          );
          DebugLogger.log(
            '  ║            ✅ UPLOAD COMPLETE!                     ║',
          );
          DebugLogger.log(
            '  ╠════════════════════════════════════════════════════╣',
          );
          DebugLogger.log(
            '  ║  📊 Summary:                                       ║',
          );
          DebugLogger.log(
            '  ║  ├─ File Size: ${FileUtils.formatBytes(_fileSize).padRight(33)}║',
          );
          DebugLogger.log('${'  ║  ├─ Blocks: $_blockCount'.padRight(55)}║');
          DebugLogger.log(
            '${'  ║  ├─ Duration: ${totalDuration.inSeconds}s'.padRight(55)}║',
          );
          DebugLogger.log(
            '${'  ║  ├─ Avg Speed: ${FileUtils.formatBytes(avgSpeed.round())}/s'.padRight(55)}║',
          );
          DebugLogger.log(
            '${'  ║  └─ Peak Memory: ${_peakMemoryMB}MB'.padRight(55)}║',
          );
          DebugLogger.log(
            '  ╠════════════════════════════════════════════════════╣',
          );
          DebugLogger.log(
            '${'  ║  🔗 URL: ${(fileData['fileUrl'] as String).substring(0, 35.clamp(0, (fileData['fileUrl'] as String).length))}...'.padRight(55)}║',
          );
          DebugLogger.log(
            '  ╚════════════════════════════════════════════════════╝',
          );
          DebugLogger.log('');

          _logInfo('🎉 Upload completed successfully!', includeMemory: true);

          final result = UploadResult.success(
            fileId: _fileId!,
            fileUrl: fileData['fileUrl'] as String,
            serverId: fileData['id'] as int?,
            metadata: fileData,
          );

          _complete(result);
          return result;
        } else {
          _logError('Finalize server error: ${json['rtnCode']}');
        }
      } else {
        _logError('Finalize HTTP error: ${response.statusCode}');
      }

      return _completeWithError('Failed to finalize upload');
    } catch (e) {
      _logError('Finalize exception: $e');
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
        fileName: FileUtils.getFileName(filePath),
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
    _stopNetworkMonitoring(); // Stop monitoring on error
    _emitProgress(errorMessage: message);
    _complete(result);
    return result;
  }

  /// Disposes resources.
  void dispose() {
    _logInfo('Disposing upload task resources', includeMemory: true);
    _stopNetworkMonitoring(); // Stop monitoring on dispose
    // Stop a running upload and resolve anyone still waiting on start()/resume().
    _isCancelled = true;
    _complete(
      UploadResult.failure(
        fileId: _fileId ?? '',
        errorMessage: 'Upload task disposed',
      ),
    );
    _progressController.close();
    _logController.close();
    _memoryController.close();
    _httpClient.close();
  }
}
