import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/core/theme/app_theme.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/notification_service.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/services/beta_config.dart';
import 'package:orbit_3d_flutter/features/home_shell.dart';
import 'package:orbit_3d_flutter/features/startup/startup_splash_screen.dart';
import 'package:orbit_3d_flutter/features/home/home_screen.dart';
import 'package:orbit_3d_flutter/features/profile/profile_selection_screen.dart';
import 'package:orbit_3d_flutter/features/onboarding/onboarding_screen.dart';
import 'package:orbit_3d_flutter/features/legal/legal_notice_screen.dart';
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
import 'package:orbit_3d_flutter/features/browse/browse_screen.dart';
import 'package:orbit_3d_flutter/features/replay/replay_screen.dart';
import 'package:orbit_3d_flutter/features/radio/radio_screen.dart';
import 'package:orbit_3d_flutter/features/epg/epg_screen.dart';
import 'package:orbit_3d_flutter/features/search/search_screen.dart';

import 'package:orbit_3d_flutter/features/settings/settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/features/multivideo/multivideo_screen.dart';
import 'package:orbit_3d_flutter/features/favorites/favorites_screen.dart';
import 'package:orbit_3d_flutter/features/history/history_screen.dart';
import 'package:orbit_3d_flutter/core/navigation/form_back_handler.dart';
import 'package:orbit_3d_flutter/core/navigation/route_meta.dart';
import 'package:orbit_3d_flutter/core/navigation/with_back_handling.dart';
import 'package:orbit_3d_flutter/core/widgets/confirm_exit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // L'import de webview_flutter_android enregistre (dartPluginClass) la
  // plateforme Android WebView automatiquement, nécessaire au déblocage
  // Cloudflare. Ne pas supprimer cet import.
  // Le fichier .env est optionnel : son absence ne doit pas bloquer le démarrage.
  // isOptional=true : sans .env (asset non embarqué), dotenv reste initialisé
  // avec une carte vide. Autrement dotenv.env lèverait NotInitializedError et
  // ferait échouer toute construction de service d'enrichissement métadonnées.
  try {
    await dotenv.load(isOptional: true);
  } catch (_) {
    // Pas de fichier .env embarqué : on continue avec les valeurs par défaut.
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
  final recentlyWatchedService = RecentlyWatchedService();
  await recentlyWatchedService.init();
  final watchedEpisodesService = WatchedEpisodesService();
  await watchedEpisodesService.init();
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
  final onboardingDone = storageService.getSetting('onboarding_done') == true;
  final legalNoticeDone =
      storageService.getSetting(kLegalNoticeDoneKey) == true;
  routerInitialLocation = !onboardingDone
      // Premier lancement : le lisez-moi (usage + ayants droit) précède le
      // diagnostic. S'il a déjà été accepté, on passe directement à la
      // configuration.
      ? (legalNoticeDone ? '/onboarding' : '/legal?flow=first')
      : hasDefaultConfig
          ? '/startup'
          : '/profiles';

  final lastRefresh = await loadLastRefresh();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        favoritesServiceProvider.overrideWithValue(favoritesService),
        historyServiceProvider.overrideWithValue(historyService),
        recentlyWatchedServiceProvider
            .overrideWithValue(recentlyWatchedService),
        watchedEpisodesServiceProvider.overrideWithValue(watchedEpisodesService),
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
      path: '/legal',
      builder: (context, state) {
        final firstLaunch = state.uri.queryParameters['flow'] == 'first';
        return firstLaunch
            ? ConfirmExitApp(child: const LegalNoticeScreen(firstLaunch: true))
            : const LegalNoticeScreen();
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => ConfirmExitApp(child: const OnboardingConfigScreen()),
    ),
    GoRoute(
      path: '/profiles',
      builder: (context, state) => const ProfileSelectionScreen(),
    ),
    GoRoute(
      path: '/profile/create',
      builder: (context, state) {
        final editKey = GlobalKey<ProfileEditScreenState>();
        return FormBackHandlerScope(
          onWillPop: () async {
            return (await editKey.currentState?.confirmLeave()) ?? true;
          },
          child: ProfileEditScreen(key: editKey),
        );
      },
    ),
    GoRoute(
      path: '/profile/edit/:id',
      builder: (context, state) {
        final editKey = GlobalKey<ProfileEditScreenState>();
        return FormBackHandlerScope(
          onWillPop: () async {
            return (await editKey.currentState?.confirmLeave()) ?? true;
          },
          child: ProfileEditScreen(
            key: editKey,
            profileId: state.pathParameters['id'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/profile/pin',
      builder: (context, state) {
        final args = state.extra;
        return ModalBackHandling(
          meta: RouteMeta.pop(),
          child: PinPadScreen(
            args: args is PinPadArgs ? args : const PinPadArgs.set(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/profile/preferences',
      builder: (context, state) => ModalBackHandling(
        meta: RouteMeta.pop(),
        child: const ProfilePreferencesScreen(),
      ),
    ),
    GoRoute(
      path: '/parental',
      builder: (context, state) => ModalBackHandling(
        meta: RouteMeta.pop(),
        child: const ParentalControlScreen(),
      ),
    ),
    GoRoute(
      path: '/matchmaking',
      builder: (context, state) => ModalBackHandling(
        meta: RouteMeta.popOrFallback('/home'),
        child: const MatchmakingScreen(),
      ),
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) {
        final playerKey = GlobalKey<PlayerScreenState>();
        return MaterialPage(
          key: state.pageKey,
          restorationId: 'player',
          child: WithBackHandling(
            meta: RouteMeta.custom(
              (context, router) {
                final playerState = playerKey.currentState;
                if (playerState != null) {
                  playerState.cleanup();
                }
                if (router.canPop()) {
                  router.pop();
                } else {
                  router.go('/home');
                }
              },
              restorationId: 'player',
            ),
            child: () {
              final data = state.extra;
              if (data is PlayerRouteData) {
                return PlayerScreen(
                  key: playerKey,
                  streamUrl: data.streamUrl,
                  title: data.title,
                  channels: data.channels,
                  initialIndex: data.index,
                  progressId: data.progressId,
                  initialPositionMs: data.initialPositionMs,
                  contentType: data.contentType,
                  favorite: data.favorite,
                  posterUrl: data.posterUrl,
                  subtitle: data.subtitle,
                  rating: data.rating,
                  genre: data.genre,
                  year: data.year,
                  seriesName: data.seriesName,
                  episodeLabel: data.episodeLabel,
                );
              }
              final url = state.uri.queryParameters['url'] ?? '';
              final title = state.uri.queryParameters['title'] ?? 'Lecture';
              final progressId = state.uri.queryParameters['progressId'];
              final initialPos =
                  int.tryParse(state.uri.queryParameters['pos'] ?? '');
              final contentType = switch (state.uri.queryParameters['type']) {
                'vod' => PlaybackContentType.vod,
                'series' => PlaybackContentType.series,
                'replay' => PlaybackContentType.replay,
                _ => PlaybackContentType.live,
              };
              final typeParam = state.uri.queryParameters['type'] ?? '';
              final queryPoster = state.uri.queryParameters['poster'];
              final querySubtitle = state.uri.queryParameters['subtitle'];
              final queryGenre = state.uri.queryParameters['genre'];
              final queryYear =
                  int.tryParse(state.uri.queryParameters['year'] ?? '') ?? 0;
              final queryRating =
                  double.tryParse(state.uri.queryParameters['rating'] ?? '');
              final queryFavorite = (url.isNotEmpty && typeParam.isNotEmpty)
                  ? FavoriteEntry(
                      type: ContentType.fromString(typeParam),
                      id: url,
                      title: title,
                      posterUrl: queryPoster ?? '',
                      subtitle: querySubtitle ?? '',
                      streamUrl: url,
                    )
                  : null;
              return PlayerScreen(
                key: playerKey,
                streamUrl: url,
                title: title,
                progressId: progressId,
                initialPositionMs: initialPos,
                contentType: contentType,
                favorite: queryFavorite,
                posterUrl: queryPoster,
                subtitle: querySubtitle,
                genre: queryGenre,
                year: queryYear,
                rating: queryRating,
              );
            }(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/multivideo',
      pageBuilder: (context, state) {
        final multiVideoKey = GlobalKey<MultiVideoScreenState>();
        return MaterialPage(
          key: state.pageKey,
          restorationId: 'multivideo',
          child: WithBackHandling(
            meta: RouteMeta.custom(
              (context, router) {
                final state = multiVideoKey.currentState;
                if (state != null) {
                  state.disposeAllControllers();
                }
                if (router.canPop()) {
                  router.pop();
                } else {
                  router.go('/home');
                }
              },
              restorationId: 'multivideo',
            ),
            child: MultiVideoScreen(key: multiVideoKey),
          ),
        );
      },
    ),
    GoRoute(
      path: '/vod/detail',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'vod_detail',
        child: WithBackHandling(
          meta: RouteMeta.pop(restorationId: 'vod_detail'),
          child: () {
            final movie = state.extra;
            if (movie is Movie) return MovieDetailScreen(movie: movie);
            return const Material(child: SizedBox.shrink());
          }(),
        ),
      ),
    ),
    GoRoute(
      path: '/series/detail',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'series_detail',
        child: WithBackHandling(
          meta: RouteMeta.pop(restorationId: 'series_detail'),
          child: SeriesDetailScreen(
            seriesId: state.uri.queryParameters['id'] ?? '',
            title: state.uri.queryParameters['title'] ?? '',
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/episode/detail',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'episode_detail',
        child: WithBackHandling(
          meta: RouteMeta.pop(restorationId: 'episode_detail'),
          child: () {
            final args = state.extra;
            if (args is (Series, Episode)) {
              final (series, episode) = args;
              return EpisodeDetailScreen(series: series, episode: episode);
            }
            return const Material(child: SizedBox.shrink());
          }(),
        ),
      ),
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'favorites',
        child: WithBackHandling(
          meta: RouteMeta.pop(restorationId: 'favorites'),
          child: const FavoritesScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'history',
        child: WithBackHandling(
          meta: RouteMeta.pop(restorationId: 'history'),
          child: const HistoryScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/startup',
      builder: (context, state) => const StartupSplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'home',
            child: ConfirmExitApp(child: const HomeScreen()),
          ),
        ),
        GoRoute(
          path: '/live',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'live',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'live'),
              child: const LiveTvScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/series',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'series',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'series'),
              child: const SeriesScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/vod',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'vod',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'vod'),
              child: const VodScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/browse',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'browse',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'browse'),
              child: const BrowseScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/radio',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'radio',
            child: WithBackHandling(
              meta: RouteMeta.custom(
                (context, router) {
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  container.read(radioServiceProvider).stop();
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go('/home');
                  }
                },
                restorationId: 'radio',
              ),
              child: const RadioScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/replay',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'replay',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'replay'),
              child: const ReplayScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/epg',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'epg',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'epg'),
              child: const EpgScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'search',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'search'),
              child: const SearchScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'settings',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'settings'),
              child: const SettingsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/advanced',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'settings_advanced',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/settings', restorationId: 'settings_advanced'),
              child: const AdvancedSettingsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/subscriptions',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'subscriptions',
            child: WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'subscriptions'),
              child: const SubscriptionsScreen(),
            ),
          ),
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
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(advancedSettingsProvider.notifier).load());
    unawaited(ref.read(tmdbApiKeyOverrideProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final advancedSettings = ref.watch(advancedSettingsProvider);
    return MaterialApp.router(
      title: 'Orbit IPTV',
      theme: AppTheme.lightTheme(highContrast: advancedSettings.highContrast),
      darkTheme: AppTheme.darkTheme(highContrast: advancedSettings.highContrast),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
