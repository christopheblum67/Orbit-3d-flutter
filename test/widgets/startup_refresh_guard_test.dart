import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/startup/startup_splash_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Api extends ApiService {
  @override
  Future<String?> resolveSubscriptionCacheKey() async => null;
}

class _XtreamApi extends _Api {
  _XtreamApi(this.check);
  final Future<bool> check;

  @override
  Future<bool> isXtreamConfigurationInvalid(Subscription subscription) => check;

  @override
  Future<DateTime?> fetchExpiration() async => null;
}

class _Subscriptions extends SubscriptionsNotifier {
  @override
  List<Subscription> build() => [];

  @override
  Future<void> refreshValidity(String id, {ApiService? api}) async {}
}

class _PendingEpg extends EPGDataCache {
  final pending = Completer<List<EPGProgram>>();
  int calls = 0;

  @override
  Future<List<EPGProgram>> loadFull(
    ApiService api, {
    bool forceRefresh = false,
  }) {
    calls++;
    return pending.future;
  }
}

void main() {
  testWidgets('invalid Xtream settings return to subscriptions during loading',
      (tester) async {
    final check = Completer<bool>();
    final live = Completer<List<Channel>>();
    final subscription = Subscription(
      id: 'subscription',
      name: 'Subscription',
      type: SubscriptionType.xtream,
      baseUrl: 'https://example.test',
      username: 'user',
      password: 'pass',
      createdAt: DateTime(2026),
    );
    final router = GoRouter(
      initialLocation: '/startup',
      routes: [
        GoRoute(
            path: '/startup', builder: (_, __) => const StartupSplashScreen()),
        GoRoute(
          path: '/subscriptions',
          builder: (_, state) => Scaffold(
            body: Text(
                'Subscriptions ${state.uri.queryParameters['connectionError']}'),
          ),
        ),
        GoRoute(path: '/profiles', builder: (_, __) => const Text('Profiles')),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWith((ref) => subscription),
      subscriptionsProvider.overrideWith(_Subscriptions.new),
      apiServiceProvider.overrideWithValue(_XtreamApi(check.future)),
      liveChannelsProvider.overrideWith((ref) => live.future),
      certificatePinningInitializerProvider.overrideWith((ref) {}),
      lastRefreshTimestampProvider.overrideWithBuild((ref, notifier) => null),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();
    check.complete(true);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions 1'), findsOneWidget);
    expect(find.text('Profiles'), findsNothing);
    live.complete([]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('valid Xtream settings continue to profiles', (tester) async {
    final check = Completer<bool>();
    final subscription = Subscription(
      id: 'subscription',
      name: 'Subscription',
      type: SubscriptionType.xtream,
      baseUrl: 'https://example.test',
      username: 'user',
      password: 'pass',
      createdAt: DateTime(2026),
    );
    final router = GoRouter(
      initialLocation: '/startup',
      routes: [
        GoRoute(
          path: '/startup',
          builder: (_, __) => const StartupSplashScreen(),
        ),
        GoRoute(
          path: '/subscriptions',
          builder: (_, __) => const Text('Subscriptions'),
        ),
        GoRoute(
          path: '/profiles',
          builder: (_, __) => const Scaffold(body: Text('Profiles')),
        ),
      ],
    );
    addTearDown(router.dispose);
    final epg = _PendingEpg();
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWith((ref) => subscription),
      subscriptionsProvider.overrideWith(_Subscriptions.new),
      apiServiceProvider.overrideWithValue(_XtreamApi(check.future)),
      epgDataCacheProvider.overrideWithValue(epg),
      liveChannelsProvider.overrideWith((ref) async => <Channel>[]),
      moviesProvider.overrideWith((ref) async => <Movie>[]),
      seriesProvider.overrideWith((ref) async => <Series>[]),
      radioChannelsProvider.overrideWith((ref) async => <Channel>[]),
      certificatePinningInitializerProvider.overrideWith((ref) {}),
      lastRefreshTimestampProvider.overrideWithBuild((ref, notifier) => null),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Profiles'), findsNothing);
    check.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('Subscriptions'), findsNothing);
    epg.pending.complete([]);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final fresh in [true, false]) {
    testWidgets('startup ${fresh ? 'skips' : 'starts'} refresh',
        (tester) async {
      final live = Completer<List<Channel>>();
      var loads = 0;
      final subscription = Subscription(
        id: 'subscription',
        name: 'Subscription',
        type: SubscriptionType.m3u,
        createdAt: DateTime(2026),
      );
      final router = GoRouter(
        initialLocation: '/startup',
        routes: [
          GoRoute(
            path: '/startup',
            builder: (_, state) => const StartupSplashScreen(),
          ),
          GoRoute(
            path: '/profiles',
            builder: (_, state) => const Scaffold(body: Text('Profiles')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(overrides: [
        activeSubscriptionProvider.overrideWith((ref) => subscription),
        apiServiceProvider.overrideWithValue(ApiService()),
        liveChannelsProvider.overrideWith((ref) {
          loads++;
          return live.future;
        }),
        certificatePinningInitializerProvider.overrideWith((ref) {}),
        lastRefreshTimestampProvider.overrideWithBuild(
          (ref, notifier) => DateTime.now().subtract(
            Duration(minutes: fresh ? 7 * 60 + 59 : 8 * 60),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Profiles'), fresh ? findsOneWidget : findsNothing);
      expect(loads, fresh ? 0 : 1);
      if (!fresh) {
        await tester.pump(const Duration(seconds: 60));
        expect(find.text('Vérifier l’abonnement'), findsNothing);
        expect(find.text('Profiles'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      live.complete([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  }

  testWidgets('a pending EPG never blocks the profile screen', (tester) async {
    final epg = _PendingEpg();
    final subscription = Subscription(
      id: 'subscription',
      name: 'Subscription',
      type: SubscriptionType.m3u,
      createdAt: DateTime(2026),
    );
    final router = GoRouter(
      initialLocation: '/startup',
      routes: [
        GoRoute(
          path: '/startup',
          builder: (_, __) => const StartupSplashScreen(),
        ),
        GoRoute(
          path: '/profiles',
          builder: (_, __) => const Scaffold(body: Text('Profiles')),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWith((ref) => subscription),
      apiServiceProvider.overrideWithValue(_Api()),
      epgDataCacheProvider.overrideWithValue(epg),
      liveChannelsProvider.overrideWith((ref) async => <Channel>[]),
      moviesProvider.overrideWith((ref) async => <Movie>[]),
      seriesProvider.overrideWith((ref) async => <Series>[]),
      radioChannelsProvider.overrideWith((ref) async => <Channel>[]),
      certificatePinningInitializerProvider.overrideWith((ref) {}),
      lastRefreshTimestampProvider.overrideWithBuild((ref, notifier) => null),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    for (var i = 0; i < 20 && find.text('Profiles').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('Vérifier l’abonnement'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(epg.calls, 1);
    epg.pending.complete([]);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}
