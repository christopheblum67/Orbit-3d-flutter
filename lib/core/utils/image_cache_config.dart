import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache disque borné des pochettes/stickers (TVmaze/OMDB/TMDB), partagé par
/// toutes les instances [OrbitCachedImage] (y compris les flux en streaming).
///
/// Limite de 5000 objets et TTL de 30 jours ; la clé disque `orbit_image_cache`
/// est cohérente avec `snackCacheCleared` (vidage des caches dans les réglages).
class OrbitCacheManager extends CacheManager {
  OrbitCacheManager()
      : super(
          Config(
            'orbit_image_cache',
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 5000,
          ),
        );
}
