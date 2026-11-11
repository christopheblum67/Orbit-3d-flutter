import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Noms des stations radio favorites du profil courant.
final radioFavoritesProvider =
    NotifierProvider<RadioFavoritesNotifier, Set<String>>(
  RadioFavoritesNotifier.new,
);

class RadioFavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen(currentProfileProvider, (_, __) => _load());
    _load();
    return const {};
  }

  String? get _key {
    final id = ref.read(currentProfileProvider)?.id;
    return id == null ? null : 'radio_favorites_$id';
  }

  Future<void> _load() async {
    final key = _key;
    if (key == null) {
      state = const {};
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = (prefs.getStringList(key) ?? const <String>[]).toSet();
  }

  Future<void> toggle(String stationName) async {
    final key = _key;
    if (key == null) return;
    final next = {...state};
    if (!next.remove(stationName)) next.add(stationName);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, next.toList());
  }
}
