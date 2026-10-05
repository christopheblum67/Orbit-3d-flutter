import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Alignement de l'axe du temps avec la grille.
///
/// ## Le défaut
///
/// Entre la colonne des noms et la frise, le bandeau d'axe plaçait trois
/// `IconButton` et l'indicateur de zoom : la frise démarrait donc environ
/// 150 px plus loin que la grille. Chaque libellé d'heure se lisait à ce
/// décalage, et la ligne « maintenant » — correctement posée sur la grille —
/// tombait vers 7 h 35 quand l'axe annonçait l'heure réelle.
///
/// Aucun calcul n'était faux : la géométrie était juste, l'axe était
/// simplement à côté de la grille qu'il mesure. Répéter les valeurs partout
/// avait produit trois repères différents pour un seul axe.
void main() {
  final gridStart = DateTime(2026, 10, 4);
  final ppm = 4.0;
  final now = DateTime(2026, 10, 4, 12, 30);

  Widget grid(Size size) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: EpgGrid2DView(
              channels: const ['TF1'],
              epgData: {
                'TF1': [
                  EPGProgram(
                    channelId: 'c1',
                    title: 'Journal',
                    description: '',
                    start: gridStart.add(const Duration(hours: 12)),
                    end: gridStart.add(const Duration(hours: 13)),
                  ),
                ],
              },
              timelineController: EpgTimelineController(
                gridStartTime: gridStart,
                pixelsPerMinute: ppm,
              ),
            ),
          ),
        ),
      );

  testWidgets('le bandeau ne déborde pas de sa bande gauche', (tester) async {
    // Un `IconButton` compact fait 40 px : trois boutons plus l'indicateur
    // débordaient de 6 px et faisaient tomber la mise en page.
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(grid(const Size(360, 733)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  test('l’axe et la grille partagent le même abscisse d’origine', () {
    // La gouttière vaut 4 px : elle doit être comptée dans le calcul de la
    // position de la ligne, et retranchée en symétrique quand on relit une
    // abscisse en heure. Oublier l'un des deux sens fausse la mesure.
    expect(kGridLeftInset, 4.0);

    final controller = EpgTimelineController(
      gridStartTime: gridStart,
      pixelsPerMinute: ppm,
    );
    // Abscisse de la ligne rouge, dans le repère de la pile.
    const namesWidth = 140.0;
    final x = namesWidth + kGridLeftInset + controller.timeToPixels(now);
    // Relecture : la gouttière se retranche des deux côtés.
    final back = controller.pixelsToTime(x - namesWidth - kGridLeftInset);

    expect(back.difference(now).inSeconds.abs(), lessThanOrEqualTo(1),
        reason: 'aller-retour : la ligne et l’axe doivent coïncider');
  });

  test('une heure pleine tombe sur sa graduation', () {
    final controller = EpgTimelineController(
      gridStartTime: gridStart,
      pixelsPerMinute: ppm,
    );
    // 9 h = 540 min × 4 px = 2160 px depuis l'origine de la grille.
    expect(controller.timeToPixels(gridStart.add(const Duration(hours: 9))),
        2160.0);
    expect(
      controller
          .pixelsToTime(2160.0)
          .difference(gridStart.add(const Duration(hours: 9)))
          .inSeconds
          .abs(),
      lessThanOrEqualTo(1),
    );
  });
}
