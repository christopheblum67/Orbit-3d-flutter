import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';

typedef ReplayUrlBuilder = String Function(
  Channel channel,
  int startEpoch,
  int endEpoch,
);

class GlobalEpgReplayService {
  const GlobalEpgReplayService();

  List<ReplayItem> build({
    required List<EPGProgram> programs,
    required List<Channel> channels,
    required DateTime now,
    required Duration? Function(Channel) archiveWindow,
    required ReplayUrlBuilder buildUrl,
    required String Function(DateTime, DateTime) formatTime,
  }) {
    final byEpgId = <String, Channel>{};
    for (final channel in channels) {
      if (!channel.supportsReplay) continue;
      for (final id in channel.epgChannelIds) {
        if (id.isNotEmpty) byEpgId[id] = channel;
      }
      if (channel.id.isNotEmpty) byEpgId[channel.id] = channel;
    }
    if (byEpgId.isEmpty) return const <ReplayItem>[];

    final items = <ReplayItem>[];
    final seen = <String>{};
    for (final program in programs) {
      final channel = byEpgId[program.channelId];
      if (channel == null) continue;
      if (!isReplayableProgram(
        program,
        now: now,
        channelSupportsReplay: true,
      )) {
        continue;
      }
      final window = archiveWindow(channel);
      if (window != null && now.difference(program.start) > window) continue;

      final startEpoch = program.start.millisecondsSinceEpoch ~/ 1000;
      final endEpoch = program.end.millisecondsSinceEpoch ~/ 1000;
      final key = '${channel.id}_$startEpoch';
      if (!seen.add(key)) continue;
      final title = program.title.trim();
      if (title.isEmpty) continue;
      items.add(ReplayItem(
        id: key,
        title: title,
        streamUrl: buildUrl(channel, startEpoch, endEpoch),
        startTime: formatTime(program.start, now),
        endTime: formatTime(program.end, now),
        categoryId: channel.groupLabel,
        channelId: channel.id,
        channelName: channel.name,
        startDate: program.start,
        description: program.description.trim(),
        startAt: program.start,
        endAt: program.end,
      ));
    }
    LoggerService.instance.info(
      'Replay EPG global: ${items.length} programme(s) rejouable(s) '
      'sur ${programs.length} entrées, ${byEpgId.length} chaîne(s) DVR',
    );
    return items;
  }
}
