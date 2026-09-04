import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class SubscriptionsNotifier extends StateNotifier<List<Subscription>> {
  final StorageService _storage;
  final Ref _ref;
  Future<void>? _initialLoad;

  SubscriptionsNotifier(this._storage, this._ref) : super([]) {
    _initialLoad = _loadSubscriptions();
  }

  Future<void> _ensureLoaded() async {
    if (_initialLoad != null) {
      await _initialLoad;
      _initialLoad = null;
    }
  }

  Future<void> _loadSubscriptions() async {
    await _storage.migrateFromSharedPreferences();
    final subs = await _storage.getSubscriptions();
    state = subs;
  }

  Future<void> addSubscription(Subscription subscription) async {
    await _ensureLoaded();
    await _storage.saveSubscription(subscription);
    state = [...state, subscription];
    if (subscription.type == SubscriptionType.xtream) {
      refreshValidity(subscription.id);
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await _ensureLoaded();
    await _storage.saveSubscription(subscription);
    state =
        state.map((s) => s.id == subscription.id ? subscription : s).toList();
    if (subscription.type == SubscriptionType.xtream) {
      refreshValidity(subscription.id);
    }
  }

  Future<void> deleteSubscription(String id) async {
    await _ensureLoaded();
    await _storage.deleteSubscription(id);
    state = state.where((s) => s.id != id).toList();
  }

  Future<void> setActive(String id) async {
    await _ensureLoaded();
    final subscriptions = state.map((s) {
      if (s.id == id) {
        return s.copyWith(isActive: true);
      } else if (s.isActive) {
        return s.copyWith(isActive: false);
      }
      return s;
    }).toList();

    for (final sub in subscriptions) {
      await _storage.saveSubscription(sub);
    }
    state = subscriptions;
    _ref.invalidate(activeSubscriptionProvider);
    // Rafraîchit la validité du serveur activé (Xtream) à la volée.
    Subscription? activated;
    for (final s in subscriptions) {
      if (s.id == id) {
        activated = s;
        break;
      }
    }
    if (activated != null && activated.type == SubscriptionType.xtream) {
      refreshValidity(id);
    }
  }

  Future<void> updateTestResult(
    String id,
    TestResultStatus status, {
    int? latencyMs,
    String? error,
  }) async {
    await _ensureLoaded();
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final updated = state[index].copyWith(
      lastTestedAt: DateTime.now(),
      lastTestResult: status,
      lastTestLatencyMs: latencyMs,
      lastTestError: error,
    );

    await _storage.saveSubscription(updated);
    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
  }

  /// Récupère la date d'expiration du compte (Xtream) et la persiste sur
  /// l'abonnement afin que `validityLabel` affiche une vraie valeur.
  /// Sans effet pour les playlists M3U (aucune validité serveur).
  Future<void> refreshValidity(String id, {ApiService? api}) async {
    await _ensureLoaded();
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final sub = state[index];
    if (sub.type != SubscriptionType.xtream) return;

    final apiService = api ?? ApiService();
    final expiry = await apiService.fetchExpiration();
    if (expiry == null) return;

    final updated = sub.copyWith(validUntil: expiry);
    await _storage.saveSubscription(updated);
    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
    _ref.invalidate(activeSubscriptionProvider);
  }

  Future<void> testConnection(Subscription sub, {ApiService? api}) async {
    _ref.read(subscriptionsTestingProvider.notifier).state = {
      ..._ref.read(subscriptionsTestingProvider),
      sub.id,
    };
    final apiService = api ?? ApiService();
    final stopwatch = Stopwatch()..start();

    try {
      if (sub.type == SubscriptionType.xtream) {
        if (sub.baseUrl == null ||
            sub.username == null ||
            sub.password == null) {
          throw Exception('Configuration Xtream incomplète');
        }
        final url =
            buildXtreamTestUrl(sub.baseUrl!, sub.username!, sub.password!);
        await apiService.get(url);
      } else {
        if (sub.m3uUrl == null) {
          throw Exception('URL M3U manquante');
        }
        await apiService.get(sub.m3uUrl!);
      }
      stopwatch.stop();
      await updateTestResult(
        sub.id,
        TestResultStatus.success,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      // Après un test réussi, rafraîchit la date d'expiration (Xtream).
      if (sub.type == SubscriptionType.xtream) {
        await refreshValidity(sub.id, api: apiService);
      }
    } catch (e) {
      stopwatch.stop();
      await updateTestResult(
        sub.id,
        TestResultStatus.error,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
    } finally {
      final current = _ref.read(subscriptionsTestingProvider);
      _ref.read(subscriptionsTestingProvider.notifier).state = {...current}
        ..remove(sub.id);
    }
  }

  static String buildXtreamTestUrl(
      String baseUrl, String username, String password,) {
    final uri = Uri.parse(baseUrl.trim().replaceAll(RegExp(r'/+$'), ''));
    final segments = [
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      'player_api.php',
    ];
    return uri.replace(pathSegments: segments, queryParameters: {
      'username': username,
      'password': password,
      'action': 'get_live_streams',
    },).toString();
  }
}

final subscriptionsProvider =
    StateNotifierProvider<SubscriptionsNotifier, List<Subscription>>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return SubscriptionsNotifier(storage, ref);
  },
);

final activeSubscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getActiveSubscription();
});

final subscriptionsTestingProvider = StateProvider<Set<String>>((ref) => {});
