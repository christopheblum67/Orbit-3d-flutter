import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/browse/browse_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('ranking labels and empty state follow the selected language',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flixPatrolMoviesProvider.overrideWith((ref) async => []),
          flixPatrolTvProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RankingsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Popular rankings'), findsOneWidget);
    expect(find.text('Now playing'), findsOneWidget);
    expect(find.text('Airing today'), findsOneWidget);
    expect(
      find.text(
        'TMDB trends are unavailable. Add a TMDB API key in Settings (or TMDB_API_KEY in assets/config/runtime.env).',
      ),
      findsNWidgets(2),
    );
  });
}
