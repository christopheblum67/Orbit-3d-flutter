import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/series/series_detail_screen.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a fallback language can be selected when no track is detected',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeriesSubtitleLanguageSelector(
              seriesId: 'series1',
              fetchTracks: () async => [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucune piste détectée'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français').last);
    await tester.pumpAndSettle();

    expect(await PlayerTrackPrefs.seriesSubtitleLanguageFor('series1'), 'fr');
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNotNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(await PlayerTrackPrefs.isSeriesSubtitleForced('series1'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores a saved language not present in detected tracks',
      (tester) async {
    await PlayerTrackPrefs.setSeriesSubtitleLanguage('series2', 'fr');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeriesSubtitleLanguageSelector(
              seriesId: 'series2',
              fetchTracks: () async => [('English (CC)', 'English (CC)')],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('fr'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNotNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('English (CC)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the selector with the keyboard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeriesSubtitleLanguageSelector(
              seriesId: 'series3',
              fetchTracks: () async => [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Français'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
