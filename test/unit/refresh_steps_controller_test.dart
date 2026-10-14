import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';

/// Verrouille la mécanique de progression partagée par l'écran de démarrage et
/// l'écran de mise à jour (4 icônes + barre).
///
/// Le point critique : une étape est marquée « faite » MÊME en cas d'échec (un
/// 429 du panel ne doit pas laisser la barre bloquée), et la progression est
/// pondérée par `kRefreshStepWeights`.
void main() {
  group('RefreshStepsController — progression', () {
    test('état initial : 0 %, aucune étape faite, non terminé', () {
      final c = RefreshStepsController(
        steps: const {StartupStep.live, StartupStep.movies},
      );
      addTearDown(c.dispose);

      expect(c.progress, 0.0);
      expect(c.percent, 0);
      expect(c.doneSteps, isEmpty);
      expect(c.isFinished, isFalse);
      expect(c.currentStep, isNull);
    });

    test('toutes les étapes réussies → 100 % et terminé', () async {
      final c = RefreshStepsController(
        steps: const {StartupStep.live, StartupStep.movies},
      );
      addTearDown(c.dispose);

      await c.run((_) async {}, gap: Duration.zero);

      expect(c.doneSteps,
          containsAll(const {StartupStep.live, StartupStep.movies}),);
      expect(c.progress, 1.0);
      expect(c.percent, 100);
      expect(c.isFinished, isTrue);
      expect(c.currentStep, isNull);
    });

    test('une étape en échec est tout de même marquée faite', () async {
      final c = RefreshStepsController(
        steps: const {StartupStep.live, StartupStep.movies},
      );
      addTearDown(c.dispose);

      await c.run(
        (step) async {
          if (step == StartupStep.live) throw Exception('429 panel');
        },
        gap: Duration.zero,
      );

      expect(c.doneSteps, contains(StartupStep.live));
      expect(c.doneSteps, contains(StartupStep.movies));
      expect(c.isFinished, isTrue);
      expect(c.error, isNotNull);
    });

    test('la progression est pondérée par kRefreshStepWeights', () async {
      // live=0.22, movies=0.22 → total 0.44. Après « live », 50 %.
      final c = RefreshStepsController(
        steps: const {StartupStep.live, StartupStep.movies},
      );
      addTearDown(c.dispose);

      final seen = <double>[];
      c.addListener(() => seen.add(c.progress));

      await c.run((_) async {}, gap: Duration.zero);

      // Le contrôleur notifie aussi au DÉBUT de chaque étape (0 %), puis après
      // son achèvement : on doit voir le palier 50 % puis 100 %.
      expect(seen.first, 0.0);
      expect(seen, contains(closeTo(0.5, 1e-9)));
      expect(seen.last, closeTo(1.0, 1e-9));
    });

    test('échec de l\'EPG → skippedEpg vrai, sans bloquer', () async {
      final c = RefreshStepsController(
        steps: const {StartupStep.epg},
      );
      addTearDown(c.dispose);

      await c.run(
        (_) async => throw Exception('EPG indisponible'),
        gap: Duration.zero,
      );

      expect(c.skippedEpg, isTrue);
      expect(c.isFinished, isTrue);
    });

    test('run n\'est pas ré-entrant (started)', () async {
      final c = RefreshStepsController(
        steps: const {StartupStep.live},
      );
      addTearDown(c.dispose);

      var calls = 0;
      await c.run((_) async => calls++, gap: Duration.zero);
      await c.run((_) async => calls++, gap: Duration.zero);

      expect(calls, 1);
    });

    test('liste d\'étapes vide → 100 % immédiat', () async {
      final c = RefreshStepsController(steps: const {});
      addTearDown(c.dispose);

      expect(c.progress, 1.0);
      expect(c.percent, 100);
    });
  });
}
