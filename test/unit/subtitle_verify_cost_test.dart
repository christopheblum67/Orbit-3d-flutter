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

  test('une panne réseau ne fige PAS la piste comme valide', () async {
    // Régression : le code faisait `_existsCache[url] = isPayload ? false : true`.
    // Une panne réseau inscrivant `true` rendait la piste « vérifiée » pour
    // toute la session, sur un cache statique sans TTL dont la clé contient
    // les identifiants du panel — donc jamais invalidable au changement de
    // compte. Le commentaire affirmait l'inverse de ce que le code faisait.
    //
    // La panne doit être une VRAIE coupure réseau, pas un code d'erreur :
    // `parseFromUrl` transforme un 4xx/5xx en `SubtitlePayloadException`, donc
    // un 500 prouve une absence et doit être mémorisé comme tel. Un port fermé
    // provoque une `SocketException`, seulesource d'incertitude réelle.
    final deadPort = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = deadPort.port;
    await deadPort.close();

    final ref = SubtitleTrackRef(
      url: 'http://127.0.0.1:$port/panne.srt',
      language: 'fr',
      label: 'panne',
    );

    final kept = await SubtitleController().verifyTracks([ref]);
    expect(
      kept.map((e) => e.url),
      contains(ref.url),
      reason: 'une panne ne prouve pas que la piste est absente : elle doit '
          'être CONSERVÉE',
    );

    // Le cœur de la régression : la piste est CONSERVÉE, mais surtout elle ne
    // doit pas être mémorisée. Sans ce contrôle, les deux branches renvoient la
    // même liste et le test passerait même avec le bug.
    expect(SubtitleController.isCached(ref.url), isFalse,
        reason: 'une panne réseau ne doit PAS entrer dans le cache : elle '
            'rendrait la piste « vérifiée » à vie, pour toute la session');

    final again = await SubtitleController().verifyTracks([ref]);
    expect(again, hasLength(1),
        reason: 'une piste jamais conclue doit rester à retester');
    expect(SubtitleController.isCached(ref.url), isFalse,
        reason: 'et toujours rien en cache après une seconde tentative');
  });

  test('une absence DÉFINITIVE est, elle, mémorisée', () async {
    // Le contrepoids indispensable : si rien n'était jamais mémorisé, le cache
    // ne servirait à rien et chaque ouverture re-testerait 32 URL.
    final server5 = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server5.close(force: true));
    server5.listen((request) {
      request.response.statusCode = 200;
      request.response.close(); // corps vide = absence
    });

    final ref = SubtitleTrackRef(
      url: 'http://127.0.0.1:${server5.port}/definitivement-absent.srt',
      language: 'fr',
      label: 'absent',
    );

    await SubtitleController().verifyTracks([ref]);
    expect(SubtitleController.isCached(ref.url), isTrue,
        reason: 'un corps vide est une conclusion définitive : la memoriser '
            'évite de re-tester à chaque ouverture du panneau');
  });

  test('un code d\'erreur HTTP, lui, marque la piste comme absente', () async {
    // Contrepoint du test précédent : un 500 est une RÉPONSE. Le parseur en
    // fait un `SubtitlePayloadException`, donc une absence DÉFINITIVE, et la
    // mise en cache est correcte.
    final server4 = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server4.close(force: true));
    server4.listen((request) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.close();
    });

    final ref = SubtitleTrackRef(
      url: 'http://127.0.0.1:${server4.port}/absent.srt',
      language: 'fr',
      label: 'absent',
    );
    final kept = await SubtitleController().verifyTracks([ref]);
    expect(kept, isEmpty,
        reason: 'un 404 est une preuve DÉFINITIVE d\'absence');
  });

  test('un corps VIDE, lui, marque la piste comme absente', () async {
    // Le serveur principal répond 200 avec un corps vide pour les chemins non
    // listés dans `serving` : c'est la preuve DÉFINITIVE d'absence.
    final ref = SubtitleTrackRef(
      url: '$base/vide.srt',
      language: 'fr',
      label: 'vide',
    );
    final kept = await SubtitleController().verifyTracks([ref]);
    expect(kept, isEmpty,
        reason: 'un corps vide est une preuve DÉFINITIVE d\'absence');
  });

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