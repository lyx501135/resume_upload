import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:resume_upload_sdk/resume_upload_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Resume Upload Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        fontFamily: 'SF Pro Display',
      ),
      themeMode: ThemeMode.system,
      home: const UploadPage(),
    );
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key, this.dio});

  /// Client for the upload SDK and the server calls. Defaults to a new [Dio].
  final Dio? dio;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _serverUrlController = TextEditingController(
    text: 'http://localhost:8080',
  );

  /// Closed in [dispose] only when this page created it.
  late final Dio _dio = widget.dio ?? Dio();

  /// Reads the body as text and does not throw on an error status, so the
  /// status code is checked by hand.
  static final _plainOptions = Options(
    responseType: ResponseType.plain,
    validateStatus: (_) => true,
  );

  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;

  UploadTask? _currentTask;
  UploadProgress? _currentProgress;
  StreamSubscription<UploadProgress>? _progressSubscription;
  UploadResult? _lastResult;

  bool _isInitialized = false;
  bool _isUploading = false;
  bool _showLogs = true;

  // Logs list
  final List<UploadLog> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  StreamSubscription<UploadLog>? _logSubscription;

  // Memory monitoring (basic timer-based)
  int _currentMemoryMB = 0;
  int _peakMemoryMB = 0;
  Timer? _memoryTimer;

  // SDK Memory monitoring (advanced stream-based)
  StreamSubscription<MemorySnapshot>? _memorySubscription;
  MemorySnapshot? _latestMemorySnapshot;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
    _startMemoryMonitoring();
  }

  void _startMemoryMonitoring() {
    _updateMemory();
    _memoryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMemory();
    });
  }

  void _updateMemory() {
    if (!kIsWeb) {
      try {
        final rss = ProcessInfo.currentRss;
        final memMB = (rss / (1024 * 1024)).round();
        if (!mounted) return;
        setState(() {
          _currentMemoryMB = memMB;
          if (memMB > _peakMemoryMB) {
            _peakMemoryMB = memMB;
          }
        });
      } catch (e) {
        // Ignore errors on platforms without ProcessInfo
      }
    }
  }

  Future<void> _initializeSDK() async {
    try {
      await UploadManager.instance.initialize(
        UploadConfig(
          baseUrl: _serverUrlController.text,
          timeoutSeconds: 60,
          maxRetries: 3,
          userId: '1',
          productCode: 'demo',
          bizSystem: 'demo',
        ),
        dio: _dio,
      );
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      _showError('Failed to initialize SDK: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.any);

      if (file != null) {
        setState(() {
          _selectedFilePath = file.path;
          _selectedFileName = file.name;
          _selectedFileSize = file.lengthSync();
          _lastResult = null;
          _currentProgress = null;
          _logs.clear();
          _peakMemoryMB = _currentMemoryMB;
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _startUpload() async {
    if (_selectedFilePath == null) {
      _showError('Please select a file first');
      return;
    }

    setState(() {
      _isUploading = true;
      _lastResult = null;
      _logs.clear();
      _peakMemoryMB = _currentMemoryMB;
    });

    try {
      // Re-initialize with current server URL
      await UploadManager.instance.initialize(
        UploadConfig(
          baseUrl: _serverUrlController.text,
          timeoutSeconds: 60,
          maxRetries: 3,
          userId: '1',
          productCode: 'demo',
          bizSystem: 'demo',
        ),
        dio: _dio,
      );

      // Release the previous task before starting a new one.
      await _progressSubscription?.cancel();
      _currentTask?.dispose();
      final task = _currentTask = UploadManager.instance.createTask(
        filePath: _selectedFilePath!,
      );

      // Listen to progress updates
      _progressSubscription = task.progressStream.listen((progress) {
        if (mounted) setState(() => _currentProgress = progress);
      });

      // Listen to log updates
      _logSubscription?.cancel();
      _logSubscription = task.logStream.listen((log) {
        if (!mounted) return;
        setState(() {
          _logs.add(log);
        });
        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      });

      // Listen to memory snapshots from SDK
      _memorySubscription?.cancel();
      _memorySubscription = task.memoryStream.listen((snapshot) {
        if (!mounted) return;
        setState(() {
          _latestMemorySnapshot = snapshot;
        });
      });

      // Completes when the upload finishes, fails or is cancelled. Pausing
      // keeps it pending, and resuming continues the same upload.
      final result = await task.start();
      if (!mounted) return;

      setState(() {
        _lastResult = result;
        _isUploading = false;
      });

      if (result.success) {
        _showSuccess('Upload completed successfully!');
      } else if (result.errorMessage != 'Upload cancelled') {
        _showError('Upload failed: ${result.errorMessage}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      _showError('Upload error: $e');
    }
  }

  void _pauseUpload() {
    _currentTask?.pause();
  }

  // The result is handled where start() is awaited in _startUpload.
  void _resumeUpload() {
    _currentTask?.resume();
  }

  void _cancelUpload() {
    _currentTask?.cancel();
    setState(() {
      _isUploading = false;
      _currentTask = null;
      _currentProgress = null;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _selectedFileSize = null;
      _currentProgress = null;
      _lastResult = null;
      _logs.clear();
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _openFile() async {
    if (_lastResult?.fileUrl != null) {
      final fullUrl = '${_serverUrlController.text}${_lastResult!.fileUrl}';
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _openFolder() async {
    // The backend stores completed files in: backend/python/storage/completed/
    // Use absolute path since we know the project location
    const basePath = '/Users/yuxiliu/Desktop/Temp/resume_upload/backend/python/storage/completed';

    // Show a dialog with the path and copy option (more reliable than trying to open with sandbox)
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_open, color: Colors.blue),
            SizedBox(width: 8),
            Text('Storage Folder'),
          ],
        ),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            const Text('Uploaded files are stored at:'),
            const SizedBox(height: 12),
            Container(
              padding: const .all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: .circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const SelectableText(
                basePath,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Due to macOS sandbox restrictions, please open this folder manually in Finder.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: basePath));
              Navigator.pop(context);
              _showSuccess('Path copied to clipboard!');
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Path'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearStorage() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Storage'),
        content: const Text(
          'This will delete all uploaded files from the server.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Get list of all files from server
      final listUri = Uri.parse('${_serverUrlController.text}/api/v1/files');
      final listResponse = await _dio.getUri<String>(
        listUri,
        options: _plainOptions,
      );

      if (listResponse.statusCode == 200) {
        final json = jsonDecode(listResponse.data ?? '');
        final files = json['bizData'] as List<dynamic>? ?? [];

        int deletedCount = 0;

        // Delete each file via API
        for (final file in files) {
          final fid = file['fid'] as String?;
          if (fid != null) {
            try {
              final deleteUri = Uri.parse('${_serverUrlController.text}/api/v1/files/$fid');
              final deleteResponse = await _dio.deleteUri<String>(
                deleteUri,
                options: _plainOptions,
              );
              if (deleteResponse.statusCode == 200) {
                deletedCount++;
              }
            } catch (e) {
              print('Error deleting file $fid: $e');
            }
          }
        }

        _showSuccess('Deleted $deletedCount files from server');
      } else {
        _showError('Failed to get file list from server');
      }
    } catch (e) {
      _showError('Error connecting to server: $e');
    }

    // Reset UI state
    setState(() {
      _lastResult = null;
      _currentProgress = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: .topLeft,
            end: .bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withValues(alpha: 0.95),
              colorScheme.primaryContainer.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const .all(24),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                // Header
                _buildHeader(theme, colorScheme),
                const SizedBox(height: 24),

                // Memory Monitor
                _buildMemoryMonitor(theme, colorScheme),
                const SizedBox(height: 24),

                // Server Configuration
                _buildServerConfig(theme, colorScheme),
                const SizedBox(height: 24),

                // File Selection
                _buildFileSelection(theme, colorScheme),
                const SizedBox(height: 24),

                // Upload Progress
                if (_currentProgress != null || _isUploading) _buildProgressSection(theme, colorScheme),

                // Upload Result
                if (_lastResult != null) _buildResultSection(theme, colorScheme),

                const SizedBox(height: 24),

                // Upload Controls
                _buildControls(theme, colorScheme),

                const SizedBox(height: 24),

                // Logs Section
                _buildLogsSection(theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) => Column(
      crossAxisAlignment: .start,
      children: [
        _buildHeaderTitle(theme, colorScheme),
        const SizedBox(height: 8),
        _buildInitializationBadge(),
      ],
    );

  Widget _buildHeaderTitle(ThemeData theme, ColorScheme colorScheme) => Row(
      children: [
        _buildHeaderIcon(colorScheme),
        const SizedBox(width: 16),
        _buildHeaderText(theme, colorScheme),
      ],
    );

  Widget _buildHeaderIcon(ColorScheme colorScheme) => Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: .circular(16),
      ),
      child: Icon(
        Icons.cloud_upload_rounded,
        size: 32,
        color: colorScheme.onPrimaryContainer,
      ),
    );

  Widget _buildHeaderText(ThemeData theme, ColorScheme colorScheme) => Expanded(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'Resume Upload',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: .bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'SDK Demo with Memory Monitoring',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

  Widget _buildInitializationBadge() {
    final backgroundColor = _isInitialized ? Colors.green.shade100 : Colors.orange.shade100;
    final foregroundColor = _isInitialized ? Colors.green.shade700 : Colors.orange.shade700;
    final icon = _isInitialized ? Icons.check_circle : Icons.hourglass_empty;
    final text = _isInitialized ? 'SDK Initialized' : 'Initializing...';

    return Container(
      padding: const .symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: .circular(20),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(
            icon,
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: .w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryMonitor(ThemeData theme, ColorScheme colorScheme) {
    final snapshot = _latestMemorySnapshot;
    final hasSnapshot = snapshot != null && _isUploading;

    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: .circular(16),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _buildMemoryMonitorHeader(theme, colorScheme, hasSnapshot, snapshot),
          const SizedBox(height: 12),
          _buildMemoryStatsRow(hasSnapshot, snapshot),
          if (hasSnapshot) ...[
            const SizedBox(height: 16),
            _buildMemoryDetails(snapshot, theme, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildMemoryMonitorHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasSnapshot,
    MemorySnapshot? snapshot,
  ) {
    return Row(
      children: [
        Icon(Icons.memory_rounded, color: colorScheme.tertiary, size: 24),
        const SizedBox(width: 12),
        Text(
          'Memory Monitor',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: .w600,
            color: colorScheme.onTertiaryContainer,
          ),
        ),
        const Spacer(),
        if (_isUploading) _buildHealthStatusBadge(hasSnapshot, snapshot),
      ],
    );
  }

  Widget _buildHealthStatusBadge(bool hasSnapshot, MemorySnapshot? snapshot) {
    final isHealthy = hasSnapshot && snapshot!.isHealthy;
    final statusColor = isHealthy ? Colors.green : Colors.orange;
    final statusText = hasSnapshot ? (snapshot!.isHealthy ? 'Healthy' : 'Warning') : 'Monitoring';

    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: .circular(12),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: .w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryStatsRow(bool hasSnapshot, MemorySnapshot? snapshot) => Row(
      children: [
        _buildMemoryChip('Current', '$_currentMemoryMB MB', Colors.blue),
        const SizedBox(width: 12),
        _buildMemoryChip('Peak', '$_peakMemoryMB MB', Colors.orange),
        if (hasSnapshot) ...[
          const SizedBox(width: 12),
          _buildMemoryChip(
            'Baseline',
            '${snapshot!.baselineMB} MB',
            Colors.grey,
          ),
        ],
      ],
    );

  Widget _buildMemoryDetails(
    MemorySnapshot snapshot,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _buildMemoryBar(snapshot, colorScheme),
        const SizedBox(height: 12),
        _buildMemoryDetailsRow(snapshot, theme, colorScheme),
        if (snapshot.recentSamples.length > 3) ...[
          const SizedBox(height: 12),
          _buildMiniSparkline(snapshot.recentSamples, colorScheme),
        ],
      ],
    );
  }

  Widget _buildMemoryDetailsRow(
    MemorySnapshot snapshot,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        _buildTrendIndicator(snapshot, theme),
        const SizedBox(width: 16),
        _buildDeltaIndicator(snapshot, theme),
        const SizedBox(width: 16),
        _buildBlockSizeIndicator(snapshot, colorScheme),
      ],
    );
  }

  Widget _buildBlockSizeIndicator(
    MemorySnapshot snapshot,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: .circular(8),
      ),
      child: Text(
        'Block: ${snapshot.blockSizeMB} MB',
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildMemoryBar(MemorySnapshot snapshot, ColorScheme colorScheme) {
    final maxMB = (snapshot.peakMB * 1.2).round().clamp(100, 1000);
    final percentage = (snapshot.currentMB / maxMB).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(
              '${snapshot.currentMB} MB',
              style: const TextStyle(fontSize: 12, fontWeight: .w600),
            ),
            Text(
              'max ~$maxMB MB',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: .circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: colorScheme.tertiary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 0.8
                  ? Colors.red
                  : percentage > 0.6
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(MemorySnapshot snapshot, ThemeData theme) {
    IconData icon;
    Color color;

    switch (snapshot.trend) {
      case MemoryTrend.rising:
        icon = Icons.trending_up_rounded;
        color = Colors.red;
        break;
      case MemoryTrend.falling:
        icon = Icons.trending_down_rounded;
        color = Colors.green;
        break;
      case MemoryTrend.stable:
        icon = Icons.trending_flat_rounded;
        color = Colors.blue;
        break;
      case MemoryTrend.unknown:
        icon = Icons.help_outline_rounded;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: .circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            snapshot.trendDescription,
            style: TextStyle(fontSize: 11, color: color, fontWeight: .w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaIndicator(MemorySnapshot snapshot, ThemeData theme) {
    final delta = snapshot.deltaFromBaselineMB;
    final isPositive = delta > 0;
    final color = delta.abs() > snapshot.blockSizeMB * 2 ? (isPositive ? Colors.orange : Colors.green) : Colors.grey;

    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: .circular(8),
      ),
      child: Text(
        'Δ ${isPositive ? '+' : ''}$delta MB',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: .w500,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildMiniSparkline(List<int> samples, ColorScheme colorScheme) {
    if (samples.isEmpty) return const SizedBox.shrink();

    final minVal = samples.reduce((a, b) => a < b ? a : b);
    final maxVal = samples.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 30,
      padding: const .symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: .circular(6),
      ),
      child: Row(
        children: [
          Text(
            'Recent: ',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
          Expanded(
            child: CustomPaint(
              painter: _SparklinePainter(
                samples: samples,
                minVal: minVal,
                maxVal: maxVal,
                color: colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryChip(String label, String value, Color color) => Container(
      padding: const .symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: .circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: .bold,
              color: color,
            ),
          ),
        ],
      ),
    );

  Widget _buildServerConfig(ThemeData theme, ColorScheme colorScheme) => Container(
      padding: const .all(20),
      decoration: _buildCardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _buildServerConfigHeader(theme, colorScheme),
          const SizedBox(height: 16),
          _buildServerUrlField(colorScheme),
        ],
      ),
    );

  BoxDecoration _buildCardDecoration(ColorScheme colorScheme) => BoxDecoration(
      color: colorScheme.surface,
      borderRadius: .circular(20),
      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

  Widget _buildServerConfigHeader(ThemeData theme, ColorScheme colorScheme) => Row(
      children: [
        Icon(Icons.dns_rounded, color: colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Server Configuration',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: .w600,
          ),
        ),
        const Spacer(),
        _buildStorageManagementButtons(colorScheme),
      ],
    );

  Widget _buildStorageManagementButtons(ColorScheme colorScheme) => Row(
      mainAxisSize: .min,
      children: [
        IconButton(
          onPressed: _openFolder,
          icon: const Icon(Icons.folder_open_rounded, size: 20),
          tooltip: 'Open storage folder',
          color: colorScheme.primary,
        ),
        IconButton(
          onPressed: _isUploading ? null : _clearStorage,
          icon: Icon(
            Icons.delete_sweep_rounded,
            size: 20,
            color: _isUploading ? colorScheme.onSurface.withValues(alpha: 0.3) : Colors.red,
          ),
          tooltip: 'Clear all uploaded files',
        ),
      ],
    );

  Widget _buildServerUrlField(ColorScheme colorScheme) => TextField(
      controller: _serverUrlController,
      decoration: InputDecoration(
        labelText: 'Server URL',
        hintText: 'http://localhost:8080',
        prefixIcon: const Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: .circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      enabled: !_isUploading,
    );

  Widget _buildFileSelection(ThemeData theme, ColorScheme colorScheme) => Container(
      padding: const .all(20),
      decoration: _buildCardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _buildFileSelectionHeader(theme, colorScheme),
          const SizedBox(height: 16),
          _selectedFilePath == null ? _buildFilePickerPlaceholder(theme, colorScheme) : _buildSelectedFileCard(theme, colorScheme),
        ],
      ),
    );

  Widget _buildFileSelectionHeader(ThemeData theme, ColorScheme colorScheme) => Row(
      children: [
        Icon(Icons.folder_open_rounded, color: colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          'File Selection',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: .w600,
          ),
        ),
      ],
    );

  Widget _buildFilePickerPlaceholder(ThemeData theme, ColorScheme colorScheme) => InkWell(
      onTap: _isUploading ? null : _pickFile,
      borderRadius: .circular(16),
      child: Container(
        padding: const .all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
          borderRadius: .circular(16),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to select a file',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Any file type supported',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildSelectedFileCard(ThemeData theme, ColorScheme colorScheme) => Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: .circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildFileIcon(colorScheme),
          const SizedBox(width: 16),
          _buildFileInfo(theme, colorScheme),
          if (!_isUploading) _buildClearButton(colorScheme),
        ],
      ),
    );

  Widget _buildFileIcon(ColorScheme colorScheme) => Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: .circular(12),
      ),
      child: Icon(
        _getFileIcon(_selectedFileName ?? ''),
        color: colorScheme.primary,
        size: 28,
      ),
    );

  Widget _buildFileInfo(ThemeData theme, ColorScheme colorScheme) => Expanded(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            _selectedFileName ?? 'Unknown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: .w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatFileSize(_selectedFileSize ?? 0),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

  Widget _buildClearButton(ColorScheme colorScheme) => IconButton(
      onPressed: _clearSelection,
      icon: const Icon(Icons.close_rounded),
      color: colorScheme.error,
    );

  Widget _buildProgressSection(ThemeData theme, ColorScheme colorScheme) {
    final progress = _currentProgress;

    return Container(
      margin: const .only(bottom: 24),
      padding: const .all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: .circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _buildProgressHeader(theme, colorScheme, progress),
          const SizedBox(height: 20),
          _buildProgressBar(colorScheme, progress),
          const SizedBox(height: 12),
          _buildProgressDetails(theme, colorScheme, progress),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    UploadProgress? progress,
  ) {
    return Row(
      children: [
        Icon(Icons.upload_rounded, color: colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Upload Progress',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: .w600,
          ),
        ),
        const Spacer(),
        _buildStatusBadge(progress),
      ],
    );
  }

  Widget _buildStatusBadge(UploadProgress? progress) {
    final statusColor = _getStatusColor(progress?.status);
    final statusText = _getStatusText(progress?.status);

    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: .circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: .w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme, UploadProgress? progress) => ClipRRect(
      borderRadius: .circular(8),
      child: LinearProgressIndicator(
        value: progress?.progress ?? 0,
        minHeight: 12,
        backgroundColor: colorScheme.primaryContainer,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );

  Widget _buildProgressDetails(
    ThemeData theme,
    ColorScheme colorScheme,
    UploadProgress? progress,
  ) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _buildProgressStats(theme, colorScheme, progress),
        const SizedBox(height: 8),
        _buildBlockInfo(theme, colorScheme, progress),
        _buildSizeInfo(theme, colorScheme, progress),
      ],
    );
  }

  Widget _buildProgressStats(
    ThemeData theme,
    ColorScheme colorScheme,
    UploadProgress? progress,
  ) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Text(
          progress?.progressPercentage ?? '0%',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: .bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          progress?.speedString ?? '0 B/s',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockInfo(
    ThemeData theme,
    ColorScheme colorScheme,
    UploadProgress? progress,
  ) {
    return Text(
      'Block ${(progress?.currentBlockIndex ?? 0) + 1} of ${progress?.totalBlocks ?? 0}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSizeInfo(
    ThemeData theme,
    ColorScheme colorScheme,
    UploadProgress? progress,
  ) {
    return Text(
      '${_formatFileSize(progress?.uploadedBytes ?? 0)} / ${_formatFileSize(progress?.totalBytes ?? 0)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildResultSection(ThemeData theme, ColorScheme colorScheme) {
    final result = _lastResult!;
    final isSuccess = result.success;

    return Container(
      margin: const .only(bottom: 24),
      padding: const .all(20),
      decoration: _buildResultDecoration(colorScheme, isSuccess),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _buildResultHeader(theme, isSuccess),
          const SizedBox(height: 16),
          if (isSuccess && result.fileUrl != null) _buildSuccessContent(theme, colorScheme, result) else if (!isSuccess) _buildErrorContent(theme, result),
        ],
      ),
    );
  }

  BoxDecoration _buildResultDecoration(ColorScheme colorScheme, bool isSuccess) {
    final accentColor = isSuccess ? Colors.green : Colors.red;

    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: .circular(20),
      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildResultHeader(ThemeData theme, bool isSuccess) {
    final accentColor = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = isSuccess ? 'Upload Successful' : 'Upload Failed';

    return Row(
      children: [
        Icon(icon, color: accentColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: .w600,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(
    ThemeData theme,
    ColorScheme colorScheme,
    UploadResult result,
  ) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          'File URL:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        _buildFileUrlCard(theme, colorScheme, result),
      ],
    );
  }

  Widget _buildFileUrlCard(
    ThemeData theme,
    ColorScheme colorScheme,
    UploadResult result,
  ) {
    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: .circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_serverUrlController.text}${result.fileUrl}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: _openFile,
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            tooltip: 'Open file in browser',
          ),
          IconButton(
            onPressed: _openFolder,
            icon: const Icon(Icons.folder_open_rounded, size: 20),
            tooltip: 'Open storage folder',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(ThemeData theme, UploadResult result) => Text(
      'Error: ${result.errorMessage}',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.red.shade700,
      ),
    );

  Widget _buildControls(ThemeData theme, ColorScheme colorScheme) => Row(
      children: [
        !_isUploading ? _buildStartButton() : _buildUploadingControls(colorScheme),
      ],
    );

  Widget _buildStartButton() => Expanded(
      child: FilledButton.icon(
        onPressed: _selectedFilePath != null ? _startUpload : null,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text('Start Upload'),
        style: FilledButton.styleFrom(
          padding: const .symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: .circular(16),
          ),
        ),
      ),
    );

  Widget _buildUploadingControls(ColorScheme colorScheme) => Expanded(
      child: Row(
        children: [
          Expanded(child: _buildPauseResumeButton()),
          const SizedBox(width: 12),
          Expanded(child: _buildCancelButton(colorScheme)),
        ],
      ),
    );

  Widget _buildPauseResumeButton() {
    final isPaused = _currentProgress?.status == UploadStatus.paused;

    if (isPaused) {
      return FilledButton.icon(
        onPressed: _resumeUpload,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Resume'),
        style: FilledButton.styleFrom(
          padding: const .symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: .circular(16),
          ),
        ),
      );
    } else {
      return FilledButton.tonalIcon(
        onPressed: _pauseUpload,
        icon: const Icon(Icons.pause_rounded),
        label: const Text('Pause'),
        style: FilledButton.styleFrom(
          padding: const .symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: .circular(16),
          ),
        ),
      );
    }
  }

  Widget _buildCancelButton(ColorScheme colorScheme) => OutlinedButton.icon(
      onPressed: _cancelUpload,
      icon: Icon(Icons.close_rounded, color: colorScheme.error),
      label: Text('Cancel', style: TextStyle(color: colorScheme.error)),
      style: OutlinedButton.styleFrom(
        padding: const .symmetric(vertical: 16),
        side: BorderSide(color: colorScheme.error),
        shape: RoundedRectangleBorder(
          borderRadius: .circular(16),
        ),
      ),
    );

  Widget _buildLogsSection(ThemeData theme, ColorScheme colorScheme) => Container(
      decoration: _buildCardDecoration(colorScheme),
      child: Column(
        children: [
          _buildLogsHeader(theme, colorScheme),
          if (_showLogs) _buildLogsContent(),
        ],
      ),
    );

  Widget _buildLogsHeader(ThemeData theme, ColorScheme colorScheme) => InkWell(
      onTap: () => setState(() => _showLogs = !_showLogs),
      borderRadius: const .vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const .all(16),
        child: Row(
          children: [
            Icon(Icons.terminal_rounded, color: colorScheme.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Upload Logs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: .w600,
              ),
            ),
            const SizedBox(width: 8),
            _buildLogCountBadge(colorScheme),
            const Spacer(),
            if (_logs.isNotEmpty) _buildClearLogsButton(),
            _buildExpandIcon(colorScheme),
          ],
        ),
      ),
    );

  Widget _buildLogCountBadge(ColorScheme colorScheme) => Container(
      padding: const .symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: .circular(10),
      ),
      child: Text(
        '${_logs.length}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: .bold,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );

  Widget _buildClearLogsButton() => IconButton(
      onPressed: _clearLogs,
      icon: const Icon(Icons.clear_all_rounded, size: 20),
      tooltip: 'Clear logs',
    );

  Widget _buildExpandIcon(ColorScheme colorScheme) => Icon(
      _showLogs ? Icons.expand_less_rounded : Icons.expand_more_rounded,
      color: colorScheme.onSurfaceVariant,
    );

  Widget _buildLogsContent() => Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: .vertical(bottom: Radius.circular(20)),
      ),
      child: _logs.isEmpty ? _buildEmptyLogsPlaceholder() : _buildLogsList(),
    );

  Widget _buildEmptyLogsPlaceholder() => Center(
      child: Text(
        'No logs yet. Start an upload to see logs.',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
      ),
    );

  Widget _buildLogsList() {
    return ListView.builder(
      controller: _logScrollController,
      padding: const .all(12),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Padding(
          padding: const .symmetric(vertical: 2),
          child: Text(
            log.toString(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: _getLogColor(log.level),
            ),
          ),
        );
      },
    );
  }

  Color _getLogColor(String level) {
    switch (level) {
      case 'ERROR':
        return Colors.red.shade400;
      case 'INFO':
        return Colors.green.shade400;
      case 'DEBUG':
        return Colors.grey.shade400;
      default:
        return Colors.white70;
    }
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getStatusColor(UploadStatus? status) {
    switch (status) {
      case UploadStatus.notStarted:
        return Colors.grey;
      case UploadStatus.inProgress:
        return Colors.blue;
      case UploadStatus.paused:
        return Colors.orange;
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
      case UploadStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(UploadStatus? status) {
    switch (status) {
      case UploadStatus.notStarted:
        return 'Not Started';
      case UploadStatus.inProgress:
        return 'Uploading';
      case UploadStatus.paused:
        return 'Paused';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _logScrollController.dispose();
    _progressSubscription?.cancel();
    _logSubscription?.cancel();
    _memorySubscription?.cancel();
    _memoryTimer?.cancel();
    _currentTask?.dispose();
    if (widget.dio == null) _dio.close();
    super.dispose();
  }
}

/// Custom painter for sparkline visualization.
class _SparklinePainter extends CustomPainter {
  final List<int> samples;
  final int minVal;
  final int maxVal;
  final Color color;

  _SparklinePainter({
    required this.samples,
    required this.minVal,
    required this.maxVal,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final range = (maxVal - minVal).clamp(1, 1000);

    for (int i = 0; i < samples.length; i++) {
      final x = (i / (samples.length - 1)) * size.width;
      final normalizedY = (samples[i] - minVal) / range;
      final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw endpoint dot
    final lastX = size.width;
    final lastY = size.height - ((samples.last - minVal) / range * size.height * 0.8) - (size.height * 0.1);
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => samples != oldDelegate.samples;
}
