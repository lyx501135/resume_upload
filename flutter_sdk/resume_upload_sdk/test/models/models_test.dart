import 'package:flutter_test/flutter_test.dart';
import 'package:resume_upload_sdk/resume_upload_sdk.dart';

void main() {
  group('BlockInfo', () {
    test('fromJson accepts a string or int crc and parses the status', () {
      final fromString = BlockInfo.fromJson({
        'index': 0,
        'crc': '123',
        'status': 1,
        'range': '0-2048',
      });
      final fromInt = BlockInfo.fromJson({
        'index': 1,
        'crc': 456,
        'status': 2,
        'range': null,
      });

      expect(fromString.crc, 123);
      expect(fromString.status, BlockStatus.uploaded);
      expect(fromInt.crc, 456);
      expect(fromInt.status, BlockStatus.partial);
      expect(fromInt.range, isNull);
    });

    test('an unknown status maps to notUploaded', () {
      final block = BlockInfo.fromJson({
        'index': 0,
        'crc': 0,
        'status': 99,
        'range': null,
      });

      expect(block.status, BlockStatus.notUploaded);
    });

    test('size is the end of the range, or 0 when it cannot be read', () {
      BlockInfo withRange(String? range) => BlockInfo.fromJson({
        'index': 0,
        'crc': 0,
        'status': 1,
        'range': range,
      });

      expect(withRange('0-2097152').size, 2097152);
      expect(withRange(null).size, 0);
      expect(withRange('garbage').size, 0);
      expect(withRange('0-x').size, 0);
    });

    test('toJson writes the wire keys only, with status as its int value', () {
      final block = BlockInfo.fromJson({
        'index': 3,
        'crc': '77',
        'status': 1,
        'range': '0-10',
      });

      expect(block.toJson(), {
        'index': 3,
        'crc': 77,
        'status': 1,
        'range': '0-10',
      });
    });

    test('round-trips through JSON', () {
      const block = BlockInfo(
        index: 2,
        crc: 9,
        status: BlockStatus.uploaded,
        range: '0-64',
        size: 64,
      );

      final again = BlockInfo.fromJson(block.toJson());

      expect(again, block);
      expect(again.size, 64);
    });

    test('value equality and copyWith', () {
      const a = BlockInfo(
        index: 0,
        crc: 1,
        status: BlockStatus.notUploaded,
        size: 5,
      );
      const b = BlockInfo(
        index: 0,
        crc: 1,
        status: BlockStatus.notUploaded,
        size: 5,
      );

      expect(a, b);
      expect(
        a.copyWith(status: BlockStatus.uploaded).status,
        BlockStatus.uploaded,
      );
      expect(a.copyWith(status: BlockStatus.uploaded), isNot(a));
    });
  });

  group('FileInfoResponse', () {
    Map<String, dynamic> payload({Object? blockMap = _absent}) => {
      'fid': 'abc',
      'fstatus': 2,
      'fileName': 'video.mp4',
      'fileSize': 5242880,
      'blockSize': 2097152,
      'blockCount': 3,
      'fcrc': '4294967295',
      'fileExt': 'mp4',
      'furl': null,
      if (!identical(blockMap, _absent)) 'blockMap': blockMap,
      'createDate': 1700000000,
      'lastModifyDate': null,
    };

    test('fromJson parses the server payload', () {
      final info = FileInfoResponse.fromJson(
        payload(
          blockMap: {
            '0': {'index': 0, 'crc': '1', 'status': 1, 'range': '0-2097152'},
            '1': {'index': 1, 'crc': '2', 'status': 0, 'range': null},
          },
        ),
      );

      expect(info.fid, 'abc');
      expect(info.fstatus, FileStatus.incomplete);
      expect(info.fcrc, 4294967295);
      expect(info.fileName, 'video.mp4');
      expect(info.createDate, 1700000000);
      expect(info.lastModifyDate, isNull);
      expect(info.blockMap.keys, unorderedEquals(['0', '1']));
      expect(info.blockMap['0']!.size, 2097152);
    });

    test('a missing blockMap is empty, and non-object entries are skipped', () {
      expect(FileInfoResponse.fromJson(payload()).blockMap, isEmpty);

      final info = FileInfoResponse.fromJson(
        payload(
          blockMap: {
            '0': {'index': 0, 'crc': 1, 'status': 1, 'range': null},
            '1': 'not a block',
          },
        ),
      );
      expect(info.blockMap.keys, ['0']);
    });

    test('an unknown fstatus maps to notStarted', () {
      final info = FileInfoResponse.fromJson(payload()..['fstatus'] = 42);

      expect(info.fstatus, FileStatus.notStarted);
    });

    test('getNextBlockIndex returns the first block the server lacks', () {
      FileInfoResponse withBlocks(Map<String, BlockStatus> statuses) =>
          FileInfoResponse.fromJson(
            payload(
              blockMap: {
                for (final e in statuses.entries)
                  e.key: {
                    'index': int.parse(e.key),
                    'crc': 0,
                    'status': e.value.value,
                    'range': null,
                  },
              },
            ),
          );

      expect(withBlocks({}).getNextBlockIndex(), 0);
      expect(
        withBlocks({'0': BlockStatus.uploaded, '1': BlockStatus.uploaded})
            .getNextBlockIndex(),
        2,
      );
      expect(
        withBlocks({'0': BlockStatus.uploaded, '1': BlockStatus.partial})
            .getNextBlockIndex(),
        1,
      );
      expect(
        withBlocks({
          '0': BlockStatus.uploaded,
          '1': BlockStatus.uploaded,
          '2': BlockStatus.uploaded,
        }).getNextBlockIndex(),
        3,
      );
    });

    test('getUploadedBlockCount counts only uploaded blocks', () {
      final info = FileInfoResponse.fromJson(
        payload(
          blockMap: {
            '0': {'index': 0, 'crc': 0, 'status': 1, 'range': null},
            '1': {'index': 1, 'crc': 0, 'status': 2, 'range': null},
            '2': {'index': 2, 'crc': 0, 'status': 1, 'range': null},
          },
        ),
      );

      expect(info.getUploadedBlockCount(), 2);
    });

    test('toJson keeps the server key names and nulls', () {
      final info = FileInfoResponse.fromJson(
        payload(
          blockMap: {
            '0': {'index': 0, 'crc': '5', 'status': 1, 'range': '0-9'},
          },
        ),
      );

      final json = info.toJson();

      expect(json.keys, unorderedEquals(payload(blockMap: {}).keys));
      expect(json['fstatus'], 2);
      expect(json['fcrc'], 4294967295);
      expect(json['furl'], isNull);
      expect(json['lastModifyDate'], isNull);
      expect(json['blockMap'], {
        '0': {'index': 0, 'crc': 5, 'status': 1, 'range': '0-9'},
      });
    });

    test('round-trips through JSON', () {
      final info = FileInfoResponse.fromJson(
        payload(
          blockMap: {
            '0': {'index': 0, 'crc': 1, 'status': 1, 'range': '0-7'},
          },
        ),
      );

      expect(FileInfoResponse.fromJson(info.toJson()), info);
    });

    test('toString summarises the upload', () {
      final info = FileInfoResponse.fromJson(payload());

      expect(
        info.toString(),
        'FileInfoResponse(fid: abc, fstatus: FileStatus.incomplete, uploadedBlocks: 0/3)',
      );
    });
  });

  group('UploadConfig', () {
    test('defaults match the documented values', () {
      const config = UploadConfig(baseUrl: 'http://x');

      expect(config.timeoutSeconds, 30);
      expect(config.maxRetries, 3);
      expect(config.retryDelayMs, 1000);
      expect(config.isRandomName, isFalse);
      expect(config.headers, isNull);
      expect(config.userId, isNull);
    });

    test('copyWith changes only the given fields', () {
      const config = UploadConfig(baseUrl: 'http://a', userId: 'u1');

      final copy = config.copyWith(baseUrl: 'http://b', maxRetries: 5);

      expect(copy.baseUrl, 'http://b');
      expect(copy.maxRetries, 5);
      expect(copy.userId, 'u1');
      expect(copy.timeoutSeconds, 30);
    });

    test('value equality', () {
      const a = UploadConfig(baseUrl: 'http://a', headers: {'X': 'y'});
      const b = UploadConfig(baseUrl: 'http://a', headers: {'X': 'y'});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('UploadProgress', () {
    UploadProgress progress({double progressValue = 0.5, double speed = 0}) =>
        UploadProgress(
          fileId: 'f',
          fileName: 'a.bin',
          totalBytes: 100,
          uploadedBytes: 50,
          progress: progressValue,
          speed: speed,
          currentBlockIndex: 1,
          totalBlocks: 2,
          status: UploadStatus.inProgress,
        );

    test('progressPercentage has one decimal place', () {
      expect(progress(progressValue: 0.256).progressPercentage, '25.6%');
      expect(progress(progressValue: 1).progressPercentage, '100.0%');
    });

    test('speedString picks B/s, KB/s or MB/s', () {
      expect(progress(speed: 500).speedString, '500 B/s');
      expect(progress(speed: 2048).speedString, '2.0 KB/s');
      expect(progress(speed: 3 * 1024 * 1024).speedString, '3.0 MB/s');
    });

    test('copyWith and equality', () {
      final a = progress();
      final b = a.copyWith(status: UploadStatus.paused);

      expect(b.status, UploadStatus.paused);
      expect(b.fileName, a.fileName);
      expect(a, progress());
      expect(b, isNot(a));
    });
  });

  group('UploadResult', () {
    test('success carries the URL and metadata', () {
      final result = UploadResult.success(
        fileId: 'f',
        fileUrl: '/storage/x',
        serverId: 7,
        metadata: const {'id': 7},
      );

      expect(result.success, isTrue);
      expect(result.fileUrl, '/storage/x');
      expect(result.serverId, 7);
      expect(result.errorMessage, isNull);
      expect(result.metadata, {'id': 7});
    });

    test('failure carries the message', () {
      final result = UploadResult.failure(fileId: 'f', errorMessage: 'boom');

      expect(result.success, isFalse);
      expect(result.fileUrl, isNull);
      expect(result.errorMessage, 'boom');
    });

    test('toString and equality', () {
      final a = UploadResult.failure(fileId: 'f', errorMessage: 'boom');

      expect(
        a.toString(),
        'UploadResult(success: false, fileId: f, fileUrl: null, error: boom)',
      );
      expect(a, UploadResult.failure(fileId: 'f', errorMessage: 'boom'));
    });
  });

  group('enums', () {
    test('fromValue maps known values and falls back for unknown ones', () {
      expect(UploadStatus.fromValue(3), UploadStatus.completed);
      expect(UploadStatus.fromValue(42), UploadStatus.notStarted);
      expect(FileStatus.fromValue(-1), FileStatus.abnormal);
      expect(FileStatus.fromValue(42), FileStatus.notStarted);
      expect(BlockStatus.fromValue(-1), BlockStatus.error);
      expect(BlockStatus.fromValue(42), BlockStatus.notUploaded);
    });
  });
}

const _absent = Object();
