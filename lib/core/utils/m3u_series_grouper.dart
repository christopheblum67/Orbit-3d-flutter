import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/series.dart';

/// Regroupe une liste plate de chaînes M3U (épisodes) en objets [Series]
/// structurés, à la manière du traitement Xtream Codes des séries.
///
/// Chaque entrée dont le nom porte un motif saison/épisode
/// (`S01E01`, `S1E1`, `Saison 1`, `1x01`, …) est rattachée à sa série ;
/// les entrées sans motif deviennent des séries mono-épisode.
class M3uSeriesGrouper {
  M3uSeriesGrouper._();

  /// Motifs : `S01E01`, `S1E1`, `Saison 1`, `Season 2`, `1x01`, …
  static final RegExp _seasonEpisodeRegex = RegExp(
    r'(.*?)(?:\b|_)(?:saison\s*(\d+)|s(\d+)[\s\-]*e(\d+)|(\d+)x(\d+))',
    caseSensitive: false,
  );

  /// Regroupe les flux M3U en séries, triées par saison puis par épisode.
  static List<Series> groupChannelsIntoSeries(List<Channel> channels) {
    final seriesMap = <String, List<Episode>>{};

    for (final channel in channels) {
      final rawName = channel.name;
      final match = _seasonEpisodeRegex.firstMatch(rawName);

      String seriesTitle;
      int seasonNumber = 1;
      int episodeNumber = 1;

      if (match != null) {
        seriesTitle = (match.group(1) ?? rawName)
            .replaceAll(RegExp(r'[\.\-_]+$'), '')
            .trim();

        if (match.group(2) != null) {
          // `Saison 1 …` (nom du groupe capturé par la regex)
          seasonNumber = int.tryParse(match.group(2)!) ?? 1;
        } else if (match.group(3) != null) {
          // `S01E05 …`
          seasonNumber = int.tryParse(match.group(3)!) ?? 1;
          episodeNumber = int.tryParse(match.group(4)!) ?? 1;
        } else if (match.group(5) != null) {
          // `1x05 …`
          seasonNumber = int.tryParse(match.group(5)!) ?? 1;
          episodeNumber = int.tryParse(match.group(6)!) ?? 1;
        }
      } else {
        // Aucun motif SxxExx : la chaîne devient une série mono-épisode.
        seriesTitle = rawName;
      }

      final key = seriesTitle.toLowerCase();
      seriesMap.putIfAbsent(key, () => <Episode>[]);
      seriesMap[key]!.add(
        Episode(
          id: channel.id,
          title: channel.name,
          season: seasonNumber,
          episodeNumber: episodeNumber,
          streamUrl: channel.streamUrl,
        ),
      );
    }

    final series = <Series>[];
    for (final entry in seriesMap.entries) {
      final episodes = [...entry.value]
        ..sort((a, b) {
          if (a.season != b.season) return a.season.compareTo(b.season);
          return a.episodeNumber.compareTo(b.episodeNumber);
        });
      if (episodes.isEmpty) continue;

      final title = entry.key;
      var firstLogo = '';
      for (final c in channels) {
        if (c.name.toLowerCase().contains(title)) {
          firstLogo = c.logoUrl;
          break;
        }
      }

      series.add(
        Series(
          id: title.hashCode.toString(),
          title: title,
          description:
              'Série importée via M3U (${episodes.length} épisodes)',
          coverUrl: firstLogo,
          year: 0,
          genre: 'Séries M3U',
          director: '',
          rating: 0.0,
          pegi: '',
          episodes: episodes,
          categoryId: 'm3u_series',
        ),
      );
    }

    return series;
  }
}
