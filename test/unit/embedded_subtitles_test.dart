import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';

/// Pont et décodage des sous-titres INTÉGRÉS (pistes embarquées media3).
///
/// Le natif (fork `video_player_android`) répond sur
/// `flutter.io/videoPlayer/tracks` avec des maps brutes (`Map<Object?, Object?>`
/// après passage par le codec standard) : ces tests fixent le contrat de
/// décodage ET les arguments envoyés, parce qu'une faute de casse sur une clé
/// (p. ex. `isForced` vs `is_forced`) ne se voit qu'à l'exécution sur un vrai
/// contenu. Le canal est simulé : aucune plateforme n'est nécessaire.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.io/videoPlayer/tracks');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <MethodCall>[];

  setUp(calls.clear);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('EmbeddedSubtitleTrack.fromMap', () {
    test('lit tous les champs annoncés par le natif', () {
      final t = EmbeddedSubtitleTrack.fromMap(<Object?, Object?>{
        'id': '3_0',
        'label': 'VFF : Forced',
        'language': 'fr',
        'isSelected': true,
        'isForced': true,
        'mimeType': 'application/x-subrip',
      });
      expect(t.id, '3_0');
      expect(t.label, 'VFF : Forced');
      expect(t.language, 'fr');
      expect(t.isSelected, isTrue);
      expect(t.isForced, isTrue);
      expect(t.mimeType, 'application/x-subrip');
    });

    test('tolère les champs absents ou d\'un type inattendu', () {
      // Une piste sans métadonnée n'a pas de `label` : sans repli, l'UI
      // afficherait « null ». Les drapeaux sont lus par `== true` : un `null`
      // ou une chaîne ne doivent pas lever ni être pris pour `true`.
      final t = EmbeddedSubtitleTrack.fromMap(<Object?, Object?>{'id': '9_1'});
      expect(t.label, 'Sous-titres');
      expect(t.language, isNull);
      expect(t.isSelected, isFalse);
      expect(t.isForced, isFalse);
      expect(t.mimeType, isNull);
    });
  });

  group('EmbeddedSubtitleCues.fromMap', () {
    test('ne garde que les textes non vides', () {
      // media3 émet un groupe où une cue peut porter un bitmap (pas de texte) :
      // l'overlay Flutter ne sait rendre que le texte, ces cues sont ignorées.
      final c = EmbeddedSubtitleCues.fromMap(<Object?, Object?>{
        'presentationTimeUs': 1200000,
        'cues': <Object?>[
          <Object?, Object?>{'text': 'Bonjour'},
          <Object?, Object?>{'text': '   '},
          <Object?, Object?>{},
          <Object?, Object?>{'text': 'Monde'},
        ],
      });
      expect(c.presentationTimeUs, 1200000);
      expect(c.texts, ['Bonjour', 'Monde']);
      expect(c.isEmpty, isFalse);
    });

    test('une map vide ou sans cues donne un groupe vide', () {
      final c = EmbeddedSubtitleCues.fromMap(const <Object?, Object?>{});
      expect(c.presentationTimeUs, 0);
      expect(c.texts, isEmpty);
      expect(c.isEmpty, isTrue);
    });
  });

  group('EmbeddedSubtitleCues.sameContent', () {
    EmbeddedSubtitleCues cues(int us, List<String> texts) =>
        EmbeddedSubtitleCues(presentationTimeUs: us, texts: texts);

    test('identique quand position et textes concordent', () {
      expect(cues(1, ['a', 'b']).sameContent(cues(1, ['a', 'b'])), isTrue);
    });

    test('différent si la position diffère', () {
      expect(cues(1, ['a']).sameContent(cues(2, ['a'])), isFalse);
    });

    test('différent si un texte diffère', () {
      expect(cues(1, ['a']).sameContent(cues(1, ['b'])), isFalse);
    });

    test('différent si le nombre de textes diffère', () {
      expect(cues(1, ['a']).sameContent(cues(1, ['a', 'b'])), isFalse);
    });
  });

  group('shouldPropagateEmbeddedTracks', () {
    EmbeddedSubtitleTrack t(String id, [String label = 'Piste']) =>
        EmbeddedSubtitleTrack(
          id: id,
          label: label,
          language: 'fr',
          isSelected: false,
          isForced: false,
          mimeType: null,
        );

    test('PREMIÈRE sonde vide : accepté (le contenu n\'a rien)', () {
      // C'est le SEUL cas où une liste vide est une information : elle précède
      // tout état hérité du contenu précédent.
      expect(
        shouldPropagateEmbeddedTracks(
          tracks: const [],
          previousSignature: kEmbeddedSigUnset,
        ),
        isTrue,
      );
    });

    test('RÉGRESSION : liste vide APRÈS des pistes connues → ignorée', () {
      // Media3 reconstruit ses groupes entre deux `tracksChanged` :
      // `getCurrentTracks()` rend alors une liste vide alors que le contenu en
      // contient six. La propager effaçait la section déjà affichée.
      final six = [
        t('3_0', 'Forced'),
        t('4_0', 'Full'),
        t('5_0', 'VFQ'),
        t('6_0', 'SDH'),
        t('7_0', 'SDH en'),
        t('8_0', 'SDH en 2'),
      ];
      final sig = embeddedTracksSignature(six);

      expect(
        shouldPropagateEmbeddedTracks(
          tracks: const [],
          previousSignature: sig,
        ),
        isFalse,
        reason: 'une liste vide transitoire ne doit pas effacer des pistes '
            'déjà annoncées',
      );
    });

    test('actualisation : une liste NON VIDE remplace toujours', () {
      final before = embeddedTracksSignature([t('3_0', 'Forced')]);
      expect(
        shouldPropagateEmbeddedTracks(
          tracks: [t('3_0', 'Forced'), t('4_0', 'Full')],
          previousSignature: before,
        ),
        isTrue,
      );
    });

    test('signature : seule l\'identité compte, pas la sélection auto', () {
      const a = EmbeddedSubtitleTrack(
        id: '3_0',
        label: 'Forced',
        language: 'fr',
        isSelected: true,
        isForced: true,
        mimeType: null,
      );
      const b = EmbeddedSubtitleTrack(
        id: '3_0',
        label: 'Forced',
        language: 'fr',
        isSelected: false,
        isForced: true,
        mimeType: null,
      );
      expect(
        embeddedTracksSignature([a]),
        embeddedTracksSignature([b]),
        reason: 'media3 peut changer sa sélection sans changer la liste ; '
            'l\'inclure ferait perdre la main sur le choix de l\'utilisateur',
      );
    });
  });

  group('EmbeddedSubtitleBridge', () {
    EmbeddedSubtitleBridge bridge() => EmbeddedSubtitleBridge(42);

    test('getTracks lit la liste du canal et la décode', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return <Object?>[
          <Object?, Object?>{
            'id': '4_0',
            'label': 'VFF : Full',
            'language': 'fr',
            'isSelected': false,
            'isForced': false,
          },
        ];
      });

      final tracks = await bridge().getTracks();

      expect(calls.single.method, 'getSubtitleTracks');
      expect(calls.single.arguments, <String, dynamic>{'playerId': 42});
      expect(tracks, hasLength(1));
      expect(tracks.single.id, '4_0');
      expect(tracks.single.label, 'VFF : Full');
    });

    test('currentCues décode le groupe courant', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return <Object?, Object?>{
          'presentationTimeUs': 500,
          'cues': <Object?>[
            <Object?, Object?>{'text': 'Ligne'},
          ],
        };
      });

      final c = await bridge().currentCues();

      expect(calls.single.method, 'getCurrentCues');
      expect(c.presentationTimeUs, 500);
      expect(c.texts, ['Ligne']);
    });

    test('selectTrack transmet playerId et trackId', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });

      await bridge().selectTrack('3_0');

      expect(calls.single.method, 'selectSubtitleTrack');
      expect(
        calls.single.arguments,
        <String, dynamic>{'playerId': 42, 'trackId': '3_0'},
      );
    });

    test('clearTracks transmet le playerId', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });

      await bridge().clearTracks();

      expect(calls.single.method, 'clearSubtitleTracks');
      expect(calls.single.arguments, <String, dynamic>{'playerId': 42});
    });
  });
}
