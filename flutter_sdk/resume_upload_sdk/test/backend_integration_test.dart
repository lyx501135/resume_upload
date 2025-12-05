// Runs only against a real backend (backend/python/app.py):
//   RESUME_UPLOAD_BACKEND_URL=http://127.0.0.1:8080 flutter test test/backend_integration_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:resume_upload_sdk/resume_upload_sdk.dart';

final _backendUrl = Platform.environment['RESUME_UPLOAD_BACKEND_URL'];

void main() {
  if (_backendUrl == null) {
    test(
      'backend integration',
      () {},
      skip: 'Set RESUME_UPLOAD_BACKEND_URL to run against a real backend',
    );
    return;
  }

  late Directory tmp;

  setUp(
    () async => tmp = await Directory.systemTemp.createTemp('resume_upload_it'),
  );
  tearDown(() => tmp.delete(recursive: true));

  Future<(File, Uint8List)> makeFile(int length, int seed) async {
    final random = Random(seed);
    final data = Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
    return (await File('${tmp.path}/file_$seed.bin').writeAsBytes(data), data);
  }

  UploadTask newTask(String path) =>
      UploadTask(
          taskId: 'it',
          filePath: path,
          config: UploadConfig(baseUrl: _backendUrl!, maxRetries: 1),
          // A fresh device ID per run, so earlier runs' uploads don't collide.
          deviceId: 'it-${DateTime.now().microsecondsSinceEpoch}',
        )
        ..enableNetworkMonitoring = false
        ..enableLogging = false;

  Future<Uint8List> download(UploadResult result) async =>
      (await http.get(Uri.parse('$_backendUrl${result.fileUrl}'))).bodyBytes;

  test('uploads a file and the backend serves identical bytes', () async {
    final (file, data) = await makeFile(5 * 1024 * 1024, 1);
    final task = newTask(file.path);
    addTearDown(task.dispose);

    final result = await task.start();

    expect(result.success, isTrue, reason: result.errorMessage);
    expect(await download(result), data);
  });

  test('pause and resume against the real backend', () async {
    final (file, data) = await makeFile(7 * 1024 * 1024, 2);
    final task = newTask(file.path);
    addTearDown(task.dispose);
    final firstBlockDone = Completer<void>();
    task.progressStream.listen((p) {
      if (p.uploadedBytes > 0 && !firstBlockDone.isCompleted) {
        firstBlockDone.complete();
      }
    });

    final done = task.start();
    await firstBlockDone.future;
    task.pause();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(task.status, UploadStatus.paused);

    task.resume();
    final result = await done;
    expect(result.success, isTrue, reason: result.errorMessage);
    expect(await download(result), data);
  });
}
