import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';

typedef PlaylistHttpGet = Future<Response<dynamic>> Function(
  String url, {
  Options? options,
});

class EmptyPlaylistException extends FormatException {
  const EmptyPlaylistException()
      : super(
            'La playlist M3U reçue est vide. Vérifiez son adresse auprès du fournisseur.');
}

class PlaylistFetchService {
  PlaylistFetchService({
    required ConditionalPlaylistCache cache,
    required PlaylistHttpGet get,
    void Function(String) log = logDiag,
  })  : _cache = cache,
        _get = get,
        _log = log;

  final ConditionalPlaylistCache _cache;
  final PlaylistHttpGet _get;
  final void Function(String) _log;

  Future<M3uPlaylist> fetch(String url) async {
    final stopwatch = Stopwatch()..start();
    _log('M3U playlist=fetch-start');
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
        _log('M3U response status=${response.statusCode ?? 0}');
        String? validator(String name) {
          final values = response.headers[name];
          if (values == null || values.isEmpty) return null;
          if (values.length == 1) return values.single;
          _log('M3U cache validator=$name ambiguous');
          return null;
        }

        return PlaylistResponse(
          statusCode: response.statusCode ?? 0,
          body: response.data is String ? response.data as String : null,
          etag: validator('etag'),
          lastModified: validator('last-modified'),
          cacheControl: response.headers['cache-control']?.join(','),
          vary: response.headers['vary']?.join(','),
        );
      },
      parse: (body) {
        final header = RegExp(r'^\s*\uFEFF?\s*#EXTM3U', caseSensitive: false)
            .hasMatch(body);
        final html = RegExp(r'^\s*\uFEFF?\s*<(?:!doctype\s+html|html)',
                caseSensitive: false)
            .hasMatch(body);
        final extinfCount =
            RegExp(r'^[ \t]*#EXTINF', multiLine: true, caseSensitive: false)
                .allMatches(body)
                .length;
        _log(
          'M3U body chars=${body.length} '
          'header=$header '
          'extinf=$extinfCount '
          'html=$html',
        );
        if (!RegExp(r'\S').hasMatch(body)) throw const EmptyPlaylistException();
        return M3uPlaylistParser.parse(body);
      },
    );
    _log(
      'M3U playlist=parsed channels=${playlist.channels.length} '
      'radios=${playlist.radios.length} '
      'movies=${playlist.movies.length} series=${playlist.series.length} '
      'totalMs=${stopwatch.elapsedMilliseconds}',
    );
    return playlist;
  }
}
