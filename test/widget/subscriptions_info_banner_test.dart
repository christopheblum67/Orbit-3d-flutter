import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

class _SubscriptionsNotifier extends SubscriptionsNotifier {
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
}

class _TestingNotifier extends SubscriptionsTestingNotifier {
  @override
  Set<String> build() => const {};
}

void main() {
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Les catégories à masquer se règlent dans Paramètres > Filtres de catégories.',
      ),
      findsOneWidget,
    );
  });
}
