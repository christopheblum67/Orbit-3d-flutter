import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/error_handler.dart';
import '../services/stream_helpers.dart' as stream_helpers;
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
import '../models/ai_recommendation.dart';

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

final epgProgramsProvider =
    AsyncNotifierProvider<EPGProgramsNotifier, List<EPGProgram>>(
  EPGProgramsNotifier.new,
);

class EPGProgramsNotifier extends AsyncNotifier<List<EPGProgram>> {
  @override
  Future<List<EPGProgram>> build() async {
    final api = ref.watch(apiServiceProvider);
    try {
      return await stream_helpers.retryStream(
        () => api.fetchEpg(),
        attempts: 2,
      );
    } catch (error, stackTrace) {
      ErrorHandler.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: 'EPG',
      );
      rethrow;
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final aiRecommendationsProvider =
    FutureProvider.autoDispose.family<List<AIRecommendation>, String>((ref, profileId) async {
  final aiService = ref.watch(aiServiceProvider);
  final profile = ref.watch(currentProfileProvider);
  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];

  if (profile == null || profile.id != profileId) {
    throw const StreamAiException('Aucun profil sélectionné pour les recommandations.');
  }

  return aiService.getRecommendations(profile, movies);
});

class StreamAiException implements Exception {
  const StreamAiException(this.message);

  final String message;

  @override
  String toString() => message;
}
