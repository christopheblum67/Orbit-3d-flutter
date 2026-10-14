import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_toolbar_buttons.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Boutons ↑/↓ et A→Z de la barre d'outils (Films / Séries / Parcourir).
///
/// Ils sont la seule porte d'accès au sens du tri depuis que la liste de choix
/// n'expose plus qu'un critère par entrée. Ces tests verrouillent :
///  - la flèche affichée correspond au sens courant du mode ;
///  - ↑/↓ inverse le critère (et sort du mode alphabétique si on y était) ;
///  - ↑/↓ est désactivé pour « À reprendre », seul critère sans inverse ;
///  - A→Z bascule A→Z ⇄ Z→A et reste allumé tant qu'il pilote l'ordre.
void main() {
  SortMode? captured;

  Future<void> pump(WidgetTester tester, SortMode mode) async {
    captured = null;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SortToolbarButtons(
            mode: mode,
            onChanged: (m) => captured = m,
          ),
        ),
      ),
    );
  }

  testWidgets('affiche ↓ pour un mode décroissant, ↑ pour un mode croissant',
      (tester) async {
    await pump(tester, SortMode.recentlyAdded);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);

    await pump(tester, SortMode.recentlyAddedAsc);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
  });

  testWidgets('↑/↓ inverse le critère courant', (tester) async {
    await pump(tester, SortMode.recentlyAdded);
    await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
    expect(captured, SortMode.recentlyAddedAsc);

    await pump(tester, SortMode.ratingAsc);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(captured, SortMode.ratingDesc);
  });

  testWidgets('« À reprendre » a son bouton ↑/↓ désactivé', (tester) async {
    await pump(tester, SortMode.resumeFirst);
    final direction = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_downward_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(
      direction.onPressed,
      isNull,
      reason: '« À reprendre » n\'a pas de sens inverse : bouton inactif',
    );
  });

  testWidgets('A→Z bascule A→Z puis Z→A, et reste allumé', (tester) async {
    await pump(tester, SortMode.yearDesc);
    await tester.tap(find.byIcon(Icons.sort_by_alpha));
    expect(captured, SortMode.nameAsc);

    await pump(tester, captured!);
    await tester.tap(find.byIcon(Icons.sort_by_alpha));
    expect(captured, SortMode.nameDesc);

    await pump(tester, captured!);
    final alpha = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.sort_by_alpha),
        matching: find.byType(IconButton),
      ),
    );
    expect(
      alpha.color,
      Colors.amber,
      reason: 'le bouton A→Z reste allumé tant que le nom pilote l\'ordre',
    );
  });

  testWidgets('↑/↓ depuis le mode alphabétique rend la main au critère inverse',
      (tester) async {
    await pump(tester, SortMode.nameAsc);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(captured, SortMode.nameDesc);
  });
}