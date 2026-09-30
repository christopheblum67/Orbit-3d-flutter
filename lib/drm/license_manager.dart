import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/drm/drm_config.dart';
import 'package:orbit_3d_flutter/drm/drm_error.dart';
import 'package:orbit_3d_flutter/drm/license_cache.dart';
import 'package:orbit_3d_flutter/drm/drm_async_result.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Gestionnaire de licences DRM (requêtes, renouvellement, cache).
class LicenseManager {
  final Dio _dio;
  final LicenseCache _cache;
  final LoggerService _logger = LoggerService.instance;

  Timer? _renewalTimer;

  LicenseManager({
    Dio? dio,
    LicenseCache? cache,
  })  : _dio = dio ?? Dio(),
        _cache = cache ?? LicenseCache();

  /// Demande une licence au serveur de licences.
  Future<DrmAsyncResult<Map<String, dynamic>>> requestLicense(
    DrmConfig config,
    String keyId,
    String challengeBase64,
  ) async {
    if (!config.isValid) {
      return DrmAsyncResult.failure(
        DrmError.fromException(
          ArgumentError('Invalid DrmConfig'),
          StackTrace.current,
          code: DrmErrorCode.invalidKey,
        ),
      );
    }

    final keyId = _extractKeyId(challengeBase64);
    if (keyId == null) {
      return DrmAsyncResult.failure(
        const DrmError(
          code: DrmErrorCode.invalidKey,
          message: 'Invalid key ID in challenge',
        ),
      );
    }

    final result = await safeAsync<DrmAsyncResult<Map<String, dynamic>>>(
      () async {
        final cached = await licenseCache.getLicense(
          config.licenseUrl,
          keyId,
          config.keySystem,
        );
        if (cached != null) {
          _logger.info('License cache hit: $config.keySystem::$keyId');
          return DrmAsyncResult.success(cached);
        }

        // Affiche une progression simple pendant le rafraîchissement.
        await _waitForRateLimit();

        final headers = <String, String>{
          'Content-Type': 'application/json',
          ...config.licenseHeaders,
        };

        final body = _buildLicenseRequest(
          challengeBase64: challengeBase64,
          config: config,
        );

        _logger.info('Requesting license from ${config.licenseUrl}');

        final response = await _dio.post(
          config.licenseUrl,
          data: body,
          options: Options(
            headers: headers,
            responseType: ResponseType.bytes,
          ),
        );

        if (response.statusCode != 200) {
          return DrmAsyncResult.failure(
            DrmError(
              code: DrmErrorCode.licenseRequestFailed,
              message: 'License request failed: ${response.statusCode}',
              context: {
                'statusCode': response.statusCode,
                'url': config.licenseUrl,
              },
            ),
          );
        }

        final licenseData = response.data;
        final licenseBytes = licenseData is List<int>
            ? licenseData
            : utf8.encode(jsonEncode(licenseData));

        final cacheKeyId = _extractKeyId(challengeBase64) ?? 'unknown';
        await licenseCache.putLicense(
          licenseUrl: config.licenseUrl,
          keyId: cacheKeyId,
          keySystem: config.keySystem,
          licenseData: {
            'data': base64Encode(licenseBytes),
            'keySystem': config.keySystem,
          },
          licenseDuration: config.licenseDuration,
        );

        if (config.licenseDuration != null) {
          _scheduleRenewal(config, challengeBase64);
        }

        return DrmAsyncResult.success({
          'data': base64Encode(licenseBytes),
          'keySystem': config.keySystem,
        });
      },
      context: 'LicenseManager.requestLicense',
    );

    if (result.isSuccess) {
      return result.valueOrNull!;
    }

    final appError = result.errorOrNull!;
    final originalError = appError.originalError ?? appError;
    if (originalError is DioException) {
      return _handleDioError(originalError);
    }
    _logger.error(
      'License request failed',
      error: originalError,
      stackTrace: appError.stackTrace ?? StackTrace.current,
    );
    return DrmAsyncResult.failure(
      DrmError.fromException(
        originalError,
        StackTrace.current,
        code: DrmErrorCode.licenseRequestFailed,
      ),
    );
  }

