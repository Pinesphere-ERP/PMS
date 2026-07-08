import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('💡 DEBUG: $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('⚠️ WARN: $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('🔴 ERROR: $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
    // TODO: Send to remote crashlytics / logging service in production
  }
}
