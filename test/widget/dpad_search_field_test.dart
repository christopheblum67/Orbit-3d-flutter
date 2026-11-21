import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_search_field.dart';

void main() {
  testWidgets('search icon changes color when focused', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: DpadSearchField(
            controller: controller,
            hint: 'Rechercher',
            onChanged: (_) {},
          ),
        ),
      ),
    ));
    final icon = find.byIcon(Icons.search);
    final scheme = Theme.of(tester.element(icon)).colorScheme;
    expect(IconTheme.of(tester.element(icon)).color, scheme.onSurfaceVariant);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(IconTheme.of(tester.element(icon)).color, scheme.primary);
  });

  testWidgets('la recherche laisse passer les flèches puis s\'édite sur OK',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: DpadSearchField(
                    controller: controller,
                    hint: 'Rechercher',
                    onChanged: (_) {},
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
  });
}
