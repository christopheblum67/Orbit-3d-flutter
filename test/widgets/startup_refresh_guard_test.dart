import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/startup/startup_splash_screen.dart';
import 'package:orbit_3d_flutter/features/startup/refresh_progress_screen.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Api extends ApiService {
  @override
  Future<String?> resolveSubscriptionCacheKey() async => null;
}

class _ParsingApi extends _Api {
  final pending = Completer<M3uPlaylist>();
  void Function()? onParsing;

  @override
  Future<M3uPlaylist> fetchM3uPlaylist(
    String url, {
    void Function()? onParsing,
  }) {
    this.onParsing = onParsing;
    return pending.future;
  }
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
  for (final startup in [true, false]) {
    testWidgets(
        'M3U body milestone updates ${startup ? 'startup' : 'manual refresh'}',
        (tester) async {
      final api = _ParsingApi();
      final subscription = Subscription(
        id: 'm3u',
        name: 'Subscription',
        type: SubscriptionType.m3u,
        m3uUrl: 'https://example.test/playlist',
        createdAt: DateTime(2026),
      );
      final router = GoRouter(
        initialLocation: '/loading',
        routes: [
          GoRoute(
            path: '/loading',
            builder: (_, __) => startup
                ? const StartupSplashScreen()
                : const RefreshProgressScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(overrides: [
        activeSubscriptionProvider.overrideWithValue(subscription),
        apiServiceProvider.overrideWithValue(api),
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
      await tester.pump();
      expect(api.onParsing, isNotNull);
      expect(
          tester
              .widget<RefreshProgressView>(find.byType(RefreshProgressView))
              .percent,
          0);

      api.onParsing!();
      await tester.pump();
      final progress =
          tester.widget<RefreshProgressView>(find.byType(RefreshProgressView));
      expect(progress.percent, greaterThan(0));
      expect(progress.title, 'Analyzing the M3U playlist…');
      expect(progress.doneSteps, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      api.pending.complete(
        const M3uPlaylist(channels: [], radios: [], movies: [], series: []),
      );
      await tester.pump(const Duration(seconds: 1));
    });
  }

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
        expect(find.text('Back to home'), findsOneWidget);
        expect(find.text('Check subscription'), findsOneWidget);
        expect(find.text('Profiles'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      live.complete([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  }

  for (final destination in ['home', 'subscriptions']) {
    testWidgets('stalled startup allows leaving for $destination',
        (tester) async {
      final live = Completer<List<Channel>>();
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
          GoRoute(path: '/home', builder: (_, __) => const Text('Home')),
          GoRoute(
            path: '/subscriptions',
            builder: (_, __) => const Text('Subscriptions'),
          ),
          GoRoute(
              path: '/profiles', builder: (_, __) => const Text('Profiles')),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(overrides: [
        activeSubscriptionProvider.overrideWith((ref) => subscription),
        apiServiceProvider.overrideWithValue(_Api()),
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
      await tester.pump(const Duration(seconds: 59));
      expect(find.text('Back to home'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Back to home'), findsOneWidget);
      expect(find.text('Check subscription'), findsOneWidget);
      if (destination == 'home') {
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
      }
      await tester.pumpAndSettle();
      expect(find.text(destination == 'home' ? 'Home' : 'Subscriptions'),
          findsOneWidget);
      live.complete([]);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('Profiles'), findsNothing);
      expect(find.text(destination == 'home' ? 'Home' : 'Subscriptions'),
          findsOneWidget);
    });
  }

  for (final destination in ['home', 'subscriptions']) {
    testWidgets(
        'manual refresh allows leaving for $destination after a later stall',
        (tester) async {
      final movies = Completer<List<Movie>>();
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => showRefreshProgress(context),
                child: const Text('Refresh'),
              ),
            ),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (_, __) => const Text('Subscriptions'),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(overrides: [
        activeSubscriptionProvider.overrideWith((ref) => null),
        apiServiceProvider.overrideWithValue(_Api()),
        liveChannelsProvider.overrideWith((ref) async => <Channel>[]),
        moviesProvider.overrideWith((ref) => movies.future),
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
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('0 %'), findsNothing);
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Back to home'), findsOneWidget);
      expect(find.text('Check subscription'), findsOneWidget);
      expect(ApiService.bypassCatalogCache, isTrue);
      await tester.tap(find.text(destination == 'home'
          ? 'Back to home'
          : 'Check subscription'));
      await tester.pumpAndSettle();
      final destinationText =
          destination == 'home' ? 'Refresh' : 'Subscriptions';
      expect(find.text(destinationText), findsOneWidget);
      expect(ApiService.bypassCatalogCache, isFalse);
      movies.complete([]);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text(destinationText), findsOneWidget);
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
    expect(find.text('Check subscription'), findsNothing);
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
