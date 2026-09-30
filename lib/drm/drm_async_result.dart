import 'package:orbit_3d_flutter/drm/drm_error.dart';

/// Résultat typé des opérations DRM qui peuvent échouer gracieusement.
///
/// Encapsule une valeur de succès `T` ou une erreur [DrmError].
/// Permet de traiter les résultats DRM de manière fonctionnelle sans try/catch.
sealed class DrmAsyncResult<T> {
  const DrmAsyncResult();

  /// Crée un succès
  static DrmAsyncResult<T> success<T>(T value) => _DrmSuccess<T>(value);

  /// Crée un échec
  static DrmAsyncResult<T> failure<T>(DrmError error) => _DrmFailure<T>(error);

  /// Vérifie si c'est un succès
  bool get isSuccess => this is _DrmSuccess<T>;

  /// Vérifie si c'est un échec
  bool get isFailure => this is _DrmFailure<T>;

  /// Récupère la valeur si succès, sinon null
  T? get valueOrNull => isSuccess ? (this as _DrmSuccess<T>).value : null;

  /// Récupère l'erreur si échec, sinon null
  DrmError? get errorOrNull =>
      isFailure ? (this as _DrmFailure<T>).error : null;

  /// Applique une fonction si succès, sinon retourne l'échec
  DrmAsyncResult<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      try {
        return DrmAsyncResult.success(
            transform((this as _DrmSuccess<T>).value),);
      } catch (error, stackTrace) {
        return DrmAsyncResult.failure(
          DrmError(
            code: DrmErrorCode.unknown,
            message: 'Transform failed: $error',
            originalError: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }
    return this as DrmAsyncResult<R>;
  }

  /// Chaîne une autre opération asynchrone DRM
  Future<DrmAsyncResult<R>> flatMap<R>(
      Future<DrmAsyncResult<R>> Function(T) next,) {
    if (isFailure) return Future.value(this as DrmAsyncResult<R>);
    return next((this as _DrmSuccess<T>).value);
  }

  /// Récupère la valeur ou lance l'erreur
  T getOrThrow() {
    if (isSuccess) return (this as _DrmSuccess<T>).value;
    throw (this as _DrmFailure<T>).error;
  }

  /// Récupère la valeur ou une valeur par défaut
  T getOrElse(T defaultValue) =>
      isSuccess ? (this as _DrmSuccess<T>).value : defaultValue;
}

class _DrmSuccess<T> extends DrmAsyncResult<T> {
  final T value;
  const _DrmSuccess(this.value);

  @override
  String toString() => 'DrmSuccess($value)';
}

class _DrmFailure<T> extends DrmAsyncResult<T> {
  final DrmError error;
  const _DrmFailure(this.error);

  @override
  String toString() => 'DrmFailure($error)';
}
