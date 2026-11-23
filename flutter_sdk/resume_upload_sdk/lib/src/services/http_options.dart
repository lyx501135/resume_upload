import 'package:dio/dio.dart';

/// Request options shared by the upload tasks.
///
/// Dio throws on 4xx and 5xx responses by default. The upload code reads the
/// status code from the response instead, as it did with package:http, so
/// `validateStatus` accepts every status. The body is read as text and decoded
/// as JSON by the caller.
Options uploadRequestOptions(Map<String, String> headers) => Options(
  headers: headers,
  responseType: ResponseType.plain,
  validateStatus: (_) => true,
);
