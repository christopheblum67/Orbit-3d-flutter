import 'dart:ui' show Size;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:video_player/video_player.dart';

/// Joueur factice : `StallDetector` ne lit que `value`, on pilote donc la
/// valeur exposee pour simuler exactement les etats que video_player remonte
/// (lecture, pause, buffer, position figee/avancee).
class _FakePlayer implements StallWatchable {
  _FakePlayer(this._value);

  VideoPlayerValue _value;

  @override
  VideoPlayerValue get value => _value;

  @override
  Object get source => this;

  set value(VideoPlayerValue v) => _value = v;
}

VideoPlayerValue _playing({
  Duration position = const Duration(seconds: 10),
  bool isBuffering = false,
}) =>
    VideoPlayerValue(
      duration: const Duration(hours: 1),
      isInitialized: true,
      isPlaying: true,
      isBuffering: isBuffering,
      position: position,
    );

/// Seuils reduits pour que les tests restent instantanes : 3 checks de 50 ms
/// = 150 ms, seuil de 200 ms (le 4e check declenche le stall).
const _interval = Duration(milliseconds: 50);
const _threshold = Duration(milliseconds: 200);
const _elapse = Duration(milliseconds: 260);

StallDetector _detector() => StallDetector(
      checkInterval: _interval,
      stallThreshold: _threshold,
      minChecksForStall: 3,
    );

