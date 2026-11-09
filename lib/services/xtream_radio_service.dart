import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
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
      'RADIO categories=resolved count=${categoryIds.length} '
      'filter=${categoryIds.isEmpty ? 'disabled' : 'enabled'}',
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
    final channels = rawStreams
        .whereType<Map>()
        .where(
          (entry) =>
              categoryIds.isEmpty ||
              categoryIds.contains(entry['category_id']?.toString()),
        )
        .map((entry) {
      final map = Map<String, dynamic>.from(entry);
      final streamUrl = XtreamUrlBuilder.buildStreamUrl(
        base,
        user,
        password,
        map['stream_id']?.toString(),
      );
      return Channel.fromMap(map).copyWith(streamUrl: streamUrl);
    }).toList();
    logDiag(
      'RADIO streams=complete received=${rawStreams.length} '
      'matched=${channels.length} durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return channels;
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
        return categories
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .where((category) {
              final name = '${category['category_name'] ?? ''}'.toLowerCase();
              return name.contains('radio') ||
                  name.contains('musique') ||
                  name.contains('music');
            })
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
      'matched=${ids.length} durationMs=${stopwatch.elapsedMilliseconds}'
      '${result.isFailure ? ' fallback=unfiltered' : ''}',
    );
    return ids;
  }
}
