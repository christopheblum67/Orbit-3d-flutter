import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/new_content.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_compact.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_compact.dart';

void main() {
  test('new badge expires exactly 72 hours after addition', () {
    final now = DateTime.utc(2026, 11, 9, 12);
    expect(isRecentlyAdded(null, now: now), isFalse);
    expect(isRecentlyAdded(now.add(const Duration(seconds: 1)), now: now),
        isFalse);
    expect(isRecentlyAdded(now, now: now), isTrue);
    expect(
      isRecentlyAdded(
        now.subtract(const Duration(days: 3)).add(const Duration(microseconds: 1)),
        now: now,
      ),
      isTrue,
    );
    expect(isRecentlyAdded(now.subtract(const Duration(days: 3)), now: now),
        isFalse);
  });

  test('full, compact and recommendation models share the same rule', () {
    for (final age in [const Duration(days: 2), const Duration(days: 4)]) {
      final added = DateTime.now().subtract(age);
      final movie = Movie(
        id: 'm', title: 'Film', description: '', posterUrl: '', year: 0,
        genre: '', director: '', rating: 0, pegi: '', streamId: '',
        addedDate: added,
      );
      final series = Series(
        id: 's', title: 'Série', description: '', coverUrl: '', year: 0,
        genre: '', director: '', rating: 0, pegi: '', episodes: const [],
        addedDate: added,
      );
      final expected = age.inDays == 2;
      expect(movie.isNew, expected);
      expect(series.isNew, expected);
      expect(MovieCompact.fromMovie(movie).isNew, expected);
      expect(SeriesCompact.fromSeries(series).isNew, expected);
      expect(Recommendation(kind: RecommendationKind.movie, movie: movie).isNew,
          expected);
      expect(Recommendation(kind: RecommendationKind.series, series: series).isNew,
          expected);
    }
  });
}
