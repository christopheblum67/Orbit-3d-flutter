import 'subscription_manager.dart';

/// Configuration de préchargement pour la phase de test bêta.
///
/// Permet d'embarquer une source (Xtream ou M3U) directement dans l'APK
/// via les paramètres de compilation `--dart-define` afin de distribuer
/// deux lots distincts aux testeurs (50% Xtream / 50% M3U).
class BetaConfig {
  /// Lot cible : 'xtream' ou 'm3u' (vide = aucun préchargement).
  static const String lot = String.fromEnvironment('BETA_LOT');

  static const String _defaultBaseUrl = String.fromEnvironment('BETA_BASE_URL');
  static const String _defaultUsername = String.fromEnvironment('BETA_USERNAME');
  static const String _defaultPassword = String.fromEnvironment('BETA_PASSWORD');
  static const String _defaultM3uUrl = String.fromEnvironment('BETA_M3U_URL');

  /// Applique la préconfiguration au premier lancement (une seule fois).
  /// Retourne true si une source a été préchargée.
  static Future<bool> applyIfNeeded() async {
    final manager = SubscriptionManager();
    final current = await manager.getActiveSubscription();
    // Une source est déjà active => on ne touche à rien.
    if (current['type'] != null) return false;

    if (lot == 'xtream' && _defaultBaseUrl.isNotEmpty && _defaultUsername.isNotEmpty) {
      await manager.saveXtream(
        baseUrl: _defaultBaseUrl,
        username: _defaultUsername,
        password: _defaultPassword,
      );
      return true;
    }

    if (lot == 'm3u' && _defaultM3uUrl.isNotEmpty) {
      await manager.saveM3u(_defaultM3uUrl);
      return true;
    }

    return false;
  }
}
