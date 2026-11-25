import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/theme/app_theme.dart';
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
    expect(
      countSpan('new').style!.color,
      Theme.of(tester.element(find.byKey(const ValueKey('new'))))
          .colorScheme
          .error,
    );
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

  for (final width in [400.0, 800.0]) {
    testWidgets('focus background covers a multiline category at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoriesRail(
              categories: const [
                MediaCategory(id: 'short', name: 'Tous'),
                MediaCategory(
                  id: 'long',
                  name: 'DOCUMENTAIRES NATURE ET DECOUVERTE',
                  count: 63,
                ),
              ],
              selectedId: 'short',
              focusSelectedOnMount: true,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('long'));
      final background =
          find.descendant(of: tile, matching: find.byType(Container)).first;
      final label = find.descendant(of: tile, matching: find.byType(RichText));
      final paragraph = tester.renderObject<RenderParagraph>(label.first);
      expect(
          paragraph
              .getBoxesForSelection(TextSelection(
                baseOffset: 0,
                extentOffset: paragraph.text.toPlainText().length,
              ))
              .length,
          greaterThan(1));
      final color =
          (tester.widget<Container>(background).decoration! as BoxDecoration)
              .color;
      expect(
        color,
        Color.alphaBlend(
          Theme.of(tester.element(tile))
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.5),
          Theme.of(tester.element(tile)).colorScheme.surfaceContainerLow,
        ),
      );
      final box = tester.getRect(background);
      final text = tester.getRect(label.first);
      expect(text.top, greaterThanOrEqualTo(box.top));
      expect(text.bottom, lessThanOrEqualTo(box.bottom));
      expect(
        tester.widget<InkWell>(
          find.descendant(of: tile, matching: find.byType(InkWell)).first,
        ).canRequestFocus,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('focus paints the whole multiline tile', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: CategoriesRail(
              categories: const [
                MediaCategory(id: 'short', name: 'Récemment', count: 19),
                MediaCategory(
                  id: 'long',
                  name: 'FR | BOX-OFFICE 2025',
                  count: 63,
                ),
              ],
              selectedId: 'short',
              focusSelectedOnMount: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('long'));
    final background =
        find.descendant(of: tile, matching: find.byType(Container)).first;
    final label =
        find.descendant(of: tile, matching: find.byType(RichText)).first;
    final paragraph = tester.renderObject<RenderParagraph>(label);
    final lines = paragraph.getBoxesForSelection(TextSelection(
      baseOffset: 0,
      extentOffset: paragraph.text.toPlainText().length,
    ));
    expect(lines.length, greaterThan(1));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final origin = tester.getTopLeft(find.byKey(boundaryKey));
    final rect = tester.getRect(background);
    final textOrigin = tester.getTopLeft(label);
    final x = (rect.left - origin.dx + 10).round();
    final yValues = [
      (textOrigin.dy - origin.dy + lines.first.toRect().center.dy).round(),
      (textOrigin.dy - origin.dy + lines.last.toRect().center.dy).round(),
    ];

    Future<List<List<int>>> pixels() async {
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final data = bytes!.buffer.asUint8List();
        final result = [
          for (final y in yValues)
            data.sublist(
                (y * image.width + x) * 4, (y * image.width + x) * 4 + 3),
        ];
        image.dispose();
        return result;
      }))!;
    }

    final before = await pixels();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final after = await pixels();
    for (var i = 0; i < yValues.length; i++) {
      expect(
        List.generate(3, (channel) => after[i][channel] - before[i][channel])
            .reduce((a, b) => a > b ? a : b),
        greaterThan(10),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('one and two line categories have the same solid focus fill',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: CategoriesRail(
              categories: const [
                MediaCategory(id: 'short', name: 'Tous', count: 19),
                MediaCategory(
                  id: 'recent',
                  name: 'SÉRIES RÉCENTES',
                ),
                MediaCategory(
                  id: 'comedy',
                  name: 'COMÉDIE DRAMATIQUE',
                ),
              ],
              selectedId: 'short',
              focusSelectedOnMount: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final origin = tester.getTopLeft(find.byKey(boundaryKey));

    Future<List<List<int>>> sampleFill(String id, int expectedLines) async {
      final tile = find.byKey(ValueKey(id));
      final background =
          find.descendant(of: tile, matching: find.byType(Container)).first;
      final label =
          find.descendant(of: tile, matching: find.byType(RichText)).first;
      final paragraph = tester.renderObject<RenderParagraph>(label);
      final boxes = paragraph.getBoxesForSelection(TextSelection(
        baseOffset: 0,
        extentOffset: paragraph.text.toPlainText().length,
      ));
      final rows = <double>[];
      for (final box in boxes) {
        final center = box.toRect().center.dy;
        if (!rows.any((row) => (row - center).abs() < 5)) {
          rows.add(center);
        }
      }
      expect(rows.length, expectedLines, reason: '$id: $boxes');
      final rect = tester.getRect(background);
      final textOrigin = tester.getTopLeft(label);
      final xValues = [
        (rect.left - origin.dx + 12).round(),
        (rect.right - origin.dx - 12).round(),
      ];
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final data = bytes!.buffer.asUint8List();
        final result = [
          for (final row in rows)
            for (final x in xValues)
              data.sublist(
                (((textOrigin.dy - origin.dy + row).round() * image.width) +
                        x) *
                    4,
                (((textOrigin.dy - origin.dy + row).round() * image.width) +
                            x) *
                        4 +
                    3,
              ),
        ];
        image.dispose();
        return result;
      }))!;
    }

    final reference = (await sampleFill('short', 1)).first;
    for (final id in ['recent', 'comedy']) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      for (final pixel in await sampleFill(id, 2)) {
        expect(pixel, reference, reason: 'entire focus fill for $id');
      }
    }
  });
}
