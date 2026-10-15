import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart' as gap;

/// Raccourci de test : le comblement de trous avec les paramètres usuels.
List<EPGProgram> fillForTest({
  required List<EPGProgram> programs,
  required DateTime start,
  required DateTime end,
}) =>
    gap.EpgGapFiller.fill(
        programs: programs, windowStart: start, windowEnd: end,);

/// Programme d'une heure, dans la fenêtre de la journée.
EPGProgram prog(String title, int startHour) {
  final day = DateTime.now();
  final start = DateTime(day.year, day.month, day.day, startHour);
  return EPGProgram(
    channelId: 'c1',
    title: title,
    description: '',
    start: start,
    end: start.add(const Duration(hours: 1)),
  );
}

/// Enveloppe la grille dans une surface contrainte, pour reproduire la mise en
/// page réelle (le `Expanded` de l'écran).
Widget harness(List<String> channels, Map<String, List<EPGProgram>> data) {
  return MaterialApp(
    // Les delegates sont nécessaires : la grille lit ses libellés via
    // `AppLocalizations.of(context)`, qui renvoie null sans eux. Un test sans
    // delegates échouerait alors même que l'écran, lui, fonctionne.
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          height: 700,
          child: EpgGrid2DView(channels: channels, epgData: data),
        ),
      ),
    ),
  );
}

