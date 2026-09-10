import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';

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
    if (!mounted) return;
    state = subs;
  }

  Future<void> addSubscription(Subscription subscription) async {
    await _ensureLoaded();
    await _storage.saveSubscription(subscription);
    if (!mounted) return;
    state = [...state, subscription];
    if (subscription.type == SubscriptionType.xtream) {
      refreshValidity(subscription.id);
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await _ensureLoaded();
    await _storage.saveSubscription(subscription);
    if (!mounted) return;
    state =
        state.map((s) => s.id == subscription.id ? subscription : s).toList();
    if (subscription.type == SubscriptionType.xtream) {
      refreshValidity(subscription.id);
    }
  }

  Future<void> deleteSubscription(String id) async {
    await _ensureLoaded();
    await _storage.deleteSubscription(id);
    if (!mounted) return;
    state = state.where((s) => s.id != id).toList();
  }

  Future<void> setActive(String id) async {
    await _ensureLoaded();
    final previouslyActive = state.where((s) => s.isActive).firstOrNull?.id;
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
    if (!mounted) return;
    state = subscriptions;

    // N'invalide les données que si l'abonnement actif change réellement :
    // chaque changement = refresh complet (même Xtream→Xtream ou M3U→M3U),
    // ce qui outrepasse les TTL des caches (EPG 30 min, replays 5 min).
    final actualChange = id != previouslyActive;
    if (!actualChange) return;

    _ref.invalidate(activeSubscriptionProvider);
    // Invalide TOUS les fournisseurs de données pour forcer un rechargement
    // complet au changement d'abonnement (changement de serveur/catalogue).
    _ref.invalidate(liveChannelsProvider);
    _ref.invalidate(moviesProvider);
    _ref.invalidate(seriesProvider);
    _ref.invalidate(replaysProvider);
    _ref.invalidate(radioChannelsProvider);
    _ref.invalidate(epgProgramsProvider);
    _ref.invalidate(epgDataCacheProvider);
    _ref.invalidate(recentlyWatchedProvider);
    // Cache REPLAYS : c'est un singleton GLOBAL (pas un provider) → il faut
    // l'invalider explicitement, sinon le TTL 5 min sert les replays de
    // l'ancien abonnement au nouveau.
    replaysCache.invalidate();
    // Outrepasse la règle des 30 min : on marque les données comme non
    // fraîches pour que `_refreshAll` (bouton « Mettre à jour ») soit
    // re-autorisé immédiatement après un changement d'abonnement.
    _ref.read(lastRefreshTimestampProvider.notifier).state = null;
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
    if (!mounted) return;
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
    if (!mounted) return;
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final sub = state[index];
    if (sub.type != SubscriptionType.xtream) return;

    final apiService = api ?? ApiService();
    final expiry = await apiService.fetchExpiration();
    if (!mounted || expiry == null) return;

    final updated = sub.copyWith(validUntil: expiry);
    await _storage.saveSubscription(updated);
    if (!mounted) return;
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
    String baseUrl,
    String username,
    String password,
  ) {
    final uri = Uri.parse(baseUrl.trim().replaceAll(RegExp(r'/+$'), ''));
    final segments = [
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      'player_api.php',
    ];
    return uri.replace(
      pathSegments: segments,
      queryParameters: {
        'username': username,
        'password': password,
        'action': 'get_live_streams',
      },
    ).toString();
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
