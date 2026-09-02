import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/core/theme/app_theme.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/notification_service.dart';
import 'package:orbit_3d_flutter/services/beta_config.dart';
import 'package:orbit_3d_flutter/features/home_shell.dart';
import 'package:orbit_3d_flutter/features/home/home_screen.dart';
import 'package:orbit_3d_flutter/features/auth/profile_selection_screen.dart';
import 'package:orbit_3d_flutter/features/auth/profile_creation_screen.dart';
import 'package:orbit_3d_flutter/features/auth/profile_preferences_screen.dart';
import 'package:orbit_3d_flutter/features/auth/parental_control_screen.dart';
import 'package:orbit_3d_flutter/features/matchmaking/matchmaking_screen.dart';
import 'package:orbit_3d_flutter/features/live_tv/live_tv_screen.dart';
import 'package:orbit_3d_flutter/features/series/series_screen.dart';
import 'package:orbit_3d_flutter/features/series/series_detail_screen.dart';
import 'package:orbit_3d_flutter/features/vod/vod_screen.dart';
import 'package:orbit_3d_flutter/features/replay/replay_screen.dart';
import 'package:orbit_3d_flutter/features/radio/radio_screen.dart';
import 'package:orbit_3d_flutter/features/epg/epg_screen.dart';
import 'package:orbit_3d_flutter/features/search/search_screen.dart';
import 'package:orbit_3d_flutter/features/ai/ai_screen.dart';
import 'package:orbit_3d_flutter/features/vpn/vpn_screen.dart';
import 'package:orbit_3d_flutter/features/settings/settings_screen.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/features/multivideo/multivideo_screen.dart';
import 'package:orbit_3d_flutter/features/favorites/favorites_screen.dart';
import 'package:orbit_3d_flutter/features/history/history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  final notificationService = NotificationService();

  await BetaConfig.applyIfNeeded();

  // S'assure qu'un éventuel abonnement issu des préférences (source par défaut)
  // est présent en Hive avant de décider de la route de démarrage.
  await storageService.migrateFromSharedPreferences();

  final restoredProfile = await _restoreLastProfile(storageService);
  final hasActiveServer = await storageService.getActiveSubscription() != null;
  final hasDefaultConfig = restoredProfile != null && hasActiveServer;
  routerInitialLocation = hasDefaultConfig ? '/home' : '/profiles';

  runApp(ProviderScope(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
      favoritesServiceProvider.overrideWithValue(favoritesService),
      historyServiceProvider.overrideWithValue(historyService),
      notificationServiceProvider.overrideWithValue(notificationService),
      currentProfileProvider.overrideWith((ref) => restoredProfile),
    ],
    child: const OrbitApp(),
  ),);

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
        builder: (context, state) => const ProfileSelectionScreen(),),
    GoRoute(
        path: '/profile/create',
        builder: (context, state) => const ProfileCreationScreen(),),
    GoRoute(
        path: '/profile/preferences',
        builder: (context, state) => const ProfilePreferencesScreen(),),
    GoRoute(
        path: '/parental',
        builder: (context, state) => const ParentalControlScreen(),),
    GoRoute(
        path: '/matchmaking',
        builder: (context, state) => const MatchmakingScreen(),),
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
            );
          }
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Lecture';
          return PlayerScreen(streamUrl: url, title: title);
        },),
    GoRoute(
        path: '/series/detail',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          final title = state.uri.queryParameters['title'] ?? '';
          return SeriesDetailScreen(seriesId: id, title: title);
        },),
    GoRoute(
        path: '/multivideo',
        builder: (context, state) => const MultiVideoScreen(),),
    GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),),
    GoRoute(
        path: '/history', builder: (context, state) => const HistoryScreen(),),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
            path: '/live', builder: (context, state) => const LiveTvScreen(),),
        GoRoute(
            path: '/series', builder: (context, state) => const SeriesScreen(),),
        GoRoute(path: '/vod', builder: (context, state) => const VodScreen()),
        GoRoute(
            path: '/radio', builder: (context, state) => const RadioScreen(),),
        GoRoute(
            path: '/replay', builder: (context, state) => const ReplayScreen(),),
        GoRoute(path: '/epg', builder: (context, state) => const EpgScreen()),
        GoRoute(
            path: '/search', builder: (context, state) => const SearchScreen(),),
        GoRoute(path: '/ai', builder: (context, state) => const AiScreen()),
        GoRoute(path: '/vpn', builder: (context, state) => const VpnScreen()),
        GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),),
        GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),),
      ],
    ),
  ],
);

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Orbit 3D IPTV',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
