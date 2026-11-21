import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/onboarding/onboarding_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

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
    expect(find.text('Adjust manually'), findsOneWidget);
    expect(find.text('Analyzing device…'), findsOneWidget);
  });
}
