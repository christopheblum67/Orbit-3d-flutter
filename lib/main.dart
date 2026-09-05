import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
// L'import ci-dessous (webview_flutter_android) charge et enregistre la
// plateforme Android WebView au démarrage (dartPluginClass), requis par le
// déblocage Cloudflare (cf_clearance). Ne pas retirer l'import.
// ignore: unused_import
import 'package:webview_flutter/webview_flutter.dart';
// ignore: unused_import
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/core/theme/app_theme.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/notification_service.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/services/beta_config.dart';
import 'package:orbit_3d_flutter/features/home_shell.dart';
import 'package:orbit_3d_flutter/features/startup/startup_splash_screen.dart';
import 'package:orbit_3d_flutter/features/home/home_screen.dart';
import 'package:orbit_3d_flutter/features/profile/profile_selection_screen.dart';
import 'package:orbit_3d_flutter/features/profile/profile_edit_screen.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/features/auth/profile_preferences_screen.dart';
import 'package:orbit_3d_flutter/features/auth/parental_control_screen.dart';
import 'package:orbit_3d_flutter/features/matchmaking/matchmaking_screen.dart';
import 'package:orbit_3d_flutter/features/live_tv/live_tv_screen.dart';
import 'package:orbit_3d_flutter/features/series/series_screen.dart';
import 'package:orbit_3d_flutter/features/series/series_detail_screen.dart';
import 'package:orbit_3d_flutter/features/series/episode_detail_screen.dart';
import 'package:orbit_3d_flutter/features/vod/vod_screen.dart';
import 'package:orbit_3d_flutter/features/vod/movie_detail_screen.dart';
import 'package:orbit_3d_flutter/features/replay/replay_screen.dart';
import 'package:orbit_3d_flutter/features/radio/radio_screen.dart';
import 'package:orbit_3d_flutter/features/epg/epg_screen.dart';
import 'package:orbit_3d_flutter/features/search/search_screen.dart';
import 'package:orbit_3d_flutter/features/ai/ai_screen.dart';

import 'package:orbit_3d_flutter/features/settings/settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/features/multivideo/multivideo_screen.dart';
import 'package:orbit_3d_flutter/features/favorites/favorites_screen.dart';
import 'package:orbit_3d_flutter/features/history/history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // L'import de webview_flutter_android enregistre (dartPluginClass) la
  // plateforme Android WebView automatiquement, nécessaire au déblocage
  // Cloudflare. Ne pas supprimer cet import.
  // Le fichier .env est optionnel : son absence ne doit pas bloquer le d�marrage.
  try {
    await dotenv.load();
  } catch (_) {
    // Pas de fichier .env embarqu� : on continue avec les valeurs par d�faut.
  }
  await Hive.initFlutter();
  Hive.registerAdapter<Subscription>(SubscriptionAdapter());
  Hive.registerAdapter<SubscriptionType>(SubscriptionTypeAdapter());
  Hive.registerAdapter<TestResultStatus>(TestResultStatusAdapter());
  // Le home utilise DateFormat(... 'fr_FR') : la locale doit être initialisée,
  // sinon format() lève DateFormat/LocaleDataException et l'accueil ne rend rien.
  try {
    await initializeDateFormatting('fr_FR');
  } catch (_) {
    // Non bloquant : on retombe sur la locale par défaut si indisponible.
  }
  final storageService = StorageService();
  await storageService.init();
  final favoritesService = FavoritesService();
  await favoritesService.init();
  final historyService = HistoryService();
  await historyService.init();
  final playbackProgressService = PlaybackProgressService();
  await playbackProgressService.init();
  final notificationService = NotificationService();
  final mediaLibraryManager = MediaLibraryManager();
  await mediaLibraryManager.init([]);

  await BetaConfig.applyIfNeeded();

  // S'assure qu'un éventuel abonnement issu des préférences (source par défaut)
  // est présent en Hive avant de décider de la route de démarrage.
  await storageService.migrateFromSharedPreferences();

  final restoredProfile = await _restoreLastProfile(storageService);
  final hasActiveServer = await storageService.getActiveSubscription() != null;
  final hasDefaultConfig = restoredProfile != null && hasActiveServer;
  routerInitialLocation = hasDefaultConfig ? '/startup' : '/profiles';

  final lastRefresh = await loadLastRefresh();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        favoritesServiceProvider.overrideWithValue(favoritesService),
        historyServiceProvider.overrideWithValue(historyService),
        playbackProgressServiceProvider
            .overrideWithValue(playbackProgressService),
        notificationServiceProvider.overrideWithValue(notificationService),
        mediaLibraryManagerProvider.overrideWithValue(mediaLibraryManager),
        currentProfileProvider.overrideWith((ref) => restoredProfile),
        lastRefreshTimestampProvider.overrideWith((ref) => lastRefresh),
      ],
      child: const OrbitApp(),
    ),
  );

  // FCM initialisé après le premier frame pour ne pas bloquer l'affichage.
  SchedulerBinding.instance.addPostFrameCallback((_) {
    notificationService.init();
  });
}

