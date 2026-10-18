import 'package:flutter/material.dart';
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
  }) async {
    // Surface haute : la liste du dialogue est virtuelle (`ListView.builder`),
    // le 6e carreau (Affinité, ajouté en fin) sortait du viewport 600 px par
    // défaut et n'était jamais construit.
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
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

    // Plus aucun doublon de sens dans la liste : le nom a ses deux boutons,
    // la durée et l'affinité leur bouton ↑/↓. On compte les tuiles (6) pour
    // verrouiller l'absence de l'ancien doublon « affinité croissante ».
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
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
          matching: find.byType(AnimatedContainer),
        )
        .first;
    final ratingTile = find
        .ancestor(
          of: find.text(l.sortByRating),
          matching: find.byType(AnimatedContainer),
        )
        .first;

    expect(
      find.descendant(of: yearTile, matching: find.text(l.sortOptionActive)),
      findsOneWidget,
      reason: '« Par année » doit rester actif même en sens inverse',
    );
    expect(
      find.descendant(of: ratingTile, matching: find.text(l.sortOptionActive)),
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
}