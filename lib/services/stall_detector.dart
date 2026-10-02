import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Cause d'un gel de lecture.
///
/// La distinction est nécessaire parce que les remèdes n'ont rien de commun,
/// et surtout parce qu'annoncer « connexion instable » pour un défaut de
/// décodage envoie l'utilisateur debugger sa box alors que son réseau
/// fonctionne parfaitement.
enum StallKind {
  /// Pas de gel.
  none,

  /// Le flux n'a jamais démarré : le tampon est rempli, mais la position
  /// reste collée au début. Le réseau et le panel sont donc hors de cause —
  /// c'est la lecture (piste trop lourde,surface absente) qui bloque.
  notStarted,

  /// La lecture a démarré puis s'est figée en cours de route, sans mise en
  /// tampon : le flux est reçu, la position ne progresse plus.
  frozen,

  /// Le lecteur remplit sa mémoire tampon : c'est le seul cas où l'on peut
  /// parler d'un problème de liaison ou de débit.
  buffering,
}

/// Détecteur de « stall » (flux figé) pendant la lecture.
///
/// Sur un flux LIVE, `controller.value.position` n'avance pas de façon continue :
/// le backend ne met la position à jour que par paliers, et pendant un simple
/// buffer la position reste immobile alors que `isPlaying` vaut toujours
/// `true`. Compter les checks « position inchangée » produisait donc des
/// faux positifs réguliers — l'écran annonçait « connexion instable » sur des
/// chaînes parfaitement stables, puis déclenchait une récupération inutile
/// qui coupait la lecture.
///
/// On ne compte un stall que si la position n'a pas bougé.
///
/// Abstraction minimale lue par le détecteur : seul [value] est utilisé, ce
/// qui permet de piloter le détecteur en test sans instancier un vrai
/// [VideoPlayerController] (classe à constructeur privé).
abstract class StallWatchable {
  VideoPlayerValue get value;

  /// Lecteur réellement observé, pour comparer deux observations sans
  /// dépendre de l'identité de l'adaptateur qui les enveloppe.
  Object get source;
}

/// Adaptateur du contrôleur réel vers [StallWatchable].
///
/// L'adaptation est explicite et non implicite : le compilateur AOT refuse
/// `VideoPlayerController` comme `StallWatchable` alors que l'analyseur
/// l'accepte (le membre `value` est hérité d'un `ValueNotifier<T>`, dont la
/// signature n'est pas considérée comme correspondance structurelle). S'y
/// fier produisait donc un build release cassé.
class VideoPlayerWatchable implements StallWatchable {
  VideoPlayerWatchable(this._controller);

  final VideoPlayerController _controller;

  @override
  VideoPlayerValue get value => _controller.value;

  @override
  Object get source => _controller;
}

class StallDetector extends ChangeNotifier {
  StallDetector({
    this.checkInterval = const Duration(seconds: 5),
    this.stallThreshold = const Duration(seconds: 15),
    this.minChecksForStall = 3,
  });

  final Duration checkInterval;
  final Duration stallThreshold;
  final int minChecksForStall;

  Timer? _timer;
  StallWatchable? _controller;
  Duration _lastPosition = Duration.zero;

  /// Fin de la dernière plage de tampon vue.
  ///
  /// C'est le signal de progression retenu quand la position ne bouge pas : sur
  /// les sources de ce panel la vidéo rend à l'écran alors que `position`
  /// reste figée à 1 ms. L'extrémité du tampon est monotone et suit
  /// réellement l'arrivée des données.
  Duration _lastBufferedEnd = Duration.zero;

  /// Fin de la dernière plage de tampon annoncée, ou zéro si aucune.
  static Duration _bufferedEnd(VideoPlayerValue v) {
    if (v.buffered.isEmpty) return Duration.zero;
    var end = Duration.zero;
    for (final range in v.buffered) {
      if (range.end > end) end = range.end;
    }
    return end;
  }

  /// Temps cumulé écoulé depuis [start], incrémenté de [checkInterval] à
  /// chaque check.
  ///
  /// On ne se sert volontairement PAS de `DateTime.now()` : le détecteur doit
  /// être pilotable en test (horloge murale non contrôlable) et ne suffered
  /// d'aucune dérive de l'horloge système. Comme `_check` est piloté par un
  /// `Timer.periodic(checkInterval)`, le temps « vu » par le détecteur est
  /// exactement le nombre de checks × [checkInterval].
  Duration _elapsed = Duration.zero;

