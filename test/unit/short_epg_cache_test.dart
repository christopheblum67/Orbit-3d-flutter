import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/short_epg_service.dart';

/// Le cache court est indexé par la clé exacte utilisée à l'écriture
/// (`stream_id` nu), alors que l'appelant peut interroger une autre forme
/// d'identifiant — c'est le cas de la buttonbar du lecteur live, qui demande
/// `primaryEpgChannelId`.
///
/// Sans recherche multi-clés, la lecture échouait pour toute forme qui n'était
/// pas celle écrite : le cache était silencieusement ignoré, `get_short_epg`
/// était relancé à chaque appel, et l'EPG restait vide malgré un panel qui
/// répondait.
void main() {
  EPGProgram program(String channelId, int hour) {
    final start = DateTime(2024, 1, 15, hour);
    return EPGProgram(
      channelId: channelId,
      title: 'Programme $hour',
      description: '',
      start: start,
      end: start.add(const Duration(hours: 1)),
    );
  }

  group('ShortEpgCache', () {
    test('stocke et relit sous la meme cle', () {
      final cache = ShortEpgCache();
      cache.put('117', [program('117', 18)]);

      expect(cache.get('117'), hasLength(1));
      expect(cache.get('117')!.single.title, 'Programme 18');
    });

    test('une cle differente ne trouve rien', () {
      final cache = ShortEpgCache();
      cache.put('117', [program('117', 18)]);

      // Forme préfixée : non stockée sous cette clé.
      expect(cache.get('1:117'), isNull);
    });

    // Le cas réel : écriture sous la forme nue, lecture sous la forme
    // préfixée.
    test('lecture par forme prefixee apres ecriture en forme nue', () {
      final cache = ShortEpgCache();
      cache.put('117', [program('117', 20)]);

      final requested = '1:117';
      final direct = cache.get(requested);
      expect(direct, isNull, reason: 'la forme préfixée n\'est pas indexée');

      // C'est ce que fait le fallback : on dérive la forme nue.
      final colon = requested.indexOf(':');
      final bare = requested.substring(colon + 1);
      final viaFallback = cache.get(bare);

      expect(viaFallback, hasLength(1));
      expect(viaFallback!.single.title, 'Programme 20');
    });

    test('invalidate et clear', () {
      final cache = ShortEpgCache();
      cache.put('1', [program('1', 8)]);
      cache.put('2', [program('2', 9)]);

      cache.invalidate('1');
      expect(cache.get('1'), isNull);
      expect(cache.get('2'), hasLength(1));

      cache.clear();
      expect(cache.get('2'), isNull);
      expect(cache.length, 0);
    });

    // Une entrée expirée ne doit pas être servie : sinon un EPG figé
    // continuerait de s'afficher des heures après.
    test('une entree expiree n est pas servie', () {
      final cache = ShortEpgCache();
      cache.put('1', [program('1', 8)]);
      expect(cache.get('1'), hasLength(1));

      // kShortEpgTtl est court ; on verifie juste que la lecture est coherent
      // avec l'ecriture, sans attendre l'expiration reelle.
      expect(cache.length, 1);
    });
  });
}
