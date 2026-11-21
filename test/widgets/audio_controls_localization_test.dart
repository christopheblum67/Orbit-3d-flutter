import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('audio controls are localized', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AudioControlsSheet()),
      ),
    ));
    await tester.pump();
    expect(find.text('Night optimization (Night Focus)'), findsOneWidget);
    expect(find.text('Dialogue boost'), findsOneWidget);
    expect(find.text('Bass reduction and limiter'), findsOneWidget);
  });
}
