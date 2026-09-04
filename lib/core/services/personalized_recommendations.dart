import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/startup_recommendation.dart';

/// Moteur de recommandations personnalisées, local et sans dépendance externe.
///
/// Classe les films et séries de la bibliothèque en fonction des genres
/// favoris du profil connecté, de la note et d'un léger facteur de nouveauté.
/// Il est conçu pour l'écran de démarrage : aucune clé API ni latence réseau
/// (hors fetch des flux déjà effectué par StartupRefreshController).
class PersonalizedRecommendations {
  final List<String> favoriteGenres;

  PersonalizedRecommendations({required this.favoriteGenres});

  /// Recomande environ [count] contenus (films + séries entrelacés).
  List<StartupRecommendation> build({
    required List<Movie> movies,
    required List<Series> series,
    required List<String> watchedTitles,
    int count = 8,
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

    _rankDesc(scoredMovies);
    _rankDesc(scoredSeries);

    final result = <StartupRecommendation>[];
    var mi = 0;
    var si = 0;
    while (result.length < count &&
        (mi < scoredMovies.length || si < scoredSeries.length)) {
      final useMovie = _pickNext(scoredMovies, mi, scoredSeries, si);
      if (useMovie && mi < scoredMovies.length) {
        final scored = scoredMovies[mi++];
        result.add(StartupRecommendation.fromMovie(
          scored.movie!,
          _reasonForMovie(scored.movie!, genref),
        ),);
      } else if (si < scoredSeries.length) {
        final scored = scoredSeries[si++];
        result.add(StartupRecommendation.fromSeries(
          scored.series!,
          _reasonForSeries(scored.series!, genref),
        ),);
      }
    }
    return result;
  }

  bool _pickNext(List<_Scored> movies, int mi, List<_Scored> series, int si) {
    if (mi >= movies.length) return false;
    if (si >= series.length) return true;
    // Intercale films/séries (alternance) pour un défilement varié.
    return (mi + si).isEven;
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

  _Scored(this.score, {this.movie, this.series});
}