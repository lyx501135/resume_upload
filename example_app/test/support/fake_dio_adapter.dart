import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A request as the fake adapter received it, with its body fully read.
class RecordedRequest {
  RecordedRequest(this.options, this.body);

  final RequestOptions options;
  final Uint8List body;

  String get method => options.method;
  Uri get uri => options.uri;
  String get path => options.uri.path;
}

/// An [HttpClientAdapter] that answers every request in-process.
///
/// Nothing reaches the network. [handler] builds the response for each request,
/// and may throw a [DioException] to simulate a transport failure.
class FakeDioAdapter implements HttpClientAdapter {
  FakeDioAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RecordedRequest request) handler;

  /// Every request received, in order.
  final List<RecordedRequest> requests = [];

  /// Whether [close] was called (by a Dio that owns this adapter).
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = BytesBuilder(copy: false);
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.add(chunk);
      }
    }
    final request = RecordedRequest(options, body.takeBytes());
    requests.add(request);
    return handler(request);
  }

  @override
  void close({bool force = false}) => closed = true;
}

/// A Dio whose only transport is [adapter].
Dio fakeDio(FakeDioAdapter adapter) => Dio()..httpClientAdapter = adapter;

/// A JSON response with [status] and [body].
ResponseBody jsonResponse(Object body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
