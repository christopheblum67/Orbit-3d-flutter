import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/core/utils/error_handler.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/ai_service.dart';
import 'package:orbit_3d_flutter/services/vpn_service.dart';
import 'package:orbit_3d_flutter/services/subscription_manager.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/radio_service.dart';
import 'package:orbit_3d_flutter/services/notification_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/ai_recommendation.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
final aiServiceProvider = Provider<AiService>((ref) => AiService());
final vpnServiceProvider = Provider<VpnService>((ref) => VpnService());
final subscriptionManagerProvider =
    Provider<SubscriptionManager>((ref) => SubscriptionManager());
final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());
final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());
final radioServiceProvider = Provider<RadioService>((ref) => RadioService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
final playbackProgressServiceProvider =
    Provider<PlaybackProgressService>((ref) => PlaybackProgressService());
final mediaLibraryManagerProvider =
    Provider<MediaLibraryManager>((ref) => MediaLibraryManager());

final playbackProgressProvider =
    Provider.family<PlaybackProgress?, String>((ref, id) {
  return ref.watch(playbackProgressServiceProvider).get(id);
});

final currentProfileProvider = StateProvider<UserProfile?>((ref) => null);

final sourceTypeProvider = FutureProvider<String?>((ref) async {
  final sub =
      await ref.watch(subscriptionManagerProvider).getActiveSubscription();
  return sub['type'];
});

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

final vodCategoriesProvider = FutureProvider<List<MediaCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchVodCategories();
});

final seriesCategoriesProvider =
    FutureProvider<List<MediaCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeriesCategories();
});

final seriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeries();
});

final seriesInfoProvider =
    FutureProvider.family<Series, String>((ref, seriesId) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeriesInfo(seriesId);
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

/// Cache partagé du guide EPG brut, avec expiration, pour éviter de
/// re-télécharger l'intégralité du XMLTV à chaque changement de chaîne.
class EPGDataCache {
  EPGDataCache();

  static const _ttl = Duration(minutes: 30);

  List<EPGProgram>? _all;
  DateTime? _fetchedAt;

  bool get isFresh {
    final fetched = _fetchedAt;
    return _all != null &&
        fetched != null &&
        DateTime.now().difference(fetched) < _ttl;
  }

  Future<List<EPGProgram>> loadFull(ApiService api) async {
    if (isFresh) return _all!;
    final programs = await api.fetchEpg();
    _all = programs;
    _fetchedAt = DateTime.now();
    return programs;
  }

  void invalidate() {
    _all = null;
    _fetchedAt = null;
  }
}

final epgDataCacheProvider = Provider<EPGDataCache>((ref) => EPGDataCache());

/// EPG d'une chaîne (par son `epg_channel_id`), chargé paresseusement puis
/// mis en cache avec une expiration. Renvoie une liste vide si la chaîne
/// n'a pas d'identifiant EPG ou aucun programme à venir.
final channelEpgProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, epgChannelId) async {
    if (epgChannelId.isEmpty) return const <EPGProgram>[];
    final api = ref.watch(apiServiceProvider);
    final cache = ref.watch(epgDataCacheProvider);
    final all = await cache.loadFull(api);
    final now = DateTime.now();
    return all
        .where((p) => p.channelId == epgChannelId && p.end.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  },
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

final aiRecommendationsProvider = FutureProvider.autoDispose
    .family<List<AIRecommendation>, String>((ref, profileId) async {
  final aiService = ref.watch(aiServiceProvider);
  final profile = ref.watch(currentProfileProvider);
  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];

  if (profile == null || profile.id != profileId) {
    throw const StreamAiException(
        'Aucun profil sélectionné pour les recommandations.',);
  }

  return aiService.getRecommendations(profile, movies);
});

class StreamAiException implements Exception {
  const StreamAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Horodatage de la dernière mise à jour des flux (UTC), durabilisé afin
/// d'afficher « Dernière mise à jour : … » dans la barre supérieure.
final lastRefreshTimestampProvider = StateProvider<DateTime?>((ref) => null);

Future<void> persistLastRefresh(DateTime timestamp) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'orbit_last_refresh',
      timestamp.toIso8601String(),
    );
  } catch (_) {
    // Non bloquant.
  }
}

Future<DateTime?> loadLastRefresh() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('orbit_last_refresh');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  } catch (_) {
    return null;
  }
}
