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
}
