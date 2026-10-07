import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Le décodage, du réseau jusqu'au texte affiché.
///
/// Un test sur `SubtitleEncoding` seul ne prouverait que la fonction : il faut
/// vérifier que le parseur l'appelle, et que le texte arrive entier jusqu'aux
/// cues. C'est ici qu'un vrai octet `0x92` servi par un serveur HTTP se
/// transforme en apostrophe affichable.
void main() {
  late HttpServer server;
  late String base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
  });

  tearDown(() async => server.close(force: true));

  /// Sert [bytes] tels quels, sans interprétation.
  void serve(String path, List<int> bytes) {
    server.listen((request) async {
      if (request.uri.path != path) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      request.response.add(bytes);
      await request.response.close();
    });
  }

  test('un SRT CP1252 avec apostrophe typographique est lu entièrement',
      () async {
    // Vrai fichier CP1252 : chaque caractère non-ASCII sur un octet.
    // « l'économie » = l + 0x92 + é(0xE9) + conomie
    final bytes = <int>[
      ...utf8.encode('1\n00:00:01,000 --> 00:00:04,000\n'),
      0x6C, // l
      0x92, // ’
      0xE9, // é
      ...utf8.encode('conomie\n\n'),
      ...utf8.encode('2\n00:00:05,000 --> 00:00:08,000\n'),
      0x22, // "
      0xE0, // à
      0x22, // "
      ...utf8.encode(' tout\n'),
    ];
    serve('/cp1252.srt', bytes);

    final track = await SubtitleParser.parseFromUrl('$base/cp1252.srt');

    expect(track.cues, hasLength(2));
    expect(
      track.cues.first.text,
      'l’économie',
      reason: 'l\'octet 0x92 doit devenir l\'apostrophe typographique, pas un '
          'caractère de contrôle C1 invisible',
    );
    expect(track.cues.last.text, '"à" tout');
  });

  test('un SRT UTF-8 est inchangé', () async {
    serve(
      '/utf8.srt',
      utf8.encode('1\n00:00:01,000 --> 00:00:04,000\nÇa va ?\n'),
    );

    final track = await SubtitleParser.parseFromUrl('$base/utf8.srt');

    expect(track.cues, hasLength(1));
    expect(track.cues.first.text, 'Ça va ?');
  });

  test('un SRT avec BOM UTF-8 est lu', () async {
    serve(
      '/bom.srt',
      <int>[
        0xEF, 0xBB, 0xBF,
        ...utf8.encode('1\n00:00:01,000 --> 00:00:04,000\nBonjour\n'),
      ],
    );

    final track = await SubtitleParser.parseFromUrl('$base/bom.srt');

    expect(track.cues, hasLength(1));
    expect(track.cues.first.text, 'Bonjour');
  });

  test('un fichier vide est toujours refusé', () async {
    // Le changement d'encodage ne doit pas rendre un fichier vide acceptable :
    // c'est ce contrat qui permet à la vérification de piste de conclure
    // « la piste n'existe pas » au lieu de garder une piste morte.
    serve('/vide.srt', const <int>[]);

    await expectLater(
      SubtitleParser.parseFromUrl('$base/vide.srt'),
      throwsA(isA<Exception>()),
    );
  });

  test('un 404 reste un 404', () async {
    serve('/present.srt', utf8.encode('1\n00:00:01,000 --> 00:00:04,000\nok\n'));

    await expectLater(
      SubtitleParser.parseFromUrl('$base/absent.srt'),
      throwsA(isA<Exception>()),
    );
  });
}