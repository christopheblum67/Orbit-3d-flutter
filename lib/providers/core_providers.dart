import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 expose les ChangeNotifierProvider dans l'export legacy.
import 'package:flutter_riverpod/legacy.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/vpn_service.dart';
import 'package:orbit_3d_flutter/services/subscription_manager.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';
import 'package:orbit_3d_flutter/services/radio_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/rust_proxy_manager.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/services/connectivity_monitor.dart';
import 'package:orbit_3d_flutter/services/host_circuit_breaker.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:orbit_3d_flutter/services/analytics_service.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final service = AnalyticsService();
  ref.onDispose(service.init);
  return service;
});

// Certificate Pinning - applique la config des réglages avancés au service API
final certificatePinningInitializerProvider = Provider<void>((ref) {
  final settings = ref.watch(advancedSettingsProvider);
  if (settings.certificatePinningEnabled &&
      settings.certificatePinningFingerprints.isNotEmpty) {
    ApiService.setCertificateFingerprints(
      settings.certificatePinningFingerprints.toSet(),
    );
  } else {
    ApiService.setCertificateFingerprints(null);
  }
});

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
final vpnServiceProvider = Provider<VpnService>((ref) => VpnService());
final subscriptionManagerProvider =
    Provider<SubscriptionManager>((ref) => SubscriptionManager());
final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());
final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());
final recentlyWatchedServiceProvider =
    Provider<RecentlyWatchedService>((ref) => RecentlyWatchedService());
final watchedEpisodesServiceProvider =
    Provider<WatchedEpisodesService>((ref) => WatchedEpisodesService());
final radioServiceProvider = Provider<RadioService>((ref) => RadioService());
final playbackProgressServiceProvider =
    ChangeNotifierProvider<PlaybackProgressService>(
  (ref) => PlaybackProgressService(),
);
final mediaLibraryManagerProvider =
    Provider<MediaLibraryManager>((ref) => MediaLibraryManager());

/// Pilote le process proxy Rust local (détection du binaire, démarrage,
/// watchdog, ping `/api/proxy-status`). Singleton partagé : l'app lit
/// `manager.isReady` avant de rebaser une URL via `stream_relay`.
final rustProxyManagerProvider = Provider<RustProxyManager>((ref) {
  final manager = RustProxyManager.instance;
  ref.onDispose(manager.dispose);
  return manager;
});

final currentProfileProvider =
    NotifierProvider<CurrentProfileNotifier, UserProfile?>(
  CurrentProfileNotifier.new,
);

class CurrentProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;

  void setUserProfile(UserProfile? profile) => state = profile;
}

final sourceTypeProvider = FutureProvider<String?>((ref) async {
  final sub =
      await ref.watch(subscriptionManagerProvider).getActiveSubscription();
  return sub['type'];
});

final profilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getProfiles();
});

/// Moniteur de connectivité temps réel (singleton via ChangeNotifier)
final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  final monitor = ConnectivityMonitor();
  ref.onDispose(monitor.dispose);
  return monitor;
});

/// Circuit breaker par hôte (cooldown anti-leech)
final hostCircuitBreakerProvider = Provider<HostCircuitBreaker>((ref) {
  return HostCircuitBreaker.instance;
});

/// Détecteur de stall (flux figé) pendant la lecture
final stallDetectorProvider = Provider<StallDetector>((ref) {
  final detector = StallDetector();
  ref.onDispose(detector.dispose);
  return detector;
});
