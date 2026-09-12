/// Crédit de film d'une personne (filmographie)
class MovieCredit {
  final int tmdbId;
  final String title;
  final int year;
  final String character;
  final String posterPath;
  final double voteAverage;

  const MovieCredit({
    required this.tmdbId,
    required this.title,
    this.year = 0,
    this.character = '',
    this.posterPath = '',
    this.voteAverage = 0,
  });

  static const String _imageBase = 'https://image.tmdb.org/t/p';

  factory MovieCredit.fromTmdbJson(Map<String, dynamic> json) {
    return MovieCredit(
      tmdbId: json['id'] as int? ?? 0,
      title:
          json['title'] as String? ?? json['original_title'] as String? ?? '',
      year: _parseYear(json['release_date']),
      character: json['character'] as String? ?? '',
      posterPath: json['poster_path'] as String? ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
    );
  }

  String get posterUrl =>
      posterPath.isNotEmpty ? '$_imageBase/w342$posterPath' : '';

  static int _parseYear(String? date) {
    if (date == null || date.isEmpty) return 0;
    final match = RegExp(r'^(\d{4})').firstMatch(date);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}

/// Détail d'une personne TMDB (bio, notes, filmographie)
class PersonDetail {
  final int id;
  final String name;
  final String biography;
  final String birthday;
  final String deathday;
  final String placeOfBirth;
  final List<String> alsoKnownAs;
  final int gender;
  final double popularity;
  final String profilePath;
  final String knownForDepartment;
  final List<MovieCredit> knownFor;
  final List<MovieCredit> movieCredits;

  const PersonDetail({
    required this.id,
    required this.name,
    this.biography = '',
    this.birthday = '',
    this.deathday = '',
    this.placeOfBirth = '',
    this.alsoKnownAs = const [],
    this.gender = 0,
    this.popularity = 0,
    this.profilePath = '',
    this.knownForDepartment = '',
    this.knownFor = const [],
    this.movieCredits = const [],
  });

  static const String _imageBase = 'https://image.tmdb.org/t/p';

  factory PersonDetail.fromTmdbJson(
    Map<String, dynamic> json, {
    Map? creditsJson,
  }) {
    final knownFor = (json['known_for'] as List<dynamic>? ?? [])
        .map((k) => MovieCredit.fromTmdbJson(Map<String, dynamic>.from(k)))
        .toList();
    final credits = creditsJson ?? const <String, dynamic>{};
    final castCredits = (credits['cast'] as List<dynamic>? ?? [])
        .map((c) => MovieCredit.fromTmdbJson(Map<String, dynamic>.from(c)))
        .toList();
    final crewCredits = (credits['crew'] as List<dynamic>? ?? [])
        .map((c) => MovieCredit.fromTmdbJson(Map<String, dynamic>.from(c)))
        .toList();
    final seen = <int>{};
    final movieCredits = <MovieCredit>[];
    for (final credit in castCredits + crewCredits) {
      if (credit.tmdbId > 0 && seen.add(credit.tmdbId)) {
        movieCredits.add(credit);
      }
    }
    final fallbackKnownFor =
        knownFor.isNotEmpty ? knownFor : castCredits.take(20).toList();

    return PersonDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      biography: json['biography'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      deathday: json['deathday'] as String? ?? '',
      placeOfBirth: json['place_of_birth'] as String? ?? '',
      alsoKnownAs: (json['also_known_as'] as List<dynamic>? ?? [])
          .map((a) => a.toString())
          .toList(),
      gender: json['gender'] as int? ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      profilePath: json['profile_path'] as String? ?? '',
      knownForDepartment: json['known_for_department'] as String? ?? '',
      knownFor: fallbackKnownFor,
      movieCredits: movieCredits,
    );
  }

  String get profileUrl =>
      profilePath.isNotEmpty ? '$_imageBase/w500$profilePath' : '';

  String get genderLabel => switch (gender) {
        2 => 'Homme',
        1 => 'Femme',
        _ => '',
      };

  /// Année de naissance (affiché dans le header acteur)
  int get birthYear {
    final match = RegExp(r'^(\d{4})').firstMatch(birthday);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}
