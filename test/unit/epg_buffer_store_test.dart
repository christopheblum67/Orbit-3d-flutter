import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/epg_buffer_store.dart';

/// Le tampon EPG local.
///
/// Ce tampon remplace un téléchargement de plusieurs dizaines de mégaoctets à
/// chaque session. Sa valeur tient à trois propriétés qu'il faut prouver
/// séparément : il relit fidèlement ce qu'il a écrit, il REFUSE un tampon trop
/// vieux, et il ne transforme jamais un fichier corrompu en grille cassée.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit_epg_buffer');
    EpgBufferStore.instance.debugSetDirectory(dir.path);
  });

  tearDown(() async {
    EpgBufferStore.instance.resetDirectoryCacheForTests();
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // ignoré : le temporaire est nettoyé par l'OS
      }
    }
  });

  EPGProgram program({
    String channel = 'TF1',
    String title = 'Le journal',
    String description = 'Résumé de l\'émission',
    int startMinutes = 0,
    bool dummy = false,
  }) {
    final start = DateTime(2026, 1, 2, 12).add(Duration(minutes: startMinutes));
    return EPGProgram(
      channelId: channel,
      title: title,
      description: description,
      start: start,
      end: start.add(const Duration(minutes: 30)),
      isDummy: dummy,
    );
  }

  group('aller-retour', () {
    test('ce qui est écrit est relu à l\'identique', () async {
      final programs = [
        program(),
        program(channel: 'FR2', title: 'Arte', startMinutes: 60),
      ];
      await EpgBufferStore.instance.write('panel-a|user', programs);

      final read = await EpgBufferStore.instance.read('panel-a|user');

      expect(read, isNotNull);
      expect(read, hasLength(2));
      expect(read!.first.channelId, 'TF1');
      expect(read.first.title, 'Le journal');
      expect(read.first.description, 'Résumé de l\'émission');
      expect(read.first.start, program().start);
      expect(read.first.end, program().end);
      expect(read.last.title, 'Arte');
    });

    test('un abonnement absent ne renvoie rien, sans exception', () async {
      expect(await EpgBufferStore.instance.read('jamais-ecrit'), isNull);
    });

    test('deux abonnements ne se mélangent pas', () async {
      await EpgBufferStore.instance.write('panel-a|user', [program()]);
      await EpgBufferStore.instance
          .write('panel-b|user', [program(channel: 'M6', title: 'Divorce')]);

      final a = await EpgBufferStore.instance.read('panel-a|user');
      final b = await EpgBufferStore.instance.read('panel-b|user');

      expect(a!.first.channelId, 'TF1');
      expect(b!.first.channelId, 'M6',
          reason: 'le tampon est indexé par abonnement : les listes de chaînes '
              'diffèrent, un partage afficherait les programmes de l\'autre');
    });
  });

  group('péremption', () {
    test('un tampon plus vieux que 12 h est refusé', () async {
      await EpgBufferStore.instance.write('k', [program()]);

      // On aginge l'écriture pour simuler un tampon de la veille.
      final file = File('${dir.path}/${EpgBufferStore.instance.fileNameFor('k')}');
      final old = DateTime.now().subtract(const Duration(hours: 13));
      file.setLastModifiedSync(old);

      expect(
        await EpgBufferStore.instance.read('k'),
        isNull,
        reason: 'sans cela, le téléphone afficherait des programmes d\'hier avec'
            'la même assurance que ceux d\'aujourd\'hui',
      );
    });

    test('un tampon récent est accepté', () async {
      await EpgBufferStore.instance.write('k', [program()]);
      expect(await EpgBufferStore.instance.read('k'), isNotNull);
    });

    test('un format inconnu est refusé sans être lu', () async {
      final file = File(
        '${dir.path}/${EpgBufferStore.instance.fileNameFor('k')}',
      );
      file.writeAsStringSync(jsonEncode({
        'v': 999,
        'writtenAt': DateTime.now().millisecondsSinceEpoch,
        'programs': <Object>[],
      }));

      expect(await EpgBufferStore.instance.read('k'), isNull);
    });
  });

  group('robustesse', () {
    test('un fichier corrompu ne lève pas, il est ignoré', () async {
      final file = File(
        '${dir.path}/${EpgBufferStore.instance.fileNameFor('k')}',
      );
      file.writeAsStringSync('{"v":1,"programs":[{"c":"TF1"');

      expect(
        await EpgBufferStore.instance.read('k'),
        isNull,
        reason: 'un tampon corrompu doit coûter un téléchargement, pas une '
            'grille cassée',
      );
    });

    test('un programme au champ manquant ne casse pas la lecture', () async {
      final file = File(
        '${dir.path}/${EpgBufferStore.instance.fileNameFor('k')}',
      );
      file.writeAsStringSync(jsonEncode({
        'v': 1,
        'writtenAt': DateTime.now().millisecondsSinceEpoch,
        'programs': [
          {'c': 'TF1', 't': 'ok', 'd': '', 's': 1767355200000, 'e': 1767357000000},
          {'c': 'M6', 't': 'champ manquant'},
        ],
      }));

      final read = await EpgBufferStore.instance.read('k');

      expect(read, isNull,
          reason: 'une entrée tronquée rend le fichier entier douteux : mieux '
              'vaut re-télécharger que mixture des programmes sans horaire');
    });

    test('aucun fichier temporaire ne subsiste après écriture', () async {
      await EpgBufferStore.instance.write('k', [program()]);

      final leftovers = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.tmp'))
          .toList();

      expect(leftovers, isEmpty,
          reason: 'l\'écriture passe par un .tmp puis un renommage ; un .tmp '
              'laissé signale une coupure au milieu de l\'écriture');
    });
  });

  group('projection de la fenêtre', () {
    final windowStart = DateTime(2026, 1, 2, 0);
    final horizon = DateTime(2026, 1, 3, 6);

    EPGProgram at(DateTime start) => EPGProgram(
          channelId: 'TF1',
          title: 'p',
          description: '',
          start: start,
          end: start.add(const Duration(minutes: 30)),
        );

    test('un programme d\'hier est écarté', () {
      final kept = EpgBufferStore.project(
        [at(DateTime(2026, 1, 1, 22))],
        windowStart: windowStart,
        horizon: horizon,
      );
      expect(kept, isEmpty);
    });

    test('un programme au-delà de l\'horizon est écarté', () {
      final kept = EpgBufferStore.project(
        [at(DateTime(2026, 1, 3, 7))],
        windowStart: windowStart,
        horizon: horizon,
      );
      expect(kept, isEmpty);
    });

    test('un programme dans la fenêtre est conservé', () {
      final kept = EpgBufferStore.project(
        [at(DateTime(2026, 1, 2, 14))],
        windowStart: windowStart,
        horizon: horizon,
      );
      expect(kept, hasLength(1));
    });

    test('la borne est l\'horizon annoncé', () {
      expect(EpgBufferStore.horizonHours, 30);
      expect(EpgBufferStore.maxAge, const Duration(hours: 12));
    });
  });

  test('le nom de fichier ne dépend que de la clé', () {
    final a = EpgBufferStore.instance.fileNameFor('panel|user');
    final b = EpgBufferStore.instance.fileNameFor('panel|user');
    final c = EpgBufferStore.instance.fileNameFor('autre|user');
    expect(a, b);
    expect(a, isNot(c));
    expect(a, matches(RegExp(r'^epg_\d+\.json$')),
        reason: 'la clé contient un caractère interdit dans un nom de fichier '
            '(`|`), d\'où le hachage');
  });
}