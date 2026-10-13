import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/models/movie.dart';

class Series {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final int year;
  final String genre;
  final String director;
  final double rating;
  final String pegi;
  final List<Episode> episodes;
  final String categoryId;

  // Date d'ajout (Xtream: `added` en secondes Unix)
  final DateTime? addedDate;

  Series({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.year,
    required this.genre,
    required this.director,
    required this.rating,
    required this.pegi,
    required this.episodes,
    this.categoryId = '',
    this.addedDate,
  });

  bool get isNew {
    if (addedDate == null) return false;
    final now = DateTime.now();
    final diff = now.difference(addedDate!);
    return diff.inDays <= 30;
  }

  /// Copie avec le genre remplacé, sans reconstruire toute la fiche.
  ///
  /// Utilisé par l'alignement matchmaking : on réinjecte le vrai genre TMDB
  /// (« Horreur, Mystère, … ») résolu à la place du nom de catégorie Xtream,
  /// exactement comme le fait déjà `Movie.copyWith` côté films.
  Series withGenre(String newGenre) => Series(
        id: id,
        title: title,
        description: description,
        coverUrl: coverUrl,
        year: year,
        genre: newGenre,
        director: director,
        rating: rating,
        pegi: pegi,
        episodes: episodes,
        categoryId: categoryId,
        addedDate: addedDate,
      );

  factory Series.fromMap(Map<String, dynamic> map) {
    // Textes du panel décodés une fois pour toutes (cf. PanelText) :
    map = PanelText.decodeMap(map);
    final rawRating = map['rating'];
    final parsedRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse('$rawRating') ?? 0;
    var parsedYear = 0;
    final rawYear = map['year'] ?? map['releaseDate'] ?? map['air_date'];
    if (rawYear != null) {
      final yearStr = '$rawYear';
      final digits = yearStr.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) {
        parsedYear = int.tryParse(digits.substring(0, 4)) ?? 0;
      }
    }
    DateTime? parseAdded(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000,
              isUtc: true,);
        }
      }
      return null;
    }

    return Series(
      id: map['series_id']?.toString() ?? map['id']?.toString() ?? '',
      title: map['name']?.toString() ?? map['title']?.toString() ?? '',
      description: firstNonEmpty([
        map['plot'],
        map['overview'],
        map['description'],
        map['synopsis'],
      ]),
      coverUrl: firstNonEmpty([
        map['cover'],
        map['poster'],
        map['backdrop_path'],
        map['stream_icon'],
      ]),
      year: parsedYear,
      genre: _joined(map['genre']),
      director: _joined(map['director']),
      rating: parsedRating,
      pegi: firstNonEmpty([
        map['pegi'],
        map['age'],
        map['mpaa'],
        map['contentRating'],
        map['us_certification'],
      ]),
      episodes: parseEpisodes(map['episodes']),
      categoryId: map['category_id']?.toString() ?? '',
      addedDate: parseAdded(map['added']),
    );
  }

  /// `get_series` ne renvoie pas `episodes` (seulement `get_series_info`), et
  /// certains panels renvoient un type inattendu. On ne fait pas echouer la
  /// serie entiere pour une liste d'episodes illisible.
  static List<Episode> parseEpisodes(dynamic raw) {
    if (raw is! List) return <Episode>[];
    final out = <Episode>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(Episode.fromMap(Map<String, dynamic>.from(e)));
        } catch (_) {
          // episode invalide ignore
        }
      }
    }
    return out;
  }

  static String _joined(Object? value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .where((e) => e != null && '$e'.trim().isNotEmpty)
          .map((e) => '$e')
          .join(', ');
    }
    return '$value';
  }

  String? get pegiLabel => ageBadgeLabel(pegi);
}

class Episode {
  final String id;
  final String title;
  final int season;
  final int episodeNumber;
  final String _streamId;

  Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNumber,
    String? streamId,
    String? streamUrl,
  }) : _streamId = streamUrl ?? streamId ?? '';

  factory Episode.fromMap(Map<String, dynamic> map) {
    // Textes du panel décodés une fois pour toutes (cf. PanelText).
    map = PanelText.decodeMap(map);
    final rawSeason = map['season'];
    final rawEp = map['episode'] ?? map['episode_num'];
    return Episode(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      season: int.tryParse('$rawSeason') ?? 0,
      episodeNumber: int.tryParse('$rawEp') ?? 0,
      streamId: map['url']?.toString() ?? '',
    );
  }

  String get streamUrl {
    final ref = _streamId;
    if (ref.isEmpty) return '';
    // URL déjà complète (M3U, timeshift) : on ne la reconstruit pas.
    if (ref.startsWith('http')) return ref;
    return buildStreamUrlGlobal(
      streamId: ref,
      type: 'series',
    ) ?? '';
  }

  /// Identifiant de flux BRUT de l'épisode, tel que le panel le publie.
  ///
  /// C'est cet identifiant, et non [streamUrl], qu'attend la découverte de
  /// sous-titres d'une série : la convention de nommage des pistes référence le
  /// stream id de l'épisode, et `series_id` ne suffit pas. Sans lui, aucune
  /// piste n'est proposée — c'est ce qui se produisait : le champ `url` de ce
  /// panel est une URL complète, donc l'identifiant était invisible et la
  /// découverte ne synthétisait rien.
  ///
  /// Deux formes sont acceptées : l'identifiant nu (`12345`), et une URL
  /// complète, dont on extrait le dernier segment en retirant l'extension
  /// (`…/series/user/pass/12345.mkv` → `12345`). C'est ce que fait le panel
  /// lui-même pour construire l'URL d'une piste.
  ///
  /// Si aucun identifiant n'est identifiable, on renvoie la chaîne vide : la
  /// découverte ne propose alors RIEN plutôt qu'une piste qui pointerait vers
  /// un autre média.
  String get streamId {
    final ref = _streamId.trim();
    if (ref.isEmpty) return '';
    if (!ref.startsWith('http')) return ref;

    final uri = Uri.tryParse(ref);
    if (uri == null) return '';

    // Un identifiant passé en paramètre d'URL prime sur le chemin.
    for (final key in const ['stream_id', 'stream', 'id']) {
      final value = uri.queryParameters[key];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '';
    final last = segments.last;
    final dot = last.lastIndexOf('.');
    // On ne retire l'extension que si elle ressemble à un format de média :
    // un point fait partie de certains identifiants.
    if (dot > 0) {
      final ext = last.substring(dot + 1).toLowerCase();
      const mediaExtensions = {
        'mkv', 'mp4', 'avi', 'ts', 'm3u8', 'mpg', 'mpeg', 'flv', 'mov', 'wmv',
      };
      if (mediaExtensions.contains(ext)) return last.substring(0, dot);
    }
    return last;
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);
}