void main() {
  group('EpgGrid2DView — les données chargées après coup sont visibles', () {
    testWidgets('une grille montée vide se remplit quand les données arrivent',
        (tester) async {
      // Régression du défaut le plus coûteux de la grille : le programme était
      // bien chargé (589 chaînes tracées) mais rien ne s'affichait.
      //
      // Cause : un `ListView.builder` ne rappelle `itemBuilder` que s'il
      // RECYCLE une ligne. Les lignes déjà affichées gardaient le painter
      // construit au premier rendu, avec un cache de rendu vide. Seule une
      // révision de données, écoutée via `repaint`, les fait repeindre.
      final channels = ['TF1 HD', 'FRANCE 2 HD'];

      await tester.pumpWidget(harness(channels, const {}));
      await tester.pump();
      expect(
        find.byType(EpgGrid2DView),
        findsOneWidget,
        reason: 'la grille doit se monter même sans aucune donnée',
      );

      final before = tester
          .state<EpgGrid2DViewState>(find.byType(EpgGrid2DView))
          .debugDataRevision;

      // Les données arrivent après coup, comme le fait le chargement EPG.
      await tester.pumpWidget(
        harness(channels, {
          'TF1 HD': [prog('LE JT', 10)],
          'FRANCE 2 HD': [prog('LE 19H', 19)],
        }),
      );
      await tester.pump();

      // C'est l'assertion qui compte : la révision doit avoir changé, sinon
      // aucune ligne déjà affichée ne se repeint et la grille reste vide.
      final after = tester
          .state<EpgGrid2DViewState>(find.byType(EpgGrid2DView))
          .debugDataRevision;
      expect(
        after,
        greaterThan(before),
        reason: 'les painters déjà construits doivent être prévenus du '
            'changement de données, sans quoi aucun bloc n\'apparaît',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('les programmes aboutissent réellement au painter',
        (tester) async {
      // Vérifier que la révision change ne suffit PAS : le défaut historique
      // était précisément un cache handed au painter vide alors que la
      // révision avait bien bougé. Ce test ferme la boucle.
      final channels = ['TF1 HD', 'FRANCE 2 HD', 'M6'];
      await tester.pumpWidget(harness(channels, const {}));
      await tester.pump();

      final state =
          tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView));

      await tester.pumpWidget(harness(channels, {
        'TF1 HD': [prog('LE JT', 10), prog('LE 19H', 19)],
        'FRANCE 2 HD': [prog('LE 13H', 13)],
        // M6 reste vide : elle doit remonter comme « sans programme ».
      }),);
      await tester.pump();

      expect(state.debugProgramCount('TF1 HD'), 2);
      expect(state.debugProgramCount('FRANCE 2 HD'), 1);
      expect(state.debugProgramCount('M6'), 0);
      expect(
        state.debugChannelsWithoutPrograms,
        ['M6'],
        reason: 'une chaîne sans donnée doit être identifiable, sinon une '
            'grille entièrement vide passe pour une grille pleine de trous',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('des données identiques ne déclenchent pas de repeint inutile',
        (tester) async {
      await tester.pumpWidget(
        harness([
          'TF1 HD',
        ], {
          'TF1 HD': [prog('LE JT', 10)],
        }),
      );
      await tester.pump();
      final state =
          tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView));
      final revision = state.debugDataRevision;

      await tester.pumpWidget(
        harness([
          'TF1 HD',
        ], {
          'TF1 HD': [prog('LE JT', 10)],
        }),
      );
      await tester.pump();

      expect(
        state.debugDataRevision,
        revision,
        reason: 'le cache ne doit pas être reconstruit à l\'identique : '
            'repainter 628 lignes sans raison coûte cher',
      );
    });

    testWidgets('les canaux sans données ne provoquent pas d\'exception',
        (tester) async {
      await tester.pumpWidget(
        harness([
          'A',
          'B',
        ], {
          'A': [prog('X', 8)],
          // 'B' volontairement absent : c'est le cas réel de la plupart des
          // chaînes d'un panel.
        }),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('un changement de catégorie reconstruit la grille',
        (tester) async {
      await tester.pumpWidget(
        harness([
          'TF1 HD',
        ], {
          'TF1 HD': [prog('LE JT', 10)],
        }),
      );
      await tester.pump();

      await tester.pumpWidget(
        harness([
          'SPORT 1',
        ], {
          'SPORT 1': [prog('FOOT', 20)],
        }),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('SPORT 1'), findsOneWidget);
    });
  });

  group('EpgGrid2DView — le zoom va jusqu\'à 4-6 heures', () {
    /// Libellé du bouton `−`, qui porte le facteur de zoom courant.
    ///
    /// On lit l'`IconButton` plutôt que le `Tooltip` interne : les deux boutons
    /// `−` et `+` affichent le même facteur, donc chercher par texte ne
    /// distinguerait pas lequel a été pressé.
    String zoomOutLabel(WidgetTester tester) {
      final button = tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(Icons.zoom_out),
        matching: find.byType(IconButton),
      ),);
      return button.tooltip ?? '';
    }

    testWidgets('trois clics sur dézoomer atteignent le palier 1,0', (tester) async {
      await tester.pumpWidget(harness(['TF1'], const {}));
      await tester.pump();

      final zoomOut = find.byIcon(Icons.zoom_out);
      expect(zoomOut, findsOneWidget);
      // Départ : 4,0 px/min, soit ~1 h 07 sur un S20.
      expect(zoomOutLabel(tester), contains('4.0'));

      for (var i = 0; i < 3; i++) {
        await tester.tap(zoomOut);
        await tester.pump();
      }

      // 4,0 -> 1,5 -> 1,15 -> 1,0 : 4 h 27 de programmes sur 267 px.
      expect(zoomOutLabel(tester), contains('1.0'));
    });
  });

  group('EpgGrid2DView — géométrie verticale cohérente', () {
    test('le pas vertical vaut hauteur + gouttière', () {
      // Régression : les deux ListView (noms et programmes) doivent avancer du
      // même pas, sinon la colonne des noms glisse par rapport aux programmes
      // et chaque programme sort de la case de sa chaîne.
      expect(
        EpgGrid2DViewState.kRowStride,
        EpgGrid2DViewState.kRowHeight + EpgGrid2DViewState.kRowGap,
      );
    });

    test('le pas vertical n\'est pas un 60 px figé', () {
      // Le symptôme observé venait de `(60.0 + 2)` resté en dur dans
      // `_maxVerticalOffset` pendant que les autres sites passaient à 48 :
      // l'étendue de défilement était 31 % trop grande.
      expect(EpgGrid2DViewState.kRowHeight, 48.0);
    });

    testWidgets('chaque programme est dessiné dans la ligne de sa chaîne',
        (tester) async {
      // Deux chaînes, un programme chacune, hauteurs distinctes : si le pas
      // vertical du `ListView` ne vaut pas `kRowStride`, la seconde ligne est
      // peinte plus haut ou plus bas que sa place et le décalage devient
      // visible dans le canvas.
      await tester.pumpWidget(harness(
        ['AAAA', 'BBBB', 'CCCC'],
        {
          'AAAA': [prog('P1', 0)],
          'BBBB': [prog('P2', 0)],
          'CCCC': [prog('P3', 0)],
        },
      ),);
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Chaque ligne mesure `kRowStride` de haut dans le viewport.
      final namesList = tester.widget<ListView>(find.byType(ListView).first);
      final gridList = tester.widget<ListView>(find.byType(ListView).last);
      expect(gridList.itemExtent, EpgGrid2DViewState.kRowStride);
      expect(namesList.itemExtent, EpgGrid2DViewState.kRowStride);
      expect(gridList.itemExtent, namesList.itemExtent);
    });
  });

  group('EpgGrid2DView — le zoom survit à une reconstruction', () {
    testWidgets('un rebuild ne remet pas le zoom à la valeur par défaut',
        (tester) async {
      // Régression : `didUpdateWidget` relisait `widget.pixelsPerMinute`, que
      // l'écran EPG passe en dur à 4,0. Chaque reconstruction (RefreshIndicator,
      // retour de dialogue, changement de catégorie) annulait donc le zoom de
      // l'utilisateur : le cache repartait à 4,0 px/min pendant que l'axe et la
      // ligne rouge gardaient l'autre échelle, et le contenu glissait sous le
      // repère horaire.
      final controller = EpgTimelineController(
        gridStartTime: DateTime.now(),
        pixelsPerMinute: EpgTimelineController.defaultPixelsPerMinute,
      );
      addTearDown(controller.dispose);

      Widget build(String title) => MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 500,
                  height: 700,
                  child: EpgGrid2DView(
                    channels: ['AAAA', 'BBBB'],
                    epgData: {
                      'AAAA': [prog(title, 0)],
                      'BBBB': [prog(title, 0)],
                    },
                    // L'écran EPG passe toujours 4,0 : c'est justement le
                    // piège, la valeur ne doit pas être réimposée.
                    pixelsPerMinute:
                        EpgTimelineController.defaultPixelsPerMinute,
                    timelineController: controller,
                  ),
                ),
              ),
            ),
          );

      await tester.pumpWidget(build('P1'));
      await tester.pump();

      // L'utilisateur dézoome trois fois : 4,0 -> 1,5 -> 1,15 -> 1,0.
      final zoomOut = find.byIcon(Icons.zoom_out);
      expect(zoomOut, findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(zoomOut);
        await tester.pump();
      }
      expect(controller.pixelsPerMinuteValue, 1.0);

      // Rebuild avec les mêmes props : le zoom doit être conservé.
      await tester.pumpWidget(build('P2'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        controller.pixelsPerMinuteValue,
        1.0,
        reason: 'un rebuild a réimposé le zoom par défaut 4,0',
      );
    });
  });

  group('EpgGrid2DView — le tap vise le programme affiché', () {
    testWidgets('défiler puis toucher ouvre le bon programme',
        (tester) async {
      // Régression : `localPosition.dx` est relatif au canvas (qui montre la
      // tranche visible de la journée), alors que `rp.left` est absolu depuis
      // minuit. Sans conversion, le programme retourné était décalé de tout le
      // défilement — plusieurs heures d'erreur à mi-journée — et le tap
      // ouvrait autre chose que ce qu'on voyait.
      final day = DateTime.now();
      final start = DateTime(day.year, day.month, day.day);
      EPGProgram at(int hour, String title) => EPGProgram(
            channelId: 'c1',
            title: title,
            description: '',
            start: start.add(Duration(hours: hour)),
            end: start.add(Duration(hours: hour + 1)),
          );

      EPGProgram? tapped;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: 700,
              child: EpgGrid2DView(
                channels: const ['AAAA'],
                epgData: {
                  'AAAA': [
                    for (var h = 0; h < 24; h++) at(h, 'P$h'),
                  ],
                },
                onProgramTap: (p, _) => tapped = p,
              ),
            ),
          ),
        ),
      ),);
      await tester.pump();
      expect(tester.takeException(), isNull);

      final state = tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView));
      final controller = state.debugTimelineControllerForTest;

      // À 4 px/min, 1 h = 240 px. On choisit une heure bien dans la journée,
      // éloignée de l'heure courante que le harnais recentre à l'ouverture.
      const ppm = 4.0;
      const targetHour = 14;
      final absoluteStart = targetHour * 60 * ppm;

      // On place la fenêtre du tout premier coup sur l'heure visée, pour ne
      // dépendre ni de l'heure système ni du recentrage automatique.
      state.debugSetHorizontalOffsetForTest(absoluteStart - 300);
      await tester.pump();

      // L'écran 300 doit donc tomber dans P14 (absolu 3360 → 3600 px).
      expect(controller.pixelsPerMinuteValue, ppm);
      expect(state.debugProgramTitleAt(300, 'AAAA'), 'P14',
          reason: 'l\'abscisse écran doit être rendue absolue avant la '
              'comparaison',);

      // Un décalage écran nul ne doit PAS tomato à P14 : sans conversion,
      // 0 px écran serait comparé aux positions absolues et tomberait sur P0.
      expect(state.debugProgramTitleAt(0, 'AAAA'), isNot('P14'),
          reason: 'le bord gauche de l\'écran est ailleurs dans la journée',);
    });
  });

