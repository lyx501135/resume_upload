import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/upload_config.dart';
import '../models/upload_progress.dart';
import '../models/upload_result.dart';
import '../models/upload_status.dart';
import 'upload_task.dart';

/// Callback type for upload progress.
typedef UploadProgressCallback = void Function(UploadProgress progress);

/// Callback type for upload completion.
typedef UploadCompletionCallback = void Function(UploadResult result);

/// Manages upload tasks.
class UploadManager {
  /// Singleton instance.
  static UploadManager? _instance;

  /// Gets the singleton instance.
  static UploadManager get instance {
    _instance ??= UploadManager._();
    return _instance!;
  }

  UploadManager._();

  /// Default configuration.
  UploadConfig _defaultConfig = const UploadConfig(baseUrl: '');

  /// Device ID for file identification.
  String? _deviceId;

  /// Dio client for the tasks created by this manager; null lets each task
  /// create its own.
  Dio? _dio;

  /// Map of active upload tasks.
  final Map<String, UploadTask> _tasks = {};

  /// UUID generator.
  final _uuid = const Uuid();

  /// Initializes the upload manager with configuration.
  ///
  /// [dio] is used by every task created afterwards. Leave it out to let each
  /// task create its own client.
  Future<void> initialize(UploadConfig config, {Dio? dio}) async {
    _defaultConfig = config;
    _dio = dio;
    await _loadDeviceId();
  }

  /// Loads or generates device ID.
  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('resume_upload_device_id');
    if (_deviceId == null) {
      _deviceId = _uuid.v4();
      await prefs.setString('resume_upload_device_id', _deviceId!);
    }
  }

  /// Gets the device ID.
  String get deviceId => _deviceId ?? _uuid.v4();

  /// Creates a new upload task.
  UploadTask createTask({required String filePath, UploadConfig? config}) {
    final taskId = _uuid.v4();
    final task = UploadTask(
      taskId: taskId,
      filePath: filePath,
      config: config ?? _defaultConfig,
      deviceId: deviceId,
      dio: _dio,
    );

    _tasks[taskId] = task;
    return task;
  }

  /// Starts an upload with callbacks.
  Future<UploadResult> upload({
    required String filePath,
    UploadConfig? config,
    UploadProgressCallback? onProgress,
    UploadCompletionCallback? onComplete,
  }) async {
    final task = createTask(filePath: filePath, config: config);

    if (onProgress != null) task.progressStream.listen(onProgress);

    final result = await task.start();

    if (onComplete != null) onComplete(result);

    // Clean up completed task
    _tasks.remove(task.taskId);

    return result;
  }

  /// Gets a task by ID.
  UploadTask? getTask(String taskId) => _tasks[taskId];

  /// Gets all active tasks.
  List<UploadTask> getActiveTasks() => _tasks.values.toList();

  /// Pauses a task by ID.
  void pauseTask(String taskId) {
    _tasks[taskId]?.pause();
  }

  /// Resumes a task by ID.
  Future<UploadResult?> resumeTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) return await task.resume();
    return null;
  }

  /// Cancels a task by ID.
  void cancelTask(String taskId) {
    _tasks[taskId]?.cancel();
    _tasks.remove(taskId);
  }

  /// Cancels all active tasks.
  void cancelAllTasks() {
    for (final task in _tasks.values) {
      task.cancel();
    }
    _tasks.clear();
  }

  /// Gets the count of active tasks.
  int get activeTaskCount => _tasks.length;

  /// Gets tasks by status.
  List<UploadTask> getTasksByStatus(UploadStatus status) =>
      _tasks.values.where((task) => task.status == status).toList();

  /// Disposes all resources.
  void dispose() {
    for (final task in _tasks.values) {
      task.dispose();
    }
    _tasks.clear();
  }
}
