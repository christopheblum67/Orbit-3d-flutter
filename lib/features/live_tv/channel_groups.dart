import 'package:orbit_3d_flutter/models/channel.dart';

class ChannelGroup {
  ChannelGroup({
    required this.name,
    required this.channels,
  });

  final String name;
  final List<Channel> channels;

  int get minNum => channels.isEmpty ? 0 : channels.first.orderNum;
}

List<ChannelGroup> buildLiveChannelGroups(List<Channel> channels) {
  if (channels.isEmpty) return const [];
  final buckets = <String, List<Channel>>{};
  for (final channel in channels) {
    buckets.putIfAbsent(channel.groupLabel, () => <Channel>[]).add(channel);
  }
  final groups = buckets.entries.map((e) {
    final sorted = [...e.value]..sort(_compareChannels);
    return ChannelGroup(name: e.key, channels: sorted);
  }).toList();
  groups.sort((a, b) {
    if (a.name.isEmpty != b.name.isEmpty) {
      return a.name.isEmpty ? 1 : -1;
    }
    final byMin = a.minNum.compareTo(b.minNum);
    if (byMin != 0) return byMin;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return groups;
}

int _compareChannels(Channel a, Channel b) {
  final byNum = a.orderNum.compareTo(b.orderNum);
  if (byNum != 0) return byNum;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
