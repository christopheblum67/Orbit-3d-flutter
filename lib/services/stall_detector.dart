import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Détecteur de "stall" (flux figé) pendant la lecture.
/// Utilise un heartbeat périodique pour vérifier si la position avance.
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
  VideoPlayerController? _controller;
  Duration _lastPosition = Duration.zero;
  DateTime _lastCheckTime = DateTime.now();
  int _stallChecks = 0;
  bool _isStalling = false;
  bool _isRunning = false;

  bool get isStalling => _isStalling;
  bool get isRunning => _isRunning;

  /// Démarre la surveillance pour le controller donné.
  void start(VideoPlayerController controller) {
    if (_isRunning) return;
    _controller = controller;
    _lastPosition = controller.value.position;
    _lastCheckTime = DateTime.now();
    _stallChecks = 0;
    _isStalling = false;
    _isRunning = true;

    _timer = Timer.periodic(checkInterval, _check);
    if (kDebugMode) {
      debugPrint('StallDetector: started monitoring');
    }
  }

  /// Arrête la surveillance.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _controller = null;
    _isRunning = false;
    _isStalling = false;
    if (kDebugMode) {
      debugPrint('StallDetector: stopped monitoring');
    }
  }

  void _check(Timer timer) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!controller.value.isPlaying) return;

    final now = DateTime.now();
    final currentPosition = controller.value.position;

    if (currentPosition == _lastPosition) {
      _stallChecks++;
      final elapsed = now.difference(_lastCheckTime);
      if (kDebugMode) {
        debugPrint(
            'StallDetector: position unchanged ($_stallChecks checks, ${elapsed.inSeconds}s)');
      }
      if (_stallChecks >= minChecksForStall && elapsed >= stallThreshold) {
        if (!_isStalling) {
          _isStalling = true;
          notifyListeners();
          if (kDebugMode) {
            debugPrint(
                'StallDetector: STALL DETECTED after ${elapsed.inSeconds}s');
          }
        }
      }
    } else {
      // Position a avancé, reset
      if (_stallChecks > 0 && kDebugMode) {
        debugPrint('StallDetector: position advanced, resetting stall counter');
      }
      _stallChecks = 0;
      _lastPosition = currentPosition;
      _lastCheckTime = now;
      if (_isStalling) {
        _isStalling = false;
        notifyListeners();
        if (kDebugMode) {
          debugPrint('StallDetector: stall recovered');
        }
      }
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
