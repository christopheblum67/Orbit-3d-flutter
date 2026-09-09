import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/subscription_manager.dart';

class StreamNetworkException implements Exception {
  StreamNetworkException(
    this.message, {
    this.original,
    this.isRetriable = false,
  });

  final String message;
  final Object? original;
  final bool isRetriable;

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
    ),
  );
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final LoggerService _logger = LoggerService.instance;

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
        return StreamNetworkException(
          message,
          original: e,
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
          baseUrl,
          username,
          password,
          map['stream_id']?.toString(),
        );
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

      // `get_vod_streams` ne renvoie ni `genre` ni `category_name` (seulement
      // `category_id`). On enrichit le genre depuis les catégories VOD pour que
      // le matchmaking puisse scorer les films par genre.
      final categoryNames = await _vodCategoryNames();

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
        _enrichMovieListMap(map, categoryNames);
        final movie = Movie.fromMap(map).copyWith(streamUrl: streamUrl);
        movie.requireStreamUrl();
        return movie;
      }).toList();
    }
    throw StreamNetworkException(
      'Ce mode n\'est pas encore disponible pour cette section.',
    );
  }

  /// Retourne la correspondance `category_id` → `category_name` des VOD.
  Future<Map<String, String>> _vodCategoryNames() async {
    try {
      final cats = await fetchVodCategories();
      return {
        for (final c in cats)
          if (c.id.isNotEmpty && c.name.isNotEmpty) c.id: c.name,
      };
    } catch (_) {
      return const <String, String>{};
    }
  }

  /// Enrichit une entrée de liste VOD : genre manquant ← nom de catégorie,
  /// et année manquante ← timestamp `added` (en secondes Unix).
  void _enrichMovieListMap(
    Map<String, dynamic> map,
    Map<String, String> categoryNames,
  ) {
    final genre = (map['genre']?.toString() ?? '').trim();
    if (genre.isEmpty) {
      final catId = map['category_id']?.toString() ?? '';
      final catName = categoryNames[catId];
      if (catName != null && catName.trim().isNotEmpty) {
        map['genre'] = catName.trim();
      }
    }
    final year = map['year'];
    if ((year == null || year == 0 || '$year' == '0') && map['added'] != null) {
      final added = map['added'];
      if (added is num) {
        map['year'] =
            DateTime.fromMillisecondsSinceEpoch(added.toInt() * 1000).year;
      }
    }
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
      'Ce mode n\'est pas encore disponible pour cette section.',
    );
  }

  Future<Series> fetchSeriesInfo(String seriesId) async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream') {
      throw StreamNetworkException(
        'Ce mode n\'est pas encore disponible pour cette section.',
      );
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
          .where(
            (e) =>
                radioCategoryIds.isEmpty ||
                radioCategoryIds.contains(e['category_id']?.toString()),
          )
          .map((e) {
        final map = Map<String, dynamic>.from(e);
        final streamUrl = buildXtreamStreamUrl(
          baseUrl,
          username,
          password,
          map['stream_id']?.toString(),
        );
        return Channel.fromMap(map).copyWith(streamUrl: streamUrl);
      }).toList();
    }
    throw StreamNetworkException(
      'Ce mode n\'est pas encore disponible pour cette section.',
    );
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
            return name.contains('radio') ||
                name.contains('musique') ||
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

  /// Nombre d'interrogations EPG courtes exécutées en parallèle (ne pas
  /// marteler le panel d'un coup ; 6-8 est un bon compromis temps/politesse).
  static const int _probeConcurrency = 8;

  /// Fenêtre de replay : on ne remonte pas au-delà de 48h.
  static const Duration _replayWindow = Duration(hours: 48);

  Future<List<ReplayItem>> fetchReplays() async {
    final sub = await _subscriptionManager.getActiveSubscription();

    if (sub['type'] == 'xtream') {
      return _fetchXtreamReplays(sub);
    }
    if (sub['type'] == 'm3u') {
      return _fetchM3uReplays(sub);
    }
    throw StreamNetworkException('Aucun abonnement configuré.');
  }

  /// Replay Xtream : les chaînes DVR (tv_archive / timeshift) exposent leurs
  /// programmes passés via l'EPG court ; chaque programme est joué avec une
  /// URL timeshift (start/end en secondes Unix) sur le flux de la chaîne.
  Future<List<ReplayItem>> _fetchXtreamReplays(
    Map<String, String?> sub,
  ) async {
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;

    final List<Channel> channels;
    try {
      channels = await fetchLiveChannels();
    } catch (_) {
      return const <ReplayItem>[];
    }

    final flagged = channels
        .where(
          (c) =>
              c.supportsReplay || c.name.toLowerCase().contains('replay'),
        )
        .toList();

    // Découverte large : beaucoup de panels ne marquent `tv_archive` que sur
    // une poignée de chaînes (ex. une catégorie) alors que le timeshift est
    // global. On sonde donc TOUJOURS un échantillon diversifié :
    //   1. toutes les chaînes explicitement DVR (« Seulement France HD » est
    //      le symptôme typique d'une marque partielle) ;
    //   2. complété par un échantillon STRATIFIÉ par catégorie (un même
    //      groupe n'apparaîtra qu'en petit nombre dans la sonde) pour couvrir
    //      le reste de la grille, sans marteler le panel (budget plafonné).
    final probeChannels = replayProbeSet(channels, flagged);
    if (probeChannels.isEmpty) return const <ReplayItem>[];

    final now = DateTime.now();
    final results = List<List<ReplayItem>?>.filled(probeChannels.length, null);
    var nextIndex = 0;
    final workerCount = probeChannels.length < _probeConcurrency
        ? probeChannels.length
        : _probeConcurrency;
    final workers = <Future<void>>[
      for (var w = 0; w < workerCount; w++)
        () async {
          while (true) {
            final i = nextIndex++;
            if (i >= probeChannels.length) break;
            results[i] = await _fetchChannelReplayPrograms(
              baseUrl: baseUrl,
              username: username,
              password: password,
              channel: probeChannels[i],
              now: now,
            );
          }
        }(),
    ];
    await Future.wait(workers);

    final replayItems = <ReplayItem>[];
    for (var i = 0; i < probeChannels.length; i++) {
      final programs = results[i] ?? const <ReplayItem>[];
      if (programs.isNotEmpty) {
        replayItems.addAll(programs);
      } else if (probeChannels[i].supportsReplay) {
        // Repli : la chaîne est replayable mais aucun programme terminé
        // n'est exposé par le panel ; on propose quand même la lecture live.
        replayItems.add(
          ReplayItem(
            id: 'ch_${probeChannels[i].id}',
            title: 'Replay · ${probeChannels[i].name}',
            streamUrl: probeChannels[i].streamUrl,
            startTime: '',
            endTime: '',
            categoryId: probeChannels[i].groupLabel,
          ),
        );
      }
    }

    // Programmes les plus récents d'abord.
    replayItems.sort((a, b) {
      final ta = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

    debugPrint('Orbit3D replays=${replayItems.length} '
        'probed=${probeChannels.length} '
        'flagged=${flagged.length}');
    return replayItems;
  }

  /// Constitution de l'ensemble des chaînes à sonder pour le replay :
  ///
  /// 1. Toutes les chaînes explicitement DVR ([flagged]), dans l'ordre de la
  ///    grille (l'ordre du panel met souvent France HD en tête ;
  ///    `take(25)` brut ne garderait QUE cette catégorie).
  /// 2. Complété par un échantillon stratifié par catégorie : au plus
  ///    `_replayProbePerGroup` chaînes NON marquées par groupe, choisis en
  ///    round-robin pour couvrir toutes les catégories jusqu'à épuisement du
  ///    budget (le DVR du panel est souvent global, la marque partielle).
  static List<Channel> replayProbeSet(
    List<Channel> channels,
    List<Channel> flagged,
  ) {
    const budget = 40;
    const perGroup = 3;
    if (channels.isEmpty) return const <Channel>[];

    final candidates = <Channel>[...flagged];
    final seen = candidates.map((c) => c.id).toSet();
    if (candidates.length >= budget) return candidates;

    final byGroup = <String, List<Channel>>{};
    for (final c in channels) {
      if (seen.contains(c.id)) continue;
      final g = c.groupLabel.isNotEmpty ? c.groupLabel : _unknownGroupLabel;
      byGroup.putIfAbsent(g, () => []).add(c);
    }

    final groupNames = byGroup.keys.toList();
    final takenByGroup = <String, int>{};
    var allExhausted = false;
    while (candidates.length < budget && !allExhausted) {
      allExhausted = true;
      for (final group in groupNames) {
        if (candidates.length >= budget) break;
        final list = byGroup[group]!;
        final taken = takenByGroup[group] ?? 0;
        if (taken >= perGroup) continue;
        if (taken >= list.length) continue;
        candidates.add(list[taken]);
        takenByGroup[group] = taken + 1;
        allExhausted = false;
      }
    }
    return candidates;
  }

  static const String _unknownGroupLabel = '(sans groupe)';

  /// Programmes terminés et rejouables d'une chaîne DVR (get_short_epg).
  Future<List<ReplayItem>> _fetchChannelReplayPrograms({
    required String baseUrl,
    required String username,
    required String password,
    required Channel channel,
    required DateTime now,
  }) async {
    try {
      final url = _playerApiUrl(baseUrl, 'player_api.php', {
        'username': username,
        'password': password,
        'action': 'get_short_epg',
        'stream_id': channel.id,
      });
      final response = await _get(url);
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map
              ? (data['epg_listings'] as List? ?? const <dynamic>[])
              : const <dynamic>[]);
      final items = <ReplayItem>[];
      for (final e in list.whereType<Map>()) {
        final map = Map<String, dynamic>.from(e);
        final start = _parseReplayDate(map['start_timestamp'] ?? map['start']);
        final end = _parseReplayDate(map['stop_timestamp'] ?? map['end']);
        if (start == null || end == null) continue;
        if (!end.isBefore(now)) continue; // programme pas encore terminé
        if (now.difference(start) > _replayWindow) continue; // trop ancien
        final title = map['title']?.toString().trim() ?? '';
        if (title.isEmpty) continue;
        final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
        final endEpoch = end.millisecondsSinceEpoch ~/ 1000;
        items.add(
          ReplayItem(
            id: '${channel.id}_$startEpoch',
            title: title,
            streamUrl: buildXtreamTimeshiftUrl(
              baseUrl,
              username,
              password,
              channel.id,
              start: startEpoch,
              end: endEpoch,
            ),
            startTime: _formatReplayTime(start, now),
            endTime: _formatReplayTime(end, now),
            categoryId: channel.groupLabel,
            startDate: start,
          ),
        );
      }
      return items;
    } catch (_) {
      return const <ReplayItem>[];
    }
  }

  /// Replay M3U : les chaînes portant un attribut `catchup`/`timeshift`
  /// apparaissent directement comme rejouables.
  Future<List<ReplayItem>> _fetchM3uReplays(Map<String, String?> sub) async {
    try {
      final url = sub['url']!;
      final response = await _get(url);
      final channels = parseM3u(response.data.toString());
      return [
        for (final c in channels.where((c) => c.supportsReplay))
          ReplayItem(
            id: 'ch_${c.id}',
            title: 'Replay · ${c.name}',
            streamUrl: c.streamUrl,
            startTime: '',
            endTime: '',
            categoryId: '',
          ),
      ];
    } catch (_) {
      return const <ReplayItem>[];
    }
  }

  /// Parse un horaire EPG : timestamp Unix (secondes) ou « yyyy-MM-dd HH:mm:ss ».
  static DateTime? _parseReplayDate(Object? raw) {
    if (raw == null) return null;
    final trimmed = raw.toString().trim();
    if (trimmed.isEmpty) return null;
    final seconds = int.tryParse(trimmed);
    if (seconds != null && seconds > 0) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }

  /// « HH:mm » si même jour, sinon « d mois HH:mm » (ex. « 5 févr. 18:30 »).
  String _formatReplayTime(DateTime dt, DateTime now) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return '$h:$m';
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.',
      'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${local.day} ${months[local.month - 1]} $h:$m';
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
      // Le parse complet (~94 000 entrées) est lourd : déporté sur un isolate
      // pour ne pas figer le thread UI (évite l'ANR sur les box TV/phones).
      final programs = await compute(
        _parseXmltvIsolate,
        response.data.toString(),
      );
      debugPrint('Orbit3D epg fetched=${programs.length} '
          'first=${programs.isEmpty ? '<none>' : programs.first.channelId} '
          'url=${url.split('?').first}');
      return programs;
    }
    // Les flux M3U ne fournissent pas de guide XMLTV : pas de programme,
    // plutôt que de lever une erreur technique à l'écran.
    return const <EPGProgram>[];
  }

  /// Entrée isolate : `compute` exige une fonction top-level.
  static List<EPGProgram> _parseXmltvIsolate(String content) =>
      ApiService().parseXmltv(content);

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
    String baseUrl,
    String script,
    Map<String, String> params,
  ) {
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

  /// URL de lecture timeshift Xtream (`/streaming/timeshift.php`) : rejoue la
  /// tranche [start, end] (secondes Unix) d'une chaîne DVR. C'est la forme
  /// réellement servie par les panels Xtream (contrairement au fichier live
  /// `/u/{u}/{p}/{id}` qui n'accepte pas de replay de manière fiable).
  String buildXtreamTimeshiftUrl(
    String baseUrl,
    String username,
    String password,
    String streamId, {
    required int start,
    required int end,
  }) {
    final uri = Uri.parse(_trimBaseUrl(baseUrl));
    final segments = <String>['streaming', 'timeshift.php'];
    return uri
        .replace(
          pathSegments: segments,
          queryParameters: {
            'username': username,
            'password': password,
            'stream': streamId,
            'start': '$start',
            'duration': '${end - start}',
          },
        )
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
    String? currentGroup;
    for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        if (nameMatch != null) {
          currentName = nameMatch.group(1)!.trim();
        }
        currentGroup = _m3uAttr(line, 'group-title').trim();
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentName != null) {
          final catchup = _m3uAttr(line, 'catchup').trim().toLowerCase();
          final catchupDays = int.tryParse(_m3uAttr(line, 'catchup-days')) ?? 0;
          final timeshift = int.tryParse(_m3uAttr(line, 'timeshift')) ?? 0;
          channels.add(
            Channel(
              id: channels.length.toString(),
              name: currentName,
              logoUrl: '',
              streamUrl: stream_helpers.requireStreamUrl(
                line.trim(),
                label: currentName,
              ),
              group: currentGroup ?? '',
              supportsReplay:
                  (catchup.isNotEmpty && catchup != 'none') ||
                      catchupDays > 0 ||
                      timeshift > 0,
              timeshift: Duration(seconds: timeshift),
            ),
          );
          currentName = null;
          currentGroup = null;
        }
      }
    }
    return channels;
  }

  /// Lit un attribut `clé="valeur"` dans une ligne M3U (#EXTINF).
  static String _m3uAttr(String line, String key) {
    final match = RegExp('$key="([^"]*)"').firstMatch(line);
    return match?.group(1) ?? '';
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
      programs.add(
        EPGProgram(
          channelId: channelId,
          title: title,
          description: desc,
          start: start,
          end: end,
        ),
      );
    }
    return programs;
  }

  // ---------- Recherche unifiée Xtream ----------
  Future<UnifiedSearchResult> search(String query) async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] != 'xtream') {
      throw StreamNetworkException(
          'Recherche non disponible pour ce type d\'abonnement.');
    }
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'search',
      'q': query,
    });
    try {
      final response = await _get(url);
      final data = response.data;
      if (data is! Map) return UnifiedSearchResult.empty();

      final live = (data['live'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Channel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final vod = (data['vod'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Movie.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final series = (data['series'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Series.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      return UnifiedSearchResult(
        items: [
          ...live.map(
              (c) => SearchItem.fromChannel(c, source: SearchSource.xtream)),
          ...vod
              .map((m) => SearchItem.fromMovie(m, source: SearchSource.xtream)),
          ...series.map(
              (s) => SearchItem.fromSeries(s, source: SearchSource.xtream)),
        ],
      );
    } catch (e) {
      _logger.warning('Xtream search failed: $e');
      return UnifiedSearchResult.empty();
    }
  }
}
