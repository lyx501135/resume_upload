import 'package:flutter/foundation.dart';

/// Debug-only logger that only prints in debug/development mode
/// Logs are completely stripped in release builds for security and performance
class DebugLogger {
  /// Log a message (only in debug mode)
  static void log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Log an error message (only in debug mode)
  static void error(String message) {
    if (kDebugMode) debugPrint('❌ $message');
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) debugPrint('⚠️ $message');
  }

  /// Log a success message (only in debug mode)
  static void success(String message) {
    if (kDebugMode) debugPrint('✅ $message');
  }

  /// Log an info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) debugPrint('ℹ️ $message');
  }
}

/// Convenience function for debug logging
/// Usage: dLog('message') instead of print('message')
void dLog(String message) {
  if (kDebugMode) debugPrint(message);
}