  /// Valeur de [_elapsed] au dernier progrès de position constaté.
  Duration _lastProgressElapsed = Duration.zero;

  /// Valeur de [_elapsed] au déclenchement du stall en cours.
  Duration _stallStartedElapsed = Duration.zero;

  int _stallChecks = 0;
  int _bufferingChecks = 0;
  bool _isStalling = false;
  bool _isRunning = false;
  StallKind _stallKind = StallKind.none;

  /// Nombre de checks consécutifs passé en état `isBuffering`.
  ///
  /// Exposé pour le diagnostic : un taux élevé de checks en buffering indique
  /// un flux réellement sous-alimenté, alors qu'un taux nul avec une position
  /// figée pointe vers un autre défaut (position live qui n'avance pas).
  int get bufferingChecks => _bufferingChecks;

  bool get isStalling => _isStalling;
  bool get isRunning => _isRunning;

  /// Cause du gel courant, pour que l'interface puisse nommer le problème.
  StallKind get stallKind => _stallKind;

  /// Tampon encore disponible devant la position de lecture, en secondes.
  ///
  /// Sert à distinguer un gel de décodage (tampon profond, le flux EST là)
  /// d'une coupure de liaison (tampon vide).
  static double _bufferedAheadSeconds(VideoPlayerValue v) {
    if (v.buffered.isEmpty) return 0;
    final pos = v.position;
    for (final range in v.buffered) {
      if (range.end >= pos) {
        final ahead = (range.end - pos).inMilliseconds / 1000.0;
        return ahead < 0 ? 0 : ahead;
      }
    }
    return 0;
  }

  /// Tampon jugé « profond » : le panel a bien livré la suite du flux.
  static const double _deepBufferSeconds = 5.0;

  /// Position considered « jamais démarrée » (le lecteur n'a pas rendu sa
  /// première image).
  static const Duration _notStartedPosition = Duration(seconds: 2);

  /// Le contrôleur actuellement observé (pour des redémarrages idempotents).
  StallWatchable? get controller => _controller;

  bool isAttachedTo(StallWatchable other) =>
      _controller != null && identical(_controller!.source, other.source);

  /// Démarre la surveillance pour le controller donné.
  void start(StallWatchable controller) {
    // Sécurité : annuler un éventuel timer existant avant d'en démarrer un
    // nouveau (un zapping rapide pouvait en laisser un orphelin).
    if (_isRunning) {
      stop();
    }
    _controller = controller;
    _lastPosition = controller.value.position;
    _lastBufferedEnd = _bufferedEnd(controller.value);
    _elapsed = Duration.zero;
    _lastProgressElapsed = Duration.zero;
    _stallStartedElapsed = Duration.zero;
      _stallChecks = 0;
      _bufferingChecks = 0;
      _isStalling = false;
      _stallKind = StallKind.none;
      _isRunning = true;

    _timer = Timer.periodic(checkInterval, _check);
    final v = controller.value;
    LoggerService.instance.info(
      'StallDetector: start live=${_isLive(v)} '
      'buf=${_bufferedDuration(v)} '
      'seuil=${stallThreshold.inSeconds}s/$minChecksForStall checks',
      tag: 'stall',
    );
  }

