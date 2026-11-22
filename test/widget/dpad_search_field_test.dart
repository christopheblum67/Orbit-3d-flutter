import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_search_field.dart';
import 'package:orbit_3d_flutter/features/search/search_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/search_service.dart';

class _SearchHistory implements SearchService {
  @override
  Future<List<String>> getHistory() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  testWidgets('les suggestions restent défilables sur un écran peu haut',
      (tester) async {
    tester.view.physicalSize = const Size(480, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/search?type=vod',
      routes: [
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        searchServiceProvider.overrideWithValue(_SearchHistory()),
        searchFilteredProvider.overrideWith(
          (ref, params) async => UnifiedSearchResult.empty(),
        ),
        searchSuggestionsProvider.overrideWith((ref, query) async* {
          yield [
            for (var i = 0; i < 9; i++) SearchSuggestion(text: 'trame $i'),
          ];
        }),
        vodCategoriesProvider.overrideWith(
          (ref) async => const [MediaCategory(id: 'films', name: 'Films')],
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'trame');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('trame 0'), findsOneWidget);

    final suggestions = find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
    );
    final scrollable = find.descendant(
      of: suggestions,
      matching: find.byType(Scrollable),
    );
    final firstTile = find.ancestor(
      of: find.text('trame 0'),
      matching: find.byType(ListTile),
    );
    final viewport = tester.getSize(suggestions);
    expect(viewport.height, lessThan(240));
    expect(
      viewport.height,
      greaterThanOrEqualTo(tester.getSize(firstTile).height),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
    );

    Focus.of(tester.element(find.byType(SearchBar))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(Focus.of(tester.element(firstTile)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final secondTile = find.ancestor(
      of: find.text('trame 1'),
      matching: find.byType(ListTile),
    );
    expect(Focus.of(tester.element(secondTile)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'trame 1');

    await tester.enterText(find.byType(TextField), 'trame');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final lastTile = find.ancestor(
      of: find.text('trame 8'),
      matching: find.byType(ListTile),
    );
    expect(lastTile, findsOneWidget);
    final visiblePart =
        tester.getRect(scrollable).intersect(tester.getRect(lastTile));
    expect(visiblePart.width, greaterThan(0));
    expect(visiblePart.height, greaterThan(0));
    await tester.tapAt(visiblePart.center);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'trame 8');
  });
}
