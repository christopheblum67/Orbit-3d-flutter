import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_rate_limiter.dart';

/// Limiteur de débit API.
///
/// Ces tests utilisent une horloge et un `sleep` injectés : aucune attente
/// réelle, donc la suite reste rapide, et les délais demandés sont vérifiés
/// exactement.
void main() {
  /// Horloge manuelle avancée par le `sleep` simulé.
  late DateTime now;
  late List<Duration> slept;
  late ApiRateLimiter limiter;

  ApiRateLimiter build({
    Duration minInterval = const Duration(milliseconds: 250),
    Duration defaultCooldown = const Duration(seconds: 10),
  }) {
    return ApiRateLimiter(
      minInterval: minInterval,
      defaultCooldown: defaultCooldown,
      clock: () => now,
      sleep: (d) async {
        slept.add(d);
        now = now.add(d);
      },
    );
  }

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    slept = <Duration>[];
    limiter = build();
  });

  group('espacement', () {
    test('la première requête ne waits pas', () async {
      await limiter.beforeRequest();
      expect(slept, isEmpty);
      expect(limiter.throttledRequests, 0);
    });

    test('deux requêtes consécutives sont espacées de minInterval', () async {
      await limiter.beforeRequest();
      await limiter.beforeRequest();
      expect(slept, [const Duration(milliseconds: 250)]);
    });

    test('trois requêtes : trois départs espacés de minInterval', () async {
      // L'horloge avance avec les `sleep` simulés. Chaque requête part
      // minInterval après la précédente, donc chaque appel attend : c'est
      // exactement ce que borne la fréquence.
      await limiter.beforeRequest();
      await limiter.beforeRequest();
      await limiter.beforeRequest();
      expect(slept, [
        const Duration(milliseconds: 250),
        const Duration(milliseconds: 250),
      ]);
      expect(limiter.throttledRequests, 2);
    });

    test('après un délai suffisant, plus rien à attendre', () async {
      await limiter.beforeRequest();
      // Le temps passe (ex. chargement d'un gros JSON).
      now = now.add(const Duration(seconds: 5));
      slept.clear();
      await limiter.beforeRequest();
      expect(slept, isEmpty);
    });

    test('un minInterval nul n\'introduit aucune attente', () async {
      final zero = build(minInterval: Duration.zero);
      await zero.beforeRequest();
      await zero.beforeRequest();
      await zero.beforeRequest();
      expect(slept, isEmpty);
    });
  });

  group('carence sur 429', () {
    test('après un 429, la requête suivante attend la carence', () async {
      limiter.onRateLimited(null);
      expect(limiter.cooldownCount, 1);
      expect(limiter.isCoolingDown, isTrue);

      await limiter.beforeRequest();
      expect(slept, [const Duration(seconds: 10)]);
    });

    test('la carence est la plus longue des deux bornes', () async {
      await limiter.beforeRequest(); // ancre le départ
      // Un 429 tardif doit IMPOSER son attente, pas se faire rogner.
      now = now.add(const Duration(seconds: 3));
      limiter.onRateLimited(const Duration(seconds: 5));

      slept.clear();
      await limiter.beforeRequest();
      expect(
        slept,
        [const Duration(seconds: 5)],
        reason: 'depuis maintenant, la carence (5 s) domine l\'espacement',
      );
    });

    test('deux 429successifs ne réduisent pas la carence', () async {
      limiter.onRateLimited(const Duration(seconds: 20));
      now = now.add(const Duration(seconds: 1));
      limiter.onRateLimited(const Duration(seconds: 2));
      expect(limiter.cooldownUntil!.difference(now).inSeconds, 19,
          reason: 'la carence la plus longue doit rester la référence');
    });

    test('une fois la carence écoulée, on repart normalement', () async {
      limiter.onRateLimited(const Duration(seconds: 5));
      await limiter.beforeRequest();
      expect(limiter.isCoolingDown, isFalse);

      // La carence est passée, mais l'espacement minimal subsiste : on ne
      // revient pas à une rafale.
      slept.clear();
      await limiter.beforeRequest();
      expect(slept, [const Duration(milliseconds: 250)]);
    });

    test('reset efface la carence', () {
      limiter.onRateLimited(const Duration(seconds: 30));
      expect(limiter.isCoolingDown, isTrue);
      limiter.reset();
      expect(limiter.isCoolingDown, isFalse);
      expect(limiter.cooldownCount, 0);
    });

    test('la carence CROIT tant que le panel refuse', () {
      // Un quota de panel se réinitialise sur une fenêtre de temps. Insister
      // toutes les 10 s ne fait que maintenir la limitation — c'était
      // exactement le cycle observé sur le S20.
      //
      // Chaque refus repart d'une horloge fraîche : on mesure ainsi la carence
      // demandée par le N-ième refus, sans être pollué par la précédente.
      Duration carenceDemandee(int refus) {
        final b = build();
        Duration? demandee;
        for (var i = 0; i < refus; i++) {
          now = DateTime(2026, 1, 1, 12);
          b.onRateLimited(null);
          demandee = b.cooldownUntil!.difference(now);
        }
        return demandee!;
      }

      expect(carenceDemandee(1), const Duration(seconds: 10));
      expect(carenceDemandee(2), const Duration(seconds: 30));
      // Le 3e refus demanderait 90 s : le plafond de 60 s s'applique.
      expect(carenceDemandee(3), const Duration(minutes: 1));
    });

    test('la carence est plafonnée à une minute', () {
      // Constat mesuré : avec 5 min de plafond, la file de requêtes restait
      // suspendue et le changement d'abonnement restait à 0 % sans qu'aucune
      // requête ne parte. Un plafond plus haut rend l'application
      // indiscernable d'un plantage.
      final b = build(defaultCooldown: const Duration(seconds: 10));
      for (var i = 0; i < 12; i++) {
        now = DateTime(2026, 1, 1, 12);
        b.onRateLimited(null);
      }
      expect(
        b.cooldownUntil!.difference(now),
        const Duration(minutes: 1),
        reason: 'au-delà, il faut tout de même réessayer',
      );
    });

    test('un nouveau panneau repart sans carence', () async {
      // Le quota du nouveau compte n'a rien à voir avec celui qui vient de
      // refuser : conserver la carence le bloquait aussi.
      limiter.onRateLimited(null);
      limiter.onRateLimited(null);
      limiter.onRateLimited(null);
      expect(limiter.isCoolingDown, isTrue);

      limiter.onNewTarget();

      expect(limiter.isCoolingDown, isFalse);
      expect(limiter.consecutiveRateLimits, 0);
      // L'espacement minimal reste : la cadence demeure polie.
      await limiter.beforeRequest();
      expect(limiter.throttledRequests, 0,
          reason: 'après reset, la première requête ne doit pas attendre');
    });

    test('un succès annule la croissance', () {
      limiter.onRateLimited(null);
      limiter.onRateLimited(null);
      expect(limiter.consecutiveRateLimits, 2);

      limiter.onSuccess();
      expect(limiter.consecutiveRateLimits, 0);

      // Le refus suivant repart de la carence de BASE. Il faut laisser
      // expirer la carence précédente, sinon c'est elle, plus longue, qui est
      // retenue — comportement voulu par ailleurs.
      now = now.add(const Duration(minutes: 10));
      limiter.onRateLimited(null);
      expect(
        limiter.cooldownUntil!.difference(now),
        const Duration(seconds: 10),
      );
    });
  });

  group('lecture des en-têtes', () {
    test('Retry-After en secondes', () {
      final h = Headers.fromMap({
        'retry-after': ['30']
      });
      expect(ApiRateLimiter.retryAfterFrom(h), const Duration(seconds: 30));
    });

    test('Retry-After en date HTTP', () {
      // Format IMF-fixdate : « Tue, 15 Nov 1994 12:45:26 GMT ».
      final future = DateTime.now().toUtc().add(const Duration(seconds: 42));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      String two(int v) => v.toString().padLeft(2, '0');
      final date = '${days[future.weekday - 1]}, ${two(future.day)} '
          '${months[future.month - 1]} ${future.year} '
          '${two(future.hour)}:${two(future.minute)}:${two(future.second)} GMT';

      final h = Headers.fromMap({
        'retry-after': [date],
      });
      final d = ApiRateLimiter.retryAfterFrom(h);
      expect(d, isNotNull);
      expect(d!.inSeconds, closeTo(42, 3));
    });

    test('X-RateLimit-Reset en epoch', () {
      final epoch = DateTime.now()
              .add(const Duration(seconds: 60))
              .millisecondsSinceEpoch ~/
          1000;
      final h = Headers.fromMap({
        'x-ratelimit-reset': ['$epoch']
      });
      final d = ApiRateLimiter.retryAfterFrom(h);
      expect(d, isNotNull);
      expect(d!.inSeconds, closeTo(60, 3));
    });

    test('en-têtes absants ou illisibles → null', () {
      expect(ApiRateLimiter.retryAfterFrom(null), isNull);
      expect(ApiRateLimiter.retryAfterFrom(Headers.fromMap({})), isNull);
      expect(
        ApiRateLimiter.retryAfterFrom(Headers.fromMap({
          'retry-after': ['brol']
        })),
        isNull,
      );
    });
  });

  group('intercepteur Dio', () {
    test('applique l\'espacement puis relaîche la requête', () async {
      final dio = Dio();
      dio.interceptors.add(limiter.interceptor);

      final seen = <DateTime>[];
      // Un adaptateur qui note l'heure de départ de chaque requête au lieu
      // d'aller sur le réseau.
      dio.httpClientAdapter = _RecordingAdapter(seen);

      await dio.get<void>('http://panel.test/a',
          options: Options(responseType: ResponseType.bytes));
      await dio.get<void>('http://panel.test/b',
          options: Options(responseType: ResponseType.bytes));

      expect(seen, hasLength(2));
      // On n'assert PAS l'écart mural : le `sleep` est simulé par `setUp`
      // (horloge injectée), donc le temps réel ne s'écoule pas. Ce qui est
      // observable et garanti, c'est que la 2e requête A ÉTÉ retenue.
      expect(
        limiter.throttledRequests,
        1,
        reason: 'la 2e requête doit avoir été retardée par minInterval',
      );
      expect(slept, [const Duration(milliseconds: 250)]);
    });

    test('un 429 reçu par l\'intercepteur arme la carence', () async {
      final dio = Dio();
      dio.interceptors.add(limiter.interceptor);
      dio.httpClientAdapter = _RecordingAdapter(<DateTime>[], status: 429);

      // Le 429 remonte en exception : on l'absorbe, c'est la carence qui
      // intéresse le test.
      try {
        await dio.get<void>('http://panel.test/a',
            options: Options(responseType: ResponseType.bytes));
        fail('un 429 doit remonter en erreur');
      } on DioException {
        // attendu
      }

      expect(limiter.cooldownCount, 1);
      expect(limiter.isCoolingDown, isTrue,
          reason: 'après un refus explicite, la suite doit se taire');
    });

    test('un 200 n\'arme aucune carence', () async {
      final dio = Dio();
      dio.interceptors.add(limiter.interceptor);
      dio.httpClientAdapter = _RecordingAdapter(<DateTime>[], status: 200);

      await dio.get<void>('http://panel.test/a',
          options: Options(responseType: ResponseType.bytes));
      expect(limiter.cooldownCount, 0);
    });
  });
}

/// Exception interne : sert à absorbing l'erreur attendue d'un 429.
class _Ok implements Exception {
  const _Ok();
}

/// Adaptateur Dio qui enregistre l'heure de départ et répond statut fixé.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.starts, {this.status = 200});

  final List<DateTime> starts;
  final int status;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    starts.add(DateTime.now());
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);
    return ResponseBody.fromBytes(
      bytes,
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}
