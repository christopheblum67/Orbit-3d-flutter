import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

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

  Map<String, int> toJson() => {
        'positionMs': positionMs,
        'durationMs': durationMs,
        'updatedAt': updatedAt,
      };

  factory PlaybackProgress.fromJson(Map<String, dynamic> json) {
    return PlaybackProgress(
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Sauvegarde persistée (Hive) de la position de lecture par identifiant de
/// média. Permet au bouton « Reprendre » de relancer au point de lecture.
class PlaybackProgressService extends ChangeNotifier {
  static const String _boxName = 'playback_progress';
  static const String _profileKeyPrefix = 'profile:';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static String idForProfile(String profileId, String mediaId) =>
      profileId.isEmpty ? mediaId : '$_profileKeyPrefix$profileId:$mediaId';

  Future<void> save(
    String id,
    int positionMs,
    int durationMs,
  ) async {
    await HiveSync.writeAsync(_boxName, (box) async {
      final value =
          '$positionMs|$durationMs|${DateTime.now().millisecondsSinceEpoch}';
      await box.put(id, value);
      final legacyId = _legacyIdFor(id);
      if (legacyId != null) await box.delete(legacyId);
    });
    notifyListeners();
  }

  PlaybackProgress? get(String id) {
    final box = Hive.box<dynamic>(_boxName);
    return _parse(box.get(id) ?? _legacyValueFor(box, id));
  }

  Future<void> clear(String id) async {
    await HiveSync.writeAsync(_boxName, (box) async {
      await box.delete(id);
      final legacyId = _legacyIdFor(id);
      if (legacyId != null) await box.delete(legacyId);
    });
    notifyListeners();
  }

  Future<Map<String, PlaybackProgress>> loadForProfile(String profileId) {
    final prefix = '$_profileKeyPrefix$profileId:';
    return HiveSync.read(_boxName, (box) {
      final progress = <String, PlaybackProgress>{};
      for (final key in box.keys) {
        if (key is! String || !key.startsWith(prefix)) continue;
        final mediaId = key.substring(prefix.length);
        final value = _parse(box.get(key));
        if (mediaId.isNotEmpty && value != null) progress[mediaId] = value;
      }
      return progress;
    });
  }

  Future<void> migrateLegacyForProfile(String profileId) async {
    final prefix = '$_profileKeyPrefix$profileId:';
    await HiveSync.writeAsync(_boxName, (box) async {
      for (final key in box.keys) {
        if (key is! String ||
            (!key.startsWith('movie-') && !key.startsWith('episode-'))) {
          continue;
        }
        final progress = _parse(box.get(key));
        if (progress == null) continue;
        await box.put(
          '$prefix$key',
          '${progress.positionMs}|${progress.durationMs}|${progress.updatedAt}',
        );
        await box.delete(key);
      }
    });
    notifyListeners();
  }

  Future<void> applySyncedProfile(
    String profileId, {
    required Map<String, PlaybackProgress> entries,
    required Set<String> removes,
  }) async {
    final prefix = '$_profileKeyPrefix$profileId:';
    await HiveSync.writeAsync(_boxName, (box) async {
      for (final mediaId in removes) {
        await box.delete('$prefix$mediaId');
      }
      for (final entry in entries.entries) {
        final value =
            '${entry.value.positionMs}|${entry.value.durationMs}|${entry.value.updatedAt}';
        await box.put('$prefix${entry.key}', value);
      }
    });
    notifyListeners();
  }

  static String? _legacyIdFor(String id) {
    if (!id.startsWith(_profileKeyPrefix)) return null;
    final separator = id.indexOf(':', _profileKeyPrefix.length);
    if (separator < 0 || separator == id.length - 1) return null;
    return id.substring(separator + 1);
  }

  static dynamic _legacyValueFor(Box<dynamic> box, String id) {
    final legacyId = _legacyIdFor(id);
    return legacyId == null ? null : box.get(legacyId);
  }

  static PlaybackProgress? _parse(dynamic raw) {
    if (raw is! String) return null;
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    return PlaybackProgress(
      positionMs: int.tryParse(parts[0]) ?? 0,
      durationMs: int.tryParse(parts[1]) ?? 0,
      updatedAt: int.tryParse(parts[2]) ?? 0,
    );
  }
}
