import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/models/movie.dart';

/// Version allégée de [Movie] pour les listes/grilles.
///
/// Ne contient que les champs nécessaires à l'affichage en grille/liste.
/// La description, le casting, l'équipe technique et l'URL de stream
/// sont chargés à la demande via [MovieRepository].
class MovieCompact {
  const MovieCompact({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.rating,
    required this.categoryId,
    this.pegi,
    this.addedDate,
  });

  final String id;
  final String title;
  final String posterUrl;
  final int year;
  final String genre;
  final double rating;
  final String categoryId;
  final String? pegi;
  final DateTime? addedDate;

  /// Crée un [MovieCompact] à partir d'un [Movie] complet.
  factory MovieCompact.fromMovie(Movie movie) {
    return MovieCompact(
      id: movie.id,
      title: movie.title,
      posterUrl: movie.posterUrl,
      year: movie.year,
      genre: movie.genre,
      rating: movie.rating,
      categoryId: movie.categoryId,
      pegi: movie.pegi,
      addedDate: movie.addedDate,
    );
  }

  /// Crée un [MovieCompact] à partir d'un JSON (API Xtream).
  factory MovieCompact.fromJson(Map<String, dynamic> json) {
    return MovieCompact(
      id: json['id']?.toString() ?? json['stream_id']?.toString() ?? '',
      title: json['name']?.toString() ?? '',
      posterUrl: json['stream_icon']?.toString() ?? json['poster']?.toString() ?? '',
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

  /// Indique si le film est considéré comme "nouveau" (ajouté il y a moins de 30 jours).
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
      other is MovieCompact && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MovieCompact(id: $id, title: $title)';
}

