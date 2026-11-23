// Main screen with a fake Dio: the storage calls go through the fake adapter,
// so no request leaves the test.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resume_upload_example/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_dio_adapter.dart';

const _listPath = '/api/v1/files';

/// Pumps frames for a while. The page has a 1-second memory timer, so
/// pumpAndSettle would never settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late FakeDioAdapter adapter;
  late Dio dio;

  /// Answers the list call with [files] and each delete with its status code
  /// from [deleteStatus] (default 200).
  void serve({
    List<String> files = const ['a', 'b'],
    int listStatus = 200,
    Map<String, int> deleteStatus = const {},
    bool connectionError = false,
  }) {
    adapter = FakeDioAdapter((request) {
      if (connectionError) {
        throw DioException.connectionError(
          requestOptions: request.options,
          reason: 'no route to host',
        );
      }
      if (request.method == 'GET' && request.path == _listPath) {
        if (listStatus != 200) return ResponseBody.fromString('', listStatus);
        return jsonResponse({
          'bizData': [
            for (final fid in files) {'fid': fid},
          ],
        });
      }
      if (request.method == 'DELETE' &&
          request.path.startsWith('$_listPath/')) {
        final fid = request.path.substring('$_listPath/'.length);
        return ResponseBody.fromString('', deleteStatus[fid] ?? 200);
      }
      return ResponseBody.fromString('', 404);
    });
    dio = fakeDio(adapter);
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: UploadPage(dio: dio)));
    await _settle(tester);
  }

  Future<void> clearStorage(WidgetTester tester, {bool confirm = true}) async {
    await tester.tap(find.byTooltip('Clear all uploaded files'));
    await _settle(tester);
    expect(find.text('Clear Storage'), findsOneWidget);
    await tester.tap(find.text(confirm ? 'Delete All' : 'Cancel'));
    await _settle(tester);
  }

  List<RecordedRequest> requestsTo(String method, String path) => adapter
      .requests
      .where((r) => r.method == method && r.path == path)
      .toList();

  setUp(() {
    // UploadManager.initialize stores a device ID in SharedPreferences.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('initializing the SDK makes no server calls', (tester) async {
    serve();

    await pumpPage(tester);

    expect(find.text('SDK Initialized'), findsOneWidget);
    expect(adapter.requests, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Clear storage lists the files and deletes each one', (
    tester,
  ) async {
    serve(files: ['a', 'b']);
    await pumpPage(tester);

    await clearStorage(tester);

    expect(find.text('Deleted 2 files from server'), findsOneWidget);
    expect(adapter.requests.map((r) => r.method), ['GET', 'DELETE', 'DELETE']);
    expect(
      requestsTo('GET', _listPath).single.uri.toString(),
      'http://localhost:8080/api/v1/files',
    );
    expect(
      requestsTo('DELETE', '$_listPath/a').single.uri.toString(),
      'http://localhost:8080/api/v1/files/a',
    );
    expect(requestsTo('DELETE', '$_listPath/b'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a delete that fails is not counted', (tester) async {
    serve(files: ['a', 'b'], deleteStatus: {'b': 500});
    await pumpPage(tester);

    await clearStorage(tester);

    expect(find.text('Deleted 1 files from server'), findsOneWidget);
    expect(requestsTo('DELETE', '$_listPath/b'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an empty list deletes nothing and reports zero', (tester) async {
    serve(files: const []);
    await pumpPage(tester);

    await clearStorage(tester);

    expect(find.text('Deleted 0 files from server'), findsOneWidget);
    expect(adapter.requests.map((r) => r.method), ['GET']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the confirmation sends nothing', (tester) async {
    serve();
    await pumpPage(tester);

    await clearStorage(tester, confirm: false);

    expect(adapter.requests, isEmpty);
    expect(find.text('Clear Storage'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a list call returning HTTP 500 shows the list error', (
    tester,
  ) async {
    serve(listStatus: 500);
    await pumpPage(tester);

    await clearStorage(tester);

    expect(find.text('Failed to get file list from server'), findsOneWidget);
    expect(requestsTo('DELETE', '$_listPath/a'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a connection error shows the connection error', (tester) async {
    serve(connectionError: true);
    await pumpPage(tester);

    await clearStorage(tester);

    expect(find.textContaining('Error connecting to server:'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the server URL field is the base of the storage calls', (
    tester,
  ) async {
    serve(files: ['a']);
    await pumpPage(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Server URL'),
      'http://storage.test:9000',
    );
    await clearStorage(tester);

    expect(
      requestsTo('GET', _listPath).single.uri.toString(),
      'http://storage.test:9000/api/v1/files',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disposing the page does not close a Dio it was given', (
    tester,
  ) async {
    serve();
    await pumpPage(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);

    expect(adapter.closed, isFalse);
  });
}
