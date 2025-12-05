import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_upload_sdk/resume_upload_sdk.dart';

import 'support/fake_upload_server.dart';

/// 5 MB: three 2 MB blocks, the last one smaller.
Uint8List _bytes(int length) {
  final random = Random(7);
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

void main() {
  late FakeUploadServer server;
  late Directory tmp;
  late File file;
  late Uint8List data;

  setUp(() async {
    server = await FakeUploadServer.start();
    tmp = await Directory.systemTemp.createTemp('resume_upload_test');
    data = _bytes(5 * 1024 * 1024);
    file = await File('${tmp.path}/video.bin').writeAsBytes(data);
  });

  tearDown(() async {
    await server.close();
    await tmp.delete(recursive: true);
  });

  UploadTask newTask({String path = '', int maxRetries = 0}) {
    final task =
        UploadTask(
            taskId: 't',
            filePath: path.isEmpty ? file.path : path,
            config: UploadConfig(
              baseUrl: server.baseUrl,
              maxRetries: maxRetries,
              retryDelayMs: 10,
            ),
            deviceId: 'device-1',
          )
          ..enableNetworkMonitoring = false
          ..enableLogging = false
          ..enableMemoryMonitoring = false;
    addTearDown(task.dispose);
    return task;
  }

  test(
    'uploads every block and the server reassembles the same file',
    () async {
      final task = newTask();
      final result = await task.start();

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(task.status, UploadStatus.completed);
      expect(server.assembled(task.fileId!), data);
    },
  );

  test('progress reports exact bytes and ends at 100%', () async {
    final task = newTask();
    final progress = <UploadProgress>[];
    task.progressStream.listen(progress.add);

    await task.start();
    await pumpEventQueue();

    expect(progress.last.uploadedBytes, data.length);
    expect(progress.last.progress, 1.0);
    expect(progress.every((p) => p.uploadedBytes <= data.length), isTrue);
  });

  test(
    'pause keeps the task resumable and resume finishes the same upload',
    () async {
      final task = newTask();
      server.blockGate = Completer<void>();
      final firstBlockArrived = Completer<void>();
      server.onBlockRequest = (_) {
        if (!firstBlockArrived.isCompleted) firstBlockArrived.complete();
      };

      var startCompleted = false;
      final startFuture = task.start()..then((_) => startCompleted = true);

      // Pause while block 0 is in flight, then let it finish.
      await firstBlockArrived.future;
      task.pause();
      server.blockGate!.complete();
      server.blockGate = null;
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(task.status, UploadStatus.paused);
      expect(
        startCompleted,
        isFalse,
        reason: 'start() must not resolve with a failure on pause',
      );
      expect(server.blockRequests.keys, [
        0,
      ], reason: 'no block after the pause');

      final resumed = await task.resume();
      expect(resumed.success, isTrue, reason: resumed.errorMessage);
      expect((await startFuture).success, isTrue);
      expect(server.assembled(task.fileId!), data);
      expect(
        server.blockRequests.values.every((n) => n == 1),
        isTrue,
        reason: 'no block uploaded twice',
      );
    },
  );

  test(
    'resume while the paused block is still in flight continues without a second loop',
    () async {
      final task = newTask();
      server.blockGate = Completer<void>();
      final firstBlockArrived = Completer<void>();
      server.onBlockRequest = (_) {
        if (!firstBlockArrived.isCompleted) firstBlockArrived.complete();
      };

      final startFuture = task.start();
      await firstBlockArrived.future;
      task.pause();
      final resumeFuture = task.resume();
      server.blockGate!.complete();
      server.blockGate = null;

      expect((await resumeFuture).success, isTrue);
      expect((await startFuture).success, isTrue);
      expect(server.blockRequests.values.every((n) => n == 1), isTrue);
    },
  );

  test(
    'a network loss auto-pauses and reconnecting auto-resumes to completion',
    () async {
      final task = newTask(maxRetries: 2);
      server.blockGate = Completer<void>();
      final firstBlockArrived = Completer<void>();
      server.onBlockRequest = (_) {
        if (!firstBlockArrived.isCompleted) firstBlockArrived.complete();
      };

      final startFuture = task.start();
      await firstBlockArrived.future;
      task.handleConnectivityChangeForTesting([ConnectivityResult.none]);
      server.blockGate!.complete();
      server.blockGate = null;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(task.status, UploadStatus.paused);

      task.handleConnectivityChangeForTesting([ConnectivityResult.wifi]);
      final result = await startFuture;
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(server.assembled(task.fileId!), data);
    },
  );

  test(
    'cancel resolves start() once with a cancelled result and no exception',
    () async {
      final task = newTask();
      server.blockGate = Completer<void>();
      final firstBlockArrived = Completer<void>();
      server.onBlockRequest = (_) {
        if (!firstBlockArrived.isCompleted) firstBlockArrived.complete();
      };

      final startFuture = task.start();
      await firstBlockArrived.future;
      task.cancel();
      server.blockGate!.complete();
      server.blockGate = null;

      final result = await startFuture;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Upload cancelled');
      expect(task.status, UploadStatus.cancelled);
    },
  );

  test('skips blocks the server already has', () async {
    final probe = newTask();
    await probe.start();
    final fid = probe.fileId!;

    // A fresh server that already holds blocks 0 and 2 from an earlier session.
    await server.close();
    server = await FakeUploadServer.start();
    server.seedBlocks(fid, {
      0: data.sublist(0, 2 << 20),
      2: data.sublist(4 << 20),
    });

    final task = newTask();
    final result = await task.start();

    expect(result.success, isTrue, reason: result.errorMessage);
    expect(server.blockRequests.keys, [1]);
    expect(server.assembled(fid), data);
  });

  test('an empty file fails with a clear message', () async {
    final empty = await File('${tmp.path}/empty.bin').create();
    final task = newTask(path: empty.path);

    final result = await task.start();

    expect(result.success, isFalse);
    expect(result.errorMessage, contains('empty'));
  });

  test('UploadTaskWeb (in-memory bytes) also pauses and resumes', () async {
    final task = UploadTaskWeb(
      taskId: 'w',
      fileData: data,
      fileName: 'video.bin',
      config: UploadConfig(baseUrl: server.baseUrl, maxRetries: 0),
      deviceId: 'device-1',
    );
    addTearDown(task.dispose);
    server.blockGate = Completer<void>();
    final firstBlockArrived = Completer<void>();
    server.onBlockRequest = (_) {
      if (!firstBlockArrived.isCompleted) firstBlockArrived.complete();
    };

    final startFuture = task.start();
    await firstBlockArrived.future;
    task.pause();
    server.blockGate!.complete();
    server.blockGate = null;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(task.status, UploadStatus.paused);

    expect((await task.resume()).success, isTrue);
    expect((await startFuture).success, isTrue);
    expect(server.assembled(task.fileId!), data);
  });
}
