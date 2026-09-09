import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';

/// État réactif des favoris : clé canonique `"<profileId>:<type>:<id>"` -> entrée.
///
/// Toute écriture (toggle, suppression) met à jour l'état ET persiste en Hive
/// via [FavoritesService]. Les widgets écoutent [favoritesProvider] pour
/// refléter le cœur immédiatement (écran Favoris, cartes Live/VOD/Séries/Replay).
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Map<String, FavoriteEntry>>(
  (ref) => FavoritesNotifier(ref),
);

class FavoritesNotifier extends StateNotifier<Map<String, FavoriteEntry>> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const {}) {
    _ref.listen(currentProfileProvider, (_, __) => _load());
    _load();
  }

  void _load() {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) {
      state = const {};
      return;
    }
    _loadForProfile(profile.id);
  }

  Future<void> _loadForProfile(String profileId) async {
    final service = _ref.read(favoritesServiceProvider);
    final entries = await service.loadForProfile(profileId);
    state = {for (final e in entries) e.key: e};
  }

  bool isFavorite(ContentType type, String id) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return false;
    return state.containsKey('${profile.id}:${type.name}:$id');
  }

  FavoriteEntry? byKey(ContentType type, String id) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return null;
    return state['${profile.id}:${type.name}:$id'];
  }

  /// Favoris d'un type, les plus récemment ajoutés en premier.
  List<FavoriteEntry> forType(ContentType type) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return const [];
    return state.values
        .where((e) => e.type == type && e.profileId == profile.id)
        .toList()
        .reversed
        .toList();
  }

  int countForType(ContentType type) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return 0;
    return state.values.where((e) => e.type == type && e.profileId == profile.id).length;
  }

  Future<void> toggle(FavoriteEntry entry) async {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return;
    final entryWithProfile = FavoriteEntry(
      type: entry.type,
      id: entry.id,
      title: entry.title,
      profileId: profile.id,
      posterUrl: entry.posterUrl,
      subtitle: entry.subtitle,
      streamUrl: entry.streamUrl,
    );
    final service = _ref.read(favoritesServiceProvider);
    if (state.containsKey(entryWithProfile.key)) {
      await service.remove(entryWithProfile.key);
      final next = Map<String, FavoriteEntry>.from(state)..remove(entryWithProfile.key);
      state = next;
    } else {
      await service.save(entryWithProfile);
      state = {...state, entryWithProfile.key: entryWithProfile};
    }
  }

  Future<void> removeEntry(ContentType type, String id) async {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return;
    final key = '${profile.id}:${type.name}:$id';
    if (!state.containsKey(key)) return;
    final next = Map<String, FavoriteEntry>.from(state)..remove(key);
    state = next;
    final service = _ref.read(favoritesServiceProvider);
    await service.remove(key);
  }

  Future<void> clearAll() async {
    if (state.isEmpty) return;
    final service = _ref.read(favoritesServiceProvider);
    for (final key in state.keys.toList()) {
      await service.remove(key);
    }
    state = const {};
  }
}