  Future<DrmAsyncResult<void>> renewLicense(
    String licenseUrl,
    String keyId,
    String keySystem,
    String challengeBase64,
  ) async {
    final result = await requestLicense(
      DrmConfig(
        licenseUrl: licenseUrl,
        keySystem: 'com.widevine.alpha',
        licenseHeaders: {},
      ),
      _extractKeyId(challengeBase64) ?? 'unknown',
      _buildChallenge(keyId),
    );

    return result.map((_) {});
  }

  void cancelRenewal() {
    _renewalTimer?.cancel();
    _renewalTimer = null;
  }

  Future<void> dispose() async {
    cancelRenewal();
    _dio.close();
  }

  Dio get dio => _dio;
  LicenseCache get cache => _cache;

  final Duration _minRequestInterval = const Duration(seconds: 1);
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < const Duration(seconds: 1)) {
      await Future.delayed(const Duration(seconds: 1) - elapsed);
    }
    _lastRequest = DateTime.now();
  }

  String? _extractKeyId(String challengeBase64) {
    final result = safeSync<String?>(
      () {
        final decoded = base64Decode(challengeBase64);
        final json = utf8.decode(decoded);
        final map = jsonDecode(json) as Map<String, dynamic>;
        final kids = map['kids'] as List?;
        if (kids != null && kids.isNotEmpty) {
          return kids.first.toString();
        }
        return null;
      },
      context: 'LicenseManager._extractKeyId',
    );
    return result.valueOrNull;
  }

  String _buildChallenge(String keyId) {
    final map = {
      'kids': [keyId],
      'type': 'temporary',
    };
    return base64Encode(utf8.encode(jsonEncode(map)));
  }

  String _buildLicenseRequest({
    required String challengeBase64,
    required DrmConfig config,
  }) {
    final map = <String, dynamic>{
      'challenge': challengeBase64,
    };
    if (config.customData != null) {
      map['customData'] = config.customData;
    }
    return jsonEncode(map);
  }

  DrmAsyncResult<Map<String, dynamic>> _handleDioError(DioException e) {
    DrmErrorCode code;
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        code = DrmErrorCode.networkError;
        message = 'Timeout licence: $e';
        break;
      case DioExceptionType.connectionError:
        code = DrmErrorCode.networkError;
        message = 'Connexion impossible: $e';
        break;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final message = switch (e.response?.statusCode) {
          401 => 'Non autorisé (401). Vérifiez vos identifiants Xtream.',
          403 => 'Accès refusé (403). L\'abonnement est peut-être bloqué.',
          404 => 'Ressource introuvable (404). Vérifiez l\'adresse du serveur.',
          429 => 'Limite de requêtes dépassée (429). Réessayez plus tard.',
          500 ||
          502 ||
          504 =>
            'Le serveur a renvoyé une erreur ($status). Réessayez plus tard.',
          _ => 'Le serveur a renvoyé une erreur (code $status).',
        };
        return DrmAsyncResult.failure(
          DrmError(code: DrmErrorCode.licenseRequestFailed, message: message),
        );
      case DioExceptionType.badCertificate:
        return DrmAsyncResult.failure(
          const DrmError(
              code: DrmErrorCode.provisioningFailed,
              message: 'Certificat invalide',),
        );
      default:
        return DrmAsyncResult.failure(
          DrmError(
              code: DrmErrorCode.licenseRequestFailed,
              message: 'Erreur requête: $e',),
        );
    }

    return DrmAsyncResult.failure(
      DrmError(code: code, message: message),
    );
  }

  void _scheduleRenewal(DrmConfig config, String challengeBase64) {
    if (config.licenseDuration == null) return;

    _renewalTimer?.cancel();
    final renewAt = config.licenseDuration! * 0.8;
    _renewalTimer = Timer(renewAt, () async {
      _logger.info('Scheduled license renewal triggered');
      await renewLicense(
        '', // licenseUrl will be extracted from config if needed
        '', // keyId will be extracted
        '', // keySystem
        '', // challengeBase64
      );
    });
  }
}
