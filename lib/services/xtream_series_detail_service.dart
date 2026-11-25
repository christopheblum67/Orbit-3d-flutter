import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';
import 'package:orbit_3d_flutter/services/xtream_url_builder.dart';

class XtreamSeriesDetailService {
  XtreamSeriesDetailService({
    required PlayerApiUrlBuilder buildApiUrl,
    required Future<Response<dynamic>> Function(String url, {Options? options})
        get,
  })  : _buildApiUrl = buildApiUrl,
        _get = get;

  final PlayerApiUrlBuilder _buildApiUrl;
  final Future<Response<dynamic>> Function(String url, {Options? options}) _get;

  Future<Series> fetch(
    String seriesId,
    String baseUrl,
    String username,
    String password,
  ) async {
    final url = _buildApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_series_info',
      'series_id': seriesId,
    });
    final response = await _get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = _decodeJsonPayload(response);
    Map<String, dynamic> root;
    if (data is List) {
      if (data.isEmpty) {
        throw StreamNetworkException(
          'Aucun détail disponible pour cette série.',
        );
      }
      root = Map<String, dynamic>.from(data.first as Map);
    } else if (data is Map) {
      root = Map<String, dynamic>.from(data);
    } else {
      throw StreamNetworkException(
        'Réponse inattendue du serveur pour cette série.',
      );
    }
    final info = root['info'];
    final stitched = Map<String, dynamic>.from(
      info is Map ? Map<String, dynamic>.from(info) : const <String, dynamic>{},
    );
    stitched['series_id'] = seriesId;
    final episodeMaps = <Map<String, dynamic>>[];
    final rawEpisodes = root['episodes'];
    final seasons = rawEpisodes is Map
        ? rawEpisodes
        : rawEpisodes is List
            ? rawEpisodes.asMap()
            : const {};
    for (final seasonEntry in seasons.entries) {
      final season = int.tryParse(seasonEntry.key.toString()) ?? 0;
      final list =
          seasonEntry.value is List ? seasonEntry.value as List : const [];
      for (final raw in list) {
        final em = Map<String, dynamic>.from(raw as Map);
        em['season'] = season;
        final id = em['id']?.toString() ?? '';
        em['url'] = id.isEmpty
            ? ''
            : XtreamUrlBuilder.buildStreamUrl(
                baseUrl,
                username,
                password,
                id,
                type: 'series',
                extension: em['container_extension']?.toString(),
                withExtension: true,
              );
        episodeMaps.add(em);
      }
    }
    stitched['episodes'] = episodeMaps;
    return Series.fromMap(stitched);
  }

  static dynamic _decodeJsonPayload(Response<dynamic> response) {
    final dynamic data = response.data;
    if (data is! List<int>) return data;
    try {
      return jsonDecode(utf8.decode(data));
    } catch (_) {
      // Some panels return JSON encoded as Latin-1.
    }
    try {
      return jsonDecode(latin1.decode(data));
    } catch (_) {
      return null;
    }
  }
}
