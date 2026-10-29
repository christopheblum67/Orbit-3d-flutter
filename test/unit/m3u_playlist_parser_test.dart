import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';

void main() {
  group('M3uPlaylistParser', () {
    test('sépare les chaînes, films et épisodes d’une playlist mixte', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="France",TF1
https://provider.example/live/tf1
#EXTINF:-1 group-title="Radios France",France Inter
https://provider.example/radio/france-inter
#EXTINF:-1 group-title="VOD, Movies",Le film (2021)
https://provider.example/movie/film.mp4
#EXTINF:-1 group-title="Series",Ma série S01.E02 Le pilote
https://provider.example/series/episode-2.mkv
#EXTINF:-1 group-title="Series",Ma série S01E01 Début
https://provider.example/series/episode-1.mkv
#EXTINF:-1 group-title="France",Contenu ambigu
https://provider.example/other/item
''';

      final playlist = M3uPlaylistParser.parse(content);

      expect(
        playlist.channels.map((item) => item.name),
        ['TF1', 'Contenu ambigu'],
      );
      expect(playlist.radios.map((item) => item.name), ['France Inter']);
      expect(playlist.movies, hasLength(1));
      expect(playlist.movies.single.title, 'Le film');
      expect(playlist.movies.single.year, 2021);
      expect(
        playlist.movies.single.streamUrl,
        'https://provider.example/movie/film.mp4',
      );
      expect(playlist.series, hasLength(1));
      expect(playlist.series.single.title, 'Ma série');
      expect(
        playlist.series.single.episodes
            .map((episode) => episode.episodeNumber)
            .toList(),
        [1, 2],
      );
      expect(playlist.series.single.episodes.first.title, 'Début');
    });

    test('utilise les types explicites et les extensions de film', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-type="movie",Film sans catégorie
https://provider.example/films/film.mkv
#EXTINF:-1 content-type="series",Série 1x03 Épisode
https://provider.example/series/episode.ts
''';

      final playlist = M3uPlaylistParser.parse(content);

      expect(playlist.movies, hasLength(1));
      expect(playlist.series, hasLength(1));
      expect(playlist.series.single.title, 'Série');
      expect(playlist.series.single.episodes.single.season, 1);
      expect(playlist.series.single.episodes.single.episodeNumber, 3);
    });

    test('regroupe les épisodes avec les libellés de saison français', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="Séries",Une série Saison 2 Épisode 03 - Finale
https://provider.example/series/finale.mp4
#EXTINF:-1 group-title="Séries",Une série Season 1 Episode 2 - Retour
https://provider.example/series/retour.mp4
''';

      final series = M3uPlaylistParser.parse(content).series.single;

      expect(series.title, 'Une série');
      expect(
        series.episodes
            .map((episode) => (episode.season, episode.episodeNumber)),
        [(1, 2), (2, 3)],
      );
      expect(series.episodes.first.title, 'Retour');
      expect(
        series.episodes.last.streamUrl,
        'https://provider.example/series/finale.mp4',
      );
    });

    test('utilise les attributs de saison et épisode sans motif dans le titre',
        () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="Séries" series-name="Ma série" season="2" episode="4" episode-title="La révélation",Chapitre spécial
https://provider.example/series/episode-4.mp4
''';

      final series = M3uPlaylistParser.parse(content).series.single;
      final episode = series.episodes.single;

      expect(series.title, 'Ma série');
      expect(episode.season, 2);
      expect(episode.episodeNumber, 4);
      expect(episode.title, 'La révélation');
    });

    test('priorise le groupe série sur un type vidéo générique', () {
      const content = '''
#EXTM3U
#EXTINF:-1 content-type="video" group-title="Series",Une série S01E02 Épisode
https://provider.example/series/episode-2.mp4
''';

      final playlist = M3uPlaylistParser.parse(content);

      expect(playlist.movies, isEmpty);
      expect(playlist.series, hasLength(1));
      expect(playlist.series.single.title, 'Une série');
      expect(playlist.series.single.episodes.single.episodeNumber, 2);
    });

    test('classe aussi les médias via les groupes EXTGRP', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Un film (2022)
#EXTGRP:Films
https://provider.example/movie/film
#EXTINF:-1,Une série S01E01 Pilote
#EXTGRP:Séries
https://provider.example/series/episode.mp4
''';

      final playlist = M3uPlaylistParser.parse(content);

      expect(playlist.movies.map((movie) => movie.title), ['Un film']);
      expect(playlist.series.map((series) => series.title), ['Une série']);
    });

    test('reconnaît les chemins Xtream movie et series', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Un film (2022)
https://provider.example/movie/user/pass/123.mp4
#EXTINF:-1,Une série S01E01 Pilote
https://provider.example/series/user/pass/456.mp4
''';

      final playlist = M3uPlaylistParser.parse(content);

      expect(playlist.movies, hasLength(1));
      expect(playlist.series, hasLength(1));
      expect(playlist.channels, isEmpty);
    });

    test('classe un titre daté sous une catégorie VOD de genre', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="Nouveautés",Tenzing (2026)
https://provider.example/content/842
''';

      final movie = M3uPlaylistParser.parse(content).movies.single;

      expect(movie.title, 'Tenzing');
      expect(movie.year, 2026);
      expect(movie.categoryId, 'Nouveautés');
    });

    test('sépare les stations radio typées des chaînes TV', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-type="radio" group-title="Audio",Station sans groupe radio
https://provider.example/radio/explicit
#EXTINF:-1 group-title="Musique",Station via groupe
https://provider.example/radio/group
#EXTINF:-1 group-title="France",Chaîne TV
https://provider.example/live/tv
''';

      final playlist = M3uPlaylistParser.parse(content);

      expect(playlist.radios.map((radio) => radio.name), [
        'Station sans groupe radio',
        'Station via groupe',
      ]);
      expect(playlist.channels.map((channel) => channel.name), ['Chaîne TV']);
    });

    test('conserve le nom affiché plutôt que tvg-name pour le direct', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-name="TF1.fr" tvg-id="tf1" group-title="France",TF1 HD
https://provider.example/live/tf1
''';

      final channel = M3uPlaylistParser.parse(content).channels.single;

      expect(channel.name, 'TF1 HD');
      expect(channel.epgChannelId, 'tf1');
    });

    test('rejette les URL de flux vides ou invalides', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="France",Chaîne invalide
not-a-stream-url
''';

      expect(
        () => M3uPlaylistParser.parse(content),
        throwsA(isA<Exception>()),
      );
    });
  });
}
