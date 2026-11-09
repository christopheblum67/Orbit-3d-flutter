import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';

/// Sonde un lecteur à intervalles bornés sans publier de réponse périmée.
class EmbeddedSubtitleScanner<T extends Object> {
  EmbeddedSubtitleScanner({
    required this.fetchTracks,
    this.period = const Duration(seconds: 1),
    this.duration = const Duration(seconds: 60),
  });

  final Future<List<EmbeddedSubtitleTrack>> Function(T player) fetchTracks;
  final Duration period;
  final Duration duration;
  _Scan<T>? _scan;

  void start({
    required T player,
    required bool Function() isCurrent,
    required Future<void> Function(
      List<EmbeddedSubtitleTrack>,
      bool Function() isCurrent,
    ) onTracks,
  }) {
    stop();
    final scan = _Scan<T>(player, isCurrent, onTracks);
    _scan = scan;
    var elapsed = Duration.zero;
    scan.timer = Timer.periodic(period, (timer) {
      if (!_isCurrent(scan)) {
        stopPlayer(player);
        return;
      }
      elapsed += period;
      unawaited(_probe(scan));
      if (elapsed >= duration) {
        timer.cancel();
        scan.timer = null;
      }
    });
    unawaited(_probe(scan));
  }

  bool _isCurrent(_Scan<T> scan) => identical(_scan, scan) && scan.isCurrent();

  Future<void> _probe(_Scan<T> scan) async {
    if (scan.running || !_isCurrent(scan)) return;
    scan.running = true;
    try {
      final tracks = await fetchTracks(scan.player);
      if (!_isCurrent(scan)) return;
      if (!shouldPropagateEmbeddedTracks(
        tracks: tracks,
        previousSignature: scan.signature,
      )) {
        return;
      }
      final signature = embeddedTracksSignature(tracks);
      if (signature == scan.signature) return;
      scan.signature = signature;
      await scan.onTracks(tracks, () => _isCurrent(scan));
    } catch (error, stackTrace) {
      if (_isCurrent(scan) && !scan.errorReported) {
        scan.errorReported = true;
        LoggerService.instance.error(
          'Échec du balayage des sous-titres intégrés',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } finally {
      scan.running = false;
    }
  }

  void stopPlayer(T player) {
    if (identical(_scan?.player, player)) stop();
  }

  void stop() {
    _scan?.timer?.cancel();
    _scan = null;
  }
}

class _Scan<T extends Object> {
  _Scan(this.player, this.isCurrent, this.onTracks);

  final T player;
  final bool Function() isCurrent;
  final Future<void> Function(
    List<EmbeddedSubtitleTrack>,
    bool Function() isCurrent,
  ) onTracks;
  Timer? timer;
  bool running = false;
  bool errorReported = false;
  String signature = kEmbeddedSigUnset;
}
