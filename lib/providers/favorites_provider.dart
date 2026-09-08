import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// État réactif des favoris : clé canonique `"<type>:<id>"` -> entrée.
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
    _load();
  }

  Future<void> _load() async {
    final service = _ref.read(favoritesServiceProvider);
    final entries = await service.loadAll();
    state = {for (final e in entries) e.key: e};
  }

  bool isFavorite(ContentType type, String id) {
    return state.containsKey('${type.name}:$id');
  }

  FavoriteEntry? byKey(ContentType type, String id) {
    return state['${type.name}:$id'];
  }

  /// Favoris d'un type, les plus récemment ajoutés en premier.
  List<FavoriteEntry> forType(ContentType type) {
    return state.values.where((e) => e.type == type).toList().reversed.toList();
  }

  int countForType(ContentType type) {
    return state.values.where((e) => e.type == type).length;
  }

  Future<void> toggle(FavoriteEntry entry) async {
    final service = _ref.read(favoritesServiceProvider);
    if (state.containsKey(entry.key)) {
      await service.remove(entry.key);
      final next = Map<String, FavoriteEntry>.from(state)..remove(entry.key);
      state = next;
    } else {
      await service.save(entry);
      state = {...state, entry.key: entry};
    }
  }

  Future<void> removeEntry(ContentType type, String id) async {
    final key = '${type.name}:$id';
    if (!state.containsKey(key)) return;
    final next = Map<String, FavoriteEntry>.from(state)..remove(key);
    state = next; // Mise à jour immédiate (requis pour un Dismissible).
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
