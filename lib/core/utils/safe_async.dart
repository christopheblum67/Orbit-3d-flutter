import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/error_handler.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Résultat d'une opération asynchrone qui peut échouer gracieusement.
/// 
/// Encapsule soit une valeur de succès `T`, soit une erreur `AppError`.
/// Permet de traiter les erreurs de manière fonctionnelle sans try/catch dispersés.
sealed class AsyncResult<T> {
  const AsyncResult();

  /// Crée un succès
  static AsyncResult<T> success<T>(T value) => _Success<T>(value);

  /// Crée un échec
  static AsyncResult<T> failure<T>(AppError error) => _Failure<T>(error);

  /// Vérifie si c'est un succès
  bool get isSuccess => this is _Success<T>;

  /// Vérifie si c'est un échec
  bool get isFailure => this is _Failure<T>;

  /// Récupère la valeur si succès, sinon null
  T? get valueOrNull => isSuccess ? (this as _Success<T>).value : null;

  /// Récupère l'erreur si échec, sinon null
  AppError? get errorOrNull => isFailure ? (this as _Failure<T>).error : null;

  /// Applique une fonction si succès, sinon retourne l'échec
  AsyncResult<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      try {
        return AsyncResult.success(transform((this as _Success<T>).value));
      } catch (e, st) {
        return AsyncResult.failure(AppError(
          message: 'Transform failed: $e',
          originalError: e,
          stackTrace: st,
        ));
      }
    }
    return this as AsyncResult<R>;
  }

  /// Chaîne une autre opération asynchrone
  Future<AsyncResult<R>> flatMap<R>(Future<AsyncResult<R>> Function(T) next) {
    if (isFailure) return Future.value(this as AsyncResult<R>);
    return next((this as _Success<T>).value);
  }

  /// Récupère la valeur ou lance l'erreur
  T getOrThrow() {
    if (isSuccess) return (this as _Success<T>).value;
    throw (this as _Failure<T>).error;
  }

  /// Récupère la valeur ou une valeur par défaut
  T getOrElse(T defaultValue) => isSuccess ? (this as _Success<T>).value : defaultValue;

  /// Applique une fonction si succès, sinon fait rien
  void ifSuccess(void Function(T) onSuccess) {
    if (isSuccess) onSuccess((this as _Success<T>).value);
  }

  /// Applique une fonction si échec, sinon fait rien
  void ifFailure(void Function(AppError) onFailure) {
    if (isFailure) onFailure((this as _Failure<T>).error);
  }
}

class _Success<T> extends AsyncResult<T> {
  final T value;
  const _Success(this.value);
  @override
  String toString() => 'Success($value)';
}

class _Failure<T> extends AsyncResult<T> {
  final AppError error;
  const _Failure(this.error);
  @override
  String toString() => 'Failure($error)';
}

/// Wrapper pour exécuter une opération asynchrone de manière sécurisée.
/// 
/// Transforme toute exception en [AsyncResult.failure] au lieu de propager
/// l'exception. Permet de chaîner les opérations avec [AsyncResult.flatMap].
/// 
/// Exemple:
/// ```dart
/// final result = await safeAsync(() => api.fetchData());
/// if (result.isSuccess) {
///   print('Données: ${result.valueOrNull}');
/// } else {
///   print('Erreur: ${result.errorOrNull?.message}');
/// }
/// ```
Future<AsyncResult<T>> safeAsync<T>(
  Future<T> Function() operation, {
  String? context,
  bool reportToCrashlytics = true,
  T? fallbackValue,
}) async {
  try {
    final value = await operation();
    return AsyncResult.success(value);
  } catch (error, stackTrace) {
    final appError = error is AppError
        ? error
        : AppError(
            message: error.toString(),
            originalError: error,
            stackTrace: stackTrace,
          );

    ErrorHandler.instance.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
    );

    if (fallbackValue != null) {
      return AsyncResult.success(fallbackValue);
    }
    return AsyncResult.failure(appError);
  }
}

/// Version synchrone de [safeAsync] pour les opérations synchrones.
AsyncResult<T> safeSync<T>(
  T Function() operation, {
  String? context,
  bool reportToCrashlytics = true,
  T? fallbackValue,
}) {
  try {
    final value = operation();
    return AsyncResult.success(value);
  } catch (error, stackTrace) {
    final appError = error is AppError
        ? error
        : AppError(
            message: error.toString(),
            originalError: error,
            stackTrace: stackTrace,
          );

    ErrorHandler.instance.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
    );

    if (fallbackValue != null) {
      return AsyncResult.success(fallbackValue);
    }
    return AsyncResult.failure(appError);
  }
}

