import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';

/// Les panels divergent sur la forme ET sur l'emplacement de leurs déclarations
/// de sous-titres. Aucun standard ne les impose, et tous ne se ressemblent pas :
/// sur le panel testé, `get_series_info` n'expose rien à la racine et porte les
/// pistes dans les objets ÉPISODE.
///
/// On couvre donc les deux voies : lire la déclaration où qu'elle soit, puis
/// synthétiser l'URL par convention à partir du stream id de l'épisode lu.
void main() {
  const context = SubtitleDiscoveryContext(
    baseUrl: 'http://panel.example:8080',
    username: 'user',
    password: 'pass',
    streamId: '54321',
  );

  group('collectLanguageCodes — emplacements des déclarations', () {
    test('à la racine', () {
      final codes = SubtitleDiscovery.collectLanguageCodes({
        'subtitles': ['fr', 'en'],
      });
      expect(codes, {'fr', 'en'});
    });

    test('dans info', () {
      final codes = SubtitleDiscovery.collectLanguageCodes({
        'info': {
          'subtitles': ['fre'],
        },
      });
      expect(codes, {'fre'});
    });

    test('dans les objets épisode d\'une série', () {
      // L'emplacement réel du panel testé.
      final codes = SubtitleDiscovery.collectLanguageCodes({
        'seasons': [
          {
            'episodes': [
              {
                'id': '31519_1_1',
                'title': 'Chapitre 1',
                'subtitles': ['fr', 'en'],
              },
              {
                'id': '31519_1_2',
                'title': 'Chapitre 2',
                'subtitles': ['fr'],
              },
            ],
          },
        ],
      });
      expect(codes, {'fr', 'en'});
    });

    test('CHAQUE épisode est lu, pas seulement le premier', () {
      // Régression : le compteur était un BUDGET d'appels et non une
      // profondeur d'imbrication. Il était incrémenté mais jamais
      // décrémenté, donc après six appels la lecture s'arrêtait — et sur une
      // série, seul le premier épisode était examiné.
      //
      // Le test voisin « dans les objets épisode » ne le voyait pas : son
      // premier épisode déclarait déjà les deux codes attendus, donc l'union
      // tombait juste malgré la lecture tronquée.
      final codes = SubtitleDiscovery.collectLanguageCodes({
        'seasons': [
          {
            'episodes': [
              {
                'id': '1',
                'title': 'Chapitre 1',
                'subtitles': ['fr'],
              },
              {
                'id': '2',
                'title': 'Chapitre 2',
                'subtitle_tracks': ['en'],
              },
              {
                'id': '3',
                'title': 'Chapitre 3',
                'subs': ['de'],
              },
            ],
          },
        ],
      });
      expect(codes, {'fr', 'en', 'de'},
          reason: 'les trois épisodes doivent être lus');
    });

    test('la lecture survit à un info racine réaliste', () {
      // Forme réellement renvoyée par `get_series_info` : un bloc `info` avec
      // de nombreuses clés scalaires AVANT les épisodes. Le bug rendait la
      // profondeur épuisée par les seules clés de `info`, et aucun épisode
      // n'était atteint.
      final codes = SubtitleDiscovery.collectLanguageCodes({
        'info': {
          'name': 'Série',
          'cover': 'http://x/cover.jpg',
          'plot': 'Un résumé.',
          'genre': 'Drame',
          'releaseDate': '2024-01-01',
          'backdrop_path': ['http://x/1.jpg', 'http://x/2.jpg'],
          'cast': ['Acteur Un', 'Acteur Deux'],
          'director': 'Un réalisateur',
        },
        'seasons': [
          {
            'season_number': 1,
            'episodes': [
              {
                'id': '10',
                'title': 'Épisode 1',
                'subtitles': ['fr'],
              },
              {
                'id': '11',
                'title': 'Épisode 2',
                'subtitles': ['en'],
              },
            ],
          },
        ],
      });
      expect(codes, {'fr', 'en'});
    });

    test('une profondeur excessive est bien bornée', () {
      // Garde-fou contre une correction sans borne : une structure
      // pathologique ne doit pas faire planter la découverte.
      Object? node = 'fr';
      for (var i = 0; i < 40; i++) {
        node = {'subtitles': node};
      }
      expect(() => SubtitleDiscovery.collectLanguageCodes(node), returnsNormally);
    });
    test('sous une clé alternative (subs, subtitle_tracks)', () {
      expect(
        SubtitleDiscovery.collectLanguageCodes({
          'subs': ['de'],
        }),
        {'de'},
      );
      expect(
        SubtitleDiscovery.collectLanguageCodes({
          'subtitle_tracks': ['it'],
        }),
        {'it'},
      );
    });

    test('liste d\'objets : le champ lang est lu', () {
      final codes = SubtitleDiscovery.collectLanguageCodes({
        'subtitles': [
          {'lang': 'fr', 'name': 'Français'},
          {'lang': 'en', 'name': 'English'},
        ],
      });
      expect(codes, {'fr', 'en'});
    });

    test('une valeur seule, pas une liste', () {
      expect(
        SubtitleDiscovery.collectLanguageCodes({
          'subtitle': 'nl',
        }),
        {'nl'},
      );
    });

    test('une URL est écartée : ce n\'est pas un code langue', () {
      // Une piste déjà adressable n'a pas à être re-synthétisée, et la valeur
      // n'est pas un code.
      expect(
        SubtitleDiscovery.collectLanguageCodes({
          'subtitles': ['http://panel.example/subtitles/u/p/1_fr.srt'],
        }),
        isEmpty,
      );
    });

    test('aucune déclaration : renvoie vide', () {
      expect(
        SubtitleDiscovery.collectLanguageCodes({
          'info': {'name': 'Une série', 'seasons': []},
        }),
        isEmpty,
      );
    });

    test('null ou vide : renvoie vide sans lever', () {
      expect(SubtitleDiscovery.collectLanguageCodes(null), isEmpty);
      expect(SubtitleDiscovery.collectLanguageCodes({}), isEmpty);
    });
  });

  group('synthesizeFromConvention', () {
    test('construit une URL par langue, avec le stream id de l\'épisode', () {
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: context,
        languages: ['fr', 'en'],
      );
      expect(tracks, hasLength(2));
      expect(
        tracks.first.url,
        'http://panel.example:8080/subtitles/user/pass/54321_fr.srt',
      );
      expect(tracks.last.url.endsWith('54321_en.srt'), isTrue);
    });

    test('les libellés sont lisibles', () {
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: context,
        languages: ['fr'],
      );
      expect(tracks.single.label, isNotEmpty);
      expect(tracks.single.label, isNot(contains('54321')));
    });

    test('sans stream id : aucune piste plutôt qu\'une fausse', () {
      // Une piste construite sur un identifiant vide pointerait vers un autre
      // média : mieux vaut ne rien proposer.
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: const SubtitleDiscoveryContext(
          baseUrl: 'http://panel.example',
          username: 'u',
          password: 'p',
        ),
        languages: ['fr'],
      );
      expect(tracks, isEmpty);
    });

    test('les doublons de langue sont écartés', () {
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: context,
        languages: ['fr', 'FR', ' fr '],
      );
      expect(tracks, hasLength(1));
    });

    test('aucune langue : aucune piste', () {
      expect(
        SubtitleDiscovery.synthesizeFromConvention(
          context: context,
          languages: const [],
        ),
        isEmpty,
      );
    });
  });
}
