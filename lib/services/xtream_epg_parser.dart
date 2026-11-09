import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Interprétation des horaires et du guide court fournis par un panel Xtream.
class XtreamEpgParser {
  const XtreamEpgParser();

  static DateTime? parseDate(Object? raw) {
    if (raw == null) return null;
    final trimmed = raw.toString().trim();
    if (trimmed.isEmpty) return null;
    final seconds = int.tryParse(trimmed);
    if (seconds != null && seconds > 0) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }

  List<EPGProgram> parseShortGuide(Object? data, Channel channel) {
    final list = data is List
        ? data
        : (data is Map
            ? (data['epg_listings'] as List? ?? const <dynamic>[])
            : const <dynamic>[]);
    final programs = <EPGProgram>[];
    for (final entry in list.whereType<Map>()) {
      final map = Map<String, dynamic>.from(entry);
      final start = parseDate(map['start_timestamp'] ?? map['start']);
      final end = parseDate(map['stop_timestamp'] ?? map['end']);
      if (start == null || end == null || !end.isAfter(start)) continue;
      final title = PanelText.decode(map['title']?.toString().trim() ?? '');
      if (title.isEmpty) continue;
      programs.add(
        EPGProgram(
          channelId: channel.primaryEpgChannelId.isNotEmpty
              ? channel.primaryEpgChannelId
              : channel.id,
          title: title,
          description: PanelText.decode(
            (map['description'] ?? map['plot'] ?? '').toString().trim(),
          ),
          start: start,
          end: end,
        ),
      );
    }
    return programs;
  }
}
