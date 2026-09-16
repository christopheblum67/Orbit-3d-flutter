/// Types de données partagés de la synchronisation cloud (S2).
///
/// Un "scope" correspond à un type de données local : favoris, épisodes vus,
/// récemment regardés. Chaque scope est synchronisé indépendamment par profil.
enum CloudSyncScope { favorites, watched, recents }

/// Une entrée du snapshot cloud : le JSON brut de l'objet métier + l'horodatage
/// de sa dernière modification (source du Last-Write-Wins par entrée).
class CloudSyncEntry {
  const CloudSyncEntry({required this.json, required this.updatedAt});

  final String json;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'json': json,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory CloudSyncEntry.fromJson(Map<String, dynamic> json) {
    return CloudSyncEntry(
      json: (json['json'] ?? '').toString(),
      updatedAt: DateTime.tryParse('${json['updatedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Snapshot versionné d'un scope pour un profil : c'est le document échangé
/// avec le cloud (et mémorisé localement comme "miroir" pour reconstruire
/// les horodatages locaux).
class CloudSyncSnapshot {
  const CloudSyncSnapshot({
    required this.scope,
    required this.profileId,
    required this.entries,
    required this.updatedAt,
    this.version = 0,
  });

  final CloudSyncScope scope;
  final String profileId;

  /// Clé canonique -> entrée (JSON + horodatage).
  final Map<String, CloudSyncEntry> entries;

  /// Horodatage global du snapshot (écriture la plus récente).
  final DateTime updatedAt;

  /// Numéro de version monotone : incrémenté à chaque poussée.
  final int version;

  bool get isEmpty => entries.isEmpty;

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        'profileId': profileId,
        'version': version,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'entries': {
          for (final e in entries.entries) e.key: e.value.toJson(),
        },
      };

  factory CloudSyncSnapshot.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    Map<String, CloudSyncEntry> entries = {};
    if (rawEntries is Map) {
      entries = {
        for (final e in rawEntries.entries)
          if (e.value is Map)
            e.key.toString(): CloudSyncEntry.fromJson(
              Map<String, dynamic>.from(e.value as Map),
            ),
      };
    }
    return CloudSyncSnapshot(
      scope: CloudSyncScope.values.asNameMap()[json['scope']] ??
          CloudSyncScope.favorites,
      profileId: (json['profileId'] ?? '').toString(),
      entries: entries,
      updatedAt: DateTime.tryParse('${json['updatedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  /// Comparaison de contenu strict (scope + profil + entrées JSON).
  bool sameContentAs(CloudSyncSnapshot? other) {
    if (other == null) return false;
    if (other.scope != scope || other.profileId != profileId) return false;
    if (other.entries.length != entries.length) return false;
    for (final e in entries.entries) {
      final o = other.entries[e.key];
      if (o == null || o.json != e.value.json) return false;
    }
    return true;
  }
}