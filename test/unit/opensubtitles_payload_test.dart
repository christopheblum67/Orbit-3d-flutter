import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Verrouille le schéma réel de `/subtitles` d'OpenSubtitles.
///
/// Un premier jeton lisait `attributes.file_id` puis, après une correction
/// trop hâtive, l'`id` de l'enveloppe. Les deux sont faux : le `/download`
/// attend le `file_id` du FICHIER, rangé dans `attributes.files[]`, et
/// l'`id` de l'enveloppe désigne la FICHE. Les deux produisaient un corps
/// vide sans erreur HTTP — le symptôme looked like un blocage réseau alors
/// que la requête était simplement mal adressée.
///
/// Ce test fige la forme du JSON pour que la prochaine évolution de l'API ne
/// se redécouvre pas à l'écran.
void main() {
  // Extrait de la réponse réelle de /subtitles?tmdb_id=533535&languages=fr
  const payload = '''
{"data":[
 {"type":"subtitle","id":"11748703","attributes":{
   "language":"fr","download_count":34,"foreign_parts_only":0,
   "hearing_impaired":1,"release":"","ratings":[{"average":4.2}],
   "files":[{"file_id":91001,"file_name":"DW.fr.srt","size":41230}]}},
 {"type":"subtitle","id":"11748704","attributes":{
   "language":"fr","download_count":12,"foreign_parts_only":1,
   "hearing_impaired":0,"release":"Director's Cut","ratings":[],
   "files":[{"file_id":91002,"file_name":"DW.fr.forced.srt","size":39000}]}}
],
"total_count":13,"file_count":13}
''';

  List<Map<String, Object?>> entries() {
    final data = (jsonDecode(payload) as Map)['data'] as List;
    return data.cast<Map<String, Object?>>();
  }

  test('le payload réel se décode sans erreur', () {
    final decoded = jsonDecode(payload);
    expect(decoded is Map, isTrue);
    expect((decoded as Map)['data'], isA<List>());
    expect(entries().length, 2);
  });

  test('id est une chaîne et désigne la fiche, pas le fichier', () {
    final first = entries().first;
    expect(first['id'], isA<String>());
    expect(int.tryParse(first['id'] as String), 11748703);
  });

  test('le file_id est imbriqué dans attributes.files[], pas à la racine', () {
    final attrs = entries().first['attributes'] as Map;
    expect(attrs.containsKey('file_id'), isFalse,
        reason: 'ce champ n\'existe pas : le lire renvoyait 0');
    final files = attrs['files'] as List;
    expect(files, isNotEmpty);
    final file = files.first as Map;
    expect(file['file_id'], 91001);
    expect(file['file_name'], 'DW.fr.srt');
  });

  test('l\'id de l\'enveloppe diffère du file_id : les confondre casse tout',
      () {
    // C'est la régression centrale : un `/download` sur 11748703 au lieu de
    // 91001 répond 200 avec un corps vide.
    final first = entries().first;
    final attrs = first['attributes'] as Map;
    final fileId = ((attrs['files'] as List).first as Map)['file_id'] as int;
    expect(fileId, isNot(int.parse(first['id'] as String)));
  });

  test('ratings est un tableau de votes, pas un nombre', () {
    final attrs = entries().first['attributes'] as Map;
    expect(attrs['ratings'], isA<List>());
    final first = (attrs['ratings'] as List).first as Map;
    expect(first['average'], isA<num>());
  });

  test('release est vide sur la plupart des entrées', () {
    final attrs = entries().first['attributes'] as Map;
    expect(attrs['release'], '');
  });

  group('lecture des drapeaux', () {
    test('0 et 1 sont des entiers, pas des booléens', () {
      final attrs = entries().first['attributes'] as Map;
      expect(attrs['foreign_parts_only'], 0);
      expect(attrs['hearing_impaired'], 1);
    });

    test('le libellé distingue le forcé grâce au nom de fichier', () {
      // `foreign_parts_only` vaut 1 sur la 2e entrée : c'est cohérent avec le
      // nom. Mais le nom seul suffit, et c'est lui qui reste filled quand le
      // drapeau est absent — d'où la détection sur les deux sources.
      const hit = OpenSubtitlesHit(
        fileId: 91002,
        language: 'fr',
        fileName: 'DW.fr.forced.srt',
        isForced: true,
      );
      expect(hit.label, contains('forcé'));
    });

    test('sans qualificatif, le libellé est la langue seule', () {
      const hit = OpenSubtitlesHit(
        fileId: 91001,
        language: 'fr',
        fileName: 'DW.fr.srt',
      );
      expect(hit.label, 'Français');
    });

    test('l\'édition complète le libellé', () {
      const hit = OpenSubtitlesHit(
        fileId: 91003,
        language: 'en',
        release: "Director's Cut",
      );
      expect(hit.label, contains('Director'));
    });
  });
}
