import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';

class XtreamMovieDetailService {
  XtreamMovieDetailService({
    required PlayerApiUrlBuilder buildApiUrl,
    required Future<Response<dynamic>> Function(String url) get,
  })  : _buildApiUrl = buildApiUrl,
        _get = get;

  final PlayerApiUrlBuilder _buildApiUrl;
  final Future<Response<dynamic>> Function(String url) _get;

  String _url(String base, String user, String password, String movieId) =>
      _buildApiUrl(base, 'player_api.php', {
        'username': user,
        'password': password,
        'action': 'get_vod_info',
        'vod_id': movieId,
      });

  Future<Movie> detail(
    Movie movie,
    String base,
    String user,
    String password,
  ) async {
    final url = _url(base, user, password, movie.id);
    final result = await safeAsync<Movie>(
      () async {
        final response = await _get(url);
        final data = response.data;
        if (data is! Map) return movie;
        final rawInfo = data['info'];
        final info = rawInfo is Map ? rawInfo : <String, dynamic>{};
        var year = movie.year;
        final releaseDate =
            firstNonEmpty([info['releaseDate'], info['releasedate']])
                .toString();
        final match = RegExp(r'^(\d{4})').firstMatch(releaseDate);
        if (match != null) year = int.tryParse(match.group(1)!) ?? year;
        final genre = firstNonEmpty([
          info['genre'],
          info['genre_1'],
          movie.genre,
        ]).toString().trim();
        var rating = movie.rating;
        final ratingRaw = firstNonEmpty([info['rating'], info['rating_5based']])
            .toString()
            .replaceAll(RegExp(r'[^0-9.]'), '');
        if (ratingRaw.isNotEmpty) rating = double.tryParse(ratingRaw) ?? rating;
        return Movie(
          id: movie.id,
          title: movie.title,
          description: firstNonEmpty([
            info['description'],
            info['plot'],
            movie.description,
          ]).toString(),
          posterUrl: firstNonEmpty([
            info['cover_big'],
            info['movie_image'],
            info['backdrop_path'],
            movie.posterUrl,
          ]).toString(),
          year: year,
          genre: genre,
          director:
              firstNonEmpty([info['director'], movie.director]).toString(),
          rating: rating,
          pegi: firstNonEmpty([
            info['age'],
            info['mpaa_rating'],
            info['us_certification'],
            movie.pegi,
          ]).toString(),
          streamId: movie.streamId,
          containerExtension: movie.containerExtension,
          categoryId: movie.categoryId,
        );
      },
      context: 'ApiService.fetchMovieDetail',
      fallbackValue: movie,
    );
    return result.getOrElse(movie);
  }

  Future<MovieCredits?> credits(
    String movieId,
    String base,
    String user,
    String password,
  ) async {
    final url = _url(base, user, password, movieId);
    final result = await safeAsync<MovieCredits?>(
      () async {
        final data = (await _get(url)).data;
        if (data is! Map) return null;
        final rawInfo = data['info'];
        final info = rawInfo is Map
            ? Map<String, dynamic>.from(rawInfo)
            : <String, dynamic>{};
        return MovieCredits.fromMap(info);
      },
      context: 'ApiService.fetchMovieCredits',
      fallbackValue: null,
    );
    return result.valueOrNull;
  }
}
