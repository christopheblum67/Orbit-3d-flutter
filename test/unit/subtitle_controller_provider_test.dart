import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';

/// L'overlay du lecteur ne s'abonne QU'À `subtitleControllerProvider` : il ne
/// possède aucun `setState`. Sa seule chance de se reconstruire quand un
/// nouveau groupe de cues arrive (polling 300 ms du pipeline natif media3) est
/// donc que `ref.watch` — et l'équivalent `ProviderContainer.listen` — soit
/// RÉVEILLÉ par `notifyListeners`.
///
/// C'est exactement ce qu'un `Provider<SubtitleController>` nu ne fait pas : il
/// renvoie bien l'instance, mais ne s'abonne jamais au `Listenable`.
/// Conséquence constatée sur le S20 : cues publiés côté natif (`onCues n=1`),
/// cues renvoyés par `getCurrentCues()` (`raw=1 text=1`), cues reçus côté Dart
/// (`1re cue reçue`), et **rien à l'écran** — la chaîne s'arrêtait au
/// `notifyListeners`, sans abonné.
///
/// Ce test verrouille la propriété : il échoue si quelqu'un « simplifie » le
/// provider en `Provider` nu. Voir docs/engineering-playbook.md, leçon L15.
void main() {
  ProviderContainer newContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('réveille ses dépendants quand le contrôleur notifie', () {
    final container = newContainer();
    var notifications = 0;
    final subscription = container.listen(
      subtitleControllerProvider,
      (_, __) => notifications++,
    );
    addTearDown(subscription.close);

    // Une action utilisateur banale : « Aucun » sous-titres.
    container.read(subtitleControllerProvider).disable();

    expect(
      notifications,
      greaterThan(0),
      reason: 'avec un Provider nu, notifications resterait à 0 : '
          "l'overlay ne se reconstruirait JAMAIS pendant la lecture, "
          'quel que soit le nombre de cues publiés',
    );
  });

  test('même instance pour tous les lecteurs (état partagé à l\'échelle app)',
      () {
    final container = newContainer();

    expect(
      identical(
        container.read(subtitleControllerProvider),
        container.read(subtitleControllerProvider),
      ),
      isTrue,
      reason: 'l\'overlay, la feuille « Détails du flux » et le panneau '
          'doivent parler du MÊME contrôleur',
    );
  });

  test('le notifier exposé est bien un SubtitleController', () {
    final container = newContainer();
    expect(
      container.read(subtitleControllerProvider),
      isA<SubtitleController>(),
    );
  });
}
