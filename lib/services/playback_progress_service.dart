import 'package:hive_flutter/hive_flutter.dart';

/// Progression de lecture enregistrée pour un média (film / épisode de série).
class PlaybackProgress {
  const PlaybackProgress({
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });

  final int positionMs;
  final int durationMs;
  final int updatedAt;

  bool get hasProgress =>
      positionMs > 0 && (durationMs <= 0 || positionMs < durationMs);

  double get fraction {
    if (durationMs <= 0) return 0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }
}

/// Sauvegarde persistée (Hive) de la position de lecture par identifiant de
/// média. Permet au bouton « Reprendre » de relancer au point de lecture.
class PlaybackProgressService {
  static const String _boxName = 'playback_progress';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> save(
    String id,
    int positionMs,
    int durationMs,
  ) async {
    final box = Hive.box<String>(_boxName);
    final value =
        '$positionMs|$durationMs|${DateTime.now().millisecondsSinceEpoch}';
    await box.put(id, value);
  }

  PlaybackProgress? get(String id) {
    final box = Hive.box<String>(_boxName);
    final raw = box.get(id);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    final position = int.tryParse(parts[0]) ?? 0;
    final duration = int.tryParse(parts[1]) ?? 0;
    final updated = int.tryParse(parts[2]) ?? 0;
    return PlaybackProgress(
      positionMs: position,
      durationMs: duration,
      updatedAt: updated,
    );
  }

  Future<void> clear(String id) async {
    final box = Hive.box<String>(_boxName);
    await box.delete(id);
  }
}
