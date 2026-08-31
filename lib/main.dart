import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/subscription.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'services/storage_service.dart';
import 'services/favorites_service.dart';
import 'services/history_service.dart';
import 'services/notification_service.dart';
import 'services/beta_config.dart';
import 'features/home_shell.dart';
import 'features/home/home_screen.dart';
import 'features/auth/profile_selection_screen.dart';
import 'features/auth/profile_creation_screen.dart';
import 'features/live_tv/live_tv_screen.dart';
import 'features/series/series_screen.dart';
import 'features/vod/vod_screen.dart';
import 'features/replay/replay_screen.dart';
import 'features/radio/radio_screen.dart';
import 'features/epg/epg_screen.dart';
import 'features/search/search_screen.dart';
import 'features/ai/ai_screen.dart';
import 'features/vpn/vpn_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/player/player_screen.dart';
import 'features/multivideo/multivideo_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/history/history_screen.dart';

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
  final storageService = StorageService();
  await storageService.init();
  final favoritesService = FavoritesService();
  await favoritesService.init();
  final historyService = HistoryService();
  await historyService.init();
  final notificationService = NotificationService();
  await notificationService.init();

  await BetaConfig.applyIfNeeded();

  runApp(ProviderScope(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
      favoritesServiceProvider.overrideWithValue(favoritesService),
      historyServiceProvider.overrideWithValue(historyService),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
    child: const OrbitApp(),
  ));
}

final GoRouter router = GoRouter(
  initialLocation: '/profiles',
  routes: [
    GoRoute(path: '/profiles', builder: (context, state) => const ProfileSelectionScreen()),
GoRoute(path: '/profile/create', builder: (context, state) => const ProfileCreationScreen()),
    GoRoute(path: '/player', builder: (context, state) {
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
    }),
    GoRoute(path: '/multivideo', builder: (context, state) => const MultiVideoScreen()),
    GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
    GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/live', builder: (context, state) => const LiveTvScreen()),
        GoRoute(path: '/series', builder: (context, state) => const SeriesScreen()),
        GoRoute(path: '/vod', builder: (context, state) => const VodScreen()),
        GoRoute(path: '/radio', builder: (context, state) => const RadioScreen()),
        GoRoute(path: '/replay', builder: (context, state) => const ReplayScreen()),
        GoRoute(path: '/epg', builder: (context, state) => const EpgScreen()),
        GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
        GoRoute(path: '/ai', builder: (context, state) => const AiScreen()),
        GoRoute(path: '/vpn', builder: (context, state) => const VpnScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        GoRoute(path: '/subscriptions', builder: (context, state) => const SubscriptionsScreen()),
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
