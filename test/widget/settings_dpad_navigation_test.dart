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
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
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
