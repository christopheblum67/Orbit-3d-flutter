import 'dart:async';

import 'package:orbit_3d_flutter/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/matchmaking/duo_profile_selection_screen.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
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
import 'package:orbit_3d_flutter/features/actors/actor_detail_screen.dart';
import 'package:orbit_3d_flutter/features/browse/browse_screen.dart';
import 'package:orbit_3d_flutter/features/replay/replay_screen.dart';
import 'package:orbit_3d_flutter/features/radio/radio_screen.dart';
import 'package:orbit_3d_flutter/features/epg/epg_screen.dart';
import 'package:orbit_3d_flutter/features/search/search_screen.dart';

import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/unified_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/category_filter_screen.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/features/multivideo/multivideo_screen.dart';
import 'package:orbit_3d_flutter/features/library/library_screen.dart';
import 'package:orbit_3d_flutter/features/history/history_screen.dart';
import 'package:orbit_3d_flutter/core/navigation/form_back_handler.dart';
import 'package:orbit_3d_flutter/core/navigation/route_meta.dart';
import 'package:orbit_3d_flutter/core/navigation/with_back_handling.dart';
import 'package:orbit_3d_flutter/core/utils/error_handler.dart';

String routerInitialLocation = '/profiles';

/// Journalise un `screen_view` à chaque changement de route (Firebase Analytics).
/// Fire-and-forget : aucun échec ne doit perturber la navigation.
class AnalyticsRouteObserver extends NavigatorObserver {
  /// Service injecte au moment de la construction du router. Un
  /// `NavigatorObserver` n'a pas acces au `Ref`, donc on le capture ici.
  final AnalyticsService analytics;

  AnalyticsRouteObserver(this.analytics);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(previousRoute);
  }

  void _log(Route<dynamic>? route) {
    final settings = route?.settings;
    if (settings == null) return;
    final name = settings.name ?? 'route';
    // Ignore: journaliser un écran ne doit jamais bloquer ni échouer la navigation.
    // ignore: avoid_slow_async_io
    unawaited(_safeScreenView(name));
  }

  Future<void> _safeScreenView(String name) async {
    // Passe par le service : il verifie que Firebase est reellement
    // initialise. Un appel direct a `FirebaseAnalytics.instance` levait
    // « No Firebase App '[DEFAULT]' has been created » a chaque navigation.
    final analytics = this.analytics;
    // Le router est construit avant l'init du service partage : on tente
    // l'initialisation ici (idempotente) plutot que d'ignorer le premier
    // evenement de navigation.
    if (!analytics.isReady) {
      await analytics.init();
      if (!analytics.isReady) return;
    }
    await safeAsync(
      () => analytics.logScreenView(name),
      context: '_safeScreenView',
      fallbackValue: null,
    );
  }
}

