import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/content_filter_provider.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/epg_providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/replay_cache.dart';

final ReplaysCache replaysCache = ReplaysCache();

/// Affichage depuis l'EPG global et le cache, sans attendre ni lancer la sonde.
/// La sonde séparée est bornée à 40 chaînes et deux workers par le service.
final replaysProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final filter = ref.watch(contentFilterProvider);
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider);
  final shortEpg =
      replaysCache.peek ?? replaysCache.stale ?? const <ReplayItem>[];

  final epgResult = await safeAsync<List<EPGProgram>>(
    () => ref.watch(epgProgramsProvider.future),
    context: 'replaysProvider.epg',
    fallbackValue: const <EPGProgram>[],
  );
  final channelsResult = await safeAsync<List<Channel>>(
    () => ref.watch(liveChannelsProvider.future),
    context: 'replaysProvider.channels',
    fallbackValue: const <Channel>[],
  );

  final fromEpg = await api.buildReplaysFromGlobalEpg(
    programs: epgResult.valueOrNull ?? const <EPGProgram>[],
    channels: channelsResult.valueOrNull ?? const <Channel>[],
  );
  final merged = ApiService.mergeReplays(fromEpg, shortEpg);
  if (merged.isEmpty) {
    LoggerService.instance.warning(
      'Replay vide court=${shortEpg.length} epg=${fromEpg.length}',
      tag: 'replay',
    );
  }
  return filter.visibleList(merged);
});

/// Sonde en arrière-plan, dédupliquée et conservée cinq minutes en cache.
/// L'écran invalide [replaysProvider] une fois la sonde terminée.
final replaysProbeProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider);
  return replaysCache.fetch(api.fetchReplays);
});

final channelReplaysCache = ChannelReplaysCache();

/// Charge uniquement la chaîne demandée ; le résultat est conservé en cache.
/// Le provider est autoDispose, et l'invalidation du cache empêche une
/// réponse de l'ancien abonnement de contaminer le nouveau.
final channelReplaysProvider = FutureProvider.autoDispose
    .family<List<ReplayItem>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider);
  final generation = channelReplaysCache.generation;
  final channels = await ref.watch(liveChannelsProvider.future);
  if (generation != channelReplaysCache.generation) {
    return const <ReplayItem>[];
  }
  final channel = channels.where((c) => c.id == id).firstOrNull;
  if (channel == null) return const <ReplayItem>[];

  final cached = channelReplaysCache.peek(id);
  if (cached != null) return cached;

  final items = await api.fetchChannelReplays(channel);
  channelReplaysCache.putIfCurrent(id, items, generation);
  return items;
});
