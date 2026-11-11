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

  testWidgets('disabled can be forced and restored', (tester) async {
    Widget selector() => ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SeriesSubtitleLanguageSelector(
                seriesId: 'disabled',
                fetchTracks: () async => [],
              ),
            ),
          ),
        );
    await tester.pumpWidget(selector());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('(Désactivés)').last);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNotNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(await PlayerTrackPrefs.seriesSubtitleLanguageFor('disabled'), '');
    expect(await PlayerTrackPrefs.isSeriesSubtitleForced('disabled'), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(selector());
    await tester.pumpAndSettle();
    expect(find.text('(Désactivés)'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('stream default audio can be forced and restored',
      (tester) async {
    Widget selector() => ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SeriesAudioLanguageSelector(
                seriesId: 'default',
                fetchTracks: () async => [],
              ),
            ),
          ),
        );
    await tester.pumpWidget(selector());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('(Défaut du flux)').last);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNotNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(await PlayerTrackPrefs.seriesAudioLanguageFor('default'), '');
    expect(await PlayerTrackPrefs.isSeriesAudioForced('default'), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(selector());
    await tester.pumpAndSettle();
    expect(find.text('(Défaut du flux)'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}
