import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';

typedef PlaylistHttpGet = Future<Response<dynamic>> Function(
  String url, {
  Options? options,
});

class PlaylistFetchService {
  PlaylistFetchService({
    required ConditionalPlaylistCache cache,
    required PlaylistHttpGet get,
  })  : _cache = cache,
        _get = get;

  final ConditionalPlaylistCache _cache;
  final PlaylistHttpGet _get;

  Future<M3uPlaylist> fetch(String url) async {
    final stopwatch = Stopwatch()..start();
    logDiag('M3U playlist=fetch-start');
    final playlist = await _cache.fetch(
      resource: url,
      request: (headers) async {
        final response = await _get(
          url,
          options: Options(
            headers: headers,
            responseType: ResponseType.plain,
            validateStatus: (status) =>
                status != null &&
                (status == 304 || (status >= 200 && status < 300)),
          ),
        );
        return PlaylistResponse(
          statusCode: response.statusCode ?? 0,
          body: response.data is String ? response.data as String : null,
          etag: response.headers.value('etag'),
          lastModified: response.headers.value('last-modified'),
          cacheControl: response.headers.value('cache-control'),
          vary: response.headers.value('vary'),
        );
      },
      parse: M3uPlaylistParser.parse,
    );
    logDiag(
      'M3U playlist=parsed channels=${playlist.channels.length} '
      'radios=${playlist.radios.length} '
      'movies=${playlist.movies.length} series=${playlist.series.length} '
      'totalMs=${stopwatch.elapsedMilliseconds}',
    );
    return playlist;
  }
}
