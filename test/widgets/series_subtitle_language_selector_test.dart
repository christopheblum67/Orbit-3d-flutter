import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/series/series_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestApp extends MaterialApp {
  _TestApp({required super.home, Locale locale = const Locale('fr')})
      : super(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('subtitle fallback and guidance follow the interface language',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: _TestApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SeriesSubtitleLanguageSelector(
            seriesId: 'english',
            fetchTracks: () async => [],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Default subtitle language'), findsOneWidget);
    expect(find.textContaining('No tracks detected'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('French'), findsOneWidget);
    expect(find.text('Français'), findsNothing);
    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    expect(find.text('Apply if available'), findsOneWidget);
    expect(await PlayerTrackPrefs.seriesSubtitleLanguageFor('english'), 'fr');
  });

  for (final subtitles in [false, true]) {
    testWidgets(
        'selection hint is compact for ${subtitles ? 'subtitles' : 'audio'}',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: _TestApp(
          home: Scaffold(
            body: subtitles
                ? SeriesSubtitleLanguageSelector(
                    seriesId: 'hint',
                    fetchTracks: () async => [],
                  )
                : SeriesAudioLanguageSelector(
                    seriesId: 'hint',
                    fetchTracks: () async => [],
                  ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final field = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(field.decoration.hintText, 'Sélectionner une langue');
      expect(field.decoration.hintStyle?.fontSize, 12);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'menu and selected language are compact for ${subtitles ? 'subtitles' : 'audio'}',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: _TestApp(
          home: Scaffold(
            body: subtitles
                ? SeriesSubtitleLanguageSelector(
                    seriesId: 'compact',
                    fetchTracks: () async => [('fr', 'Français')],
                  )
                : SeriesAudioLanguageSelector(
                    seriesId: 'compact',
                    fetchTracks: () async => [('fr', 'Français')],
                  ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      final option = find.text('Français').last;
      final optionStyle = DefaultTextStyle.of(tester.element(option))
          .style
          .merge(tester.widget<Text>(option).style);
      expect(optionStyle.fontSize, 12);

      await tester.tap(option);
      await tester.pumpAndSettle();
      final selected = find.text('Français');
      final selectedStyle = DefaultTextStyle.of(tester.element(selected))
          .style
          .merge(tester.widget<Text>(selected).style);
      expect(selectedStyle.fontSize, 12);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a fallback language can be selected when no track is detected',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: _TestApp(
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
        child: _TestApp(
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
        child: _TestApp(
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
          child: _TestApp(
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
          child: _TestApp(
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

  for (final width in [360.0, 260.0]) {
    for (final subtitles in [false, true]) {
      testWidgets(
          'track preferences adapt to width $width, subtitles: $subtitles',
          (tester) async {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(
          child: _TestApp(
            home: Scaffold(
              body: subtitles
                  ? SeriesSubtitleLanguageSelector(
                      seriesId: 'layout',
                      fetchTracks: () async => [('fr', 'Français')],
                    )
                  : SeriesAudioLanguageSelector(
                      seriesId: 'layout',
                      fetchTracks: () async => [('fr', 'Français')],
                    ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final dropdown =
            tester.getRect(find.byType(DropdownButtonFormField<String>));
        final checkbox = tester.getRect(find.byType(Checkbox));
        if (width >= 320) {
          expect(checkbox.left, greaterThan(dropdown.right));
          expect(checkbox.top, lessThan(dropdown.bottom));
        } else {
          expect(checkbox.top, greaterThanOrEqualTo(dropdown.bottom));
        }
      });
    }
  }

  testWidgets('long track labels fit with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final label = 'Français sous-titrage malentendant version longue';
    await PlayerTrackPrefs.setSeriesSubtitleLanguage('long', label);
    await tester.pumpWidget(ProviderScope(
      child: _TestApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: SeriesSubtitleLanguageSelector(
              seriesId: 'long',
              fetchTracks: () async => [(label, label)],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
