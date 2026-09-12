import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';

/// Client OMDB (Open Movie Database) pour fallback année/runtime/rating
/// Nécessite clé API dans .env : OMDB_API_KEY
class OmdbService {
  static const String _baseUrl = 'https://www.omdbapi.com';
  static const String _cacheBoxName = 'metadata_cache';
  static const Duration _cacheTtl = Duration(hours: 24);
  static const Duration _minRequestInterval = Duration(seconds: 1); // 1 req/s

  /// Accès sûr à dotenv : renvoie '' si dotenv n'est pas initialisé.
  static String _env(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  final Dio _dio;
  final LoggerService _logger = LoggerService.instance;
  Box? _cacheBox;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  OmdbService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),) {
    _initCache();
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (msg) => _logger.debug('[OMDB] $msg'),
    ),);
  }

  Future<void> _initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
    } else {
      _cacheBox = Hive.box(_cacheBoxName);
    }
  }

  String get _apiKey => _env('OMDB_API_KEY');

  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Rate limiter : 1 req/s
  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequest);
    if (elapsed < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - elapsed);
    }
    _lastRequest = DateTime.now();
  }

  String _cacheKey(String prefix, String id) => 'omdb:$prefix:$id';

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

  // ==================== FILM PAR IMDB ID ====================

  /// Récupère les détails complets par IMDB ID (fallback principal)
  Future<Map<String, dynamic>?> getByImdbId(String imdbId) async {
    if (!hasApiKey || imdbId.isEmpty) return null;

    final cacheKey = _cacheKey('imdb', imdbId);
    final cached = _getCached(cacheKey, (d) => d);
    if (cached != null) return cached;

    await _waitForRateLimit();

    try {
      final response = await _dio.get('/', queryParameters: {
        'i': imdbId,
        'plot': 'full',
        'apikey': _apiKey,
      },);

      if (response.data['Response'] == 'True') {
        await _setCache(cacheKey, response.data);
        return response.data;
      } else {
        _logger.warning('OMDB error: ${response.data['Error']}');
        return null;
      }
    } catch (e) {
      _logger.warning('OMDB getByImdbId error: $e');
      return null;
    }
  }

  /// Récupère par titre + année (recherche)
  Future<Map<String, dynamic>?> searchByTitle(String title, {int? year}) async {
    if (!hasApiKey) return null;

    final cacheKey = _cacheKey('search', '${title}_${year ?? ''}');
    final cached = _getCached(cacheKey, (d) => d);
    if (cached != null) return cached;

    await _waitForRateLimit();

    try {
      final params = <String, String>{
        't': title,
        'plot': 'full',
        'apikey': _apiKey,
      };
      if (year != null && year > 0) {
        params['y'] = year.toString();
      }

      final response = await _dio.get('/', queryParameters: params);

      if (response.data['Response'] == 'True') {
        await _setCache(cacheKey, response.data);
        return response.data;
      } else {
        _logger.warning('OMDB search error: ${response.data['Error']}');
        return null;
      }
    } catch (e) {
      _logger.warning('OMDB searchByTitle error: $e');
      return null;
    }
  }

  // ==================== ENRICHISSEMENT FILM ====================

  /// Complète les champs manquants d'un MovieDetail depuis OMDB
  Future<MovieDetail> fillMissingMovie(MovieDetail detail) async {
    if (!hasApiKey) return detail;

    Map<String, dynamic>? data;

    // Essayer par IMDB ID d'abord
    if (detail.imdbId.isNotEmpty) {
      data = await getByImdbId(detail.imdbId);
    }

    // Fallback par titre + année
    if (data == null && detail.title.isNotEmpty) {
      data = await searchByTitle(detail.title,
          year: detail.year > 0 ? detail.year : null,);
    }

    if (data == null) return detail;

    return _mergeOmdbData(detail, data);
  }

  MovieDetail _mergeOmdbData(MovieDetail detail, Map<String, dynamic> data) {
    final year = _parseYear(data['Year']);
    final runtime = _parseRuntime(data['Runtime']);
    final genre = data['Genre'] as String? ?? '';
    final director = data['Director'] as String? ?? '';
    final imdbRating = data['imdbRating'] as String? ?? '';
    final imdbVotes = data['imdbVotes'] as String? ?? '';
    final country = data['Country'] as String? ?? '';
    final language = data['Language'] as String? ?? '';
    final awards = data['Awards'] as String? ?? '';
    final boxOffice = data['BoxOffice'] as String? ?? '';
    final production = data['Production'] as String? ?? '';
    final website = data['Website'] as String? ?? '';
    final dvd = data['DVD'] as String? ?? '';
    final imdbId = data['imdbID'] as String? ?? '';

    return detail.copyWith(
      year: detail.year > 0 ? detail.year : year,
      runtime: detail.runtime > 0 ? detail.runtime : runtime,
      genre: detail.genre.isNotEmpty ? detail.genre : genre,
      director: detail.director.isNotEmpty ? detail.director : director,
      rating:
          detail.rating > 0 ? detail.rating : double.tryParse(imdbRating) ?? 0,
      originCountry: detail.originCountry.isNotEmpty
          ? detail.originCountry
          : country.split(',').map((c) => c.trim()).toList(),
      spokenLanguages: detail.spokenLanguages.isNotEmpty
          ? detail.spokenLanguages
          : language.split(',').map((l) => l.trim()).toList(),
      budget: detail.budget > 0 ? detail.budget : _parseBoxOffice(boxOffice),
      revenue: detail.revenue > 0 ? detail.revenue : _parseBoxOffice(boxOffice),
      imdbId: detail.imdbId.isNotEmpty ? detail.imdbId : imdbId,
      dataSource: 'omdb',
    );
  }

  // ==================== ENRICHISSEMENT SÉRIE ====================

  /// Complète les champs manquants d'un SeriesDetail depuis OMDB
  Future<SeriesDetail> fillMissingSeries(SeriesDetail detail) async {
    if (!hasApiKey) return detail;

    Map<String, dynamic>? data;

    if (detail.imdbId.isNotEmpty) {
      data = await getByImdbId(detail.imdbId);
    }

    if (data == null && detail.title.isNotEmpty) {
      data = await searchByTitle(detail.title,
          year: detail.year > 0 ? detail.year : null,);
    }

    if (data == null) return detail;

    return _mergeOmdbSeriesData(detail, data);
  }

  SeriesDetail _mergeOmdbSeriesData(
      SeriesDetail detail, Map<String, dynamic> data,) {
    final year = _parseYear(data['Year']);
    final runtime = _parseRuntime(data['Runtime']);
    final genre = data['Genre'] as String? ?? '';
    final network = data['Network'] as String? ?? '';
    final imdbRating = data['imdbRating'] as String? ?? '';
    final totalSeasons = data['totalSeasons'] as String? ?? '';
    final imdbId = data['imdbID'] as String? ?? '';

    return detail.copyWith(
      year: detail.year > 0 ? detail.year : year,
      runtime: detail.runtime > 0 ? detail.runtime : runtime,
      genre: detail.genre.isNotEmpty ? detail.genre : genre,
      networks: detail.networks.isNotEmpty
          ? detail.networks
          : [network].where((n) => n.isNotEmpty).toList(),
      rating:
          detail.rating > 0 ? detail.rating : double.tryParse(imdbRating) ?? 0,
      numberOfSeasons: detail.numberOfSeasons > 0
          ? detail.numberOfSeasons
          : int.tryParse(totalSeasons) ?? 0,
      imdbId: detail.imdbId.isNotEmpty ? detail.imdbId : imdbId,
      dataSource: 'omdb',
    );
  }

  // ==================== HELPERS ====================

  int _parseYear(String? yearStr) {
    if (yearStr == null || yearStr == 'N/A') return 0;
    final match = RegExp(r'(\d{4})').firstMatch(yearStr);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  int _parseRuntime(String? runtimeStr) {
    if (runtimeStr == null || runtimeStr == 'N/A') return 0;
    final match = RegExp(r'(\d+)').firstMatch(runtimeStr);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  int _parseBoxOffice(String? boxOfficeStr) {
    if (boxOfficeStr == null || boxOfficeStr == 'N/A') return 0;
    // Format: $123,456,789
    final clean = boxOfficeStr.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(clean) ?? 0;
  }

  Future<void> dispose() async {
    if (_cacheBox != null && _cacheBox!.isOpen) {
      await _cacheBox!.close();
    }
  }
}
