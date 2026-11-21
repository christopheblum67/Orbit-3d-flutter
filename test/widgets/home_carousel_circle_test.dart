import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/home/home_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('M3U home carousel exposes the VOD and series tiles',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sourceTypeProvider.overrideWith((ref) async => 'm3u'),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        activeSubscriptionProvider.overrideWith((ref) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        lastRefreshTimestampProvider.overrideWithBuild(
          (ref, notifier) => DateTime.now(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    final profile = tester.getRect(find.byIcon(Icons.person_outline));
    final settings = tester.getRect(find.byIcon(Icons.settings_outlined));
    expect(settings.right, greaterThan(900));
    expect(profile.left, lessThan(settings.left));
    expect(settings.bottom, greaterThan(500));

    expect(find.byKey(const ValueKey('/vod')), findsOneWidget);
    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(2);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/series')), findsOneWidget);
  });

  testWidgets('Multi TV tile follows the active profile setting',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ]);
    addTearDown(router.dispose);
    final container = ProviderContainer(overrides: [
      sourceTypeProvider.overrideWith((ref) async => 'xtream'),
      activeSubscriptionProvider.overrideWith((ref) => null),
      favoritesProvider.overrideWithBuild((ref, notifier) => {}),
      lastRefreshTimestampProvider.overrideWithBuild(
        (ref, notifier) => DateTime.now(),
      ),
    ]);
    addTearDown(container.dispose);
    final profile = UserProfile(
      id: 'a',
      firstName: 'A',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
      settings: const {'multiTvEnabled': false},
    );
    container.read(currentProfileProvider.notifier).setUserProfile(profile);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    var page = tester.widget<PageView>(find.byType(PageView));
    expect(page.childrenDelegate.estimatedChildCount, 8);
    page.controller!.jumpToPage(7);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/radio')), findsOneWidget);
    expect(find.byKey(const ValueKey('/multivideo')), findsNothing);

    container.read(currentProfileProvider.notifier).setUserProfile(
          profile.copyWith(settings: const {'multiTvEnabled': true}),
        );
    await tester.pumpAndSettle();
    page = tester.widget<PageView>(find.byType(PageView));
    expect(page.childrenDelegate.estimatedChildCount, 9);
    page.controller!.jumpToPage(7);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/multivideo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'phone portrait enlarges circles and preserves selection on rotation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/vod', builder: (_, __) => const Text('VOD ouverte')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sourceTypeProvider.overrideWith((ref) async => 'xtream'),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        activeSubscriptionProvider.overrideWith((ref) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        lastRefreshTimestampProvider.overrideWithBuild(
          (ref, notifier) => DateTime.now(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    final circle = find.descendant(
      of: find.byKey(const ValueKey('/live')),
      matching: find.byWidgetPredicate((widget) =>
          widget is AnimatedContainer &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle),
    );
    expect(tester.getSize(circle).width, closeTo(390 * 0.68, 0.1));

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, 0.01));

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller!;
    expect(controller.viewportFraction, 0.38);
    expect(controller.page, closeTo(1, 0.01));
    await tester.tap(find.text('Films'));
    await tester.pumpAndSettle();
    expect(find.text('VOD ouverte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('last refresh age follows the saved timestamp', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ]);
    addTearDown(router.dispose);
    final container = ProviderContainer(overrides: [
      sourceTypeProvider.overrideWith((ref) async => 'xtream'),
      currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      activeSubscriptionProvider.overrideWith((ref) => null),
      favoritesProvider.overrideWithBuild((ref, notifier) => {}),
      lastRefreshTimestampProvider.overrideWithBuild(
        (ref, notifier) => DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Updated 5 min ago'), findsOneWidget);
    container.read(lastRefreshTimestampProvider.notifier).setTimestamp(null);
    await tester.pump();
    expect(find.text('Last update unknown'), findsOneWidget);
  });

  testWidgets('carousel circles navigate with the remote', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/vod', builder: (_, __) => const Text('VOD ouverte')),
    ]);
    addTearDown(router.dispose);
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tvModeNotifierProvider.overrideWith((ref) => tvMode),
        sourceTypeProvider.overrideWith((ref) async => 'xtream'),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        activeSubscriptionProvider.overrideWith((ref) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        lastRefreshTimestampProvider.overrideWithBuild(
          (ref, notifier) => DateTime.now(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    Finder circleFor(String route) => find.descendant(
          of: find.byKey(ValueKey(route)),
          matching: find.byWidgetPredicate((widget) =>
              widget is AnimatedContainer &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle),
        );
    BoxDecoration circleDecoration(String route) =>
        tester.widget<AnimatedContainer>(circleFor(route)).decoration!
            as BoxDecoration;

    final liveIcon = find.descendant(
      of: find.byKey(const ValueKey('/live')),
      matching: find.byIcon(Icons.tv_rounded),
    );
    expect(tester.getCenter(liveIcon).dx,
        closeTo(tester.getCenter(circleFor('/live')).dx, 1));
    expect(
      find.byWidgetPredicate((widget) =>
          widget is AnimatedContainer &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle),
      findsWidgets,
    );
    expect(circleDecoration('/live').boxShadow, isNotEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('/vod'));
    expect(tester.widget<TvFocus>(tile).enableTvEffects, isFalse);
    final decoration = circleDecoration('/vod');
    expect(circleDecoration('/live').boxShadow, isEmpty);
    expect(decoration.boxShadow, isNotEmpty);
    final node = tester.widget<TvFocus>(tile).focusNode!;
    node.unfocus();
    await tester.pumpAndSettle();
    expect(circleDecoration('/vod').boxShadow, isEmpty);
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(circleDecoration('/vod').boxShadow, isNotEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('VOD ouverte'), findsOneWidget);
  });

  testWidgets('D-pad navigation wraps from the last carousel tile to TV',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ]);
    addTearDown(router.dispose);
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tvModeNotifierProvider.overrideWith((ref) => tvMode),
        sourceTypeProvider.overrideWith((ref) async => 'xtream'),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        activeSubscriptionProvider.overrideWith((ref) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        lastRefreshTimestampProvider.overrideWithBuild(
          (ref, notifier) => DateTime.now(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller!;
    controller.jumpToPage(8);
    await tester.pumpAndSettle();
    final lastTile = find.byKey(const ValueKey('/radio'));
    tester.widget<TvFocus>(lastTile).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(controller.page, closeTo(0, 0.01));
    expect(find.byKey(const ValueKey('/live')), findsOneWidget);
    expect(
      tester
          .widget<TvFocus>(find.byKey(const ValueKey('/live')))
          .focusNode!
          .hasPrimaryFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TvFocus>(lastTile).focusNode!.hasPrimaryFocus,
      isTrue,
    );
    expect(
      tester.widget<PageView>(find.byType(PageView)).controller!.page,
      closeTo(8, 0.01),
    );
    expect(tester.takeException(), isNull);
  });
}
