import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Paramètres de `/subtitles`, verrouillés sur les règles de la documentation.
///
/// La régression la plus coûteuse du chantier : `season_number` et
/// `episode_number` envoyés avec un simple `query`. L'API ne signale pas
/// l'erreur, elle ignore la combinaison et répond 0 résultat — une recherche
/// qui ne vise plus rien, indiscernable d'un épisode absent de la base.
void main() {
  group('paramètres de recherche', () {
    test('sans identifiant parent, saison et episode sont retires', () {
      final params = OpenSubtitlesService.buildSearchParams(
        cleanedTitle: 'Monstre : Lizzie Borden',
        seasonNumber: 1,
        episodeNumber: 2,
      );
      expect(params.containsKey('season_number'), isFalse,
          reason: 'ignoré par l\'API sans parent_imdb_id ni parent_tmdb_id',);
      expect(params.containsKey('episode_number'), isFalse);
      expect(params['query'], 'monstre : lizzie borden');
    });

    test('avec un identifiant, saison et episode partent', () {
      final params = OpenSubtitlesService.buildSearchParams(
        tmdbId: 102379,
        seasonNumber: 1,
        episodeNumber: 2,
      );
      expect(params['tmdb_id'], '102379');
      expect(params['season_number'], '1');
      expect(params['episode_number'], '2');
    });

    test('la requete part en minuscules', () {
      // L'index compare sensiblement à la casse : en majuscules, la recherche
      // ne matchait rien.
      final params = OpenSubtitlesService.buildSearchParams(
        cleanedTitle: 'The Office US',
      );
      expect(params['query'], 'the office us');
    });

    test('les langues sont toujours envoyees', () {
      final params = OpenSubtitlesService.buildSearchParams(
        cleanedTitle: 'Dune',
      );
      expect(params['languages'], 'fr,en');
    });

    test('un titre vide ne produit pas de query', () {
      final params = OpenSubtitlesService.buildSearchParams(cleanedTitle: '   ');
      expect(params.containsKey('query'), isFalse);
    });
  });
}
