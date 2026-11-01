import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/models/cast.dart';

/// Fonction globale pour construire les URLs de stream (configurée au démarrage).
typedef StreamUrlBuilder = String Function({
  required String streamId,
  String? containerExtension,
  String? type,
});

/// Constructeur d'URL de stream global (configuré par ApiService au bootstrap).
StreamUrlBuilder? _globalStreamUrlBuilder;

void setGlobalStreamUrlBuilder(StreamUrlBuilder builder) {
  _globalStreamUrlBuilder = builder;
}

/// Construit l'URL de stream via le builder global (public pour MovieDetail).
String? buildStreamUrlGlobal({
  required String streamId,
  String? containerExtension,
  String type = 'movie',
}) {
  return _globalStreamUrlBuilder?.call(
    streamId: streamId,
    containerExtension: containerExtension,
    type: type,
  );
}

class Movie {
  final String id;
  final String title;
  final String description;
  final String posterUrl;
  final int year;
  final String genre;
  final String director;
  final double rating;
  final String pegi;
  final String categoryId;

  // Composants minimaux pour construire l'URL à la demande
  final String _streamId;
  final String _containerExtension;

  /// Composant minimal pour reconstruire l'URL (exposé pour reconstruction).
  String get streamId => _streamId;

  /// Extension du conteneur (ex: mkv, mp4).
  String get containerExtension => _containerExtension;

  // Nouvelles données de casting
  final List<Actor> cast;
  final List<CrewMember> crew;

  // Champs enrichis propres à MovieDetail (légers, propagation depuis
  // get_vod_info / M3U). Ajoutés ici pour que [MovieDetail.fromMovie] les
  // intègre sans casser le catalogue existant.
  final List<String> keywords;
  final int runtime; // minutes
  final int budget; // USD
  final int revenue; // USD
  final List<String> productionCompanies;
  final String trailerUrl;
  final String backdropUrl;
  final int tmdbId;
  final String imdbId;

