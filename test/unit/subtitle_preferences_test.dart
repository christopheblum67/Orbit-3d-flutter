import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/subtitle_preferences.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Subtitles extends SubtitleController {
  int revision = 0;
  final actions = <String>[];
  List<EmbeddedSubtitleTrack> tracks = [];
  Completer<void>? selection;
  Completer<void>? selectionStarted;

  @override
  int get manualSelectionRevision => revision;

  @override
  List<EmbeddedSubtitleTrack> get embeddedTracks => tracks;

  @override
  Future<void> selectEmbeddedTrack(String id,
      {bool userInitiated = true}) async {
    actions.add('select:$id:$userInitiated');
    selectionStarted?.complete();
    await selection?.future;
  }

  @override
  void disable({bool userInitiated = true}) =>
      actions.add('disable:$userInitiated');

  @override
  void disableEmbedded({bool userInitiated = true}) =>
      actions.add('disableEmbedded:$userInitiated');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const forced = EmbeddedSubtitleTrack(
    id: 'forced',
    label: 'Français forced',
    language: 'fr',
    isSelected: false,
    isForced: true,
    mimeType: null,
  );
  const full = EmbeddedSubtitleTrack(
    id: 'full',
    label: 'Français',
    language: 'fr',
    isSelected: false,
    isForced: false,
    mimeType: null,
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('forced-only waits for tracks and then selects once', () async {
    final prefs = SubtitlePreferences();
    final controller = _Subtitles();
    addTearDown(controller.dispose);
    prefs.startScan(controller);
    Future<void> apply(List<EmbeddedSubtitleTrack> tracks) => prefs.applyVod(
          controller: controller,
          tracks: tracks,
          contentType: PlaybackContentType.vod,
          generation: 1,
          readMode: () => VodSubtitleMode.forcedOnly,
          isCurrent: () => true,
        );
    await apply([]);
    await apply([forced]);
    await apply([forced]);
    expect(
        controller.actions, ['disableEmbedded:false', 'select:forced:false']);
  });

  test('manual selection after scan blocks automatic VOD selection', () async {
    final prefs = SubtitlePreferences();
    final controller = _Subtitles();
    addTearDown(controller.dispose);
    prefs.startScan(controller);
    controller.revision++;
    await prefs.applyVod(
      controller: controller,
      tracks: [forced],
      contentType: PlaybackContentType.vod,
      generation: 1,
      readMode: () => VodSubtitleMode.forcedOnly,
      isCurrent: () => true,
    );
    expect(controller.actions, isEmpty);
  });

  test('series preference waits for a match and applies once per generation',
      () async {
    await PlayerTrackPrefs.setSeriesSubtitleLanguage('series', 'fr');
    final prefs = SubtitlePreferences();
    final controller = _Subtitles();
    addTearDown(controller.dispose);
    Future<void> apply(int generation) => prefs.applySeries(
          controller: controller,
          seriesId: 'series',
          generation: generation,
          isCurrent: () => true,
        );
    await apply(1);
    controller.tracks = [forced, full];
    await apply(1);
    await apply(1);
    await apply(2);
    expect(controller.actions, ['select:full:false', 'select:full:false']);
  });

  test('stale series selection does not mark generation as applied', () async {
    await PlayerTrackPrefs.setSeriesSubtitleLanguage('series', 'fr');
    final prefs = SubtitlePreferences();
    final controller = _Subtitles()..tracks = [full];
    addTearDown(controller.dispose);
    final pendingSelection = Completer<void>();
    controller.selection = pendingSelection;
    final started = Completer<void>();
    controller.selectionStarted = started;
    var current = true;
    final pending = prefs.applySeries(
      controller: controller,
      seriesId: 'series',
      generation: 1,
      isCurrent: () => current,
    );
    await started.future;
    current = false;
    pendingSelection.complete();
    await pending;
    controller.selection = null;
    controller.selectionStarted = null;
    current = true;
    await prefs.applySeries(
      controller: controller,
      seriesId: 'series',
      generation: 1,
      isCurrent: () => current,
    );
    expect(controller.actions, ['select:full:false', 'select:full:false']);
  });
}
