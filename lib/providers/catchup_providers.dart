import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/short_epg_service.dart';

final catchUpEpgCacheProvider = Provider<ShortEpgCache>((ref) {
  ref.watch(activeSubscriptionProvider);
  final cache = ShortEpgCache();
  ref.onDispose(cache.clear);
  return cache;
});

/// Programmes terminés dans la fenêtre d'archive annoncée par la chaîne.
final channelCatchUpProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, channelId) async {
    ref.watch(activeSubscriptionProvider);
    if (channelId.isEmpty) return const <EPGProgram>[];
    final channels = await ref.watch(liveChannelsProvider.future);
    if (!ref.mounted) return const <EPGProgram>[];
    final channel = channels.where((c) => c.id == channelId).firstOrNull;
    if (channel == null) return const <EPGProgram>[];

    final cache = ref.watch(catchUpEpgCacheProvider);
    final api = ref.read(apiServiceProvider);
    var programs = cache.get(channelId);
    if (programs == null) {
      programs = await api.fetchChannelCatchUpPrograms(channel);
      if (!ref.mounted) return const <EPGProgram>[];
      if (programs.isEmpty) return const <EPGProgram>[];
      cache.put(channelId, programs);
    }
    return _pastPrograms(programs, ApiService.archiveWindow(channel));
  },
);

List<EPGProgram> _pastPrograms(List<EPGProgram> programs, Duration window) {
  final now = DateTime.now();
  final cutoff = now.subtract(window);
  return programs
      .where((p) => p.end.isBefore(now))
      .where((p) => !p.end.isBefore(cutoff))
      .toList()
    ..sort((a, b) => b.end.compareTo(a.end));
}
