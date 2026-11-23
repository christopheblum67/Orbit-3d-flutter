import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/features/startup/refresh_progress_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EpgCache extends EPGDataCache {
  bool? forced;

  @override
  Future<List<EPGProgram>> loadFull(ApiService api,
      {bool forceRefresh = false}) async {
    forced = forceRefresh;
    return [];
  }
}

class _SubscriptionsNotifier extends SubscriptionsNotifier {
  final deleted = <String>[];

  @override
  List<Subscription> build() => [
        Subscription(
          id: 'sub-1',
          name: 'Test',
          type: SubscriptionType.xtream,
          baseUrl: 'https://panel.example',
          username: 'user',
          password: 'pass',
          createdAt: DateTime(2026),
        ),
      ];

  @override
  Future<void> deleteSubscription(String id) async {
    deleted.add(id);
    state = state.where((subscription) => subscription.id != id).toList();
  }
}

class _TestingNotifier extends SubscriptionsTestingNotifier {
  @override
  Set<String> build() => const {};
}

class _DuplicateSubscriptionsNotifier extends SubscriptionsNotifier {
  @override
  List<Subscription> build() {
    Subscription xtream(String id, String? password) => Subscription(
          id: id,
          name: id,
          type: SubscriptionType.xtream,
          baseUrl: 'https://panel.example/',
          username: 'user',
          password: password,
          createdAt: DateTime(2026),
        );
    Subscription m3u(String id, String url) => Subscription(
          id: id,
          name: id,
          type: SubscriptionType.m3u,
          m3uUrl: url,
          createdAt: DateTime(2026),
        );
    return [
      xtream('xtream-a', 'pass'),
      xtream('xtream-b', 'pass')
        ..baseUrl = 'https://panel.example/player_api.php',
      xtream('different-password', 'other'),
      xtream('missing-password-a', null),
      xtream('missing-password-b', null),
      m3u('m3u-a', 'https://list.example/playlist?token=secret'),
      m3u('m3u-b', 'https://list.example/playlist?token=secret'),
      m3u('different-list', 'https://list.example/other?token=secret'),
      m3u('missing-url-a', ''),
      m3u('missing-url-b', ''),
    ];
  }
}

void main() {
  test('category filter guidance uses the current path in every language', () {
    for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
      final l = lookupAppLocalizations(Locale(language));
      expect(l.subscriptionFilterHelp, contains(l.settingsTitle));
      expect(l.subscriptionFilterHelp, contains(l.sectionAccessibility));
      expect(l.subscriptionFilterHelp, contains(l.settingsCategoryFilters));
    }
  });
  testWidgets('subscription deletion defaults to delete and supports D-pad',
      (tester) async {
    final notifier = _SubscriptionsNotifier();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SubscriptionsScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        subscriptionsProvider.overrideWith(() => notifier),
        subscriptionsTestingProvider.overrideWith(_TestingNotifier.new),
        activeSubscriptionProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    final deleteIcon = find.byIcon(Icons.delete);
    await tester.ensureVisible(deleteIcon);
    final iconFocus =
        find.ancestor(of: deleteIcon, matching: find.byType(TvFocus)).first;
    Focus.of(tester.element(find
            .descendant(
              of: iconFocus,
              matching: find.byType(ExcludeFocus),
            )
            .first))
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final confirm = find.descendant(of: dialog, matching: find.text('Delete'));
    final cancel = find.descendant(of: dialog, matching: find.text('Cancel'));
    bool isFocused(Finder finder) => find
        .descendant(
          of: find
              .byWidget(FocusManager.instance.primaryFocus!.context!.widget),
          matching: finder,
        )
        .evaluate()
        .isNotEmpty;
    expect(isFocused(confirm), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(isFocused(cancel), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(notifier.deleted, isEmpty);
    expect(dialog, findsNothing);

    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();
    expect(isFocused(confirm), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(isFocused(confirm), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(notifier.deleted, ['sub-1']);
    expect(dialog, findsNothing);
  });

  testWidgets('subscription form is localized in English', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SubscriptionsScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        subscriptionsProvider.overrideWith(_SubscriptionsNotifier.new),
        subscriptionsTestingProvider.overrideWith(_TestingNotifier.new),
        activeSubscriptionProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('New subscription'), findsOneWidget);
    expect(find.text('Subscription name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Nouvel abonnement'), findsNothing);
  });

  testWidgets('marks matching sources without removing subscriptions',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SubscriptionsScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        subscriptionsProvider.overrideWith(_DuplicateSubscriptionsNotifier.new),
        subscriptionsTestingProvider.overrideWith(_TestingNotifier.new),
        activeSubscriptionProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Doublon possible'), findsNWidgets(4));
    expect(find.textContaining('Aucun n’a été supprimé'), findsOneWidget);
    expect(find.text('different-password'), findsOneWidget);
    expect(find.text('missing-password-a'), findsOneWidget);
    expect(find.text('different-list'), findsOneWidget);
    expect(find.textContaining('token=secret'), findsNothing);
  });

  testWidgets('shows where category filters are configured', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SubscriptionsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionsProvider.overrideWith(_SubscriptionsNotifier.new),
          subscriptionsTestingProvider.overrideWith(_TestingNotifier.new),
          activeSubscriptionProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Les catégories à masquer se règlent dans Configuration > Accessibilité > Filtres de catégories.',
      ),
      findsOneWidget,
    );
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(
          OutlinedButton, 'Forcer la mise à jour de l’abonnement actif'),
    );
    expect(button.onPressed, isNull);
  });

  for (final success in [true, false]) {
    testWidgets('forced refresh reports ${success ? "success" : "failure"}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sub = Subscription(
        id: 'sub-1',
        name: 'Test',
        type: SubscriptionType.xtream,
        baseUrl: 'https://panel.example',
        username: 'user',
        password: 'pass',
        createdAt: DateTime(2026),
        isActive: true,
      );
      final pending = Completer<List<Channel>>();
      final cache = _EpgCache();
      var started = 0;
      var bypassed = false;
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const SubscriptionsScreen()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          subscriptionsProvider.overrideWith(_SubscriptionsNotifier.new),
          subscriptionsTestingProvider.overrideWith(_TestingNotifier.new),
          activeSubscriptionProvider.overrideWithValue(sub),
          lastRefreshTimestampProvider
              .overrideWithBuild((ref, notifier) => DateTime.now()),
          liveChannelsProvider.overrideWith((ref) {
            started++;
            bypassed = ApiService.bypassCatalogCache;
            return pending.future;
          }),
          moviesProvider.overrideWith((ref) async => []),
          seriesProvider.overrideWith((ref) async => []),
          radioChannelsProvider.overrideWith((ref) async => []),
          replaysProvider.overrideWith((ref) async => []),
          epgDataCacheProvider.overrideWithValue(cache),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pumpAndSettle();
      await tester
          .tap(find.text('Forcer la mise à jour de l’abonnement actif'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RefreshProgressScreen), findsOneWidget);
      expect(started, 1);
      expect(bypassed, isTrue);
      pending.complete(success
          ? [
              Channel(
                  id: '1', name: 'Test', logoUrl: '', streamUrl: '', group: '')
            ]
          : []);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(cache.forced, isTrue);
      expect(ApiService.bypassCatalogCache, isFalse);
      expect(
        find.text(success
            ? 'Mise à jour terminée : au moins une source actualisée.'
            : 'Mise à jour impossible : aucune donnée reçue.'),
        findsOneWidget,
      );
    });
  }
}
