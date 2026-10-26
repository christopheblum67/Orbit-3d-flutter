import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/navigation/initial_route.dart';
import 'package:orbit_3d_flutter/features/legal/legal_notice_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _MemorySettingsStorage extends StorageService {
  final Map<String, Object?> values = {};

  @override
  Object? getSetting(String key) => values[key];

  @override
  Future<void> setSetting(String key, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  testWidgets('first launch acceptance persists and opens onboarding',
      (tester) async {
    final storage = _MemorySettingsStorage();
    final router = GoRouter(
      initialLocation: initialRouteFor(
        onboardingDone: false,
        legalNoticeDone: false,
      ),
      routes: [
        GoRoute(
          path: '/legal',
          builder: (context, state) =>
              const LegalNoticeScreen(firstLaunch: true),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(
            body: Text('Onboarding'),
          ),
        ),
        GoRoute(
          path: '/startup',
          builder: (context, state) => const Scaffold(
            body: Text('Startup'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('J\'ai lu et j\'accepte · Continuer'), findsOneWidget);
    await tester.tap(find.text('J\'ai lu et j\'accepte · Continuer'));
    await tester.pumpAndSettle();

    expect(storage.values[kLegalNoticeDoneKey], isTrue);
    expect(find.text('Onboarding'), findsOneWidget);
  });
}
