import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/video_error_state.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';

void main() {
  testWidgets('provider website action is explicit and user-triggered',
      (tester) async {
    var opened = false;
    final l = AppLocalizationsFr();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VideoErrorState(
            title: l.cloudflareCheckRequired,
            message: l.cloudflareChallengeHelp,
            onProviderWebsite: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text(l.openProviderWebsite), findsOneWidget);
    expect(find.textContaining('La session du navigateur'), findsOneWidget);
    expect(opened, isFalse);

    await tester.tap(find.text(l.openProviderWebsite));
    expect(opened, isTrue);
  });
}
