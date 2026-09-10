import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/trakt_rank_entry.dart';

/// Client Trakt (classements populaires/tendances films + séries).
/// API publique gratuite, clé applicative partagée (`TRAKT_CLIENT_ID`),
/// sans OAuth : https://docs.trakt.tv/
class TraktService {
  static const String _baseUrl = 'https://api.trakt.tv';
  static const String _cacheBoxName = 'metadata_cache';
  static const Duration _cacheTtl = Duration(hours: 24);
  // Trakt : 1000 appels / 5 min par clé applicative. On reste sage : 40/10s.
  static const int _maxRequestsPer10Seconds = 40;

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
  final _requestTimestamps = <int>[];

  TraktService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Orbit/1.0',
            'trakt-api-version': '2',
            'trakt-api-key': _env('TRAKT_CLIENT_ID'),
          },
        ),
      ) {
    _initCache();
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (msg) => _logger.debug('[Trakt] $msg'),
      ),
    );
  }

  Future<void> _initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
    } else {
      _cacheBox = Hive.box(_cacheBoxName);
    }
  }

  String get _clientId => _env('TRAKT_CLIENT_ID');

  bool get hasApiKey => _clientId.isNotEmpty;

  /// Rate limiter : max [maxRequestsPer10Seconds] req / 10 s (token bucket).
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
  String _cacheKey(String prefix, String path) => 'trakt:$prefix:$path';

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

  // ==================== CLASSEMENTS (populaires / tendances) ====================

  /// Films populaires (Trakt top).
  Future<List<TraktRankEntry>> getPopularMovies({int limit = 24}) =>
      _getRankings('/movies/popular', isTv: false, limit: limit);

  /// Séries populaires (Trakt top).
  Future<List<TraktRankEntry>> getPopularShows({int limit = 24}) =>
      _getRankings('/shows/popular', isTv: true, limit: limit);

  /// Films visionnés en ce moment (tendance temps réel).
  Future<List<TraktRankEntry>> getTrendingMovies({int limit = 24}) =>
      _getRankings('/movies/trending', isTv: false, limit: limit);

  /// Séries visionnées en ce moment (tendance temps réel).
  Future<List<TraktRankEntry>> getTrendingShows({int limit = 24}) =>
      _getRankings('/shows/trending', isTv: true, limit: limit);

  /// Charge un endpoint de classement Trakt via le cache partagé (TTL 24 h)
  /// et le rate limiter. `extended=full` ajoute images, genres, runtime, etc.
  Future<List<TraktRankEntry>> _getRankings(
    String path, {
    required bool isTv,
    int limit = 24,
  }) async {
    if (!hasApiKey) return const [];
    final cacheKey = _cacheKey(isTv ? 'rank_show' : 'rank_movie', path);
    final parse = _rankingParser(path, isTv: isTv);
    final cached = _getCached(cacheKey, parse);
    if (cached != null) return cached;

    await _waitForRateLimit();

    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {
          'extended': 'full',
          'limit': '$limit',
        },
      );
      if (response.data == null) return const [];
      await _setCache(cacheKey, {'items': response.data});
      return parse({'items': response.data});
    } catch (e) {
      _logger.warning('Trakt $path error: $e');
      return const [];
    }
  }

  /// Parser d'une liste : trending = {@code {watchers, movie|show}}, sinon objets directs.
  List<TraktRankEntry> Function(Map<String, dynamic>) _rankingParser(
    String path, {
    required bool isTv,
  }) {
    final isTrending = path.contains('/trending');
    return (data) {
      final items = data['items'] as List<dynamic>? ?? [];
      return items.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (isTrending) {
          return isTv
              ? TraktRankEntry.fromTrendingShowJson(map)
              : TraktRankEntry.fromTrendingMovieJson(map);
        }
        return isTv
            ? TraktRankEntry.fromShowJson(map)
            : TraktRankEntry.fromMovieJson(map);
      }).toList();
    };
  }

  /// Ferme le cache
  Future<void> dispose() async {
    if (_cacheBox != null && _cacheBox!.isOpen) {
      await _cacheBox!.close();
    }
  }
}