import 'package:resume_upload_sdk/resume_upload_sdk.dart';

Future<void> main() async {
  // 1. Configure and initialize the upload manager
  const config = UploadConfig(
    baseUrl: 'https://your-server.com/api/upload',
    timeoutSeconds: 30,
    maxRetries: 3,
    retryDelayMs: 1000,
  );
  await UploadManager.instance.initialize(config);

  // 2. Upload a file with progress tracking
  await UploadManager.instance.upload(
    filePath: '/path/to/file.pdf',
    onProgress: (progress) {
      print('Upload progress: ${progress.progressPercentage}');
    },
    onComplete: (result) {
      if (result.success) {
        print('Upload succeeded!');
      } else {
        print('Upload failed: ${result.errorMessage}');
      }
    },
  );

  // 3. Or create a task for manual control
  final task = UploadManager.instance.createTask(
    filePath: '/path/to/large-file.zip',
  );

  // Listen to progress
  task.progressStream.listen((progress) {
    print(progress.progressPercentage);
  });

  // Start the upload. The future completes when the upload finishes, fails or
  // is cancelled; pausing doesn't complete it.
  final done = task.start();

  // Pause if needed
  task.pause();

  // Resume later; `done` completes when the upload finishes
  task.resume();

  final result = await done;
  print(result.success ? 'Uploaded: ${result.fileUrl}' : result.errorMessage);

  // Clean up
  UploadManager.instance.dispose();
}
