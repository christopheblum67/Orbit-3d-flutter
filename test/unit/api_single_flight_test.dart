import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Regroupement des requêtes identiques (« single flight »).
///
/// Mesuré au logcat lors d'un changement d'abonnement :
///
/// ```
/// 10:29:03.690 GET get_live_categories
/// 10:29:03.691 GET autre
/// 10:29:03.691 GET get_live_categories      <- doublon
/// 10:29:04.107 GET get_live_streams
/// 10:29:04.107 GET get_live_streams         <- doublon
/// ```
///
/// `fetchLiveChannels` est appelée par quatre points indépendants, et chaque
/// appel déclenchait son propre couple `get_live_categories` +
/// `get_live_streams`. Sur un panel qui limite les requêtes, un doublon est une
/// unité de quota brûlée pour rien : c'est ce qui divisait le budget réel par
/// deux.
///
/// Le test porte sur le MÉCANISME, pas sur `fetchLiveChannels` : sans
/// abonnement actif le corps échoue avant toute requête, donc compter les
/// exécutions y serait impossible. Or « une seule exécution pour N appelants
/// » est précisément la garantie à prouver.
void main() {
  late ApiService api;

  setUp(() => api = ApiService());

  group('single flight', () {
    test('N appelants concurrents = UNE seule exécution', () async {
      var executions = 0;
      final gate = Completer<int>();

      Future<int> body() {
        executions++;
        return gate.future;
      }

      final results = [
        api.singleFlightForTest('k', body),
        api.singleFlightForTest('k', body),
        api.singleFlightForTest('k', body),
        api.singleFlightForTest('k', body),
      ];

      expect(executions, 1,
          reason: 'le corps ne doit tourner qu\'une fois, quel que soit le '
              'nombre d\'appelants concurrents',);
      expect(api.inFlightCount, 1);

      gate.complete(42);
      expect(await Future.wait(results), [42, 42, 42, 42],
          reason: 'tous les appelants doivent recevoir le même résultat',);
      expect(executions, 1);
      expect(api.inFlightCount, 0);
    });

    test('après achèvement, le regroupement ne fige pas le résultat', () async {
      var executions = 0;
      Future<int> body() async {
        executions++;
        return executions;
      }

      expect(await api.singleFlightForTest<int>('k', body), 1);
      // Un appel ultérieur doit bien refaire le travail : c'est le défaut
      // classique d'un cache mal branché, qui renverrait 1 pour toujours.
      expect(await api.singleFlightForTest<int>('k', body), 2);
      expect(executions, 2);
    });

    test('un échec n\'empoisonne pas les tentatives suivantes', () async {
      var attempts = 0;
      Future<int> failing() {
        attempts++;
        throw StateError('panne réseau');
      }

      await expectLater(
        api.singleFlightForTest('k', failing),
        throwsA(isA<StateError>()),
      );
      expect(api.inFlightCount, 0,
          reason: 'un vol raté laissé en cache ferait échouer tous les '
              'appels suivants, définitivement',);

      // L'appel suivant repart à zéro.
      await expectLater(
        api.singleFlightForTest('k', failing),
        throwsA(isA<StateError>()),
      );
      expect(attempts, 2);
    });

    test('les clés distinctes ne se confondent pas', () async {
      final gate = Completer<void>();
      api.singleFlightForTest('live', () => gate.future);
      api.singleFlightForTest('vod', () => gate.future);
      api.singleFlightForTest('series', () => gate.future);

      expect(api.inFlightCount, 3,
          reason: 'Films, Séries et Live sont trois endpoints différents : '
              'les regrouper ensemble renverrait le mauvais contenu',);
      gate.complete();
    });

    test('deux appels séquentiels ne partagent rien', () async {
      final first = await api.singleFlightForTest<int>('k', () async => 1);
      final second = await api.singleFlightForTest<int>('k', () async => 2);
      expect(first, 1);
      expect(second, 2);
    });
  });
}
