import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/subscription_manager.dart';

class StreamNetworkException implements Exception {
  StreamNetworkException(this.message,
      {this.original, this.isRetriable = false,});

  final String message;
  final Object? original;
  final bool isRetriable;

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    followRedirects: true,
    maxRedirects: 5,
  ),);
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  Future<Response<dynamic>> _get(String url) {
    return stream_helpers.retryStream(
      () => _performGet(url),
      attempts: 2,
      shouldRetry: (error) {
        if (error is StreamNetworkException) return error.isRetriable;
        return true;
      },
    );
  }

  Future<Response<dynamic>> get(String url) => _get(url);

  Future<Response<dynamic>> _performGet(String url) async {
    try {
      return await _dio.get<dynamic>(url);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  StreamNetworkException _toNetworkException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return StreamNetworkException(
          'Délai de connexion au serveur dépassé (15 s). '
          'Vérifiez votre connexion Internet et la disponibilité du serveur.',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.sendTimeout:
        return StreamNetworkException(
          'Délai d\'envoi dépassé (15 s). Le serveur ne répond pas correctement.',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.receiveTimeout:
        return StreamNetworkException(
          'Le serveur met trop de temps à répondre (30 s). '
          'Le flux est peut-être indisponible ou bloqué (ex. Cloudflare).',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.transformTimeout:
        return StreamNetworkException(
          'La réponse du serveur n\'a pas pu être traitée à temps. '
          'Le flux est peut-être indisponible ou bloqué (ex. Cloudflare).',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.connectionError:
        return StreamNetworkException(
          'Impossible de se connecter au serveur. '
          'Vérifiez votre réseau et l\'accès au serveur.',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.badCertificate:
        return StreamNetworkException(
          'Certificat de sécurité invalide. '
          'Vérifiez la configuration HTTPS du serveur.',
          original: e,
        );
      case DioExceptionType.cancel:
        return StreamNetworkException('Requête annulée.', original: e);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final message = switch (status) {
          401 => 'Accès refusé par le serveur (code 401). '
              'Vérifiez vos identifiants Xtream.',
          403 => 'Accès refusé par le serveur (code 403). '
              'L\'abonnement est peut-être bloqué.',
          404 => 'Ressource introuvable (code 404). '
              'Vérifiez l\'adresse du serveur.',
          _ => 'Le serveur a renvoyé une erreur (code ${status ?? 'inconnu'}).',
        };
        return StreamNetworkException(message, original: e);
      case DioExceptionType.unknown:
        return StreamNetworkException(
          'Erreur réseau inattendue : ${e.message ?? e.runtimeType}.',
          original: e,
          isRetriable: true,
        );
    }
  }

  // ---------- Canaux live ----------
  Future<List<Channel>> fetchLiveChannels() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_live_streams',
      });
      final response = await _get(url);
      return (response.data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        final streamUrl = buildXtreamStreamUrl(
            baseUrl, username, password, map['stream_id']?.toString(),);
        final channel = Channel.fromMap(map).copyWith(streamUrl: streamUrl);
        channel.requireStreamUrl();
        return channel;
      }).toList();
    } else if (sub['type'] == 'm3u') {
      final url = sub['url']!;
      final response = await _get(url);
      return parseM3u(response.data.toString());
    } else {
      throw StreamNetworkException('Aucun abonnement configuré.');
    }
  }

  // ---------- Films (VOD) ----------
  Future<List<MediaCategory>> fetchVodCategories() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream') {
      return const [];
    }
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_vod_categories',
    });
    final response = await _get(url);
    final raw = response.data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MediaCategory.fromMap(Map<String, dynamic>.from(e)))
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  Future<List<MediaCategory>> fetchSeriesCategories() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream') {
      return const [];
    }
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_series_categories',
    });
    final response = await _get(url);
    final raw = response.data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MediaCategory.fromMap(Map<String, dynamic>.from(e)))
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  Future<List<Movie>> fetchMovies() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_vod_streams',
      });
      final response = await _get(url);
      return (response.data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        final streamUrl = buildXtreamStreamUrl(
            baseUrl, username, password, map['stream_id']?.toString(),
            type: 'movie', extension: map['container_extension']?.toString(),);
        final movie = Movie.fromMap(map).copyWith(streamUrl: streamUrl);
        movie.requireStreamUrl();
        return movie;
      }).toList();
    }
    throw StreamNetworkException(
        'Ce mode n\'est pas encore disponible pour cette section.',);
  }

  // ---------- Séries ----------
  Future<List<Series>> fetchSeries() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_series',
      });
      final response = await _get(url);
      return (response.data as List).map((e) => Series.fromMap(e)).toList();
    }
    throw StreamNetworkException(
        'Ce mode n\'est pas encore disponible pour cette section.',);
  }

  Future<Series> fetchSeriesInfo(String seriesId) async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream') {
      throw StreamNetworkException(
          'Ce mode n\'est pas encore disponible pour cette section.',);
    }
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_series_info',
      'series_id': seriesId,
    });
    final response = await _get(url);
    final data = response.data;
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
    final rootSorted = root;
    final info = rootSorted['info'];
    final stitched = Map<String, dynamic>.from(
      info is Map ? Map<String, dynamic>.from(info) : const <String, dynamic>{},
    );
    stitched['series_id'] = seriesId;
    final episodeMaps = <Map<String, dynamic>>[];
    final rawEpisodes = root['episodes'];
    if (rawEpisodes is Map) {
      for (final seasonEntry in rawEpisodes.entries) {
        final season = int.tryParse(seasonEntry.key.toString()) ?? 0;
        final list =
            seasonEntry.value is List ? seasonEntry.value as List : const [];
        for (final raw in list) {
          final em = Map<String, dynamic>.from(raw as Map);
          em['season'] = season;
          final id = em['id']?.toString() ?? '';
          em['url'] = id.isEmpty
              ? ''
              : buildXtreamStreamUrl(
                  baseUrl,
                  username,
                  password,
                  id,
                  type: 'series',
                  extension: em['container_extension']?.toString(),
                );
          episodeMaps.add(em);
        }
      }
    }
    stitched['episodes'] = episodeMaps;
    return Series.fromMap(stitched);
  }

  // ---------- Radios ----------
  Future<List<Channel>> fetchRadioChannels() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;

      // Identifie la catégorie "Radio" parmi les catégories live, puis ne
      // garde que les flux appartenant à cette catégorie. Beaucoup de
      // serveurs ignorent `category=radio` sur get_live_streams et
      // renverraient alors tout le Live TV.
      final radioCategoryIds = await _fetchRadioCategoryIds(
        baseUrl,
        username,
        password,
      );

      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_live_streams',
      });
      final response = await _get(url);
      return (response.data as List)
          .whereType<Map>()
          .where((e) =>
              radioCategoryIds.isEmpty ||
              radioCategoryIds.contains(e['category_id']?.toString()),)
          .map((e) {
            final map = Map<String, dynamic>.from(e);
            final streamUrl = buildXtreamStreamUrl(
              baseUrl,
              username,
              password,
              map['stream_id']?.toString(),
            );
            return Channel.fromMap(map).copyWith(streamUrl: streamUrl);
          })
          .toList();
    }
    throw StreamNetworkException(
        'Ce mode n\'est pas encore disponible pour cette section.',);
  }

  Future<Set<String>> _fetchRadioCategoryIds(
    String baseUrl,
    String username,
    String password,
  ) async {
    try {
      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_live_categories',
      });
      final response = await _get(url);
      final categories = response.data as List;
      return categories
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((c) {
            final name = '${c['category_name'] ?? ''}'.toLowerCase();
            return name.contains('radio') || name.contains('musique') ||
                name.contains('music');
          })
          .map((c) => c['category_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  // ---------- Replays ----------
  Future<List<ReplayItem>> fetchReplays() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_simple_data_table',
        'stream_id': 'replay',
      });
      final response = await _get(url);
      return (response.data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        final id = map['stream_id']?.toString() ?? '';
        final streamUrl = id.isEmpty
            ? ''
            : buildXtreamStreamUrl(
                baseUrl,
                username,
                password,
                id,
                extra: {
                  'start': '${map['start'] ?? ''}',
                  'end': '${map['end'] ?? ''}',
                },
              );
        final replay = ReplayItem.fromMap(map).copyWith(streamUrl: streamUrl);
        replay.requireStreamUrl();
        return replay;
      }).toList();
    }
    throw StreamNetworkException(
        'Ce mode n\'est pas encore disponible pour cette section.',);
  }

  // ---------- EPG (XMLTV) ----------
  Future<List<EPGProgram>> fetchEpg() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = _playerApiUrl(baseUrl, 'xmltv.php', {
        'username': username,
        'password': password,
      });
      final response = await _get(url);
      return parseXmltv(response.data.toString());
    }
    // Les flux M3U ne fournissent pas de guide XMLTV : pas de programme,
    // plutôt que de lever une erreur technique à l'écran.
    return const <EPGProgram>[];
  }

  static String _trimBaseUrl(String baseUrl) {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    const suffix = '/player_api.php';
    if (url.toLowerCase().endsWith(suffix)) {
      url = url.substring(0, url.length - suffix.length);
    }
    return url;
  }

  static String _playerApiUrl(
      String baseUrl, String script, Map<String, String> params,) {
    final uri = Uri.parse(_trimBaseUrl(baseUrl));
    final segments = [...uri.pathSegments.where((s) => s.isNotEmpty), script];
    return uri
        .replace(pathSegments: segments, queryParameters: params)
        .toString();
  }

  String buildXtreamStreamUrl(
    String baseUrl,
    String username,
    String password,
    String? streamId, {
    String type = '',
    String? extension,
    bool withExtension = false,
    Map<String, String> extra = const {},
  }) {
    if (streamId == null || streamId.isEmpty) return '';
    final uri = Uri.parse(_trimBaseUrl(baseUrl));
    final segments = <String>[
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      username,
      password,
    ];
    final mediaType = type.toLowerCase();
    if (mediaType == 'movie') {
      segments.add('movie');
    } else if (mediaType == 'series') {
      segments.add('series');
    }
    var mediaId = streamId;
    // Les serveurs Xtream récents (ex. draap.online) servent le fichier
    // :/movie/{id} et :/series/{id} sans extension ; forcer ".mp4" renvoie
    // un 404. On ne l'ajoute que si l'appelant le demande explicitement
    // (withExtension) pour les serveurs legacy qui l'exigent.
    if ((mediaType == 'movie' || mediaType == 'series') && withExtension) {
      final ext = _normalizeExtension(extension);
      mediaId = '$streamId.$ext';
    }
    segments.add(mediaId);
    final query = extra.isEmpty ? null : extra;
    return uri
        .replace(pathSegments: segments, queryParameters: query)
        .toString();
  }

  static String _normalizeExtension(String? extension) {
    if (extension == null || extension.trim().isEmpty) return 'mp4';
    return extension.trim().replaceFirst(RegExp(r'^\.'), '').toLowerCase();
  }

  List<Channel> parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <Channel>[];
    String? currentName;
    for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        if (nameMatch != null) {
          currentName = nameMatch.group(1)!.trim();
        }
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentName != null) {
          channels.add(Channel(
            id: channels.length.toString(),
            name: currentName,
            logoUrl: '',
            streamUrl: stream_helpers.requireStreamUrl(line.trim(),
                label: currentName,),
            group: '',
          ),);
          currentName = null;
        }
      }
    }
    return channels;
  }

  // ---------- Parseur XMLTV basique ----------
  List<EPGProgram> parseXmltv(String content) {
    final document = XmlDocument.parse(content);
    final programs = <EPGProgram>[];
    for (final prog in document.findAllElements('programme')) {
      final channelId = prog.getAttribute('channel') ?? '';
      final title = prog.getElement('title')?.innerText ?? '';
      final desc = prog.getElement('desc')?.innerText ?? '';
      final start =
          stream_helpers.parseXmltvDate(prog.getAttribute('start') ?? '');
      final end =
          stream_helpers.parseXmltvDate(prog.getAttribute('stop') ?? '');
      if (start == null || end == null) continue;
      programs.add(EPGProgram(
        channelId: channelId,
        title: title,
        description: desc,
        start: start,
        end: end,
      ),);
    }
    return programs;
  }
}
