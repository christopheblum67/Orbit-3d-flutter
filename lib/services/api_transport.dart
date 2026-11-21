import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/services/api_rate_limiter.dart';
import 'package:orbit_3d_flutter/services/api_request_gate.dart';
import 'package:orbit_3d_flutter/services/certificate_pinning.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    show StreamNetworkException;

class ApiTransport {
  ApiTransport({required this.rateLimiter});

  static Set<String>? _certificateFingerprints;

  static void setCertificateFingerprints(Set<String>? fingerprints) {
    _certificateFingerprints =
        fingerprints?.isNotEmpty == true ? fingerprints : null;
  }

  Future<Response<dynamic>> request(
    String url, {
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) =>
      _get(url, options: options, onReceiveProgress: onReceiveProgress);

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

    // Limiteur de débit : espace les départs de requêtes et se tait après un 429.
    //
    // Mesuré sur le panel `1.888000.eu` : sans cela, tout partait en rafale et
    // TOUT était refusé, y compris la première requête (429 en 130–200 ms).
    dio.interceptors.add(rateLimiter.interceptor);

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

  final LoggerService _logger = LoggerService.instance;

  /// Limiteur de débit partagé par tous les appels de cette instance.
  ///
  /// Volontairement une seule instance par `ApiService` : le budget doit être
  /// commun à tous les appels, sinon chaque écran repartirait de zéro.
  final ApiRateLimiter rateLimiter;

  Future<Response<dynamic>> _get(
    String url, {
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) {
    return stream_helpers.retryStream(
      () => _performGet(url, options, onReceiveProgress),
      // Le panel applique un rate-limit (429) sous charge : on retente 3 fois
      // avec 1,2 s d'écart avant d'abandonner (démarrage séquentiel en plus).
      //
      // SAUF sur 429, qui n'est PAS une panne transitoire mais un « tu vas trop
      // vite » : le réessayer ici multipliait la pression (3 × 2 retries
      // internes = jusqu'à 9 requêtes pour un seul appel logique) et
      // entretenait le blocage. Un 429 remonte immédiatement : c'est
      // [ApiRequestGate] qui espace les appels suivants, et l'utilisateur voit un
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
  static final ApiRequestGate _apiGate = ApiRequestGate();
  static int _nextPlaylistRequestId = 0;

  Future<Response<dynamic>> get(String url) => _get(url);

  /// Nombre de re-essais sur rejet HTTP non 2xx (429/5xx).
  ///
  /// Volontairement bas : le rejet est en général dû à une rafale de requêtes
  /// simultanées, et repartir en force aggraverait la situation. Un repli
  /// croissant suffit à attendre que la rafale retombe.
  static const int _badResponseRetries = 2;

  Future<Response<dynamic>> _performGet(
    String url, [
    Options? extra,
    ProgressCallback? onReceiveProgress,
  ]) async {
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
    final traceId = extra?.extra?['orbitM3uTraceId'];
    final requestId = traceId is int ? ++_nextPlaylistRequestId : null;
    if (requestId != null) {
      logDiag('M3U gate trace=$traceId attempt=$requestId state=waiting');
    }
    await _apiGate.acquire();
    if (requestId != null) {
      logDiag(
          'M3U gate trace=$traceId attempt=$requestId state=acquired '
          'waitMs=${sw.elapsedMilliseconds}');
    }
    try {
      final res = await _dio.get<dynamic>(
        url,
        options: (extra ?? Options()).copyWith(receiveTimeout: budget),
        onReceiveProgress: onReceiveProgress,
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
            options:
                (extra ?? Options()).copyWith(receiveTimeout: _slowTimeout),
            onReceiveProgress: onReceiveProgress,
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
      // tout de suite, et [ApiRequestGate] espace les appels suivants.
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
              onReceiveProgress: onReceiveProgress,
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
}
