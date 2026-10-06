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

  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;

  DateTime? _lastStart;
  DateTime? _cooldownUntil;
  int _throttled = 0;
  int _cooldowns = 0;

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
    final until = now.add(retryAfter ?? defaultCooldown);
    // Un panel qui réclame PLUS de carence qu'on n'en a déjà ne doit pas être
    // contrarié : on retient toujours la plus longue des deux.
    if (_cooldownUntil == null || until.isAfter(_cooldownUntil!)) {
      _cooldownUntil = until;
    }
    _cooldowns++;
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
