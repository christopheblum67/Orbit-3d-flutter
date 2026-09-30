import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

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

  /// Nombre de checks consécutifs passé en état `isBuffering`.
  ///
  /// Exposé pour le diagnostic : un taux élevé de checks en buffering indique
  /// un flux réellement sous-alimenté, alors qu'un taux nul avec une position
  /// figée pointe vers un autre défaut (position live qui n'avance pas).
  int get bufferingChecks => _bufferingChecks;

  bool get isStalling => _isStalling;
  bool get isRunning => _isRunning;

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
    _elapsed = Duration.zero;
    _lastProgressElapsed = Duration.zero;
    _stallStartedElapsed = Duration.zero;
    _stallChecks = 0;
    _bufferingChecks = 0;
    _isStalling = false;
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
        _stallStartedElapsed = _elapsed;
        notifyListeners();
        // Journalisé SANS kDebugMode : en release, `debugPrint` est muet, ce
        // qui rendait tout diagnostic de la lecture impossible à partir d'un
        // logcat.
        LoggerService.instance.warning(
          'StallDetector: BLOCAGE EN BUFFERING '
          'depuis ${stalledFor.inSeconds}s '
          'pos=$currentPosition bufChecks=$_bufferingChecks '
          'buf=${_bufferedDuration(v)} isLive=${_isLive(v)}',
          tag: 'stall',
        );
      }
      return;
    }

    if (currentPosition != _lastPosition) {
      // La position a avancé : c'est la preuve que le flux progresse.
      if (_isStalling) {
        LoggerService.instance.info(
          'StallDetector: stall récupéré, pos=$currentPosition '
          'après ${(_elapsed - _stallStartedElapsed).inSeconds}s',
          tag: 'stall',
        );
        _isStalling = false;
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
      _lastProgressElapsed = _elapsed;
      return;
    }

    // Position immobile chez un lecteur qui n'est pas en buffer.
    _stallChecks++;
    if (_stallChecks >= minChecksForStall && stalledFor >= stallThreshold) {
      if (!_isStalling) {
        _isStalling = true;
        _stallStartedElapsed = _elapsed;
        notifyListeners();
        // Journalisé SANS kDebugMode : en release, `debugPrint` est muet, ce
        // qui rendait tout diagnostic de la lecture impossible à partir d'un
        // logcat. Les compteurs environnants sont indispensables pour
        // distinguer un vrai blocage d'un faux positif.
        LoggerService.instance.warning(
          'StallDetector: STALL après ${stalledFor.inSeconds}s '
          'pos=$currentPosition '
          'checks=$_stallChecks bufChecks=$_bufferingChecks '
          'buf=${_bufferedDuration(v)} '
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