final GoRouter router = GoRouter(
  initialLocation: routerInitialLocation,
  observers: <NavigatorObserver>[AnalyticsRouteObserver(AnalyticsService())],
  routes: [
    GoRoute(
      path: '/legal',
      builder: (context, state) {
        final firstLaunch = state.uri.queryParameters['flow'] == 'first';
        return firstLaunch
            ? const LegalNoticeScreen(firstLaunch: true)
            : const LegalNoticeScreen();
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingConfigScreen(),
    ),
    GoRoute(
      path: '/profiles',
      builder: (context, state) => ProfileSelectionScreen(
        startupFlow: state.uri.queryParameters['startup'] == 'true',
      ),
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
          meta: const RouteMeta.pop(),
          child: PinPadScreen(
            args: args is PinPadArgs ? args : const PinPadArgs.set(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/profile/preferences',
      builder: (context, state) => const ModalBackHandling(
        meta: RouteMeta.pop(),
        child: ProfilePreferencesScreen(),
      ),
    ),
    GoRoute(
      path: '/parental',
      builder: (context, state) => const ModalBackHandling(
        meta: RouteMeta.pop(),
        child: ParentalControlScreen(),
      ),
    ),
    GoRoute(
      path: '/matchmaking',
      builder: (context, state) => const ModalBackHandling(
        meta: RouteMeta.popOrFallback('/home'),
        child: MatchmakingScreen(),
      ),
    ),
    GoRoute(
      path: '/duo',
      builder: (context, state) => const ModalBackHandling(
        meta: RouteMeta.popOrFallback('/home'),
        child: DuoProfileSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/matchmaking/duo',
      builder: (context, state) => ModalBackHandling(
        meta: const RouteMeta.popOrFallback('/home'),
        child: MatchmakingScreen(initialGroup: state.extra as List<String>?),
      ),
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) {
        final playerKey = GlobalKey<PlayerScreenState>();

        // Normaliser les paramètres vers PlayerRouteData (extra prioritaire, sinon queryParams)
        PlayerRouteData routeData;
        final extra = state.extra;
        if (extra is PlayerRouteData) {
          routeData = extra;
        } else {
          // Fallback pour deep links externes (query parameters)
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
          routeData = PlayerRouteData(
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
        }

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
            child: PlayerScreen(
              key: playerKey,
              streamUrl: routeData.streamUrl,
              title: routeData.title,
              channels: routeData.channels,
              initialIndex: routeData.index,
              progressId: routeData.progressId,
              initialPositionMs: routeData.initialPositionMs,
              vodId: routeData.vodId,
              consecutiveEpisodes: routeData.consecutiveEpisodes,
              contentType: routeData.contentType,
              favorite: routeData.favorite,
              posterUrl: routeData.posterUrl,
              subtitle: routeData.subtitle,
              rating: routeData.rating,
              genre: routeData.genre,
              year: routeData.year,
              seriesName: routeData.seriesName,
              episodeLabel: routeData.episodeLabel,
              series: routeData.series,
              episode: routeData.episode,
            ),
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
      path: '/actor/detail',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'actor_detail',
        child: WithBackHandling(
          meta: const RouteMeta.pop(restorationId: 'actor_detail'),
          child: () {
            final actor = state.extra;
            if (actor is Actor) return ActorDetailScreen(actor: actor);
            return const Material(child: SizedBox.shrink());
          }(),
        ),
      ),
    ),
    GoRoute(
      path: '/vod/detail',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'vod_detail',
        child: WithBackHandling(
          meta: const RouteMeta.pop(restorationId: 'vod_detail'),
          child: () {
            final movie = state.extra;
            if (movie is Movie) return MovieDetailScreen(movie: movie);
            // Navigation depuis un modèle compact : on reconstruit une fiche
            // minimale, l'écran recharge le détail complet via son provider.
            final id = state.uri.queryParameters['id'] ?? '';
            if (id.isNotEmpty) {
              return MovieDetailScreen(movie: Movie.fromStreamId(id));
            }
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
          meta: const RouteMeta.pop(restorationId: 'series_detail'),
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
          meta: const RouteMeta.pop(restorationId: 'episode_detail'),
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
        child: const WithBackHandling(
          meta: RouteMeta.pop(restorationId: 'favorites'),
          child: LibraryScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        restorationId: 'history',
        child: const WithBackHandling(
          meta: RouteMeta.pop(restorationId: 'history'),
          child: HistoryScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/startup',
      builder: (context, state) => StartupSplashScreen(
        remainingPhase: state.uri.queryParameters['phase'] == 'remaining',
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'home',
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/live',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'live',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'live'),
              child: LiveTvScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/series',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'series',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'series'),
              child: SeriesScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/vod',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'vod',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'vod'),
              child: VodScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/browse',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'browse',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'browse'),
              child: BrowseScreen(),
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
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'replay'),
              child: ReplayScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/epg',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'epg',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'epg'),
              child: EpgScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'search',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'search'),
              child: SearchScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/downloads',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'downloads',
            child: const WithBackHandling(
              meta:
                  RouteMeta.popOrFallback('/home', restorationId: 'downloads'),
              child: LibraryScreen(initialTab: 1),
            ),
          ),
        ),
        GoRoute(
          path: '/subscriptions',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'subscriptions',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback(
                '/home',
                restorationId: 'subscriptions',
              ),
              child: SubscriptionsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'settings',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'settings'),
              child: UnifiedSettingsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/advanced',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'settings-advanced',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback(
                '/settings',
                restorationId: 'settings-advanced',
              ),
              child: AdvancedSettingsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/category-filters',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'category-filters',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback(
                '/settings',
                restorationId: 'category-filters',
              ),
              child: CategoryFilterScreen(),
            ),
          ),
        ),
      ],
    ),
  ],
);
