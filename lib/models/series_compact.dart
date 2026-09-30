import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/models/series.dart';

/// Version allégée de [Series] pour les listes/grilles.
///
/// Ne contient que les champs nécessaires à l'affichage en grille/liste.
/// Les épisodes, la description détaillée et l'URL de stream sont
/// chargés à la demande via [SeriesRepository].
class SeriesCompact {
  const SeriesCompact({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.year,
    required this.genre,
    required this.rating,
    required this.categoryId,
    this.pegi,
    this.addedDate,
  });

  final String id;
  final String title;
  final String coverUrl;
  final int year;
  final String genre;
  final double rating;
  final String categoryId;
  final String? pegi;
  final DateTime? addedDate;

  /// Crée un [SeriesCompact] à partir d'une [Series] complète.
  factory SeriesCompact.fromSeries(Series series) {
    return SeriesCompact(
      id: series.id,
      title: series.title,
      coverUrl: series.coverUrl,
      year: series.year,
      genre: series.genre,
      rating: series.rating,
      categoryId: series.categoryId,
      pegi: series.pegi,
      addedDate: series.addedDate,
    );
  }

  /// Crée un [SeriesCompact] à partir d'un JSON (API Xtream).
  factory SeriesCompact.fromJson(Map<String, dynamic> json) {
    return SeriesCompact(
      id: json['series_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['name']?.toString() ?? '',
      coverUrl: json['cover']?.toString() ?? json['poster']?.toString() ?? '',
      year: int.tryParse(json['year']?.toString() ?? '') ?? 0,
      genre: json['genre']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
      pegi: json['pegi']?.toString() ?? json['age']?.toString(),
      addedDate: json['added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(json['added'].toString()) * 1000)
          : null,
    );
  }

  /// Indique si la série est considérée comme "nouvelle" (ajoutée il y a moins de 30 jours).
  bool get isNew {
    if (addedDate == null) return false;
    final now = DateTime.now();
    final diff = now.difference(addedDate!);
    return diff.inDays <= 30;
  }

  /// Label PEGI formaté pour l'affichage.
  String? get pegiLabel => pegi != null ? ageBadgeLabel(pegi!) : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesCompact && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SeriesCompact(id: $id, title: $title)';
}

