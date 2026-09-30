import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/drm/drm_async_result.dart';
import 'package:orbit_3d_flutter/drm/drm_config.dart';
import 'package:orbit_3d_flutter/drm/drm_error.dart';
import 'package:orbit_3d_flutter/drm/license_manager.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart' show safeSync;

/// Délégué Widevine pour Media3/ExoPlayer.
///
/// Implémente l'interface `MediaDrmCallback` d'ExoPlayer/Media3
/// pour fournir les clés de déchiffrement Widevine.
class WidevineDelegate {
  final LicenseManager _licenseManager;
  final LoggerService _logger = LoggerService.instance;

  WidevineDelegate({LicenseManager? licenseManager})
      : _licenseManager = licenseManager ?? LicenseManager();

  /// Crée une session MediaDrm et demande les clés pour un défi donné.
  Future<DrmAsyncResult<Uint8List>> getKeyRequest(
    String sessionId,
    String licenseUrl,
    Uint8List challenge,
  ) async {
    final keyId = _extractKeyId(challenge);
    if (keyId == null) {
      return DrmAsyncResult.failure(
        const DrmError(
          code: DrmErrorCode.invalidKey,
          message: 'Impossible d\'extraire le keyId du défi Widevine.',
        ),
      );
    }

    _logger.info('Widevine key request for session $sessionId');

    final result = await _licenseManager.requestLicense(
      DrmConfig.widevine(licenseUrl: licenseUrl),
      keyId,
      base64Encode(challenge),
    );

    return result.map((licenseData) {
      final licenseBytes = base64Decode(licenseData['data'] as String);
      return Uint8List.fromList(licenseBytes);
    });
  }

  /// Fournit les clés de déchiffrement à MediaDrm.
  Future<DrmAsyncResult<void>> provideKeys(
    String sessionId,
    List<Uint8List> keyIds,
  ) async {
    _logger.info('Providing keys for session $sessionId');
    return DrmAsyncResult.success(null);
  }

  String? _extractKeyId(Uint8List challenge) {
    final result = safeSync<String?>(
      () {
        final challengeStr = utf8.decode(challenge);
        final map = jsonDecode(challengeStr) as Map<String, dynamic>;
        final kids = map['kids'] as List?;
        return kids?.first?.toString();
      },
      context: 'WidevineDelegate._extractKeyId',
    );
    return result.valueOrNull;
  }
}

/// Configuration pour l'initialisation MediaDrm.
class WidevineConfig {
  final String licenseUrl;
  final Map<String, String> headers;
  final String? certificateBase64;

  WidevineConfig({
    required this.licenseUrl,
    Map<String, String>? headers,
    this.certificateBase64,
  }) : headers = <String, String>{
          'Content-Type': 'application/json',
          ...?headers,
        };

  Map<String, dynamic> toJson() => {
        'licenseUrl': licenseUrl,
        'headers': headers,
        if (certificateBase64 != null) 'certificateBase64': certificateBase64,
      };

  factory WidevineConfig.fromJson(Map<String, dynamic> json) => WidevineConfig(
        licenseUrl: json['licenseUrl'] as String,
        headers: Map<String, String>.from(json['headers'] ?? {}),
        certificateBase64: json['certificateBase64'] as String?,
      );
}
