import 'dart:convert';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/drm/widevine/widevine_delegate.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';

class WidevineConfigStore {
  WidevineConfigStore._();

  static final WidevineConfigStore instance = WidevineConfigStore._();
  static const _secretKey = 'widevine_config';

  Future<WidevineConfig?> load() async {
    final serialized = await secretStore.read(_secretKey);
    if (serialized == null || serialized.isEmpty) return null;

    try {
      final decoded = jsonDecode(serialized);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      final config = WidevineConfig.fromJson(decoded);
      if (!_hasValidLicenseUrl(config.licenseUrl)) {
        throw const FormatException('Invalid Widevine license URL');
      }
      return config;
    } on FormatException catch (error) {
      LoggerService.instance.warning(
        'Configuration Widevine enregistrée illisible',
        error: error,
      );
      return null;
    } on TypeError catch (error) {
      LoggerService.instance.warning(
        'Configuration Widevine enregistrée illisible',
        error: error,
      );
      return null;
    }
  }

  Future<void> save(WidevineConfig? config) async {
    if (config == null) {
      await secretStore.delete(_secretKey);
      return;
    }
    if (!_hasValidLicenseUrl(config.licenseUrl)) {
      throw ArgumentError.value(config.licenseUrl, 'licenseUrl');
    }
    await secretStore.write(_secretKey, jsonEncode(config.toJson()));
  }

  static bool _hasValidLicenseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        uri.scheme == 'https';
  }
}
