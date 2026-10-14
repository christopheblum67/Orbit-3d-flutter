import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_credentials_store.dart';

/// Identifiants du compte OpenSubtitles saisis dans les réglages.
///
/// Le compte est OPTIONNEL : sans lui, les recherches restent anonymes et
/// `/download` répond 503 (« compte requis »). Voir
/// [OpenSubtitlesCredentialsStore] pour le stockage.
final openSubtitlesCredentialsProvider =
    NotifierProvider<OpenSubtitlesCredentialsNotifier, OpenSubtitlesCredentials>(
  OpenSubtitlesCredentialsNotifier.new,
);

class OpenSubtitlesCredentialsNotifier extends Notifier<OpenSubtitlesCredentials> {
  /// Incrémenté à chaque écriture VOLONTAIRE des identifiants.
  ///
  /// Même garde-fou que la clé API : `load()` est lancé en `unawaited` au
  /// démarrage (voir `main.dart`), il se termine donc souvent APRÈS que
  /// l'utilisateur a enregistré son compte. Sans ce compteur, ce `load()`
  /// tardif publierait l'ancien état par-dessus la saisie nouvelle.
  int _writeGeneration = 0;

  @override
  OpenSubtitlesCredentials build() => const OpenSubtitlesCredentials();

  Future<void> load() async {
    final generationAtStart = _writeGeneration;
    await OpenSubtitlesCredentialsStore.instance.load();
    // Une saisie a eu lieu pendant le chargement : elle fait foi.
    if (generationAtStart != _writeGeneration) return;
    state = OpenSubtitlesCredentialsStore.instance.credentials;
  }

  Future<void> setCredentials(OpenSubtitlesCredentials credentials) async {
    _writeGeneration++;
    await OpenSubtitlesCredentialsStore.instance.setCredentials(credentials);
    state = OpenSubtitlesCredentialsStore.instance.credentials;
  }

  Future<void> clear() async {
    _writeGeneration++;
    await OpenSubtitlesCredentialsStore.instance.clear();
    state = OpenSubtitlesCredentialsStore.instance.credentials;
  }
}