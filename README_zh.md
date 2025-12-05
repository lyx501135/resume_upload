# Resume Upload

[English](README.md)

跨平台断点续传 SDK，支持分块上传、自动重试和完整性校验。

[![pub package](https://img.shields.io/pub/v/resume_upload_sdk.svg)](https://pub.dev/packages/resume_upload_sdk)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

## 概述

Resume Upload 提供了一个 Flutter SDK，支持在 iOS、Android、macOS、Windows、Linux 上可靠地上传大文件。文件被分割成多个块，逐块上传并进行 CRC32 校验，网络中断或应用重启后可自动断点续传。

## 功能特性

- **断点续传** - 从上次成功上传的分块自动恢复
- **分块上传** - 可配置分块大小（2MB / 4MB / 8MB / 16MB）
- **完整性校验** - 每个分块进行 CRC32 校验
- **进度跟踪** - 实时上传进度回调
- **暂停 / 恢复 / 取消** - 完整的上传生命周期控制
- **自动重试** - 可配置重试次数和延迟
- **并发上传** - 同时管理多个上传任务

## 项目结构

```
resume_upload/
├── flutter_sdk/          # 跨平台 Flutter/Dart SDK（pub.dev 包）
├── example_app/          # Flutter 示例应用
└── backend/python/       # Flask 后端服务
```

## 快速开始

```yaml
dependencies:
  resume_upload_sdk: ^1.0.0
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

## 后端服务

项目包含一个 Python Flask 后端服务，用于开发和测试。支持分块接收、校验和文件合并。

```bash
cd backend/python
pip install -r requirements.txt
python app.py
```

服务运行在 `http://localhost:8080`，提供以下接口：

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/v1/large_file/upload_file` | POST | 初始化上传 |
| `/api/v1/large_file/upload_block` | POST | 上传分块 |
| `/api/v1/uploadFileForLargeFile` | POST | 合并分块 |
| `/api/v1/files` | GET | 获取文件列表 |
| `/api/v1/files/<fid>` | GET | 获取文件信息 |
| `/api/v1/files/<fid>` | DELETE | 删除文件 |
| `/health` | GET | 健康检查 |

## 文档

- [Flutter SDK 文档](flutter_sdk/resume_upload_sdk/README.md)

## 许可证

基于 Apache License 2.0 开源。详见 [LICENSE](LICENSE)。
