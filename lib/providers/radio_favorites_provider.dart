import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/radio_favorites_store.dart';

/// Noms des stations radio favorites du profil courant.
final radioFavoritesProvider =
    NotifierProvider<RadioFavoritesNotifier, Set<String>>(
  RadioFavoritesNotifier.new,
);

class RadioFavoritesNotifier extends Notifier<Set<String>> {
  int _generation = 0;

  @override
  Set<String> build() {
    ref.listen(currentProfileProvider, (_, __) => _load());
    _load();
    return const {};
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final profileId = ref.read(currentProfileProvider)?.id;
    if (profileId == null) {
      state = const {};
      return;
    }
    state = const {};
    final favorites = await RadioFavoritesStore.read(profileId);
    if (!ref.mounted ||
        generation != _generation ||
        ref.read(currentProfileProvider)?.id != profileId) {
      return;
    }
    state = favorites;
  }

  Future<void> toggle(String stationName) async {
    final profileId = ref.read(currentProfileProvider)?.id;
    if (profileId == null) return;
    final generation = ++_generation;
    final next = await RadioFavoritesStore.toggle(profileId, stationName);
    if (!ref.mounted ||
        generation != _generation ||
        ref.read(currentProfileProvider)?.id != profileId) {
      return;
    }
    state = next;
  }
}
