import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/services/tmdb_api_key_store.dart';

/// Override de la clé API TMDB (Réglages → Classements TMDB).
///
/// L'état est une chaîne vide tant que l'utilisateur n'a pas saisi sa propre
/// clé : dans ce cas l'app retombe sur la clé partagée (`.env` / build).
final tmdbApiKeyOverrideProvider =
    StateNotifierProvider<TmdbApiKeyOverrideNotifier, String>(
  (ref) => TmdbApiKeyOverrideNotifier(),
);

class TmdbApiKeyOverrideNotifier extends StateNotifier<String> {
  TmdbApiKeyOverrideNotifier() : super('');

  Future<void> load() async {
    await TmdbApiKeyStore.instance.load();
    state = TmdbApiKeyStore.instance.override;
  }

  Future<void> setOverride(String value) async {
    await TmdbApiKeyStore.instance.setOverride(value);
    state = TmdbApiKeyStore.instance.override;
  }
}