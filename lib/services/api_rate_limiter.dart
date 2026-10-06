import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

/// Limiteur de débit des requêtes envoyées à un panel Xtream.
///
/// ## Pourquoi
///
/// Mesuré sur le S20 (logcat, panel `1.888000.eu`), sans aucune limite côté
/// application :
///
/// ```
/// 08:38:15.174 GET get_user_info      -> 429 en 185 ms
/// 08:38:19.727 GET get_live_categories -> 429 en 173 ms
/// 08:38:20.394 GET get_live_streams    -> 429 en 493 ms
/// 08:38:21.947 GET get_live_categories -> 429 en 129 ms   (doublon)
/// 08:38:22.677 GET get_live_streams    -> 429 en 729 ms   (doublon)
/// ```
///
/// Les réponses tombaient en ~130–200 ms : le panel ne cherchait pas à être
/// lent, il **rejetait** — le quota était déjà consommé. Rien dans le code
/// n'espacait les appels, donc tout ce que l'application demandait partait en
/// rafale et la réponse était toujours « non ».
///
/// Aucun correctif « réessayer » ne peut résoudre cela : réessayer pendant une
/// limitation ne fait qu'allonger la limitation. Il faut apparemment **réduire
/// le débit**, et savoir se taire après un refus.
///
/// ## Ce que fait la classe
///
/// 1. [beforeRequest] espace les départs de requêtes de [minInterval].
///    Les requêtes peuvent ensuite se chevaucher si le panel répond lentement :
///    on borne la FRÉQUENCE, pas la concurrence.
/// 2. [onRateLimited] met l'application en carence jusqu'à l'instant indiqué
///    par le panel (`Retry-After` / `X-RateLimit-Reset`), ou [defaultCooldown]
///    si le panel n'en dit rien.
///
/// L'horloge est injectable pour que les tests n'aient pas à dormir.
class ApiRateLimiter {
  ApiRateLimiter({
    this.minInterval = const Duration(milliseconds: 250),
    this.defaultCooldown = const Duration(seconds: 10),
    this.maxCooldown = const Duration(minutes: 1),
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  })  : _clock = clock ?? DateTime.now,
        _sleep = sleep ?? Future<void>.delayed;

  /// Écart minimal entre deux départs de requêtes.
  final Duration minInterval;

  /// Carence appliquée quand le panel ne dit pas combien de temps attendre.
  ///
  /// Volontairement long : sur ce panel, quelques centaines de millisecondes
  /// ne suffisaient pas, et repartir trop tôt consommait le quota restant.
  final Duration defaultCooldown;

  /// Plafond de la croissance exponentielle.
  ///
  /// Un quota de panel se réinitialise sur une fenêtre de temps, pas en
  /// quelques secondes. Insister toutes les 10 s ne fait que consommer du
  /// quota restant : la carence croît donc tant que le panel refuse.
  ///
  /// **Plafond à 60 s, délibérément bas.** Mesuré sur le S20 : avec 5 min,
  /// la file entière de requêtes restait suspendue et le changement
  /// d'abonnement restait affiché à 0 %, sans qu'aucune requête ne parte
  /// réellement. Un plafond plus élevé ne relance pas plus vite — il rend
  /// surtout l'application indistinctement d'un plantage.
  final Duration maxCooldown;

  /// Facteur de croissance après chaque refus.
  static const int growthFactor = 3;

  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;

  DateTime? _lastStart;
  DateTime? _cooldownUntil;
  int _throttled = 0;
  int _cooldowns = 0;
  int _consecutiveRateLimits = 0;

  /// Nombre de requêtes retardées par l'espacement.
  int get throttledRequests => _throttled;

  /// Nombre de fois où une carence a été appliquée.
  int get cooldownCount => _cooldowns;

  /// Fin de la carence en cours, s'il y en a une.
  DateTime? get cooldownUntil => _cooldownUntil;

