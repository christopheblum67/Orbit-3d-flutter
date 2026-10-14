import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlayerTrackPrefs', () {
    test('returns null when nothing saved', () async {
      final result = await PlayerTrackPrefs.audioTrackFor('movie-42');
      expect(result, isNull);
    });

    test('persists and reloads the chosen audio track', () async {
      await PlayerTrackPrefs.setAudioTrack('movie-42', '0_1');
      final result = await PlayerTrackPrefs.audioTrackFor('movie-42');
      expect(result, '0_1');
    });

    test('keeps distinct tracks per media', () async {
      await PlayerTrackPrefs.setAudioTrack('movie-1', '0_0');
      await PlayerTrackPrefs.setAudioTrack('movie-2', '0_2');
      expect(await PlayerTrackPrefs.audioTrackFor('movie-1'), '0_0');
      expect(await PlayerTrackPrefs.audioTrackFor('movie-2'), '0_2');
    });

    test('clearAudioTrack oublie la piste mémorisée (« Aucun »)', () async {
      // Sans cet oubli, la piste serait ré-appliquée à la lecture suivante et
      // réactiverait l'audio que l'utilisateur venait de couper.
      await PlayerTrackPrefs.setAudioTrack('movie-42', '0_1');
      await PlayerTrackPrefs.clearAudioTrack('movie-42');
      expect(await PlayerTrackPrefs.audioTrackFor('movie-42'), isNull);
    });

    test('clearAudioTrack n\'affecte pas un autre contenu', () async {
      await PlayerTrackPrefs.setAudioTrack('movie-1', '0_0');
      await PlayerTrackPrefs.setAudioTrack('movie-2', '0_2');
      await PlayerTrackPrefs.clearAudioTrack('movie-1');
      expect(await PlayerTrackPrefs.audioTrackFor('movie-1'), isNull);
      expect(await PlayerTrackPrefs.audioTrackFor('movie-2'), '0_2');
    });
  });

  group('PlayerTrackPrefs — sous-titres de série', () {
    test('aucune préférence par défaut', () async {
      expect(
        await PlayerTrackPrefs.seriesSubtitleLanguageFor('serie-7'),
        isNull,
      );
      expect(await PlayerTrackPrefs.isSeriesSubtitleForced('serie-7'), isFalse);
    });

    test('mémorise et relit la langue de sous-titres', () async {
      await PlayerTrackPrefs.setSeriesSubtitleLanguage('serie-7', 'fr');
      expect(await PlayerTrackPrefs.seriesSubtitleLanguageFor('serie-7'), 'fr');
    });

    test('mémorise le caractère forcé', () async {
      await PlayerTrackPrefs.setSeriesSubtitleForced('serie-7', true);
      expect(await PlayerTrackPrefs.isSeriesSubtitleForced('serie-7'), isTrue);
    });

    test('les préférences de sous-titres sont indépendantes de l\'audio',
        () async {
      // Une même série peut avoir une langue audio ET une langue de
      // sous-titres distinctes : les clés ne doivent pas se marcher dessus.
      await PlayerTrackPrefs.setSeriesAudioLanguage('serie-7', 'en');
      await PlayerTrackPrefs.setSeriesSubtitleLanguage('serie-7', 'fr');
      expect(await PlayerTrackPrefs.seriesAudioLanguageFor('serie-7'), 'en');
      expect(await PlayerTrackPrefs.seriesSubtitleLanguageFor('serie-7'), 'fr');
    });

    test('isole les préférences par série', () async {
      await PlayerTrackPrefs.setSeriesSubtitleLanguage('serie-1', 'fr');
      await PlayerTrackPrefs.setSeriesSubtitleLanguage('serie-2', 'de');
      expect(await PlayerTrackPrefs.seriesSubtitleLanguageFor('serie-1'), 'fr');
      expect(await PlayerTrackPrefs.seriesSubtitleLanguageFor('serie-2'), 'de');
    });

    test('clearSeriesSubtitlePreference efface langue ET caractère forcé',
        () async {
      await PlayerTrackPrefs.setSeriesSubtitleLanguage('serie-7', 'fr');
      await PlayerTrackPrefs.setSeriesSubtitleForced('serie-7', true);

      await PlayerTrackPrefs.clearSeriesSubtitlePreference('serie-7');

      expect(
        await PlayerTrackPrefs.seriesSubtitleLanguageFor('serie-7'),
        isNull,
      );
      expect(await PlayerTrackPrefs.isSeriesSubtitleForced('serie-7'), isFalse);
    });
  });
}
