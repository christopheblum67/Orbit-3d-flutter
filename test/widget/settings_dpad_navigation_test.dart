import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/settings/unified_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
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
    testWidgets('network card is localized and editable in $language',
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
      final tab = find.text('${l.tabNetwork} & ${l.tabSecurity}');
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.dnsProvider));
      await tester.pumpAndSettle();
      expect(find.text(l.cloudflareReset), findsOneWidget);
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
      tester.view.physicalSize = size;
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
      await tester.ensureVisible(find.text('Player & Audio'));
      await tester.tap(find.text('Player & Audio'));
      await tester.pumpAndSettle();
      final audio = find.text('Audio & Night Focus');
      await tester.ensureVisible(audio);
      await tester.tap(audio);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
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
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      final memory = find.text('Memory & Cache');
      await tester.ensureVisible(memory);
      await tester.tap(memory);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Advanced'));
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Accessibility'));
      await tester.tap(find.text('Accessibility'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(container.read(advancedSettingsProvider).highContrast, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('subtitle checkbox works by D-pad and touch', (tester) async {
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
    await tester.tap(find.text('Network & Security'));
    await tester.pumpAndSettle();

    FocusNode tileFocus(Finder content) {
      final tile =
          find.ancestor(of: content, matching: find.byType(TvFocus)).first;
      return Focus.of(tester.element(find
          .descendant(
            of: tile,
            matching: find.byType(AnimatedBuilder),
          )
          .first));
    }

    tileFocus(find.text('DNS provider (DoH)')).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(tileFocus(find.text('Player')).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    final checkbox = find.byType(CheckboxListTile);
    expect(checkbox, findsOneWidget);
    expect(
        find.text(
            'Automatically disable subtitles when starting a movie or series'),
        findsOneWidget);
    expect(find.text('Force no subtitles'), findsNothing);
    expect(tileFocus(checkbox).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isTrue);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tileFocus(find.text('Player')).hasFocus, isTrue);
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

  testWidgets('settings screen navigates account tiles and tabs with D-pad',
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
    expect(find.text('Language, PIN'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(
      Focus.of(tester.element(find.text('Account'))).hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      Focus.of(tester.element(find.text('Network & Security'))).hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(first, findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(first, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
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
