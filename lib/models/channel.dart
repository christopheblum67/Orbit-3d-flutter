import '../services/stream_helpers.dart' as stream_helpers;

class Channel {
  final String id;
  final String name;
  final String logoUrl;
  final String streamUrl;
  final String group;
  final String epgChannelId;

  Channel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.streamUrl,
    required this.group,
    this.epgChannelId = '',
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      logoUrl: map['logo'] ?? '',
      streamUrl: map['url'] ?? '',
      group: map['group'] ?? '',
      epgChannelId: map['epg_channel_id'] ?? '',
    );
  }

  Channel copyWith({String? streamUrl}) {
    return Channel(
      id: id,
      name: name,
      logoUrl: logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      group: group,
      epgChannelId: epgChannelId,
    );
  }

  String requireStreamUrl() => stream_helpers.requireStreamUrl(streamUrl, label: name);
}
