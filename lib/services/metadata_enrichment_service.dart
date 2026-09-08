import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/services/ai_service.dart';
import 'package:orbit_3d_flutter/services/omdb_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';

/// Orchestrateur principal d'enrichissement des métadonnées
/// Chaîne les fallbacks : TMDB/TVmaze → OMDB → IA
class MetadataEnrichmentService {
  final TmdbService _tmdb;
  final TvmazeService _tvmaze;
  final OmdbService _omdb;
  final AiService _ai;

  MetadataEnrichmentService({
    required TmdbService tmdb,
    required TvmazeService tvmaze,
    required OmdbService omdb,
    required AiService ai,
  })  : _tmdb = tmdb,
        _tvmaze = tvmaze,
        _omdb = omdb,
        _ai = ai;

  /// Enrichit un film (VOD) avec toutes les métadonnées disponibles
  Future<MovieDetail> enrichMovie(Movie movie) async {
    var detail = MovieDetail.fromMovie(movie);

    // 1. TMDB PRIMAIRE (recherche par titre + année si pas d'ID connu)
    if (_tmdb.hasApiKey) {
      int? tmdbId;

      // Si on a déjà un IMDB ID dans les données Xtream, on pourrait le mapper
      // Sinon, recherche par titre + année
      tmdbId = await _tmdb.searchMovieId(movie.title,
          year: movie.year > 0 ? movie.year : null);

      if (tmdbId != null) {
        final tmdbDetail = await _tmdb.getMovieDetail(tmdbId);
        if (tmdbDetail != null) {
          detail = _mergeMovieDetail(detail, tmdbDetail);
        }
      }
    }

    // 2. OMDB FALLBACK (si année/runtime/director manquent)
    if (detail.year == 0 ||
        detail.runtime == 0 ||
        detail.director.isEmpty ||
        detail.imdbId.isEmpty) {
      final omdbDetail = await _omdb.fillMissingMovie(detail);
      if (omdbDetail != detail) {
        detail = _mergeMovieDetail(detail, omdbDetail);
      }
    }

    // 3. TVMAZE FALLBACK CAST (si pas de casting)
    if (detail.cast.isEmpty) {
      int? tvmazeId;
      if (_tvmaze.hasApiKey || true) {
        // TVmaze n'a pas besoin de clé
        tvmazeId = await _tvmaze.searchMovieId(movie.title);
        if (tvmazeId != null) {
          final tvmazeDetail = await _tvmaze.getMovieDetail(tvmazeId);
          if (tvmazeDetail != null && tvmazeDetail.cast.isNotEmpty) {
            detail = detail.copyWith(
              cast: tvmazeDetail.cast,
              tvmazeId: tvmazeId,
            );
          }
        }
      }
    }

    // 4. IA DERNIER RECOURS (si champs critiques encore manquants)
    if (detail.needsAiFallback) {
      final aiDetail = await _enrichMovieWithAi(detail, movie);
      if (aiDetail != null) {
        detail = aiDetail;
      }
    }

    return detail;
  }