Future<UserProfile?> _restoreLastProfile(StorageService storage) async {
  final lastId = storage.getSetting('last_profile_id') as String?;
  if (lastId == null || lastId.isEmpty) return null;
  final profiles = await storage.getProfiles();
  for (final profile in profiles) {
    if (profile.id == lastId) return profile;
  }
  return null;
}

String routerInitialLocation = '/profiles';

final GoRouter router = GoRouter(
  initialLocation: routerInitialLocation,
  routes: [
    GoRoute(
      path: '/profiles',
      builder: (context, state) => const ProfileSelectionScreen(),
    ),
    GoRoute(
      path: '/profile/create',
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/profile/edit/:id',
      builder: (context, state) => ProfileEditScreen(
        profileId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/profile/pin',
      builder: (context, state) {
        final args = state.extra;
        return PinPadScreen(
          args: args is PinPadArgs ? args : const PinPadArgs.set(),
        );
      },
    ),
    GoRoute(
      path: '/profile/preferences',
      builder: (context, state) => const ProfilePreferencesScreen(),
    ),
    GoRoute(
      path: '/parental',
      builder: (context, state) => const ParentalControlScreen(),
    ),
    GoRoute(
      path: '/matchmaking',
      builder: (context, state) => const MatchmakingScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final data = state.extra;
        if (data is PlayerRouteData) {
          return PlayerScreen(
            streamUrl: data.streamUrl,
            title: data.title,
            channels: data.channels,
            initialIndex: data.index,
            progressId: data.progressId,
            initialPositionMs: data.initialPositionMs,
            contentType: data.contentType,
          );
        }
        final url = state.uri.queryParameters['url'] ?? '';
        final title = state.uri.queryParameters['title'] ?? 'Lecture';
        final progressId = state.uri.queryParameters['progressId'];
        final initialPos = int.tryParse(state.uri.queryParameters['pos'] ?? '');
        final contentType = switch (state.uri.queryParameters['type']) {
          'vod' => PlaybackContentType.vod,
          'series' => PlaybackContentType.series,
          'replay' => PlaybackContentType.replay,
          _ => PlaybackContentType.live,
        };
        return PlayerScreen(
          streamUrl: url,
          title: title,
          progressId: progressId,
          initialPositionMs: initialPos,
          contentType: contentType,
        );
      },
    ),
    GoRoute(
      path: '/vod/detail',
      builder: (context, state) {
        final movie = state.extra;
        if (movie is Movie) return MovieDetailScreen(movie: movie);
        return const Material(child: SizedBox.shrink());
      },
    ),
    GoRoute(
      path: '/series/detail',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'] ?? '';
        final title = state.uri.queryParameters['title'] ?? '';
        return SeriesDetailScreen(seriesId: id, title: title);
      },
    ),
    GoRoute(
      path: '/episode/detail',
      builder: (context, state) {
        final args = state.extra;
        if (args is (Series, Episode)) {
          final (series, episode) = args;
          return EpisodeDetailScreen(series: series, episode: episode);
        }
        return const Material(child: SizedBox.shrink());
      },
    ),
    GoRoute(
      path: '/multivideo',
      builder: (context, state) => const MultiVideoScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/startup',
      builder: (context, state) => const StartupSplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/live',
          builder: (context, state) => const LiveTvScreen(),
        ),
        GoRoute(
          path: '/series',
          builder: (context, state) => const SeriesScreen(),
        ),
        GoRoute(path: '/vod', builder: (context, state) => const VodScreen()),
        GoRoute(
          path: '/radio',
          builder: (context, state) => const RadioScreen(),
        ),
        GoRoute(
          path: '/replay',
          builder: (context, state) => const ReplayScreen(),
        ),
        GoRoute(path: '/epg', builder: (context, state) => const EpgScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(path: '/ai', builder: (context, state) => const AiScreen()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/advanced',
          builder: (context, state) => const AdvancedSettingsScreen(),
        ),
        GoRoute(
          path: '/subscriptions',
          builder: (context, state) => const SubscriptionsScreen(),
        ),
      ],
    ),
  ],
);

class OrbitApp extends ConsumerStatefulWidget {
  const OrbitApp({super.key});

  @override
  ConsumerState<OrbitApp> createState() => _OrbitAppState();
}

class _OrbitAppState extends ConsumerState<OrbitApp> {
  bool _dialogOpen = false;

  Future<void> _confirmExit() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const _ExitConfirmDialog(),
    );
    _dialogOpen = false;
    if (shouldExit == true && context.mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Orbit IPTV',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmExit();
        },
        child: child!,
      ),
    );
  }
}

class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16181E),
      title: const Row(
        children: [
          Icon(
            Icons.power_settings_new_rounded,
            color: Color(0xFFFF6B6B),
            size: 26,
          ),
          SizedBox(width: 10),
          Text(
            'Quitter Orbit IPTV',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: const Text(
        'Voulez-vous vraiment fermer l\'application ?',
        style: TextStyle(color: Colors.white70, fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Non',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Oui',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
