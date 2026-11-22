import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/device_info.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';

/// Le [SafeArea] réellement construit par [TvSafeArea] : c'est lui qui porte
/// l'overscan, donc la seule valeur à vérifier.
SafeArea _safeAreaOf(WidgetTester tester) => tester.widget<SafeArea>(
      find.descendant(
        of: find.byType(TvSafeArea),
        matching: find.byType(SafeArea),
      ),
    );

Future<void> _pumpTvSafeArea(
  WidgetTester tester, {
  bool enableTvMode = false,
  DeviceDetectionResult? detection,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final controller = container.read(tvModeControllerProvider);
  if (detection != null) {
    await controller.updateFromDetection(detection);
  }
  if (enableTvMode) {
    controller.enable();
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: TvSafeArea(child: Text('Content')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'un appareil non-TV ne recoit AUCUN overscan, meme si le mode TV a ete active',
      (tester) async {
    // Réplique le cas terrain : sur un téléphone tactile, une touche (Entrée du
    // clavier virtuel, Retour système) active le mode TV alors qu'aucune TV
    // n'a été détectée. Avant correctif, l'overscan de 48/27 dp s'appliquait
    // et encadrait toute l'application (96 dp de largeur perdus, plus de
    // disposition « 2 grilles »).
    await _pumpTvSafeArea(tester, enableTvMode: true);

    expect(
      _safeAreaOf(tester).minimum,
      EdgeInsets.zero,
      reason: "l'overscan est une contrainte de dalle de télévision et ne doit "
          'jamais rogner un écran tactile',
    );
  });

  testWidgets('une TV ecartee par la detection ne recoit pas d overscan',
      (tester) async {
    await _pumpTvSafeArea(
      tester,
      enableTvMode: true,
      detection: const DeviceDetectionResult(
        deviceType: DeviceType.phone,
        isTv: false,
        confidence: 0.9,
      ),
    );

    expect(_safeAreaOf(tester).minimum, EdgeInsets.zero);
  });

  testWidgets('une TV reellement detectee recoit bien l overscan',
      (tester) async {
    await _pumpTvSafeArea(
      tester,
      enableTvMode: true,
      detection: const DeviceDetectionResult(
        deviceType: DeviceType.tv,
        isTv: true,
        confidence: 0.9,
      ),
    );

    expect(_safeAreaOf(tester).minimum, tvOverscanInsets);
  });

  testWidgets('sans mode TV, aucune marge', (tester) async {
    await _pumpTvSafeArea(tester);

    expect(_safeAreaOf(tester).minimum, EdgeInsets.zero);
  });
}