  /// Enrichit une série avec toutes les métadonnées disponibles
  Future<SeriesDetail> enrichSeries(Series series) async {
    var detail = SeriesDetail.fromSeries(series);

    // 1. TVMAZE PRIMAIRE (le meilleur pour les séries)
    int? tvmazeId = await _tvmaze.searchShowId(series.title);

    if (tvmazeId != null) {
      final tvmazeDetail = await _tvmaze.getShowDetail(tvmazeId);
      if (tvmazeDetail != null) {
        detail = _mergeSeriesDetail(detail, tvmazeDetail);
      }
    }

    // 2. TMDB FALLBACK GUEST STARS (si TVmaze n'a pas les guest stars par saison)
    if (detail.guestStarsPerSeason.isEmpty && _tmdb.hasApiKey) {
      int? tmdbId;
      if (detail.tmdbId > 0) {
        tmdbId = detail.tmdbId;
      } else {
        tmdbId = await _tmdb.searchTvId(series.title,
            year: series.year > 0 ? series.year : null);
      }

      if (tmdbId != null) {
        final seasonNumbers = detail.episodes
            .map((e) => e.season)
            .where((s) => s > 0)
            .toSet()
            .toList();

        final guestStars =
            await _tmdb.getSeasonGuestStars(tmdbId, seasonNumbers);
        if (guestStars != null && guestStars.isNotEmpty) {
          detail = detail.copyWith(
            guestStarsPerSeason: guestStars,
            tmdbId: tmdbId,
          );
        }
      }
    }

    // 3. OMDB FALLBACK (champs manquants)
    if (detail.year == 0 || detail.runtime == 0 || detail.networks.isEmpty) {
      final omdbDetail = await _omdb.fillMissingSeries(detail);
      if (omdbDetail != detail) {
        detail = _mergeSeriesDetail(detail, omdbDetail);
      }
    }

    // 4. IA DERNIER RECOURS
    if (detail.needsAiFallback) {
      final aiDetail = await _enrichSeriesWithAi(detail, series);
      if (aiDetail != null) {
        detail = aiDetail;
      }
    }

    return detail;
  }

  // ==================== MERGE HELPERS ====================

  MovieDetail _mergeMovieDetail(MovieDetail base, MovieDetail incoming) {
    // Préserver les données Xtream (streamUrl, etc.) et ne compléter que les manquants
    return base.copyWith(
      // Métadonnées TMDB/OMDB/TVmaze prennent le dessus si base manquante
      title: base.title.isNotEmpty ? base.title : incoming.title,
      description:
          base.description.isNotEmpty ? base.description : incoming.description,
      posterUrl:
          base.posterUrl.isNotEmpty ? base.posterUrl : incoming.posterUrl,
      year: base.year > 0 ? base.year : incoming.year,
      genre: base.genre.isNotEmpty ? base.genre : incoming.genre,
      director: base.director.isNotEmpty ? base.director : incoming.director,
      rating: base.rating > 0 ? base.rating : incoming.rating,
      pegi: base.pegi.isNotEmpty ? base.pegi : incoming.pegi,
      // IDs externes
      imdbId: base.imdbId.isNotEmpty ? base.imdbId : incoming.imdbId,
      tmdbId: incoming.tmdbId > 0 ? incoming.tmdbId : base.tmdbId,
      tvmazeId: incoming.tvmazeId > 0 ? incoming.tvmazeId : base.tvmazeId,
      // Enrichis
      runtime: incoming.runtime > 0 ? incoming.runtime : base.runtime,
      keywords:
          incoming.keywords.isNotEmpty ? incoming.keywords : base.keywords,
      originCountry: incoming.originCountry.isNotEmpty
          ? incoming.originCountry
          : base.originCountry,
      spokenLanguages: incoming.spokenLanguages.isNotEmpty
          ? incoming.spokenLanguages
          : base.spokenLanguages,
      budget: incoming.budget > 0 ? incoming.budget : base.budget,
      revenue: incoming.revenue > 0 ? incoming.revenue : base.revenue,
      status: incoming.status.isNotEmpty ? incoming.status : base.status,
      trailerUrl: incoming.trailerUrl ?? base.trailerUrl,
      backdropUrl: incoming.backdropUrl ?? base.backdropUrl,
      originalLanguage: incoming.originalLanguage ?? base.originalLanguage,
      originalTitle: incoming.originalTitle ?? base.originalTitle,
      // Cast/Crew (prendre le plus complet)
      cast: incoming.cast.isNotEmpty ? incoming.cast : base.cast,
      crew: incoming.crew.isNotEmpty ? incoming.crew : base.crew,
      // Source tracking
      dataSource: incoming.dataSource,
      aiGenerated: incoming.aiGenerated,
    );
  }

