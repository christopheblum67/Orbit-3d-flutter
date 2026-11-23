import 'package:collection/collection.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';

/// Applique les préférences automatiques sans reprendre une sélection manuelle.
class SubtitlePreferences {
  int _seriesGeneration = -1;
  int _vodGeneration = -1;
  int _manualRevisionAtScan = 0;

  void startScan(SubtitleController controller) {
    _vodGeneration = -1;
    _manualRevisionAtScan = controller.manualSelectionRevision;
  }

  Future<void> applyAutomatic({
    required SubtitleController controller,
    required List<EmbeddedSubtitleTrack> tracks,
    required PlaybackContentType contentType,
    required int generation,
    required bool Function() readForceNoSubtitles,
    required VodSubtitleMode Function() readMode,
    required String? seriesId,
    required bool Function() isCurrent,
  }) async {
    bool forceOff() => _applyForcedOff(
          controller: controller,
          contentType: contentType,
          forceNoSubtitles:
              readForceNoSubtitles() || readMode() == VodSubtitleMode.disabled,
        );
    if (!isCurrent() || forceOff()) return;
    await applyVod(
      controller: controller,
      tracks: tracks,
      contentType: contentType,
      generation: generation,
      readMode: readMode,
      isCurrent: isCurrent,
    );
    if (!isCurrent() || forceOff()) return;
    await applySeries(
      controller: controller,
      seriesId: seriesId,
      generation: generation,
      isCurrent: isCurrent,
    );
    if (isCurrent()) forceOff();
  }

  /// Force-off wins over automatic preferences, but not a later manual choice.
  bool _applyForcedOff({
    required SubtitleController controller,
    required PlaybackContentType contentType,
    required bool forceNoSubtitles,
  }) {
    if (!forceNoSubtitles ||
        (contentType != PlaybackContentType.vod &&
            contentType != PlaybackContentType.series)) {
      return false;
    }
    if (controller.manualSelectionRevision == _manualRevisionAtScan) {
      controller.disable(userInitiated: false);
    }
    return true;
  }

  Future<void> applyVod({
    required SubtitleController controller,
    required List<EmbeddedSubtitleTrack> tracks,
    required PlaybackContentType contentType,
    required int generation,
    required VodSubtitleMode Function() readMode,
    required bool Function() isCurrent,
  }) async {
    if (contentType != PlaybackContentType.vod &&
            contentType != PlaybackContentType.series ||
        _vodGeneration == generation) {
      return;
    }

    if (controller.manualSelectionRevision != _manualRevisionAtScan) {
      _vodGeneration = generation;
      return;
    }

    final mode = readMode();
    if (mode == VodSubtitleMode.defaultSelection) {
      _vodGeneration = generation;
      return;
    }
    if (mode == VodSubtitleMode.disabled) {
      controller.disable(userInitiated: false);
      return;
    }
    final forced = tracks.firstWhereOrNull((track) => track.isForced);
    if (forced == null) {
      controller.disableEmbedded(userInitiated: false);
      return;
    }
    await controller.selectEmbeddedTrack(forced.id, userInitiated: false);
    if (isCurrent()) _vodGeneration = generation;
  }

  Future<void> applySeries({
    required SubtitleController controller,
    required String? seriesId,
    required int generation,
    required bool Function() isCurrent,
  }) async {
    if (seriesId == null ||
        controller.manualSelectionRevision != _manualRevisionAtScan) {
      return;
    }
    final preference =
        await PlayerTrackPrefs.seriesSubtitleLanguageFor(seriesId);
    if (preference == null ||
        !isCurrent() ||
        controller.manualSelectionRevision != _manualRevisionAtScan) {
      return;
    }
    if (preference.isEmpty) {
      controller.disable(userInitiated: false);
      return;
    }
    if (_seriesGeneration == generation) return;

    final track = pickEmbeddedSubtitleTrackForPreference(
      controller.embeddedTracks,
      preference,
    );
    if (track == null) return;
    await controller.selectEmbeddedTrack(track.id, userInitiated: false);
    if (isCurrent()) _seriesGeneration = generation;
  }
}
