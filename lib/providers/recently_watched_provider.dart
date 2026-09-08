import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';

/// État réactif « récemment regardé » : clé canonique `"<type>:<id>"` -> entrée.
///
/// Chaque nouvelle lecture remplace l'entrée du même contenu et la fait
/// remonter en tête. Les widgets écoutent [recentlyWatchedProvider] pour
/// afficher « Récemment regardé » en tête des listes Live / Films / Séries.
final recentlyWatchedProvider =
    StateNotifierProvider<RecentlyWatchedNotifier, Map<String, RecentEntry>>(
  (ref) => RecentlyWatchedNotifier(ref),
);

class RecentlyWatchedNotifier extends StateNotifier<Map<String, RecentEntry>> {
  final Ref _ref;
  DateTime? _lastWatchedAt;

  RecentlyWatchedNotifier(this._ref) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final service = _ref.read(recentlyWatchedServiceProvider);
    final entries = await service.loadAll();
    state = {for (final e in entries) e.key: e};
    if (entries.isNotEmpty) {
      _lastWatchedAt = entries
          .map((e) => e.watchedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
  }

  /// Enregistre une lecture, remplace le doublon et borne à 50 entrées.
  Future<void> record(
    ContentType type,
    String id,
    String title, {
    String posterUrl = '',
    String subtitle = '',
    String streamUrl = '',
  }) async {
    if (id.isEmpty) return;
    // Estampille strictement croissante : garantit un ordre déterministe
    // même pour plusieurs lectures dans la même milliseconde.
    var watchedAt = DateTime.now();
    if (_lastWatchedAt != null && !watchedAt.isAfter(_lastWatchedAt!)) {
      watchedAt = _lastWatchedAt!.add(const Duration(microseconds: 1));
    }
    _lastWatchedAt = watchedAt;
    final entry = RecentEntry(
      type: type,
      id: id,
      title: title,
      posterUrl: posterUrl,
      subtitle: subtitle,
      streamUrl: streamUrl,
      watchedAt: watchedAt,
    );
    final next = Map<String, RecentEntry>.from(state)..[entry.key] = entry;

    // Bornage à 50 éléments, les plus récents d'abord.
    final sorted = next.values.toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    var keysToDrop = <String>{};
    if (sorted.length > RecentlyWatchedService.maxEntries) {
      final kept = sorted.sublist(0, RecentlyWatchedService.maxEntries);
      keysToDrop = sorted
          .skip(RecentlyWatchedService.maxEntries)
          .map((e) => e.key)
          .toSet();
      next.removeWhere((k, _) => keysToDrop.contains(k));
    }

    state = next;
    final service = _ref.read(recentlyWatchedServiceProvider);
    await service.save(entry);
    for (final key in keysToDrop) {
      await service.remove(key);
    }
  }

  /// Récemment regardés d'un type, du plus récent au plus ancien.
  List<RecentEntry> forType(ContentType type) {
    return state.values.where((e) => e.type == type).toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
  }

  Future<void> clearAll() async {
    if (state.isEmpty) return;
    final service = _ref.read(recentlyWatchedServiceProvider);
    await service.clearAll();
    state = const {};
  }
}
