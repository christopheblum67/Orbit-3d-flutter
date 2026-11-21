import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/drm/widevine/widevine_delegate.dart';
import 'package:orbit_3d_flutter/drm/widevine_config_store.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/widevine_config_tile.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';

void main() {
  testWidgets('configuration stays bound to the subscription it was opened for',
      (tester) async {
    final secrets = InMemorySecretStore();
    overrideSecretStoreForTesting(secrets);
    addTearDown(restoreSecretStoreForTesting);
    final store = WidevineConfigStore.instance;
    await store.save(WidevineConfig(licenseUrl: 'https://legacy.example.test'));
    var subscription = Subscription(
      id: 'first',
      name: 'Premier',
      type: SubscriptionType.m3u,
      createdAt: DateTime(2020),
    );
    final container = ProviderContainer(
      overrides: [
        activeSubscriptionProvider.overrideWith((ref) => subscription),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: WidevineConfigTile()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Widevine DRM'));
    await tester.pumpAndSettle();
    expect(find.text('Widevine — Premier'), findsOneWidget);
    await tester.tap(find.text('Copier l’ancienne configuration globale'));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'https://legacy.example.test',
    );
    subscription = Subscription(
      id: 'second',
      name: 'Second',
      type: SubscriptionType.m3u,
      createdAt: DateTime(2020),
    );
    container.invalidate(activeSubscriptionProvider);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      (await store.loadForSubscription('first'))?.licenseUrl,
      'https://legacy.example.test',
    );
    expect(await store.loadForSubscription('second'), isNull);
    expect((await store.load())?.licenseUrl, 'https://legacy.example.test');
  });

  testWidgets('missing subscription message is localized', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [activeSubscriptionProvider.overrideWith((ref) => null)],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: WidevineConfigTile()),
      ),
    ));
    expect(find.text('Select an active subscription'), findsOneWidget);
    await tester.tap(find.text('Widevine DRM'));
    await tester.pumpAndSettle();
    expect(find.text('Select an active subscription first.'), findsOneWidget);
  });
}
