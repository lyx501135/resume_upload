import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// In-process server speaking the same protocol as backend/python/app.py:
/// upload_file (init / status), upload_block (one block per request) and
/// uploadFileForLargeFile (finalize).
class FakeUploadServer {
  FakeUploadServer._(this._server);

  final HttpServer _server;
  final Map<String, _FileState> _files = {};

  /// When set, block uploads wait for this gate before being stored, so a test
  /// can pause or cancel while a block is in flight.
  Completer<void>? blockGate;

  /// Called when a block request arrives (before the gate).
  void Function(int index)? onBlockRequest;

  /// Number of upload_block requests received per block index.
  final Map<int, int> blockRequests = {};

  static Future<FakeUploadServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeUploadServer._(server);
    server.listen(fake._handle);
    return fake;
  }

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> close() => _server.close(force: true);

  /// Pre-seeds uploaded blocks for [fid], as if an earlier session uploaded them.
  void seedBlocks(String fid, Map<int, Uint8List> blocks) =>
      _files.putIfAbsent(fid, _FileState.new).blocks.addAll(blocks);

  /// The file assembled from the stored blocks.
  Uint8List assembled(String fid) {
    final state = _files[fid]!;
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < state.blockCount; i++) {
      out.add(state.blocks[i]!);
    }
    return out.takeBytes();
  }

  Future<void> _handle(HttpRequest request) async {
    final q = request.uri.queryParameters;
    final body = await request
        .fold<BytesBuilder>(BytesBuilder(), (b, d) => b..add(d))
        .then((b) => b.takeBytes());
    Map<String, dynamic>? data;
    switch (request.uri.path) {
      case '/api/v1/large_file/upload_file':
        final state = _files.putIfAbsent(q['fid']!, _FileState.new);
        state
          ..fid = q['fid']!
          ..fcrc = q['fcrc']!
          ..fileSize = int.parse(q['fileSize']!)
          ..blockCount = int.parse(q['blockCount']!)
          ..blockSize = int.parse(q['blockSize']!);
        data = state.toJson();
      case '/api/v1/large_file/upload_block':
        final index = int.parse(q['index']!);
        blockRequests[index] = (blockRequests[index] ?? 0) + 1;
        onBlockRequest?.call(index);
        if (blockGate != null) await blockGate!.future;
        final state = _files[q['fid']!]!;
        state.blocks[index] = body;
        data = state.toJson();
      case '/api/v1/uploadFileForLargeFile':
        final state = _files[q['fid']!]!;
        if (!state.isComplete) {
          request.response.statusCode = 400;
          request.response.write(
            jsonEncode({
              'rtnCode': '9999999',
              'message': 'File upload not completed',
            }),
          );
          await request.response.close();
          return;
        }
        data = {
          'result': 1,
          'file': {
            'id': 42,
            'fileUrl': '/storage/completed/${state.fid}',
            'fileSize': state.fileSize,
          },
        };
      default:
        request.response.statusCode = 404;
        await request.response.close();
        return;
    }
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode({'rtnCode': '0000000', 'bizData': data, 'message': 'Success'}),
    );
    await request.response.close();
  }
}

class _FileState {
  String fid = '';
  String fcrc = '0';
  int fileSize = 0;
  int blockCount = 0;
  int blockSize = 0;
  final Map<int, Uint8List> blocks = {};

  bool get isComplete =>
      blockCount > 0 &&
      List.generate(blockCount, (i) => i).every(blocks.containsKey);

  Map<String, dynamic> toJson() => {
    'fid': fid,
    'fcrc': fcrc,
    'fileSize': fileSize,
    'blockCount': blockCount,
    'blockSize': blockSize,
    'fstatus': isComplete ? 1 : (blocks.isEmpty ? 0 : 2),
    'blockMap': {
      for (final i in blocks.keys)
        '$i': {
          'index': i,
          'crc': '0',
          'status': 1,
          'range': '${blocks[i]!.length}-${blocks[i]!.length}',
        },
    },
  };
}
