/// Utilitaire d'agrégation des épisodes VOD par série.
///
/// Regroupe les flux dont le nom contient un motif saison/épisode
/// (S01E01, 1x01, Saison 1 Ep 2, ...) sous un nom de série normalisé,
/// puis trie les épisodes par saison puis par épisode.
class SeriesAggregator {
  SeriesAggregator._();

  // Motifs courants : S01E01, S1E1, 1x01, Saison 1 Ep 2, Season 2 Episode 3, ...
  static final RegExp _seasonEpisodeRegex = RegExp(
    r'(.*?)\s*[\(\[\s\-]*(?:saison|season|s)?\s*(\d{1,2})\s*[\._\s]*(?:e|ep|episode|x)\s*(\d{1,2})',
    caseSensitive: false,
  );

  /// Extrait (nomSerie, saison, episode) d'un titre, ou null si non détecté.
  static ({String name, int season, int episode})? parse(String title) {
    final match = _seasonEpisodeRegex.firstMatch(title.trim());
    if (match == null) return null;
    final name = (match.group(1) ?? title).trim();
    final season = int.tryParse(match.group(2) ?? '1') ?? 1;
    final episode = int.tryParse(match.group(3) ?? '1') ?? 1;
    if (name.isEmpty) return null;
    return (name: name, season: season, episode: episode);
  }

  /// Regroupe une liste plate de titres par nom de série normalisé.
  /// Les entrées sans motif saison/épisode sont placées sous '__MOVIES__'.
  static Map<String, List<({String title, int season, int episode})>> group(
    Iterable<String> titles,
  ) {
    final map = <String, List<({String title, int season, int episode})>>{};
    for (final t in titles) {
      final parsed = parse(t);
      if (parsed == null) {
        map.putIfAbsent('__MOVIES__', () => []).add(
              (title: t, season: 0, episode: 0),
            );
      } else {
        map.putIfAbsent(parsed.name, () => []).add(
              (title: t, season: parsed.season, episode: parsed.episode),
            );
      }
    }
    // Trie les épisodes de chaque série par saison puis épisode.
    for (final entry in map.entries) {
      if (entry.key != '__MOVIES__') {
        entry.value.sort((a, b) {
          if (a.season != b.season) return a.season.compareTo(b.season);
          return a.episode.compareTo(b.episode);
        });
      }
    }
    return map;
  }
}