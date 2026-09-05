import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
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
          429 => 'Limite de requêtes dépassée (code 429). '
              'Le serveur limite le nombre de requêtes. '
              'Réessayez dans quelques instants.',
          _ => 'Le serveur a renvoyé une erreur (code ${status ?? 'inconnu'}).',
        };
        return StreamNetworkException(message, original: e,
            isRetriable: status == 429,
          );
      case DioExceptionType.unknown:
        return StreamNetworkException(
          'Erreur réseau inattendue : ${e.message ?? e.runtimeType}.',
          original: e,
          isRetriable: true,
        );
    }
  }

  // ---------- Informations du compte (validité) ----------
  /// Récupère la date d'expiration du compte Xtream via
  /// `get_user_info` (champ `exp_date`, timestamp Unix en secondes).
  /// Renvoie `null` si l'information n'est pas disponible (M3U, champ absent…).
  Future<DateTime?> fetchExpiration() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream') return null;
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_user_info',
    });
    try {
      final response = await _get(url);
      final data = response.data;
      if (data is! Map) return null;
      final raw = data['user_info'];
      final info = raw is Map ? raw : data;
      final expRaw = info['exp_date'];
      if (expRaw == null) return null;
      final seconds = int.tryParse('$expRaw');
      // Certains serveurs renvoient 0 pour « illimité ».
      if (seconds == null || seconds <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  // ---------- Canaux live ----------
  Future<List<Channel>> fetchLiveChannels() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final categoryNames =
          await _fetchLiveCategoryNames(baseUrl, username, password);
      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_live_streams',
      });
      final response = await _get(url);
      return (response.data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        final categoryId = map['category_id']?.toString() ?? '';
        if (categoryNames.containsKey(categoryId)) {
          map['category_name'] = categoryNames[categoryId];
        }
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

  Future<Map<String, String>> _fetchLiveCategoryNames(
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
      if (response.data is! List) return const {};
      final map = <String, String>{};
      for (final e in response.data as List) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = m['category_id']?.toString();
        final name = m['category_name']?.toString() ?? '';
        if (id != null && id.isNotEmpty && name.isNotEmpty) {
          map[id] = name;
        }
      }
      return map;
    } catch (_) {
      return const {};
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
            baseUrl,
            username,
            password,
            map['stream_id']?.toString(),
            type: 'movie',
            extension: map['container_extension']?.toString(),
            withExtension: true,
        );
        final movie = Movie.fromMap(map).copyWith(streamUrl: streamUrl);
        movie.requireStreamUrl();
        return movie;
      }).toList();
    }
    throw StreamNetworkException(
        'Ce mode n\'est pas encore disponible pour cette section.',);
  }

  /// Enrichit un film avec les métadonnées détaillées du serveur grâce à
  /// `get_vod_info` (synopsis, année, genre, réalisateur, note, âge/PEGI).
  /// L'endpoint de liste `get_vod_streams` ne fournit pas ces champs, d'où
  /// l'appel ciblé au détail. Renvoie une copie enrichie de [movie], ou le
  /// film d'origine inchangé si l'information n'est pas disponible.
  Future<Movie> fetchMovieDetail(Movie movie) async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream' || movie.id.isEmpty) return movie;
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_vod_info',
      'vod_id': movie.id,
    });
    try {
      final response = await _get(url);
      final data = response.data;
      if (data is! Map) return movie;
      final rawInfo = data['info'];
      final info = rawInfo is Map ? rawInfo : <String, dynamic>{};

      // Année depuis `releaseDate` (YYYY-...), sinon depuis `releasedate`.
      var year = movie.year;
      final releaseDate =
          firstNonEmpty([info['releaseDate'], info['releasedate']]).toString();
      final ym = RegExp(r'^(\d{4})').firstMatch(releaseDate);
      if (ym != null) year = int.tryParse(ym.group(1)!) ?? year;

      final genreRaw = firstNonEmpty([
        info['genre'],
        info['genre_1'],
        movie.genre,
      ]).toString().trim();

      var rating = movie.rating;
      final ratingRaw = firstNonEmpty([info['rating'], info['rating_5based']])
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
      if (ratingRaw.isNotEmpty) rating = double.tryParse(ratingRaw) ?? rating;

      final posterUrl = firstNonEmpty([
        info['cover_big'],
        info['movie_image'],
        info['backdrop_path'],
        movie.posterUrl,
      ]).toString();

      return Movie(
        id: movie.id,
        title: movie.title,
        description: firstNonEmpty([
          info['description'],
          info['plot'],
          movie.description,
        ]).toString(),
        posterUrl: posterUrl,
        year: year,
        genre: genreRaw,
        director: firstNonEmpty([
          info['director'],
          movie.director,
        ]).toString(),
        rating: rating,
        pegi: firstNonEmpty([
          info['age'],
          info['mpaa_rating'],
          info['us_certification'],
          movie.pegi,
        ]).toString(),
        streamUrl: movie.streamUrl,
        categoryId: movie.categoryId,
      );
    } catch (_) {
      return movie;
    }
  }

  /// Récupère le casting et l'équipe technique d'un film (cast + crew).
  /// Nécessite un serveur Xtream compatible avec l'endpoint `get_vod_info`
  /// qui retourne les champs `cast` et `crew` (format TMDB-like).
  Future<MovieCredits?> fetchMovieCredits(String movieId) async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream' || movieId.isEmpty) return null;
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_vod_info',
      'vod_id': movieId,
    });
    try {
      final response = await _get(url);
      final data = response.data;
      if (data is! Map) return null;
      final rawInfo = data['info'];
      final info = rawInfo is Map
          ? Map<String, dynamic>.from(rawInfo)
          : <String, dynamic>{};
      return MovieCredits.fromMap(info);
    } catch (_) {
      return null;
    }
  }

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
                  withExtension: true,
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
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        final inner = data['epg_listings'] ?? data['replay'] ?? data['data'];
        list = inner is List ? inner : const [];
      } else {
        list = const [];
      }
      return list.map((e) {
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
    final mediaType = type.toLowerCase();
    // Live et Radio : `/u/p/{id}`, redirigé vers un CDN signé.
    // Movie/Séries : chemin Xtream standard `/movie/{u}/{p}/{id}` ou
    // `/series/{u}/{p}/{id}` — c'est la seule forme que draap.online sert
    // (302 → CDN) ; `/u/p/movie/{id}` renvoyait 401/406.
    final segments = <String>[];
    if (mediaType == 'movie' || mediaType == 'series') {
      segments.add(mediaType);
    }
    segments.addAll(<String>[
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      username,
      password,
    ]);
    var mediaId = streamId;
    // Les serveurs Xtream récents (ex. draap.online) servent le fichier
    // /movie/{id} et /series/{id} sans extension ; forcer ".mp4" renvoie
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
