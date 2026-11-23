// Upload tasks over Dio, with every request answered by a fake HttpClientAdapter.
// No socket is opened: the fake backend below speaks the same protocol as
// backend/python/app.py.
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_upload_sdk/resume_upload_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_dio_adapter.dart';

/// A scripted failure for an upload_block request.
enum BlockFailure {
  /// HTTP 200 with an error rtnCode.
  rtnError,

  /// The transport fails before any response.
  connection,
}

/// Speaks the upload protocol in-process and keeps the blocks it has stored.
class FakeUploadBackend {
  FakeUploadBackend({required this.fileSize, required this.blockSize});

  final int fileSize;
  final int blockSize;
  int get blockCount => (fileSize / blockSize).ceil();

  String fid = '';

  /// Blocks stored so far, by index.
  final Map<int, Uint8List> stored = {};

  /// upload_block requests received per index, failed ones included.
  final Map<int, int> blockRequests = {};

  /// Failures for upload_block requests, consumed in order before the block is
  /// stored. An int is an HTTP status; a [BlockFailure] is as documented there.
  final Map<int, List<Object>> blockFailures = {};

  /// HTTP status for upload_file, if it should fail.
  int? fileInfoStatus;

  /// HTTP status for the finalize request, if it should fail.
  int? finalizeStatus;

  FutureOr<ResponseBody> handle(RecordedRequest request) {
    final q = request.uri.queryParameters;
    switch (request.path) {
      case '/api/v1/large_file/upload_file':
        if (fileInfoStatus != null) {
          return ResponseBody.fromString('', fileInfoStatus!);
        }
        fid = q['fid']!;
        return jsonResponse(_ok(_info()));
      case '/api/v1/large_file/upload_block':
        final index = int.parse(q['index']!);
        blockRequests[index] = (blockRequests[index] ?? 0) + 1;
        final queue = blockFailures[index];
        if (queue != null && queue.isNotEmpty) {
          final failure = queue.removeAt(0);
          if (failure is int) {
            return jsonResponse({'rtnCode': '9999999'}, status: failure);
          }
          if (failure == BlockFailure.rtnError) {
            return jsonResponse({'rtnCode': '9999999'});
          }
          throw DioException.connectionError(
            requestOptions: request.options,
            reason: 'connection reset',
          );
        }
        stored[index] = request.body;
        return jsonResponse(_ok(_info()));
      case '/api/v1/uploadFileForLargeFile':
        if (finalizeStatus != null) {
          return jsonResponse({'rtnCode': '9999999'}, status: finalizeStatus!);
        }
        if (stored.length < blockCount) {
          return jsonResponse({'rtnCode': '9999999'}, status: 400);
        }
        return jsonResponse({
          'rtnCode': '0000000',
          'bizData': {
            'file': {'id': 42, 'fileUrl': '/storage/completed/$fid'},
          },
        });
      default:
        return ResponseBody.fromString('', 404);
    }
  }

  /// The file rebuilt from the stored blocks, in index order.
  Uint8List assembled() {
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < blockCount; i++) {
      out.add(stored[i]!);
    }
    return out.takeBytes();
  }

  Map<String, Object> _info() => {
    'fid': fid,
    'fstatus': stored.length == blockCount ? 1 : (stored.isEmpty ? 0 : 2),
    'fileSize': fileSize,
    'blockSize': blockSize,
    'blockCount': blockCount,
    'fcrc': '0', // a string, as the server sends it
    'blockMap': {
      for (final i in stored.keys)
        '$i': {
          'index': i,
          'crc': '0',
          'status': 1,
          'range': '0-${stored[i]!.length}',
        },
    },
  };

  static Map<String, Object> _ok(Map<String, Object> bizData) => {
    'rtnCode': '0000000',
    'bizData': bizData,
  };
}