  bool get isCoolingDown =>
      _cooldownUntil != null && _clock().isBefore(_cooldownUntil!);

  /// À appeler avant chaque départ de requête.
  ///
  /// Ne fait rien si aucune attente n'est nécessaire : le chemin rapide ne doit
  /// jamais coûter une suspension.
  Future<void> beforeRequest() async {
    final now = _clock();

    // Carence : on attend le plus tard des deux, expiration ou fin de carence.
    var waitUntil = _cooldownUntil;
    final pacedFrom = _lastStart;
    if (pacedFrom != null) {
      final earliest = pacedFrom.add(minInterval);
      if (waitUntil == null || earliest.isAfter(waitUntil)) {
        waitUntil = earliest;
      }
    }

    if (waitUntil != null && now.isBefore(waitUntil)) {
      final delay = waitUntil.difference(now);
      _throttled++;
      await _sleep(delay);
    }

    _lastStart = _clock();
  }

  /// À appeler sur une réponse 429.
  ///
  /// [retryAfter] vient de `Retry-After` ou `X-RateLimit-Reset` ; à défaut,
  /// c'est [defaultCooldown].
  void onRateLimited(Duration? retryAfter) {
    final now = _clock();
    _consecutiveRateLimits++;
    // Croissance exponentielle plafonnée : insister à intervalle CONSTANT ne
    // fait que maintenir la limitation. 10 s, puis 30 s, puis 90 s…
    //
    // Un quota de panel se réinitialise sur une fenêtre de temps, pas en
    // quelques secondes : attendre 10 s entre chaque refus revenait à
    // demander sans jamais etre entendu.
    final backoff =
        defaultCooldown * _pow(growthFactor, _consecutiveRateLimits - 1);
    final capped = backoff > maxCooldown ? maxCooldown : backoff;
    final until = now.add(retryAfter ?? capped);
    // Un panel qui réclame PLUS de carence qu'on n'en a déjà ne doit pas être
    // contrarié : on retient toujours la plus longue des deux.
    if (_cooldownUntil == null || until.isAfter(_cooldownUntil!)) {
      _cooldownUntil = until;
    }
    _cooldowns++;
  }

  /// Une réponse réussie annule la croissance : le quota est revenu.
  void onSuccess() {
    _consecutiveRateLimits = 0;
  }

  /// Ouvre une nouvelle fenêtre de tentative.
  ///
  /// Appelé au changement d'abonnement : on interroge un AUTRE panel, dont le
  /// quota n'a rien à voir avec celui qui vient de refuser. Conserver la
  /// carence rendrait le nouveau compte également bloqué, pour une raison
  /// qui ne le concerne pas — c'est exactement ce qui a produit «
  /// changement d'abonnement à 0 % ».
  ///
  /// Seul l'espacement minimal est conservé : la cadence reste polie.
  void onNewTarget() {
    _consecutiveRateLimits = 0;
    _cooldownUntil = null;
  }

  /// Nombre de refus consécutifs, pour le diagnostic.
  int get consecutiveRateLimits => _consecutiveRateLimits;

