import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';

/// Coût et exactitude de la vérification des pistes déduites.
///
/// Le service vérifie qu'un fichier existe avant de l'afficher, pour ne pas
/// présenter quatre pistes dont trois n'existent pas. Cette vérification se
/// fait par requêtes HTTP : elle était à la fois trop chère et, pire, fausse
/// dans un cas — une piste existante sous une forme d'URL secondaire était
/// supprimée parce que la forme principale ne répondait pas.
///
/// Un petit serveur HTTP local répond ici comme un panel : il compte les
/// requêtes, ce qui est le seul moyen de mesurer le coût réel.
void main() {
  late HttpServer server;
  late String base;
  final requested = <String>[];

  /// Chemins qui répondent avec un vrai sous-titre ; les autres, corps vide.
  final serving = <String>{};

  setUp(() async {
    requested.clear();
    serving.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      final path = request.uri.path;
      requested.add(path);
      request.response.headers.contentType = ContentType.text;
      if (serving.contains(path)) {
        request.response.write(
          '1\n00:00:01,000 --> 00:00:04,000\nBonjour\n\n',
        );
      }
      await request.response.close();
    });
  });

  tearDown(() async => server.close(force: true));

  SubtitleTrackRef trackWithAlternates({
    String? primary,
    String? second,
    String? third,
  }) {
    var ref = SubtitleTrackRef(
      url: primary ?? '$base/1_fr.srt',
      language: 'fr',
      label: 'Français',
    );
    if (second != null || third != null) {
      ref = ref.copyWith(
        alternates: [
          if (second != null)
            SubtitleTrackRef(url: second, language: 'fr', label: 'Français'),
          if (third != null)
            SubtitleTrackRef(url: third, language: 'fr', label: 'Français'),
        ],
      );
    }
    return ref;
  }

  test('première forme disponible : une seule requête', () async {
    serving.add('/1_fr.srt');

    final kept = await SubtitleController().verifyTracks([
      trackWithAlternates(
        primary: '$base/1_fr.srt',
        second: '$base/1.srt',
        third: '$base/1.fre.srt',
      ),
    ]);

    expect(kept, hasLength(1));
    // Le panel répond du premier coup : inutile de tester les deux autres
    // formes, la sélection n'utiliserait que celle-ci.
    expect(requested, hasLength(1));
  });

  test('forme principale absente, repli disponible : la piste est gardée',
      () async {
    // C'est le défaut corrigé : le repli n'était jamais testé, donc une piste
    // servie sous une autre forme disparaissait de la liste.
    serving.add('/1.srt');

    final kept = await SubtitleController().verifyTracks([
      trackWithAlternates(
        primary: '$base/1_fr.srt',
        second: '$base/1.srt',
        third: '$base/1.fre.srt',
      ),
    ]);

    expect(kept, hasLength(1),
        reason: 'la piste existe, sous la forme secondaire');
    expect(requested, hasLength(2), reason: 'on s’arrête au premier succès');
    expect(kept.first.url, '$base/1.srt',
        reason: 'la forme gagnante devient l’URL principale');
  });

  test('aucune forme disponible : la piste disparaît', () async {
    final kept = await SubtitleController().verifyTracks([
      trackWithAlternates(
        primary: '$base/9_fr.srt',
        second: '$base/9.srt',
        third: '$base/9.fre.srt',
      ),
    ]);

    expect(kept, isEmpty);
    expect(requested, hasLength(3));
  });

  test('quatre pistes absentes coûtent douze requêtes, pas quatre', () async {
    // Bornage théorique : le pire cas est len(candidats) par piste. C'est
    // acceptable parce qu'il n'atteint ce maximum que si rien n'existe, et le
    // cache de session rend la deuxième ouverture gratuite.
    final tracks = [
      for (var i = 0; i < 4; i++)
        trackWithAlternates(
          primary: '$base/$i-fr.srt',
          second: '$base/$i.srt',
          third: '$base/$i-fre.srt',
        ),
    ];

    final kept = await SubtitleController().verifyTracks(tracks);

    expect(kept, isEmpty);
    expect(requested, hasLength(12));
  });

  test('le cache de session évite de re-tester', () async {
    serving.add('/1_fr.srt');
    final controller = SubtitleController();

    await controller.verifyTracks([
      trackWithAlternates(primary: '$base/1_fr.srt', second: '$base/1.srt'),
    ]);
    final afterFirst = requested.length;

    await controller.verifyTracks([
      trackWithAlternates(primary: '$base/1_fr.srt', second: '$base/1.srt'),
    ]);

    expect(requested.length, afterFirst,
        reason: 'aucune requête supplémentaire pour la même URL');
  });
}