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
  });
}