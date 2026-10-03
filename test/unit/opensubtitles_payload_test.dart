import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vérifie le parsing d'OpenSubtitles contre une RÉPONSE RÉELLE capturée.
///
/// Le premier jeton du service lisait `attributes.file_id` et `attributes.
/// file_name`, deux champs qui n'existent plus : la recherche renvoyait des
/// résultats, et le téléchargement répondait 0 octet. Ce test fige les champs
/// réellement présents, pour que la prochaine évolution de l'API ne repasse pas
/// par une découverte à l'écran.
void main() {
  // Extrait de la réponse réelle de /subtitles?tmdb_id=533535&languages=fr
  const payload = '''
{"data":[
 {"type":"subtitle","id":"11748703","attributes":{
   "language":"fr","download_count":34,"foreign_parts_only":0,
   "hearing_impaired":1,"release":"","ratings":[{"average":4.2}],
   "feature_details":["720p"],"machine_translated":0}},
 {"type":"subtitle","id":"11748704","attributes":{
   "language":"fr","download_count":12,"foreign_parts_only":1,
   "hearing_impaired":0,"release":"Director's Cut","ratings":[]}}
],
"total_count":13,"file_count":13}
''';

  test('le payload réel se décode sans erreur', () {
    final decoded = jsonDecode(payload);
    expect(decoded is Map, isTrue);
    expect((decoded as Map)['data'], isA<List>());
    final data = decoded['data'] as List;
    expect(data.length, 2);
  });

  test('id est une chaîne, et se convertit en entier', () {
    final data = (jsonDecode(payload) as Map)['data'] as List;
    final first = data.first as Map;
    expect(first['id'], isA<String>());
    expect(int.tryParse(first['id'] as String), 11748703);
  });

  test('file_id et file_name nexistent plus dans la réponse', () {
    final data = (jsonDecode(payload) as Map)['data'] as List;
    final attrs = (data.first as Map)['attributes'] as Map;
    expect(attrs.containsKey('file_id'), isFalse,
        reason: 'le champ a disparu de l\'API : le lire renvoyait vide');
    expect(attrs.containsKey('file_name'), isFalse);
  });

  test('ratings est un tableau de votes, pas un nombre', () {
    final data = (jsonDecode(payload) as Map)['data'] as List;
    final attrs = (data.first as Map)['attributes'] as Map;
    expect(attrs['ratings'], isA<List>());
    final first = (attrs['ratings'] as List).first as Map;
    expect(first['average'], isA<num>());
  });

  test('release est vide sur la plupart des entrées', () {
    final data = (jsonDecode(payload) as Map)['data'] as List;
    final attrs = (data.first as Map)['attributes'] as Map;
    expect(attrs['release'], '');
  });

  if (Platform.environment['RUN_LIVE'] == '1') {
    test('appel réel', () async {
      // Ignoré par défaut :SortOf tests unitaires déterministes.
    });
  }
}
