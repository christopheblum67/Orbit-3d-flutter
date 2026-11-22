import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Follows redirects explicitly so request headers never cross an origin.
class OriginBoundImageFileService extends FileService {
  OriginBoundImageFileService({http.Client? client}) : _providedClient = client;

  final http.Client? _providedClient;
  late final http.Client _client = _providedClient ?? IOClient();
  late final HttpFileService _webService = HttpFileService();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    // Browser networking may follow redirects without exposing intermediate
    // responses. Never pass caller-supplied headers to it.
    if (kIsWeb) return _webService.get(url);

    final initial = Uri.parse(url);
    var current = initial;
    var forwardHeaders = true;
    var redirects = 0;
    while (true) {
      final request = http.Request('GET', current)..followRedirects = false;
      if (forwardHeaders && headers != null) request.headers.addAll(headers);
      final response = await _client.send(request);
      final status = response.statusCode;
      final location = response.headers['location'];
      if (!const {301, 302, 303, 307, 308}.contains(status) ||
          location == null) {
        return HttpGetResponse(response);
      }

      await response.stream.drain<void>();
      final next = current.resolve(location);
      if (++redirects > 5) {
        throw const HttpException('Too many redirects');
      }
      if ((next.scheme != 'http' && next.scheme != 'https') ||
          !next.hasAuthority ||
          next.host.isEmpty ||
          next.userInfo.isNotEmpty) {
        throw const HttpException('Invalid redirect');
      }
      if (next.scheme != initial.scheme ||
          next.host != initial.host ||
          next.port != initial.port) {
        forwardHeaders = false;
      }
      current = next;
    }
  }
}

void configureOrbitImageCache(TargetPlatform platform) {
  if (platform != TargetPlatform.android) return;
  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSize = 100;
  cache.maximumSizeBytes = 40 * 1024 * 1024;
}

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
            fileService: OriginBoundImageFileService(),
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