void main() {
  group('StallDetector', () {
    late StallDetector detector;

    setUp(() {
      detector = _detector();
    });

    tearDown(() {
      detector.dispose();
    });

    test('initial state: not stalling, not running', () {
      expect(detector.isStalling, isFalse);
      expect(detector.isRunning, isFalse);
    });

    test('starts and stops monitoring', () {
      fakeAsync((fa) {
        final player = _FakePlayer(_playing());
        detector.start(player);
        expect(detector.isRunning, isTrue);
        expect(detector.isAttachedTo(player), isTrue);

        detector.stop();
        expect(detector.isRunning, isFalse);
        expect(detector.isStalling, isFalse);
        expect(detector.isAttachedTo(player), isFalse);
        // Aucun tick ne doit plusDeclencher quoi que ce soit.
        fa.elapse(const Duration(seconds: 1));
      });
    });

    test('dispose stops monitoring', () {
      final d = _detector();
      d.dispose();
      expect(d.isRunning, isFalse);
    });

    test('configuration parameters are respected', () {
      final detector1 = StallDetector(
        checkInterval: const Duration(seconds: 1),
        stallThreshold: const Duration(seconds: 10),
        minChecksForStall: 5,
      );
      expect(detector1.isRunning, isFalse);
      detector1.dispose();

      final detector2 = StallDetector(
        checkInterval: const Duration(milliseconds: 100),
        stallThreshold: const Duration(seconds: 5),
        minChecksForStall: 2,
      );
      expect(detector2.isRunning, isFalse);
      detector2.dispose();
    });
  });

  group('StallDetector - mécanisme de détection', () {
    test('une position qui avance ne lève jamais de stall', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(_playing(position: Duration.zero));
        detector.start(player);

        for (var i = 1; i <= 6; i++) {
          player.value = _playing(position: Duration(seconds: i));
          fa.elapse(_interval);
        }

        expect(detector.isStalling, isFalse);
        expect(detector.bufferingChecks, 0);
        detector.dispose();
      });
    });

    test('une position figée signale un stall après le seuil', () {
      fakeAsync((fa) {
        final detector = _detector();
        var notifications = 0;
        detector.addListener(() => notifications++);
        final player = _FakePlayer(_playing());
        detector.start(player);

        // 2 checks : sous le seuil, rien encore.
        fa.elapse(const Duration(milliseconds: 120));
        expect(detector.isStalling, isFalse);

        fa.elapse(_elapse);
        expect(detector.isStalling, isTrue);
        expect(notifications, greaterThan(0));
        detector.dispose();
      });
    });

    test('un rebuffer court suivi d’une reprise ne lève pas de stall', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(_playing(isBuffering: true));
        detector.start(player);

        // 2 checks en buffer, puis la lecture reprend et la position avance.
        fa.elapse(const Duration(milliseconds: 120));
        expect(detector.isStalling, isFalse);
        expect(detector.bufferingChecks, 2);

        player.value = _playing(position: const Duration(seconds: 12));
        fa.elapse(_interval);
        expect(detector.isStalling, isFalse);
        // Le compteur est remis à zéro dès que la progression est constatée.
        expect(detector.bufferingChecks, 0);
        detector.dispose();
      });
    });

    test('un blocage continu en buffering lève un stall (isPlaying false)', () {
      // C’est le mode de défaillance silencieux le plus grave : image noire,
      // son muet, isPlaying == false et isBuffering == true. Avant, le
      // détecteur sortait sur le garde `!isPlaying` et ne voyait rien.
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(
          const VideoPlayerValue(
            duration: Duration(hours: 1),
            isInitialized: true,
            isPlaying: false,
            isBuffering: true,
            position: Duration(seconds: 3),
          ),
        );
        detector.start(player);

        fa.elapse(_elapse);
        expect(detector.isStalling, isTrue);
        expect(detector.bufferingChecks, greaterThanOrEqualTo(3));
        detector.dispose();
      });
    });

    test('une pause volontaire n’est jamais un stall', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(
          const VideoPlayerValue(
            duration: Duration(hours: 1),
            isInitialized: true,
            isPlaying: false,
            position: Duration(seconds: 30),
          ),
        );
        detector.start(player);

        fa.elapse(const Duration(seconds: 2));
        expect(detector.isStalling, isFalse);
        expect(detector.bufferingChecks, 0);
        detector.dispose();
      });
    });

    test('la reprise de la position après un stall referme l’état', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(_playing());
        detector.start(player);

        fa.elapse(_elapse);
        expect(detector.isStalling, isTrue);

        player.value = _playing(position: const Duration(seconds: 42));
        fa.elapse(_interval);
        expect(detector.isStalling, isFalse);
        detector.dispose();
      });
    });

    test('tampon profond + position figée au début : gel de DÉMARRAGE', () {
      // C'est le cas relevé sur S20 : le flux arrivait (28 s de tampon) mais la
      // position restait à 0 s, sur une piste 4K. Annoncer « connexion instable
      // » aurait été faux — le réseau n'était pas en cause.
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(
          VideoPlayerValue(
            duration: const Duration(hours: 2),
            isInitialized: true,
            isPlaying: true,
            position: const Duration(milliseconds: 1),
            buffered: <DurationRange>[DurationRange(Duration.zero, const Duration(seconds: 28))],
            size: const Size(3840, 2160),
          ),
        );
        detector.start(player);
        fa.elapse(_elapse);

        expect(detector.isStalling, isTrue);
        expect(detector.stallKind, StallKind.notStarted);
        detector.dispose();
      });
    });

    test('position figée en cours de lecture : gel de LECTURE', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(
          VideoPlayerValue(
            duration: const Duration(hours: 2),
            isInitialized: true,
            isPlaying: true,
            position: const Duration(minutes: 12),
            buffered: <DurationRange>[DurationRange(Duration.zero, const Duration(seconds: 30))],
          ),
        );
        detector.start(player);
        fa.elapse(_elapse);

        expect(detector.isStalling, isTrue);
        expect(detector.stallKind, StallKind.frozen);
        detector.dispose();
      });
    });

    test('buffering continu : gel de BUFFERING (le seul cas réseau)', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(
          const VideoPlayerValue(
            duration: Duration(hours: 2),
            isInitialized: true,
            isPlaying: false,
            isBuffering: true,
            position: Duration(minutes: 12),
          ),
        );
        detector.start(player);
        fa.elapse(_elapse);

        expect(detector.isStalling, isTrue);
        expect(detector.stallKind, StallKind.buffering);
        detector.dispose();
      });
    });

    test('la reprise remet la cause à none', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(
          VideoPlayerValue(
            duration: const Duration(hours: 2),
            isInitialized: true,
            isPlaying: true,
            position: const Duration(minutes: 12),
            buffered: <DurationRange>[DurationRange(Duration.zero, const Duration(seconds: 30))],
          ),
        );
        detector.start(player);
        fa.elapse(_elapse);
        expect(detector.stallKind, isNot(StallKind.none));

        player.value = const VideoPlayerValue(
          duration: Duration(hours: 2),
          isInitialized: true,
          isPlaying: true,
          position: Duration(minutes: 13),
        );
        fa.elapse(_interval);
        expect(detector.stallKind, StallKind.none);
        detector.dispose();
      });
    });

    test('position figée MAIS tampon qui avance : aucun gel', () {
      // Le cas mesuré sur S20 : la vidéo rend à l'écran, `position` reste à
      // 1 ms, et seul le tampon progresse. Juger sur la position seule
      // affichait « Aperçu figé » sur un flux parfaitement sain.
      fakeAsync((fa) {
        final detector = _detector();
        var bufferedEnd = const Duration(seconds: 20);
        final player = _FakePlayer(
          VideoPlayerValue(
            duration: const Duration(hours: 2),
            isInitialized: true,
            isPlaying: true,
            position: const Duration(milliseconds: 1),
            buffered: <DurationRange>[DurationRange(Duration.zero, bufferedEnd)],
          ),
        );
        detector.start(player);

        // Le tampon avance de 3 s à chaque check, la position jamais.
        for (var i = 0; i < 6; i++) {
          bufferedEnd += const Duration(seconds: 3);
          player.value = VideoPlayerValue(
            duration: const Duration(hours: 2),
            isInitialized: true,
            isPlaying: true,
            position: const Duration(milliseconds: 1),
            buffered: <DurationRange>[
              DurationRange(Duration.zero, bufferedEnd),
            ],
          );
          fa.elapse(_interval);
        }

        expect(detector.isStalling, isFalse);
        expect(detector.stallKind, StallKind.none);
        detector.dispose();
      });
    });

    test('ni position ni tampon qui bougent : gel de LECTURE', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(
          VideoPlayerValue(
            duration: const Duration(hours: 2),
            isInitialized: true,
            isPlaying: true,
            position: const Duration(minutes: 12),
            buffered: <DurationRange>[
              DurationRange(Duration.zero, const Duration(seconds: 30)),
            ],
          ),
        );
        detector.start(player);
        // Le tampon ne bouge pas d'un check à l'autre.
        fa.elapse(_elapse);

        expect(detector.isStalling, isTrue);
        expect(detector.stallKind, StallKind.frozen);
        detector.dispose();
      });
    });

    test('start() sur le même contrôleur ne redémarre pas le timer', () {
      fakeAsync((fa) {
        final detector = _detector();
        final player = _FakePlayer(_playing());
        detector.start(player);
        fa.elapse(_interval);
        // Restart demandé (transition ready->ready) : la surveillance
        // repart proprement, un seul timer actif.
        detector.start(player);
        expect(detector.isRunning, isTrue);
        expect(detector.isAttachedTo(player), isTrue);

        fa.elapse(_elapse);
        expect(detector.isStalling, isTrue);
        detector.dispose();
      });
    });

    test('start() sur un contrôleur différent bascule la surveillance', () {
      fakeAsync((fa) {
        final detector = _detector();
        final first = _FakePlayer(_playing());
        detector.start(first);
        fa.elapse(_interval);
        expect(detector.isAttachedTo(first), isTrue);

        final second = _FakePlayer(_playing());
        detector.start(second);
        expect(detector.isAttachedTo(second), isTrue);
        expect(detector.isAttachedTo(first), isFalse);
        detector.dispose();
      });
    });
  });
}
