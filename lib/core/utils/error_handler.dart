// ignore_for_file: avoid_print

export 'safe_async.dart';

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

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

  FirebaseCrashlytics? _crashlytics;

  /// Initialise Crashlytics sans bloquer (fire-and-forget).
  ///
  /// Uniquement en release/profil : en debug, la collecte native gênerait le
  /// débogage. `Firebase.initializeApp()` étant idempotent, l'appel est sûr
  /// même si Analytics/Messaging l'ont déjà initialisé ; son absence
  /// (pas de google-services.json) est simplement ignorée.
  Future<void> initCrashlytics() async {
    if (_crashlytics != null) return;
    if (kDebugMode) return;
    try {
      await Firebase.initializeApp();
      _crashlytics = FirebaseCrashlytics.instance;
    } catch (_) {
      // Firebase indisponible : reporting désactivé, l'app continue.
      _crashlytics = null;
    }
  }

  void _reportToCrashlytics(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    final crash = _crashlytics;
    if (crash == null) return;
    // Fire-and-forget : le reporting ne doit jamais bloquer ni faire échouer.
    unawaited(
      crash.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: context,
      ),
    );
  }

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

    _reportToCrashlytics(
      error,
      error is AppError ? error.stackTrace ?? stackTrace : stackTrace,
      context: context,
    );

    if (kDebugMode) {
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: context ?? 'Orbit3D',
        ),
      );
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
