import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

class PlaybackProgressWriter {
  PlaybackProgressWriter(this._service);

  final PlaybackProgressService _service;
  Future<void> _pending = Future<void>.value();

  Future<void> get pending => _pending;

  void save({
    required String id,
    required int positionMs,
    required int durationMs,
    required bool preserveOnError,
    void Function()? markWatched,
  }) {
    if (durationMs > 0 && positionMs / durationMs >= 0.8) {
      markWatched?.call();
    }

    final clear =
        !preserveOnError && durationMs > 0 && positionMs > durationMs * 0.95;
    _pending = _pending.then((_) async {
      await safeAsync(
        () => clear
            ? _service.clear(id)
            : _service.save(id, positionMs, durationMs),
        context: 'PlayerScreen.saveProgress',
      );
    });
  }
}
