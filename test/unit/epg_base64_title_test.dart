import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

void main() {
  // Certains panels encodent les titres et descriptifs EPG en base64. Sans
  // décodage, l'EPG affichait « RmFtaWxsZXZXMgbm9tYJ… ».
  group('décodage base64 des titres EPG', () {
    test('décode un titre encodé', () {
      final raw = base64Encode(utf8.encode('Le Petit Nicolas'));
      expect(
        ApiService.decodeEpgTextForTest(raw),
        'Le Petit Nicolas',
      );
    });

    test('décode un titre accentué', () {
      final raw = base64Encode(utf8.encode('Journal 20h — édition régionale'));
      expect(
        ApiService.decodeEpgTextForTest(raw),
        'Journal 20h — édition régionale',
      );
    });

    test('laisse intact un titre en clair', () {
      expect(
          ApiService.decodeEpgTextForTest('Le Petit Nicolas'),
          'Le Petit Nicolas',);
      expect(ApiService.decodeEpgTextForTest('TF1'), 'TF1');
    });

    test('ne décode pas un mot qui ressemble à du base64', () {
      // « Actu » et « News » sont des alphabets base64 valides : les déduire
      // produirait des caractères de contrôle. Ils doivent rester intacts.
      expect(ApiService.decodeEpgTextForTest('Actu'), 'Actu');
      expect(ApiService.decodeEpgTextForTest('News'), 'News');
    });

    test('ne décode pas une longueur impossible', () {
      expect(ApiService.decodeEpgTextForTest(''), '');
      expect(ApiService.decodeEpgTextForTest('abc'), 'abc');
    });
  });

  group('base64 sans padding', () {
    // Régression mesurée sur le panel : les titres sont émis SANS padding. Un
    // titre de 20 octets fait 27 caractères, et l'ancienne garde « longueur
    // multiple de 4 » le rejetait. Résultat : la plupart des titres se
    // décodaient et les autres restaient en base64 dans la MÊME liste, sans
    // rien pour les distinguer — c'est ce que signalait « il reste du base64 ».
    test('longueur congrue à 3 : 27 caractères pour 20 octets', () {
      const encoded = 'TGUgcHJvZ3JhbW1lIGRlIGxhIHNvaXLDqWU';
      expect(encoded.length, 35);
      expect(encoded.length % 4, 3);
      expect(
        ApiService.decodeEpgTextForTest(encoded),
        'Le programme de la soirée',
      );
    });

    test('longueur congrue à 2', () {
      const encoded = 'Sm91cm5hbCBkdSBtYXRpbg';
      expect(encoded.length, 22);
      expect(encoded.length % 4, 2);
      expect(ApiService.decodeEpgTextForTest(encoded), 'Journal du matin');
    });

    test('une chaîne non alignée et non encodée reste inchangée', () {
      // 23 caractères d'un alphabet base64, mais le décodage ne donne pas de
      // texte valide : il ne faut pas altérer la valeur.
      const raw = 'LeBulletinDuSoirPrograms';
      expect(ApiService.decodeEpgTextForTest(raw), raw);
    });
  });

  group('le décodage ne doit rien casser', () {
    test('une longueur congrue à 1 n\'est pas du base64', () {
      // Impossible en base64 (1 caractère ne peut pas représenter 6 bits) :
      // le texte est rendu tel quel.
      const raw = 'LeBulletinDuSoirX';
      expect(raw.length % 4, 1);
      expect(ApiService.decodeEpgTextForTest(raw), raw);
    });

    test('un titre en clair avec espaces est inchangé', () {
      const raw = 'Le Bulletin du soir';
      expect(ApiService.decodeEpgTextForTest(raw), raw);
    });

    test('un titre en clair avec ponctuation est inchangé', () {
      const raw = 'JT 20h - Édition spéciale';
      expect(ApiService.decodeEpgTextForTest(raw), raw);
    });

    test('un identifiant de chaîne alphanumérique est inchangé', () {
      const raw = 'FRANCE2FHD';
      expect(ApiService.decodeEpgTextForTest(raw), raw);
    });
  });
}
