import 'dart:async';
import 'dart:typed_data';

import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/core/utils/catalog_diagnostic.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/services/catalog_disk_cache.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';

typedef MovieCatalogSync = Future<void> Function(
  String key,
  Uint8List bytes,
  List<Movie> items,
);
typedef SeriesCatalogSync = Future<void> Function(
  String key,
  Uint8List bytes,
  List<Series> items,
);

class XtreamMediaCatalogService {
  XtreamMediaCatalogService({
    required CatalogBytesLoader loadBytes,
    required PlayerApiUrlBuilder buildApiUrl,
    required Future<Map<String, String>> Function() loadVodCategoryNames,
    required MovieCatalogSync syncMovies,
    required SeriesCatalogSync syncSeries,
  })  : _loadBytes = loadBytes,
        _buildApiUrl = buildApiUrl,
        _loadVodCategoryNames = loadVodCategoryNames,
        _syncMovies = syncMovies,
        _syncSeries = syncSeries;

  final CatalogBytesLoader _loadBytes;
  final PlayerApiUrlBuilder _buildApiUrl;
  final Future<Map<String, String>> Function() _loadVodCategoryNames;
  final MovieCatalogSync _syncMovies;
  final SeriesCatalogSync _syncSeries;

  String _url(String base, String user, String password, String action) =>
      _buildApiUrl(base, 'player_api.php', {
        'username': user,
        'password': password,
        'action': action,
      });

  Future<List<Movie>> movies(String base, String user, String password) async {
    final key = '$base|$user';
    final bytes = await _loadBytes(
      'vod',
      key,
      _url(base, user, password, 'get_vod_streams'),
    );
    final categoryNames =
        await traceCatalogStep('vod', 'categories', _loadVodCategoryNames);
    final parsed = await traceCatalogStep(
      'vod',
      'parse',
      () => parseMoviesInBackground(MoviesParseInput(bytes, categoryNames)),
    );
    if (parsed.ignored > 0) {
      logDiag('VOD entrees ignorees=${parsed.ignored} '
          '(${parsed.firstError ?? ''})');
    }
    logDiag('Catalogue parse decode=${parsed.decodeMs}ms '
        'build=${parsed.buildMs}ms n=${parsed.items.length}');
    unawaited(traceCatalogStep(
      'vod',
      'database_sync',
      () => _syncMovies(key, bytes, parsed.items),
    ));
    return parsed.items;
  }

  Future<List<Series>> series(String base, String user, String password) async {
    final key = '$base|$user';
    final bytes = await _loadBytes(
      'series',
      key,
      _url(base, user, password, 'get_series'),
    );
    final parsed = await traceCatalogStep(
      'series',
      'parse',
      () => parseSeriesInBackground(bytes),
    );
    if (parsed.ignored > 0) {
      logDiag('SERIES entrees ignorees=${parsed.ignored} '
          '(${parsed.firstError ?? ''})');
    }
    logDiag('Catalogue parse decode=${parsed.decodeMs}ms '
        'build=${parsed.buildMs}ms n=${parsed.items.length}');
    unawaited(traceCatalogStep(
      'series',
      'database_sync',
      () => _syncSeries(key, bytes, parsed.items),
    ));
    return parsed.items;
  }
}
