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

  /// Instance unique partagée par tous les widgets d'image.
  ///
  /// La classe était instanciée dans le `build()` de chaque
  /// `OrbitCachedImage`/`CachedImage` : sur une grille VOD, chaque frappe au
  /// clavier reconstruisait le parent, donc ~40 `CacheManager` + ~40 `Config`
  /// par frappe. Le cache disque était déjà partagé (même clé
  /// `orbit_image_cache`) ; seule l'instance était dupliquée.
  ///
  /// `CacheManager` est sans état par requête et thread-safe côté API
  /// publique : une instance unique change le comportement du cache, pas celui
  /// des images.
  static final OrbitCacheManager shared = OrbitCacheManager();
}
