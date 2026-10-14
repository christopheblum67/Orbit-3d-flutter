import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Exclusivité et polling des sous-titres intégrés dans [SubtitleController].
///
/// Le canal natif est simulé par un `setMockMethodCallHandler` : on teste la
/// logique du contrôleur (quel canal est appelé, quand, et avec quels effets),
/// sans exécuter le vrai lecteur media3 — qui n'existe pas sous `flutter test`.
///
/// Les tests utilisent `testWidgets` volontairement : le binding de widgets
/// fournit un horloge FAUSSE, seul moyen de faire avancer le `Timer.periodic`
/// du polling (`tester.pump(Duration)`) sans attendre réellement 300 ms.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.io/videoPlayer/tracks');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <MethodCall>[];
  Map<Object?, Object?> cuesReply = const <Object?, Object?>{};

  setUp(() {
    calls.clear();
    cuesReply = const <Object?, Object?>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getCurrentCues':
          return cuesReply;
        default:
          // getSubtitleTracks / selectSubtitleTrack / clearSubtitleTracks.
          return null;
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  EmbeddedSubtitleTrack forcedTrack() => const EmbeddedSubtitleTrack(
        id: '3_0',
        label: 'VFF : Forced',
        language: 'fr',
        isSelected: true,
        isForced: true,
        mimeType: null,
      );

  EmbeddedSubtitleTrack fullTrack() => const EmbeddedSubtitleTrack(
        id: '4_0',
        label: 'VFF : Full',
        language: 'fr',
        isSelected: false,
        isForced: false,
        mimeType: null,
      );

  SubtitleTrack externalTrack() => const SubtitleTrack(
        language: 'fr',
        label: 'externe',
        cues: <SubtitleCue>[],
      );

  int countOf(String method) => calls.where((c) => c.method == method).length;

  testWidgets('setEmbeddedContext adopte la piste sélectionnée par media3',
      (tester) async {
    final ctrl = SubtitleController();

    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack(), fullTrack()]);
    await tester.pump();

    expect(ctrl.embeddedTracks, hasLength(2));
    expect(
      ctrl.activeEmbeddedTrackId,
      '3_0',
      reason: 'la piste que media3 a marquée sélectionnée (forced) devient '
          'la piste intégrée active',
    );
    expect(ctrl.hasActiveEmbedded, isTrue);
    // Le polling démarre dès qu'une piste intégrée est active : un premier
    // tick immédiat, pour ne pas attendre 300 ms avant le premier texte.
    expect(countOf('getCurrentCues'), greaterThanOrEqualTo(1));

    ctrl.dispose();
  });

  testWidgets('setEmbeddedContext rejoué ne vole pas la piste choisie',
      (tester) async {
    // Régression : la découverte est rejouée pendant que les pistes texte
    // arrivent par vagues. Chaque re-scan appelait setEmbeddedContext, qui
    // ré-adoptait la sélection automatique de media3 — effaçant le choix de
    // l'utilisateur fait entre-temps.
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack(), fullTrack()]);
    await tester.pump();
    await ctrl.selectEmbeddedTrack('4_0');
    expect(ctrl.activeEmbeddedTrackId, '4_0');

    ctrl.setEmbeddedContext(
      playerId: 7,
      tracks: [
        forcedTrack(),
        fullTrack(),
        const EmbeddedSubtitleTrack(
          id: '5_0',
          label: 'VFQ',
          language: 'fr',
          isSelected: true,
          isForced: false,
          mimeType: null,
        ),
      ],
    );

    expect(
      ctrl.activeEmbeddedTrackId,
      '4_0',
      reason: 'une nouvelle vague de pistes ne doit pas voler le choix',
    );
    expect(ctrl.embeddedTracks, hasLength(3));

    ctrl.dispose();
  });

  testWidgets(
      'setEmbeddedContext replie sur media3 si la piste active disparaît',
      (tester) async {
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack(), fullTrack()]);
    await ctrl.selectEmbeddedTrack('4_0');
    expect(ctrl.activeEmbeddedTrackId, '4_0');

    // « Full » disparaît : « Forced » (sélectionnée par media3) reste.
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack()]);

    expect(ctrl.activeEmbeddedTrackId, '3_0');

    ctrl.dispose();
  });

  testWidgets('selectEmbeddedTrack coupe la piste externe (exclusivité)',
      (tester) async {
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack(), fullTrack()]);

    // Une piste externe prend le relais : l'intégrée est éteinte.
    ctrl.adoptTrack(externalTrack(), 'externe');
    expect(ctrl.activeTrack, isNotNull);
    expect(ctrl.hasActiveEmbedded, isFalse);

    // Puis l'utilisateur choisit une AUTRE piste intégrée.
    await ctrl.selectEmbeddedTrack('4_0');

    expect(ctrl.activeEmbeddedTrackId, '4_0');
    expect(
      ctrl.activeTrack,
      isNull,
      reason: 'sélectionner une piste intégrée doit couper l\'externe, '
          'sinon les deux s\'afficheraient',
    );
    expect(ctrl.activeTrackUrl, isNull);
    expect(
      calls.where((c) => c.method == 'selectSubtitleTrack').single.arguments,
      <String, dynamic>{'playerId': 7, 'trackId': '4_0'},
    );

    ctrl.dispose();
  });

  testWidgets('adopter une piste externe dé-sélectionne l\'intégrée côté natif',
      (tester) async {
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack()]);
    expect(ctrl.hasActiveEmbedded, isTrue);
    expect(countOf('clearSubtitleTracks'), 0);

    ctrl.adoptTrack(externalTrack(), 'externe');
    await tester.pump(); // laisse partir l'appel clearTracks (async)

    expect(ctrl.hasActiveEmbedded, isFalse);
    expect(ctrl.liveEmbeddedCues, isNull);
    expect(
      countOf('clearSubtitleTracks'),
      1,
      reason: 'sans cet appel natif, la piste intégrée resterait '
          'sélectionnée et s\'afficherait en même temps que l\'externe',
    );

    ctrl.dispose();
  });

  testWidgets(
      'une vague intégrée TARDIVE ne vole pas la piste externe (OpenSubtitles)',
      (tester) async {
    // Régression observée par l'utilisateur : « les sous-titres OpenSubtitles
    // ne se lisent plus » alors que les intégrés fonctionnent.
    //
    // Séquence réelle. media3 auto-sélectionne une piste texte quelques
    // SECONDES après le début de la lecture, pas au premier sondage : au
    // démarrage, les pistes texte du manifeste sont souvent connues mais
    // aucune n'est encore sélectionnée. Si l'utilisateur choisit un
    // sous-titre OpenSubtitles dans cette fenêtre, sa piste est adoptée avec
    // `_activeEmbeddedTrackId == null` — donc `_cancelEmbeddedForExternal`
    // sortait sans rien couper. Quand media3 sélectionnait enfin sa piste
    // (souvent la « forced ») ET que la liste s'enrichissait, la signature
    // changeait, `setEmbeddedContext` était rappelé et ré-adoptait la piste
    // intégrée : l'overlay intégré prenait la place du sous-titre externe.
    final ctrl = SubtitleController();

    // 1. Première sonde : une piste existe, AUCUNE sélectionnée.
    ctrl.setEmbeddedContext(playerId: 7, tracks: [fullTrack()]);
    await tester.pump();
    expect(
      ctrl.hasActiveEmbedded,
      isFalse,
      reason: 'media3 n\'a encore rien auto-sélectionné',
    );

    // 2. L'utilisateur choisit un sous-titre OpenSubtitles.
    ctrl.adoptTrack(externalTrack(), 'OpenSubtitles FR');
    expect(ctrl.activeTrack, isNotNull);
    expect(ctrl.hasActiveEmbedded, isFalse);

    // 3. media3 sélectionne enfin sa piste « forced » : nouvelle liste, donc
    //    nouvelle signature, donc `setEmbeddedContext` est rappelé.
    const lateForced = EmbeddedSubtitleTrack(
      id: '3_0',
      label: 'VFF : Forced',
      language: 'fr',
      isSelected: true,
      isForced: true,
      mimeType: null,
    );
    ctrl.setEmbeddedContext(playerId: 7, tracks: [lateForced, fullTrack()]);

    expect(
      ctrl.hasActiveEmbedded,
      isFalse,
      reason: 'une piste intégrée apparue APRÈS le choix externe ne doit pas '
          'reprendre l\'affichage : l\'overlay intégré masquerait le '
          'sous-titre OpenSubtitles, qui « ne se lit plus »',
    );
    expect(
      ctrl.activeTrack,
      isNotNull,
      reason: 'le sous-titre externe reste la piste active',
    );

    ctrl.dispose();
  });

  testWidgets('adopter un externe coupe le natif même si rien n\'est actif',
      (tester) async {
    // Même cause racine que ci-dessus, vue côté canal : quand aucune piste
    // intégrée n'est active au moment du choix externe, il faut quand même
    // désactiver le type « texte » côté natif — sinon media3 reste libre
    // d'auto-sélectionner une piste plus tard (cf. test précédent).
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [fullTrack()]);
    await tester.pump();
    expect(ctrl.hasActiveEmbedded, isFalse);
    calls.clear();

    ctrl.adoptTrack(externalTrack(), 'OpenSubtitles FR');
    await tester.pump();

    expect(
      countOf('clearSubtitleTracks'),
      1,
      reason: 'sans cet appel natif, media3 peut encore auto-sélectionner une '
          'piste texte et masquer le sous-titre externe',
    );

    ctrl.dispose();
  });

  testWidgets('selectEmbeddedTrack ignore un id inconnu', (tester) async {
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack(), fullTrack()]);
    calls.clear();

    await ctrl.selectEmbeddedTrack('inexistant');

    expect(countOf('selectSubtitleTrack'), 0);
    expect(
      ctrl.activeEmbeddedTrackId,
      '3_0',
      reason: 'un id inconnu ne doit rien changer',
    );

    ctrl.dispose();
  });

  testWidgets('le polling publie les cues et suit le contenu', (tester) async {
    final ctrl = SubtitleController();
    cuesReply = <Object?, Object?>{
      'presentationTimeUs': 1000,
      'cues': <Object?>[
        <Object?, Object?>{'text': 'Bonjour'},
      ],
    };

    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack()]);
    await tester.pump();
    expect(ctrl.liveEmbeddedCues?.texts, ['Bonjour']);

    // Tick suivant : contenu différent → nouveau groupe publié.
    cuesReply = <Object?, Object?>{
      'presentationTimeUs': 4000,
      'cues': <Object?>[
        <Object?, Object?>{'text': 'Au revoir'},
      ],
    };
    await tester.pump(const Duration(milliseconds: 300));
    expect(ctrl.liveEmbeddedCues?.texts, ['Au revoir']);

    ctrl.dispose();
  });

  testWidgets('un tick au contenu identique ne notifie pas', (tester) async {
    final ctrl = SubtitleController();
    cuesReply = <Object?, Object?>{
      'presentationTimeUs': 1000,
      'cues': <Object?>[
        <Object?, Object?>{'text': 'Stable'},
      ],
    };
    var notifications = 0;
    ctrl.addListener(() => notifications++);

    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack()]);
    await tester.pump();
    final afterFirst = notifications;
    expect(afterFirst, greaterThan(0));

    // Deuxième tick, même position, même texte : aucun rebuild.
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      notifications,
      afterFirst,
      reason: 'un contenu identique est ré-émis à chaque tick ; le notifier '
          'se serait reconstruit 3 fois par seconde pour rien',
    );

    ctrl.dispose();
  });

  testWidgets('disableEmbedded éteint et dé-sélectionne côté natif',
      (tester) async {
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack()]);
    await tester.pump();

    ctrl.disableEmbedded();
    await tester.pump();

    expect(ctrl.hasActiveEmbedded, isFalse);
    expect(ctrl.liveEmbeddedCues, isNull);
    expect(countOf('clearSubtitleTracks'), 1);

    ctrl.dispose();
  });

  testWidgets('detachEmbedded coupe l\'état et arrête le polling',
      (tester) async {
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack()]);
    await tester.pump();
    expect(ctrl.hasActiveEmbedded, isTrue);

    ctrl.detachEmbedded(7);
    expect(ctrl.hasActiveEmbedded, isFalse);
    expect(ctrl.embeddedTracks, isEmpty);
    expect(ctrl.liveEmbeddedCues, isNull);

    // Le polling est arrêté : plus aucun appel après plusieurs intervalles.
    final polled = countOf('getCurrentCues');
    await tester.pump(const Duration(seconds: 2));
    expect(
      countOf('getCurrentCues'),
      polled,
      reason: 'sans annulation du Timer, le polling continuerait de frapper '
          'un lecteur détruit',
    );

    ctrl.dispose();
  });

  group('cycle de vie : une liste vide ne détruit pas les pistes', () {
    // Le contrôleur n'a pas la règle de propagation — elle est dans
    // `player_screen`. On vérifie ici le COMPORTEMENT DU CONTRÔLEUR qui en
    // découle, pour verrouiller le contrat des deux côtés.

    testWidgets('les 6 pistes restent disponibles après une liste vide',
        (tester) async {
      // Scénario réel du logcat : 6 pistes détectées, puis une sonde vide.
      final six = [
        const EmbeddedSubtitleTrack(
          id: '3_0',
          label: 'Forced',
          language: 'fr',
          isSelected: true,
          isForced: true,
          mimeType: null,
        ),
        for (final id in ['4_0', '5_0', '6_0', '7_0', '8_0'])
          EmbeddedSubtitleTrack(
            id: id,
            label: 'Piste $id',
            language: 'fr',
            isSelected: false,
            isForced: false,
            mimeType: null,
          ),
      ];

      final ctrl = SubtitleController();
      ctrl.setEmbeddedContext(playerId: 7, tracks: six);
      expect(ctrl.embeddedTracks, hasLength(6));

      // La règle de propagation refuse la liste vide : le contrôleur n'est donc
      // JAMAIS appelé avec elle. Si elle l'était, la section disparaîtrait.
      final propagate = shouldPropagateEmbeddedTracks(
        tracks: const [],
        previousSignature: embeddedTracksSignature(six),
      );
      expect(propagate, isFalse);
      expect(ctrl.embeddedTracks, hasLength(6));

      ctrl.dispose();
    });

    testWidgets('changement de lecteur : l\'état précédent est libéré',
        (tester) async {
      final ctrl = SubtitleController();
      final old = [
        const EmbeddedSubtitleTrack(
          id: '3_0',
          label: 'Forced',
          language: 'fr',
          isSelected: true,
          isForced: true,
          mimeType: null,
        ),
      ];

      ctrl.setEmbeddedContext(playerId: 7, tracks: old);
      await tester.pump();
      expect(ctrl.embeddedTracks, hasLength(1));

      // `detachEmbedded` du lecteur 7 : plus rien ne doit lui appartenir.
      ctrl.detachEmbedded(7);
      expect(ctrl.embeddedTracks, isEmpty);
      expect(ctrl.hasActiveEmbedded, isFalse);

      // Le lecteur 9 repart d'une signature vierge : sa première sonde peut
      // conclu « pas de piste intégrée » sans hériter de l'ancien contenu.
      expect(
        shouldPropagateEmbeddedTracks(
          tracks: const [],
          previousSignature: kEmbeddedSigUnset,
        ),
        isTrue,
      );

      ctrl.dispose();
    });
  });

  testWidgets('le contenu suivant ne garde pas la piste externe du précédent',
      (tester) async {
    // Bug préexistant hors OpenSubtitles : le contrôleur est partagé par toute
    // l'app (Provider non autoDispose) et `_activeTrack` n'était JAMAIS
    // réinitialisé entre deux contenus. Après un film sous-titré
    // (OpenSubtitles) puis un zapping / un autre film, les cues de l'ANCIENNE
    // piste continuaient de s'afficher sur le NOUVEAU contenu. Le correctif
    // expose `resetForNewContent()`, appelé par le player à chaque changement
    // de contenu.
    final ctrl = SubtitleController();

    // Contenu A : contexte posé, l'utilisateur choisit un sous-titre externe.
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack(), fullTrack()]);
    await tester.pump();
    ctrl.adoptTrack(externalTrack(), 'OpenSubtitles FR');
    expect(ctrl.activeTrack, isNotNull);

    // Changement de contenu : l'écran appelle le reset avant de basculer.
    ctrl.resetForNewContent();

    expect(
      ctrl.activeTrack,
      isNull,
      reason: 'la piste externe du film précédent ne doit pas s\'afficher '
          'sur le contenu suivant',
    );
    expect(ctrl.activeTrackUrl, isNull);
    expect(
      ctrl.hasActiveEmbedded,
      isFalse,
      reason: 'l\'état intégré du contenu précédent est aussi libéré',
    );
    expect(ctrl.embeddedTracks, isEmpty);

    // Le contenu B repart proprement : sa découverte peut adopter la piste
    // sélectionnée par media3, sans garde d'exclusivité parasite.
    ctrl.setEmbeddedContext(
      playerId: 9,
      tracks: [forcedTrack(), fullTrack()],
    );
    await tester.pump();
    expect(ctrl.activeEmbeddedTrackId, '3_0');
    expect(ctrl.embeddedTracks, hasLength(2));

    ctrl.dispose();
  });

  testWidgets('detachEmbedded d\'un AUTRE lecteur ne coupe rien',
      (tester) async {
    final ctrl = SubtitleController();
    ctrl.setEmbeddedContext(playerId: 7, tracks: [forcedTrack()]);
    await tester.pump();

    ctrl.detachEmbedded(8); // autre texture (préchauffage)

    expect(
      ctrl.hasActiveEmbedded,
      isTrue,
      reason: 'le contrôleur est partagé : couper le pont d\'une texture '
          'étrangère laisserait le lecteur en cours sans sous-titres',
    );
    expect(ctrl.embeddedTracks, hasLength(1));

    ctrl.dispose();
  });
}
