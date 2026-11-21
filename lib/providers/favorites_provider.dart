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
    NotifierProvider<FavoritesNotifier, Map<String, FavoriteEntry>>(
  FavoritesNotifier.new,
);

class FavoriteScopeRequired extends StateError {
  FavoriteScopeRequired()
      : super('Un profil et un abonnement actifs sont nécessaires.');
}

class FavoritesNotifier extends Notifier<Map<String, FavoriteEntry>> {
  int _revision = 0;
  String? _scope;
  Future<void>? _pendingLoad;

  @override
  Map<String, FavoriteEntry> build() {
    ref.listen(currentProfileProvider, (_, __) => _load());
    ref.listen(activeSubscriptionProvider, (_, __) => _load());
    ref.listen(subscriptionsProvider, (_, __) => _load());
    _load(initial: true);
    return const {};
  }

  void _load({bool initial = false}) {
    final profile = ref.read(currentProfileProvider);
    final subscription = ref.read(activeSubscriptionProvider);
    final scope =
        profile == null || subscription == null || subscription.id.isEmpty
            ? null
            : '${profile.id}\u0000${subscription.id}';
    final revision = ++_revision;
    if (!initial && scope != _scope) state = const {};
    _scope = scope;
    if (profile == null || subscription == null || subscription.id.isEmpty) {
      _pendingLoad = null;
      return;
    }
    _pendingLoad = _loadForProfile(profile.id, subscription.id, revision);
  }

  Future<void> _loadForProfile(
    String profileId,
    String subscriptionId,
    int revision,
  ) async {
    final service = ref.read(favoritesServiceProvider);
    final entries = await service.loadForSubscription(
      profileId,
      subscriptionId,
      canMigrateLegacy: () {
        if (!ref.mounted || revision != _revision) return false;
        final subscriptions = ref.read(subscriptionsProvider);
        return subscriptions.length == 1 &&
            subscriptions.single.id == subscriptionId &&
            ref.read(activeSubscriptionProvider)?.id == subscriptionId;
      },
    );
    if (!ref.mounted || revision != _revision) return;
    state = {for (final e in entries) e.profileKey: e};
  }

  bool isFavorite(ContentType type, String id) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return false;
    return state.containsKey('${profile.id}:${type.name}:$id');
  }

  FavoriteEntry? byKey(ContentType type, String id) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return null;
    return state['${profile.id}:${type.name}:$id'];
  }

  /// Favoris d'un type, les plus récemment ajoutés en premier.
  List<FavoriteEntry> forType(ContentType type) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return const [];
    return state.values
        .where((e) => e.type == type && e.profileId == profile.id)
        .toList()
        .reversed
        .toList();
  }

  int countForType(ContentType type) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return 0;
    return state.values
        .where((e) => e.type == type && e.profileId == profile.id)
        .length;
  }

  Future<void> toggle(FavoriteEntry entry) => _update(entry, toggle: true);

  /// Ajoute un favori sans retirer une entrée déjà présente.
  Future<void> add(FavoriteEntry entry) => _update(entry, toggle: false);

  Future<void> _update(FavoriteEntry entry, {required bool toggle}) async {
    final profile = ref.read(currentProfileProvider);
    final subscription = ref.read(activeSubscriptionProvider);
    if (profile == null || subscription == null || subscription.id.isEmpty) {
      throw FavoriteScopeRequired();
    }
    await _pendingLoad;
    if (!ref.mounted ||
        ref.read(currentProfileProvider)?.id != profile.id ||
        ref.read(activeSubscriptionProvider)?.id != subscription.id) {
      return;
    }
    _revision++;
    final entryWithProfile = FavoriteEntry(
      type: entry.type,
      id: entry.id,
      title: entry.title,
      profileId: profile.id,
      subscriptionId: subscription.id,
      posterUrl: entry.posterUrl,
      subtitle: entry.subtitle,
      streamUrl: entry.streamUrl,
    );
    final service = ref.read(favoritesServiceProvider);
    if (state.containsKey(entryWithProfile.profileKey)) {
      if (!toggle) return;
      await service.remove(entryWithProfile.key);
      if (!ref.mounted || _scope != '${profile.id}\u0000${subscription.id}') {
        return;
      }
      final next = Map<String, FavoriteEntry>.from(state)
        ..remove(entryWithProfile.profileKey);
      state = next;
    } else {
      await service.save(entryWithProfile);
      if (!ref.mounted || _scope != '${profile.id}\u0000${subscription.id}') {
        return;
      }
      state = {...state, entryWithProfile.profileKey: entryWithProfile};
    }
  }

  Future<void> removeEntry(ContentType type, String id) async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    final key = '${profile.id}:${type.name}:$id';
    final entry = state[key];
    if (entry == null) return;
    _revision++;
    final next = Map<String, FavoriteEntry>.from(state)..remove(key);
    state = next;
    final service = ref.read(favoritesServiceProvider);
    await service.remove(entry.key);
  }

  Future<void> clearAll() async {
    if (state.isEmpty) return;
    final service = ref.read(favoritesServiceProvider);
    _revision++;
    final entries = state.values.toList();
    final scope = _scope;
    for (final entry in entries) {
      await service.remove(entry.key);
    }
    if (!ref.mounted || scope != _scope) return;
    final next = Map<String, FavoriteEntry>.from(state);
    for (final entry in entries) {
      next.remove(entry.profileKey);
    }
    state = next;
  }

  /// Applique les changements imposés par la synchronisation cloud (S2).
  Future<void> applySyncedProfile(
    List<FavoriteEntry> entries, {
    required Set<String> removes,
  }) async {
    final service = ref.read(favoritesServiceProvider);
    for (final e in entries) {
      await service.save(e);
    }
    for (final key in removes) {
      await service.remove(key);
    }
    if (ref.mounted) _load();
  }
}
