# Resume Upload

[中文文档](README_zh.md)

A multi-platform SDK for resumable, chunk-based file uploads with automatic retry and integrity verification.

[![pub package](https://img.shields.io/pub/v/resume_upload_sdk.svg)](https://pub.dev/packages/resume_upload_sdk)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

## Overview

Resume Upload provides a Flutter SDK that handles large file uploads reliably on iOS, Android, macOS, Windows and Linux. Files are split into chunks, uploaded individually with CRC32 verification, and automatically resumed if interrupted by network issues or app restarts.

## Features

- **Resumable uploads** - Automatically resumes from the last successful chunk
- **Chunk-based** - Configurable block sizes (2MB / 4MB / 8MB / 16MB)
- **Integrity verification** - CRC32 checksums on every chunk
- **Progress tracking** - Real-time progress callbacks
- **Pause / Resume / Cancel** - Full upload lifecycle control
- **Automatic retry** - Configurable retry count and delay
- **Concurrent uploads** - Manage multiple uploads simultaneously

## Project Structure

```
resume_upload/
├── flutter_sdk/          # Cross-platform Flutter/Dart SDK (pub.dev package)
├── example_app/          # Flutter example application
└── backend/python/       # Flask backend server
```

## Quick Start

```yaml
dependencies:
  resume_upload_sdk: 
```

```dart
import 'package:resume_upload_sdk/resume_upload_sdk.dart';

await UploadManager.instance.initialize(
  UploadConfig(baseUrl: 'https://your-server.com/api/upload'),
);

final result = await UploadManager.instance.upload(
  filePath: '/path/to/file.pdf',
  onProgress: (progress) => print('${progress.percentage}%'),
);
```

## Backend

A Python Flask server is included for development and testing. It handles chunk receiving, verification, and file merging.

```bash
cd backend/python
pip install -r requirements.txt
python app.py
```

The server runs on `http://localhost:8080` with the following endpoints:

| Endpoint                          | Method | Description         |
| --------------------------------- | ------ | ------------------- |
| `/api/v1/large_file/upload_file`  | POST   | Initialize upload   |
| `/api/v1/large_file/upload_block` | POST   | Upload a chunk      |
| `/api/v1/uploadFileForLargeFile`  | POST   | Finalize and merge  |
| `/api/v1/files`                   | GET    | List uploaded files |
| `/api/v1/files/<fid>`             | GET    | Get file info       |
| `/api/v1/files/<fid>`             | DELETE | Delete a file       |
| `/health`                         | GET    | Health check        |

## Documentation

- [Flutter SDK README](flutter_sdk/resume_upload_sdk/README.md)

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
