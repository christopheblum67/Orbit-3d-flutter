import 'package:orbit_3d_flutter/models/series.dart';

Episode? nextPlayableEpisode(Series series, Episode current) {
  final episodes = series.episodes.where((e) => e.season > 0 && e.episodeNumber > 0).toList()
    ..sort((a, b) {
      final season = a.season.compareTo(b.season);
      return season != 0 ? season : a.episodeNumber.compareTo(b.episodeNumber);
    });
  final index = episodes.indexWhere((e) => e.id == current.id &&
      e.season == current.season && e.episodeNumber == current.episodeNumber);
  if (index < 0 || index + 1 >= episodes.length) return null;
  final next = episodes[index + 1];
  return next.streamUrl.isEmpty ? null : next;
}
