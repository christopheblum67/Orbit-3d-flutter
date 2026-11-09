import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';

class ReplaySelection {
  const ReplaySelection._();

  static List<ReplayItem> merge(
    List<ReplayItem> fromEpg,
    List<ReplayItem> fromShortEpg,
  ) {
    final seen = <String>{};
    final merged = <ReplayItem>[];
    for (final r in [...fromEpg, ...fromShortEpg]) {
      final start = r.startAt?.millisecondsSinceEpoch ??
          r.startDate?.millisecondsSinceEpoch ??
          0;
      if (seen.add('${r.channelId}_$start')) merged.add(r);
    }
    return merged;
  }

  static List<Channel> probeSet(
    List<Channel> channels,
    List<Channel> flagged,
  ) {
    const budget = 40;
    const perGroup = 3;
    if (channels.isEmpty) return const <Channel>[];

    final flaggedIds = flagged.map((c) => c.id).toSet();
    final candidates = <Channel>[];
    final seen = <String>{};
    final takenByGroup = <String, int>{};

    void fillRoundRobin(List<Channel> source) {
      final byGroup = <String, List<Channel>>{};
      for (final c in source) {
        final group = c.groupLabel.isNotEmpty ? c.groupLabel : '(sans groupe)';
        byGroup.putIfAbsent(group, () => []).add(c);
      }
      final groupNames = byGroup.keys.toList();
      var allExhausted = false;
      while (candidates.length < budget && !allExhausted) {
        allExhausted = true;
        for (final group in groupNames) {
          if (candidates.length >= budget) break;
          final list = byGroup[group]!;
          final taken = takenByGroup[group] ?? 0;
          if (taken >= perGroup) continue;
          Channel? next;
          for (final c in list) {
            if (!seen.contains(c.id)) {
              next = c;
              break;
            }
          }
          if (next == null) continue;
          seen.add(next.id);
          candidates.add(next);
          takenByGroup[group] = taken + 1;
          allExhausted = false;
        }
      }
    }

    fillRoundRobin(flagged);
    if (candidates.length >= budget) return candidates;
    fillRoundRobin(channels.where((c) => !flaggedIds.contains(c.id)).toList());
    return candidates;
  }
}
