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
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
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
    );
  }

  static int _parseNumValue(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '') ?? 0;
  }

  Channel copyWith({String? streamUrl}) {
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
