import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Cache persistant pour les licences DRM (offline + renouvellement).
class LicenseCache {
  static const String _boxName = 'drm_licenses';
  static const String _metaBoxName = 'drm_licenses_meta';

  Box<dynamic>? _box;
  Box<dynamic>? _metaBox;

  /// Initialise les boxes Hive.
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
    if (!Hive.isBoxOpen(_metaBoxName)) {
      _metaBox = await Hive.openBox(_metaBoxName);
    } else {
      _metaBox = Hive.box(_metaBoxName);
    }
  }

  /// Génère une clé unique pour une licence.
  String _licenseKey(String licenseUrl, String keyId, String keySystem) =>
      '$keySystem::$licenseUrl::$keyId';

  /// Stocke une licence (données brutes + métadonnées).
  Future<void> putLicense({
    required String licenseUrl,
    required String keyId,
    required String keySystem,
    required Map<String, dynamic> licenseData,
    Duration? licenseDuration,
  }) async {
    await init();
    final key = _licenseKey(licenseUrl, keyId, keySystem);
    final meta = {
      'licenseUrl': licenseUrl,
      'keyId': keyId,
      'keySystem': keySystem,
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
      'expiresAt': DateTime.now()
          .add(const Duration(days: 30)) // fallback 30 jours
          .millisecondsSinceEpoch,
    };
    await _box!.put(key, licenseData);
    await _metaBox!.put(key, meta);
    LoggerService.instance.info('License cached: $keySystem::$keyId');
  }

  /// Récupère une licence valide (non expirée).
  Future<Map<String, dynamic>?> getLicense(
    String licenseUrl,
    String keyId,
    String keySystem,
  ) async {
    await init();
    final key = _licenseKey(licenseUrl, keyId, keySystem);
    final meta = _metaBox!.get(key);
    if (meta == null) return null;

    final expiresAt = meta['expiresAt'] as int?;
    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      // Expirée → on la supprime
      await _box!.delete(key);
      await _metaBox!.delete(key);
      LoggerService.instance
          .info('License expired and removed: $keySystem::$keyId');
      return null;
    }

    final data = _box!.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  /// Vérifie si une licence existe et est valide.
  Future<bool> hasValidLicense(
    String licenseUrl,
    String keyId,
    String keySystem,
  ) async {
    final license = await getLicense(licenseUrl, keyId, keySystem);
    return license != null;
  }

  /// Supprime une licence spécifique.
  Future<void> removeLicense(
    String licenseUrl,
    String keyId,
    String keySystem,
  ) async {
    await init();
    final key = _licenseKey(licenseUrl, keyId, keySystem);
    await _box!.delete(key);
    await _metaBox!.delete(key);
    LoggerService.instance.info('License removed: $keySystem::$keyId');
  }

  /// Nettoie toutes les licences expirées.
  Future<int> cleanExpired() async {
    await init();
    final now = DateTime.now().millisecondsSinceEpoch;
    int count = 0;
    for (final key in _metaBox!.keys.toList()) {
      final meta = _metaBox!.get(key);
      if (meta == null) continue;
      final expiresAt = meta['expiresAt'] as int?;
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _box!.delete(key);
        await _metaBox!.delete(key);
        count++;
      }
    }
    if (count > 0) {
      LoggerService.instance.info('Cleaned $count expired licenses');
    }
    return count;
  }

  /// Vide complètement le cache.
  Future<void> clear() async {
    await init();
    await _box!.clear();
    await _metaBox!.clear();
    LoggerService.instance.warning('License cache cleared');
  }

  /// Liste toutes les licences en cache (pour debug/UI).
  Future<List<Map<String, dynamic>>> listLicenses() async {
    await init();
    final result = <Map<String, dynamic>>[];
    for (final key in _metaBox!.keys) {
      final meta = _metaBox!.get(key);
      if (meta != null) {
        result.add(Map<String, dynamic>.from(meta as Map));
      }
    }
    return result;
  }
}

/// Singleton global pour le cache de licences.
final licenseCache = LicenseCache();
