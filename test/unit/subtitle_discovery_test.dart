import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';

void main() {
  const context = SubtitleDiscoveryContext(
    baseUrl: 'http://panel.example:8080',
    username: 'joe',
    password: 'secret',
    streamId: '1234',
  );

  group('SubtitleDiscovery — format code langue (le plus répandu)', () {
    // Format documenté des panels Xtream : une simple liste de codes, AUCUNE
    // URL. Sans synthèse, ces pistes étaient jetées et l'onglet affichait
    // « aucune piste disponible ».
    test('liste de codes langue synthétise une URL par piste', () {
      final tracks = SubtitleDiscovery.parse(
        {
          'info': {
            'subtitles': ['fre', 'eng', 'esp'],
            'container_extension': 'mkv',
          },
        },
        context: context,
      );

      expect(tracks, hasLength(3));
      expect(
        tracks.first.url,
        'http://panel.example:8080/subtitles/joe/secret/1234_fre.srt',
      );
      expect(tracks.map((t) => t.language), ['fre', 'eng', 'esp']);
      expect(tracks.first.label, 'Français');
      expect(tracks[1].label, 'Anglais');
    });

    test('accepte les noms de langue complets', () {
      final tracks = SubtitleDiscovery.parse(
        {
          'info': {
            'subtitles': ['French', 'German'],
          },
        },
        context: context,
      );
      expect(tracks, hasLength(2));
      expect(tracks.first.url, contains('1234_french.srt'));
      // Un nom de langue connu est traduit : l'app est localisée, et un
      // utilisateur francophone ne doit pas lire « French ».
      expect(tracks.first.label, 'Français');
      expect(tracks[1].label, 'Allemand');
    });

    test('sans contexte, une liste de codes ne produit aucune piste', () {
      // Sans `streamId`, on ne peut pas construire d'URL : mieux vaut vide
      // qu'une piste pointant sur un média arbitraire.
      final tracks = SubtitleDiscovery.parse({
        'info': {
          'subtitles': ['fre'],
        },
      });
      expect(tracks, isEmpty);
    });

    test('série sans stream id d\'épisode : aucune synthèse', () {
      final tracks = SubtitleDiscovery.parse(
        {
          'info': {
            'subtitles': ['fre'],
          },
        },
        context: const SubtitleDiscoveryContext(
          baseUrl: 'http://panel.example:8080',
          username: 'joe',
          password: 'secret',
          // series_id seul : insuffisant, la convention attend l'épisode.
        ),
      );
      expect(tracks, isEmpty);
    });
  });

  group('SubtitleDiscovery — URLs directes', () {
    test('liste d\'objets avec url/name (Xtream UI)', () {
      final tracks = SubtitleDiscovery.parse({
        'info': {
          'subtitles': [
            {'language': 'fre', 'file': 'http://cdn.example/1234_fr.srt'},
            {'language': 'eng', 'file': 'http://cdn.example/1234_en.srt'},
          ],
        },
      });
      expect(tracks, hasLength(2));
      expect(tracks.first.url, 'http://cdn.example/1234_fr.srt');
      expect(tracks.first.label, 'Français');
    });

    test('liste positionnelle [lang, label, url]', () {
      final tracks = SubtitleDiscovery.parse({
        'info': {
          'subtitles': [
            ['fre', 'Français', 'http://cdn.example/a.srt'],
          ],
        },
      });
      expect(tracks, hasLength(1));
      expect(tracks.first.label, 'Français');
      expect(tracks.first.url, 'http://cdn.example/a.srt');
    });

    test('chaîne d\'URL seule', () {
      final tracks = SubtitleDiscovery.parse({
        'info': {'subtitles': 'http://cdn.example/only_fr.srt'},
      });
      expect(tracks, hasLength(1));
      expect(tracks.first.language, 'fr');
    });

    test('chemin relatif résolu sur le panel', () {
      final tracks = SubtitleDiscovery.parse(
        {
          'info': {
            'subtitles': [
              {'language': 'fre', 'file': '1234_fr.srt'},
            ],
          },
        },
        context: context,
      );
      expect(tracks, hasLength(1));
      expect(
        tracks.first.url,
        'http://panel.example:8080/1234_fr.srt',
      );
    });
  });

  group('SubtitleDiscovery — tolérance', () {
    test('ne lève jamais sur une réponse vide ou bizarre', () {
      expect(SubtitleDiscovery.parse(null), isEmpty);
      expect(SubtitleDiscovery.parse({}), isEmpty);
      expect(SubtitleDiscovery.parse({'info': 'nope'}), isEmpty);
      expect(SubtitleDiscovery.parse({'info': {'subtitles': 42}}), isEmpty);
    });

    test('ignore les URLs de flux listées dans le même champ', () {
      // Garde-fou historique : un panel qui liste ses propres flux sous la
      // clé `streams` ne doit pas produire de fausses pistes.
      final tracks = SubtitleDiscovery.parse({
        'info': {
          'streams': [
            'http://panel.example:8080/live/joe/secret/55.ts',
          ],
        },
      });
      expect(tracks, isEmpty);
    });

    test('déduplique la même piste annoncée deux fois', () {
      final tracks = SubtitleDiscovery.parse({
        'info': {
          'subtitles': [
            {'language': 'fr', 'file': 'http://cdn.example/same.srt'},
            {'language': 'fr', 'file': 'http://cdn.example/same.srt'},
          ],
        },
      });
      expect(tracks, hasLength(1));
    });
  });
}
