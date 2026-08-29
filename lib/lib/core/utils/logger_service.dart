import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggerService {
  LoggerService._();
  
  static final LoggerService _instance = LoggerService._();
  static LoggerService get instance => _instance;
  
  static const String _tag = 'Orbit3D';
  static bool _isProduction = false;
  
  static void configure({required bool isProduction}) {
    _isProduction = isProduction;
  }
  
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_isProduction && level == LogLevel.debug) {
      return;
    }
    
    final String logTag = tag ?? _tag;
    final String formattedMessage = '[\] \';
    
    switch (level) {
      case LogLevel.debug:
        developer.log(formattedMessage, name: logTag, level: 0);
        break;
      case LogLevel.info:
        developer.log(formattedMessage, name: logTag, level: 1);
        break;
      case LogLevel.warning:
        developer.log(formattedMessage, name: logTag, level: 2, error: error);
        break;
      case LogLevel.error:
        developer.log(formattedMessage, name: logTag, level: 3, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.critical:
        developer.log(formattedMessage, name: logTag, level: 4, error: error, stackTrace: stackTrace);
        break;
    }
    
    if (kDebugMode) {
      debugPrint(formattedMessage);
    }
  }
  
  void debug(String message, {String? tag}) {
    log(message, level: LogLevel.debug, tag: tag);
  }
  
  void info(String message, {String? tag}) {
    log(message, level: LogLevel.info, tag: tag);
  }
  
  void warning(String message, {String? tag, Object? error}) {
    log(message, level: LogLevel.warning, tag: tag, error: error);
  }
  
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.error, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.critical, tag: tag, error: error, stackTrace: stackTrace);
  }
}
