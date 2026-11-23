import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/features/settings/unified_settings_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Storage extends StorageService {
  @override
  dynamic getSetting(String key) => null;

  @override
  Future<UserPreferences> getPreferences() async => const UserPreferences();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  const clearedBoxes = ['history', 'recently_watched', 'search_history'];
  const preservedBoxes = [
    'profiles',
    'settings',
    'subscriptions',
    'metadata_cache',
    'epg_cache',
    'downloads',
    'settings_backup',
  ];
  const cacheDirectories = [
    'playlist_cache',
    'xmltv_http_cache',
    'catalog_validators',
  ];
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  final prefsData = <String, Object>{
    'tls_impersonation': false,
    'certificate_pinning_enabled': true,
    'certificate_pinning_fingerprints': <String>['fingerprint'],
    'dns_provider': 'custom-dns',
    'local_video_proxy': true,
    'player_engine.primary.live': 'vlc',
    'tmdb_api_key_override': 'api-key',
    'cf_cookies': 'cloudflare-cookie',
    'cf_user_agent': 'cloudflare-agent',
    'profile_pin_attempts_locked': 'locked-state',
    'unknown_future_connection_setting': 'preserve',
  };

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('orbit_reset_');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (_) async => directory.path);
    SharedPreferences.setMockInitialValues(prefsData);
    for (final name in [...clearedBoxes, ...preservedBoxes]) {
      final box = await Hive.openBox<dynamic>(name);
      await box.put('sentinel', 'data-$name');
    }
    for (final name in cacheDirectories) {
      final cache = Directory('${directory.path}${Platform.pathSeparator}$name');
      await cache.create();
      await File('${cache.path}${Platform.pathSeparator}entry.json')
          .writeAsString('cached-$name');
    }
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('reset clears local history but preserves connection data',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const Scaffold(body: Text('Onboarding')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(_Storage()),
        activeSubscriptionProvider.overrideWithValue(null),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    final l = lookupAppLocalizations(const Locale('fr'));
    await tester.ensureVisible(find.text(l.resetApp));
    await tester.tap(find.text(l.resetApp));
    await tester.pumpAndSettle();
    expect(find.text(l.resetAppDialogBody), findsOneWidget);
    await tester.tap(find.text(l.cancel));
    await tester.pumpAndSettle();
    expect(Hive.box<dynamic>('history').get('sentinel'), 'data-history');

    await tester.tap(find.text(l.resetApp));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text(l.resetAppDialogConfirm));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('Onboarding'), findsOneWidget);
    for (final name in clearedBoxes) {
      expect(Hive.box<dynamic>(name).isEmpty, isTrue, reason: name);
    }
    for (final name in preservedBoxes) {
      expect(Hive.box<dynamic>(name).get('sentinel'), 'data-$name',
          reason: name);
    }
    for (final entry in prefsData.entries) {
      expect(prefs.get(entry.key), entry.value, reason: entry.key);
    }
    await tester.runAsync(() async {
      for (final name in cacheDirectories) {
        final file = File(
          '${directory.path}${Platform.pathSeparator}$name'
          '${Platform.pathSeparator}entry.json',
        );
        expect(await file.readAsString(), 'cached-$name', reason: name);
      }
    });
  });

  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    testWidgets('reset confirmation fits a short screen in $language',
        (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(_Storage()),
          activeSubscriptionProvider.overrideWithValue(null),
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pumpAndSettle();
      final l = lookupAppLocalizations(Locale(language));
      await tester.ensureVisible(find.text(l.resetApp));
      await tester.tap(find.text(l.resetApp));
      await tester.pumpAndSettle();
      expect(find.text(l.resetAppDialogTitle), findsOneWidget);
      expect(find.text(l.resetAppDialogConfirm).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
