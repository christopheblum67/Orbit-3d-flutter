import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/series.dart';

/// La découverte des sous-titres d'une série a besoin du stream id de
/// l'ÉPISODE, et `series_id` ne suffit pas.
///
/// Ce panel renvoie `episodes[].url` sous forme d'URL complète : sans
/// extraction, l'identifiant restait invisible, la découverte ne synthétisait
/// aucune piste et l'écran annonçait « le panel ne publie pas de sous-titre » —
/// alors qu'il en publie. Ces tests verrouillent l'extraction.
void main() {
  Episode episodeWithUrl(String url) => Episode(
        id: '31519_1_1',
        title: 'Chapitre 1',
        season: 1,
        episodeNumber: 1,
        streamUrl: url,
      );

  group('Episode.streamId — valeur déjà nue', () {
    test('un identifiant brut est renvoyé tel quel', () {
      expect(episodeWithUrl('12345').streamId, '12345');
    });

    test('une valeur vide reste vide', () {
      expect(episodeWithUrl('').streamId, '');
    });
  });

  group('Episode.streamId — extrait d\'une URL', () {
    test('URL Xtream /series/user/pass/12345.mkv', () {
      expect(
        episodeWithUrl('http://panel.example:8080/series/u/p/12345.mkv')
            .streamId,
        '12345',
      );
    });

    test('URL /live/… en .ts', () {
      expect(
        episodeWithUrl('http://panel.example/live/u/p/987.ts').streamId,
        '987',
      );
    });

    test('extension m3u8 (HLS)', () {
      expect(
        episodeWithUrl('http://panel.example/hls/u/p/555.m3u8').streamId,
        '555',
      );
    });

    test('URL avec port et chemin imbriqué', () {
      expect(
        episodeWithUrl('https://host.tld:8080/xtream/series/u/p/4242.mp4')
            .streamId,
        '4242',
      );
    });

    test('un paramètre stream_id prime sur le chemin', () {
      expect(
        episodeWithUrl('http://panel.example/player?stream_id=777&id=999')
            .streamId,
        '777',
      );
    });

    test('le paramètre stream est accepté aussi', () {
      expect(
        episodeWithUrl('http://panel.example/live?stream=888').streamId,
        '888',
      );
    });

    test('URL sans extension : le segment est pris tel quel', () {
      expect(
        episodeWithUrl('http://panel.example/series/u/p/31337').streamId,
        '31337',
      );
    });

    test('un point interne à l\'identifiant est conservé', () {
      // `1.2` n'est pas une extension : l'identifiant doit rester entier.
      expect(episodeWithUrl('http://panel.example/x/1.2').streamId, '1.2');
    });

    test('URL inexploitable : renvoie vide plutôt qu\'un faux id', () {
      // Le dernier segment est le nom d'hôte : le garder produirait une piste
      // fausse, qui pointerait vers un autre média.
      expect(episodeWithUrl('http://panel.example').streamId, '');
    });

    test('URL malformée : renvoie vide', () {
      expect(episodeWithUrl('http://').streamId, '');
    });
  });

  group('Episode.streamUrl reste inchangé', () {
    test('une URL complète n\'est pas reconstruite', () {
      expect(
        episodeWithUrl('http://panel.example/series/u/p/12345.mkv').streamUrl,
        'http://panel.example/series/u/p/12345.mkv',
      );
    });
  });
}
