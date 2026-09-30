import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/epg_stream_parser.dart';

/// Les consommateurs de l'EPG (`epgCurrentProgram`, `epgNextProgram`, la
/// grille) localisent un programme par **dichotomie** sur l'heure de début.
/// Une dichotomie suppose une liste triée : sur une liste désordonnée elle
/// renvoie un programme arbitraire, typiquement vide, alors que le guide est
/// pourtant disponible.
///
/// Or aucun contrat de tri n'est garanti :
///  - le dump XMLTV peut livrer les `<programme>` dans le désordre ;
///  - `get_short_epg` renvoie fréquemment la journée courante mêlée à la
///    précédente, sans ordre.
void main() {
  EPGProgram program(String channelId, DateTime start, {int hours = 1}) {
    return EPGProgram(
      channelId: channelId,
      title: 'Programme $start',
      description: '',
      start: start,
      end: start.add(Duration(hours: hours)),
    );
  }

  group('EpgStreamParser ordering', () {
    // Panneaux qui livrent le XMLTV dans le désordre : la liste doit être
    // remise en ordre, sinon la recherche dichotomique est faussée.
    test('sorts programmes by start date', () {
      final xml = '<tv>'
          '<programme start="20240115180000 +0000" stop="20240115190000 +0000" channel="tf1"><title>18h</title></programme>'
          '<programme start="20240115060000 +0000" stop="20240115070000 +0000" channel="tf1"><title>06h</title></programme>'
          '<programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="tf1"><title>12h</title></programme>'
          '</tv>';

      final programs = EpgStreamParser.parse(xml);

      expect(programs, hasLength(3));
      for (var i = 1; i < programs.length; i++) {
        expect(
          programs[i].start.isBefore(programs[i - 1].start),
          isFalse,
          reason: 'programmes non triés par début à l\'index $i',
        );
      }
      expect(programs.first.title, '06h');
      expect(programs.last.title, '18h');
    });

    // Listes de 0 ou 1 élément : le tri ne doit rien casser ni lever.
    test('handles empty and single-entry payloads', () {
      expect(EpgStreamParser.parse('<tv></tv>'), isEmpty);

      final single = EpgStreamParser.parse(
        '<tv><programme start="20240115060000 +0000" '
        'stop="20240115070000 +0000" channel="tf1">'
        '<title>06h</title></programme></tv>',
      );
      expect(single, hasLength(1));
      expect(single.single.title, '06h');
    });
  });

  group('dichotomy over a parsed list', () {
    // Reproduit le symptôme observé : grille vide / « aucun programme » sur un
    // panel dont le XMLTV n'est pas trié.
    test('binary search finds the running programme', () {
      final base = DateTime.utc(2024, 1, 15, 6);
      final xml = '<tv>'
          '<programme start="20240115180000 +0000" stop="20240115190000 +0000" channel="tf1"><title>18h</title></programme>'
          '<programme start="20240115060000 +0000" stop="20240115070000 +0000" channel="tf1"><title>06h</title></programme>'
          '<programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="tf1"><title>12h</title></programme>'
          '</tv>';

      final programs = EpgStreamParser.parse(xml);
      final at = base.add(const Duration(minutes: 30));

      final current = programs
          .where((p) => !p.start.isAfter(at) && p.end.isAfter(at))
          .toList();

      expect(current, hasLength(1));
      expect(current.single.title, '06h');
    });
  });
}
