import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/home/home_screen.dart';
import 'package:orbit_3d_flutter/features/startup/refresh_progress_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('defers automatic refresh while app is backgrounded',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(() =>
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    final pending = Completer<List<Channel>>();
    var loads = 0;
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sourceTypeProvider.overrideWith((ref) async => 'xtream'),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        activeSubscriptionProvider.overrideWith((ref) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        lastRefreshTimestampProvider.overrideWithBuild((ref, notifier) => null),
        liveChannelsProvider.overrideWith((ref) {
          loads++;
          return pending.future;
        }),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();
    expect(find.byType(RefreshProgressScreen), findsNothing);
    expect(loads, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(RefreshProgressScreen), findsNothing);
    expect(loads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete([]);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('does not open refresh over a player and retries after return',
      (tester) async {
    addTearDown(() =>
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    final pending = Completer<List<Channel>>();
    var loads = 0;
    DateTime? lastRefresh = DateTime.now();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/player', builder: (_, __) => const Text('Player')),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        sourceTypeProvider.overrideWith((ref) async => 'xtream'),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        activeSubscriptionProvider.overrideWith((ref) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        lastRefreshTimestampProvider
            .overrideWithBuild((ref, notifier) => lastRefresh),
        liveChannelsProvider.overrideWith((ref) {
          loads++;
          return pending.future;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    unawaited(router.push('/player'));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    lastRefresh = null;
    container.invalidate(lastRefreshTimestampProvider);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Player'), findsOneWidget);
    expect(find.byType(RefreshProgressScreen), findsNothing);
    expect(loads, 0);
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(RefreshProgressScreen), findsNothing);
    expect(loads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete([]);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
  });
}