/// Extension pour ajouter `safeAsync` directement sur les Futures.
extension SafeAsyncExtension<T> on Future<T> {
  /// Transforme ce Future en [AsyncResult] en capturant les erreurs.
  Future<AsyncResult<T>> toAsyncResult({
    String? context,
    bool reportToCrashlytics = true,
    T? fallbackValue,
  }) async {
    return safeAsync(() => this, context: context, reportToCrashlytics: true, fallbackValue: fallbackValue);
  }
}

/// Helper pour exécuter plusieurs opérations en parallèle et collecter les résultats.
/// 
/// Retourne une liste de [AsyncResult] - on peut ensuite filtrer les succès/échecs.
Future<List<AsyncResult<T>>> safeAsyncAll<T>(
  Iterable<Future<T> Function()> operations, {
  String? context,
}) async {
  final futures = operations.map((op) => safeAsync(op, context: context)).toList();
  return Future.wait(futures);
}

/// Helper pour réessayer une opération avec backoff exponentiel.
/// 
/// Retourne un [AsyncResult] - succès si une tentative réussit, échec après épuisement.
Future<AsyncResult<T>> retryAsync<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 500),
  double backoffFactor = 2.0,
  bool Function(Object error)? shouldRetry,
  String? context,
}) async {
  Object? lastError;
  StackTrace? lastStack;

  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    final result = await safeAsync(operation, context: context);
    if (result.isSuccess) return result;

    lastError = result.errorOrNull?.originalError ?? result.errorOrNull;
    lastStack = result.errorOrNull?.stackTrace;

    final error = result.errorOrNull;
    final shouldRetryAgain = shouldRetry?.call(error?.originalError ?? error) ?? true;

    if (!shouldRetryAgain || attempt == maxAttempts - 1) break;

    final delay = Duration(milliseconds: (baseDelay.inMilliseconds * math.pow(backoffFactor, attempt)).round());
    await Future.delayed(delay);
  }

  return AsyncResult.failure(AppError(
    message: 'Échec après $maxAttempts tentatives',
    originalError: lastError,
    stackTrace: lastStack,
    code: 'RETRY_EXHAUSTED',
  ));
}

/// Helper pour créer des erreurs typées selon le contexte.
class AppErrors {
  static AppError networkError(String message, {Object? originalError, StackTrace? stackTrace}) =>
      AppError(message: message, code: 'NETWORK_ERROR', originalError: originalError, stackTrace: stackTrace);

  static AppError timeoutError(String message, {Object? originalError, StackTrace? stackTrace}) =>
      AppError(message: message, code: 'TIMEOUT', originalError: originalError, stackTrace: stackTrace);

  static AppError authError(String message, {Object? originalError, StackTrace? stackTrace}) =>
      AppError(message: message, code: 'AUTH_ERROR', originalError: originalError, stackTrace: stackTrace);

  static AppError notFoundError(String message, {Object? originalError, StackTrace? stackTrace}) =>
      AppError(message: message, code: 'NOT_FOUND', originalError: originalError, stackTrace: stackTrace);

  static AppError validationError(String message, {Object? originalError, StackTrace? stackTrace}) =>
      AppError(message: message, code: 'VALIDATION_ERROR', originalError: originalError, stackTrace: stackTrace);

  static AppError unknownError(String message, {Object? originalError, StackTrace? stackTrace}) =>
      AppError(message: message, code: 'UNKNOWN_ERROR', originalError: originalError, stackTrace: stackTrace);
}

/// Extension pour faciliter l'utilisation de [AsyncResult] dans l'UI.
extension AsyncResultUI<T> on AsyncResult<T> {
  /// Affiche un widget de chargement, d'erreur ou le contenu selon l'état.
  Widget when({
    required Widget Function(T data) data,
    Widget Function(AppError error)? error,
    Widget Function()? loading,
  }) {
    if (isSuccess) {
      return data((this as _Success).value) as Widget;
    }
    if (isFailure) {
      return (error?.call((this as _Failure).error) ?? _DefaultErrorWidget(error: (this as _Failure).error)) as Widget;
    }
    return (loading ?? const _DefaultLoadingWidget()) as Widget;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final AppError error;
  const _DefaultErrorWidget({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            error.code != null ? '${error.code}: ${error.message}' : error.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}