import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Codes d'erreur DRM standardisés.
enum DrmErrorCode {
  /// Erreur inconnue / non catégorisée.
  unknown,

  /// Erreur de provisioning (Widevine provisioning failed).
  provisioningFailed,

  /// Échec création session MediaDrm.
  sessionCreationFailed,

  /// Échec requête licence (réseau, auth, 4xx/5xx).
  licenseRequestFailed,

  /// Licence expirée / invalide.
  licenseExpired,

  /// Clé invalide / corrompue.
  invalidKey,

  /// Erreur réseau / timeout.
  networkError,

  /// Erreur de déchiffrement / lecture.
  decryptionError,

  /// Opération annulée par l'utilisateur.
  cancelled,

  /// Non supporté sur cette plateforme / device.
  unsupported,

  /// Clé expirée / rotation nécessaire.
  keyExpired,

  /// Dépassement du nombre de dispositifs autorisés.
  deviceLimitExceeded,

  /// Erreur interne MediaDrm / CDM.
  internalError,
}

/// Exception typée pour les erreurs DRM.
class DrmError implements Exception {
  final DrmErrorCode code;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const DrmError({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  /// Crée une [DrmError] depuis une exception générique.
  factory DrmError.fromException(
    Object error,
    StackTrace? stackTrace, {
    DrmErrorCode code = DrmErrorCode.unknown,
    String? message,
    Map<String, dynamic>? context,
  }) {
    return DrmError(
      code: code,
      message: message ?? error.toString(),
      originalError: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  @override
  String toString() => 'DrmError($code): $message'
      '${context != null ? ' | Context: $context' : ''}'
      '${originalError != null ? ' | Cause: $originalError' : ''}';

  /// Vérifie si l'erreur est récupérable (retry possible).
  bool get isRecoverable {
    return switch (code) {
      DrmErrorCode.networkError ||
      DrmErrorCode.licenseRequestFailed ||
      DrmErrorCode.provisioningFailed ||
      DrmErrorCode.sessionCreationFailed =>
        true,
      _ => false,
    };
  }

  /// Vérifie si l'erreur nécessite une action utilisateur (retry manuel).
  bool get requiresUserAction {
    return switch (code) {
      DrmErrorCode.cancelled ||
      DrmErrorCode.deviceLimitExceeded ||
      DrmErrorCode.licenseExpired =>
        true,
      _ => false,
    };
  }
}

/// Helper pour logger les erreurs DRM de façon cohérente.
extension DrmErrorLogging on DrmError {
  void log() {
    LoggerService.instance.error(
      'DRM Error [$code]: $message',
      error: originalError,
      stackTrace: stackTrace,
    );
  }
}
