import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Configuration de cache d'images bornée pour l'application.
///
/// - `maxNrOfCacheObjects`: 5000 fichiers max (évite remplissage disque)
/// - `stalePeriod`: 30 jours (nettoyage automatique fichiers inutilisés)
/// - Clé de cache dédiée pour isolation.
class OrbitCacheManager extends CacheManager with ImageCacheManager {
  static const String _cacheKey = 'orbit_cached_images';
  static const int _maxObjects = 5000;
  static const Duration _stalePeriod = Duration(days: 30);

  static final OrbitCacheManager _instance = OrbitCacheManager._();
  factory OrbitCacheManager() => _instance;
  OrbitCacheManager._() : super(Config(_cacheKey, maxNrOfCacheObjects: _maxObjects, stalePeriod: _stalePeriod));
}