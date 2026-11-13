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
