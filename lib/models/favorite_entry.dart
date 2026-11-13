/// Types de contenus favorisables (Live, VOD, Séries, Replay).
enum ContentType {
  live,
  vod,
  series,
  replay;

  String get label => switch (this) {
        ContentType.live => 'Live',
        ContentType.vod => 'VOD',
        ContentType.series => 'Séries',
        ContentType.replay => 'Replay',
      };

  static ContentType fromString(String? value) {
    return ContentType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ContentType.live,
    );
  }
}

/// Entrée de favori persistée : suffisante pour afficher et ouvrir le contenu
/// même si le catalogue n'est pas (encore) chargé.
class FavoriteEntry {
  const FavoriteEntry({
    required this.type,
    required this.id,
    required this.title,
    this.profileId = '',
    this.subscriptionId = '',
    this.posterUrl = '',
    this.subtitle = '',
    this.streamUrl = '',
  });

  final ContentType type;
  final String id;
  final String title;
  final String profileId;
  final String subscriptionId;
  final String posterUrl;
  final String subtitle;
  final String streamUrl;

  String get profileKey =>
      profileId.isEmpty ? '${type.name}:$id' : '$profileId:${type.name}:$id';

  String get key => subscriptionId.isEmpty
      ? profileKey
      : '$profileId:subscription:${Uri.encodeComponent(subscriptionId)}:${type.name}:$id';

  FavoriteEntry forSubscription(String subscriptionId) => FavoriteEntry(
        type: type,
        id: id,
        title: title,
        profileId: profileId,
        subscriptionId: subscriptionId,
        posterUrl: posterUrl,
        subtitle: subtitle,
        streamUrl: streamUrl,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'title': title,
        'profileId': profileId,
        'subscriptionId': subscriptionId,
        'posterUrl': posterUrl,
        'subtitle': subtitle,
        'streamUrl': streamUrl,
      };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    final type = ContentType.fromString(json['type'] as String?);
    return FavoriteEntry(
      type: type,
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      profileId: (json['profileId'] ?? '').toString(),
      subscriptionId: (json['subscriptionId'] ?? '').toString(),
      posterUrl: (json['posterUrl'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      streamUrl: (json['streamUrl'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteEntry &&
        other.key == key &&
        other.title == title &&
        other.posterUrl == posterUrl &&
        other.subtitle == subtitle &&
        other.streamUrl == streamUrl;
  }

  @override
  int get hashCode => Object.hash(key, title, posterUrl, subtitle, streamUrl);
}