/// 5 MB: three blocks of 2 MB, 2 MB and 1 MB.
Uint8List _bytes(int length) {
  final random = Random(11);
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const deviceId = 'device-dio';
  late Directory tmp;
  late File file;
  late Uint8List data;
  late String fid;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('resume_upload_dio');
    data = _bytes(5 * 1024 * 1024);
    file = await File('${tmp.path}/video.bin').writeAsBytes(data);
    fid = FileUtils.fileIdFromCrc(deviceId, Crc32.calculate(data));
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  late FakeUploadBackend backend;
  late FakeDioAdapter adapter;
  late Dio dio;

  void useBackend() {
    backend = FakeUploadBackend(
      fileSize: data.length,
      blockSize: 2 * 1024 * 1024,
    );
    adapter = FakeDioAdapter(backend.handle);
    dio = fakeDio(adapter);
    addTearDown(() => dio.close(force: true));
  }

  UploadConfig config({int maxRetries = 0}) => UploadConfig(
    baseUrl: 'http://fake.test',
    timeoutSeconds: 5,
    maxRetries: maxRetries,
    retryDelayMs: 1,
    headers: const {'X-Token': 'secret'},
    userId: '1',
    productCode: 'demo',
    bizSystem: 'demo',
  );

  UploadTask newTask({int maxRetries = 0}) {
    final task =
        UploadTask(
            taskId: 't',
            filePath: file.path,
            config: config(maxRetries: maxRetries),
            deviceId: deviceId,
            dio: dio,
          )
          ..enableNetworkMonitoring = false
          ..enableLogging = false
          ..enableMemoryMonitoring = false;
    addTearDown(task.dispose);
    return task;
  }

  List<RecordedRequest> requestsTo(String path) =>
      adapter.requests.where((r) => r.path == path).toList();

  const uploadFile = '/api/v1/large_file/upload_file';
  const uploadBlock = '/api/v1/large_file/upload_block';
  const finalize = '/api/v1/uploadFileForLargeFile';

  group('request shape', () {
    test('upload_file: POST with the file metadata in the query', () async {
      useBackend();
      final result = await newTask().start();
      expect(result.success, isTrue, reason: result.errorMessage);

      final info = requestsTo(uploadFile).single;
      expect(info.method, 'POST');
      expect(info.body, isEmpty);
      expect(info.uri.queryParameters, containsPair('fid', fid));
      expect(info.uri.queryParameters['fileSize'], '${data.length}');
      expect(info.uri.queryParameters['blockCount'], '3');
      expect(info.uri.queryParameters['blockSize'], '${2 * 1024 * 1024}');
      expect(info.uri.queryParameters['fileExt'], 'bin');
      for (final key in ['fcrc', 'createDate', 'lastModifyDate']) {
        expect(info.uri.queryParameters.containsKey(key), isTrue, reason: key);
      }
      expect(info.options.headers['Content-Type'], 'application/octet-stream');
      expect(info.options.headers['X-Token'], 'secret');
    });

    test(
      'upload_block: POST of the exact block bytes with index, range and CRC',
      () async {
        useBackend();
        await newTask().start();

        final blocks = requestsTo(uploadBlock);
        expect(blocks.map((b) => b.uri.queryParameters['index']), [
          '0',
          '1',
          '2',
        ]);
        final sizes = [2 * 1024 * 1024, 2 * 1024 * 1024, 1024 * 1024];
        for (var i = 0; i < blocks.length; i++) {
          final block = blocks[i];
          final expected = data.sublist(
            i * 2 * 1024 * 1024,
            i * 2 * 1024 * 1024 + sizes[i],
          );
          expect(block.method, 'POST');
          expect(block.body, expected, reason: 'block $i body');
          expect(block.uri.queryParameters['fid'], fid);
          expect(block.uri.queryParameters['range'], '0-${sizes[i]}');
          expect(
            block.uri.queryParameters['crc'],
            '${Crc32.calculate(expected)}',
          );
          expect(
            block.options.headers['Content-Type'],
            'application/octet-stream',
          );
          expect(block.options.headers['X-Token'], 'secret');
        }
        expect(backend.assembled(), data);
      },
    );

    test(
      'finalize: POST with the directory, naming and business query',
      () async {
        useBackend();
        await newTask().start();

        final done = requestsTo(finalize).single;
        expect(done.method, 'POST');
        expect(done.uri.queryParameters, {
          'fid': fid,
          'dirId': '0',
          'isRandomName': 'false',
          'userId': '1',
          'productCode': 'demo',
          'bizSystem': 'demo',
        });
        expect(done.options.headers['X-Token'], 'secret');
      },
    );

    test('a null config.headers sends only the Content-Type', () async {
      useBackend();
      final task =
          UploadTask(
              taskId: 't',
              filePath: file.path,
              config: const UploadConfig(
                baseUrl: 'http://fake.test',
                retryDelayMs: 1,
              ),
              deviceId: deviceId,
              dio: dio,
            )
            ..enableNetworkMonitoring = false
            ..enableLogging = false
            ..enableMemoryMonitoring = false;
      addTearDown(task.dispose);

      expect((await task.start()).success, isTrue);
      expect(requestsTo(uploadBlock).first.options.headers['X-Token'], isNull);
    });
  });

  group('retries and failures', () {
    test('a block that returns HTTP 500 is retried, then succeeds', () async {
      useBackend();
      backend.blockFailures[1] = [500, 503];

      final result = await newTask(maxRetries: 2).start();

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(backend.blockRequests[1], 3);
      expect(backend.blockRequests[0], 1);
      expect(backend.assembled(), data);
    });

    test('a block with an error rtnCode is retried, then succeeds', () async {
      useBackend();
      backend.blockFailures[0] = [BlockFailure.rtnError];

      final result = await newTask(maxRetries: 1).start();

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(backend.blockRequests[0], 2);
    });

    test('a connection error is retried, then the upload fails', () async {
      useBackend();
      backend.blockFailures[2] = [
        BlockFailure.connection,
        BlockFailure.connection,
        BlockFailure.connection,
      ];
      final task = newTask(maxRetries: 2);

      final result = await task.start();

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Failed to upload blocks');
      expect(task.status, UploadStatus.failed);
      expect(backend.blockRequests[2], 3, reason: '1 attempt + 2 retries');
      expect(
        requestsTo(finalize),
        isEmpty,
        reason: 'no finalize after failure',
      );
    });

    test(
      'exhausting retries with HTTP errors fails with the same message',
      () async {
        useBackend();
        backend.blockFailures[0] = [500, 500];

        final result = await newTask(maxRetries: 1).start();

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Failed to upload blocks');
        expect(backend.blockRequests[0], 2);
      },
    );

    test(
      'upload_file returning HTTP 500 fails before any block is sent',
      () async {
        useBackend();
        backend.fileInfoStatus = 500;

        final result = await newTask().start();

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Failed to get file info from server');
        expect(requestsTo(uploadBlock), isEmpty);
      },
    );

    test('finalize returning HTTP 400 fails the upload', () async {
      useBackend();
      backend.finalizeStatus = 400;

      final task = newTask();
      final result = await task.start();

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Failed to finalize upload');
      expect(task.status, UploadStatus.failed);
    });
  });

  group('resume', () {
    test('only the blocks the server lacks are sent', () async {
      useBackend();
      backend.fid = fid;
      backend.stored[0] = data.sublist(0, 2 * 1024 * 1024);
      backend.stored[2] = data.sublist(4 * 1024 * 1024);

      final task = newTask();
      final result = await task.start();

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(backend.blockRequests.keys, [1]);
      expect(backend.assembled(), data);
    });

    test('progress starts from the bytes the server already has', () async {
      useBackend();
      backend.fid = fid;
      backend.stored[0] = data.sublist(0, 2 * 1024 * 1024);
      final task = newTask();
      final progress = <UploadProgress>[];
      task.progressStream.listen(progress.add);

      await task.start();
      await pumpEventQueue();

      // Block 0 was already stored, so the first progress event comes after
      // block 1 finishes: 2 MB + 2 MB.
      expect(progress.first.uploadedBytes, 4 * 1024 * 1024);
      expect(progress.last.uploadedBytes, data.length);
    });
  });

  group('client ownership', () {
    test('dispose does not close a Dio that was passed in', () async {
      useBackend();
      final task = newTask();
      await task.start();

      task.dispose();
      await pumpEventQueue();

      expect(adapter.closed, isFalse);
    });

    test('UploadTaskWeb uses the injected Dio and retries a block', () async {
      useBackend();
      backend.blockFailures[1] = [500];
      final task = UploadTaskWeb(
        taskId: 'w',
        fileData: data,
        fileName: 'video.bin',
        config: config(maxRetries: 1),
        deviceId: deviceId,
        dio: dio,
      );
      addTearDown(task.dispose);

      final result = await task.start();

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.fileId, fid);
      expect(backend.blockRequests[1], 2);
      expect(backend.assembled(), data);
    });

    test('UploadManager hands its Dio to the tasks it creates', () async {
      useBackend();
      // Tasks from the manager watch connectivity, so mock its event channel.
      const connectivity = MethodChannel(
        'dev.fluttercommunity.plus/connectivity_status',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectivity, (call) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(connectivity, null),
      );
      await UploadManager.instance.initialize(config(), dio: dio);
      addTearDown(() => UploadManager.instance.dispose());

      final result = await UploadManager.instance.upload(filePath: file.path);

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(adapter.requests, isNotEmpty);
      expect(backend.assembled(), data);
    });
  });
}
