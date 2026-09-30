import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Gestion du Certificate Pinning pour les connexions DRM sécurisées.
class CertificatePinning {
  final Map<String, List<String>> _pins;
  final LoggerService _logger = LoggerService.instance;

  CertificatePinning({Map<String, List<String>>? pins})
      : _pins = pins ?? const {};

  Future<bool> verify(String host, List<int> certificateDer) async {
    final expectedPins = _pins[host];
    if (expectedPins == null || expectedPins.isEmpty) {
      _logger.warning('No pins configured for host: $host');
      return true;
    }

    final digest = sha256.convert(certificateDer);
    final fingerprint = base64Encode(digest.bytes);

    if (expectedPins.contains(fingerprint)) {
      _logger.info('Certificate pinning OK for $host');
      return true;
    }

    _logger.error(
        'Certificate pinning FAILED for $host. Expected: $expectedPins, got: $fingerprint',);
    return false;
  }

  void addPin(String host, String sha256Base64) {
    _pins.putIfAbsent(host, () => []).add(sha256Base64);
  }

  static CertificatePinning fromJson(Map<String, dynamic> json) {
    final pins = <String, List<String>>{};
    final pinsJson = json['pins'] as Map<String, dynamic>?;
    if (pinsJson != null) {
      pinsJson.forEach((host, pins) {
        if (pins is List) {
          pins = List<String>.from(pins.map((p) => p.toString()));
        }
      });
    }
    return CertificatePinning(pins: pins);
  }

  Map<String, dynamic> toJson() => {
        'pins': _pins,
      };
}
