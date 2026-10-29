import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';

/// Transforme les chaînes M3U « films » en objets [Movie], avec extraction
/// automatique de l'année de sortie depuis le titre (ex : `Avatar 2 (2022)`).
class M3uMovieTransformer {
  M3uMovieTransformer._();

  /// Année entre 1900 et 2099 dans le titre.
  static final RegExp _yearRegex = RegExp(r'\b(19\d{2}|20\d{2})\b');

  /// Convertit une liste plate de chaînes M3U films en objets [Movie].
  static List<Movie> transformChannelsToMovies(List<Channel> channels) {
    return channels.map((channel) {
      var rawTitle = channel.name.trim();
      int extractedYear = DateTime.now().year;

      final match = _yearRegex.firstMatch(rawTitle);
      if (match != null) {
        extractedYear = int.tryParse(match.group(1)!) ?? extractedYear;
        // Retire l'année (et les parenthèses qui l'enveloppent) du titre.
        rawTitle = rawTitle.replaceAll(RegExp(r'[\(\[\-\s]+$'), '').trim();
      }

      return Movie(
        id: channel.id,
        title: rawTitle,
        description: 'Film importé via M3U (Groupe : ${channel.group})',
        posterUrl: channel.logoUrl,
        year: extractedYear,
        genre: channel.group.isNotEmpty ? channel.group : 'Films M3U',
        director: '',
        rating: 0.0,
        pegi: '',
        streamId: channel.streamUrl,
        containerExtension: 'mp4',
        categoryId: channel.categoryId,
      );
    }).toList();
  }
}
