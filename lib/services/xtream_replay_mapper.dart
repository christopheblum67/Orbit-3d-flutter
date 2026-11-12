import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/services/xtream_epg_parser.dart';

/// Transforme les entrées EPG Xtream en replays, sans effectuer de requête.
class XtreamReplayMapper {
  const XtreamReplayMapper();

  List<ReplayItem> build({
    required Iterable<Map> entries,
    required Channel channel,
    required DateTime now,
    required Duration? window,
    required bool fullGuide,
    required String Function(int startEpoch, int endEpoch) buildUrl,
    required String Function(DateTime, DateTime) formatTime,
  }) {
    final items = <ReplayItem>[];
    final seen = <int>{};
    for (final entry in entries) {
      final map = Map<String, dynamic>.from(entry);
      final start = XtreamEpgParser.parseDate(
        map['start_timestamp'] ?? map['start'],
      );
      final end = XtreamEpgParser.parseDate(
        map['stop_timestamp'] ?? (fullGuide ? map['stop'] : null) ?? map['end'],
      );
      if (start == null || end == null || !end.isBefore(now)) continue;
      if (window != null && now.difference(start) > window) continue;
      final title = PanelText.decode(map['title']?.toString().trim() ?? '');
      if (title.isEmpty) continue;
      final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
      if (fullGuide && !seen.add(startEpoch)) continue;
      final endEpoch = end.millisecondsSinceEpoch ~/ 1000;
      items.add(
        ReplayItem(
          id: '${channel.id}_$startEpoch',
          title: title,
          streamUrl: buildUrl(startEpoch, endEpoch),
          startTime: formatTime(start, now),
          endTime: formatTime(end, now),
          categoryId: channel.groupLabel,
          channelId: channel.id,
          channelName: channel.name,
          startDate: start,
          description: PanelText.decode(
            _firstString(map, const ['description', 'plot', 'desc', 'summary']),
          ),
          host: PanelText.decode(
            _firstString(
              map,
              const ['name', 'presenter', 'host', 'director', 'actor'],
            ),
          ),
          startAt: start,
          endAt: end,
        ),
      );
    }
    if (fullGuide) {
      items.sort(
        (a, b) => (b.startAt ?? b.startDate ?? DateTime(1900))
            .compareTo(a.startAt ?? a.startDate ?? DateTime(1900)),
      );
    }
    return items;
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final raw = map[key];
      if (raw == null) continue;
      var value = raw.toString().trim();
      if (value.isEmpty) continue;
      value = value
          .replaceAll('&apos;', "'")
          .replaceAll('&#39;', "'")
          .replaceAll('&quot;', '"')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&');
      if (value.contains('<')) {
        value = value
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim();
      }
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}