group('EpgGapFiller — la grille est continue', () {
    test('une journée entière est couverte sans trou', () {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final filled = fillForTest(
        programs: [prog('Nuit', 0)],
        start: day,
        end: day.add(const Duration(days: 1)),
      );
      var covered = Duration.zero;
      for (final b in filled) {
        covered += b.end.difference(b.start);
      }
      expect(covered, const Duration(days: 1));
    });

    test('les blocs sont contigus', () {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final filled = fillForTest(
        programs: [prog('A', 10), prog('B', 12)],
        start: day,
        end: day.add(const Duration(days: 1)),
      );
      for (var i = 1; i < filled.length; i++) {
        expect(filled[i].start, filled[i - 1].end);
      }
    });
  });

  group('EpgGrid2DView — le défilement horizontal', () {
    testWidgets('un glissement horizontal déplace la grille', (tester) async {
      final day = DateTime.now();
      final start = DateTime(day.year, day.month, day.day);
      await tester.pumpWidget(harness(['TF1 HD'], {
        'c1': fillForTest(
          programs: [
            EPGProgram(
              channelId: 'c1',
              title: 'Programme 1',
              description: '',
              start: start,
              end: start.add(const Duration(hours: 2)),
            ),
          ],
          start: start,
          end: start.add(const Duration(days: 1)),
        ),
      }),);
      await tester.pump();

      final state = tester.state<EpgGrid2DViewState>(
          find.byType(EpgGrid2DView),);
      final before = state.debugHorizontalOffsetForTest;

      // Un glissement horizontal franchement vers la gauche doit entraîner la
      // journée (le contenu visible avance dans le temps).
      await tester.drag(
        find.byType(EpgGrid2DView),
        const Offset(-120, 4),
        warnIfMissed: false,
      );
      await tester.pump();

      final after = state.debugHorizontalOffsetForTest;
      expect(after, greaterThan(before));
      // Le doigt suit la grille : la journée avance exactement de la distance
      // parcourue, une fois l'adaptation tactile prise en compte.
      expect(after - before, closeTo(120, 40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('un glissement vertical ne déplace pas la grille',
        (tester) async {
      final day = DateTime.now();
      final start = DateTime(day.year, day.month, day.day);
      final program = EPGProgram(
        channelId: 'c1',
        title: 'Programme 1',
        description: '',
        start: start,
        end: start.add(const Duration(hours: 2)),
      );
      // Beaucoup de chaînes : la liste est alors franchement défilable, donc
      // son recognizer vertical participe réellement à l'arène. Avec une seule
      // chaîne, la liste ne défile pas et le geste horizontal gagnerait sans
      // adversaire — le test ne prouverait rien.
      final channels = List.generate(40, (i) => 'CH$i');
      final data = {
        for (final c in channels) c: fillForTest(
          programs: [program],
          start: start,
          end: start.add(const Duration(days: 1)),
        ),
      };
      await tester.pumpWidget(harness(channels, data));
      await tester.pump();

      final state = tester.state<EpgGrid2DViewState>(
          find.byType(EpgGrid2DView),);
      final before = state.debugHorizontalOffsetForTest;

      // Geste franchement vertical (avec la petite dérive horizontale d'un
      // doigt réel) : c'est le défilement des chaînes, pas la frise.
      await tester.drag(
        find.byType(EpgGrid2DView),
        const Offset(4, -260),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump();

      final after = state.debugHorizontalOffsetForTest;
      expect(after, closeTo(before, 1.0),
          reason: 'un geste vertical ne doit pas entraîner la journée',);
      expect(tester.takeException(), isNull);
    });
  });

  group('EpgGrid2DView — le texte est peint dans le viewport', () {
    test('`screenXFor` ramène une abscisse absolue dans le viewport', () {
      // 10:00 à 4 px/min = 2400 px depuis minuit ; défilé de 2300 px, le bord
      // gauche du bloc se retrouve à 100 px du bord visible.
      expect(screenXFor(2400, 2300), 100);
      expect(screenXFor(100, 0), 100);
      // Programme à cheval sur minuit : l'abscisse reste négative, le culling
      // s'en charge.
      expect(screenXFor(-60, 0), -60);
    });

    testWidgets('le titre reste peint DANS le bloc après défilement',
        (tester) async {
      final day = DateTime.now();
      final start = DateTime(day.year, day.month, day.day);
      // Un programme par heure, de 00:00 à 24:00 : la fenêtre visible en
      // contient toujours, quel que soit le décalage.
      final programs = [
        for (var h = 0; h < 24; h++)
          EPGProgram(
            channelId: 'c1',
            title: 'P$h',
            description: '',
            start: start.add(Duration(hours: h)),
            end: start.add(Duration(hours: h + 1)),
          ),
      ];

      await tester.pumpWidget(
        _captureHarness(['AAAA'], {'AAAA': programs}),
      );
      // Deux frames : le postFrame qui recentre sur l'heure courante passe au
      // premier ; on impose ensuite notre position.
      await tester.pump();
      await tester.pump();

      final state =
          tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView));
      // Place le programme de 10:00 à 100 px du bord gauche visible.
      const ppm = 4.0;
      final tenAm = start.add(const Duration(hours: 10));
      final offset = programLeftPx(tenAm, start, ppm) - 100;
      state.debugSetHorizontalOffsetForTest(offset);
      await tester.pump();
      expect(state.debugHorizontalOffsetForTest, closeTo(offset, 0.5));

      final captureRect = tester.getRect(find.byKey(_captureKey));
      // La ligne 0 commence sous la frise et le mini-lecteur : on lit sa vraie
      // position plutôt que de la supposer.
      final gridList = find.byWidgetPredicate(
        (w) => w is ListView && w.itemExtent == EpgGrid2DViewState.kRowStride,
      );
      final gridRect = tester.getRect(gridList.last);
      expect(gridRect.left - captureRect.left, closeTo(kChannelWidth, 1.0),
          reason: 'la liste de droite doit être la grille de programmes',);

      // `toImage` doit tourner hors de la zone async simulée du test.
      final image = await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_captureKey),
        );
        return boundary.toImage();
      });
      expect(image, isNotNull, reason: 'capture de la grille impossible');
      final rgba = await tester.runAsync(() async {
        final data =
            await image!.toByteData(format: ui.ImageByteFormat.rawRgba);
        return data!.buffer.asUint8List();
      });

      final blockLeft = gridRect.left - captureRect.left + 100;
      final rowTop = gridRect.top - captureRect.top;
      final bright = _countBrightPixels(
        rgba!,
        image!.width,
        x0: blockLeft.round() + 2,
        x1: (blockLeft + 200).round(),
        y0: rowTop.round() + 4,
        y1: rowTop.round() + 44,
      );

      image.dispose();
      expect(
        bright,
        greaterThan(50),
        reason: 'le titre doit être peint dans le bloc visible ; des blocs '
            'vides signifient que le texte part à son abscisse ABSOLUE '
            '(hors du canvas) au lieu de son abscisse écran',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('l\'indicateur « en direct » est peint dans le bloc',
        (tester) async {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      // Programme couvrant l'instant courant, pour être « live ».
      final liveStart = now.isBefore(day.add(const Duration(minutes: 45)))
          ? day
          : now.subtract(const Duration(minutes: 45));
      final liveEnd = now.add(const Duration(minutes: 45));
      final programs = [
        EPGProgram(
          channelId: 'c1',
          title: 'EN COURS',
          description: '',
          start: liveStart,
          end: liveEnd,
        ),
      ];

      await tester.pumpWidget(
        _captureHarness(['TF1 HD'], {'TF1 HD': programs}),
      );
      await tester.pump();
      await tester.pump();

      final state =
          tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView));
      const ppm = 4.0;
      final desiredOffset = programLeftPx(liveStart, day, ppm) - 100;
      state.debugSetHorizontalOffsetForTest(desiredOffset);
      await tester.pump();
      final actualOffset = state.debugHorizontalOffsetForTest;
      final liveLeft = programLeftPx(liveStart, day, ppm) - actualOffset;

      expect(
        liveLeft,
        greaterThanOrEqualTo(-50),
        reason: 'le bloc « live » doit être positionnable sur la fenêtre visible',
      );
      expect(
        liveLeft,
        lessThan(300),
        reason: 'le bloc « live » doit rester dans la fenêtre de test',
      );

      final captureRect = tester.getRect(find.byKey(_captureKey));
      final gridList = find.byWidgetPredicate(
        (w) => w is ListView && w.itemExtent == EpgGrid2DViewState.kRowStride,
      );
      final gridRect = tester.getRect(gridList.last);
      expect(gridRect.left - captureRect.left, closeTo(kChannelWidth, 1.0));

      final image = await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_captureKey),
        );
        return boundary.toImage();
      });
      expect(image, isNotNull, reason: 'capture de la grille impossible');
      final rgba = await tester.runAsync(() async {
        final data =
            await image!.toByteData(format: ui.ImageByteFormat.rawRgba);
        return data!.buffer.asUint8List();
      });

      final gridDelta = gridRect.left - captureRect.left;
      final rowTop = gridRect.top - captureRect.top;
      final red = _countRedPixels(
        rgba!,
        image!.width,
        x0: (gridDelta + liveLeft + 2).round(),
        x1: (gridDelta + liveLeft + 62).round(),
        y0: (rowTop + 4).round(),
        y1: (rowTop + 44).round(),
      );
      // On vérifie aussi que le titre existe à droite de l'indicateur.
      final white = _countBrightPixels(
        rgba,
        image.width,
        x0: (gridDelta + liveLeft + 68).round(),
        x1: (gridDelta + liveLeft + 200).round(),
        y0: (rowTop + 4).round(),
        y1: (rowTop + 44).round(),
      );

      image.dispose();
      expect(
        red,
        greaterThan(25),
        reason: 'l\'indicateur « en direct » (pastille + libellé) doit être '
            'peint dans le bloc visible',
      );
      expect(
        white,
        greaterThan(30),
        reason: 'le titre doit rester peint à droite de l\'indicateur live, '
            'sans se superposer à celui-ci',
      );
      expect(tester.takeException(), isNull);
    });
  });
}

