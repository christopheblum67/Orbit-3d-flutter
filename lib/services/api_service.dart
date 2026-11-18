import 'dart:async';
import 'package:orbit_3d_flutter/services/catalog_disk_cache.dart';
import 'package:orbit_3d_flutter/services/catalog_http_validators.dart';
import 'package:orbit_3d_flutter/services/catalog_fetch_service.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';
import 'package:orbit_3d_flutter/services/conditional_xmltv_cache.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/services/api_rate_limiter.dart';
import 'package:orbit_3d_flutter/services/api_transport.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/epg_stream_parser.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    show StreamNetworkException;
import 'package:orbit_3d_flutter/services/subscription_manager.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';
import 'package:orbit_3d_flutter/services/xtream_url_builder.dart';
import 'package:orbit_3d_flutter/services/xmltv_service.dart';
import 'package:orbit_3d_flutter/services/playlist_fetch_service.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';
import 'package:orbit_3d_flutter/services/xtream_media_catalog_service.dart';
import 'package:orbit_3d_flutter/services/xtream_radio_service.dart';
import 'package:orbit_3d_flutter/services/xtream_movie_detail_service.dart';
import 'package:orbit_3d_flutter/services/xtream_series_detail_service.dart';
import 'package:orbit_3d_flutter/services/xtream_subtitle_service.dart';
import 'package:orbit_3d_flutter/services/xtream_replay_service.dart';

class ApiService {
  /// Instance courante, utilisée par le builder global d'URLs de stream.
  static ApiService? _instance;

  /// Identifiants Xtream de l'abonnement actif, mémorisés pour permettre la
  /// reconstruction synchrone des URLs de stream.
  String? _subBaseUrl;
  String? _subUsername;
  String? _subPassword;

