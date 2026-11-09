import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/next_episode.dart';
import 'package:orbit_3d_flutter/models/series.dart';

void main() {
  Episode episode(int season, int number, {bool playable = true}) => Episode(
        id: '$season-$number',
        title: 'Episode $number',
        season: season,
        episodeNumber: number,
        streamUrl: playable ? 'https://example.test/video' : '',
      );
  Series series(List<Episode> episodes) => Series(
        id: 'series',
        title: 'Series',
        description: '',
        coverUrl: '',
        year: 0,
        genre: '',
        director: '',
        rating: 0,
        pegi: '',
        episodes: episodes,
      );
  test('finds next episode across seasons without skipping unavailable episodes', () {
    final first = episode(1, 1);
    final second = episode(1, 2);
    final third = episode(2, 1);
    final s = series([third, second, first]);
    expect(nextPlayableEpisode(s, first), same(second));
    expect(nextPlayableEpisode(s, second), same(third));
    expect(nextPlayableEpisode(s, third), isNull);
    final unavailable = episode(1, 2, playable: false);
    expect(nextPlayableEpisode(series([first, unavailable, third]), first), isNull);
  });
}
