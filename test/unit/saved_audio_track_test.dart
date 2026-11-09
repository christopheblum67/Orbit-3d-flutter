import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/saved_audio_track.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class _Controller implements VideoPlayerController {
  _Controller(this.tracks);

  final Future<List<VideoAudioTrack>> Function() tracks;
  final selected = <String>[];
  int queries = 0;

  @override
  Future<List<VideoAudioTrack>> getAudioTracks() {
    queries++;
    return tracks();
  }

  @override
  Future<void> selectAudioTrack(String id) async => selected.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const tracks = [
    VideoAudioTrack(
      id: 'en',
      label: 'English',
      language: 'en',
      isSelected: true,
    ),
    VideoAudioTrack(
      id: 'fr',
      label: 'Français',
      language: 'fr',
      isSelected: false,
    ),
  ];

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('episode preference has priority over series language', () async {
    await PlayerTrackPrefs.setAudioTrack('episode', 'en');
    await PlayerTrackPrefs.setSeriesAudioLanguage('series', 'FR');
    final controller = _Controller(() async => tracks);
    await applySavedAudioTrack(
      controller: controller,
      mediaKey: 'episode',
      seriesId: 'series',
      isCurrent: () => true,
    );
    expect(controller.selected, ['en']);
  });

  test('series language matches without case sensitivity', () async {
    await PlayerTrackPrefs.setSeriesAudioLanguage('series', 'FR');
    final controller = _Controller(() async => tracks);
    await applySavedAudioTrack(
      controller: controller,
      mediaKey: 'episode',
      seriesId: 'series',
      isCurrent: () => true,
    );
    expect(controller.selected, ['fr']);
  });

  test('empty preference prevents querying the player', () async {
    await PlayerTrackPrefs.setAudioTrack('episode', '');
    final controller = _Controller(() async => tracks);
    await applySavedAudioTrack(
      controller: controller,
      mediaKey: 'episode',
      seriesId: 'series',
      isCurrent: () => true,
    );
    expect(controller.queries, 0);
    expect(controller.selected, isEmpty);
  });

  test('unknown tracks and unavailable forced languages are not selected',
      () async {
    await PlayerTrackPrefs.setAudioTrack('episode', 'missing');
    final controller = _Controller(() async => tracks);
    await applySavedAudioTrack(
      controller: controller,
      mediaKey: 'episode',
      seriesId: 'series',
      isCurrent: () => true,
    );
    await PlayerTrackPrefs.clearAudioTrack('episode');
    await PlayerTrackPrefs.setSeriesAudioForced('series', true);
    await PlayerTrackPrefs.setSeriesAudioLanguage('series', 'de');
    await applySavedAudioTrack(
      controller: controller,
      mediaKey: 'episode',
      seriesId: 'series',
      isCurrent: () => true,
    );
    expect(controller.selected, isEmpty);
  });

  test('a stale player cannot select a track after discovery', () async {
    await PlayerTrackPrefs.setAudioTrack('episode', 'fr');
    final result = Completer<List<VideoAudioTrack>>();
    final started = Completer<void>();
    final controller = _Controller(() {
      started.complete();
      return result.future;
    });
    var current = true;
    final pending = applySavedAudioTrack(
      controller: controller,
      mediaKey: 'episode',
      seriesId: 'series',
      isCurrent: () => current,
    );
    await started.future;
    current = false;
    result.complete(tracks);
    await pending;
    expect(controller.selected, isEmpty);
  });
}
