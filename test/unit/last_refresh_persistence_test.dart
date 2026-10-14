import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Conteneur Riverpod isolé : chaque test repart d'un état propre.
ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

/// Persistance de l'horodatage « À jour depuis X ».
///
/// Défaut corrigé : `persistLastRefresh` et `loadLastRefresh` existaient, mais
/// **aucun appelant** n'écrivait la valeur. Le widget affichait donc
/// « Jamais mis à jour » après chaque redémarrage, jusqu'à ce qu'un
/// rafraîchissement manuel soit déclenché. La persistance est donc testée à
/// travers le notifier, comme c'est le seul chemin que l'application utilise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('lastRefreshTimestampProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('setTimestamp écrit dans les préférences', () async {
      final container = _container();
      final when = DateTime(2026, 3, 14, 15, 9, 26);

      container.read(lastRefreshTimestampProvider.notifier).setTimestamp(when);

      // L'écriture est `unawaited` : il faut laisser le microtask passer.
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('orbit_last_refresh');
      expect(raw, isNotNull,
          reason: 'sans écriture, le widget affiche « Jamais mis à jour » '
              'après chaque redémarrage',);
      expect(DateTime.parse(raw!), when);
    });

    test('la valeur relue est identique, fuseau compris', () async {
      final container = _container();
      final when = DateTime(2026, 3, 14, 15, 9, 26);

      container.read(lastRefreshTimestampProvider.notifier).setTimestamp(when);
      await Future<void>.delayed(Duration.zero);

      final reloaded = await loadLastRefresh();
      expect(reloaded, isNotNull);
      // Heure locale : le libellé raisonne en heures de la montre, un décalage
      // de fuseau afficherait « mis à jour il y a -1 h ».
      expect(reloaded!.isUtc, isFalse);
      expect(reloaded.difference(when), Duration.zero);
      expect(reloaded.isAtSameMomentAs(when), isTrue);
    });

    test('un timestamp nul efface l\'affichage sans écrire', () async {
      final container = _container();
      container
          .read(lastRefreshTimestampProvider.notifier)
          .setTimestamp(DateTime(2026, 1, 1));
      await Future<void>.delayed(Duration.zero);

      container.read(lastRefreshTimestampProvider.notifier).setTimestamp(null);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(lastRefreshTimestampProvider), isNull);
    });

    test('loadLastRefresh tolère une valeur absente ou illisible', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await loadLastRefresh(), isNull);

      SharedPreferences.setMockInitialValues(
        <String, Object>{'orbit_last_refresh': 'pas-une-date'},
      );
      expect(await loadLastRefresh(), isNull,
          reason: 'une préférence corrompue ne doit pas casser le lancement',);
    });
  });
}
