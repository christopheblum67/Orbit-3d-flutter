import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';

/// Client TMDB (TheMovieDB) avec rate limiting, cache Hive et gestion d'erreurs
class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';
  static const String _cacheBoxName = 'metadata_cache';
  static const Duration _cacheTtl = Duration(hours: 24);
  static const int _maxRequestsPer10Seconds = 40;

  final Dio _dio;
  final LoggerService _logger = LoggerService.instance;
  Box? _cacheBox;
  final _requestTimestamps = <int>[];
  final _rateLimitLock = Completer<void>();

  TmdbService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          queryParameters: {
            'language': 'fr-FR',
            'api_key': dotenv.env['TMDB_API_KEY'] ?? '',
          },
        )) {
    _initCache();
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (msg) => _logger.debug('[TMDB] $msg'),
    ));
  }

  Future<void> _initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
    } else {
      _cacheBox = Hive.box(_cacheBoxName);
    }
  }

  String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Rate limiter : max 40 req/10s (token bucket simple)
  Future<void> _waitForRateLimit() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _requestTimestamps.removeWhere((ts) => now - ts > 10000);

    if (_requestTimestamps.length >= _maxRequestsPer10Seconds) {
      final oldest = _requestTimestamps.first;
      final waitMs = 10000 - (now - oldest);
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
    _requestTimestamps.add(DateTime.now().millisecondsSinceEpoch);
  }

  /// Génère une clé de cache
  String _cacheKey(String prefix, String id) => 'tmdb:$prefix:$id';

  /// Récupère depuis le cache si valide
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

  /// Sauvegarde dans le cache
  Future<void> _setCache(String key, Map<String, dynamic> data) async {
    if (_cacheBox == null) return;
    await _cacheBox!.put(key, {
      'data': data,
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ==================== FILMS ====================

  /// Recherche un film par titre + année (pour mapper Xtream ID → TMDB ID)
  Future<int?> searchMovieId(String title, {int? year}) async {
    if (!hasApiKey) return null;
    await _waitForRateLimit();

    try {
      final queryParams = <String, String>{
        'query': title,
        'include_adult': 'false',
      };
      if (year != null && year > 0) {
        queryParams['year'] = year.toString();
      }

      final response =
          await _dio.get('/search/movie', queryParameters: queryParams);
      final results = response.data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        // Prendre le premier résultat (le plus pertinent)
        return results.first['id'] as int;
      }
    } catch (e) {
      _logger.warning('TMDB searchMovieId error: $e');
    }
    return null;
  }

  /// Détails complets d'un film
  Future<MovieDetail?> getMovieDetail(int tmdbId) async {
    if (!hasApiKey) return null;

    final cacheKey = _cacheKey('movie', tmdbId.toString());
    final cached = _getCached(cacheKey, (d) => _parseMovieDetail(d, tmdbId));
    if (cached != null) return cached;

    await _waitForRateLimit();

    try {
      // Paralléliser detail + credits + images + videos + external_ids
      final futures = await Future.wait([
        _dio.get('/movie/$tmdbId', queryParameters: {
          'append_to_response': 'credits,images,videos,external_ids,keywords'
        }),
      ], eagerError: false);

      final detailResponse = futures[0];
      if (detailResponse.data == null) return null;

      final detail = _parseMovieDetail(detailResponse.data, tmdbId);
      await _setCache(cacheKey, detailResponse.data);
      return detail;
    } catch (e) {
      _logger.warning('TMDB getMovieDetail error: $e');
      return null;
    }
  }

  MovieDetail _parseMovieDetail(Map<String, dynamic> data, int tmdbId) {
    final externalIds = data['external_ids'] as Map<String, dynamic>? ?? {};
    final imdbId = externalIds['imdb_id'] as String? ?? '';
    final tvmazeId = externalIds['tvmaze_id'] as int? ?? 0;

    final credits = data['credits'] as Map<String, dynamic>? ?? {};
    final castList = (credits['cast'] as List<dynamic>? ?? [])
        .map((e) => _parseActor(e, ActorSource.tmdb))
        .toList();
    final crewList = (credits['crew'] as List<dynamic>? ?? [])
        .map((e) => CrewMember.fromMap(e))
        .toList();

    final images = data['images'] as Map<String, dynamic>? ?? {};
    final backdrops = (images['backdrops'] as List<dynamic>? ?? [])
        .where((b) => b['file_path'] != null)
        .toList();
    final backdropUrl = backdrops.isNotEmpty
        ? '$_imageBaseUrl/w1280${backdrops.first['file_path']}'
        : null;

    final videos = data['videos'] as Map<String, dynamic>? ?? {};
    final results = videos['results'] as List<dynamic>? ?? [];
    String? trailerUrl;
    for (final video in results) {
      if (video['site'] == 'YouTube' &&
          video['type'] == 'Trailer' &&
          video['key'] != null) {
        trailerUrl = 'https://www.youtube.com/watch?v=${video['key']}';
        break;
      }
    }

    final keywordsData = data['keywords'] as Map<String, dynamic>? ?? {};
    final keywords = (keywordsData['keywords'] as List<dynamic>? ?? [])
        .map((k) => k['name'] as String)
        .toList();

    final genres = (data['genres'] as List<dynamic>? ?? [])
        .map((g) => g['name'] as String)
        .join(', ');

    final originCountry = (data['origin_country'] as List<dynamic>? ?? [])
        .map((c) => c.toString())
        .toList();

    final spokenLanguages = (data['spoken_languages'] as List<dynamic>? ?? [])
        .map((l) => l['english_name'] as String)
        .toList();

    return MovieDetail(
      id: data['id'].toString(),
      title: data['title'] ?? '',
      description: data['overview'] ?? '',
      posterUrl: data['poster_path'] != null
          ? '$_imageBaseUrl/w500${data['poster_path']}'
          : '',
      year: _parseYear(data['release_date']),
      genre: genres,
      director: _extractDirector(crewList),
      rating: (data['vote_average'] as num?)?.toDouble() ?? 0,
      pegi: _parseCertification(data),
      streamUrl: '', // Sera rempli par Xtream
      tmdbId: tmdbId,
      imdbId: imdbId,
      tvmazeId: tvmazeId,
      runtime: data['runtime'] as int? ?? 0,
      keywords: keywords,
      originCountry: originCountry,
      spokenLanguages: spokenLanguages,
      budget: data['budget'] as int? ?? 0,
      revenue: data['revenue'] as int? ?? 0,
      status: data['status'] ?? '',
      trailerUrl: trailerUrl,
      backdropUrl: backdropUrl,
      originalLanguage: data['original_language'],
      originalTitle: data['original_title'],
      cast: castList,
      crew: crewList,
      dataSource: 'tmdb',
    );
  }

  // ==================== SÉRIES (TMDB TV) ====================

  /// Recherche une série par titre + année
  Future<int?> searchTvId(String title, {int? year}) async {
    if (!hasApiKey) return null;
    await _waitForRateLimit();

    try {
      final queryParams = <String, String>{
        'query': title,
        'include_adult': 'false',
      };
      if (year != null && year > 0) {
        queryParams['first_air_date_year'] = year.toString();
      }

      final response =
          await _dio.get('/search/tv', queryParameters: queryParams);
      final results = response.data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        return results.first['id'] as int;
      }
    } catch (e) {
      _logger.warning('TMDB searchTvId error: $e');
    }
    return null;
  }

  /// Détails d'une série TV
  Future<SeriesDetail?> getTvDetail(int tmdbId) async {
    if (!hasApiKey) return null;

    final cacheKey = _cacheKey('tv', tmdbId.toString());
    final cached = _getCached(cacheKey, (d) => _parseTvDetail(d, tmdbId));
    if (cached != null) return cached;

    await _waitForRateLimit();

    try {
      final response = await _dio.get('/tv/$tmdbId', queryParameters: {
        'append_to_response': 'aggregate_credits,external_ids,keywords,videos',
      });

      final detail = _parseTvDetail(response.data, tmdbId);
      await _setCache(cacheKey, response.data);
      return detail;
    } catch (e) {
      _logger.warning('TMDB getTvDetail error: $e');
      return null;
    }
  }

  /// Détails d'une saison (pour guest stars)
  Future<Map<int, List<Actor>>?> getSeasonGuestStars(
      int tmdbId, List<int> seasonNumbers) async {
    if (!hasApiKey) return null;

    final guestStarsMap = <int, List<Actor>>{};

    for (final seasonNum in seasonNumbers) {
      if (seasonNum == 0) continue; // Skip specials
      await _waitForRateLimit();

      try {
        final response = await _dio.get('/tv/$tmdbId/season/$seasonNum');
        final episodes = response.data['episodes'] as List<dynamic>? ?? [];

        final seasonGuests = <Actor>[];
        for (final ep in episodes) {
          final guestStars = ep['guest_stars'] as List<dynamic>? ?? [];
          for (final guest in guestStars) {
            final actor = _parseActor(guest, ActorSource.tmdb)
                .copyWith(isGuestStar: true);
            // Éviter les doublons par ID
            if (!seasonGuests.any((a) => a.id == actor.id)) {
              seasonGuests.add(actor);
            }
          }
        }

        if (seasonGuests.isNotEmpty) {
          guestStarsMap[seasonNum] = seasonGuests;
        }
      } catch (e) {
        _logger.warning(
            'TMDB getSeasonGuestStars error for season $seasonNum: $e');
      }
    }

    return guestStarsMap.isEmpty ? null : guestStarsMap;
  }

  SeriesDetail _parseTvDetail(Map<String, dynamic> data, int tmdbId) {
    final externalIds = data['external_ids'] as Map<String, dynamic>? ?? {};
    final imdbId = externalIds['imdb_id'] as String? ?? '';
    final tvmazeId = externalIds['tvmaze_id'] as int? ?? 0;

    final aggregateCredits =
        data['aggregate_credits'] as Map<String, dynamic>? ?? {};
    final castList = (aggregateCredits['cast'] as List<dynamic>? ?? [])
        .map((e) => _parseActor(e, ActorSource.tmdb))
        .toList();

    final networks = (data['networks'] as List<dynamic>? ?? [])
        .map((n) => n['name'] as String)
        .toList();

    final keywordsData = data['keywords'] as Map<String, dynamic>? ?? {};
    final keywords = (keywordsData['results'] as List<dynamic>? ?? [])
        .map((k) => k['name'] as String)
        .toList();

    final genres = (data['genres'] as List<dynamic>? ?? [])
        .map((g) => g['name'] as String)
        .join(', ');

    final firstAirDate = data['first_air_date'] as String? ?? '';
    final lastAirDate = data['last_air_date'] as String?;

    return SeriesDetail(
      id: data['id'].toString(),
      title: data['name'] ?? '',
      description: data['overview'] ?? '',
      coverUrl: data['poster_path'] != null
          ? '$_imageBaseUrl/w500${data['poster_path']}'
          : '',
      year: _parseYear(firstAirDate),
      genre: genres,
      director: '', // TV shows don't have a single director
      rating: (data['vote_average'] as num?)?.toDouble() ?? 0,
      pegi: _parseCertification(data),
      episodes: const [],
      tmdbId: tmdbId,
      imdbId: imdbId,
      tvmazeId: tvmazeId,
      runtime: (data['episode_run_time'] as List<dynamic>? ?? []).firstOrNull
              as int? ??
          0,
      keywords: keywords,
      networks: networks,
      status: data['status'] ?? '',
      firstAirDate: firstAirDate,
      lastAirDate: lastAirDate,
      numberOfSeasons: data['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: data['number_of_episodes'] as int? ?? 0,
      originalLanguage: data['original_language'],
      originalName: data['original_name'],
      cast: castList,
      dataSource: 'tmdb',
    );
  }

  // ==================== HELPERS ====================

  Actor _parseActor(Map<String, dynamic> map, ActorSource source) {
    return Actor(
      id: map['id']?.toString() ?? map['cast_id']?.toString() ?? '',
      name: map['name'] ?? map['original_name'] ?? '',
      character: map['character'] ?? map['role'] ?? '',
      profilePath: map['profile_path'] ?? '',
      order: map['order'] ?? 0,
      isGuestStar: map['guest_star'] == true,
      source: source,
    );
  }

  int _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0;
    final match = RegExp(r'^(\d{4})').firstMatch(dateStr);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  String _extractDirector(List<CrewMember> crew) {
    final directors = crew
        .where((m) =>
            m.department.toLowerCase() == 'directing' &&
            m.job.toLowerCase().contains('director'))
        .toList();
    return directors.isNotEmpty ? directors.first.name : '';
  }

  String _parseCertification(Map<String, dynamic> data) {
    // TMDB certification est dans release_dates ou content_ratings
    // Pour simplifier, on retourne vide - sera complété par OMDB si nécessaire
    return '';
  }

  /// Ferme le cache
  Future<void> dispose() async {
    if (_cacheBox != null && _cacheBox!.isOpen) {
      await _cacheBox!.close();
    }
  }
}
