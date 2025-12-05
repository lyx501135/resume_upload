/// Upload status enumeration.
enum UploadStatus {
  /// Upload has not started yet.
  notStarted(0),

  /// Upload is in progress.
  inProgress(1),

  /// Upload is paused.
  paused(2),

  /// Upload completed successfully.
  completed(3),

  /// Upload failed due to an error.
  failed(4),

  /// Upload was cancelled.
  cancelled(5);

  final int value;
  const UploadStatus(this.value);

  static UploadStatus fromValue(int value) {
    switch (value) {
      case 0:
        return UploadStatus.notStarted;
      case 1:
        return UploadStatus.inProgress;
      case 2:
        return UploadStatus.paused;
      case 3:
        return UploadStatus.completed;
      case 4:
        return UploadStatus.failed;
      case 5:
        return UploadStatus.cancelled;
      default:
        return UploadStatus.notStarted;
    }
  }
}

/// File status from server response.
enum FileStatus {
  /// File upload not started.
  notStarted(0),

  /// File upload completed and verified.
  completed(1),

  /// File upload incomplete.
  incomplete(2),

  /// File is abnormal/corrupted.
  abnormal(-1);

  final int value;
  const FileStatus(this.value);

  static FileStatus fromValue(int value) {
    switch (value) {
      case 0:
        return FileStatus.notStarted;
      case 1:
        return FileStatus.completed;
      case 2:
        return FileStatus.incomplete;
      case -1:
        return FileStatus.abnormal;
      default:
        return FileStatus.notStarted;
    }
  }
}

/// Block status from server response.
enum BlockStatus {
  /// Block not uploaded.
  notUploaded(0),

  /// Block uploaded successfully.
  uploaded(1),

  /// Block partially uploaded.
  partial(2),

  /// Block upload error.
  error(-1);

  final int value;
  const BlockStatus(this.value);

  static BlockStatus fromValue(int value) {
    switch (value) {
      case 0:
        return BlockStatus.notUploaded;
      case 1:
        return BlockStatus.uploaded;
      case 2:
        return BlockStatus.partial;
      case -1:
        return BlockStatus.error;
      default:
        return BlockStatus.notUploaded;
    }
  }
}
