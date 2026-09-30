import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Fenêtre de conservation du cache : 30 minutes.
const Duration kShortEpgTtl = Duration(minutes: 30);

/// Cache mémoire des guides courts (`get_short_epg`) par `stream_id`.
///
/// Évite de re-interroger le panel à chaque ouverture de catch-up ou de grille
/// EPG d'une chaîne. L'entrée est considered périmée après [kShortEpgTtl].
class ShortEpgCache {
  final Map<String, _ShortEpgEntry> _entries = <String, _ShortEpgEntry>{};

  /// Nombre d'entrées en cache (diagnostic/tests).
  int get length => _entries.length;

  /// Retourne la liste en cache si elle est encore valide.
  List<EPGProgram>? get(String streamId) {
    final entry = _entries[streamId];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(streamId);
      return null;
    }
    return entry.programs;
  }

  /// Stocke une liste de programmes pour une chaîne.
  void put(String streamId, List<EPGProgram> programs) {
    _entries[streamId] = _ShortEpgEntry(
      programs: List<EPGProgram>.unmodifiable(programs),
      expiresAt: DateTime.now().add(kShortEpgTtl),
    );
  }

  void invalidate(String streamId) => _entries.remove(streamId);

  void clear() => _entries.clear();
}

class _ShortEpgEntry {
  _ShortEpgEntry({required this.programs, required this.expiresAt});

  final List<EPGProgram> programs;
  final DateTime expiresAt;
}

/// Précharge en tâche de fond le guide court des chaînes de l'abonnement.
///
/// Lançé au démarrage (idle), il évite la latence du premier `get_short_epg`
/// sans jamais bloquer le chargement de l'application.
class EpgPreloadService {
  EpgPreloadService({required this.cache, this.ttl = kShortEpgTtl});

  final ShortEpgCache cache;

  /// Durée maximale de la précharge (garde-fou temps réel).
  final Duration ttl;

  bool _running = false;
  bool get isRunning => _running;

  /// Précharge les [limit] premières chaînes, sans jamais dépasser [ttl].
  Future<int> preload(ApiService api, List<Channel> channels, {int limit = 20}) async {
    if (_running) return 0;
    _running = true;
    final deadline = DateTime.now().add(ttl);
    var loaded = 0;
    try {
      for (final channel in channels.take(limit)) {
        if (DateTime.now().isAfter(deadline)) break;
        if (cache.get(channel.id) != null) continue;
        final result = await safeAsync<List<EPGProgram>>(
          () => api.fetchChannelEpgPrograms(channel),
          context: 'EpgPreloadService.preload',
        );
        final programs = result.valueOrNull;
        if (programs == null || programs.isEmpty) continue;
        cache.put(channel.id, programs);
        loaded++;
      }
    } finally {
      _running = false;
    }
    if (loaded > 0) {
      LoggerService.instance
          .info('EpgPreloadService: $loaded guides courts préchargés');
    }
    return loaded;
  }
}
