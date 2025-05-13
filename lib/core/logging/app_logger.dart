import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'; // Para kDebugMode

class AppLogger {
  static void log(String message, {String name = 'App', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
        level: error != null ? 1000 : 0, // Nivel de severidad (INFO=0, SEVERE=1000 para errores)
      );
    }
  }

  static void info(String message, {String name = 'AppInfo'}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name,
        level: 0, // INFO
      );
    }
  }

  static void warning(String message, {String name = 'AppWarning', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
        level: 900, // WARNING
      );
    }
  }

  static void error(String message, {String name = 'AppError', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
        level: 1000, // SEVERE
      );
    }
  }
} 