import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_options_dialog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Dialogue de tri : depuis la refonte, la liste n'expose qu'un représentant
/// par critère (le sens vient des boutons ↑/↓ de la barre d'outils), et
/// l'entrée active est marquée par critère, pas par mode exact — un sens
/// inverse choisi via ↑/↓ doit laisser « Par année » actif.
void main() {
  SortMode? selected;

  Future<void> open(
    WidgetTester tester,
    SortMode current, {
    bool withAffinity = true,
    Locale locale = const Locale('fr'),
    Size size = const Size(1080, 2200),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => SortOptionsDialogTV.show(
                context,
                currentMode: current,
                withAffinity: withAffinity,
                onSortSelected: (m) => selected = m,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('le dialogue de tri est traduit en anglais', (tester) async {
    await open(tester, SortMode.yearAsc, locale: const Locale('en'));
    expect(find.text('Advanced sorting options'), findsOneWidget);
    expect(
        find.text('Sort chronologically by production year'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('un seul représentant par critère, sans doublons asc/desc',
      (tester) async {
    await open(tester, SortMode.recentlyAdded);
    final l = AppLocalizations.of(tester.element(find.byType(Dialog)));

    expect(find.text(l.sortLatestM3UXtream), findsOneWidget);
    expect(find.text(l.sortResumePriority), findsOneWidget);
    expect(find.text(l.sortByRating), findsOneWidget);
    expect(find.text(l.sortByYear), findsOneWidget);
    expect(find.text(l.sortByDuration), findsOneWidget);
    expect(find.text(l.sortAffinity), findsOneWidget);

    expect(find.byType(SortOptionTileTV), findsNWidgets(6));
    expect(find.text(l.sortNameAToZ), findsNothing);
    expect(find.text(l.sortNameZToA), findsNothing);
  });

  testWidgets('l\'entrée active suit le critère, pas le sens', (tester) async {
    // `yearAsc` n'existe que via le bouton ↑/↓ : « Par année » doit rester la
    // tuile marquée active.
    await open(tester, SortMode.yearAsc);
    final l = AppLocalizations.of(tester.element(find.byType(Dialog)));
    final yearTile = find
        .ancestor(
          of: find.text(l.sortByYear),
          matching: find.byType(SortOptionTileTV),
        )
        .first;
    final ratingTile = find
        .ancestor(
          of: find.text(l.sortByRating),
          matching: find.byType(SortOptionTileTV),
        )
        .first;

    expect(
      find.descendant(of: yearTile, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
      reason: '« Par année » doit rester actif même en sens inverse',
    );
    expect(
      find.descendant(
          of: ratingTile, matching: find.byIcon(Icons.check_circle)),
      findsNothing,
    );
  });

  testWidgets('sélectionner un critère referme le dialogue', (tester) async {
    await open(tester, SortMode.recentlyAdded);
    final l = AppLocalizations.of(tester.element(find.byType(Dialog)));
    await tester.tap(find.text(l.sortByDuration));
    await tester.pumpAndSettle();

    expect(selected, SortMode.durationShort);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('sans affinité, l\'entrée « Par affinité » disparaît',
      (tester) async {
    await open(tester, SortMode.recentlyAdded, withAffinity: false);
    final l = AppLocalizations.of(tester.element(find.byType(Dialog)));
    expect(find.text(l.sortAffinity), findsNothing);
  });

  testWidgets('les six options tiennent dans une fenêtre TV compacte',
      (tester) async {
    await open(tester, SortMode.recentlyAdded, size: const Size(1280, 720));
    final dialog = tester.getRect(find.byType(Dialog));
    final panel = find
        .descendant(
          of: find.byType(Dialog),
          matching: find.byType(Container),
        )
        .first;
    final size = tester.getSize(panel);
    expect(size.width * size.height, lessThanOrEqualTo(560 * 510 / 2));
    for (final element in tester.elementList(find.byType(SortOptionTileTV))) {
      final circle = tester.widget<AnimatedContainer>(find.descendant(
        of: find.byWidget(element.widget),
        matching: find.byType(AnimatedContainer),
      ));
      expect((circle.decoration! as BoxDecoration).shape, BoxShape.circle);
    }
    final tiles = find.byType(SortOptionTileTV);
    expect(tiles, findsNWidgets(6));
    for (final element in tester.elementList(tiles)) {
      final rect = tester.getRect(find.byWidget(element.widget));
      expect(rect.top, greaterThanOrEqualTo(dialog.top));
      expect(rect.bottom, lessThanOrEqualTo(dialog.bottom));
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(selected, SortMode.resumeFirst);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('le tri reste lisible sur téléphone avec texte agrandi',
      (tester) async {
    await open(tester, SortMode.yearAsc,
        size: const Size(360, 640), locale: const Locale('de'), textScale: 1.5);
    final l = AppLocalizations.of(tester.element(find.byType(Dialog)));
    await tester.scrollUntilVisible(
      find.text(l.sortAffinity),
      120,
      scrollable: find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.sortAffinity), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le D-pad atteint la dernière option et revient en haut',
      (tester) async {
    await open(tester, SortMode.recentlyAdded,
        size: const Size(640, 360), textScale: 1.5);
    final l = AppLocalizations.of(tester.element(find.byType(Dialog)));
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(Focus.of(tester.element(find.text(l.sortAffinity))).hasFocus, isTrue);
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(Focus.of(tester.element(find.text(l.sortLatestM3UXtream))).hasFocus,
        isTrue);
    expect(tester.takeException(), isNull);
  });
}
