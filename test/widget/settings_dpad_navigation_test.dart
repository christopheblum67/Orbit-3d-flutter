import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/features/settings/unified_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
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
      expect(tester.widget<Text>(find.text(l.accountProfilesSubtitle)).maxLines,
          isNull);
      await tester
          .ensureVisible(find.byKey(const ValueKey('hidden-advanced-entry')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

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
      await tester.ensureVisible(find.text(l.dnsProvider));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.dnsProvider));
      await tester.pumpAndSettle();
      expect(find.text(l.cloudflareReset), findsNothing);
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
      final audio = find.text('Audio & Night Focus');
      await tester.ensureVisible(audio);
      await tester.tap(audio);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      final memory = find.text('Memory & Cache');
      await tester.ensureVisible(memory);
      await tester.tap(memory);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Accessibility').last);
      await tester.tap(find.text('Accessibility').last);
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
    await tester.ensureVisible(find.text('DNS provider (DoH)'));
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
    expect(tileFocus(find.text('Player').first).hasFocus, isTrue);
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
    expect(tileFocus(find.text('Player').first).hasFocus, isTrue);
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
    expect(find.text('Language, PIN'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
    final l = lookupAppLocalizations(const Locale('en'));
    for (final title in [
      l.sectionAccountProfile,
      l.sectionBackup,
      l.tabNetwork,
      l.tabPlayer,
      l.sectionRecommendations,
      l.sectionDiagnostics,
    ]) {
      expect(find.byKey(ValueKey('settings-group-$title')), findsOneWidget);
    }
    expect(find.byKey(ValueKey('settings-group-${l.sectionAccessibility}')),
        findsNothing);
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
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final dns = find.text('DNS provider (DoH)');
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TvFocus>(),
      same(tester.element(dns).findAncestorWidgetOfExactType<TvFocus>()),
    );
    expect(
      tester.getRect(dns).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(TvSafeArea)).bottom),
    );
    for (var i = 0; i < 10; i++) {
      if (FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<TvFocus>() ==
          tester.element(first).findAncestorWidgetOfExactType<TvFocus>()) {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TvFocus>(),
      same(tester.element(first).findAncestorWidgetOfExactType<TvFocus>()),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('OPENED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
