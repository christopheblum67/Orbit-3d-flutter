import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/onboarding/onboarding_screen.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _Storage extends StorageService {
  final settings = <String, dynamic>{};

  @override
  Future<void> setSetting(String key, dynamic value) async {
    settings[key] = value;
  }
}

void main() {
  testWidgets('onboarding uses the selected language', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingConfigScreen(),
      ),
    ));
    expect(find.text('Welcome to Orbit IPTV'), findsOneWidget);
    expect(find.text('Adjust manually'), findsNothing);
    expect(find.text('Analyzing device…'), findsOneWidget);
  });

  testWidgets('device profile can be selected immediately and saved',
      (tester) async {
    final storage = _Storage();
    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingConfigScreen(),
      ),
      GoRoute(
        path: '/startup',
        builder: (_, __) => const Scaffold(body: Text('Started')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        deviceHardwareDetectionProvider
            .overrideWithValue(() async => const HardwareSpecs(
                  deviceName: 'Test',
                  brand: 'Test',
                  isTv: false,
                  isPhysicalDevice: true,
                  totalRamMb: 4096,
                  lowRam: false,
                  sdkInt: 30,
                  connection: ConnectionKind.wifi,
                  recommendedProfile: DeviceProfile.standard,
                )),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    final l = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l.onboardingChooseProfile), findsOneWidget);
    expect(find.text(l.onboardingAdjust), findsNothing);
    expect(find.text(l.onboardingProfile('Standard')), findsOneWidget);
    final ultra = find.text(l.onboardingProfile('Ultra'));
    await tester.ensureVisible(ultra);
    await tester.tap(ultra);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.confirmAndContinue));
    await tester.pumpAndSettle();
    expect(storage.settings['device_profile'], 'ultra');
    expect(storage.settings['onboarding_done'], isTrue);
    expect(find.text('Started'), findsOneWidget);
  });
}
