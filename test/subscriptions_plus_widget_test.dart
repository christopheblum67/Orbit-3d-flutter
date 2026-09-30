import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

class _FakeSubscriptionsNotifier extends SubscriptionsNotifier {
  @override
  List<Subscription> build() => const <Subscription>[];
}

class _FakeTestingNotifier extends SubscriptionsTestingNotifier {
  @override
  Set<String> build() => const <String>{};
}

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('orbit_hive_');
    Hive.init(dir.path);
    await Hive.openBox('subscriptions');
  });

  late final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SubscriptionsScreen(),
      ),
    ],
  );

  testWidgets('» + '' ouvre le dialogue d''ajout d''abonnement',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionsProvider
              .overrideWith(() => _FakeSubscriptionsNotifier()),
          subscriptionsTestingProvider
              .overrideWith(() => _FakeTestingNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsNWidgets(2));
  });
}
