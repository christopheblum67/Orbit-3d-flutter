import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/startup/startup_splash_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

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
            Duration(minutes: fresh ? 29 : 30),
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
      await tester.pumpWidget(const SizedBox.shrink());
      live.complete([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  }
}