  SeriesDetail _mergeSeriesDetail(SeriesDetail base, SeriesDetail incoming) {
    return base.copyWith(
      title: base.title.isNotEmpty ? base.title : incoming.title,
      description:
          base.description.isNotEmpty ? base.description : incoming.description,
      coverUrl: base.coverUrl.isNotEmpty ? base.coverUrl : incoming.coverUrl,
      year: base.year > 0 ? base.year : incoming.year,
      genre: base.genre.isNotEmpty ? base.genre : incoming.genre,
      director: base.director.isNotEmpty ? base.director : incoming.director,
      rating: base.rating > 0 ? base.rating : incoming.rating,
      pegi: base.pegi.isNotEmpty ? base.pegi : incoming.pegi,
      imdbId: base.imdbId.isNotEmpty ? base.imdbId : incoming.imdbId,
      tvmazeId: incoming.tvmazeId > 0 ? incoming.tvmazeId : base.tvmazeId,
      tmdbId: incoming.tmdbId > 0 ? incoming.tmdbId : base.tmdbId,
      runtime: incoming.runtime > 0 ? incoming.runtime : base.runtime,
      keywords:
          incoming.keywords.isNotEmpty ? incoming.keywords : base.keywords,
      networks:
          incoming.networks.isNotEmpty ? incoming.networks : base.networks,
      status: incoming.status.isNotEmpty ? incoming.status : base.status,
      firstAirDate: incoming.firstAirDate.isNotEmpty
          ? incoming.firstAirDate
          : base.firstAirDate,
      lastAirDate: incoming.lastAirDate ?? base.lastAirDate,
      numberOfSeasons: incoming.numberOfSeasons > 0
          ? incoming.numberOfSeasons
          : base.numberOfSeasons,
      numberOfEpisodes: incoming.numberOfEpisodes > 0
          ? incoming.numberOfEpisodes
          : base.numberOfEpisodes,
      originalLanguage: incoming.originalLanguage ?? base.originalLanguage,
      originalName: incoming.originalName ?? base.originalName,
      guestStarsPerSeason: incoming.guestStarsPerSeason.isNotEmpty
          ? incoming.guestStarsPerSeason
          : base.guestStarsPerSeason,
      cast: incoming.cast.isNotEmpty ? incoming.cast : base.cast,
      dataSource: incoming.dataSource,
      aiGenerated: incoming.aiGenerated,
    );
  }

  // ==================== IA FALLBACK ====================

  Future<MovieDetail?> _enrichMovieWithAi(
      MovieDetail detail, Movie originalMovie) async {
    try {
      final prompt = '''
Tu es un expert cinéma. Génère des métadonnées manquantes pour ce film VOD.

Film: "${originalMovie.title}"
Année connue: ${originalMovie.year > 0 ? originalMovie.year : 'inconnue'}
Genre connu: ${originalMovie.genre.isNotEmpty ? originalMovie.genre : 'inconnu'}
Réalisateur connu: ${originalMovie.director.isNotEmpty ? originalMovie.director : 'inconnu'}
Synopsis: ${originalMovie.description.isNotEmpty ? originalMovie.description : 'inconnu'}

Réponds UNIQUEMENT en JSON valide (sans texte autour) :
{
  "year": 2023,
  "genre": "Action, Thriller",
  "director": "John Doe",
  "runtime": 120,
  "originCountry": ["US"],
  "spokenLanguages": ["English"],
  "keywords": ["action", "thriller", "pursuit"],
  "cast": [
    {"id": "1", "name": "Actor Name", "character": "Character Name", "order": 1}
  ]
}

Si une info est inconnue, mets null ou tableau vide. Ne pas inventer.
''';

      // L'AiService actuel est fait pour les recommandations, pas pour ce format
      // On ferait un appel direct ici ou on étendrait AiService
      // Pour l'instant, on retourne null (IA non implémentée pour ce cas)
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SeriesDetail?> _enrichSeriesWithAi(
      SeriesDetail detail, Series originalSeries) async {
    try {
      // Même logique que pour les films
      return null;
    } catch (e) {
      return null;
    }
  }
}
