import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Nettoyage du nom d'épisode avant une recherche texte chez OpenSubtitles.
///
/// Les panels servent des noms de release bruts, formats pour un lecteur, pas
/// pour un index. Envoyés tels quels à `query`, ils ne matchent rien : le
/// message affiché est alors « aucun resultat », indiscernable d'un media
/// absent de la base.
///
/// La suite fige les formes vues sur le panel de test, dont le titre reel qui a
/// fait echouer la premiere tentative.
void main() {
  group('nettoyage du titre de recherche', () {
    test('nom de release du panel de test', () {
      expect(
        OpenSubtitlesService.cleanSearchTitle(
          '|FR| Monstre : L\'histoire de Lizzie Borden 01x02 '
          '- Une chatte tenace (MULTI)',
        ),
        'Monstre : L\'histoire de Lizzie Borden - Une chatte tenace',
      );
    });

    test('retire le marqueur de diffusion et les metadonnees', () {
      expect(
        OpenSubtitlesService.cleanSearchTitle('|VF| The Office US S03E12 1080p'),
        'The Office US',
      );
    });

    test('retire S01E02 comme 1x02', () {
      expect(
        OpenSubtitlesService.cleanSearchTitle('Breaking Bad S01E02'),
        'Breaking Bad',
      );
      expect(
        OpenSubtitlesService.cleanSearchTitle('Breaking Bad 1x02'),
        'Breaking Bad',
      );
    });

    test('conserve le titre d\'episode, qui affine la recherche', () {
      // C'est le sous-titre de l'episode (« Une chatte tenace ») : le garder
      // rend la requete plus precise, pas moins. Seul le numero est du bruit,
      // puisqu'il est deja transmis en season_number / episode_number.
      final cleaned = OpenSubtitlesService.cleanSearchTitle(
        'Monstre 01x02 - Une chatte tenace',
      );
      expect(cleaned, 'Monstre - Une chatte tenace');
    });

    test('conserve l\'annee, seul element discriminant restant', () {
      expect(
        OpenSubtitlesService.cleanSearchTitle('Blade Runner (1982) 1080p'),
        contains('1982'),
      );
    });

    test('retire les marqueurs techniques', () {
      final cleaned = OpenSubtitlesService.cleanSearchTitle(
        'Dune 2021 2160p WEB-DL x265 HDR VOSTFR',
      );
      expect(cleaned, 'Dune 2021');
    });

    test('un mot unique est rejete : trop ambigu', () {
      // « Dune » seul ramènerait tous les contenus homonymes ; l'utilisateur
      // lirait ça comme un bug plutot que comme une recherche.
      expect(OpenSubtitlesService.cleanSearchTitle('|FR| Dune (MULTI)'), '');
    });

    test('une chaine vide reste vide', () {
      expect(OpenSubtitlesService.cleanSearchTitle('   '), '');
      expect(OpenSubtitlesService.cleanSearchTitle(''), '');
    });
  });
}
