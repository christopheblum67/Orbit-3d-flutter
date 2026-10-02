import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';

/// Le décodeur unique des textes de panel.
///
/// Il est utilisé à la frontière de TOUS les modèles (`fromMap`), précisément
/// pour qu'un champ ne puisse plus être oublié : c'était la cause des trois
/// bugs d'affilée observés (titres de films en base64, replays, EPG), chacun
/// sur un chemin où le décodage n'avait pas été appliqué.
///
/// Ces tests verrouillent donc deux choses : ce qui DOIT être décodé, et — plus
/// important — ce qui ne doit surtout PAS l'être.
void main() {
  group('PanelText.decode — ce qui doit être décodé', () {
    test('titre encodé avec padding', () {
      final raw = base64Encode(utf8.encode('Le Petit Nicolas'));
      expect(PanelText.decode(raw), 'Le Petit Nicolas');
    });

    test('titre accentué', () {
      final raw = base64Encode(utf8.encode('Journal 20h — édition régionale'));
      expect(PanelText.decode(raw), 'Journal 20h — édition régionale');
    });

    test('encodage SANS padding, longueur congrue à 3', () {
      // Régression mesurée sur le panel : un titre de 20 octets fait 27
      // caractères, et une garde « multiple de 4 » le rejetait. Résultat :
      // certains titres décodés, d'autres non, dans la MÊME liste.
      const encoded = 'TGUgcHJvZ3JhbW1lIGRlIGxhIHNvaXLDqWU';
      expect(encoded.length % 4, 3);
      expect(PanelText.decode(encoded), 'Le programme de la soirée');
    });

    test('encodage SANS padding, longueur congrue à 2', () {
      const encoded = 'Sm91cm5hbCBkdSBtYXRpbg';
      expect(encoded.length % 4, 2);
      expect(PanelText.decode(encoded), 'Journal du matin');
    });

    test('description longue encodée', () {
      final text = 'Le journal d\'information du soir, avec les '
          'informations locales et nationales.';
      final raw = base64Encode(utf8.encode(text));
      expect(PanelText.decode(raw), text);
    });

    test('description TRÈS longue encodée : au-delà de 512 caractères', () {
      // Régression : la limite était à 512, et un synopsis de 500 caractères
      // fait ~668 caractères une fois encodé. Les titres courts se décodaient,
      // les descriptifs longs restaient en base64 — dans la même liste.
      final sentence = 'Le journal de la soirée présente les actualités du jour. ';
      final text = sentence * 10; // ≈ 500 caractères
      expect(text.length, greaterThan(400));
      final raw = base64Encode(utf8.encode(text));
      expect(raw.length, greaterThan(512));
      expect(PanelText.decode(raw), text);
    });

    test('un blob reste refusé même avec la borne relevée', () {
      // La borne est un garde-fou, pas une invitation à tout décoder.
      final blob = base64Encode(List.filled(6000, 65));
      expect(PanelText.decode(blob), blob);
    });
  });

  group('PanelText.decode — ce qui ne doit PAS être touché', () {
    test('titre en clair avec espaces', () {
      const raw = 'Le Bulletin du soir';
      expect(PanelText.decode(raw), raw);
    });

    test('titre en clair avec ponctuation', () {
      const raw = 'JT 20h - Édition spéciale';
      expect(PanelText.decode(raw), raw);
    });

    test('identifiant de chaîne alphanumérique', () {
      const raw = 'FRANCE2FHD';
      expect(PanelText.decode(raw), raw);
    });

    test('longueur congrue à 1 : pas du base64', () {
      const raw = 'LeBulletinDuSoirX';
      expect(raw.length % 4, 1);
      expect(PanelText.decode(raw), raw);
    });

    test('URL de flux : jamais décodée', () {
      // Une URL sort de l'alphabet base64 (« : », « / », « ? »), c'est ce qui
      // protège les jetons d'authentification d'un faux décodage.
      const raw =
          'http://panel.example:8080/series/user/pass/12345.mkv?token=abc';
      expect(PanelText.decode(raw), raw);
    });

    test('chaîne trop courte', () {
      expect(PanelText.decode('Actu'), 'Actu');
      expect(PanelText.decode('News'), 'News');
      expect(PanelText.decode('TF1'), 'TF1');
    });

    test('vide et nul', () {
      expect(PanelText.decode(''), '');
      expect(PanelText.decode(null), '');
      expect(PanelText.decode('   '), '');
    });

    test('valeur qui n\'est pas de l\'UTF-8', () {
      // Octets arbitraires : le décodage « réussit » mais ne donne pas du texte.
      final raw = base64Encode([0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF9, 0xF8]);
      expect(PanelText.decode(raw), raw);
    });

    test('un mot qui ressemble à du base64 mais donne des contrôles', () {
      // Contrôle : un décodage réussi mais plein de caractères de contrôle est
      // refusé, c'est ce qui distingue du texte d'un faux positif.
      final raw = base64Encode(utf8.encode('AAAAAAAB\nBBBB\n'));
      expect(PanelText.decode(raw), contains('\n'));
    });
  });

  group('PanelText.decodeMap — la frontière des modèles', () {
    test('décode toutes les valeurs textuelles', () {
      final title = base64Encode(utf8.encode('Le Nom du film'));
      final plot = base64Encode(utf8.encode('Le résumé du film.'));
      final out = PanelText.decodeMap({
        'name': title,
        'plot': plot,
        'rating': 8.5,
        'stream_id': '12345',
      });
      expect(out['name'], 'Le Nom du film');
      expect(out['plot'], 'Le résumé du film.');
      // Les valeurs non textuelles sont intactes.
      expect(out['rating'], 8.5);
      expect(out['stream_id'], '12345');
    });

    test('décode les maps imbriquées', () {
      final out = PanelText.decodeMap({
        'info': {
          'title': base64Encode(utf8.encode('Titre imbriqué')),
        },
      });
      final info = out['info'] as Map<String, dynamic>;
      expect(info['title'], 'Titre imbriqué');
    });

    test('décode les listes', () {
      final out = PanelText.decodeMap({
        'genres': ['Action', base64Encode(utf8.encode('Comédie'))],
      });
      expect(out['genres'], ['Action', 'Comédie']);
    });

    test('map vide', () {
      expect(PanelText.decodeMap(const {}), isEmpty);
    });

    test('ne casse pas une structure profonde (garde de profondeur)', () {
      // Une imbrication absurde ne doit pas faire exploser la pile.
      Map<String, dynamic> deep = {'v': base64Encode(utf8.encode('x'))};
      for (var i = 0; i < 12; i++) {
        deep = {'n': deep};
      }
      expect(() => PanelText.decodeMap(deep), returnsNormally);
    });
  });

  group('PanelText.first', () {
    test('renvoie le premier champ non vide, décodé', () {
      final raw = base64Encode(utf8.encode('Le résumé'));
      expect(
        PanelText.first([null, '', '  ', raw]),
        'Le résumé',
      );
    });

    test('tous vides : chaîne vide', () {
      expect(PanelText.first([null, '', '   ']), '');
    });
  });
}