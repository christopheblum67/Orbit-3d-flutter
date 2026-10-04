import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_key_store.dart';

/// Clé API OpenSubtitles saisie par l'utilisateur.
///
/// L'API refusant toute requête sans clé, une valeur vide rend la recherche
/// en ligne indisponible — elle n'est pas un mode dégradé. Voir
/// [OpenSubtitlesKeyStore] pour le stockage.
final openSubtitlesApiKeyProvider =
    NotifierProvider<OpenSubtitlesApiKeyNotifier, String>(
  OpenSubtitlesApiKeyNotifier.new,
);

class OpenSubtitlesApiKeyNotifier extends Notifier<String> {
  @override
  String build() => '';

  Future<void> load() async {
    await OpenSubtitlesKeyStore.instance.load();
    state = OpenSubtitlesKeyStore.instance.apiKey;
  }

  Future<void> setApiKey(String value) async {
    await OpenSubtitlesKeyStore.instance.setApiKey(value);
    state = OpenSubtitlesKeyStore.instance.apiKey;
  }
}
