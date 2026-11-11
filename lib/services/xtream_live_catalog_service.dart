import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/xtream_url_builder.dart';

typedef CatalogBytesLoader = Future<Uint8List> Function(
  String name,
  String cacheKey,
  String url, {
  bool useFreshCache,
});
typedef PlayerApiUrlBuilder = String Function(
  String baseUrl,
  String script,
  Map<String, String> parameters,
);

class XtreamLiveCatalogService {
  XtreamLiveCatalogService({
    required CatalogBytesLoader loadBytes,
    required PlayerApiUrlBuilder buildApiUrl,
  })  : _loadBytes = loadBytes,
        _buildApiUrl = buildApiUrl;

  final CatalogBytesLoader _loadBytes;
  final PlayerApiUrlBuilder _buildApiUrl;

  String _url(String base, String user, String password, String action) =>
      _buildApiUrl(base, 'player_api.php', {
        'username': user,
        'password': password,
        'action': action,
      });

  Future<List<Channel>> live(
    String base,
    String user,
    String password,
  ) async {
    final watch = Stopwatch()..start();
    final results = await Future.wait<Object?>([
      _liveCategoryNames(base, user, password),
      _loadBytes(
        'live',
        '$base|$user',
        _url(base, user, password, 'get_live_streams'),
      ),
    ]);
    final names = results[0]! as Map<String, String>;
    final bytes = results[1]! as Uint8List;
    logDiag('LIVE bytes=${bytes.length} loadMs=${watch.elapsedMilliseconds}');
    final streams = await compute(_decodeJsonList, bytes);
    logDiag('LIVE decoded n=${streams.length} '
        'sinceStartMs=${watch.elapsedMilliseconds}');
    final channels = _buildChannels(streams, names, base, user, password);
    logDiag('LIVE built n=${channels.length} '
        'sinceStartMs=${watch.elapsedMilliseconds}');
    return channels;
  }

  List<Channel> _buildChannels(
    List<dynamic> streams,
    Map<String, String> names,
    String base,
    String user,
    String password,
  ) {
    return streams.map((entry) {
      final map = Map<String, dynamic>.from(entry);
      final categoryId = map['category_id']?.toString() ?? '';
      if (names.containsKey(categoryId)) {
        map['category_name'] = names[categoryId];
      }
      final url = XtreamUrlBuilder.buildStreamUrl(
        base,
        user,
        password,
        map['stream_id']?.toString(),
      );
      final channel = Channel.fromMap(map).copyWith(streamUrl: url);
      channel.requireStreamUrl();
      return channel;
    }).toList();
  }

  Future<Map<String, String>> _liveCategoryNames(
    String base,
    String user,
    String password,
  ) async {
    final result = await safeAsync<Map<String, String>>(
      () async {
        final bytes = await _loadBytes(
          'live_cats',
          '$base|$user',
          _url(base, user, password, 'get_live_categories'),
        );
        final list = await compute(_decodeJsonList, bytes);
        final names = <String, String>{};
        for (final entry in list) {
          final map = Map<String, dynamic>.from(entry as Map);
          final id = map['category_id']?.toString();
          final name = map['category_name']?.toString() ?? '';
          if (id != null && id.isNotEmpty && name.isNotEmpty) names[id] = name;
        }
        return names;
      },
      context: 'ApiService._fetchLiveCategoryNames',
      fallbackValue: const <String, String>{},
    );
    return result.getOrElse(const <String, String>{});
  }

  Future<List<MediaCategory>> categories(
    String base,
    String user,
    String password, {
    required bool series,
  }) async {
    final bytes = await _loadBytes(
      series ? 'series_cats' : 'vod_cats',
      '$base|$user',
      _url(base, user, password,
          series ? 'get_series_categories' : 'get_vod_categories'),
      useFreshCache: false,
    );
    final raw = await compute(_decodeJsonList, bytes);
    return raw
        .whereType<Map>()
        .map((entry) => MediaCategory.fromMap(Map<String, dynamic>.from(entry)))
        .where((category) => category.id.isNotEmpty)
        .toList();
  }
}

List<dynamic> _decodeJsonList(Uint8List bytes) {
  Object? raw;
  try {
    raw = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    raw = jsonDecode(latin1.decode(bytes));
  }
  return raw is List ? raw : const <dynamic>[];
}
