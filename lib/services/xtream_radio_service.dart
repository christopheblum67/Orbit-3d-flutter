import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/xtream_taxonomy.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';
import 'package:orbit_3d_flutter/services/xtream_url_builder.dart';

typedef RadioHttpGet = Future<Response<dynamic>> Function(String url);

class XtreamRadioService {
  XtreamRadioService({
    required PlayerApiUrlBuilder buildApiUrl,
    required RadioHttpGet get,
  })  : _buildApiUrl = buildApiUrl,
        _get = get;

  final PlayerApiUrlBuilder _buildApiUrl;
  final RadioHttpGet _get;

  String _url(String base, String user, String password, String action) =>
      _buildApiUrl(base, 'player_api.php', {
        'username': user,
        'password': password,
        'action': action,
      });

  Future<List<Channel>> fetch(String base, String user, String password) async {
    final categoryIds = await _fetchCategoryIds(base, user, password);
    logDiag(
      'RADIO categories=resolved count=${categoryIds.length}',
    );
    final stopwatch = Stopwatch()..start();
    logDiag('RADIO streams=request start');
    final response = await _get(_url(base, user, password, 'get_live_streams'));
    final rawStreams = response.data;
    if (rawStreams is! List) {
      logDiag(
        'RADIO streams=invalid-response '
        'type=${rawStreams.runtimeType} durationMs=${stopwatch.elapsedMilliseconds}',
      );
      throw const FormatException('Réponse de flux Radio invalide.');
    }
    // Chez certains panels les stations n'ont aucune catégorie
    // (`category_id` nul), alors que toutes les chaînes TV en ont une.
    bool isRadio(Map entry) {
      final id = entry['category_id']?.toString().trim() ?? '';
      return id.isEmpty || id == 'null' || categoryIds.contains(id);
    }

    final channels = rawStreams.whereType<Map>().where(isRadio).map((entry) {
      final map = Map<String, dynamic>.from(entry);
      final streamUrl = XtreamUrlBuilder.buildStreamUrl(
        base,
        user,
        password,
        map['stream_id']?.toString(),
      );
      return Channel.fromMap(map).copyWith(streamUrl: streamUrl);
    }).toList();
    final kept = rawStreams.whereType<Map>().where(isRadio).toList();
    final uncategorized = kept
        .where((e) => !categoryIds.contains(e['category_id']?.toString()))
        .toList();
    logDiag(
      'RADIO split byCategory=${kept.length - uncategorized.length} '
      'uncategorized=${uncategorized.length} '
      'sampleUncat=${_sample(uncategorized)} '
      'sampleCat=${_sample(kept.where((e) => categoryIds.contains(e['category_id']?.toString())).toList())}',
    );
    logDiag(
      'RADIO streams=complete received=${rawStreams.length} '
      'matched=${channels.length} durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return channels;
  }

  static String _sample(List<Map> entries) {
    if (entries.isEmpty) return '-';
    final step = (entries.length / 40).ceil().clamp(1, entries.length);
    return [
      for (var i = 0; i < entries.length; i += step) '${entries[i]['name']}',
    ].join(' ; ');
  }

  Future<Set<String>> _fetchCategoryIds(
    String base,
    String user,
    String password,
  ) async {
    final stopwatch = Stopwatch()..start();
    logDiag('RADIO categories=request start');
    final result = await safeAsync<Set<String>>(
      () async {
        final response =
            await _get(_url(base, user, password, 'get_live_categories'));
        final categories = response.data as List;
        final maps = categories
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
        logDiag(
          'RADIO liveCategories=${maps.length} names='
          '${maps.map((c) => '${c['category_id']}=${c['category_name']}').join(' ; ')}',
        );
        final matched = maps.where((category) {
          return XtreamTaxonomy.isRadioCategory(
            '${category['category_name'] ?? ''}',
          );
        }).toList();
        logDiag(
          'RADIO categoryNames=${matched.map((c) => c['category_name']).join(' ; ')}',
        );
        return matched
            .map((category) => category['category_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      },
      context: 'ApiService._fetchRadioCategoryIds',
      fallbackValue: const <String>{},
    );
    final ids = result.getOrElse(const <String>{});
    logDiag(
      'RADIO categories=${result.isSuccess ? 'complete' : 'failed'} '
      'matched=${ids.length} durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return ids;
  }
}