  /// Arrête la surveillance.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _controller = null;
    _isRunning = false;
    // Journalisé AVANT la remise à zéro : sans cela, le log affichait
    // toujours `stalling=false`.
      LoggerService.instance
          .debug('StallDetector: stop (stalling=$_isStalling)', tag: 'stall');
      _isStalling = false;
      _stallKind = StallKind.none;
    }

  void _check(Timer timer) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final v = controller.value;

    // Une pause volontaire n'est pas un blocage : on ne compte rien. En
    // revanche un flux en STATE_BUFFERING peut être gelé définitivement (ou
    // pendant que `isPlaying` vaut false) — image noire, son muet : c'est
    // précisément le mode de défaillance silencieux le plus grave, on
    // continue donc de le surveiller.
    if (!v.isPlaying && !v.isBuffering) return;

    _elapsed += checkInterval;
    final currentPosition = v.position;
    final stalledFor = _elapsed - _lastProgressElapsed;

    // Progression = le flux avance. On regarde le tampon ET la position.
    //
    // La position SEULE ne suffit pas, et c'est mesuré : sur les sources de ce
    // panel la vidéo rend à l'écran alors que `position` reste figée à 1 ms
    // (relevé : pos=0:00:00.001 avec 20,8 s de tampon, image Moving). Juger sur
    // la position seule donnait un « gel » sur un flux parfaitement sain.
    // L'extrémité du tampon, elle, est monotone et suit réellement l'arrivée
    // des données.
    final bufferedEnd = _bufferedEnd(v);
    final progressed =
        currentPosition != _lastPosition || bufferedEnd != _lastBufferedEnd;

    // Un lecteur en train de remplir sa mémoire tampon n'est PAS un flux
    // bloqué : c'est le comportement attendu sur un flux live ou une
    // connexion instable. On ne lève un stall que si le buffering est
    // CONTINU sans qu'aucun progrès de position n'ait eu lieu depuis
    // [_lastProgressElapsed] (vrai gel : la position ne bouge pas pendant un
    // buffer, [_lastProgressElapsed] n'est donc jamais rafraîchi).
    if (v.isBuffering) {
      _bufferingChecks++;
      _stallChecks = 0;
      if (!_isStalling &&
          _bufferingChecks >= minChecksForStall &&
          stalledFor >= stallThreshold) {
        _isStalling = true;
        _stallKind = StallKind.buffering;
        _stallStartedElapsed = _elapsed;
        notifyListeners();
        // Journalisé SANS kDebugMode : en release, `debugPrint` est muet, ce
        // qui rendait tout diagnostic de la lecture impossible à partir d'un
        // logcat.
        LoggerService.instance.warning(
          'StallDetector: BUFFERING '
          'depuis ${stalledFor.inSeconds}s '
          'pos=$currentPosition bufChecks=$_bufferingChecks '
          'buf=${_bufferedAheadSeconds(v)}s isLive=${_isLive(v)}',
          tag: 'stall',
        );
      }
      return;
    }

    if (progressed) {
      // La position a avancé : c'est la preuve que le flux progresse.
      if (_isStalling) {
        LoggerService.instance.info(
          'StallDetector: stall récupéré, pos=$currentPosition '
          'après ${(_elapsed - _stallStartedElapsed).inSeconds}s',
            tag: 'stall',
          );
        _isStalling = false;
        _stallKind = StallKind.none;
        notifyListeners();
      }
      if (_bufferingChecks > 0) {
        LoggerService.instance.debug(
          'StallDetector: $currentPosition après $_bufferingChecks checks '
          'en buffering, buf=${_bufferedDuration(v)}',
          tag: 'stall',
        );
      }
      _stallChecks = 0;
      _bufferingChecks = 0;
      _lastPosition = currentPosition;
      _lastBufferedEnd = bufferedEnd;
      _lastProgressElapsed = _elapsed;
      return;
    }

    // Position immobile chez un lecteur qui n'est pas en buffer.
    _stallChecks++;
    if (_stallChecks >= minChecksForStall && stalledFor >= stallThreshold) {
      if (!_isStalling) {
        // Le tampon tranche entre les deux causes : profond, le panel a bien
        // livré la suite et c'est la LECTURE qui bloque (piste trop lourde,
        // première image jamais rendue) ; vide, c'est bien la liaison.
        final ahead = _bufferedAheadSeconds(v);
        final notStarted = currentPosition <= _notStartedPosition;
        _stallKind = (notStarted && ahead >= _deepBufferSeconds)
            ? StallKind.notStarted
            : StallKind.frozen;
        _isStalling = true;
        _stallStartedElapsed = _elapsed;
        notifyListeners();
        // Journalisé SANS kDebugMode : en release, `debugPrint` est muet, ce
        // qui rendait tout diagnostic de la lecture impossible à partir d'un
        // logcat. Les compteurs environnants sont indispensables pour
        // distinguer un vrai blocage d'un faux positif.
        LoggerService.instance.warning(
          'StallDetector: ${_stallKind.name.toUpperCase()} '
          'après ${stalledFor.inSeconds}s '
          'pos=$currentPosition '
          'checks=$_stallChecks bufChecks=$_bufferingChecks '
          'buf=${ahead}s '
          'isLive=${_isLive(v)} '
          'w=${v.size.width}x${v.size.height}',
          tag: 'stall',
        );
      }
    }
  }

  /// Durée mise en tampon déclarée par le lecteur, si elle est connue.
  String _bufferedDuration(VideoPlayerValue v) {
    final d = v.buffered;
    if (d.isEmpty) return 'vide';
    final last = d.last;
    return '${last.end.inMilliseconds}ms';
  }

  bool _isLive(VideoPlayerValue v) =>
      v.duration <= Duration.zero || v.duration > const Duration(hours: 6);

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
