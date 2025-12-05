# resume_upload_sdk

[![pub package](https://img.shields.io/pub/v/resume_upload_sdk.svg)](https://pub.dev/packages/resume_upload_sdk)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/lyx501135/resume_upload/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue)](https://pub.dev/packages/resume_upload_sdk)

A production-ready Flutter SDK for **resumable, chunk-based file uploads**. Never lose upload progress again - automatically resumes from the last successful chunk after network interruptions or app restarts.

[中文文档](#chinese-docs)

---

## Why resume_upload_sdk?

Uploading large files over unreliable networks is painful. A single dropped connection means starting over from scratch. This SDK solves that by:

- Splitting files into chunks and uploading them independently
- Tracking which chunks succeeded, so interrupted uploads resume instantly
- Verifying every chunk with CRC32 checksums to guarantee data integrity

Whether you're building a cloud storage app, a media uploader, or an enterprise file management system, this SDK handles the hard parts so you can focus on your product.

## Features

| Feature | Description |
|---------|-------------|
| **Resumable uploads** | Automatically resumes from the last successful chunk after interruption |
| **Chunk-based** | Configurable block sizes (2MB / 4MB / 8MB / 16MB) for optimal performance |
| **CRC32 verification** | Integrity checks on every chunk to prevent data corruption |
| **Progress tracking** | Real-time progress via stream-based callbacks |
| **Pause / Resume / Cancel** | Full upload lifecycle control |
| **Automatic retry** | Configurable retry count and delay for transient failures |
| **Concurrent uploads** | Manage multiple upload tasks simultaneously |
| **Cross-platform** | iOS, Android, macOS, Windows, and Linux |

## Getting Started

### Installation

```yaml
dependencies:
  resume_upload_sdk: ^1.1.1
```

```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:resume_upload_sdk/resume_upload_sdk.dart';

// 1. Initialize once
await UploadManager.instance.initialize(
  UploadConfig(baseUrl: 'https://your-server.com/api/upload'),
);

// 2. Upload a file with progress tracking
await UploadManager.instance.upload(
  filePath: '/path/to/file.pdf',
  onProgress: (progress) {
    print(progress.progressPercentage);
  },
  onComplete: (result) {
    print('Success: ${result.success}');
  },
);
```

### Advanced Usage

#### Full upload lifecycle control

```dart
final task = UploadManager.instance.createTask(filePath: '/path/to/file.pdf');

// Listen to progress
task.progressStream.listen((progress) {
  print(progress.progressPercentage);
});

// Start upload. The future completes when the upload finishes, fails or is
// cancelled. Pausing doesn't complete it.
final done = task.start();

// Pause when needed (e.g., user switches to background)
task.pause();

// Resume later: the upload continues and `done` completes when it finishes
task.resume();

// Or cancel: `done` completes with a failed result ('Upload cancelled')
// task.cancel();

final result = await done;
```

#### Custom configuration per upload

```dart
final config = UploadConfig(
  baseUrl: 'https://your-server.com/api/upload',
  timeoutSeconds: 60,
  maxRetries: 5,
  retryDelayMs: 2000,
  headers: {'Authorization': 'Bearer token'},
  userId: 'user-123',
);

await UploadManager.instance.upload(
  filePath: '/path/to/large-file.zip',
  config: config,
);
```

## API Reference

### UploadConfig

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `baseUrl` | `String` | required | Upload server base URL |
| `timeoutSeconds` | `int` | `30` | HTTP request timeout |
| `maxRetries` | `int` | `3` | Max retry attempts for failed chunks |
| `retryDelayMs` | `int` | `1000` | Delay between retries (ms) |
| `headers` | `Map<String, String>?` | `null` | Custom HTTP headers |
| `userId` | `String?` | `null` | User identifier |

### UploadManager

| Method | Description |
|--------|-------------|
| `initialize(config)` | Initialize with default configuration |
| `upload(filePath, ...)` | Upload a file with callbacks |
| `createTask(filePath)` | Create a task for manual control |
| `pauseTask(taskId)` | Pause a specific upload |
| `resumeTask(taskId)` | Resume a paused upload |
| `cancelTask(taskId)` | Cancel and remove an upload |
| `cancelAllTasks()` | Cancel all active uploads |

## Server Requirements

This SDK expects a backend that implements the chunked upload protocol:

1. **Init upload** - Register a file and receive upload metadata
2. **Upload chunk** - Upload individual chunks with CRC32 verification
3. **Merge chunks** - Merge all chunks into the final file

A ready-to-use Python Flask backend is included in the [GitHub repository](https://github.com/lyx501135/resume_upload/tree/main/backend).

## License

Apache License 2.0 - see [LICENSE](https://github.com/lyx501135/resume_upload/blob/main/LICENSE) for details.

---

<a id="chinese-docs"></a>

# 中文文档

一个生产级 Flutter SDK，用于**断点续传分块上传**。再也不用担心上传进度丢失 - 网络中断或应用重启后自动从上次成功的分块恢复。

## 为什么选择 resume_upload_sdk？

在不稳定的网络环境下上传大文件是一件痛苦的事情。一次连接中断就意味着从头开始。这个 SDK 通过以下方式解决了这个问题：

- 将文件分割成多个块，独立上传
- 跟踪每个块的上传状态，中断后立即恢复
- 使用 CRC32 校验每个块，保证数据完整性

无论你是在构建云存储应用、媒体上传工具，还是企业文件管理系统，这个 SDK 都能帮你处理复杂的部分。

## 功能特性

| 功能 | 说明 |
|------|------|
| **断点续传** | 中断后自动从上次成功的分块恢复 |
| **分块上传** | 可配置分块大小（2MB / 4MB / 8MB / 16MB） |
| **CRC32 校验** | 每个分块进行完整性校验，防止数据损坏 |
| **进度跟踪** | 基于 Stream 的实时进度回调 |
| **暂停 / 恢复 / 取消** | 完整的上传生命周期控制 |
| **自动重试** | 可配置重试次数和延迟 |
| **并发上传** | 同时管理多个上传任务 |
| **跨平台** | iOS、Android、macOS、Windows、Linux |

## 快速开始

### 安装

```yaml
dependencies:
  resume_upload_sdk: ^1.1.1
```

```bash
flutter pub get
```

### 基本用法

```dart
import 'package:resume_upload_sdk/resume_upload_sdk.dart';

// 1. 初始化（只需一次）
await UploadManager.instance.initialize(
  UploadConfig(baseUrl: 'https://your-server.com/api/upload'),
);

// 2. 上传文件并跟踪进度
await UploadManager.instance.upload(
  filePath: '/path/to/file.pdf',
  onProgress: (progress) {
    print(progress.progressPercentage);
  },
  onComplete: (result) {
    print('上传成功: ${result.success}');
  },
);
```

### 高级用法

#### 完整的上传生命周期控制

```dart
final task = UploadManager.instance.createTask(filePath: '/path/to/file.pdf');

// 监听进度
task.progressStream.listen((progress) {
  print(progress.progressPercentage);
});

// 开始上传。上传完成、失败或被取消时 future 才会完成，暂停不会让它完成。
final done = task.start();

// 暂停（例如用户切到后台）
task.pause();

// 稍后恢复：上传继续进行，完成后 `done` 返回结果
task.resume();

// 或者取消：`done` 返回失败结果（'Upload cancelled'）
// task.cancel();

final result = await done;
```

## 服务端要求

SDK 需要后端实现分块上传协议：

1. **初始化上传** - 注册文件并返回上传元数据
2. **上传分块** - 上传单个分块并进行 CRC32 校验
3. **合并分块** - 将所有分块合并为最终文件

[GitHub 仓库](https://github.com/lyx501135/resume_upload/tree/main/backend) 中包含一个可直接使用的 Python Flask 后端。

## 许可证

Apache License 2.0 - 详见 [LICENSE](https://github.com/lyx501135/resume_upload/blob/main/LICENSE)。
