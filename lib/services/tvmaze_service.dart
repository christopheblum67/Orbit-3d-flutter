import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';

/// Client TVmaze (gratuit, pas de clé API) avec rate limiting 1 req/s et cache Hive
class TvmazeService {
  static const String _baseUrl = 'https://api.tvmaze.com';
  static const String _cacheBoxName = 'metadata_cache';
  static const Duration _cacheTtl = Duration(hours: 24);
  static const Duration _minRequestInterval = Duration(seconds: 1);

  final Dio _dio;
  final LoggerService _logger = LoggerService.instance;
  Box? _cacheBox;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  TvmazeService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),) {
    _initCache();
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (msg) => _logger.debug('[TVmaze] $msg'),
    ),);
  }

  Future<void> _initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
    } else {
      _cacheBox = Hive.box(_cacheBoxName);
    }
  }

  /// TVmaze ne nécessite pas de clé API
  bool get hasApiKey => true;

  /// Rate limiter : 1 req/s
  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequest);
    if (elapsed < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - elapsed);
    }
    _lastRequest = DateTime.now();
  }

  String _cacheKey(String prefix, String id) => 'tvmaze:$prefix:$id';

  T? _getCached<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    if (_cacheBox == null) return null;
    final entry = _cacheBox!.get(key);
    if (entry == null) return null;

    final Map<String, dynamic> data = Map<String, dynamic>.from(entry);
    final fetchedAt = data['fetchedAt'] as int? ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - fetchedAt >
        _cacheTtl.inMilliseconds) {
      _cacheBox!.delete(key);
      return null;
    }
    return fromJson(Map<String, dynamic>.from(data['data']));
  }

  Future<void> _setCache(String key, Map<String, dynamic> data) async {
    if (_cacheBox == null) return;
    await _cacheBox!.put(key, {
      'data': data,
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ==================== FILMS ====================

  /// Recherche un film par titre (TVmaze a une base de films limitée).
  /// L'année aide à désambiguïser entre un film et ses remakes/séquelles :
  /// on préfère un résultat `Movie` dont l'année de première diffusion concorde.
  Future<int?> searchMovieId(String title, {int? year}) async {
    await _waitForRateLimit();

    try {
      final response = await _dio.get('/search/shows', queryParameters: {
        'q': title,
      },);
      final results = response.data as List?;
      if (results != null && results.isNotEmpty) {
        Map<String, dynamic>? firstMovie;
        Map<String, dynamic>? yearMatch;
        for (final result in results) {
          final show = result['show'] as Map<String, dynamic>?;
          if (show == null || show['type'] != 'Movie') continue;
          firstMovie ??= show;
          if (year != null) {
            final premiered = show['premiered'] as String?;
            final showYear = (premiered != null && premiered.length >= 4)
                ? int.tryParse(premiered.substring(0, 4))
                : null;
            if (showYear == year) {
              yearMatch = show;
              break;
            }
          } else {
            break;
          }
        }
        final selected = yearMatch ?? firstMovie;
        if (selected != null) return selected['id'] as int;
        // Fallback: premier résultat (même si ce n'est pas typé "Movie")
        final firstShow = results.first['show'] as Map<String, dynamic>?;
        if (firstShow != null) return firstShow['id'] as int;
      }
    } catch (e) {
      _logger.warning('TVmaze searchMovieId error: $e');
    }
    return null;
  }

  /// Détails d'un film (TVmaze)
  Future<MovieDetail?> getMovieDetail(int tvmazeId) async {
    final cacheKey = _cacheKey('movie', tvmazeId.toString());
    final cached = _getCached(cacheKey, (d) => _parseMovieDetail(d, tvmazeId));
    if (cached != null) return cached;

    await _waitForRateLimit();

    try {
      final futures = await Future.wait([
        _dio.get('/shows/$tvmazeId'),
        _dio.get('/shows/$tvmazeId/cast'),
        _dio.get('/shows/$tvmazeId/images'),
      ], eagerError: false,);

      final showData = futures[0].data;
      final castData = futures[1].data as List<dynamic>? ?? [];
      final imagesData = futures[2].data as List<dynamic>? ?? [];

      final detail =
          _parseMovieDetail(showData, tvmazeId, castData, imagesData);
      await _setCache(cacheKey, showData);
      return detail;
    } catch (e) {
      _logger.warning('TVmaze getMovieDetail error: $e');
      return null;
    }
  }

  MovieDetail _parseMovieDetail(Map<String, dynamic> data, int tvmazeId,
      [List<dynamic>? castData, List<dynamic>? imagesData,]) {
    final externals = data['externals'] as Map<String, dynamic>? ?? {};
    final imdbId = externals['imdb'] as String? ?? '';
    final tmdbId = externals['themoviedb'] as int? ?? 0;

    final castList = (castData ?? [])
        .map((e) => _parseActor(e, ActorSource.tvmaze))
        .toList();

    String? backdropUrl;
    if (imagesData != null && imagesData.isNotEmpty) {
      for (final img in imagesData) {
        if (img['type'] == 'background' &&
            img['resolutions']?['original'] != null) {
          backdropUrl = img['resolutions']['original'];
          break;
        }
      }
    }

    final genres = (data['genres'] as List<dynamic>? ?? []).join(', ');
    final country = data['network']?['country']?['name'] ??
        data['webChannel']?['country']?['name'] ??
        '';

    return MovieDetail(
      id: data['id'].toString(),
      title: data['name'] ?? '',
      description: _stripHtml(data['summary']),
      posterUrl: data['image']?['original'] ?? data['image']?['medium'] ?? '',
      year: _parseYear(data['premiered']),
      genre: genres,
      director:
          '', // TVmaze ne donne pas le réalisateur directement pour les films
      rating: (data['rating']?['average'] as num?)?.toDouble() ?? 0,
      pegi: data['rating']?['rating']?.toString() ?? '',
      streamUrl: '',
      tvmazeId: tvmazeId,
      imdbId: imdbId,
      tmdbId: tmdbId,
      runtime: data['runtime'] as int? ?? 0,
      originCountry: country.isNotEmpty ? [country] : [],
      status: data['status'] ?? '',
      backdropUrl: backdropUrl,
      originalLanguage: data['language'],
      originalTitle: data['name'],
      cast: castList,
      dataSource: 'tvmaze',
    );
  }

  // ==================== SÉRIES ====================

  /// Recherche une série par titre
  Future<int?> searchShowId(String title) async {
    await _waitForRateLimit();

    try {
      final response = await _dio.get('/search/shows', queryParameters: {
        'q': title,
      },);
      final results = response.data as List?;
      if (results != null && results.isNotEmpty) {
        // Filtrer pour ne garder que les séries (type: "Scripted", "Documentary", etc.)
        for (final result in results) {
          final show = result['show'] as Map<String, dynamic>?;
          if (show != null && show['type'] != 'Movie') {
            return show['id'] as int;
          }
        }
        final firstShow = results.first['show'] as Map<String, dynamic>?;
        if (firstShow != null) return firstShow['id'] as int;
      }
    } catch (e) {
      _logger.warning('TVmaze searchShowId error: $e');
    }
    return null;
  }

  /// Détails complets d'une série (PRIMAIRE pour les séries)
  Future<SeriesDetail?> getShowDetail(int tvmazeId) async {
    final cacheKey = _cacheKey('show', tvmazeId.toString());
    final cached = _getCached(cacheKey, (d) => _parseShowDetail(d, tvmazeId));
    if (cached != null) return cached;

    await _waitForRateLimit();

    try {
      // Paralléliser : show + cast + seasons + episodes
      final futures = await Future.wait([
        _dio.get('/shows/$tvmazeId', queryParameters: {'embed': 'cast'}),
        _dio.get('/shows/$tvmazeId/seasons'),
        _dio.get('/shows/$tvmazeId/episodes'),
      ], eagerError: false,);

      final showData = futures[0].data;
      final seasonsData = futures[1].data as List<dynamic>? ?? [];
      final episodesData = futures[2].data as List<dynamic>? ?? [];

      final detail =
          _parseShowDetail(showData, tvmazeId, seasonsData, episodesData);
      await _setCache(cacheKey, showData);
      return detail;
    } catch (e) {
      _logger.warning('TVmaze getShowDetail error: $e');
      return null;
    }
  }

  /// Récupère le casting global d'une série
  Future<List<Actor>> getShowCast(int tvmazeId) async {
    await _waitForRateLimit();

    try {
      final response = await _dio.get('/shows/$tvmazeId/cast');
      final castData = response.data as List<dynamic>? ?? [];
      return castData.map((e) => _parseActor(e, ActorSource.tvmaze)).toList();
    } catch (e) {
      _logger.warning('TVmaze getShowCast error: $e');
      return [];
    }
  }

  SeriesDetail _parseShowDetail(Map<String, dynamic> data, int tvmazeId,
      [List<dynamic>? seasonsData, List<dynamic>? episodesData,]) {
    final externals = data['externals'] as Map<String, dynamic>? ?? {};
    final imdbId = externals['imdb'] as String? ?? '';
    final tmdbId = externals['themoviedb'] as int? ?? 0;

    // Cast global (depuis l'embed)
    List<Actor> mainCast = [];
    final embedded = data['_embedded'] as Map<String, dynamic>? ?? {};
    final castEmbed = embedded['cast'] as List<dynamic>? ?? [];
    mainCast = castEmbed
        .map((e) {
          final person = e['person'] as Map<String, dynamic>?;
          final character = e['character'] as Map<String, dynamic>?;
          if (person != null) {
            return Actor(
              id: person['id'].toString(),
              name: person['name'] ?? '',
              character: character?['name'] ?? '',
              profilePath: person['image']?['original'] ??
                  person['image']?['medium'] ??
                  '',
              order: 0,
              source: ActorSource.tvmaze,
            );
          }
          return null;
        })
        .whereType<Actor>()
        .toList();

    // Guest stars par saison
    final guestStarsPerSeason = <int, List<Actor>>{};
    if (episodesData != null) {
      final guestsBySeason = <int, Map<String, Actor>>{};

      for (final ep in episodesData) {
        final season = ep['season'] as int? ?? 0;
        if (season == 0) continue;

        final guestStars = ep['guest_stars'] as List<dynamic>? ?? [];
        for (final guest in guestStars) {
          final person = guest['person'] as Map<String, dynamic>?;
          final character = guest['character'] as Map<String, dynamic>?;
          if (person != null) {
            final actor = Actor(
              id: person['id'].toString(),
              name: person['name'] ?? '',
              character: character?['name'] ?? '',
              profilePath: person['image']?['original'] ??
                  person['image']?['medium'] ??
                  '',
              order: 0,
              isGuestStar: true,
              source: ActorSource.tvmaze,
            );
            guestsBySeason.putIfAbsent(season, () => {})[actor.id] = actor;
          }
        }
      }

      for (final entry in guestsBySeason.entries) {
        guestStarsPerSeason[entry.key] = entry.value.values.toList();
      }
    }

    final networks = <String>[];
    if (data['network'] != null) {
      networks.add(data['network']['name']);
    }
    if (data['webChannel'] != null) {
      networks.add(data['webChannel']['name']);
    }

    final genres = (data['genres'] as List<dynamic>? ?? []).join(', ');
    final firstAirDate = data['premiered'] as String? ?? '';
    final lastAirDate = data['ended'] as String?;

    return SeriesDetail(
      id: data['id'].toString(),
      title: data['name'] ?? '',
      description: _stripHtml(data['summary']),
      coverUrl: data['image']?['original'] ?? data['image']?['medium'] ?? '',
      year: _parseYear(firstAirDate),
      genre: genres,
      director: '',
      rating: (data['rating']?['average'] as num?)?.toDouble() ?? 0,
      pegi: data['rating']?['rating']?.toString() ?? '',
      episodes: const [],
      tvmazeId: tvmazeId,
      imdbId: imdbId,
      tmdbId: tmdbId,
      runtime: data['runtime'] as int? ?? 0,
      networks: networks,
      status: data['status'] ?? '',
      firstAirDate: firstAirDate,
      lastAirDate: lastAirDate,
      numberOfSeasons:
          data['_embedded']?['seasons']?.length ?? (seasonsData?.length ?? 0),
      numberOfEpisodes:
          data['_embedded']?['episodes']?.length ?? (episodesData?.length ?? 0),
      originalLanguage: data['language'],
      originalName: data['name'],
      guestStarsPerSeason: guestStarsPerSeason,
      cast: mainCast,
      dataSource: 'tvmaze',
    );
  }

  // ==================== HELPERS ====================

  Actor _parseActor(Map<String, dynamic> map, ActorSource source) {
    final person = map['person'] as Map<String, dynamic>? ?? map;
    final character = map['character'] as Map<String, dynamic>? ?? {};

    return Actor(
      id: person['id']?.toString() ?? '',
      name: person['name'] ?? '',
      character: character['name'] ?? '',
      profilePath:
          person['image']?['original'] ?? person['image']?['medium'] ?? '',
      order: 0,
      source: source,
    );
  }

  int _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0;
    final match = RegExp(r'^(\d{4})').firstMatch(dateStr);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  String _stripHtml(String? html) {
    if (html == null) return '';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&', '&')
        .replaceAll('<', '<')
        .replaceAll('>', '>')
        .replaceAll('"', '"')
        .trim();
  }

  Future<void> dispose() async {
    if (_cacheBox != null && _cacheBox!.isOpen) {
      await _cacheBox!.close();
    }
  }
}
