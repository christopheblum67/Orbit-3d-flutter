import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class AppError implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;
  final dynamic originalError;
  
  AppError({
    required this.message,
    this.code,
    this.stackTrace,
    this.originalError,
  });
  
  @override
  String toString() {
    return 'AppError: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class ErrorHandler {
  ErrorHandler._();
  
  static final ErrorHandler _instance = ErrorHandler._();
  static ErrorHandler get instance => _instance;
  
  static final LoggerService _logger = LoggerService.instance;
  
  void handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    if (error is AppError) {
      _logger.error(
        '${context != null ? '$context: ' : ''}${error.message}',
        error: error,
        stackTrace: error.stackTrace ?? stackTrace,
      );
    } else {
      _logger.error(
        '${context != null ? '$context: ' : ''}Unexpected error: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
    
    if (kDebugMode) {
      FlutterError.presentError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: context ?? 'Orbit3D',
      ));
    }
  }
  
  AppError createError(
    String message, {
    String? code,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
  
  void setupGlobalErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(
        details.exception,
        stackTrace: details.stack,
        context: details.library ?? 'FlutterError',
      );
    };
    
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      handleError(error, stackTrace: stack, context: 'PlatformDispatcher');
      return true;
    };
  }
}