import '../models/subscription.dart';
import 'storage_service.dart';

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
    final storage = StorageService();
    await storage.init();

    final subs = await storage.getSubscriptions();
    // Un abonnement existe déjà => on ne touche à rien.
    if (subs.isNotEmpty) return false;

    if (lot == 'xtream' && _defaultBaseUrl.isNotEmpty && _defaultUsername.isNotEmpty) {
      final sub = Subscription.fromSubscriptionManagerFormat(
        DateTime.now().millisecondsSinceEpoch.toString(),
        'Abonnement Beta',
        {
          'type': 'xtream',
          'baseUrl': _defaultBaseUrl,
          'username': _defaultUsername,
          'password': _defaultPassword,
        },
      ).copyWith(isActive: true);
      await storage.saveSubscription(sub);
      await storage.setActiveSubscription(sub.id);
      return true;
    }

    if (lot == 'm3u' && _defaultM3uUrl.isNotEmpty) {
      final sub = Subscription.fromSubscriptionManagerFormat(
        DateTime.now().millisecondsSinceEpoch.toString(),
        'Playlist M3U Beta',
        {
          'type': 'm3u',
          'url': _defaultM3uUrl,
        },
      ).copyWith(isActive: true);
      await storage.saveSubscription(sub);
      await storage.setActiveSubscription(sub.id);
      return true;
    }

    return false;
  }
}