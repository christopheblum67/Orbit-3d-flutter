import 'package:orbit_3d_flutter/models/favorite_entry.dart';

/// Entrée « récemment regardé » : suffisante pour afficher et rouvrir le
/// contenu (mêmes champs qu'un favori) + l'horodatage de la dernière lecture.
class RecentEntry {
  const RecentEntry({
    required this.type,
    required this.id,
    required this.title,
    this.profileId = '',
    this.posterUrl = '',
    this.subtitle = '',
    this.streamUrl = '',
    required this.watchedAt,
  });

  final ContentType type;
  final String id;
  final String title;
  final String profileId;
  final String posterUrl;
  final String subtitle;
  final String streamUrl;
  final DateTime watchedAt;

  String get key => profileId.isEmpty
      ? '${type.name}:$id'
      : '$profileId:${type.name}:$id';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'title': title,
        'profileId': profileId,
        'posterUrl': posterUrl,
        'subtitle': subtitle,
        'streamUrl': streamUrl,
        'watchedAt': watchedAt.toIso8601String(),
      };

  factory RecentEntry.fromJson(Map<String, dynamic> json) {
    final type = ContentType.fromString(json['type'] as String?);
    return RecentEntry(
      type: type,
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      profileId: (json['profileId'] ?? '').toString(),
      posterUrl: (json['posterUrl'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      streamUrl: (json['streamUrl'] ?? '').toString(),
      watchedAt: DateTime.tryParse('${json['watchedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecentEntry && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
