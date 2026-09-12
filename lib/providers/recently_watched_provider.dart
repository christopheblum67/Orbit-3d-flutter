import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';

/// État réactif « récemment regardé » : clé canonique `"<profileId>:<type>:<id>"` -> entrée.
///
/// Chaque nouvelle lecture remplace l'entrée du même contenu et la fait
/// remonter en tête. Les widgets écoutent [recentlyWatchedProvider] pour
/// afficher « Récemment regardé » en tête des listes Live / Films / Séries.
final recentlyWatchedProvider =
    NotifierProvider<RecentlyWatchedNotifier, Map<String, RecentEntry>>(
  RecentlyWatchedNotifier.new,
);

class RecentlyWatchedNotifier extends Notifier<Map<String, RecentEntry>> {
  DateTime? _lastWatchedAt;

  @override
  Map<String, RecentEntry> build() {
    ref.listen(currentProfileProvider, (_, __) => _load());
    _load();
    return const {};
  }

  void _load() {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      state = const {};
      return;
    }
    _loadForProfile(profile.id);
  }

  Future<void> _loadForProfile(String profileId) async {
    final service = ref.read(recentlyWatchedServiceProvider);
    final entries = await service.loadForProfile(profileId);
    if (!ref.mounted) return;
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
    final profile = ref.read(currentProfileProvider);
    if (profile == null || id.isEmpty) return;
    var watchedAt = DateTime.now();
    if (_lastWatchedAt != null && !watchedAt.isAfter(_lastWatchedAt!)) {
      watchedAt = _lastWatchedAt!.add(const Duration(microseconds: 1));
    }
    _lastWatchedAt = watchedAt;
    final entry = RecentEntry(
      type: type,
      id: id,
      title: title,
      profileId: profile.id,
      posterUrl: posterUrl,
      subtitle: subtitle,
      streamUrl: streamUrl,
      watchedAt: watchedAt,
    );
    final next = Map<String, RecentEntry>.from(state)..[entry.key] = entry;

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
    final service = ref.read(recentlyWatchedServiceProvider);
    await service.save(entry);
    for (final key in keysToDrop) {
      await service.remove(key);
    }
  }

  /// Récemment regardés d'un type, du plus récent au plus ancien.
  List<RecentEntry> forType(ContentType type) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return const [];
    return state.values
        .where((e) => e.type == type && e.profileId == profile.id)
        .toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
  }

  Future<void> clearAll() async {
    if (state.isEmpty) return;
    final service = ref.read(recentlyWatchedServiceProvider);
    await service.clearAll();
    state = const {};
  }
}
