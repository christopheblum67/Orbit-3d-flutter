import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/home_menu_drawer.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/home_shell.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('mobile bottom navigation includes profile and settings',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeShell(
            child: Focus(
              autofocus: true,
              child: Text('HOME_CONTENT'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sourceTypeProvider.overrideWith((ref) async => 'xtream'),
        ],
        child: MaterialApp.router(
          builder: (context, child) => TvModeDetector(
            child: child ?? const SizedBox.shrink(),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(
      tester.getRect(find.byIcon(Icons.person_outline)).left,
      greaterThanOrEqualTo(0),
    );
    expect(
      tester.getRect(find.byIcon(Icons.settings)).right,
      lessThanOrEqualTo(360),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide TV mode hides the rail and D-pad navigates from the drawer',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeShell(
              child: Focus(
                autofocus: true,
                child: Text('HOME_CONTENT'),
              ),
            ),
          ),
          GoRoute(
            path: '/live',
            builder: (context, state) => HomeShell(
              child: Scaffold(
                appBar: AppBar(title: const Text('LIVE_PAGE_APPBAR')),
                body: const Text('LIVE_CONTENT'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sourceTypeProvider.overrideWith((ref) async => 'xtream'),
          ],
          child: MaterialApp.router(
            builder: (context, child) => TvModeDetector(
              child: child ?? const SizedBox.shrink(),
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsNothing);
      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(tester.widget<AppBar>(find.byType(AppBar)).actions, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus,
        isNotNull,
      );
      expect(
        FocusManager.instance.primaryFocus!.debugLabel,
        'Home menu button',
      );

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(HomeMenuDrawer), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/live');
      expect(find.byType(AppBar), findsOneWidget);
    },
  );
}
