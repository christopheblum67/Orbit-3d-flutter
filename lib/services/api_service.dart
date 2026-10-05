import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/catchup_url_builder.dart';
import 'package:orbit_3d_flutter/services/epg_stream_parser.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    show StreamNetworkException;
import 'package:orbit_3d_flutter/services/subscription_manager.dart';
import 'package:orbit_3d_flutter/services/certificate_pinning.dart';
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';

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

  static Set<String>? _certificateFingerprints;

  /// Configure les fingerprints SHA-256 autorisés pour le certificate pinning.
  /// Si null ou vide, le pinning est désactivé.
  static void setCertificateFingerprints(Set<String>? fingerprints) {
    _certificateFingerprints =
        fingerprints?.isNotEmpty == true ? fingerprints : null;
  }

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

  /// Budget court : suffisant pour tout appel de controle (live, infos d'un
  /// canal, EPG d'une chaine). Au-dela, c'est un vrai probleme reseau.
  static const Duration _fastTimeout = Duration(seconds: 30);

  /// Budget long : payload catalogue volumineux. `get_vod_streams` etait ~30 Mo
  /// et `get_series` ~44 Mo sur un panel Xtream ; le decoding JSON depasse
  /// largement 30 s sur mobile.
  static const Duration _slowTimeout = Duration(seconds: 180);

  /// URLs qui ont deja necessite le budget long. Evite de repayer le delai
  /// court a chaque appel tant que le cache vit.
  final Set<String> _slowUrls = <String>{};

  /// Ouvre le cache d'URL lentes. A appeler quand l'abonnement change : le
  /// classement à cette URL est lent, mais vaut pour UN serveur, pas pour le
  /// suivant, et le conserver ferait perdre jusqu'a 30 s sur chaque appel.
  void forgetSlowUrls() {
    if (_slowUrls.isEmpty) return;
    _slowUrls.clear();
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: _fastTimeout,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    // Certificate pinning si des fingerprints sont configurés
    if (_certificateFingerprints != null &&
        _certificateFingerprints!.isNotEmpty) {
      dio.httpClientAdapter = createPinningHttpClientAdapter(
        allowedFingerprints: _certificateFingerprints!,
        logger: _logger,
      );
    }
    return dio;
  }

  late final Dio _dio = _createDio();
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final LoggerService _logger = LoggerService.instance;

  ApiService() {
    _instance = this;
    initStreamUrlBuilder();
  }

  Future<Response<dynamic>> _get(String url, {Options? options}) {
    return stream_helpers.retryStream(
      () => _performGet(url, options),
      // Le panel applique un rate-limit (429) sous charge : on retente 3 fois
      // avec 1,2 s d'écart avant d'abandonner (démarrage séquentiel en plus).
      //
      // SAUF sur 429, qui n'est PAS une panne transitoire mais un « tu vas trop
      // vite » : le réessayer ici multipliait la pression (3 × 2 retries
      // internes = jusqu'à 9 requêtes pour un seul appel logique) et
      // entretenait le blocage. Un 429 remonte immédiatement : c'est
      // [_ApiGate] qui espace les appels suivants, et l'utilisateur voit un
      // état exploitable au lieu d'un chargement éternel.
      attempts: 3,
      delay: const Duration(milliseconds: 1200),
      shouldRetry: (error) {
        if (isRateLimitError(error)) return false;
        if (error is StreamNetworkException) return error.isRetriable;
        return true;
      },
    );
  }

  /// Vrai si l'erreur est un refus de quota (HTTP 429) du panel.
  ///
  /// Partagé par la couche de retry et les appelants qui doivent éviter
  /// d'empiler des requêtes sur un panel déjà saturé.
  static bool isRateLimitError(Object? error) {
    if (error == null) return false;
    if (error is StreamNetworkException) {
      final text = '${error.message} ${error.original ?? ''}';
      return text.contains('429') ||
          text.toLowerCase().contains('limite de requ');
    }
    return error.toString().contains('429');
  }

  /// Sérialisation des appels au panel.
  ///
  /// Le panel applique un rate-limit global : une rafale de requêtes
  /// simultanées (la sonde Replay qui interroge 40 chaînes, le chargement
  /// VOD + séries + EPG au démarrage) le fait répondre 429 à TOUT, y compris
  /// aux requêtes sans rapport. On impose donc un espacement minimal entre
  /// deux appels et un plafond d'appels simultanés, comme le verrou global
  /// `OPEN_GATE` le fait côté natif pour les requêtes de segments.
  ///
  /// L'espacement est adaptatif : après un 429 il s'allonge (le panel
  /// signale une saturation durable), puis redescend progressivement.
  static final _ApiGate _apiGate = _ApiGate();

  Future<Response<dynamic>> get(String url) => _get(url);

  /// Nombre de re-essais sur rejet HTTP non 2xx (429/5xx).
  ///
  /// Volontairement bas : le rejet est en général dû à une rafale de requêtes
  /// simultanées, et repartir en force aggraverait la situation. Un repli
  /// croissant suffit à attendre que la rafale retombe.
  static const int _badResponseRetries = 2;

  Future<Response<dynamic>> _performGet(String url, [Options? extra]) async {
    final sw = Stopwatch()..start();
    logDiag('GET ${_shortAction(url)} ...');
    // Escalade universal : plutot que de deviner a l'avance quelles actions sont
    // lourdes (ce qui serait lie a un panel), on tente le budget court et on
    // reessaie UNE fois avec le budget long si le serveur n'a pas fini. Le GET
    // est idempotent, le doublecout n'est paye que si le 1er essai echoue.
    final budget = _slowUrls.contains(url) ? _slowTimeout : _fastTimeout;
    // Portillon global : on attend notre tour avant d'émettre. C'est ce qui
    // empêche une rafale (sonde Replay, VOD + séries + EPG) de faire répondre
    // 429 à des requêtes qui n'y sont pour rien.
    await _apiGate.acquire();
    try {
      final res = await _dio.get<dynamic>(
        url,
        options: (extra ?? Options()).copyWith(receiveTimeout: budget),
      );
      _apiGate.onSuccess();
      // On ne retire PAS l'URL du cache lent ici : une requete qui a reussi
      // avec le budget long peut reechouer au budget court au prochain appel
      // (charge serveur variable). L'apprentissage doit survivre jusqu'au
      // changement d'abonnement,Nvautre `forgetSlowUrls()`.
      logDiag(
        'HTTP ${res.statusCode} ${sw.elapsedMilliseconds}ms '
        'lent=${budget == _slowTimeout} ${_shortAction(url)}',
      );
      return res;
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.transformTimeout;
      if (isTimeout && budget == _fastTimeout) {
        _slowUrls.add(url);
        logDiag('HTTP TIMEOUT ${_shortAction(url)} -> escalade 180s');
        try {
          final res = await _dio.get<dynamic>(
            url,
            options: Options(receiveTimeout: _slowTimeout),
          );
          logDiag(
            'HTTP ${res.statusCode} ${sw.elapsedMilliseconds}ms (escalade) '
            '${_shortAction(url)}',
          );
          return res;
        } on DioException catch (e2) {
          logDiag('HTTP ECHEC final ${sw.elapsedMilliseconds}ms ${e2.type}');
          throw _toNetworkException(e2);
        }
      }

      // Statut HTTP non 2xx (429/403/503...).
      //
      // Les rejets arrivent en ~45 ms, ce qui exclut un délai réseau : c'est
      // le panel qui refuse la requête, très probablement parce que le
      // préchargeur EPG émet plusieurs `get_short_epg` simultanés. Le GET étant
      // idempotent, on réessaie avec un repli croissant : le même appel
      // réussissait ~1,8 s plus tard lors des relevés, une fois la rafale
      // retombée.
      //
      // SAUF sur 429 : c'est une saturation, pas une panne. Réessayer 250 ms
      // puis 1 s plus tard ne fait qu'ajouter 2 requêtes au painel déjà
      // saturé, et ce comportement (combiné aux retries de `_get`) multipliait
      // la pression jusqu'à 9 requêtes pour un appel logique — et c'est
      // précisément ce qui entretenait le blocage. On remonte donc l'erreur
      // tout de suite, et [_ApiGate] espace les appels suivants.
      final status = e.response?.statusCode;
      final isRateLimited = status == 429;
      final retriable = !isRateLimited &&
          e.type == DioExceptionType.badResponse &&
          (status == null || status == 408 || (status >= 500 && status < 600));
      if (isRateLimited) {
        // Le gate relève son espacement : le panel vient de refuser.
        _apiGate.onRateLimited();
      }
      if (retriable) {
        for (var attempt = 1; attempt <= _badResponseRetries; attempt++) {
          final backoff = Duration(milliseconds: 250 * attempt * attempt);
          logDiag(
            'HTTP ${status ?? '?'} ${_shortAction(url)} '
            '-> retry $attempt/$_badResponseRetries dans ${backoff.inMilliseconds}ms',
          );
          await Future<void>.delayed(backoff);
          try {
            final res = await _dio.get<dynamic>(
              url,
              options: (extra ?? Options()).copyWith(receiveTimeout: budget),
            );
            _apiGate.onSuccess();
            logDiag(
              'HTTP ${res.statusCode} ${sw.elapsedMilliseconds}ms '
              '(retry ok) ${_shortAction(url)}',
            );
            return res;
          } on DioException {
            // On continue jusqu'au dernier essai, puis on sort en erreur.
          }
        }
        logDiag(
          'HTTP ${status ?? '?'} ${_shortAction(url)} '
          '-> $_badResponseRetries retries épuisés',
        );
      }

      logDiag(
        'HTTP ECHEC ${sw.elapsedMilliseconds}ms ${e.type} '
        'status=$status ${_shortAction(url)}',
      );
      throw _toNetworkException(e);
    } finally {
      // Le créneau est rendu quel que soit le sort de l'appel : sans cela,
      // une exception quittant le `try` le monopolisait, et le portillon se
      // fermait après trois échecs.
      _apiGate.release();
    }
  }

  /// Extrait l'action pour un log lisible, sans le user/password.
  static String _shortAction(String url) {
    final i = url.indexOf('action=');
    if (i < 0) return 'autre';
    final rest = url.substring(i + 7);
    final end = rest.indexOf('&');
    return end < 0 ? rest : rest.substring(0, end);
  }

  /// Heure de réinitialisation du quota, déduite des en-têtes du serveur.
  ///
  /// Trois conventions coexistent sur les API Xtream : `Retry-After` en
  /// secondes, et `X-RateLimit-Reset` en epoch **secondes** ou en epoch
  /// **millisecondes**. On les essaie toutes — deviner entre secondes et
  /// millisecondes donnerait une date fausse, ce qui est pire que pas de date.
  ///
  /// Renvoie `null` si le serveur n'en donne pas : on affiche alors un message
  /// sans heure, jamais une heure inventée.
  static String? rateLimitResetHint(Headers? headers) {
    if (headers == null || headers.isEmpty) return null;

    String? read(List<String> keys) {
      for (final key in keys) {
        final value = headers.value(key)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final raw = read([
          'retry-after',
          'Retry-After',
          'x-ratelimit-reset',
          'X-RateLimit-Reset',
        ]) ??
        read(['ratelimit-reset', 'RateLimit-Reset']);
    if (raw == null) return null;

    DateTime? at;
    final seconds = int.tryParse(raw) ?? double.tryParse(raw)?.round();
    if (seconds != null) {
      // Epoch en secondes : autour de 1,7e9. En millisecondes : 1,7e12.
      at = seconds > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(seconds)
          : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } else {
      at = DateTime.tryParse(raw);
    }
    if (at == null) return null;

    at = at.toLocal();
    if (at.isBefore(DateTime.now())) return null;
    final minutes = at.difference(DateTime.now()).inMinutes + 1;
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return 'Quota réinitialisé à $h:$m (dans ~$minutes min).';
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
          'Le serveur met trop de temps à répondre. '
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
        final headers = e.response?.headers;
        final message = switch (status) {
          401 => 'Accès refusé par le serveur (code 401). '
              'Vérifiez vos identifiants Xtream.',
          403 => 'Accès refusé par le serveur (code 403). '
              'L\'abonnement est peut-être bloqué.',
          404 => 'Ressource introuvable (code 404). '
              'Vérifiez l\'adresse du serveur.',
          // « Réessayez dans quelques instants » n'était qu'une phrase. Le
          // serveur, lui, sait dire QUAND : son en-tête de réinitialisation
          // donne l'heure exacte, ce qui répond à la seule question utile —
          // « quand est-ce que ça repart ? ».
          429 => 'Limite de requêtes dépassée (code 429). '
              '${rateLimitResetHint(e.response?.headers) ?? 'Le serveur limite le nombre de requêtes.'} '
              'Aucune relance automatique : réessayer pendant une limitation '
              'ne fait qu\'allonger la limitation.',
          _ => 'Le serveur a renvoyé une erreur (code ${status ?? 'inconnu'}).',
        };
        return StreamNetworkException(
          message,
          original: e,
          // 429 n'est PAS réessayable : c'est une demande de patienter, pas
          // une panne passagère. Le marqué comme réessayable faisait boucler
          // l'application contre le quota, et le panel bloquait d'autant plus
          // longtemps — Films et Séries restaient vides au lieu de revenir.
          isRetriable: status != 429,
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
  Future<List<Channel>> fetchLiveChannels() async {
    final sub = await _activeSub();
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
    final result = await safeAsync<Map<String, String>>(
      () async {
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
      },
      context: 'ApiService._fetchLiveCategoryNames',
      fallbackValue: const <String, String>{},
    );
    return result.getOrElse(const <String, String>{});
  }

  // ---------- Films (VOD) ----------
  Future<List<MediaCategory>> fetchVodCategories() async {
    final sub = await _activeSub();
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
    final sub = await _activeSub();
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
    final sub = await _activeSub();
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

      final raw = response.data;
      if (raw is! List) {
        throw StreamNetworkException(
          'Réponse VOD illisible (type ${raw.runtimeType}).',
        );
      }
      // On ne trace QUE les elements reellement ignores : c'est un signal de
      // panel non standard, utile a diagnostiquer, unlike un compteur sur
      // 100 000 elements qui ne signale rien.

      // Construction directe sans `.map().toList()` : un `map` intermédiaire
      // materialiserait 100 000 `Map<String, dynamic>` (~500 o chacun) avant la
      // conversion, soit plusieurs centaines de Mo de pointe sur mobile. On
      // transforme element par element et on libere la source au fil de l'eau.
      final out = <Movie>[];
      var ignores = 0;
      for (var i = 0; i < raw.length; i++) {
        final e = raw[i];
        if (e is! Map) {
          ignores++;
          continue;
        }
        try {
          final map = Map<String, dynamic>.from(e);
          _enrichMovieListMap(map, categoryNames);
          final movie = Movie.fromMap(map);
          movie.requireStreamUrl();
          out.add(movie);
        } catch (err) {
          // Une entree malformee ne doit pas faire echouer les 99 568 autres.
          if (ignores < 5) {
            logDiag('VOD entree ignoree #$i: ${err.runtimeType} -> $err');
          }
          ignores++;
        }
      }
      if (ignores > 0) logDiag('VOD entrees ignorees=$ignores');
      return out;
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
    final sub = await _activeSub();
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
    final result = await safeAsync<Movie>(
      () async {
        final response = await _get(url);
        final data = response.data;
        if (data is! Map) return movie;
        final rawInfo = data['info'];
        final info = rawInfo is Map ? rawInfo : <String, dynamic>{};

        // Année depuis `releaseDate` (YYYY-...), sinon depuis `releasedate`.
        var year = movie.year;
        final releaseDate =
            firstNonEmpty([info['releaseDate'], info['releasedate']])
                .toString();
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
          streamId: movie.streamId,
          containerExtension: movie.containerExtension,
          categoryId: movie.categoryId,
        );
      },
      context: 'ApiService.fetchMovieDetail',
      fallbackValue: movie,
    );
    return result.getOrElse(movie);
  }

  /// Récupère le casting et l'équipe technique d'un film (cast + crew).
  /// Nécessite un serveur Xtream compatible avec l'endpoint `get_vod_info`
  /// qui retourne les champs `cast` et `crew` (format TMDB-like).
  Future<MovieCredits?> fetchMovieCredits(String movieId) async {
    final sub = await _activeSub();
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
    final result = await safeAsync<MovieCredits?>(
      () async {
        final response = await _get(url);
        final data = response.data;
        if (data is! Map) return null;
        final rawInfo = data['info'];
        final info = rawInfo is Map
            ? Map<String, dynamic>.from(rawInfo)
            : <String, dynamic>{};
        return MovieCredits.fromMap(info);
      },
      context: 'ApiService.fetchMovieCredits',
      fallbackValue: null,
    );
    return result.valueOrNull;
  }

  Future<List<Series>> fetchSeries() async {
    final sub = await _activeSub();
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
      final raw = response.data;
      if (raw is! List) {
        throw StreamNetworkException(
          'Réponse séries illisible (type ${raw.runtimeType}).',
        );
      }
      // Pas de `.map().toList()` : sur 30 000 séries cela materialisait une
      // liste intermediaire de Maps sans raison. `Series.fromMap` lit deja la
      // Map directement.
      final out = <Series>[];
      var ignores = 0;
      for (final e in raw) {
        if (e is! Map) {
          ignores++;
          continue;
        }
        try {
          out.add(Series.fromMap(Map<String, dynamic>.from(e)));
        } catch (err) {
          if (ignores < 5) {
            logDiag('SERIES entree ignoree: ${err.runtimeType} -> $err');
          }
          ignores++;
        }
      }
      if (ignores > 0) logDiag('SERIES entrees ignorees=$ignores');
      return out;
    }
    throw StreamNetworkException(
      'Ce mode n\'est pas encore disponible pour cette section.',
    );
  }

  /// Découvre les pistes de sous-titres publiées pour un contenu.
  ///
  /// Interroge `get_vod_info` (film) ou `get_series_info` (série) et en
  /// extrait les sous-titres. Aucun standard n'impose le format de retour, les
  /// panels divergent : l'extraction est déléguée à [SubtitleDiscovery], qui
  /// accepte les variantes courantes et ne lève jamais.
  ///
  /// Retourne une liste vide si le panel n'en publie pas ou si l'appel échoue :
  /// l'absence de sous-titres ne doit pas être une erreur.
  /// Découvre les sous-titres d'un contenu.
  ///
  /// Renvoie les pistes trouvées, si elles sont DÉDUITES — des panels ne
  /// déclarent rien et servent les fichiers par convention d'URL, et
  /// l'interface doit le dire plutôt que présenter une supposition comme une
  /// certitude — et l'identifiant TMDB que le panel a lui-même publié.
  ///
  /// Ce dernier point évite une dépendance inutile : beaucoup de panels
  /// renvoient `tmdb_id` dans `get_vod_info` et `get_series_info`. Résoudre
  /// l'identifiant par notre propre recherche TMDB exige une clé API que
  /// l'utilisateur n'a pas forcément saisie, et le contenu devenait
  /// introuvable alors que l'information était dans la réponse que nous
  /// venions de lire.
  Future<({List<SubtitleTrackRef> tracks, bool guessed, int tmdbId})>
      discoverSubtitles(
    String contentId, {
    required bool isSeries,
    String? streamId,
  }) async {
    const nothing = (tracks: <SubtitleTrackRef>[], guessed: false, tmdbId: 0);
    if (contentId.isEmpty) return nothing;
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return nothing;

    final url = _playerApiUrl(sub['baseUrl']!, 'player_api.php', {
      'username': sub['username']!,
      'password': sub['password']!,
      'action': isSeries ? 'get_series_info' : 'get_vod_info',
      if (isSeries) 'series_id': contentId else 'vod_id': contentId,
    });

    // Contexte de synthèse d'URL, pour le format le plus répandu : une liste de
    // codes langue sans URL. Pour un film, `vod_id` EST le stream id. Pour une
    // série, `series_id` ne l'est PAS : la convention de nommage attend le
    // stream id de l'ÉPISODE, que l'appelant doit fournir. Sans lui, on ne
    // synthétise rien — une piste déduite sur le mauvais identifiant pointe
    // vers le média d'une autre série.
    final context = SubtitleDiscoveryContext(
      baseUrl: sub['baseUrl']!,
      username: sub['username']!,
      password: sub['password']!,
      streamId: isSeries ? streamId : contentId,
    );

    final result = await safeAsync<
        ({List<SubtitleTrackRef> tracks, bool guessed, int tmdbId})>(
      () async {
        final response = await _get(url);
        // Relevé de la charge utile : « aucune piste disponible » est
        // indifférenciable entre un panel qui ne publie rien et un câblage
        // cassé de notre côté.
        _logSubtitlePayload(
          action: isSeries ? 'get_series_info' : 'get_vod_info',
          contentId: contentId,
          streamId: context.streamId ?? '',
          data: response.data,
        );

        final declared =
            SubtitleDiscovery.parse(response.data, context: context);
        final panelTmdbId = _tmdbIdFrom(response.data);
        if (declared.isNotEmpty) {
          return (tracks: declared, guessed: false, tmdbId: panelTmdbId);
        }

        // Aucune piste adressable dans la réponse. Deuxième voie : les codes
        // langue peuvent être déclarés PLUS PROFOND, notamment dans les objets
        // épisode d'une série, où le parseur ne va pas les chercher.
        var codes =
            SubtitleDiscovery.collectLanguageCodes(response.data).toList();
        var guessed = false;
        if (codes.isEmpty) {
          // Troisième voie : le panel ne déclare rien du tout — mesuré sur deux
          // contenus d'un même panel, `get_vod_info` comme `get_series_info`.
          // Ses fichiers existent pourtant, servis par convention d'URL. Sans
          // candidates, l'app ne peut rien proposer alors que la piste existe.
          codes = SubtitleDiscovery.defaultConventionLanguages(
            deviceLanguageCode: PlatformDispatcher.instance.locale.languageCode,
          );
          guessed = true;
        }

        // L'URL d'une piste se construit avec le stream id de l'épisode lu, pas
        // avec celui de l'épisode qui porte la déclaration.
        final synthesized = SubtitleDiscovery.synthesizeFromConvention(
          context: context,
          languages: codes,
        );
        _logger.info(
          'Sous-titres $contentId : ${synthesized.length} piste(s) '
          '${guessed ? 'CONVENTIONNELLES (le panel ne déclare rien)' : 'déclarées'} '
          '-> ${(codes.toList()..sort()).join(', ')}',
          tag: 'subtitle',
        );
        return (
          tracks: synthesized,
          guessed: guessed,
          tmdbId: panelTmdbId,
        );
      },
      context: 'ApiService.discoverSubtitles',
      fallbackValue: (
        tracks: const <SubtitleTrackRef>[],
        guessed: false,
        tmdbId: 0,
      ),
    );
    final found = result.valueOrNull ??
        (tracks: const <SubtitleTrackRef>[], guessed: false, tmdbId: 0);
    final effectiveStreamId = context.streamId ?? '';
    _logger.info(
      'Sous-titres ${isSeries ? 'série' : 'film'} $contentId : '
      '${found.tracks.length} piste(s), stream id « $effectiveStreamId »'
      '${effectiveStreamId.isEmpty ? ' (AUCUN : URL non synthétisable)' : ''}',
      tag: 'subtitle',
    );
    return found;
  }

  /// Identifiant TMDB publié par le panel, s'il en fournit un.
  ///
  /// Cherché à la racine ET dans les objets infos/épisodes : selon le panel,
  /// `tmdb_id` est soit au niveau du contenu, soit attaché à chaque épisode.
  /// On garde le premier trouvé, les valeurs divergentes étant rares.
  static int _tmdbIdFrom(Object? data) {
    var found = 0;
    void walk(Object? node, int depth) {
      if (found != 0 || node is! Map || depth > 4) return;
      for (final entry in node.entries) {
        if (found != 0) return;
        final key = entry.key.toString().toLowerCase();
        if (key == 'tmdb_id') {
          final value = entry.value;
          final id = value is int
              ? value
              : value is num
                  ? value.toInt()
                  : int.tryParse('$value');
          if (id != null && id > 0) found = id;
        } else if (entry.value is Map || entry.value is List) {
          walk(entry.value, depth + 1);
        }
      }
    }

    walk(data, 0);
    return found;
  }

  /// Journalise la forme de la réponse `subtitles` renvoyée par le panel.
  void _logSubtitlePayload({
    required String action,
    required String contentId,
    required String streamId,
    required Object? data,
  }) {
    Map<String, dynamic>? found;
    var depth = 0;
    void walk(Object? node) {
      if (depth > 4 || found != null) return;
      depth++;
      if (node is Map) {
        final map = Map<String, dynamic>.from(node);
        for (final key in const [
          'subtitles',
          'subtitle',
        ]) {
          if (map.containsKey(key)) {
            found = {'$action.$key': map[key]};
            return;
          }
        }
        walk(map['info']);
      }
    }

    walk(data);
    if (found == null) {
      _logger.info(
        'Sous-titres $action $contentId : aucun champ « subtitles » dans la '
        'réponse (stream id « $streamId »)',
        tag: 'subtitle',
      );
      return;
    }
    final raw = found!.values.first;
    final summary = raw is List
        ? '${raw.length} entrée(s) : ${raw.take(3).join(' | ')}'
        : '$raw';
    _logger.info(
      'Sous-titres $action $contentId : $summary',
      tag: 'subtitle',
    );
  }

  Future<Series> fetchSeriesInfo(String seriesId) async {
    final sub = await _activeSub();
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
    // `get_short_epg` renvoie du JSON dont les titres/descriptions sont en
    // UTF-8, alors que le panel_Xtream sert souvent `text/html` ou
    // `text/xml` SANS charset : Dio applique alors son défaut (latin1) et
    // chaque accent devenait illisible (« à caractères spéciaux »). On
    // récupère donc les octets bruts et on décode nous-mêmes.
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
    final sub = await _activeSub();
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
    final result = await safeAsync<Set<String>>(
      () async {
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
      },
      context: 'ApiService._fetchRadioCategoryIds',
      fallbackValue: const <String>{},
    );
    return result.getOrElse(const <String>{});
  }

  // ---------- Replays ----------

  /// Nombre d'interrogations EPG courtes exécutées en parallèle.
  ///
  /// Abaisse de 8 à 2 après les tempêtes de 429 observées : la sonde
  /// interroge jusqu'à 40 chaînes et le panneau applique un quota GLOBAL —
  /// huit sondes simultanées suffisaient à le faire répondre 429 à toutes les
  /// requêtes de l'app, y compris celles des écrans Films et Séries. Le gain
  /// de temps de la sonde est marginal (l'EPG global alimente le replay
  /// multi-jours) ; le coût d'un catalogue bloqué, lui, est total.
  ///
  /// Le portillon [_ApiGate] limite par ailleurs l'ensemble des appels
  /// concurrents à 3 : ce réglage ne gouverne que la sonde.
  static const int _probeConcurrency = 2;

  /// Fenêtre de replay : on ne remonte pas au-delà de 48h.
  static const Duration _replayWindow = Duration(hours: 48);

  /// Nombre d'entrées demandées à ``get_short_epg``.
  ///
  /// Un programme TV dure en moyenne 30 à 90 minutes : 48 h de replay
  /// représentent 40 à 100 programmes selon la chaîne. On demande 100 pour
  /// couvrir la fenêtre entière, quitte à ce que le panel en renvoie moins.
  static const int _replayLimit = 100;

  /// Construit les replays à partir de l'**EPG global** déjà téléchargé.
  ///
  /// ## Pourquoi cette source et pas `get_short_epg`
  ///
  /// Le paramètre `limit` de `get_short_epg` n'est pas respecté par les
  /// panels : les logs du 29/09 montrent `limit=100` renvoyé **4 entrées**, et
  /// quatre programmes en pleine journée sont presque tous *futurs*. Cet appel
  /// ne peut donc pas alimenter un replay multi-jours — au mieux il donne le
  /// dernier programme passé, d'où les écrans à une seule date, un seul
  /// programme à la fois.
  ///
  /// L'EPG global, lui, couvre plusieurs jours et fait déjà authority pour le
  /// guide. On le croise donc avec les chaînes marquées `supportsReplay` et on
  /// ne conserve que les programmes **terminés** : c'est exactement la
  /// définition de [isReplayableProgram].
  ///
  /// [fetchReplays] reste utilisé en complément, pour les chaînes absentes de
  /// l'EPG global.
  Future<List<ReplayItem>> buildReplaysFromGlobalEpg({
    required List<EPGProgram> programs,
    required List<Channel> channels,
  }) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <ReplayItem>[];
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final now = DateTime.now();

    // Index des chaînes rejouables sous TOUS leurs identifiants EPG possibles
    // (`{stream_id}` et `{num}:{stream_id}`) : le XMLTV et le panel ne
    // s'accordent pas toujours sur la même forme.
    final byEpgId = <String, Channel>{};
    for (final c in channels) {
      if (!c.supportsReplay) continue;
      for (final id in c.epgChannelIds) {
        if (id.isNotEmpty) byEpgId[id] = c;
      }
      if (c.id.isNotEmpty) byEpgId[c.id] = c;
    }
    if (byEpgId.isEmpty) return const <ReplayItem>[];

    final items = <ReplayItem>[];
    final seen = <String>{};
    for (final p in programs) {
      final channel = byEpgId[p.channelId];
      if (channel == null) continue;
      if (!isReplayableProgram(p, now: now, channelSupportsReplay: true)) {
        continue;
      }
      // Fenêtre propre à la chaîne : `catchup-days` de l'abonnement quand le
      // provider le déclare, 48 h sinon.
      if (now.difference(p.start) > archiveWindow(channel)) continue;

      final startEpoch = p.start.millisecondsSinceEpoch ~/ 1000;
      final endEpoch = p.end.millisecondsSinceEpoch ~/ 1000;
      final key = '${channel.id}_$startEpoch';
      if (!seen.add(key)) continue;

      final title = p.title.trim();
      if (title.isEmpty) continue;
      items.add(
        ReplayItem(
          id: key,
          title: title,
          streamUrl: replayStreamUrl(
            channel: channel,
            baseUrl: baseUrl,
            username: username,
            password: password,
            startEpoch: startEpoch,
            endEpoch: endEpoch,
          ),
          startTime: _formatReplayTime(p.start, now),
          endTime: _formatReplayTime(p.end, now),
          categoryId: channel.groupLabel,
          channelId: channel.id,
          channelName: channel.name,
          startDate: p.start,
          description: p.description.trim(),
          startAt: p.start,
          endAt: p.end,
        ),
      );
    }

    _logger.info(
      'Replay EPG global: ${items.length} programme(s) rejouable(s) '
      'sur ${programs.length} entrées, ${byEpgId.length} chaîne(s) DVR',
    );
    return items;
  }

  /// Fusionne les replays issus de l'EPG global (autoritaires) avec ceux de
  /// `get_short_epg`, en dédupliquant sur chaîne + début de programme.
  ///
  /// L'EPG global passe en premier : il est plus complet. `get_short_epg` ne
  /// sert qu'à rattraper une chaîne absente du dump XMLTV.
  static List<ReplayItem> mergeReplays(
    List<ReplayItem> fromEpg,
    List<ReplayItem> fromShortEpg,
  ) {
    final seen = <String>{};
    final merged = <ReplayItem>[];
    for (final r in [...fromEpg, ...fromShortEpg]) {
      final start = r.startAt?.millisecondsSinceEpoch ??
          r.startDate?.millisecondsSinceEpoch ??
          0;
      if (seen.add('${r.channelId}_$start')) merged.add(r);
    }
    return merged;
  }

  Future<List<ReplayItem>> fetchReplays() async {
    final sub = await _activeSub();

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

    final channelsResult = await safeAsync<List<Channel>>(
      () => fetchLiveChannels(),
      context: 'ApiService._fetchChannelReplayPrograms',
      fallbackValue: const <Channel>[],
    );
    final channels = channelsResult.getOrElse(const <Channel>[]);

    final flagged = channels
        .where(
          (c) => c.supportsReplay || c.name.toLowerCase().contains('replay'),
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
      }
      // Pas de fallback live TV : on n'affiche que les vrais programmes catch-up
      // issus de l'EPG (get_short_epg). Si aucun programme terminé n'est exposé
      // par le panel pour cette chaîne, on ne l'affiche pas.
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

  /// Constitution de l'ensemble des chaînes à sonder pour le replay.
  ///
  /// Le budget est GLOBAL ([budget]) : certains panels marquent TOUT le
  /// catalogue DVR (tv_archive partout) — sonder les ~200 chaînes martèlerait
  /// le panel et déclencherait l'anti-leech (blocage IP temporaire qui fait
  /// ensuite échouer le catalogue VOD). Le budget est donc réparti en
  /// round-robin PAR CATÉGORIE (au plus [perGroup] chaînes par groupe), en
  /// donnant la priorité aux chaînes explicitement DVR afin que toutes les
  /// catégories soient couvertes (pas de cluster « Seulement France HD » : le
  /// `take(25)` brut ne garderait que la première catégorie).
  static List<Channel> replayProbeSet(
    List<Channel> channels,
    List<Channel> flagged,
  ) {
    const budget = 40;
    const perGroup = 3;
    if (channels.isEmpty) return const <Channel>[];

    final flaggedIds = flagged.map((c) => c.id).toSet();
    final candidates = <Channel>[];
    final seen = <String>{};
    final takenByGroup = <String, int>{};

    void fillRoundRobin(List<Channel> source) {
      final byGroup = <String, List<Channel>>{};
      for (final c in source) {
        final g = c.groupLabel.isNotEmpty ? c.groupLabel : _unknownGroupLabel;
        byGroup.putIfAbsent(g, () => []).add(c);
      }
      final groupNames = byGroup.keys.toList();
      var allExhausted = false;
      while (candidates.length < budget && !allExhausted) {
        allExhausted = true;
        for (final group in groupNames) {
          if (candidates.length >= budget) break;
          final list = byGroup[group]!;
          final taken = takenByGroup[group] ?? 0;
          if (taken >= perGroup) continue;
          Channel? next;
          for (final c in list) {
            if (!seen.contains(c.id)) {
              next = c;
              break;
            }
          }
          if (next == null) continue;
          seen.add(next.id);
          candidates.add(next);
          takenByGroup[group] = taken + 1;
          allExhausted = false;
        }
      }
    }

    // 1. Chaînes explicitement DVR d'abord — réparties par catégorie pour
    //    ne jamais dépasser le budget total (anti-leech) ni clusteriser.
    fillRoundRobin(flagged);
    if (candidates.length >= budget) return candidates;
    // 2. Complétion du budget avec le reste de la grille (marquage partiel :
    //    le DVR du panel est souvent global, la marque elle ne l'est pas).
    fillRoundRobin(channels.where((c) => !flaggedIds.contains(c.id)).toList());
    return candidates;
  }

  static const String _unknownGroupLabel = '(sans groupe)';

  /// Point d'entrée de test pour le décodage des textes de panel.
  ///
  /// Le décodeur unique vit dans [PanelText]. Il était dupliqué ici : deux
  /// implémentations du même garde-fou finissent toujours par diverger, et c'est
  /// cette divergence qui avait laissé des titres en base64 à côté de titres
  /// corrects dans une même liste.
  @visibleForTesting
  static String decodeEpgTextForTest(String raw) => PanelText.decode(raw);

  /// Programmes EPG d'une chaîne via `get_short_epg` (JSON).
  ///
  /// Complément au XMLTV global : renseigne le guide d'une chaîne en direct sans
  /// télécharger l'intégralité du dump. Échec ⇒ liste vide, le flux principal
  /// (XMLTV) reste la référence.
  ///
  /// Les titres et synopsis de certains panels arrivent encodés en base64 ; le
  /// décodage passe désormais par [PanelText], qui porte les garde-fous.
  Future<List<EPGProgram>> fetchChannelEpgPrograms(Channel channel) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <EPGProgram>[];
    final result = await safeAsync<List<EPGProgram>>(
      () async {
        final url = _playerApiUrl(sub['baseUrl']!, 'player_api.php', {
          'username': sub['username']!,
          'password': sub['password']!,
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
        final programs = <EPGProgram>[];
        for (final e in list.whereType<Map>()) {
          final map = Map<String, dynamic>.from(e);
          final start =
              _parseReplayDate(map['start_timestamp'] ?? map['start']);
          final end = _parseReplayDate(map['stop_timestamp'] ?? map['end']);
          if (start == null || end == null || !end.isAfter(start)) continue;
          final title = PanelText.decode(
            map['title']?.toString().trim() ?? '',
          );
          if (title.isEmpty) continue;
          programs.add(
            EPGProgram(
              // `epgChannelId` peut contenir plusieurs candidats séparés par
              // une virgule : on retient le premier, sinon l'id de la chaîne.
              channelId: channel.primaryEpgChannelId.isNotEmpty
                  ? channel.primaryEpgChannelId
                  : channel.id,
              title: title,
              description: PanelText.decode(
                (map['description'] ?? map['plot'] ?? '').toString().trim(),
              ),
              start: start,
              end: end,
            ),
          );
        }
        return programs;
      },
      context: 'ApiService.fetchChannelEpgPrograms',
      fallbackValue: const <EPGProgram>[],
    );
    return result.getOrElse(const <EPGProgram>[]);
  }

  /// Programmes rejouables d'**une seule** chaîne : un appel.
  ///
  /// ## L'endpoint qui compte
  ///
  /// `get_short_epg` ne sert **pas** à ça. Sa documentation le dit : « aperçu
  /// rapide des **prochains** programmes ». Il renvoie 4 entrées, toutes
  /// futures, et le filtre « terminé » les élimine toutes — d'où un Replay vide
  /// alors que le panel archive bien. Mesuré le 30/09 : `0 programme(s)
  /// rejouable(s) sur 4 renvoyés par get_short_epg`.
  ///
  /// L'EPG complet d'une chaîne, celui qui est « nécessaire pour calculer le
  /// Replay », vient de `get_simple_data_table&stream_id=…`. Cet appel n'était
  /// fait nulle part dans l'application.
  ///
  /// Un seul appel par chaîne, comme le niveau 1 de l'écran : le catalogue
  /// compte plus de 1400 chaînes rejouables, et les sonder toutes déclencherait
  /// la tempête de 429 qui vide l'EPG, les Films et le Live TV.
  Future<List<ReplayItem>> fetchChannelReplays(Channel channel) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <ReplayItem>[];
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final now = DateTime.now();

    final entries = await _fetchChannelFullEpg(
      baseUrl: baseUrl,
      username: username,
      password: password,
      channel: channel,
    );

    // Repli : certains panels ne servent pas l'EPG complet par cet appel. On
    // retente alors avec l'aperçu court, qui ne donnera que les rares
    // programmes déjà diffusés — moins de résultats, mais mieux que rien.
    if (entries.isEmpty) {
      return _fetchChannelReplayPrograms(
        baseUrl: baseUrl,
        username: username,
        password: password,
        channel: channel,
        now: now,
      );
    }

    // Fenêtre de l'abonnement pour CETTE chaîne (`tv_archive_duration`). Le tri
    // par jour est fait par l'écran ; on renvoie du plus récent au plus ancien,
    // qui est l'ordre de lecture attendu.
    final window = archiveWindow(channel);
    final items = <ReplayItem>[];
    final seen = <int>{};
    for (final e in entries) {
      final map = Map<String, dynamic>.from(e);
      final start = _parseReplayDate(map['start_timestamp'] ?? map['start']);
      final end = _parseReplayDate(
        map['stop_timestamp'] ?? map['stop'] ?? map['end'],
      );
      if (start == null || end == null) continue;
      if (!end.isBefore(now)) continue; // pas encore terminé
      if (now.difference(start) > window) continue; // hors fenêtre du compte
      // Ce panel encode les titres et descriptifs en base64 : sans décodage,
      // la table affichait « TxkgTWlsbGlvbg== » là où il faut lire
      // « Le Bulletin ». Le décodage est prudent (longueur, alphabet, contrôle
      // de caractères) : un titre en clair qui ressemblerait à du base64 n'est
      // jamais altéré.
      final title = PanelText.decode(
        map['title']?.toString().trim() ?? '',
      );
      if (title.isEmpty) continue;
      final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
      if (!seen.add(startEpoch)) continue;
      items.add(
        ReplayItem(
          id: '${channel.id}_$startEpoch',
          title: title,
          streamUrl: replayStreamUrl(
            channel: channel,
            baseUrl: baseUrl,
            username: username,
            password: password,
            startEpoch: startEpoch,
            endEpoch: end.millisecondsSinceEpoch ~/ 1000,
          ),
          startTime: _formatReplayTime(start, now),
          endTime: _formatReplayTime(end, now),
          categoryId: channel.groupLabel,
          channelId: channel.id,
          channelName: channel.name,
          startDate: start,
          description: PanelText.decode(
            _firstString(map, const [
              'description',
              'plot',
              'desc',
              'summary',
            ]),
          ),
          host: PanelText.decode(
            _firstString(map, const [
              'name',
              'presenter',
              'host',
              'director',
              'actor',
            ]),
          ),
          startAt: start,
          endAt: end,
        ),
      );
    }
    items.sort(
      (a, b) => (b.startAt ?? b.startDate ?? DateTime(1900))
          .compareTo(a.startAt ?? a.startDate ?? DateTime(1900)),
    );

    _logger.info(
      'Replay ${channel.name}: ${items.length} programme(s) rejouable(s) '
      'sur ${entries.length} de l\'EPG complet '
      '(fenêtre ${window.inDays} j, archive ${channel.archiveDays} j)',
      tag: 'replay',
    );
    return items;
  }

  /// EPG complet d'une chaîne (`get_simple_data_table&stream_id=…`).
  ///
  /// Séparé de [fetchChannelReplays] pour que le tri, le filtre et la
  /// construction d'URL soient testables sans réseau.
  Future<List<Map<String, dynamic>>> _fetchChannelFullEpg({
    required String baseUrl,
    required String username,
    required String password,
    required Channel channel,
  }) async {
    final result = await safeAsync<List<Map<String, dynamic>>>(
      () async {
        final url = _playerApiUrl(baseUrl, 'player_api.php', {
          'username': username,
          'password': password,
          'action': 'get_simple_data_table',
          'stream_id': channel.id,
        });
        final response = await _get(url);
        final data = response.data;
        // Trois formes rencontrées : liste nue, `epg_listings` (variante
        // get_short_epg) et `epg_programmes` (variante get_simple_data_table).
        final list = data is List
            ? data
            : (data is Map
                ? (data['epg_programmes'] as List? ??
                    data['epg_listings'] as List? ??
                    const <dynamic>[])
                : const <dynamic>[]);
        final entries = <Map<String, dynamic>>[];
        for (final e in list.whereType<Map>()) {
          entries.add(Map<String, dynamic>.from(e));
        }
        _logger.info(
          'EPG complet ${channel.name} (${channel.id}): ${entries.length} '
          'programme(s) via get_simple_data_table',
          tag: 'replay',
        );
        return entries;
      },
      context: 'ApiService._fetchChannelFullEpg',
      fallbackValue: const <Map<String, dynamic>>[],
    );
    return result.getOrElse(const <Map<String, dynamic>>[]);
  }

  /// URL de lecture d'un programme de replay.
  ///
  /// Le template `catchup-source` déclaré par le provider, s'il y en a un,
  /// **prime sur tout** : c'est lui qui décrit le chemin de replay réel. En
  /// son absence on applique la convention Xtream Codes
  /// (`/timeshift/user/pass/durée/date/id.ext`), qui est celle de ce panel —
  /// `get_live_streams` n'y expose pas de `catchup-source`, contrairement aux
  /// playlists M3U qui en déclarent toujours un.
  ///
  /// Inventer une URL alors qu'un template est disponible donnait des liens
  /// morts : le programme était listé, puis la lecture échouait.
  String replayStreamUrl({
    required Channel channel,
    required String baseUrl,
    required String username,
    required String password,
    required int startEpoch,
    required int endEpoch,
  }) {
    final fromTemplate = CatchupUrl.build(
      channel: channel,
      start: DateTime.fromMillisecondsSinceEpoch(startEpoch * 1000),
      end: DateTime.fromMillisecondsSinceEpoch(endEpoch * 1000),
    );
    if (fromTemplate != null && fromTemplate.isNotEmpty) return fromTemplate;
    return buildXtreamTimeshiftUrl(
      baseUrl,
      username,
      password,
      channel.id,
      start: startEpoch,
      end: endEpoch,
    );
  }

  /// Fenêtre de retroactivité d'une chaîne.
  ///
  /// `catchup-days` / `tv_archive_duration` est la fenêtre **de l'abonnement**
  /// — 48 h, 7 jours, 14 jours selon le compte. C'est donc elle qu'on lit, et
  /// le 48 h n'est plus qu'un repli pour les panels qui ne déclarent rien.
  static Duration archiveWindow(Channel channel) {
    if (channel.archiveDays > 0) return Duration(days: channel.archiveDays);
    return _replayWindow;
  }

  /// Programmes terminés et rejouables d'une chaîne DVR (get_short_epg).
  Future<List<ReplayItem>> _fetchChannelReplayPrograms({
    required String baseUrl,
    required String username,
    required String password,
    required Channel channel,
    required DateTime now,
  }) async {
    final result = await safeAsync<List<ReplayItem>>(
      () async {
        final url = _playerApiUrl(baseUrl, 'player_api.php', {
          'username': username,
          'password': password,
          'action': 'get_short_epg',
          'stream_id': channel.id,
          // `get_short_epg` plafonne à 4 entrées par défaut. Quatre programmes
          // en pleine journée couvrent à peine deux heures, tous FUTURS : le
          // filtre « terminé uniquement » les supprimait tous et l'écran
          // finissait sur « aucun replay disponible », alors que le panel en
          // publie. On demande explicitement une fenêtre couvrant les
          // `_replayWindow`.
          'limit': '${_replayLimit}',
        });
        final response = await _get(url);
        final data = response.data;
        final list = data is List
            ? data
            : (data is Map
                ? (data['epg_listings'] as List? ?? const <dynamic>[])
                : const <dynamic>[]);
        final items = <ReplayItem>[];
        // Diagnostic : `get_short_epg` plafonne par défaut à 4 entrées, et un
        // panel peut en renvoyer 0 malgré `tv_archive: 1`. Sans ce log, un
        // « aucun replay disponible » est indiscernable d'un vrai panel vide.
        _logger.info(
          'Replay ${channel.name} (${channel.id}): short_epg limit=$_replayLimit '
          '-> ${list.length} entrées brutes',
        );
        // Relevé des entrées brutes : sans lui, « 0 programme rejouable sur 4 »
        // est indécidable. Les 4 peuvent être toutes futures (le panel ne
        // publie pas d'historique par cet appel), ou des passées rejetées par
        // notre filtre — et les deux appellent des corrections opposées.
        final window = archiveWindow(channel);
        final sample = <String>[];
        for (final e in list.whereType<Map>().take(6)) {
          final map = Map<String, dynamic>.from(e);
          final s = _parseReplayDate(map['start_timestamp'] ?? map['start']);
          final en = _parseReplayDate(map['stop_timestamp'] ?? map['end']);
          if (s == null || en == null) {
            sample.add('?');
            continue;
          }
          final delta = now.difference(s);
          final hours = (delta.inMinutes / 60).round();
          final state = en.isBefore(now) ? 'terminé' : 'à venir';
          final tooOld = delta > window ? ', hors fenêtre' : '';
          sample.add(
            '${_formatReplayTime(s, now)} ($hours h, $state$tooOld)',
          );
        }
        if (sample.isNotEmpty) {
          _logger.info(
            'Replay ${channel.name}: entrées = ${sample.join(' | ')} '
            '(fenêtre ${window.inDays} j)',
            tag: 'replay',
          );
        }
        for (final e in list.whereType<Map>()) {
          final map = Map<String, dynamic>.from(e);
          final start =
              _parseReplayDate(map['start_timestamp'] ?? map['start']);
          final end = _parseReplayDate(map['stop_timestamp'] ?? map['end']);
          if (start == null || end == null) continue;
          if (!end.isBefore(now)) continue; // programme pas encore terminé
          // Fenêtre de rétroactivité : `catchup-days` de l'abonnement quand le
          // provider le déclare (48 h, 7 j, 14 j selon le compte), 48 h sinon.
          // Fixer 48 h en dur éliminait à tort les replays d'un compte
          // annonçant 7 jours : le programme était bien servi, il était
          // filtré de notre côté.
          if (now.difference(start) > archiveWindow(channel))
            continue; // trop ancien
          // Même décodage que le chemin `get_simple_data_table` : ce panel
          // encode les titres en base64 sur les deux appels. Sans lui, les
          // chaînes servies par ce repli affichaient « QWxsZSwgbGUgbG9pciI »
          // alors que les autres étaient lisibles.
          final title = PanelText.decode(
            map['title']?.toString().trim() ?? '',
          );
          if (title.isEmpty) continue;
          final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
          final endEpoch = end.millisecondsSinceEpoch ~/ 1000;
          items.add(
            ReplayItem(
              id: '${channel.id}_$startEpoch',
              title: title,
              streamUrl: replayStreamUrl(
                channel: channel,
                baseUrl: baseUrl,
                username: username,
                password: password,
                startEpoch: startEpoch,
                endEpoch: endEpoch,
              ),
              startTime: _formatReplayTime(start, now),
              endTime: _formatReplayTime(end, now),
              categoryId: channel.groupLabel,
              channelId: channel.id,
              channelName: channel.name,
              startDate: start,
              // Résumé et présentation : `get_short_epg` les fournit sous
              // des noms de champs variables selon les panels. On les lit
              // tous, et l'affichage masque ce qui est vide.
              description: PanelText.decode(
                _firstString(map, const [
                  'description',
                  'plot',
                  'desc',
                  'summary',
                ]),
              ),
              host: PanelText.decode(
                _firstString(map, const [
                  'name',
                  'presenter',
                  'host',
                  'director',
                  'actor',
                ]),
              ),
              startAt: start,
              endAt: end,
            ),
          );
        }
        _logger.info(
          'Replay ${channel.name}: ${items.length} programme(s) rejouable(s) '
          'sur ${list.length} renvoyés par get_short_epg',
        );
        return items;
      },
      context: 'ApiService._fetchChannelReplayPrograms',
      fallbackValue: const <ReplayItem>[],
    );
    return result.getOrElse(const <ReplayItem>[]);
  }

  /// Replay M3U : les chaînes portant un attribut `catchup`/`timeshift`
  /// apparaissent directement comme rejouables.
  Future<List<ReplayItem>> _fetchM3uReplays(Map<String, String?> sub) async {
    // M3U playlists don't carry catch-up program metadata (what aired when).
    // Real catch-up requires an EPG source (XMLTV) to know what aired when.
    // The M3U `catchup`/`catchup-days` attributes only indicate *support*, not
    // program metadata. Returning empty here avoids false "Replay à Channel"
    // entries that just play the live stream.
    return const <ReplayItem>[];
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

  /// Première clé non vide parmi [keys], normalisée en texte brut.
  ///
  /// Les panels n'utilisent pas les mêmes noms de champs d'une installation à
  /// l'autre : `description` / `plot` / `desc`, `name` / `presenter` /
  /// `director`... On essaie donc une liste ordonnée par fréquence décroissante
  /// plutôt que de coder un nom unique, sinon la moitié des replays
  /// s'afficheraient sans résumé ni présentateur.
  ///
  /// Les balises HTML éventuelles sont retirées : le texte est rendu dans un
  /// `Text` Flutter, où du markup apparaissait littéralement.
  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final raw = map[k];
      if (raw == null) continue;
      var v = raw.toString().trim();
      if (v.isEmpty) continue;
      // Le XMLTV échappe l'apostrophe en `&apos;` : sans cette correction le
      // titre s'affichait littéralement « C dans l&apos;achat ».
      //
      // `&amp;` passe en DERNIER : le dé-échapprement doit être unique,
      // sinon un `&amp;apos;` légitime deviendrait une apostrophe.
      v = v
          .replaceAll('&apos;', "'")
          .replaceAll('&#39;', "'")
          .replaceAll('&quot;', '"')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&');
      if (v.contains('<')) {
        // Le nettoyage des balises vient APRÈS l'échappement : sinon
        // `&lt;b&gt;` redeviendrait une balise et disparaîtrait au lieu de
        // s'afficher.
        v = v
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim();
      }
      if (v.isNotEmpty) return v;
    }
    return '';
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
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${local.day} ${months[local.month - 1]} $h:$m';
  }

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
      // `responseType: bytes` : on veut les octets bruts, pas une String déjà
      // décodée par Dio selon un charset HTTP souvent absent => accents
      // cassés. Le décodage réel est fait par [_decodeXmltvPayload].
      final response = await _get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      // Le dump XMLTV est massivement en UTF-8 alors que le panel_Xtream sert
      // souvent `Content-Type: text/xml` SANS charset : Dio applique alors son
      // défaut (latin1), ce qui transformait chaque accent en « é ». On
      // décode donc les octets bruts nous-mêmes, en suivant la déclaration
      // `encoding=` du prologue XML quand elle existe.
      final content = _decodeXmltvPayload(response);
      // Le parse complet (~94 000 entrées) est lourd : déporté sur un isolate
      // pour ne pas figer le thread UI (évite l'ANR sur les box TV/phones).
      final programs = await compute(_parseXmltvIsolate, content);
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

  /// Décode une réponse JSON dont l'encodage HTTP est absent ou faux.
  ///
  /// Le panel_Xtream sert parfois `text/html` ou `text/xml` sans `charset` :
  /// Dio décode alors en latin1, ce qui corrompt les accents. Contrairement au
  /// XMLTV, on ne peut pas se fier au prologue du document, donc on essaie
  /// l'UTF-8 en premier (repli sur latin1 si le contenu n'est pas de l'UTF-8
  /// valide — typiquement un JSON déjà échappé en latin1 par le panel).
  static dynamic _decodeJsonPayload(Response<dynamic> response) {
    final dynamic data = response.data;
    if (data is! List<int>) return data;

    // Tentative UTF-8 : si elle réussit, c'est de l'UTF-8.
    try {
      return jsonDecode(utf8.decode(data));
    } catch (_) {
      // Ignoré : on tente latin1 ci-dessous.
    }
    try {
      return jsonDecode(latin1.decode(data));
    } catch (_) {
      return null;
    }
  }

  /// Décode le corps XMLTV en respectant l'encodage réellement déclaré.
  ///
  /// Priorité : la déclaration `encoding="…"` du prologue XML, puis l'en-tête
  /// HTTP de la réponse, puis UTF-8. On retombe sur latin1 seulement si le
  /// décodage strict UTF-8 échoue, ce qui couvre les vieux dumps CP1252.
  static String _decodeXmltvPayload(Response<dynamic> response) {
    final dynamic data = response.data;
    final List<int> bytes;
    if (data is List<int>) {
      bytes = data;
    } else if (data is String) {
      // Dio a déjà décodé : on ne peut plus rattraper l'encodage, on réencode
      // en UTF-8 pour uniformiser la suite du traitement.
      return data;
    } else {
      return data?.toString() ?? '';
    }

    // 1. Déclaration XML du prologue (les 4 premiers Ko suffisent).
    final head = latin1.decode(bytes.take(4096).toList(), allowInvalid: true);
    final match = RegExp(
      "encoding\\s*=\\s*['\"]([A-Za-z0-9_.\\-]+)['\"]",
      caseSensitive: false,
    ).firstMatch(head);
    final declared = match?.group(1)?.toLowerCase();

    // 2. En-tête HTTP.
    final header = response.headers.value('content-type')?.toLowerCase() ?? '';
    final headerCharset =
        RegExp('charset=([A-Za-z0-9_.\\-]+)').firstMatch(header)?.group(1);

    final candidates = <String>[
      if (declared != null) declared,
      if (headerCharset != null) headerCharset,
      'utf-8',
      'iso-8859-1',
    ];

    for (final charset in candidates) {
      final decoded = _decodeCharset(bytes, charset);
      if (decoded != null) return decoded;
    }
    // `iso-8859-1` ne lève jamais : cette ligne est donc inatteignable en
    // pratique, mais garantit un String non-null.
    return latin1.decode(bytes, allowInvalid: true);
  }

  /// Décode [bytes] avec [charset]. Retourne null si l'encodage est inconnu ou
  /// si le décodage strict échoue (ce qui permet d'essayer le suivant).
  static String? _decodeCharset(List<int> bytes, String charset) {
    final name = charset.toLowerCase().trim();
    try {
      if (name == 'utf-8' || name == 'utf8') {
        return utf8.decode(bytes);
      }
      if (name == 'iso-8859-1' ||
          name == 'latin1' ||
          name == 'iso8859-1' ||
          name == 'windows-1252' ||
          name == 'cp1252') {
        return latin1.decode(bytes, allowInvalid: true);
      }
    } catch (_) {
      return null;
    }
    return null;
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
    final uri = Uri.parse(_trimBaseUrl(baseUrl));
    final durationMinutes = ((end - start) / 60).ceil().clamp(1, 1 << 20);
    final startLocal = DateTime.fromMillisecondsSinceEpoch(start * 1000);
    final two = (int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${startLocal.year}-${two(startLocal.month)}-${two(startLocal.day)}'
        ':${two(startLocal.hour)}-${two(startLocal.minute)}';
    final ext = _normalizeTimeshiftExtension(extension);

    final segments = <String>[
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      'timeshift',
      username,
      password,
      '$durationMinutes',
      stamp,
      '$streamId.$ext',
    ];
    return uri.replace(pathSegments: segments).toString();
  }

  /// Extension de sortie du timeshift.
  ///
  /// `.ts` par défaut : c'est le format servi en priorité par les panels.
  /// `.m3u8` est accepté pour les comptes dont `allowed_output_formats`
  /// écarte le transport stream.
  static String _normalizeTimeshiftExtension(String? extension) {
    var ext = (extension ?? 'ts').trim().replaceFirst(RegExp(r'^\.'), '');
    ext = ext.toLowerCase();
    if (ext.isEmpty) return 'ts';
    if (ext == 'mpegts' || ext == 'mpeg-ts') return 'ts';
    if (ext == 'hls' || ext == 'm3u8') return 'm3u8';
    return ext;
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
    // Attributs catch-up de la ligne #EXTINF en cours.
    //
    // Ils étaient lus sur la ligne d'URL qui suit, où ils n'existent pas :
    // `catchup`, `catchup-days` et `timeshift` revenaient donc VIDES, et
    // `supportsReplay` valait toujours `false` en M3U — le replay était mort
    // avant même d'être cherché. Les attributs sont déclarés sur #EXTINF, il
    // faut donc les lire là, au moment où on la parse.
    var catchupMode = '';
    var catchupSource = '';
    var catchupDays = 0;
    var timeshift = 0;
    for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        if (nameMatch != null) {
          currentName = nameMatch.group(1)!.trim();
        }
        currentGroup = _m3uAttr(line, 'group-title').trim();
        catchupMode = _m3uAttr(line, 'catchup').trim().toLowerCase();
        catchupSource = _m3uAttr(line, 'catchup-source').trim();
        catchupDays = int.tryParse(_m3uAttr(line, 'catchup-days').trim()) ?? 0;
        timeshift = int.tryParse(_m3uAttr(line, 'timeshift').trim()) ?? 0;
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentName != null) {
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
              // `catchup="none"` est la valeur d'absence explicite : elle ne
              // doit pas compter comme un mode de substitution.
              supportsReplay:
                  (catchupMode.isNotEmpty && catchupMode != 'none') ||
                      catchupSource.isNotEmpty ||
                      catchupDays > 0 ||
                      timeshift > 0,
              timeshift: Duration(seconds: timeshift),
              // `catchup-days` EST la fenêtre de l'abonnement. C'est elle qui
              // remplace le 48 h deviné : 48 h, 7 j ou 14 j selon le compte.
              archiveDays: catchupDays,
              catchupMode: catchupMode,
              catchupSource: catchupSource,
            ),
          );
          currentName = null;
          currentGroup = null;
          catchupMode = '';
          catchupSource = '';
          catchupDays = 0;
          timeshift = 0;
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

/// Portillon d'appels au panel : espacement minimal entre deux requêtes et
/// plafond d'appels simultanés.
///
/// Le rate-limit du panel est GLOBAL : une rafale (sonde Replay sur 40 chaînes,
/// chargement VOD + séries + EPG en parallèle) le fait répondre 429 à tout le
/// monde, y compris aux requêtes sans rapport avec la rafale. Sérialiser évite
/// de déclencher la saturation au lieu de la subir.
///
/// L'espacement est adaptatif : un 429 l'allonge, et il redescend
/// progressivement vers [_minGap] quand les appels réussissent, pour ne pas
/// imposer un rythme lent sans raison après un incident isolé.
class _ApiGate {
  /// Espacement de base entre deux appels.
  static const Duration _minGap = Duration(milliseconds: 120);

  /// Espacement maximum, atteint après plusieurs refus consécutifs.
  static const Duration _maxGap = Duration(seconds: 2);

  /// Appels simultanés maximum.
  static const int _maxConcurrent = 3;

  /// Attente entre deux vérifications de disponibilité d'un créneau.
  static const Duration _poll = Duration(milliseconds: 25);

  DateTime _nextAllowedAt = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _gap = _minGap;
  int _inFlight = 0;
  int _consecutive429 = 0;

  /// Acquiert un ticket d'appel : attend, au besoin, que l'espacement soit
  /// respecté et qu'un créneau soit libre.
  ///
  /// Le bloc de décision est synchrone et sans `await` : aucune préemption
  /// n'est possible entre la lecture et la mise à jour de l'état, la boucle
  /// d'attente ne peut donc pas laisser deux appels obtenir le même créneau.
  Future<void> acquire() async {
    while (true) {
      var wait = Duration.zero;
      var admitted = false;
      final now = DateTime.now();
      if (_inFlight >= _maxConcurrent) {
        wait = _poll;
      } else if (now.isBefore(_nextAllowedAt)) {
        wait = _nextAllowedAt.difference(now);
      } else {
        _inFlight++;
        _nextAllowedAt = now.add(_gap);
        admitted = true;
      }
      if (admitted) return;
      await Future<void>.delayed(wait);
    }
  }

  /// Signale un refus 429 : l'espacement croît, comme le compteur de refus
  /// consécutifs.
  void onRateLimited() {
    _consecutive429++;
    final scaled = _minGap.inMilliseconds * (_consecutive429 + 1);
    _gap = Duration(
      milliseconds:
          scaled > _maxGap.inMilliseconds ? _maxGap.inMilliseconds : scaled,
    );
    _nextAllowedAt = DateTime.now().add(_gap);
  }

  /// Signale un appel réussi : le compteur de refus redescend d'un cran et
  /// l'espacement se rapproche du minimum.
  void onSuccess() {
    if (_consecutive429 > 0) _consecutive429--;
    final halved = _gap.inMilliseconds ~/ 2;
    final floor = _minGap.inMilliseconds;
    _gap = Duration(milliseconds: halved < floor ? floor : halved);
  }

  /// Libère le créneau occupé par un appel terminé.
  void release() {
    if (_inFlight > 0) _inFlight--;
  }

  /// Nombre de refus 429 consécutifs (diagnostic).
  int get consecutiveRateLimits => _consecutive429;
}
