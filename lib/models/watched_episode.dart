/// Entrée « épisode déjà vu » : un épisode de série marqué comme regardé par
/// un profil. Identifié par sa clé canonique (profil + série + saison/épisode).
class WatchedEpisodeEntry {
  const WatchedEpisodeEntry({
    required this.profileId,
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeId,
    required this.episodeTitle,
    required this.season,
    required this.episodeNumber,
    required this.watchedAt,
  });

  final String profileId;
  final String seriesId;
  final String seriesTitle;
  final String episodeId;
  final String episodeTitle;
  final int season;
  final int episodeNumber;
  final DateTime watchedAt;

  /// Clé canonique : `"<profileId>:<seriesId>:S<saison>E<épisode>"`.
  /// Repli sur l'id d'épisode si la numérotation est absente (source dégradée).
  String get key => keyFor(
        profileId: profileId,
        seriesId: seriesId,
        season: season,
        episodeNumber: episodeNumber,
        episodeId: episodeId,
      );

  /// Construction canonique de la clé (partagée UI/service/notifier).
  static String keyFor({
    required String profileId,
    required String seriesId,
    required int season,
    required int episodeNumber,
    String episodeId = '',
  }) {
    if (season > 0 && episodeNumber > 0) {
      return '$profileId:$seriesId:S${season}E$episodeNumber';
    }
    return '$profileId:$seriesId:E$episodeId';
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'seriesId': seriesId,
        'seriesTitle': seriesTitle,
        'episodeId': episodeId,
        'episodeTitle': episodeTitle,
        'season': season,
        'episodeNumber': episodeNumber,
        'watchedAt': watchedAt.toIso8601String(),
      };

  factory WatchedEpisodeEntry.fromJson(Map<String, dynamic> json) {
    return WatchedEpisodeEntry(
      profileId: (json['profileId'] ?? '').toString(),
      seriesId: (json['seriesId'] ?? '').toString(),
      seriesTitle: (json['seriesTitle'] ?? '').toString(),
      episodeId: (json['episodeId'] ?? '').toString(),
      episodeTitle: (json['episodeTitle'] ?? '').toString(),
      season: (json['season'] as num?)?.toInt() ?? 0,
      episodeNumber: (json['episodeNumber'] as num?)?.toInt() ?? 0,
      watchedAt: DateTime.tryParse('${json['watchedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WatchedEpisodeEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;
}