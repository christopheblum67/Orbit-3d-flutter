class Series {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final int year;
  final String genre;
  final String director;
  final double rating;
  final String pegi;
  final List<Episode> episodes;

  Series({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.year,
    required this.genre,
    required this.director,
    required this.rating,
    required this.pegi,
    required this.episodes,
  });

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      coverUrl: map['cover'] ?? '',
      year: map['year'] ?? 0,
      genre: map['genre'] ?? '',
      director: map['director'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      pegi: map['pegi'] ?? '',
      episodes: (map['episodes'] as List<dynamic>? ?? [])
          .map((e) => Episode.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Episode {
  final String id;
  final String title;
  final int season;
  final int episodeNumber;
  final String streamUrl;

  Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNumber,
    required this.streamUrl,
  });

  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      season: map['season'] ?? 0,
      episodeNumber: map['episode'] ?? 0,
      streamUrl: map['url'] ?? '',
    );
  }
}
