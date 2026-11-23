// Block sizing, block slicing, CRCs and file IDs: the arithmetic that decides
// what each block request contains and how a resume lines up with the server.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:resume_upload_sdk/resume_upload_sdk.dart';
import 'package:resume_upload_sdk/src/utils/file_utils.dart';
import 'package:resume_upload_sdk/src/utils/file_utils_web.dart' as web;

const _mb = 1024 * 1024;

Uint8List _bytes(int length, [int seed = 3]) {
  final random = Random(seed);
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

void main() {
  group('block size tiers', () {
    test('the block size grows with the file size', () {
      expect(BlockSize.getBlockSizeForFileSize(0), 2 * _mb);
      expect(BlockSize.getBlockSizeForFileSize(10 * _mb - 1), 2 * _mb);
      expect(BlockSize.getBlockSizeForFileSize(10 * _mb), 4 * _mb);
      expect(BlockSize.getBlockSizeForFileSize(100 * _mb - 1), 4 * _mb);
      expect(BlockSize.getBlockSizeForFileSize(100 * _mb), 8 * _mb);
      expect(BlockSize.getBlockSizeForFileSize(1024 * _mb - 1), 8 * _mb);
      expect(BlockSize.getBlockSizeForFileSize(1024 * _mb), 16 * _mb);
    });

    test('the web and file helpers agree on every tier', () {
      for (final size in [1, 10 * _mb, 99 * _mb, 500 * _mb, 2048 * _mb]) {
        expect(
          web.FileUtilsWeb.getBlockSize(size),
          BlockSize.getBlockSizeForFileSize(size),
          reason: 'size $size',
        );
      }
    });
  });

  group('FileUtils on a file', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('resume_upload_chunks');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('a 5 MB file is three blocks: 2 MB, 2 MB and 1 MB', () async {
      final data = _bytes(5 * _mb);
      final path = (await File('${tmp.path}/a.bin').writeAsBytes(data)).path;

      expect(await FileUtils.getFileSize(path), 5 * _mb);
      expect(await FileUtils.getBlockSize(path), 2 * _mb);
      expect(await FileUtils.getBlockCount(path), 3);
      expect(await FileUtils.getBlockDataSize(path, 0), 2 * _mb);
      expect(await FileUtils.getBlockDataSize(path, 1), 2 * _mb);
      expect(await FileUtils.getBlockDataSize(path, 2), 1 * _mb);
    });

    test('an exact multiple of the block size has no short block', () async {
      final data = _bytes(4 * _mb);
      final path = (await File('${tmp.path}/b.bin').writeAsBytes(data)).path;

      expect(await FileUtils.getBlockCount(path), 2);
      expect(await FileUtils.getBlockDataSize(path, 1), 2 * _mb);
    });

    test(
      'readBlock returns each block and the blocks rebuild the file',
      () async {
        final data = _bytes(5 * _mb);
        final path = (await File('${tmp.path}/c.bin').writeAsBytes(data)).path;

        final blocks = [
          for (var i = 0; i < 3; i++) await FileUtils.readBlock(path, i),
        ];

        expect(blocks[0], data.sublist(0, 2 * _mb));
        expect(blocks[1], data.sublist(2 * _mb, 4 * _mb));
        expect(blocks[2], data.sublist(4 * _mb));
        final rebuilt = BytesBuilder(copy: false)
          ..add(blocks[0])
          ..add(blocks[1])
          ..add(blocks[2]);
        expect(rebuilt.takeBytes(), data);
      },
    );

    test('readBlockRange starts inside a block (partial resume)', () async {
      final data = _bytes(5 * _mb);
      final path = (await File('${tmp.path}/d.bin').writeAsBytes(data)).path;

      // Block 1 starts at 2 MB; reading from 1000 bytes into it.
      final tail = await FileUtils.readBlockRange(path, 1, 1000);

      expect(tail.length, 2 * _mb - 1000);
      expect(tail, data.sublist(2 * _mb + 1000, 4 * _mb));
    });

    test('block CRCs match the CRC of the same bytes', () async {
      final data = _bytes(5 * _mb);
      final path = (await File('${tmp.path}/e.bin').writeAsBytes(data)).path;

      for (var i = 0; i < 3; i++) {
        final block = await FileUtils.readBlock(path, i);
        expect(await FileUtils.getBlockCrc(path, i), Crc32.calculate(block));
      }
    });

    test('getFileCrc agrees with Crc32 over the whole content', () async {
      final data = _bytes(3 * _mb + 17);
      final path = (await File('${tmp.path}/f.bin').writeAsBytes(data)).path;

      expect(await FileUtils.getFileCrc(path), Crc32.calculate(data));
    });

    test('a missing file has CRC 0 and size 0', () async {
      final path = '${tmp.path}/missing.bin';

      expect(await FileUtils.getFileCrc(path), 0);
      expect(await FileUtils.getFileSize(path), 0);
    });

    test('the file ID is MD5(deviceId + CRC) and is stable', () async {
      final data = _bytes(1 * _mb);
      final path = (await File('${tmp.path}/g.bin').writeAsBytes(data)).path;
      final crc = Crc32.calculate(data);

      final fromFile = await FileUtils.generateFileId(path, 'dev');

      expect(fromFile, FileUtils.fileIdFromCrc('dev', crc));
      expect(fromFile, web.FileUtilsWeb.generateFileId(data, 'dev'));
      expect(fromFile, isNot(FileUtils.fileIdFromCrc('other', crc)));
      expect(fromFile.length, 32);
    });
  });

  group('FileUtilsWeb on bytes', () {
    test('blocks cover the bytes exactly and match the file helpers', () {
      final data = _bytes(5 * _mb);
      final count = web.FileUtilsWeb.getBlockCount(data.length);

      expect(count, 3);
      var total = 0;
      for (var i = 0; i < count; i++) {
        final block = web.FileUtilsWeb.readBlock(data, i);
        expect(block.length, web.FileUtilsWeb.getBlockDataSize(data, i));
        expect(web.FileUtilsWeb.getBlockCrc(data, i), Crc32.calculate(block));
        expect(block, data.sublist(total, total + block.length));
        total += block.length;
      }
      expect(total, data.length);
    });

    test('an exact multiple has no short final block', () {
      final data = _bytes(4 * _mb);

      expect(web.FileUtilsWeb.getBlockCount(data.length), 2);
      expect(web.FileUtilsWeb.getBlockDataSize(data, 1), 2 * _mb);
    });

    test('calculateCrc is the CRC32 of the bytes', () {
      // The standard check value for CRC-32 of "123456789".
      expect(
        web.FileUtilsWeb.calculateCrc(
          Uint8List.fromList('123456789'.codeUnits),
        ),
        0xCBF43926,
      );
    });
  });
}
