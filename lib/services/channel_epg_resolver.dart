import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/epg_fallback_budget.dart';
import 'package:orbit_3d_flutter/services/short_epg_service.dart';

/// Dépendances capturées avant le premier await, uniquement en cas de cache raté.
class ChannelEpgSources {
  const ChannelEpgSources({
    required this.channels,
    required this.budget,
    required this.loadFull,
    required this.programsForChannel,
    required this.fetchShort,
  });

  final List<Channel> channels;
  final EpgFallbackBudget budget;
  final Future<void> Function() loadFull;
  final List<EPGProgram> Function(String) programsForChannel;
  final Future<List<EPGProgram>> Function(Channel) fetchShort;
}

List<EPGProgram> upcomingEpgPrograms(List<EPGProgram> programs, DateTime now) {
  return programs.where((p) => p.end.isAfter(now)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

/// Résout cache court, XMLTV global puis repli réseau borné, dans cet ordre.
class ChannelEpgResolver {
  const ChannelEpgResolver();

  Future<List<EPGProgram>> resolve({
    required String channelId,
    required bool includePast,
    required bool allowNetworkFallback,
    required ShortEpgCache cache,
    required ChannelEpgSources Function() prepareSources,
    DateTime? now,
  }) async {
    if (channelId.isEmpty) return const <EPGProgram>[];
    final current = now ?? DateTime.now();
    List<EPGProgram> keep(List<EPGProgram> programs) => includePast
        ? (programs.toList()..sort((a, b) => a.start.compareTo(b.start)))
        : upcomingEpgPrograms(programs, current);

    final colon = channelId.indexOf(':');
    final bare = colon > 0 ? channelId.substring(colon + 1) : '';
    final cached =
        cache.get(channelId) ?? (bare.isNotEmpty ? cache.get(bare) : null);
    if (cached != null) {
      final result = keep(cached);
      if (result.isNotEmpty) return result;
    }

    final sources = prepareSources();
    Channel? channel;
    for (final candidate in sources.channels) {
      if (candidate.id == channelId ||
          candidate.epgChannelIds.contains(channelId)) {
        channel = candidate;
        break;
      }
    }
    await sources.loadFull();

    final candidates = channel == null
        ? <String>[channelId]
        : <String>[
            ...channel.epgChannelIds,
            if (channel.id.isNotEmpty) channel.id,
          ];
    for (final candidate in candidates) {
      final result = keep(sources.programsForChannel(candidate));
      if (result.isNotEmpty) return result;
    }

    if (!allowNetworkFallback ||
        channel == null ||
        !sources.budget.tryConsume()) {
      return const <EPGProgram>[];
    }
    final target = channel;
    final fetched = await safeAsync<List<EPGProgram>>(
      () => sources.fetchShort(target),
      context: 'channelEpgProvider',
    );
    final programs = fetched.valueOrNull;
    if (programs != null && programs.isNotEmpty) {
      cache.put(target.id, programs);
      final result = keep(programs);
      if (result.isNotEmpty) return result;
    }
    return const <EPGProgram>[];
  }
}