  static int _pow(int base, int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= base;
      // Garde-fou : au-delà, la valeur n'a plus de sens et le plafond de
      // [maxCooldown] prend le relais de toute façon.
      if (result > 100000) return 100000;
    }
    return result;
  }

  /// Remet le limiteur à zéro.
  ///
  /// Réservé aux tests : en production, un reset en cours de session
  /// effacerait la carence obtenue du panel.
  @visibleForTesting
  void reset() {
    _lastStart = null;
    _cooldownUntil = null;
    _throttled = 0;
    _cooldowns = 0;
    _consecutiveRateLimits = 0;
  }

  /// Intercepteur Dio : espace les départs et applique la carence.
  ///
  /// `QueuedInterceptorsWrapper` sérialise les `onRequest`, ce qui donne
  /// l'espacement voulu, tout en laissant les requêtes se chevaucher ensuite :
  /// on borne la fréquence, pas la concurrence.
  Interceptor get interceptor => QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          await beforeRequest();
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Une réponse non-erreur signifie que le quota est revenu : on
          // ramène la croissance à zéro, sinon la carence resterait longue
          // alors que le panel nous accepte de nouveau.
          if ((response.statusCode ?? 0) < 400) onSuccess();
          handler.next(response);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode;
          if (status == 429) {
            onRateLimited(retryAfterFrom(error.response?.headers));
          }
          handler.next(error);
        },
      );

  /// Extrait la durée d'attente annoncée par le panel.
  ///
  /// `Retry-After` peut être un nombre de SECONDES ou une date HTTP
  /// (IMF-fixdate, ex. « Tue, 15 Nov 1994 12:45:26 GMT ») ; les deux sont
  /// acceptés. `X-RateLimit-Reset` est un epoch en secondes.
  ///
  /// Le format de date est parsé via [HttpDate] : `DateTime.parse` le refuse,
  /// ce qui faisait silencieusement retomber sur `null`.
  static Duration? retryAfterFrom(Headers? headers) {
    if (headers == null || headers.isEmpty) return null;

    final retryAfter = _firstHeader(headers, const [
      'retry-after',
      'Retry-After',
    ]);
    if (retryAfter != null) {
      final seconds =
          int.tryParse(retryAfter) ?? double.tryParse(retryAfter)?.round();
      if (seconds != null && seconds > 0) return Duration(seconds: seconds);

      final date = _parseHttpDate(retryAfter);
      if (date != null) {
        final delta = date.difference(DateTime.now());
        return delta.isNegative ? Duration.zero : delta;
      }
    }

    final reset = _firstHeader(headers, const [
      'x-ratelimit-reset',
      'X-RateLimit-Reset',
      'ratelimit-reset',
      'RateLimit-Reset',
    ]);
    if (reset != null) {
      final epochSeconds = int.tryParse(reset);
      if (epochSeconds != null && epochSeconds > 0) {
        final at = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
        final delta = at.difference(DateTime.now());
        return delta.isNegative ? Duration.zero : delta;
      }
    }

    return null;
  }

  /// Parse une date HTTP (IMF-fixdate) sans dépendre de `DateTime.parse`.
  ///
  /// Trois formats sont admis : IMF-fixdate, RFC 850 et asctime.
  static DateTime? _parseHttpDate(String raw) {
    try {
      return HttpDate.parse(raw);
    } on Object {
      // On tente les deux variantes historiques.
    }
    try {
      final rfc850 = DateTime.tryParse(_rfc850ToIso(raw));
      if (rfc850 != null) return rfc850;
    } on Object {
      // ignoré
    }
    return DateTime.tryParse(raw);
  }

  static String _rfc850ToIso(String raw) {
    // « Sunday, 06-Nov-94 08:49:37 GMT » → « 1994-11-06 08:49:37 »
    final m = RegExp(
      r'(\d{2})-([A-Za-z]{3})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(raw);
    if (m == null) return raw;
    const months = {
      'Jan': '01',
      'Feb': '02',
      'Mar': '03',
      'Apr': '04',
      'May': '05',
      'Jun': '06',
      'Jul': '07',
      'Aug': '08',
      'Sep': '09',
      'Oct': '10',
      'Nov': '11',
      'Dec': '12',
    };
    final mon = months[m.group(2)!] ?? '01';
    final year = int.parse(m.group(3)!);
    final fullYear = year < 70 ? 2000 + year : 1900 + year;
    return '${fullYear.toString().padLeft(4, '0')}-$mon-${m.group(1)} '
        '${m.group(4)}:${m.group(5)}:${m.group(6)}';
  }

  static String? _firstHeader(Headers headers, List<String> keys) {
    for (final key in keys) {
      final value = headers.value(key)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
