import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';

void main() {
  group('piste declaree vs URL deduite', () {
    const ctx = SubtitleDiscoveryContext(
      baseUrl: 'http://panel.example:8080',
      username: 'user',
      password: 'pass',
      streamId: '54321',
    );

    test('un chemin relatif du panel est resolu, pas lu comme un code langue',
        () {
      // Certains panels renvoyent le CHEMIN du fichier, pas une URL ni un code
      // langue. Il faut le resoudre sur la racine du site.
      //
      // Le code traitait `54321_fr.srt` comme un code langue : il construisait
      // `.../subtitles/user/pass/54321.54321_fr.srt.srt` — une URL morte — et
      // la vraie adresse, `http://panel.example:8080/54321_fr.srt`, n'etait
      // jamais tentee puisque le premier essai renvoyait deja un `String?`.
      final tracks = SubtitleDiscovery.parse({
        'subtitles': ['54321_fr.srt'],
      }, context: ctx,);

      expect(tracks, hasLength(1));
      expect(
        tracks.first.url,
        'http://panel.example:8080/54321_fr.srt',
        reason: 'le panel a fourni le fichier : cette adresse doit etre '
            'utilisee telle quelle',
      );
      expect(
        tracks.first.language,
        'fr',
        reason: 'le code se deduit du NOM DE FICHIER, sinon l\'utilisateur '
            'verrait un libellite incomprehensible',
      );
    });

    test('un chemin relatif du panel ne recoit pas de replis conventionnels',
        () {
      // Le panel a DONNE l'adresse : elle n'est pas devinee. Les replis de
      // `urlsForLanguage` ne pourraient designer que des fichiers que le panel
      // n'a jamais mentionnes — ici trois URL mortes de plus a sonder.
      final tracks = SubtitleDiscovery.parse({
        'subtitles': ['54321_fr.srt'],
      }, context: ctx,);

      expect(
        tracks.first.alternates,
        isEmpty,
        reason: 'des replis n ont de sens que pour une URL deduite d\'un code '
            'langue, pas pour un fichier designe par le panel',
      );
      expect(
        SubtitleDiscovery.needsVerification(tracks),
        isFalse,
        reason: 'puisque le panel a fourni l\'adresse, la piste ne doit pas '
            'partir en verification : son existence est au panel de la dire',
      );
    });

    test('un chemin absolu est resoli sur la racine du site', () {
      final tracks = SubtitleDiscovery.parse({
        'subtitles': ['/media/sub/54321_en.srt'],
      }, context: ctx,);

      expect(tracks, hasLength(1));
      expect(tracks.first.url, 'http://panel.example:8080/media/sub/54321_en.srt');
    });

    test('un code langue seul produit une URL DEDUITE, avec ses replis', () {
      // Le panel ne fournit qu'un CODE. L'URL est donc construite par nous, et
      // `guessed` restait faux — la piste etait presentee comme une declaration
      // alors qu'elle n'avait jamais ete testee.
      final tracks = SubtitleDiscovery.parse({
        'subtitles': ['fr'],
      }, context: ctx,);

      expect(tracks, hasLength(1));
      final track = tracks.first;
      expect(track.language, 'fr');
      expect(track.url, contains('54321_fr.srt'));

      // Les autres formes de convention doivent etre attachees comme replis :
      // `urlsForLanguage` en definit quatre.
      expect(track.alternates, isNotEmpty,
          reason: 'sans replis, une piste servie sous une autre forme est '
              'declaree morte alors qu elle existe',);
      expect(track.alternates.any((a) => a.url.contains('54321.fr.srt')),
          isTrue,
          reason: 'la forme .fr.srt doit etre un repli',);
    });

    test('needsVerification : vrai des que l URL est deduite', () {
      final tracks = SubtitleDiscovery.parse({
        'subtitles': ['fr'],
      }, context: ctx,);
      expect(SubtitleDiscovery.needsVerification(tracks), isTrue,
          reason: 'c est le trou du correctif : `guessed` etait false ici, donc '
              'la piste passait sans verification',);
    });

    test('une URL FOURNIE par le panel ne demande pas de verification', () {
      // Contrepoint indispensable : si TOUT etait verifie, on repayerait des
      // requetes pour des pistes que le panel a explicitement annoncees.
      final tracks = SubtitleDiscovery.parse({
        'subtitles': ['http://panel.example:8080/x/54321_fr.srt'],
      }, context: ctx,);

      expect(tracks, hasLength(1));
      expect(SubtitleDiscovery.needsVerification(tracks), isFalse,
          reason: 'le panel a fourni l URL : elle est adressable telle quelle',);
    });

    test('plusieurs codes donnent plusieurs pistes verifiables', () {
      final tracks = SubtitleDiscovery.parse({
        'subtitles': ['fr', 'en'],
      }, context: ctx,);
      expect(tracks, hasLength(2));
      expect(SubtitleDiscovery.needsVerification(tracks), isTrue);
      for (final t in tracks) {
        expect(t.alternates, isNotEmpty);
      }
    });
  });

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
