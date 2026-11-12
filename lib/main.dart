import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
// L'import ci-dessous (webview_flutter_android) charge et enregistre la
// plateforme Android WebView au démarrage (dartPluginClass), requis pour la
// vérification manuelle du fournisseur. Ne pas retirer l'import.
// ignore: unused_import
import 'package:webview_flutter/webview_flutter.dart';
// ignore: unused_import
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/duration_adapter.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_mirror_store.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/services/beta_config.dart';
import 'package:orbit_3d_flutter/drm/drm_provider.dart';
import 'package:orbit_3d_flutter/features/legal/legal_notice_screen.dart';

import 'package:orbit_3d_flutter/core/navigation/initial_route.dart';
import 'package:orbit_3d_flutter/core/utils/error_handler.dart';
import 'package:orbit_3d_flutter/core/utils/image_cache_config.dart';
import 'package:orbit_3d_flutter/orbit_app.dart';

import 'package:orbit_3d_flutter/core/navigation/app_router.dart';
export 'package:orbit_3d_flutter/core/navigation/app_router.dart';
export 'package:orbit_3d_flutter/orbit_app.dart';

void main() {
  runZonedGuarded(
    _bootstrap,
    (error, stackTrace) {
      ErrorHandler.instance
          .handleError(error, stackTrace: stackTrace, context: 'Zone');
    },
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureOrbitImageCache(defaultTargetPlatform);

  // Capture globales installées le plus tôt possible (erreurs cadre + isolate).
  ErrorHandler.instance.setupGlobalErrorHandling();
  // Crashlytics init non bloquant (release/profil uniquement).
  unawaited(ErrorHandler.instance.initCrashlytics());
  // L'import de webview_flutter_android enregistre (dartPluginClass) la
  // plateforme Android WebView automatiquement, nécessaire au déblocage
  // Cloudflare. Ne pas supprimer cet import.
  // Le fichier de configuration local est ignoré par Git et facultatif.
  await safeAsync(
    () => dotenv.load(
      fileName: 'assets/config/runtime.env',
      isOptional: true,
    ),
    context: 'dotenv.load',
    fallbackValue: null,
  );
  await Hive.initFlutter();
  Hive.registerAdapter<Subscription>(SubscriptionAdapter());
  Hive.registerAdapter<SubscriptionType>(SubscriptionTypeAdapter());
  Hive.registerAdapter<TestResultStatus>(TestResultStatusAdapter());
  Hive.registerAdapter<DownloadStatus>(DownloadStatusAdapter());
  Hive.registerAdapter<DownloadProgress>(DownloadProgressAdapter());
  Hive.registerAdapter<DownloadTask>(DownloadTaskAdapter());
  // `DownloadTask.estimatedTimeRemaining` est un `Duration` : sans cet
  // adaptateur, Hive refuse la tâche à l'écriture (« Cannot write, unknown
  // type: Duration »). Constaté en écrivant une vraie tâche dans un test.
  Hive.registerAdapter<Duration>(DurationAdapter());
  // Le home utilise DateFormat(... 'fr_FR') : la locale doit être initialisée,
  // sinon format() lève DateFormat/LocaleDataException et l'accueil ne rend rien.
  await safeAsync(
    () => initializeDateFormatting('fr_FR'),
    context: 'initializeDateFormatting',
    fallbackValue: null,
  );
  final storageService = StorageService();
  await storageService.init();
  final favoritesService = FavoritesService();
  await favoritesService.init();
  final historyService = HistoryService();
  await historyService.init();
  final recentlyWatchedService = RecentlyWatchedService();
  await recentlyWatchedService.init();
  final watchedEpisodesService = WatchedEpisodesService();
  await watchedEpisodesService.init();
  final playbackProgressService = PlaybackProgressService();
  await playbackProgressService.init();
  final cloudSyncMirrorStore = CloudSyncMirrorStore();
  await cloudSyncMirrorStore.init();
  final mediaLibraryManager = MediaLibraryManager();
  await mediaLibraryManager.init([]);

  await BetaConfig.applyIfNeeded();

  // S'assure qu'un éventuel abonnement issu des préférences (source par défaut)
  // est présent en Hive avant de décider de la route de démarrage.
  await storageService.migrateFromSharedPreferences();

  final restoredProfile = await _restoreLastProfile(storageService);
  final onboardingDone = storageService.getSetting('onboarding_done') == true;
  final legalNoticeDone =
      storageService.getSetting(kLegalNoticeDoneKey) == true;
  routerInitialLocation = initialRouteFor(
    onboardingDone: onboardingDone,
    legalNoticeDone: legalNoticeDone,
  );

  final activeSubscriptionId = storageService.getActiveSubscriptionSync()?.id;
  final lastRefresh = activeSubscriptionId == null || activeSubscriptionId.isEmpty
      ? null
      : await loadLastRefresh(subscriptionId: activeSubscriptionId);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        favoritesServiceProvider.overrideWithValue(favoritesService),
        historyServiceProvider.overrideWithValue(historyService),
        recentlyWatchedServiceProvider
            .overrideWithValue(recentlyWatchedService),
        watchedEpisodesServiceProvider
            .overrideWithValue(watchedEpisodesService),
        playbackProgressServiceProvider
            .overrideWith((ref) => playbackProgressService),
        mediaLibraryManagerProvider.overrideWithValue(mediaLibraryManager),
        currentProfileProvider
            .overrideWithBuild((ref, notifier) => restoredProfile),
        lastRefreshTimestampProvider
            .overrideWithBuild((ref, notifier) => lastRefresh),
        licenseManagerProvider.overrideWithValue(LicenseManager()),
        licenseCacheProvider.overrideWithValue(licenseCache),
        drmManagerProvider
            .overrideWithValue(DrmManager(licenseManager: LicenseManager())),
        widevineDelegateProvider.overrideWithValue(
          WidevineDelegate(licenseManager: LicenseManager()),
        ),
      ],
      child: const OrbitApp(),
    ),
  );
}

Future<UserProfile?> _restoreLastProfile(StorageService storage) async {
  final lastId = storage.getSetting('last_profile_id') as String?;
  if (lastId == null || lastId.isEmpty) return null;
  final profiles = await storage.getProfiles();
  for (final profile in profiles) {
    if (profile.id == lastId) return profile.hasPin ? null : profile;
  }
  return null;
}
