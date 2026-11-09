import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';

class PlaybackHistoryEntry {
  const PlaybackHistoryEntry({
    required this.type,
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.subtitle,
    required this.streamUrl,
  });

  final ContentType type;
  final String id;
  final String title;
  final String posterUrl;
  final String subtitle;
  final String streamUrl;
}

PlaybackHistoryEntry? playbackHistoryEntry({
  required Channel? channel,
  required FavoriteEntry? favorite,
  required String fallbackStreamUrl,
}) {
  if (channel != null) {
    return PlaybackHistoryEntry(
      type: ContentType.live,
      id: channel.id,
      title: channel.name,
      posterUrl: channel.logoUrl,
      subtitle: channel.groupLabel,
      streamUrl: channel.streamUrl,
    );
  }
  if (favorite == null) return null;
  return PlaybackHistoryEntry(
    type: favorite.type,
    id: favorite.id,
    title: favorite.title,
    posterUrl: favorite.posterUrl,
    subtitle: favorite.subtitle,
    streamUrl:
        favorite.streamUrl.isEmpty ? fallbackStreamUrl : favorite.streamUrl,
  );
}

/// Lance les deux écritures indépendamment sans bloquer la lecture.
Future<void> writePlaybackHistory({
  required PlaybackHistoryEntry entry,
  required Future<void> Function(PlaybackHistoryEntry) writeRecent,
  required Future<void> Function(PlaybackHistoryEntry) writeHistory,
}) async {
  final recent = safeAsync<void>(
    () => writeRecent(entry),
    context: 'playbackHistory.recent',
  );
  final history = safeAsync<void>(
    () => writeHistory(entry),
    context: 'playbackHistory.history',
  );
  await Future.wait([recent, history]);
}
