import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

class Channel {
  final String id;
  final String name;
  final String logoUrl;
  final String streamUrl;
  final String group;
  final String categoryId;
  final String epgChannelId;
  final int orderNum;
  final double rating;

  /// La chaîne expose un replay/catchup (tv_archive, radio_tv=dvr,
  /// timeshift) : ses programmes passés sont relisibles.
  final bool supportsReplay;
  final Duration timeshift;

  Channel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.streamUrl,
    required this.group,
    this.categoryId = '',
    this.epgChannelId = '',
    this.orderNum = 0,
    this.rating = 0,
    this.supportsReplay = false,
    this.timeshift = Duration.zero,
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
    final radioTv = map['radio_tv']?.toString().toLowerCase() ?? '';
    final tvArchive = map['tv_archive']?.toString().toLowerCase();
    final hasArchive = tvArchive == '1' ||
        tvArchive == 'true' ||
        tvArchive == 'yes';
    final timeshiftSeconds =
        int.tryParse('${map['timeshift_seconds'] ?? '0'}') ?? 0;
    return Channel(
      id: firstNonEmpty([map['stream_id'], map['id']]),
      name: map['name'] ?? '',
      logoUrl: firstNonEmpty([map['stream_icon'], map['logo']]),
      streamUrl: map['url'] ?? '',
      group: firstNonEmpty([map['category_name'], map['group']]),
      categoryId: map['category_id']?.toString() ?? '',
      epgChannelId: map['epg_channel_id']?.toString() ?? '',
      orderNum: _parseNumValue(map['num']),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      supportsReplay:
          radioTv == 'dvr' || hasArchive || timeshiftSeconds > 0,
      timeshift: Duration(seconds: timeshiftSeconds),
    );
  }

  static int _parseNumValue(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '') ?? 0;
  }

  Channel copyWith({
    String? streamUrl,
    bool? supportsReplay,
    Duration? timeshift,
  }) {
    return Channel(
      id: id,
      name: name,
      logoUrl: logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      group: group,
      categoryId: categoryId,
      epgChannelId: epgChannelId,
      orderNum: orderNum,
      rating: rating,
      supportsReplay: supportsReplay ?? this.supportsReplay,
      timeshift: timeshift ?? this.timeshift,
    );
  }

  String get groupLabel {
    final raw = group.trim();
    if (raw.isEmpty) return '';
    final parts = raw.split(RegExp(r'[|;]'));
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return raw;
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: name);
}
