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

  /// Abonnement de test supplémentaire (facultatif) — ex. draap.online.
  static const String _test2BaseUrl = String.fromEnvironment('BETA2_BASE_URL');
  static const String _test2Username = String.fromEnvironment('BETA2_USERNAME');
  static const String _test2Password = String.fromEnvironment('BETA2_PASSWORD');
  static const String _test2Name = String.fromEnvironment('BETA2_NAME', defaultValue: 'Abo test DRAAP');

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

    // Abonnement de test supplémentaire (inactif) — ex. draap.online.
    // Ajouté en plus du lot bêta, commutable manuellement dans l'app.
    var added = false;
    if (_test2BaseUrl.isNotEmpty && _test2Username.isNotEmpty) {
      final sub = Subscription.fromSubscriptionManagerFormat(
        DateTime.now().millisecondsSinceEpoch.toString() + '-t2',
        _test2Name,
        {
          'type': 'xtream',
          'baseUrl': _test2BaseUrl,
          'username': _test2Username,
          'password': _test2Password,
        },
      ); // isActive false par défaut => second abo test.
      await storage.saveSubscription(sub);
      added = true;
    }

    return added;
  }
}