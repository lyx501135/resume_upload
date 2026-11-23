## 1.3.0

- Requires Dart 3.14 / Flutter 3.50 or newer (`sdk: ^3.14.0`).

- Replaced the `http` dependency with `dio`. Requests keep the same URLs,
  query parameters, headers, timeouts and retry behaviour; a non-2xx response
  is still a failed block or step, not an exception.
- **API change:** `UploadTask`, `UploadTaskWeb` and `UploadManager.initialize`
  take an optional `Dio dio` argument, so you can share a client or fake the
  server in tests. Without it, each task creates its own `Dio` and closes it on
  `dispose()`. A `Dio` you pass in is never closed by the SDK.
- The data models (`UploadConfig`, `UploadProgress`, `UploadResult`,
  `BlockInfo`, `FileInfoResponse`) are generated with freezed and
  json_serializable. The JSON keys and values are unchanged. They now also have
  `==`/`hashCode`, and `FileInfoResponse` has a `toJson()`.
- **Behavior change:** `copyWith(field: null)` now sets a nullable field to
  `null`. Previously a `null` argument kept the current value.

## 1.2.1

- README: the installation snippet no longer hard-codes a version number, so it
  stays correct in future releases.

## 1.2.0

Pause, resume and cancel now work as documented.

- **Behavior change:** `UploadTask.start()` and `resume()` return a future that
  completes only when the upload finishes, fails or is cancelled. Pausing no
  longer completes it with a failed result; `resume()` returns the same future.
- Fixed pausing: the task was marked failed as soon as the upload loop saw the
  pause, so `resume()` failed with "Upload is not paused" and
  `UploadManager.resumeTask()` couldn't find the task.
- Fixed automatic resume after a network loss, which never happened because
  network monitoring was stopped when the upload paused.
- Fixed `cancel()` throwing "Bad state: Future already completed".
- Fixed `pause()` and `cancel()` changing the status of a finished upload.
- Blocks the server already has are skipped instead of uploaded again.
- Uploaded bytes come from the server's block map, so resuming no longer counts
  the last block at full size, and the speed only counts successful blocks.
- An empty or missing file fails immediately with "File is empty or does not
  exist" instead of "Failed to finalize upload" (and a NaN progress value).
- `dispose()` during an upload stops it and completes pending futures instead of
  throwing when events were added to closed streams.
- The whole-file CRC32 is computed once per `start()` instead of two or three
  times, plus once more on every resume.
- Added `FileUtils.fileIdFromCrc`.
- `UploadTaskWeb` gets the same pause, resume and cancel fixes.
- Docs: Web isn't listed as a supported platform (the package uses `dart:io`);
  the README examples show the new `start()`/`resume()` behavior.
- Added tests against an in-process server that speaks the backend protocol.

## 1.1.1

- Shortened the `pubspec.yaml` description to fit pub.dev's 60-180 character limit.
- Fixed all `flutter analyze` warnings and lints (unused private declarations, missing curly braces, string interpolation, unresolved type inference) for a clean static analysis pass.
- Removed an unused/obsolete `enable-experiment` entry from `analysis_options.yaml`.
- Fixed outdated API usage in `example/example.dart`.
- Applied `dart format` across the package.

## 1.1.0

- Upgraded `connectivity_plus` to `^7.3.1` (from `^5.0.2`) for Swift Package Manager support and current platform compatibility.
- Adapted the internal connectivity handler to connectivity_plus 6+'s `List<ConnectivityResult>` stream and callback API.

## 1.0.2

- Fixed Chinese documentation anchor link on pub.dev.

## 1.0.1

- Improved README with API reference tables and Chinese documentation.

## 1.0.0

- Initial release.
- Chunk-based resumable file uploads.
- Automatic resume on network interruption.
- Pause, resume, and cancel support.
- Upload progress tracking with stream-based callbacks.
- CRC32 integrity verification.
- Cross-platform support: iOS, Android, macOS, Windows, Linux, and Web.
- Configurable chunk size, retry policy, and timeouts.
- Singleton `UploadManager` for managing multiple concurrent uploads.
