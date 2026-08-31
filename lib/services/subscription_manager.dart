import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscription.dart';
import 'storage_service.dart';

/// Délégué vers [StorageService] pour la gestion multi-abonnements Hive.
/// Garde l'API inchangée pour ne pas casser [BetaConfig] et l'existant.
class SubscriptionManager {
  static const String _subscriptionsBox = 'subscriptions';

  Future<void> _ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_subscriptionsBox)) {
      await Hive.openBox<Subscription>(_subscriptionsBox);
    }
  }

  Future<void> saveXtream({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    await _ensureBoxOpen();
    final storage = StorageService();
    await storage.init();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final sub = Subscription(
      id: id,
      name: 'Xtream Codes',
      type: SubscriptionType.xtream,
      baseUrl: baseUrl,
      username: username,
      password: password,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await storage.saveSubscription(sub);
    await storage.setActiveSubscription(id);
  }

  Future<void> saveM3u(String url) async {
    await _ensureBoxOpen();
    final storage = StorageService();
    await storage.init();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final sub = Subscription(
      id: id,
      name: 'Playlist M3U',
      type: SubscriptionType.m3u,
      m3uUrl: url,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await storage.saveSubscription(sub);
    await storage.setActiveSubscription(id);
  }

  Future<Map<String, String?>> getActiveSubscription() async {
    await _ensureBoxOpen();
    final storage = StorageService();
    await storage.init();

    final active = await storage.getActiveSubscription();
    if (active == null) return {'type': null};
    return active.toSubscriptionManagerFormat();
  }

  Future<void> clear() async {
    await _ensureBoxOpen();
    final storage = StorageService();
    await storage.init();
    await storage.clearSubscriptions();
  }
}