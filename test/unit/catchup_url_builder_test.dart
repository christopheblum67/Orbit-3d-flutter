import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/catchup_url_builder.dart';

/// Le chemin de replay doit venir du modèle `catchup-source` déclaré par le
/// provider, pas d'une convention devinée.
///
/// Ces tests figent la table de substitution documentée : une variable mal
/// substituée donne une URL qui répond 404, et le programme est alors listé
/// mais illisible — un échec silencieux, visible seulement à la lecture.
void main() {
  // 29/09/2026 20:00:00, instant fixe pour figer les valeurs attendues.
  final start = DateTime(2026, 9, 29, 20, 0, 0);
  final end = DateTime(2026, 9, 29, 20, 40, 0);
  final startEpoch = start.millisecondsSinceEpoch ~/ 1000;

  String resolve(
    String template, {
    String mode = 'default',
    String liveUrl = 'http://panel.example/live/user/pass/12345.ts',
    Duration offset = Duration.zero,
  }) =>
      CatchupUrl.resolve(
        template: template,
        mode: mode,
        liveUrl: liveUrl,
        start: start,
        end: end,
        offset: offset,
      );

  group('CatchupUrl — table de substitution', () {
    test('{utc} et {start} valent le timestamp de début, en secondes', () {
      expect(resolve('{utc}'), '$startEpoch');
      expect(resolve('{start}'), '$startEpoch');
      // Alias : les deux écritures doivent donner le même nombre.
      expect(resolve('{utc}'), resolve('{start}'));
    });

    test('{lutc} et {now} valent l\'instant d\'exécution', () {
      // Au début d'un replay, l'exécution coïncide avec le début du programme.
      expect(resolve('{lutc}'), '$startEpoch');
      expect(resolve('{now}'), '$startEpoch');
      // Reprise 10 minutes plus tard : l'exécution avance, le début non.
      expect(
        resolve('{lutc}', offset: const Duration(minutes: 10)),
        '${startEpoch + 600}',
      );
      expect(resolve('{utc}', offset: const Duration(minutes: 10)),
          '$startEpoch',);
    });

    test('{duration} est la durée en secondes', () {
      // 20:00 → 20:40 = 40 min = 2400 s.
      expect(resolve('{duration}'), '2400');
    });

    test('{offset} vaut 0 à l\'ouverture du replay', () {
      expect(resolve('{offset}'), '0');
    });

    test('{offset} vaut le décalage de reprise', () {
      expect(resolve('{offset}', offset: const Duration(minutes: 10)), '600');
    });

    test('{offset} négatif est ramené à 0', () {
      expect(resolve('{offset}', offset: const Duration(minutes: -5)), '0');
    });

    test('composantes ISO sur 2026-09-29 20:00:00', () {
      expect(resolve('{Y}'), '2026');
      expect(resolve('{m}'), '09');
      expect(resolve('{d}'), '29');
      expect(resolve('{H}'), '20');
      expect(resolve('{M}'), '00');
      expect(resolve('{S}'), '00');
    });

    test('composantes ISO remplies à 2 chiffres', () {
      final morning = DateTime(2026, 1, 2, 3, 4, 5);
      final value = CatchupUrl.resolve(
        template: '{Y}-{m}-{d} {H}:{M}:{S}',
        mode: 'default',
        liveUrl: 'http://panel.example/live/1.ts',
        start: morning,
        end: morning.add(const Duration(minutes: 30)),
      );
      expect(value, '2026-01-02 03:04:05');
    });

    test('plusieurs variables dans un même modèle', () {
      final value = resolve(
        '?start={utc}&duration={duration}&date={Y}{m}{d}{H}{M}{S}',
      );
      expect(value, '?start=$startEpoch&duration=2400&date=20260929200000');
    });

    test('aucune variable ne reste dans le résultat', () {
      final value = resolve('/ts/{Y}/{m}/{d}/{H}{M}{S}-{utc}-{duration}.ts');
      expect(value.contains('{'), isFalse);
      expect(value.contains('}'), isFalse);
    });

    test('le format ISO `YYYYMMDDHHMMSS` est produit par la fonction dédiée', () {
      expect(CatchupUrl.buildCatchupIsoStamp(start), '20260929200000');
    });
  });

  group('CatchupUrl — résolution du modèle', () {
    test('un fragment de requête n\'est PAS traité comme un chemin', () {
      // Régression : le modèle `?start=…` se faisait préfixer par l'hôte, ce
      // qui produisait `http://panel.example?start=…` — une URL sans le flux.
      expect(resolve('?start={utc}'), '?start=$startEpoch');
    });

    test('une valeur nue n\'est PAS traitée comme un chemin', () {
      expect(resolve('{utc}'), '$startEpoch');
    });

    test('un chemin relatif se rattache à l\'hôte du flux live', () {
      // Flussonic : chemin relatif horodaté, sur le même serveur.
      expect(
        resolve(
          '/timeshift_abs-{utc}-{duration}.ts',
          mode: 'flussonic',
          liveUrl: 'http://panel.example/live/user/1.ts',
        ),
        'http://panel.example/timeshift_abs-$startEpoch-2400.ts',
      );
    });

    test('un chemin relatif conserve le port du flux live', () {
      expect(
        resolve(
          '/ts-{utc}.ts',
          liveUrl: 'http://panel.example:8080/live/1.ts',
        ),
        'http://panel.example:8080/ts-$startEpoch.ts',
      );
    });

    test('un modèle absolu est respecté tel quel', () {
      expect(
        resolve(
          'https://autre.example/ts/{utc}/{duration}.ts',
          liveUrl: 'http://panel.example/live/1.ts',
        ),
        'https://autre.example/ts/$startEpoch/2400.ts',
      );
    });

    test('un protocole relatif `//` n\'est pas complété', () {
      expect(resolve('//cdn.example/ts/{utc}.ts'), '//cdn.example/ts/$startEpoch.ts');
    });
  });

  group('CatchupUrl — mode append', () {
    test('le modèle complète l\'URL du flux live', () {
      // C'est le cas piège : sans ce mode on obtenait `start=…&duration=…`
      // seul, sans hôte ni chemin — une URL non jouable.
      expect(
        resolve(
          'start={utc}&duration={duration}',
          mode: 'append',
          liveUrl: 'http://panel.example/live/user/pass/12345.ts',
        ),
        'http://panel.example/live/user/pass/12345.ts'
        '?start=$startEpoch&duration=2400',
      );
    });

    test('un flux live déjà pourvu en query reçoit un &', () {
      expect(
        resolve(
          'start={utc}',
          mode: 'append',
          liveUrl: 'http://panel.example/live/1.ts?token=abc',
        ),
        'http://panel.example/live/1.ts?token=abc&start=$startEpoch',
      );
    });

    test('un modèle commençant par ? est collé tel quel', () {
      expect(
        resolve(
          '?start={utc}',
          mode: 'append',
          liveUrl: 'http://panel.example/live/1.ts',
        ),
        'http://panel.example/live/1.ts?start=$startEpoch',
      );
    });

    test('le mode est insensible à la casse et aux espaces', () {
      expect(
        resolve(
          'start={utc}',
          mode: ' APPEND ',
          liveUrl: 'http://panel.example/live/1.ts',
        ),
        'http://panel.example/live/1.ts?start=$startEpoch',
      );
    });
  });

  group('CatchupUrl.build', () {
    Channel channelWith({String mode = '', String source = ''}) => Channel(
          id: '42',
          name: 'TF1',
          logoUrl: '',
          streamUrl: 'http://panel.example/live/user/42.ts',
          group: 'France',
          catchupMode: mode,
          catchupSource: source,
        );

    test('renvoie null sans modèle : l\'appelant garde sa convention', () {
      // Sans modèle, aucune URL ne doit être inventée : c'est le cas Xtream,
      // traité par une convention dédiée.
      expect(CatchupUrl.build(channel: channelWith(), start: start, end: end),
          isNull,);
    });

    test('substitue le modèle de la chaîne', () {
      expect(
        CatchupUrl.build(
          channel: channelWith(
            mode: 'default',
            source: '?start={utc}&duration={duration}',
          ),
          start: start,
          end: end,
        ),
        '?start=$startEpoch&duration=2400',
      );
    });

    test('un modèle bordé d\'espaces est accepté', () {
      expect(
        CatchupUrl.build(
          channel: channelWith(source: '  ?start={utc}  '),
          start: start,
          end: end,
        ),
        '?start=$startEpoch',
      );
    });

    test('le décalage de reprise est transmis', () {
      expect(
        CatchupUrl.build(
          channel: channelWith(
            mode: 'append',
            source: 'start={utc}&offset={offset}',
          ),
          start: start,
          end: end,
          offset: const Duration(minutes: 10),
        ),
        'http://panel.example/live/user/42.ts'
        '?start=$startEpoch&offset=600',
      );
    });
  });
}
