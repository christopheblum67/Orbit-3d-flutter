import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/widgets/performance_hud.dart';

class _Controller extends RefreshStepsController {
  _Controller() : super(steps: {});

  StartupStep? step;
  int value = 0;
  bool finished = false;

  @override
  StartupStep? get currentStep => step;
  @override
  int get percent => value;
  @override
  bool get isFinished => finished;

  void update(StartupStep? next, {int percent = 0, bool done = false}) {
    step = next;
    value = percent;
    finished = done;
    notifyListeners();
  }
}

Widget _app(_Controller controller, {bool enabled = true}) => MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            PerformanceHud(controller: controller, enabled: enabled),
          ],
        ),
      ),
    );

void main() {
  testWidgets('affiche la progression réelle et conserve les étapes rapides',
      (tester) async {
    final controller = _Controller();
    await tester.pumpWidget(_app(controller));
    expect(find.text('En attente...'), findsOneWidget);
    expect(
      find.text('Réseau et cache : données indisponibles'),
      findsOneWidget,
    );

    controller.update(StartupStep.live);
    controller.update(StartupStep.movies, percent: 40);
    await tester.pump();
    expect(find.text('Chaînes live'), findsOneWidget);
    expect(find.text('Films & VOD'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      0.4,
    );

    controller.update(null, percent: 100, done: true);
    await tester.pump();
    expect(find.text('Performance HUD'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('change de contrôleur et respecte enabled', (tester) async {
    final first = _Controller();
    final second = _Controller();
    first.update(StartupStep.live);
    second.update(StartupStep.series, percent: 25);
    await tester.pumpWidget(_app(first));
    await tester.pumpWidget(_app(second));
    first.update(StartupStep.movies);
    await tester.pump();
    expect(find.text('Séries'), findsOneWidget);
    expect(find.text('Films & VOD'), findsNothing);
    expect(find.text('Chaînes live'), findsNothing);
    await tester.pumpWidget(_app(second, enabled: false));
    expect(find.text('Performance HUD'), findsNothing);
    second.update(StartupStep.radio, percent: 50);
    await tester.pumpWidget(_app(second));
    expect(find.text('Radios'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    first.dispose();
    second.dispose();
  });
}