/// Clé de capture : la grille est enveloppée dans une frontière de repeint
/// dédiée, pour la photographier au pixel près dans le test de visibilité.
const Key _captureKey = Key('epg-capture');

Widget _captureHarness(
  List<String> channels,
  Map<String, List<EPGProgram>> data,
) {
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: _captureKey,
          child: SizedBox(
            width: 500,
            height: 700,
            child: EpgGrid2DView(channels: channels, epgData: data),
          ),
        ),
      ),
    ),
  );
}

/// Compte les pixels franchement clairs (glyphes blancs sur fond sombre) d'un
/// rectangle de l'image RGBA.
///
/// Seuil sur les trois canaux : le texte (blanc à 70 %) passe largement, alors
/// que le fond (#1C1F26), la bordure (blanc à 10 %) et la ligne « maintenant »
/// (rouge, vert et bleu bas) restent sous le seuil.
int _countBrightPixels(
  Uint8List rgba,
  int width, {
  required int x0,
  required int x1,
  required int y0,
  required int y1,
}) {
  const threshold = 130;
  final height = rgba.length ~/ (width * 4);
  var count = 0;
  for (var y = y0 < 0 ? 0 : y0; y < y1 && y < height; y++) {
    for (var x = x0 < 0 ? 0 : x0; x < x1 && x < width; x++) {
      final i = (y * width + x) * 4;
      if (rgba[i] > threshold &&
          rgba[i + 1] > threshold &&
          rgba[i + 2] > threshold) {
        count++;
      }
    }
  }
  return count;
}

/// Compte les pixels « rouge vif » typiques de la pastille et du libellé
/// « en direct » (`#FF5252`).
///
/// Critère : rouge dominant (R > 200), vert et bleu faibles (G,B < 140).
/// Cela évite de compter du blanc (tous hauts), du violet de fond/bordure
/// (R moyen) ou de la ligne rouge très fine au mauvais endroit.
int _countRedPixels(
  Uint8List rgba,
  int width, {
  required int x0,
  required int x1,
  required int y0,
  required int y1,
}) {
  const rThresh = 200;
  const gbThresh = 140;
  final height = rgba.length ~/ (width * 4);
  var count = 0;
  for (var y = y0 < 0 ? 0 : y0; y < y1 && y < height; y++) {
    for (var x = x0 < 0 ? 0 : x0; x < x1 && x < width; x++) {
      final i = (y * width + x) * 4;
      if (rgba[i] > rThresh &&
          rgba[i + 1] < gbThresh &&
          rgba[i + 2] < gbThresh) {
        count++;
      }
    }
  }
  return count;
}