  /// Mémorise l'abonnement actif résolu puis le retourne.
  Future<Map<String, String?>> _activeSub() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    _rememberSubscription(sub);
    return sub;
  }

  void _rememberSubscription(Map<String, String?> sub) {
    if (sub['type'] != 'xtream') {
      _subBaseUrl = null;
      _subUsername = null;
      _subPassword = null;
      return;
    }
    _subBaseUrl = sub['baseUrl'];
    _subUsername = sub['username'];
    _subPassword = sub['password'];
  }

  /// Identité NON SECRÈTE de l'abonnement courant, pour nommer un cache.
  ///
  /// Sert au tampon EPG sur disque : deux abonnements ont des listes de chaînes
  /// DIFFÉRENTES, et un tampon partagé afficherait les programmes d'un panel sur
  /// les chaînes de l'autre.
  ///
  /// Le mot de passe est délibérément exclu — cette valeur entre dans un nom de
  /// fichier et un journal, elle n'a donc aucune raison d'y figurer.
  ///
  /// ## Asynchrone, et c'est nécessaire
  ///
  /// Une version synchrone lisant les champs mémorisés ne renvoyait `null` qu'au
  /// DÉMARRAGE À FROID : ils ne sont renseignés que par [_activeSub], or le
  /// tampon est consulté AVANT le premier appel réseau. Résultat mesuré sur le
  /// S20 : aucune trace de lecture ni d'écriture, le tampon jamais produit.
  Future<String?> resolveSubscriptionCacheKey() async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return null;
    final base = sub['baseUrl'];
    final user = sub['username'];
    if (base == null || base.isEmpty || user == null || user.isEmpty) {
      return null;
    }
    return '$base|$user';
  }

  static void setCertificateFingerprints(Set<String>? fingerprints) =>
      ApiTransport.setCertificateFingerprints(fingerprints);

  /// Construit les URLs de stream de façon **synchrone** à partir des
  /// identifiants de l'abonnement actif mémorisés en mémoire.
  ///
  /// `Movie`, `Series` et `MovieDetail` ne stockent plus l'URL complète
  /// (≈ 13 Mo pour un catalogue de 100k entrées) mais uniquement le
  /// `stream_id` ; l'URL est reconstruite à la demande via ce builder.
  ///
  /// Renvoie `null` tant que l'abonnement actif n'a pas été résolu au moins
  /// une fois (voir [_rememberSubscription]).
  static String? buildStreamUrlFromCache({
    required String streamId,
    String? containerExtension,
    String type = 'movie',
  }) {
    final instance = _instance;
    if (instance == null) return null;
    return instance._buildStreamUrl(
      streamId: streamId,
      containerExtension: containerExtension,
      type: type,
    );
  }

  String? _buildStreamUrl({
    required String streamId,
    String? containerExtension,
    String type = 'movie',
  }) {
    if (streamId.isEmpty) return null;
    final baseUrl = _subBaseUrl;
    final username = _subUsername;
    final password = _subPassword;
    if (baseUrl == null ||
        baseUrl.isEmpty ||
        username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    final url = buildXtreamStreamUrl(
      baseUrl,
      username,
      password,
      streamId,
      type: type,
      extension: containerExtension,
      withExtension: type.toLowerCase() == 'movie' &&
          containerExtension?.trim().isNotEmpty == true,
    );
    return url.isEmpty ? null : url;
  }

  /// Instancie le builder global d'URLs de stream (models `Movie`/`Series`).
  ///
  /// Le typedef historique renvoie une `String` non nulle : on renvoie donc
  /// une chaîne vide quand l'abonnement n'est pas (encore) résolu, ce qui
  /// reproduit le comportement d'un flux absent plutôt qu'une exception.
  static void initStreamUrlBuilder() {
    setGlobalStreamUrlBuilder(
      ({required String streamId, String? containerExtension, String? type}) {
        return buildStreamUrlFromCache(
              streamId: streamId,
              containerExtension: containerExtension,
              type: type ?? 'movie',
            ) ??
            '';
      },
    );
  }

  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final ApiRateLimiter rateLimiter = ApiRateLimiter();
  late final ApiTransport _transport = ApiTransport(rateLimiter: rateLimiter);

  void forgetSlowUrls() => _transport.forgetSlowUrls();

  void onSubscriptionChanged() {
    _subscriptionGeneration++;
    _inFlight.clear();
    forgetSlowUrls();
    rateLimiter.onNewTarget();
  }

  ApiService({
    ConditionalPlaylistCache? playlistCache,
    CatalogDiskCache? catalogCache,
    CatalogHttpValidators? catalogValidators,
    ConditionalXmltvCache? xmltvCache,
  })  : _playlistCache = playlistCache ?? ConditionalPlaylistCache.instance,
        _catalogCache = catalogCache ?? CatalogDiskCache.instance,
        _catalogValidators = catalogValidators ?? CatalogHttpValidators.instance,
        _xmltvCache = xmltvCache ?? ConditionalXmltvCache.instance {
    _instance = this;
    initStreamUrlBuilder();
  }

  Future<Response<dynamic>> _get(String url, {Options? options}) =>
      _transport.request(url, options: options);

  Future<Response<dynamic>> get(String url) => _get(url);

  static bool isRateLimitError(Object? error) => ApiTransport.isRateLimitError(error);

  static String? rateLimitResetHint(Headers? headers) =>
      ApiTransport.rateLimitResetHint(headers);

  /// Retourne vrai uniquement si la configuration est refusée ou inaccessible.
  Future<bool> isXtreamConfigurationInvalid(Subscription subscription) async {
    final base = subscription.baseUrl?.trim() ?? '';
    final username = subscription.username ?? '';
    final password = subscription.password ?? '';
    final uri = Uri.tryParse(base);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        username.trim().isEmpty ||
        password.isEmpty) {
      return true;
    }
    final url = _playerApiUrl(base, 'player_api.php', {
      'username': username,
      'password': password,
    });
    try {
      final response = await get(url);
      final data = response.data;
      if (data is! Map) return false;
      final info = data['user_info'];
      final auth = info is Map ? info['auth'] : data['auth'];
      return auth == 0 || auth == '0' || auth == false;
    } on StreamNetworkException catch (error) {
      final original = error.original;
      if (original is! DioException) return false;
      return _isConfigurationConnectionError(original);
    } on DioException catch (error) {
      return _isConfigurationConnectionError(error);
    }
  }

  static bool _isConfigurationConnectionError(DioException error) {
    final status = error.response?.statusCode;
    return status == 401 ||
        status == 403 ||
        status == 404 ||
        error.type == DioExceptionType.connectionError;
  }

  // ---------- Informations du compte (validité) ----------
  /// Récupère la date d'expiration du compte Xtream via
  /// `get_user_info` (champ `exp_date`, timestamp Unix en secondes).
  /// Renvoie `null` si l'information n'est pas disponible (M3U, champ absent…).
  Future<DateTime?> fetchExpiration() async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return null;
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final url = _playerApiUrl(baseUrl, 'player_api.php', {
      'username': username,
      'password': password,
      'action': 'get_user_info',
    });
    final result = await safeAsync<DateTime?>(
      () async {
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
      },
      context: 'ApiService.fetchExpiration',
      fallbackValue: null,
    );
    return result.valueOrNull;
  }

  // ---------- Canaux live ----------

  /// Requêtes identiques en cours, par clé.
  ///
  /// `fetchLiveChannels` est appelée par quatre points indépendants
  /// (`liveChannelsProvider`, le provider des replays, le contrôleur de
  /// démarrage, et le chemin interne des replays Xtream). chacune déclenchait
  /// son propre `get_live_categories` PUIS son propre `get_live_streams`.
  /// Mesuré au logcat lors d'un changement d'abonnement :
  ///
  /// ```
  /// 10:29:03.690 GET get_live_categories
  /// 10:29:03.691 GET autre
  /// 10:29:03.691 GET get_live_categories
  /// 10:29:04.107 GET get_live_streams
  /// 10:29:04.107 GET get_live_streams
  /// ```
  ///
  /// Sur un panel qui limite les requêtes, un doublon est une unité de quota
  /// brûlée pour rien : diviser le budget réel par deux, c'est ce qui
  /// déclenche les rafales de 429.
  ///
  /// Le regroupement se fait ICI, dans la couche réseau, et pas aux points
  /// d'appel : c'est le seul endroit où l'on est sûr de tout rabattre, y
  /// compris les appelants futurs. Les clés sont aussi isolées entre les
  /// abonnements afin qu'une requête encore en cours sur l'ancien ne bloque pas
  /// le chargement du nouvel abonnement.
  final Map<String, Future<Object?>> _inFlight = <String, Future<Object?>>{};
  int _subscriptionGeneration = 0;

  /// Exécute [body] une seule fois par [key] tant qu'elle est en cours.
  ///
  /// Les appels concurrents partagent le même Future. L'entrée est retirée dès
  /// l'achèvement, y compris en cas d'erreur : un vol raté ne doit pas
  /// contaminer les tentatives suivantes.
  Future<T> _singleFlight<T>(String key, Future<T> Function() body) {
    final scopedKey = '$_subscriptionGeneration:$key';
    final existing = _inFlight[scopedKey];
    if (existing != null) return existing.then((value) => value as T);

    final completer = Completer<T>();
    _inFlight[scopedKey] = completer.future;

    // `Future.sync` est indispensable : `body()` peut lever de façon
    // SYNCHRONE, avant de rendre son Future. Sans cet enveloppe, l'exception
    // sortirait de `_singleFlight` au lieu d'arriver par le Future, et surtout
    // l'entrée resterait en vol — cette clé échouerait alors définitivement.
    // C'est un bug trouvé par un test, pas une précaution théorique.
    Future<T>.sync(body).then(
      (value) {
        _inFlight.remove(scopedKey);
        completer.complete(value);
      },
      onError: (Object error, StackTrace stack) {
        _inFlight.remove(scopedKey);
        completer.completeError(error, stack);
      },
    );
    return completer.future;
  }

  /// Nombre de regroupements en cours, pour le diagnostic.
  @visibleForTesting
  int get inFlightCount => _inFlight.length;

  /// Accès au regroupement pour les tests.
  ///
  /// Tester le regroupement via `fetchLiveChannels` ne prouve rien : sans
  /// abonnement actif, le corps échoue avant toute requête et on ne peut pas
  /// compter les exécutions. Exposer le mécanisme permet de compter, ce qui
  /// est la seule chose qui compte vraiment ici.
  @visibleForTesting
  Future<T> singleFlightForTest<T>(String key, Future<T> Function() body) =>
      _singleFlight(key, body);

  Future<List<Channel>> fetchLiveChannels() {
    // Changer d'abonnement change la génération des clés single-flight.
    return _singleFlight('live_channels', () => _fetchLiveChannels());
  }

  Future<List<Channel>> _fetchLiveChannels() async {
    final sub = await _activeSub();
    if (sub['type'] == 'xtream') {
      return _liveCatalogService.live(
        sub['baseUrl']!, sub['username']!, sub['password']!,
      );
    }
    throw StreamNetworkException(
      'Le chargement Live M3U doit passer par le fournisseur de playlist M3U.',
    );
  }

  // ---------- Films (VOD) ----------
  Future<List<MediaCategory>> fetchVodCategories() {
    return _singleFlight('vod_categories', () => _fetchVodCategories());
  }

  Future<List<MediaCategory>> _fetchVodCategories() async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') {
      return const [];
    }
    return _liveCatalogService.categories(
      sub['baseUrl']!, sub['username']!, sub['password']!, series: false,
    );
  }

  Future<List<MediaCategory>> fetchSeriesCategories() {
    return _singleFlight('series_categories', () => _fetchSeriesCategories());
  }

  Future<List<MediaCategory>> _fetchSeriesCategories() async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') {
      return const [];
    }
    return _liveCatalogService.categories(
      sub['baseUrl']!, sub['username']!, sub['password']!, series: true,
    );
  }

  /// Quand `true`, le prochain chargement des catalogues ignore le cache
  /// disque (rafraîchissement manuel) puis le réécrit.
  static bool bypassCatalogCache = false;
  final CatalogDiskCache _catalogCache;
  final CatalogHttpValidators _catalogValidators;
  late final CatalogFetchService _catalogFetchService = CatalogFetchService(
    cache: _catalogCache,
    validators: _catalogValidators,
    get: _get,
  );
  late final XtreamLiveCatalogService _liveCatalogService =
      XtreamLiveCatalogService(
    loadBytes: _catalogBytes,
    buildApiUrl: _playerApiUrl,
  );
  late final XtreamMediaCatalogService _mediaCatalogService =
      XtreamMediaCatalogService(
    loadBytes: _catalogBytes,
    buildApiUrl: _playerApiUrl,
    loadVodCategoryNames: _vodCategoryNames,
    syncMovies: (key, bytes, items) => CatalogDb.instance.syncMovies(
      key,
      CatalogDb.signatureOf(bytes, items.length),
      items,
    ),
    syncSeries: (key, bytes, items) => CatalogDb.instance.syncSeries(
      key,
      CatalogDb.signatureOf(bytes, items.length),
      items,
    ),
  );
  final ConditionalXmltvCache _xmltvCache;
  late final XmltvService _xmltvService =
      XmltvService(cache: _xmltvCache, get: _get);

  /// Octets bruts d'un catalogue : cache disque s'il est frais, sinon réseau
  /// (puis écriture du cache).
  Future<Uint8List> _catalogBytes(
    String name,
    String cacheKey,
    String url, {
    bool useFreshCache = true,
  }) =>
      _catalogFetchService.fetch(
        name,
        cacheKey,
        url,
        useFreshCache: useFreshCache && !bypassCatalogCache,
      );

  @visibleForTesting
  Future<Uint8List> catalogBytesForTest(
    String name,
    String cacheKey,
    String url, {
    bool useFreshCache = true,
  }) =>
      _catalogBytes(name, cacheKey, url, useFreshCache: useFreshCache);

  Future<List<Movie>> fetchMovies() {
    return _singleFlight('vod_streams', () => _fetchMovies());
  }

  Future<List<Movie>> _fetchMovies() async {
    final sub = await _activeSub();
    if (sub['type'] == 'xtream') {
      return _mediaCatalogService.movies(
        sub['baseUrl']!, sub['username']!, sub['password']!,
      );
    }
    throw StreamNetworkException(
      'Ce mode n\'est pas encore disponible pour cette section.',
    );
  }

  /// Retourne la correspondance `category_id` → `category_name` des VOD.
  Future<Map<String, String>> _vodCategoryNames() async {
    final result = await safeAsync<Map<String, String>>(
      () async {
        final cats = await fetchVodCategories();
        return {
          for (final c in cats)
            if (c.id.isNotEmpty && c.name.isNotEmpty) c.id: c.name,
        };
      },
      context: 'ApiService._vodCategoryNames',
      fallbackValue: const <String, String>{},
    );
    return result.getOrElse(const <String, String>{});
  }

  late final XtreamMovieDetailService _movieDetailService =
      XtreamMovieDetailService(buildApiUrl: _playerApiUrl, get: get);

  /// Enrichit un film avec les métadonnées détaillées du serveur grâce à
  /// `get_vod_info` (synopsis, année, genre, réalisateur, note, âge/PEGI).
  /// L'endpoint de liste `get_vod_streams` ne fournit pas ces champs, d'où
  /// l'appel ciblé au détail. Renvoie une copie enrichie de [movie], ou le
  /// film d'origine inchangé si l'information n'est pas disponible.
  Future<Movie> fetchMovieDetail(Movie movie) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream' || movie.id.isEmpty) return movie;
    return _movieDetailService.detail(
      movie, sub['baseUrl']!, sub['username']!, sub['password']!,
    );
  }

  /// Récupère le casting et l'équipe technique d'un film (cast + crew).
  /// Nécessite un serveur Xtream compatible avec l'endpoint `get_vod_info`
  /// qui retourne les champs `cast` et `crew` (format TMDB-like).
  Future<MovieCredits?> fetchMovieCredits(String movieId) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream' || movieId.isEmpty) return null;
    return _movieDetailService.credits(
      movieId, sub['baseUrl']!, sub['username']!, sub['password']!,
    );
  }

  Future<List<Series>> fetchSeries() {
    return _singleFlight('series_streams', () => _fetchSeries());
  }

  Future<List<Series>> _fetchSeries() async {
    final sub = await _activeSub();
    if (sub['type'] == 'xtream') {
      return _mediaCatalogService.series(
        sub['baseUrl']!, sub['username']!, sub['password']!,
      );
    }
    throw StreamNetworkException(
      'Ce mode n\'est pas encore disponible pour cette section.',
    );
  }

  late final XtreamSubtitleService _subtitleService = XtreamSubtitleService(
    activeSub: _activeSub,
    get: get,
    buildApiUrl: _playerApiUrl,
  );

  Future<({List<SubtitleTrackRef> tracks, bool guessed})>
      discoverSubtitles(String contentId, {required bool isSeries, String? streamId}) =>
      _subtitleService.discoverSubtitles(contentId, isSeries: isSeries, streamId: streamId);

  late final XtreamSeriesDetailService _seriesDetailService =
      XtreamSeriesDetailService(buildApiUrl: _playerApiUrl, get: _get);

  Future<Series> fetchSeriesInfo(String seriesId) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') {
      throw StreamNetworkException(
        'Ce mode n\'est pas encore disponible pour cette section.',
      );
    }
    return _seriesDetailService.fetch(
      seriesId, sub['baseUrl']!, sub['username']!, sub['password']!,
    );
  }

  // ---------- Radios ----------
  late final XtreamRadioService _radioService = XtreamRadioService(
    buildApiUrl: _playerApiUrl,
    get: get,
  );

  Future<List<Channel>> fetchRadioChannels() async {
    final sub = await _activeSub();
    logDiag('RADIO fetch=start source=${sub['type'] ?? 'unknown'}');
    if (sub['type'] == 'xtream') {
      return _radioService.fetch(
        sub['baseUrl']!, sub['username']!, sub['password']!,
      );
    }
    logDiag(
      'RADIO fetch=unsupported-source source=${sub['type'] ?? 'unknown'}',
    );
    throw StreamNetworkException(
      'Ce mode n\'est pas encore disponible pour cette section.',
    );
  }

  // ---------- Replays ----------
  late final XtreamReplayService _replayService = XtreamReplayService(
    activeSub: _activeSub,
    get: get,
    buildApiUrl: _playerApiUrl,
    fetchLiveChannels: fetchLiveChannels,
  );

  Future<List<ReplayItem>> buildReplaysFromGlobalEpg({
    required List<EPGProgram> programs,
    required List<Channel> channels,
  }) => _replayService.buildReplaysFromGlobalEpg(
    programs: programs, channels: channels,
  );

  static List<ReplayItem> mergeReplays(
    List<ReplayItem> fromEpg, List<ReplayItem> fromShortEpg,
  ) => XtreamReplayService.mergeReplays(fromEpg, fromShortEpg);

  Future<List<ReplayItem>> fetchReplays() => _replayService.fetchReplays();

  static List<Channel> replayProbeSet(List<Channel> channels, List<Channel> flagged) =>
      XtreamReplayService.replayProbeSet(channels, flagged);

  @visibleForTesting
  static String decodeEpgTextForTest(String raw) =>
      PanelText.decode(raw);

  Future<List<EPGProgram>> fetchChannelEpgPrograms(Channel channel) =>
      _replayService.fetchChannelEpgPrograms(channel);

  Future<List<ReplayItem>> fetchChannelReplays(Channel channel) =>
      _replayService.fetchChannelReplays(channel);

  String replayStreamUrl({
    required Channel channel,
    required String baseUrl,
    required String username,
    required String password,
    required int startEpoch,
    required int endEpoch,
  }) => _replayService.replayStreamUrl(
    channel: channel, baseUrl: baseUrl, username: username, password: password,
    startEpoch: startEpoch, endEpoch: endEpoch,
  );

  static Duration? archiveWindow(Channel channel) =>
      XtreamReplayService.archiveWindow(channel);

  // ---------- EPG (XMLTV) ----------
  Future<List<EPGProgram>> fetchEpg() async {
    final sub = await _activeSub();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = _playerApiUrl(baseUrl, 'xmltv.php', {
        'username': username,
        'password': password,
      });
      final programs = await _xmltvService.fetch(url);
      debugPrint('Orbit3D epg fetched=${programs.length} '
          'first=${programs.isEmpty ? '<none>' : programs.first.channelId} '
          'url=${url.split('?').first}');
      return programs;
    }
    // Les flux M3U ne fournissent pas de guide XMLTV : pas de programme,
    // plutôt que de lever une erreur technique à l'écran.
    return const <EPGProgram>[];
  }

  @visibleForTesting
  Future<List<EPGProgram>> fetchXmltvForTest(String url) =>
      _xmltvService.fetch(url);

  static String _trimBaseUrl(String baseUrl) {
    return XtreamUrlBuilder.trimBaseUrl(baseUrl);
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
    return XtreamUrlBuilder.buildStreamUrl(
      baseUrl,
      username,
      password,
      streamId,
      type: type,
      extension: extension,
      withExtension: withExtension,
      extra: extra,
    );
  }

  /// URL de lecture timeshift Xtream.
  ///
  /// Format documenté de l'API Xtream Codes :
  /// `/timeshift/{username}/{password}/{duration_minutes}/{YYYY-MM-DD:HH-mm}/{stream_id}.{ext}`
  ///
  /// L'ancienne version de cette méthode produisait
  /// `/streaming/timeshift.php?username=…&stream=…&start=…&duration=…`, forme
  /// qui n'existe pas sur les panels Xtream. Le replay était donc détecté dans
  /// la liste mais **toujours illisible** à la lecture.
  ///
  /// Trois points sont structurants etSources d'échec silencieux :
  ///  - `duration` est en **minutes**, pas en secondes (l'ancienne version
  ///    envoyait `end - start` en secondes) ;
  ///  - la date est au format `YYYY-MM-DD:HH-mm` (deux-points avant l'heure,
  ///    tiret entre l'heure et les minutes) ;
  ///  - l'extension doit correspondre aux formats autorisés par le compte
  ///    (`allowed_output_formats`), sinon le panel répond 406/401.
  String buildXtreamTimeshiftUrl(
    String baseUrl,
    String username,
    String password,
    String streamId, {
    required int start,
    required int end,
    String? extension,
  }) {
    return XtreamUrlBuilder.buildTimeshiftUrl(
      baseUrl,
      username,
      password,
      streamId,
      start: start,
      end: end,
      extension: extension,
    );
  }

  List<Channel> parseM3u(String content) {
    return M3uPlaylistParser.parse(content).channels;
  }

  final ConditionalPlaylistCache _playlistCache;
  late final PlaylistFetchService _playlistFetchService =
      PlaylistFetchService(cache: _playlistCache, get: _get);

  Future<M3uPlaylist> fetchM3uPlaylist(String url) =>
      _playlistFetchService.fetch(url);

  // ---------- Parseur XMLTV basique (mono-passe, sans DOM) ----------
  List<EPGProgram> parseXmltv(String content) => EpgStreamParser.parse(content);

  // ---------- Recherche unifiée Xtream ----------
  Future<UnifiedSearchResult> search(String query) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') {
      throw StreamNetworkException(
        'Recherche non disponible pour ce type d\'abonnement.',
      );
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
    final result = await safeAsync<UnifiedSearchResult>(
      () async {
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
              (c) => SearchItem.fromChannel(c, source: SearchSource.xtream),
            ),
            ...vod.map(
              (m) => SearchItem.fromMovie(m, source: SearchSource.xtream),
            ),
            ...series.map(
              (s) => SearchItem.fromSeries(s, source: SearchSource.xtream),
            ),
          ],
        );
      },
      context: 'ApiService.search',
      fallbackValue: UnifiedSearchResult.empty(),
    );
    return result.getOrElse(UnifiedSearchResult.empty());
  }
}