  // Date d'ajout (Xtream: `added` en secondes Unix)
  final DateTime? addedDate;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.director,
    required this.rating,
    required this.pegi,
    required String streamId,
    String containerExtension = '',
    this.categoryId = '',
    this.cast = const [],
    this.crew = const [],
    this.keywords = const <String>[],
    this.runtime = 0,
    this.budget = 0,
    this.revenue = 0,
    this.productionCompanies = const <String>[],
    this.trailerUrl = '',
    this.backdropUrl = '',
    this.tmdbId = 0,
    this.imdbId = '',
    this.addedDate,
  })  : _streamId = streamId,
        _containerExtension = containerExtension;

  /// URL de stream construite à la demande (lazy) via le builder global.
  /// Économise ~13 Mo RAM sur 99k films en ne stockant pas l'URL complète avec credentials.
  String get streamUrl {
    if (_streamId.isEmpty) return '';
    // URL déjà complète (M3U, timeshift) : on ne la reconstruit pas.
    if (_streamId.startsWith('http')) return _streamId;
    return buildStreamUrlGlobal(
      streamId: _streamId,
      containerExtension: _containerExtension.isNotEmpty ? _containerExtension : null,
      type: 'movie',
    ) ?? '';
  }

  /// Fiche minimale destinée à la navigation depuis un modèle compact : elle
  /// porte l'identifiant (donc l'URL de stream reconstruite à la demande) et
  /// laisse l'écran de détail charger le reste.
  factory Movie.fromStreamId(String streamId) => Movie(
        id: streamId,
        title: '',
        description: '',
        posterUrl: '',
        year: 0,
        genre: '',
        director: '',
        rating: 0,
        pegi: '',
        streamId: streamId,
      );

  bool get isNew {
    if (addedDate == null) return false;
    final now = DateTime.now();
    final diff = now.difference(addedDate!);
    return diff.inDays <= 30;
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    // Textes du panel décodés une fois pour toutes (cf. PanelText) :
    map = PanelText.decodeMap(map);
    // `cast` et `crew` ne sont pas presents sur `get_vod_streams` et certains
    // panels les renvoient en chaine ou avec des cles non-String : on ignore
    // silencieusement ce qui n'est pas exploitable plutot que de faire echouer
    // tout le catalogue.
    List<Actor> parseCast() {
      // `get_vod_streams` ne renvoie pas `cast`, mais certains panels l'ajoutent
      // en chaîne fusionnée : `Actor.listFromDynamic` gère les deux formats.
      return Actor.listFromDynamic(map['cast']);
    }

    List<CrewMember> parseCrew() {
      final raw = map['crew'];
      if (raw is! List) return <CrewMember>[];
      final out = <CrewMember>[];
      for (final e in raw) {
        if (e is Map) {
          try {
            out.add(CrewMember.fromMap(Map<String, dynamic>.from(e)));
          } catch (_) {
            // entree invalide ignoree
          }
        }
      }
      return out;
    }

    final castList = parseCast();
    final crewList = parseCrew();
    // `sort` exige une liste modifiable : `parseCast()` garantit une liste
    // growable (cf. `Actor.listFromDynamic`). On saute l'appel sous 2 éléments,
    // un tri n'y change rien — c'est le cas de 100 % des entrées de
    // `get_vod_streams`, qui ne portent ni cast ni crew.
    if (castList.length > 1) {
      castList.sort((a, b) => a.order.compareTo(b.order));
    }
    if (crewList.length > 1) {
      crewList.sort((a, b) {
        final deptCompare = a.department.compareTo(b.department);
        if (deptCompare != 0) return deptCompare;
        return a.order.compareTo(b.order);
      });
    }

    // Champs enrichis : keywords (chaine sparsee), runtime/budget/revenue
    // (chaines numeriques), productionCompanies (chaines ou listes).
    List<String> parseSimpleList(dynamic v) {
      if (v == null) return const <String>[];
      if (v is List) {
        return v
            .map((e) => e is Map ? (e['name'] ?? e['tag'] ?? '').toString() : e.toString())
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      if (v is String && v.trim().isNotEmpty) {
        // Chaine "a, b, c" ou "a|b" : on decoupe pour un vrai rendu par puce.
        final parts = v
            .split(RegExp(r'[,|]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return parts.isEmpty ? const <String>[] : parts;
      }
      return const <String>[];
    }

    final List<String> keywordsRaw = parseSimpleList(map['keywords']);
    final List<String> companiesRaw = parseSimpleList(map['production_companies']);
    final String trailerRaw = (map['trailer'] ?? map['trailer_url']) != null
        ? ((map['trailer'] ?? map['trailer_url']) as dynamic).toString().trim()
        : '';
    final dynamic backdropDyn = map['backdrop_path'] ?? map['backdrop'];
    final String backdropRaw = backdropDyn is List
        ? (backdropDyn.isNotEmpty ? backdropDyn.first.toString().trim() : '')
        : (backdropDyn?.toString().trim() ?? '');
    final int tmdbRaw = int.tryParse('${map['tmdb_id'] ?? ''}') ?? 0;
    final String imdbRaw = (map['imdb_id'] ?? map['imdb'] ?? '').toString().trim();
    // Xtream renvoie `duration` au format "HH:MM:SS" (souvent "00:00:00").
    // `runtime` peut etre un nombre de minutes.
    int parseRuntime(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      final s = v.toString().trim();
      if (s.isEmpty) return 0;
      final hms = RegExp(r'^(\d+):(\d{1,2}):(\d{1,2})').firstMatch(s);
      if (hms != null) {
        final h = int.tryParse(hms.group(1)!) ?? 0;
        final m = int.tryParse(hms.group(2)!) ?? 0;
        return h * 60 + m;
      }
      return int.tryParse(s) ?? 0;
    }

    var runtimeRaw = parseRuntime(map['duration']);
    if (runtimeRaw == 0) runtimeRaw = parseRuntime(map['runtime']);
    var budgetRaw = 0;
    if (map['budget'] is String) {
      final parsed = int.tryParse(map['budget']);
      if (parsed != null && parsed > 0) budgetRaw = parsed;
    }
    var revenueRaw = 0;
    if (map['revenue'] is String) {
      final parsed = int.tryParse(map['revenue']);
      if (parsed != null && parsed > 0) revenueRaw = parsed;
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

    /// Les panels Xtream n'ont pas de type stable pour les champs numeriques :
    /// `rating` est une chaine ("7.5") sur la quasi-totalite des entrees et un
    /// nombre sur quelques-unes, `year` peut etre une chaine aussi. Un cast
    /// `as num?` casse le chargement entier du catalogue sur le premier element
    /// rencontre, donc on passe toujours par `toString()` puis un parse tolerant.
    double parseRating(dynamic value) {
      if (value == null) return 0;
      return double.tryParse('$value'.trim()) ?? 0;
    }

    int parseYear(dynamic value) {
      if (value == null) return 0;
      final match = RegExp(r'\d{4}').firstMatch('$value');
      if (match != null) return int.tryParse(match.group(0)!) ?? 0;
      return int.tryParse('$value'.trim()) ?? 0;
    }

    return Movie(
      id: map['id']?.toString() ?? map['stream_id']?.toString() ?? '',
      title: map['name']?.toString() ?? map['title']?.toString() ?? '',
      description: firstNonEmpty([
        map['plot'],
        map['overview'],
        map['description'],
        map['synopsis'],
      ]),
      posterUrl: firstNonEmpty([
        map['poster'],
        map['stream_icon'],
        map['cover'],
        map['backdrop_path'],
      ]),
      year: parseYear(map['year']),
      genre: firstNonEmpty([map['genre'], map['categories']]),
      director: firstNonEmpty([map['director'], map['director_name']]),
      rating: parseRating(map['rating']),
      pegi: firstNonEmpty([
        map['pegi'],
        map['age'],
        map['mpaa'],
        map['us_certification'],
        map['contentRating'],
      ]),
      streamId: map['stream_id']?.toString() ?? '',
      containerExtension: map['container_extension']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      cast: castList,
      crew: crewList,
      keywords: keywordsRaw.isEmpty ? const <String>[] : keywordsRaw,
      runtime: runtimeRaw > 0 ? runtimeRaw : 0,
      budget: budgetRaw > 0 ? budgetRaw : 0,
      revenue: revenueRaw > 0 ? revenueRaw : 0,
      productionCompanies: companiesRaw.isEmpty ? const <String>[] : companiesRaw,
      trailerUrl: trailerRaw.isEmpty ? '' : trailerRaw,
      backdropUrl: backdropRaw.isEmpty ? '' : backdropRaw,
      tmdbId: tmdbRaw > 0 ? tmdbRaw : 0,
      imdbId: imdbRaw,
      addedDate: parseAdded(map['added']),
    );
  }

  Movie copyWith({
    String? id,
    String? title,
    String? description,
    String? posterUrl,
    int? year,
    String? genre,
    String? director,
    double? rating,
    String? pegi,
    String? streamId,
    String? containerExtension,
    String? categoryId,
    List<Actor>? cast,
    List<CrewMember>? crew,
    List<String>? keywords,
    int? runtime,
    int? budget,
    int? revenue,
    List<String>? productionCompanies,
    String? trailerUrl,
    String? backdropUrl,
    int? tmdbId,
    String? imdbId,
    DateTime? addedDate,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      director: director ?? this.director,
      rating: rating ?? this.rating,
      pegi: pegi ?? this.pegi,
      streamId: streamId ?? _streamId,
      containerExtension: containerExtension ?? _containerExtension,
      categoryId: categoryId ?? this.categoryId,
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
      keywords: keywords ?? this.keywords,
      runtime: runtime ?? this.runtime,
      budget: budget ?? this.budget,
      revenue: revenue ?? this.revenue,
      productionCompanies: productionCompanies ?? this.productionCompanies,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      tmdbId: tmdbId ?? this.tmdbId,
      imdbId: imdbId ?? this.imdbId,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);

  String? get pegiLabel => ageBadgeLabel(pegi);
}
