import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/settings/category_filter_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Filters extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(subscriptionId: 'sub');

  @override
  Future<bool> rescan({ApiService? api, bool force = false}) async => true;
}

void main() {
  testWidgets('category tabs follow D-pad left and right', (tester) async {
    final subscription = Subscription(
      id: 'sub',
      name: 'Test',
      type: SubscriptionType.m3u,
      createdAt: DateTime(2020),
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const CategoryFilterScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSubscriptionProvider.overrideWithValue(subscription),
          vodCategoryFilterProvider.overrideWith(_Filters.new),
          vodCategoriesProvider.overrideWith((ref) async =>
              const [MediaCategory(id: 'films', name: 'Action')]),
          seriesCategoriesProvider.overrideWith((ref) async => []),
          liveChannelsAllProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Rescan categories'), findsOneWidget);
    expect(find.text('Settings for this subscription — Never scanned'),
        findsOneWidget);
    final focus = tester.widget<Focus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Focus && widget.focusNode?.debugLabel == 'Category tab 0',
      ),
    );
    focus.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Category tab 1');
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Category tab 2');
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Category tab 1');
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<SwitchListTile>(),
      isNotNull,
    );
  });
}
