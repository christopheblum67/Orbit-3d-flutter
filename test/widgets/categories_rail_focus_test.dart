import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/categories_rail.dart';
import 'package:orbit_3d_flutter/models/category.dart';

void main() {
  const categories = [
    MediaCategory(id: '', name: 'Tous'),
    MediaCategory(id: 'films', name: 'Films'),
  ];

  testWidgets('shows all panel categories without country filters',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoriesRail(
            categories: const [
              MediaCategory(id: 'fr', name: 'FRANCE'),
              MediaCategory(id: 'it', name: 'ITALY'),
            ],
            selectedId: 'fr',
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byKey(const ValueKey('fr')), findsOneWidget);
    expect(find.byKey(const ValueKey('it')), findsOneWidget);
  });

  testWidgets('shows additions separately only for matching category counts',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoriesRail(
            categories: const [
              MediaCategory(id: 'new', name: 'Nouveautés', count: 283),
              MediaCategory(id: 'other', name: 'Autres', count: 10),
            ],
            increasedCounts: const {
              'new': (total: 283, added: 2),
              'other': (total: 11, added: 1),
            },
            selectedId: 'new',
            onSelected: (_) {},
          ),
        ),
      ),
    );
    TextSpan countSpan(String id) {
      final text = tester.widget<RichText>(
        find
            .descendant(
              of: find.byKey(ValueKey(id)),
              matching: find.byType(RichText),
            )
            .first,
      );
      final root = text.text as TextSpan;
      final inner = root.children!.first as TextSpan;
      return inner.children!.last as TextSpan;
    }

    expect(countSpan('new').text, ' (+2)');
    expect(countSpan('new').style!.color, Colors.red.shade800);
    expect(countSpan('new').style!.fontWeight, FontWeight.w800);
    expect(countSpan('other').text, ' (10)');
    expect(countSpan('other').style!.color, isNull);
  });

  testWidgets('focuses the selected category and supports D-pad selection',
      (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoriesRail(
            categories: categories,
            selectedId: '',
            focusSelectedOnMount: true,
            onSelected: (id) => selected = id,
          ),
        ),
      ),
    );
    await tester.pump();

    final first = find.byKey(const ValueKey(''));
    final categoryFocus = tester.widget<Focus>(
      find.descendant(of: first, matching: find.byType(Focus)).first,
    );
    expect(categoryFocus.focusNode!.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, '');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 'films');
  });

  testWidgets('does not request initial focus when disabled', (tester) async {
    final otherFocus = FocusNode();
    addTearDown(otherFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Focus(focusNode: otherFocus, child: const Text('Grille')),
              CategoriesRail(
                categories: categories,
                selectedId: '',
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    otherFocus.requestFocus();
    await tester.pump();
    expect(otherFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets('only the focused category has a ring', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoriesRail(
            categories: categories,
            selectedId: '',
            focusSelectedOnMount: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    BoxDecoration tileDecoration(String id) {
      final tile = find.byKey(ValueKey(id));
      final container = tester.widget<Container>(
        find.descendant(of: tile, matching: find.byType(Container)).first,
      );
      return container.decoration! as BoxDecoration;
    }

    final selected = tileDecoration('');
    final focused = tileDecoration('films');
    expect((selected.border! as Border).top.color, Colors.transparent);
    expect(selected.color, isNot(Colors.transparent));
    expect((focused.border! as Border).top.color, isNot(Colors.transparent));
    expect(focused.boxShadow, isNotEmpty);
  });
}
