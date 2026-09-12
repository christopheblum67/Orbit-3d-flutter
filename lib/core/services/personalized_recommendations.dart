import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/startup_recommendation.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';

/// Moteur de recommandations personnalisées, local et sans dépendance externe.
///
/// Classe les films et séries de la bibliothèque en fonction des genres
/// favoris du profil connecté, de la note et d'un léger facteur de nouveauté.
/// Il est conçu pour l'écran de démarrage : aucune clé API ni latence réseau
/// (hors fetch des flux déjà effectué par StartupRefreshController).
class PersonalizedRecommendations {
  final List<String> favoriteGenres;

  PersonalizedRecommendations({required this.favoriteGenres});

  /// Recommande environ [count] contenus (films, séries, radio, replay entrelacés).
  List<StartupRecommendation> build({
    required List<Movie> movies,
    required List<Series> series,
    List<Channel> radios = const [],
    List<ReplayItem> replays = const [],
    required List<String> watchedTitles,
    int count = 12,
  }) {
    final genref = favoriteGenres
        .map((g) => g.trim().toLowerCase())
        .where((g) => g.isNotEmpty)
        .toSet();

    final scoredMovies = <_Scored>[];
    for (final movie in movies) {
      if (watchedTitles.contains(movie.title.toLowerCase())) continue;
      final score = _score(movie.title, movie.genre, movie.rating, movie.year);
      scoredMovies.add(_Scored(score, movie: movie));
    }

    final scoredSeries = <_Scored>[];
    for (final s in series) {
      if (watchedTitles.contains(s.title.toLowerCase())) continue;
      final score = _score(s.title, s.genre, s.rating, s.year);
      scoredSeries.add(_Scored(score, series: s));
    }

    final scoredRadios = <_Scored>[];
    for (final r in radios) {
      if (watchedTitles.contains(r.name.toLowerCase())) continue;
      final score = _scoreRadio(r);
      scoredRadios.add(_Scored(score, radio: r));
    }

    final scoredReplays = <_Scored>[];
    for (final rp in replays) {
      if (watchedTitles.contains(rp.title.toLowerCase())) continue;
      final score = _scoreReplay(rp);
      scoredReplays.add(_Scored(score, replay: rp));
    }

    _rankDesc(scoredMovies);
    _rankDesc(scoredSeries);
    _rankDesc(scoredRadios);
    _rankDesc(scoredReplays);

    final result = <StartupRecommendation>[];
    var mi = 0, si = 0, ri = 0, rpi = 0;
    final pools = <List<_Scored>>[
      scoredMovies,
      scoredSeries,
      scoredRadios,
      scoredReplays,
    ];
    var poolIndex = 0;
    while (result.length < count) {
      bool added = false;
      for (var p = 0; p < pools.length; p++) {
        final pool = pools[(poolIndex + p) % pools.length];
        final idx = [mi, si, ri, rpi][(poolIndex + p) % pools.length];
        if (idx < pool.length) {
          final scored = pool[idx];
          switch ((poolIndex + p) % pools.length) {
            case 0:
              mi++;
              result.add(StartupRecommendation.fromMovie(
                scored.movie!,
                _reasonForMovie(scored.movie!, genref),
              ),);
              break;
            case 1:
              si++;
              result.add(StartupRecommendation.fromSeries(
                scored.series!,
                _reasonForSeries(scored.series!, genref),
              ),);
              break;
            case 2:
              ri++;
              result.add(StartupRecommendation.fromRadio(
                scored.radio!,
                'Station radio${scored.radio!.group.isNotEmpty ? " · ${scored.radio!.group}" : ""}',
              ),);
              break;
            case 3:
              rpi++;
              result.add(StartupRecommendation.fromReplay(
                scored.replay!.title,
                '', // ReplayItem n'a pas de posterUrl
                'Replay',
                scored.replay!.streamUrl,
                rating: 0,
                id: scored.replay!.id,
              ),);
              break;
          }
          added = true;
          break;
        }
      }
      if (!added) break;
      poolIndex = (poolIndex + 1) % pools.length;
    }
    return result;
  }

  int _scoreRadio(Channel radio) {
    var score = 20; // base pour radio
    if (radio.groupLabel.isNotEmpty) score += 10;
    if (radio.logoUrl.isNotEmpty) score += 5;
    return score;
  }

  int _scoreReplay(ReplayItem replay) {
    var score = 30; // base pour replay
    if (replay.title.isNotEmpty) score += 10;
    if (replay.streamUrl.isNotEmpty) score += 5;
    return score;
  }

  int _score(String title, String genre, double rating, int year) {
    var score = 0;
    if (genre.isNotEmpty && _genreHits(genre)) score += 60;
    if (rating > 0) score += (rating * 4).round().clamp(0, 48);
    final ageYears = DateTime.now().year - year;
    if (year > 0 && ageYears <= 2) score += 12;
    if (title.isEmpty) return -1000;
    return score;
  }

  bool _genreHits(String itemGenre) {
    final lower = itemGenre.toLowerCase();
    for (final g in favoriteGenres) {
      final lg = g.toLowerCase();
      if (lg.isEmpty) continue;
      if (lower.contains(lg) || lg.contains(lower)) return true;
    }
    return false;
  }

  String _reasonForMovie(Movie movie, Set<String> genref) {
    if (movie.genre.isNotEmpty && _genreHits(movie.genre)) {
      return 'Dans vos genres favoris (${movie.genre.split(',').first.trim()}).';
    }
    if (movie.rating >= 7) {
      return 'Noté ${movie.rating.toStringAsFixed(1)} sur vos goûts.';
    }
    return movie.year > 0
        ? 'Film de ${movie.year} à découvrir.'
        : 'Un film à découvrir.';
  }

  String _reasonForSeries(Series series, Set<String> genref) {
    if (series.genre.isNotEmpty && _genreHits(series.genre)) {
      return 'Série dans vos genres favoris (${series.genre.split(',').first.trim()}).';
    }
    if (series.rating >= 7) {
      return 'Série notée ${series.rating.toStringAsFixed(1)} sur vos goûts.';
    }
    return series.year > 0
        ? 'Série de ${series.year} à découvrir.'
        : 'Une série à découvrir.';
  }

  void _rankDesc(List<_Scored> list) {
    list.sort((a, b) => b.score.compareTo(a.score));
  }
}

class _Scored {
  final int score;
  final Movie? movie;
  final Series? series;
  final Channel? radio;
  final ReplayItem? replay;

  _Scored(this.score, {this.movie, this.series, this.radio, this.replay});
}
