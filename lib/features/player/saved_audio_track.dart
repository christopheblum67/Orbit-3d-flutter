import 'package:collection/collection.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:video_player/video_player.dart';

/// Réapplique la piste mémorisée uniquement si le lecteur est toujours actif.
Future<void> applySavedAudioTrack({
  required VideoPlayerController controller,
  required String mediaKey,
  required String? seriesId,
  required bool Function() isCurrent,
}) async {
  await safeAsync(
    () async {
      final pref = await PlayerTrackPrefs.audioTrackFor(mediaKey);
      if (pref != null && pref.isEmpty) return;

      if (!isCurrent()) return;
      final tracks = await controller.getAudioTracks();
      if (tracks.isEmpty) return;

      var trackIdToApply = pref;
      if (trackIdToApply == null && seriesId != null) {
        final forced = await PlayerTrackPrefs.isSeriesAudioForced(seriesId);
        final lang = await PlayerTrackPrefs.seriesAudioLanguageFor(seriesId);
        if (lang != null && lang.isNotEmpty) {
          final matchingTrack = tracks.firstWhereOrNull(
            (t) =>
                t.language != null &&
                t.language!.toLowerCase() == lang.toLowerCase(),
          );
          if (matchingTrack != null) {
            trackIdToApply = matchingTrack.id;
          } else if (!forced) {
            return;
          }
        }
      }

      if (trackIdToApply == null || !isCurrent()) return;
      if (!tracks.any((t) => t.id == trackIdToApply)) return;
      await controller.selectAudioTrack(trackIdToApply);
    },
    context: '_applySavedAudioTrack',
  );
}
