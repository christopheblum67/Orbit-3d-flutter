import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/utils/device_info.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/features/settings/unified_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_account_screen.dart';
import 'package:orbit_3d_flutter/features/settings/category_filter_screen.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/readme_contact_dialog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_activity_sync_provider.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SettingsStorage extends StorageService {
  final settings = <String, dynamic>{};
  UserPreferences preferences = const UserPreferences();

  @override
  dynamic getSetting(String key) => settings[key];

  @override
  Future<void> setSetting(String key, dynamic value) async {
    settings[key] = value;
  }

  @override
  Future<UserPreferences> getPreferences() async => preferences;

  @override
  Future<void> savePreferences(UserPreferences value) async {
    preferences = value;
  }
}

class _CategorySettings extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(
        subscriptionId: 'sub',
        knownVodCategories: [MediaCategory(id: 'films', name: 'Action')],
      );

  @override
  Future<bool> rescan({ApiService? api, bool force = false}) async => true;
}

class _CloudSync extends EncryptedActivitySyncNotifier {
  int syncCount = 0;

  @override
  EncryptedActivitySyncState build() =>
      const EncryptedActivitySyncState(profileId: 'profile');

  @override
  Future<void> syncAll() async {
    syncCount++;
  }
}

void main() {
  testWidgets('read me opens contact information and retains legal access',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      GoRoute(path: '/legal', builder: (_, __) => const Text('LEGAL DOCUMENT')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        activeSubscriptionProvider.overrideWith((ref) => null),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    final title = lookupAppLocalizations(const Locale('fr')).legalNotice;
    await tester.ensureVisible(find.text(title));
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    expect(find.byType(ReadmeContactDialog), findsOneWidget);
    expect(find.text('Contacter l’équipe'), findsOneWidget);
    await tester.tap(find.text('Mentions légales'));
    await tester.pumpAndSettle();
    expect(find.text('LEGAL DOCUMENT'), findsOneWidget);
  });

  for (final config in [
    (size: const Size(360, 720), tv: false, manual: false, expected: 60.0),
    (size: const Size(640, 360), tv: false, manual: true, expected: 108.0),
    (size: const Size(960, 540), tv: true, manual: false, expected: 162.0),
    (size: const Size(540, 960), tv: true, manual: false, expected: 76.0),
  ]) {
    testWidgets('settings icons adapt to ${config.size}, TV=${config.tv}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TvModeController();
      if (config.tv) {
        await controller.updateFromDetection(const DeviceDetectionResult(
          deviceType: DeviceType.tv,
          isTv: true,
          confidence: 1,
        ));
      } else if (config.manual) {
        controller.enable();
      }
      addTearDown(controller.dispose);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          tvModeControllerProvider.overrideWithValue(controller),
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
          activeSubscriptionProvider.overrideWith((ref) => null),
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      final profile = find
          .ancestor(
            of: find.text('User profiles'),
            matching: find.byType(TvFocus),
          )
          .first;
      final circle = find.descendant(
        of: profile,
        matching: find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle),
      );
      final diameter = tester.getSize(circle).width;
      expect(diameter, lessThanOrEqualTo(config.expected));
      expect(diameter, greaterThanOrEqualTo(config.tv ? 65 : 48));
      if (config.size.width > config.size.height) {
        expect(diameter, closeTo(tester.getSize(profile).width - 6, 0.1));
        expect(diameter, greaterThan(52));
      } else if (!config.tv) {
        expect(diameter, closeTo(config.expected, 0.1));
      }
      final image = find.descendant(of: profile, matching: find.byType(Image));
      expect(tester.getSize(image).width, closeTo(diameter * 0.65, 0.1));
      expect(tester.getRect(circle).left,
          greaterThanOrEqualTo(tester.getRect(profile).left));
      expect(tester.getRect(circle).right,
          lessThanOrEqualTo(tester.getRect(profile).right));
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(360, 720), const Size(640, 360)]) {
    for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
      testWidgets('combined settings tabs fit and work in $language at $size',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final sub = Subscription(
          id: 'sub',
          name: 'Test',
          type: SubscriptionType.m3u,
          createdAt: DateTime(2020),
        );
        final router = GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
        ]);
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
            activeSubscriptionProvider.overrideWithValue(sub),
            currentProfileProvider.overrideWithBuild((ref, notifier) => null),
            vodCategoryFilterProvider.overrideWith(_CategorySettings.new),
            vodCategoriesProvider.overrideWith((ref) async => []),
            seriesCategoriesProvider.overrideWith((ref) async => []),
            liveChannelsAllProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ));
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(language));
        await tester.ensureVisible(find.text(l.sectionAccessibility));
        await tester.tap(find.text(l.sectionAccessibility));
        await tester.pumpAndSettle();
        expect(find.text(l.dnsProvider), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(TabBar),
            matching: find.text(l.tabNetwork),
          ),
          findsNothing,
        );
        await tester.sendKeyEvent(language == 'ar'
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(find.byType(CategoryFilterScreen), findsOneWidget);
        for (final label in [
          l.settingsCategoryFilters,
          l.audioAndNightFocus,
          l.sectionMemory,
        ]) {
          final tab = find.descendant(
            of: find.byType(TabBar).first,
            matching: find.text(label),
          );
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          if (label == l.settingsCategoryFilters) {
            expect(find.byType(CategoryFilterScreen), findsOneWidget);
            expect(find.text('Test'), findsWidgets);
            final films = find.descendant(
              of: find.byType(CategoryFilterScreen),
              matching: find.text(l.films),
            );
            await tester.tap(films.first);
            await tester.pumpAndSettle();
            expect(find.text('Action'), findsOneWidget);
            final categoryCheckbox = find.descendant(
              of: find.byType(CategoryFilterScreen),
              matching: find.byType(CheckboxListTile),
            );
            await tester.ensureVisible(categoryCheckbox);
            await tester.tap(categoryCheckbox);
            await tester.pumpAndSettle();
            expect(tester.widget<CheckboxListTile>(categoryCheckbox).value,
                isFalse);
            final filmTabFocus = tester.widget<Focus>(find.byWidgetPredicate(
              (widget) =>
                  widget is Focus &&
                  widget.focusNode?.debugLabel == 'Category tab 1',
            ));
            filmTabFocus.focusNode!.requestFocus();
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.select);
            await tester.pumpAndSettle();
            expect(tester.widget<CheckboxListTile>(categoryCheckbox).value,
                isTrue);
          }
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    testWidgets(
        'cloud and backup actions share a localized dialog in $language',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 720);
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
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
          activeSubscriptionProvider.overrideWith((ref) => null),
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        ],
        child: MaterialApp.router(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      final l = lookupAppLocalizations(Locale(language));
      expect(find.text(l.backupExport), findsNothing);
      expect(find.text(l.backupImport), findsNothing);
      await tester.ensureVisible(find.text(l.sectionBackup));
      await tester.tap(find.text(l.sectionBackup));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      final title = tester.widget<Text>(find.descendant(
        of: dialog,
        matching: find.text('${l.settingsCloudAccount} · ${l.sectionBackup}'),
      ));
      expect(title.style?.fontSize, lessThanOrEqualTo(16));
      for (final label in [
        l.settingsCloudAccount,
        l.backupExport,
        l.backupImport
      ]) {
        expect(find.descendant(of: dialog, matching: find.text(label)),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cloud backup dialog supports D-pad export and restore',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    final storage = _SettingsStorage();
    final container = ProviderContainer(overrides: [
      storageServiceProvider.overrideWithValue(storage),
      tvModeNotifierProvider.overrideWithValue(tvMode),
      deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
      activeSubscriptionProvider.overrideWith((ref) => null),
      currentProfileProvider.overrideWithBuild((ref, notifier) => null),
    ]);
    addTearDown(container.dispose);
    await container.read(advancedSettingsProvider.notifier).load();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    final l = lookupAppLocalizations(const Locale('en'));

    Future<void> openDialog() async {
      await tester.ensureVisible(find.text(l.sectionBackup));
      await tester.tap(find.text(l.sectionBackup));
      await tester.pumpAndSettle();
    }

    bool hasTileFocus(Finder content) {
      final tile =
          find.ancestor(of: content, matching: find.byType(TvFocus)).first;
      return Focus.of(tester.element(find
              .descendant(of: tile, matching: find.byType(AnimatedBuilder))
              .first))
          .hasFocus;
    }

    await openDialog();
    expect(hasTileFocus(find.text(l.settingsCloudAccount).last), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(hasTileFocus(find.text(l.backupExport)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.settings['settings_backup'], isA<String>());
    expect(find.text(l.snackBackupExported), findsOneWidget);

    await container
        .read(advancedSettingsProvider.notifier)
        .setHighContrast(true);
    await openDialog();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(hasTileFocus(find.text(l.backupImport)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).highContrast, isFalse);
    expect(find.text(l.snackImportSuccess), findsOneWidget);

    await openDialog();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(CloudAccountScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(CloudAccountScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cloud backup dialog retains manual sync and status',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sync = _CloudSync();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        encryptedActivitySyncProvider.overrideWith(() => sync),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        activeSubscriptionProvider.overrideWith((ref) => null),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    final l = lookupAppLocalizations(const Locale('en'));
    await tester.ensureVisible(find.text(l.sectionBackup));
    await tester.tap(find.text(l.sectionBackup));
    await tester.pumpAndSettle();
    expect(find.text(l.cloudSyncLastSync(l.never)), findsOneWidget);
    await tester.tap(find.text(l.cloudSyncNow));
    await tester.pumpAndSettle();
    expect(sync.syncCount, 1);
  });

  testWidgets('future advanced actions explain they are not yet available',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(960, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
      activeSubscriptionProvider.overrideWith((ref) => null),
      currentProfileProvider.overrideWithBuild((ref, notifier) => null),
    ]);
    addTearDown(container.dispose);
    await container.read(advancedSettingsProvider.notifier).load();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    final l = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l.cloudSyncProfileHelp), findsNothing);
    expect(find.byIcon(Icons.settings_input_component), findsNothing);
    for (final title in ['Contact', 'Activate app']) {
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text('Coming soon'),
          ),
          findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(UnifiedSettingsScreen)))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  test('future action labels are available in all supported languages', () {
    for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
      final l = lookupAppLocalizations(Locale(language));
      expect(l.settingsContact, isNotEmpty);
      expect(l.settingsActivateApp, isNotEmpty);
      expect(l.comingSoon, isNotEmpty);
    }
  });

  for (final size in [
    const Size(360, 720),
    const Size(640, 360),
    const Size(960, 540),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('four account cards fit on one row at $size, scale $scale',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = ProviderContainer(overrides: [
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
          activeSubscriptionProvider.overrideWith((ref) => null),
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        ]);
        addTearDown(container.dispose);
        await container.read(advancedSettingsProvider.notifier).load();
        final router = GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
        ]);
        addTearDown(router.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ));
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(const Locale('en'));
        final titles = [
          l.accountProfiles,
          l.accountSubscriptions,
          l.accountPreferences,
          l.accountDeviceProfile,
        ];
        final rects = [
          for (final title in titles)
            tester.getRect(find
                .ancestor(
                  of: find.text(title),
                  matching: find.byType(TvFocus),
                )
                .first),
        ];
        for (final rect in rects) {
          expect(rect.top, closeTo(rects.first.top, 0.1));
          expect(rect.width, greaterThan(60));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    testWidgets('circular settings fit and retain their labels in $language',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 720);
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
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
          activeSubscriptionProvider.overrideWith((ref) => null),
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        ],
        child: MaterialApp.router(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      final l = lookupAppLocalizations(Locale(language));
      final tile = find
          .ancestor(
            of: find.text(l.accountProfiles),
            matching: find.byType(TvFocus),
          )
          .first;
      final circles = find.descendant(
        of: tile,
        matching: find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle),
      );
      expect(circles, findsOneWidget);
      expect(
          tester.widget<Text>(find.text(l.accountProfiles)).maxLines, isNull);
      expect(find.text(l.accountProfilesSubtitle), findsNothing);
      expect(find.text(l.accountPreferencesSubtitle), findsNothing);
      expect(find.text(l.matchmaking), findsNothing);
      final maintenance =
          find.byKey(ValueKey('settings-group-${l.sectionDiagnostics}'));
      expect(
          find.descendant(of: maintenance, matching: find.text(l.enginesTile)),
          findsOneWidget);
      expect(
          find.descendant(
              of: maintenance, matching: find.text(l.sectionBackup)),
          findsOneWidget);
      expect(find.descendant(of: maintenance, matching: find.text(l.resetApp)),
          findsNothing);
      final contactTile = find
          .ancestor(
              of: find.text(l.settingsContact), matching: find.byType(TvFocus))
          .first;
      final legalTile = find
          .ancestor(
              of: find.text(l.legalNotice), matching: find.byType(TvFocus))
          .first;
      final contactFocus = Focus.of(tester.element(find
          .descendant(of: contactTile, matching: find.byType(AnimatedBuilder))
          .first));
      contactFocus.requestFocus();
      await tester.pumpAndSettle();
      contactFocus.nextFocus();
      await tester.pumpAndSettle();
      expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<TvFocus>(),
          same(tester.widget<TvFocus>(legalTile)));
      final resetTile = find
          .ancestor(of: find.text(l.resetApp), matching: find.byType(TvFocus))
          .first;
      final secret = find
          .ancestor(
              of: find.byKey(const ValueKey('hidden-advanced-entry')),
              matching: find.byType(TvFocus))
          .first;
      final resetFocus = Focus.of(tester.element(find
          .descendant(of: resetTile, matching: find.byType(AnimatedBuilder))
          .first));
      resetFocus.requestFocus();
      await tester.pumpAndSettle();
      resetFocus.nextFocus();
      await tester.pumpAndSettle();
      expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<TvFocus>(),
          same(tester.widget<TvFocus>(secret)));
      await tester
          .ensureVisible(find.byKey(const ValueKey('hidden-advanced-entry')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('network section is localized and editable in $language',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(overrides: [
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        activeSubscriptionProvider.overrideWith((ref) => null),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      ]);
      addTearDown(container.dispose);
      await container.read(advancedSettingsProvider.notifier).load();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      ]);
      addTearDown(router.dispose);
      final l = lookupAppLocalizations(Locale(language));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.dnsProvider), findsNothing);
      await tester.ensureVisible(find.text(l.sectionAccessibility));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.sectionAccessibility));
      await tester.pumpAndSettle();
      expect(find.text(l.dnsProvider), findsOneWidget);
      expect(find.text(l.tabNetwork), findsOneWidget);
      expect(find.text(l.cloudflareReset), findsNothing);
      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8.8.8.8 (Google DoH)').last);
      await tester.pumpAndSettle();
      expect(container.read(advancedSettingsProvider).dnsProvider,
          '8.8.8.8 (Google DoH)');
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(360, 720), const Size(640, 360)]) {
    testWidgets('compact settings dialogs on ${size.width}x${size.height}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final tvMode = TvModeNotifier()..enable();
      addTearDown(tvMode.dispose);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(overrides: [
        tvModeNotifierProvider.overrideWithValue(tvMode),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        activeSubscriptionProvider.overrideWith((ref) => null),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      ]);
      addTearDown(container.dispose);
      await container.read(advancedSettingsProvider.notifier).load();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final settings = find.text('Accessibility');
      await tester.ensureVisible(settings);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('DNS provider (DoH)'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.text('8.8.8.8 (Google DoH)'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.ensureVisible(settings);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.text('No active subscription'),
          ),
          findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(
          container.read(advancedSettingsProvider).nightFocusEnabled, isTrue);
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(
          container.read(advancedSettingsProvider).nightFocusAudioShiftMs, 50);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(
          container
              .read(advancedSettingsProvider)
              .nightFocusVolumeNormalization,
          isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.byType(AudioControlsSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      final minus = find.byTooltip('-50 ms');
      expect(
        find.descendant(
          of: find
              .byWidget(FocusManager.instance.primaryFocus!.context!.widget),
          matching: minus,
        ),
        findsOneWidget,
      );
      final viewport = tester.getRect(find.descendant(
        of: find.byType(AudioControlsSheet),
        matching: find.byType(ListView),
      ));
      expect(tester.getRect(minus).top, greaterThanOrEqualTo(viewport.top));
      expect(tester.getRect(minus).bottom, lessThanOrEqualTo(viewport.bottom));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find
              .byWidget(FocusManager.instance.primaryFocus!.context!.widget),
          matching: find.text('Bass reduction and limiter'),
        ),
        findsOneWidget,
      );
      Navigator.of(tester.element(find.byType(AudioControlsSheet))).pop();
      await tester.pumpAndSettle();
      final memory = find.text('Memory & Cache');
      await tester.ensureVisible(memory);
      await tester.tap(memory);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final accessibilityTab = find.text('Accessibility').last;
      await tester.ensureVisible(accessibilityTab);
      await tester.tap(accessibilityTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      expect(container.read(advancedSettingsProvider).highContrast, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('player options are inside playback engines', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(overrides: [
      deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
      activeSubscriptionProvider.overrideWith((ref) => null),
      currentProfileProvider.overrideWithBuild((ref, notifier) => null),
    ]);
    addTearDown(container.dispose);
    await container.read(advancedSettingsProvider.notifier).load();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Player'), findsNothing);
    await tester.ensureVisible(find.text('Playback engines'));
    await tester.tap(find.text('Playback engines'));
    await tester.pumpAndSettle();
    final checkbox = find.widgetWithText(CheckboxListTile, 'No subtitles');
    expect(find.byType(CheckboxListTile), findsNWidgets(7));
    expect(find.text('Movie and series subtitles'), findsOneWidget);
    expect(find.text('Force no subtitles'), findsNothing);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isFalse);
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isTrue);
  });

  test('profile preferences subtitle contains only language and PIN', () {
    const subtitles = {
      'fr': 'Langue, PIN',
      'en': 'Language, PIN',
      'de': 'Sprache, PIN',
      'es': 'Idioma, PIN',
      'it': 'Lingua, PIN',
      'ar': 'اللغة، رمز PIN',
    };
    for (final entry in subtitles.entries) {
      expect(
        lookupAppLocalizations(Locale(entry.key)).accountPreferencesSubtitle,
        entry.value,
      );
    }
  });

  testWidgets(
      'settings screen navigates and scrolls between sections with D-pad',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      GoRoute(path: '/subscriptions', builder: (_, __) => const Text('OPENED')),
    ]);
    addTearDown(router.dispose);
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tvModeNotifierProvider.overrideWithValue(tvMode),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        activeSubscriptionProvider.overrideWith((ref) => null),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final first = find.text('User profiles');
    final second = find.text('Xtream/M3U subscriptions');
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(find.text('Language, PIN'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
    final l = lookupAppLocalizations(const Locale('en'));
    for (final entry in {
      l.sectionAccessibility: 'assets/icons/settings-accessibility.png',
      l.settingsActivateApp: 'assets/icons/settings-activate.png',
      l.resetApp: 'assets/icons/settings-reset.png',
      l.accountPreferences: 'assets/icons/settings-preferences.png',
      l.sectionBackup: 'assets/icons/settings-backup.png',
      l.settingsContact: 'assets/icons/settings-contact.png',
    }.entries) {
      final tile = find
          .ancestor(
            of: find.text(entry.key),
            matching: find.byType(TvFocus),
          )
          .first;
      final image = tester.widget<Image>(
        find.descendant(of: tile, matching: find.byType(Image)),
      );
      expect((image.image as AssetImage).assetName, entry.value);
    }
    for (final title in [l.legalNotice, l.clearCaches]) {
      final tile = find
          .ancestor(
            of: find.text(title),
            matching: find.byType(TvFocus),
          )
          .first;
      expect(find.descendant(of: tile, matching: find.byType(Image)),
          findsNothing);
      expect(
          find.descendant(of: tile, matching: find.byType(Icon)), findsNothing);
    }
    for (final title in [
      l.sectionAccountProfile,
      l.sectionDiagnostics,
    ]) {
      expect(find.byKey(ValueKey('settings-group-$title')), findsOneWidget);
    }
    expect(find.byKey(ValueKey('settings-group-${l.sectionAccessibility}')),
        findsNothing);
    expect(
        find.byKey(ValueKey('settings-group-${l.tabNetwork}')), findsNothing);
    final accountGroup =
        find.byKey(ValueKey('settings-group-${l.sectionAccountProfile}'));
    final diagnosticGroup =
        find.byKey(ValueKey('settings-group-${l.sectionDiagnostics}'));
    expect(
        tester.getRect(accountGroup).top, tester.getRect(diagnosticGroup).top);
    expect(
        find.descendant(
            of: diagnosticGroup, matching: find.text(l.enginesTile)),
        findsOneWidget);
    expect(
        find.descendant(
            of: diagnosticGroup, matching: find.text(l.sectionBackup)),
        findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TvFocus>(),
      same(tester.element(first).findAncestorWidgetOfExactType<TvFocus>()),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TvFocus>(),
      same(tester.element(second).findAncestorWidgetOfExactType<TvFocus>()),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('OPENED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(640, 360), const Size(960, 540)]) {
    for (final language in ['en', 'ar']) {
      testWidgets('D-pad returns from the bottom on TV at $size in $language',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final controller = TvModeController();
        await controller.updateFromDetection(const DeviceDetectionResult(
          deviceType: DeviceType.tv,
          isTv: true,
          confidence: 1,
        ));
        addTearDown(controller.dispose);
        final tvMode = TvModeNotifier(controller);
        addTearDown(tvMode.dispose);
        final router = GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
        ]);
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            tvModeControllerProvider.overrideWithValue(controller),
            tvModeNotifierProvider.overrideWithValue(tvMode),
            deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
            activeSubscriptionProvider.overrideWith((ref) => null),
            currentProfileProvider.overrideWithBuild((ref, notifier) => null),
          ],
          child: MaterialApp.router(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ));
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(language));
        final groups = [
          l.sectionAccountProfile,
          l.sectionDiagnostics,
        ]
            .map((title) => find.byKey(ValueKey('settings-group-$title')))
            .toList();
        final top = groups
            .map((group) => tester.getRect(group).top)
            .reduce((a, b) => a < b ? a : b);
        final firstRow = <Widget>{};
        for (final group
            in groups.where((group) => tester.getRect(group).top < top + 2)) {
          final tiles = find
              .descendant(of: group, matching: find.byType(TvFocus))
              .evaluate()
              .map((element) => element.widget)
              .toList();
          final firstTileTop = tiles
              .map((tile) => tester.getRect(find.byWidget(tile)).top)
              .reduce((a, b) => a < b ? a : b);
          firstRow.addAll(tiles.where((tile) =>
              tester.getRect(find.byWidget(tile)).top < firstTileTop + 2));
        }
        final starts = [
          find.text(l.sectionBackup),
          find.text(l.legalNotice),
          find.text(l.sectionAccessibility),
          find.text(l.resetApp),
          find.text(l.settingsContact),
          find.text(l.settingsActivateApp),
          find.byKey(const ValueKey('hidden-advanced-entry')),
        ];
        for (final start in starts) {
          final tile =
              find.ancestor(of: start, matching: find.byType(TvFocus)).first;
          await tester.ensureVisible(tile);
          Focus.of(tester.element(find
                  .descendant(of: tile, matching: find.byType(AnimatedBuilder))
                  .first))
              .requestFocus();
          await tester.pumpAndSettle();
          for (var i = 0; i < 20; i++) {
            final focused = FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<TvFocus>();
            if (firstRow.contains(focused)) break;
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
            await tester.pumpAndSettle();
          }
          final currentTile = FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<TvFocus>();
          final labels = currentTile == null
              ? <String?>[]
              : tester
                  .widgetList<Text>(find.descendant(
                    of: find.byWidget(currentTile),
                    matching: find.byType(Text),
                  ))
                  .map((text) => text.data)
                  .toList();
          expect(
            firstRow,
            contains(currentTile),
            reason: 'Failed to navigate up from $start, focus=$labels',
          );
          final focusedContext = FocusManager.instance.primaryFocus!.context!;
          final viewport = tester.getRect(find
              .descendant(
                of: find.byType(TvSafeArea),
                matching: find.byType(SingleChildScrollView),
              )
              .first);
          final focusedRect =
              tester.getRect(find.byWidget(focusedContext.widget));
          expect(focusedRect.top, greaterThanOrEqualTo(viewport.top),
              reason:
                  'start=$start focus=$labels focused=$focusedRect viewport=$viewport '
                  'tile=${tester.getRect(find.byWidget(currentTile!))} '
                  'label=${tester.getRect(find.text(labels.first!))}');
          if (focusedRect.height <= viewport.height) {
            expect(focusedRect.bottom, lessThanOrEqualTo(viewport.bottom));
          }
        }
      });
    }
  }

  testWidgets('empty advanced icon requires the existing access code',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedSettingsScreen()),
      GoRoute(
        path: '/settings/advanced',
        builder: (_, __) => const Scaffold(body: Text('ADVANCED OPENED')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        activeSubscriptionProvider.overrideWith((ref) => null),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('hidden-advanced-entry'));
    var decoration =
        tester.widget<Container>(entry).decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    expect(decoration.border, isNull);
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text(
        lookupAppLocalizations(const Locale('en')).advancedAccessConfirm));
    await tester.pumpAndSettle();
    expect(find.text('ADVANCED OPENED'), findsNothing);
    final entryFocus = find.ancestor(of: entry, matching: find.byType(TvFocus));
    Focus.of(tester.element(find
            .descendant(of: entryFocus, matching: find.byType(AnimatedBuilder))
            .first))
        .requestFocus();
    await tester.pumpAndSettle();
    decoration = tester.widget<Container>(entry).decoration! as BoxDecoration;
    expect(decoration.color!.a, lessThan(0.1));
    expect((decoration.border! as Border).top.color.a, lessThan(0.25));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), kAdvancedSettingsCode);
    await tester.tap(find.text(
        lookupAppLocalizations(const Locale('en')).advancedAccessConfirm));
    await tester.pumpAndSettle();
    expect(find.text('ADVANCED OPENED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('D-pad moves between settings and activates each once',
      (tester) async {
    var first = false;
    var second = false;
    var firstCalls = 0;
    var secondCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  TvFocus(
                    autofocus: true,
                    onActivate: () => setState(() {
                      first = !first;
                      firstCalls++;
                    }),
                    child: SettingsSwitchTile(
                      title: 'First setting',
                      subtitle: '',
                      value: first,
                      onChanged: (value) => setState(() {
                        first = value;
                        firstCalls++;
                      }),
                    ),
                  ),
                  TvFocus(
                    onActivate: () => setState(() {
                      second = !second;
                      secondCalls++;
                    }),
                    child: SettingsSwitchTile(
                      title: 'Second setting',
                      subtitle: '',
                      value: second,
                      onChanged: (value) => setState(() {
                        second = value;
                        secondCalls++;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(first, isTrue);
    expect(firstCalls, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(second, isTrue);
    expect(secondCalls, 1);
    expect(firstCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
