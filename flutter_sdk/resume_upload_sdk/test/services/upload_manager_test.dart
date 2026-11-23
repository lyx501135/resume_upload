import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_upload_sdk/resume_upload_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tasks that run watch connectivity, so its event channel is mocked.
const _connectivity = MethodChannel(
  'dev.fluttercommunity.plus/connectivity_status',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UploadManager manager;
  late Directory tmp;
  late String path;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_connectivity, (call) async => null);
    manager = UploadManager.instance;
    await manager.initialize(const UploadConfig(baseUrl: 'http://fake.test'));
    tmp = await Directory.systemTemp.createTemp('resume_upload_mgr');
    path = (await File('${tmp.path}/a.bin').writeAsBytes([1, 2, 3])).path;
  });

  tearDown(() async {
    manager.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_connectivity, null);
    await tmp.delete(recursive: true);
  });

  test('createTask registers the task under a fresh id', () {
    final a = manager.createTask(filePath: path);
    final b = manager.createTask(filePath: path);

    expect(a.taskId, isNot(b.taskId));
    expect(manager.getTask(a.taskId), same(a));
    expect(manager.activeTaskCount, 2);
    expect(manager.getActiveTasks(), containsAll([a, b]));
    expect(a.config.baseUrl, 'http://fake.test');
    expect(a.deviceId, isNotEmpty);
  });

  test('createTask uses the config it is given over the default', () {
    final task = manager.createTask(
      filePath: path,
      config: const UploadConfig(baseUrl: 'http://other.test'),
    );

    expect(task.config.baseUrl, 'http://other.test');
  });

  test('cancelTask cancels and forgets the task', () {
    final task = manager.createTask(filePath: path);

    manager.cancelTask(task.taskId);

    expect(task.status, UploadStatus.cancelled);
    expect(manager.getTask(task.taskId), isNull);
    expect(manager.activeTaskCount, 0);
  });

  test('cancelAllTasks cancels every task and empties the registry', () {
    final a = manager.createTask(filePath: path);
    final b = manager.createTask(filePath: path);

    manager.cancelAllTasks();

    expect(a.status, UploadStatus.cancelled);
    expect(b.status, UploadStatus.cancelled);
    expect(manager.activeTaskCount, 0);
  });

  test('getTasksByStatus filters on the task status', () {
    final notStarted = manager.createTask(filePath: path);
    final cancelled = manager.createTask(filePath: path)..cancel();

    expect(manager.getTasksByStatus(UploadStatus.notStarted), [notStarted]);
    expect(manager.getTasksByStatus(UploadStatus.cancelled), [cancelled]);
  });

  test('pauseTask and resumeTask on an unknown id do nothing', () async {
    manager.pauseTask('missing');

    expect(await manager.resumeTask('missing'), isNull);
  });

  test('resumeTask on a task that is not paused reports a failure', () async {
    final task = manager.createTask(filePath: path);

    final result = await manager.resumeTask(task.taskId);

    expect(result!.success, isFalse);
    expect(result.errorMessage, 'Upload is not paused');
  });

  test('upload() removes the task once it has finished', () async {
    final result = await manager.upload(filePath: '${tmp.path}/missing.bin');

    expect(result.success, isFalse);
    expect(result.errorMessage, contains('empty'));
    expect(manager.activeTaskCount, 0);
  });
}
