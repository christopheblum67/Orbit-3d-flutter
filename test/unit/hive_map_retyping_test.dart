import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/json_retyping.dart';

/// Le cache Hive perd les types génériques Dart au round-trip, et
/// `Map<String, dynamic>.from` ne corrige que la RACINE.
///
/// Conséquence : après un CACHE HIT, les maps imbriquées restent des
/// `_Map<dynamic, dynamic>` et le premier cast du parseur
/// (`data['externals'] as Map<String, dynamic>?`) lève un `TypeError` →
/// l'écran affiche « Détail indisponible / Une erreur est survenue ».
///
/// Ces tests fixent le mécanisme ET le remède.
void main() {
  /// Reproduit ce que Hive renvoie au round-trip : une map dont les clés n'ont
  /// pas de type contraint, donc `_Map<dynamic, dynamic>`.
  ///
  /// ⚠ Un `jsonDecode(...) as Map<dynamic, dynamic>` ne reproduirait RIEN :
  /// le cast Dart est gratuit, l'objet reste un `_Map<String, dynamic>`. Il
  /// faut construire la map dynamic pour de vrai.
  Map<dynamic, dynamic> hiveLike(Map<dynamic, dynamic> raw) => raw;

  group('Map<String, dynamic>.from est SUPERFICIELLE (le défaut)', () {
    test('la racine est retypée, les imbriquées restent dynamic', () {
      final fromHive = hiveLike(<dynamic, dynamic>{
        'externals': <dynamic, dynamic>{'imdb': 'tt1'},
      });

      // Ce que le cache fait (`Map<String, dynamic>.from` sur la racine) :
      final shallow = Map<String, dynamic>.from(fromHive);

      // Le parseur de TVmaze fait exactement ce cast :
      expect(
        () => shallow['externals'] as Map<String, dynamic>?,
        throwsA(isA<TypeError>()),
        reason: 'c\'est l\'erreur "Détail indisponible" vue sur l\'app',
      );
    });
  });

  group('deepRetypeMap répare le round-trip', () {
    test('une map imbriquée redevient castable', () {
      final fixed = deepRetypeMap(
        hiveLike(<dynamic, dynamic>{
          'externals': <dynamic, dynamic>{'imdb': 'tt1'},
        }),
      );

      final externals = fixed['externals'] as Map<String, dynamic>?;
      expect(externals, isNotNull);
      expect(externals!['imdb'], 'tt1');
    });

    test('retype à travers les LISTES de maps', () {
      // Forme réellement rencontrée : `_embedded.cast` est une liste de maps,
      // et chaque map contient elle-même `person` / `character`.
      final fixed = deepRetypeMap(
        hiveLike(<dynamic, dynamic>{
          '_embedded': <dynamic, dynamic>{
            'cast': <dynamic>[
              <dynamic, dynamic>{
                'person': <dynamic, dynamic>{'name': 'A'},
                'character': <dynamic, dynamic>{'name': 'B'},
              },
            ],
          },
        }),
      );

      final embedded = fixed['_embedded'] as Map<String, dynamic>?;
      final cast = embedded!['cast'] as List<dynamic>?;
      final person = (cast!.first as Map)['person'] as Map<String, dynamic>?;
      expect(person?['name'], 'A');
      final character =
          (cast.first as Map)['character'] as Map<String, dynamic>?;
      expect(character?['name'], 'B');
    });

    test('préserve les valeurs scalaires ET la structure exacte', () {
      final fixed = deepRetypeMap(
        hiveLike(<dynamic, dynamic>{
          'a': 1,
          'b': 2.5,
          'c': 'texte',
          'd': null,
          'e': true,
          'f': <dynamic>[1, 2, 3],
        }),
      );

      expect(fixed['a'], 1);
      expect(fixed['b'], 2.5);
      expect(fixed['c'], 'texte');
      expect(fixed['d'], isNull);
      expect(fixed['e'], isTrue);
      expect(fixed['f'], [1, 2, 3]);
    });

    test('ne perd pas les clés non textuelles', () {
      final fixed = deepRetypeMap({7: 'sept'});
      expect(fixed['7'], 'sept');
    });
  });

  group('le contenu est identique avant/après retypage', () {
    test('round-trip JSON -> Hive -> retypage = JSON d\'origine', () {
      const source = '{"externals":{"imdb":"tt1","themoviedb":99},"_embedded":'
          '{"cast":[{"person":{"name":"A"}}]},"genres":["Drama","Comedy"]}';

      // 1. Ce que le réseau livre (JSON bien typé).
      final fromNetwork = jsonDecode(source) as Map<String, dynamic>;
      // 2. Ce que Hive restitue : mêmes DONNÉES, mais chaque map reconstruite
      // sans contrainte de type de clé.
      dynamic loseTypes(dynamic value) {
        if (value is Map) {
          return <dynamic, dynamic>{
            for (final e in value.entries) e.key: loseTypes(e.value),
          };
        }
        if (value is List) return value.map(loseTypes).toList();
        return value;
      }

      final fromHive = loseTypes(fromNetwork) as Map<dynamic, dynamic>;
      // 3. Après retypage profond.
      final fixed = deepRetypeMap(fromHive);

      // Le contenu ne doit dépendre QUE de la source, jamais du passage en
      // cache : c'est tout l'intérêt du correctif.
      expect(
        jsonEncode(fixed),
        jsonEncode(fromNetwork),
        reason: 'un cache hit doit produire EXACTEMENT le même objet qu\'un '
            'cache miss, sinon le même contenu échoue selon sa provenance',
      );
    });
  });
}
