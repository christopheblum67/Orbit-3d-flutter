import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/navigation/initial_route.dart';
import 'package:orbit_3d_flutter/features/legal/legal_notice_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _MemorySettingsStorage extends StorageService {
  final Map<String, Object?> values = {};

  @override
  Object? getSetting(String key) => values[key];

  @override
  Future<void> setSetting(String key, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    testWidgets('legal document scrolls with the remote in $language',
        (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = GoRouter(initialLocation: '/legal', routes: [
        GoRoute(
          path: '/legal',
          builder: (_, __) => const LegalNoticeScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('Settings')),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      final document = find.byKey(const ValueKey('legal-document-scroll'));
      final scroll = tester.widget<SingleChildScrollView>(document).controller!;
      final l = lookupAppLocalizations(Locale(language));
      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.text(l.profileBack).hitTestable(), findsOneWidget);
      expect(scroll.offset, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(scroll.offset, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(scroll.offset, 0);
      await tester.drag(document, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      for (var i = 0;
          i < 80 && scroll.offset < scroll.position.maxScrollExtent;
          i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pump();
      }
      expect(scroll.offset, scroll.position.maxScrollExtent);
      expect(find.text(l.legalWarningBody).hitTestable(), findsOneWidget);
      expect(find.text(l.profileBack).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.profileBack));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });
  }

  testWidgets('document is readable in light and dark themes', (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LegalNoticeScreen(firstLaunch: true),
        ),
      ));
      await tester.pumpAndSettle();
      final document = tester
          .widget<Container>(find.byKey(const ValueKey('legal-document')));
      final scheme =
          Theme.of(tester.element(find.byType(LegalNoticeScreen))).colorScheme;
      expect((document.decoration! as BoxDecoration).color,
          scheme.surfaceContainerLowest);
      final l = lookupAppLocalizations(const Locale('fr'));
      final body = tester.widget<Text>(find.text(l.legalServicePlayer));
      expect(body.style!.color, scheme.onSurface);
      expect(body.style!.height, greaterThan(1.0));
    }
  });

  testWidgets('legal notice and optional cloud sharing are localized',
      (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LegalNoticeScreen(firstLaunch: true),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    expect(find.text('I have read and accept · Continue'), findsOneWidget);
    expect(find.textContaining('If you enable cloud sharing'), findsOneWidget);
    expect(find.text('Using the app'), findsOneWidget);
  });

  testWidgets('first launch acceptance persists and opens onboarding',
      (tester) async {
    final storage = _MemorySettingsStorage();
    final router = GoRouter(
      initialLocation: initialRouteFor(
        onboardingDone: false,
        legalNoticeDone: false,
      ),
      routes: [
        GoRoute(
          path: '/legal',
          builder: (context, state) =>
              const LegalNoticeScreen(firstLaunch: true),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(
            body: Text('Onboarding'),
          ),
        ),
        GoRoute(
          path: '/startup',
          builder: (context, state) => const Scaffold(
            body: Text('Startup'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('J\'ai lu et j\'accepte · Continuer'), findsOneWidget);
    await tester.tap(find.text('J\'ai lu et j\'accepte · Continuer'));
    await tester.pumpAndSettle();

    expect(storage.values[kLegalNoticeDoneKey], isTrue);
    expect(find.text('Onboarding'), findsOneWidget);
  });

  testWidgets('first launch can scroll and accept with the remote',
      (tester) async {
    final storage = _MemorySettingsStorage();
    final router = GoRouter(initialLocation: '/legal', routes: [
      GoRoute(
        path: '/legal',
        builder: (_, __) => const LegalNoticeScreen(firstLaunch: true),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const Scaffold(body: Text('Onboarding')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<SingleChildScrollView>(
          find.byKey(const ValueKey('legal-document-scroll')),
        )
        .controller!;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(scroll.offset, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.values[kLegalNoticeDoneKey], isTrue);
    expect(find.text('Onboarding'), findsOneWidget);
  });
}
