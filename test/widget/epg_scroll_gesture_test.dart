import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_scroll_gesture.dart';

void main() {
  group('HorizontalDragLayer — défilement par glissement', () {
    testWidgets('un glissement horizontal déplace la grille', (tester) async {
      // Le défaut historique : aucun geste horizontal n'existait. Le
      // défilement passait par un `Listener` brut, qui perdait l'arène de
      // gestes face au `ListView` vertical — la grille restait figée.
      final offset = ValueNotifier<double>(0.0);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: HorizontalDragLayer(
              offset: offset,
              maxOffset: 10000.0,
              onOffsetChanged: (value) => offset.value = value,
              child: const SizedBox(
                width: 300,
                height: 400,
                child: Text('grille'),
              ),
            ),
          ),
        ),
      ),);

      expect(offset.value, 0.0);

      // Glissement de 120 px vers la gauche : la journée avance de 120 px.
      await tester.timedDrag(
        find.text('grille'),
        const Offset(-120, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();

      expect(offset.value, closeTo(120.0, 1.0),
          reason: 'le glissement doit déplacer la grille',);

      // Glissement inverse : retour à zéro, la journée revient en arrière.
      await tester.timedDrag(
        find.text('grille'),
        const Offset(120, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();
      expect(offset.value, closeTo(0.0, 1.0));
    });

    testWidgets('la base du geste est lue à l\'instant du toucher', (tester) async {
      // Régression mesurée dans la grille : l'offset était passé en `double`
      // figé au build. La grille se déplaçant par `ValueNotifier` sans se
      // reconstruire, la base restait à 0 et le premier glissement sautait
      // d'autant. Ici, la valeur change AVANT le geste, sans rebuild.
      final offset = ValueNotifier<double>(500.0);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: HorizontalDragLayer(
              offset: offset,
              maxOffset: 10000.0,
              onOffsetChanged: (value) => offset.value = value,
              child: const SizedBox(
                width: 300,
                height: 400,
                child: Text('base'),
              ),
            ),
          ),
        ),
      ),);

      // Décalage modifié hors rebuild, comme le fait le zoom/le recentrage.
      offset.value = 1200.0;

      await tester.timedDrag(
        find.text('base'),
        const Offset(-100, 0),
        const Duration(milliseconds: 150),
      );
      await tester.pumpAndSettle();

      // Sans la lecture vivante, la base restait 500 et le résultat 600.
      expect(offset.value, closeTo(1300.0, 1.0),
          reason: 'la base doit être l\'offset courant (1200), pas le build (500)',);
    });

    testWidgets('le décalage est borné à la journée', (tester) async {
      final offset = ValueNotifier<double>(500.0);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: HorizontalDragLayer(
              offset: offset,
              maxOffset: 1000.0,
              onOffsetChanged: (value) => offset.value = value,
              child: const SizedBox(width: 300, height: 400, child: Text('g')),
            ),
          ),
        ),
      ),);

      // Tirage vers la droite depuis 500 : ne doit pas dépasser 1000.
      await tester.timedDrag(
        find.text('g'),
        const Offset(-900, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();
      expect(offset.value, 1000.0);

      // Tirage vers la droite depuis 1000 : on revient vers le début de la journée,
      // donc vers 0 au lieu de dépasser la borne basse.
      await tester.timedDrag(
        find.text('g'),
        const Offset(900, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();
      expect(offset.value, closeTo(100.0, 1.0));
    });

    testWidgets('un glissement vertical ne déplace PAS la grille', (tester) async {
      // C'est le partage d'arène : un geste franchement vertical doit laisser
      // le `ListView` défiler, pas la frise.
      final offset = ValueNotifier<double>(0.0);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: HorizontalDragLayer(
              offset: offset,
              maxOffset: 10000.0,
              onOffsetChanged: (value) => offset.value = value,
              child: const SizedBox(width: 300, height: 400, child: Text('v')),
            ),
          ),
        ),
      ),);

      await tester.timedDrag(
        find.text('v'),
        const Offset(0, -150),
        const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();

      expect(offset.value, 0.0,
          reason: 'un geste vertical ne doit pas toucher au décalage',);
    });

    testWidgets('le geste cumulé ne dérive pas', (tester) async {
      // Le tactile n'envoie pas ses positions en nombres entiers : repartir
      // d'une base figée évite la dérive d'arrondi qu'un cumul naïf
      // produirait.
      final offset = ValueNotifier<double>(0.0);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: HorizontalDragLayer(
              offset: offset,
              maxOffset: 100000.0,
              onOffsetChanged: (value) => offset.value = value,
              child: const SizedBox(width: 300, height: 400, child: Text('d')),
            ),
          ),
        ),
      ),);

      // Trois gestes identiques de 33 px : le total doit être exact.
      for (var i = 0; i < 3; i++) {
        await tester.timedDrag(
          find.text('d'),
          const Offset(-33, 0),
          const Duration(milliseconds: 150),
        );
        await tester.pumpAndSettle();
      }
      expect(offset.value, closeTo(99.0, 0.5),
          reason: 'trois glissements de 33 px doivent faire exactement 99 px',);
    });
  });
}