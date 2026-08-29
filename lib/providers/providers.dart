import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/vpn_service.dart';
import '../services/subscription_manager.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../services/radio_service.dart';
import '../services/notification_service.dart';
import '../models/user_profile.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../models/epg_program.dart';
import '../models/replay_item.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final aiServiceProvider = Provider<AiService>((ref) => AiService());
final vpnServiceProvider = Provider<VpnService>((ref) => VpnService());
final subscriptionManagerProvider = Provider<SubscriptionManager>((ref) => SubscriptionManager());
final favoritesServiceProvider = Provider<FavoritesService>((ref) => FavoritesService());
final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());
final radioServiceProvider = Provider<RadioService>((ref) => RadioService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final currentProfileProvider = StateProvider<UserProfile?>((ref) => null);

final profilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getProfiles();
});

final liveChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchLiveChannels();
});

final moviesProvider = FutureProvider<List<Movie>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchMovies();
});

final seriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeries();
});

final radioChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchRadioChannels();
});

final replaysProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchReplays();
});

final epgProgramsProvider = FutureProvider<List<EPGProgram>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchEpg();
});
