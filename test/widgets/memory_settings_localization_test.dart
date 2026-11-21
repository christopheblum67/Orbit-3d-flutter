import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/memory_settings_panel.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('memory settings describe the scope of each action in English',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home:
            Scaffold(body: SingleChildScrollView(child: MemorySettingsPanel())),
      ),
    ));
    expect(find.text('Memory and cache'), findsOneWidget);
    expect(find.textContaining('global history'), findsOneWidget);
    expect(
        find.textContaining('cached files on disk are kept'), findsOneWidget);
  });
}
