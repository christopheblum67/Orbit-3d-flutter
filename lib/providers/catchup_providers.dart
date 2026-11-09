import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/epg_providers.dart';

/// Programmes terminés dans la fenêtre d'archive annoncée par la chaîne.
final channelCatchUpProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, channelId) async {
    if (channelId.isEmpty) return const <EPGProgram>[];

    final channels = ref.read(liveChannelsProvider).value ?? const <Channel>[];
    final channel = channels.cast<Channel?>().firstWhere(
          (c) => c!.id == channelId,
          orElse: () => null,
        );
    if (channel == null) return const <EPGProgram>[];

    final archiveDays = channel.archiveDays > 0 ? channel.archiveDays : 7;
    final cache = ref.read(shortEpgCacheProvider);
    final cached = cache.get(channelId);
    if (cached != null) return _pastPrograms(cached, archiveDays);

    // Capturer les dépendances avant l'attente : le provider peut être détruit.
    final api = ref.read(apiServiceProvider);
    final result = await safeAsync<List<EPGProgram>>(
      () => api.fetchChannelEpgPrograms(channel),
      context: 'channelCatchUpProvider',
    );
    final programs = result.valueOrNull;
    if (programs == null || programs.isEmpty) return const <EPGProgram>[];

    cache.put(channelId, programs);
    return _pastPrograms(programs, archiveDays);
  },
);

List<EPGProgram> _pastPrograms(List<EPGProgram> programs, int archiveDays) {
  final now = DateTime.now();
  return programs
      .where((p) => p.end.isBefore(now))
      .where((p) => now.difference(p.end).inDays <= archiveDays)
      .toList()
    ..sort((a, b) => b.end.compareTo(a.end));
}
