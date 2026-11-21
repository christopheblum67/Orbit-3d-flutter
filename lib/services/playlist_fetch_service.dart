import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';

typedef PlaylistHttpGet = Future<Response<dynamic>> Function(
  String url, {
  Options? options,
  ProgressCallback? onReceiveProgress,
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
  static int _nextTraceId = 0;

  Future<M3uPlaylist> fetch(String url, {VoidCallback? onParsing}) async {
    final stopwatch = Stopwatch()..start();
    final traceId = ++_nextTraceId;
    _log('M3U playlist=fetch-start');
    _log('M3U trace id=$traceId state=start');
    final playlist = await _cache.fetch(
      resource: url,
      request: (headers) async {
        int? lastProgressLogMs;
        var lastReceived = 0;
        var lastTotal = -1;
        final response = await _get(
          url,
          options: Options(
            headers: headers,
            extra: {'orbitM3uTraceId': traceId},
            responseType: ResponseType.plain,
            validateStatus: (status) =>
                status != null &&
                (status == 304 || (status >= 200 && status < 300)),
          ),
          onReceiveProgress: (received, total) {
            if (received <= 0) return;
            final counterReset = received < lastReceived;
            lastReceived = received;
            lastTotal = total;
            final elapsed = stopwatch.elapsedMilliseconds;
            if (counterReset ||
                lastProgressLogMs == null ||
                elapsed - lastProgressLogMs! >= 5000) {
              final state = counterReset
                  ? 'counter-reset'
                  : lastProgressLogMs == null
                      ? 'first-byte'
                      : 'receiving';
              _log(
                'M3U transfer trace=$traceId state=$state '
                'receivedBytes=$received totalBytes=$total elapsedMs=$elapsed',
              );
              lastProgressLogMs = elapsed;
            }
          },
        );
        if (lastReceived > 0) {
          _log('M3U transfer trace=$traceId state=response '
              'lastReceivedBytes=$lastReceived lastTotalBytes=$lastTotal '
              'elapsedMs=${stopwatch.elapsedMilliseconds}');
        }
        _log('M3U response status=${response.statusCode ?? 0}');
        _log('M3U trace id=$traceId state=response '
            'status=${response.statusCode ?? 0} '
            'elapsedMs=${stopwatch.elapsedMilliseconds}');
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
      parse: (body) async {
        onParsing?.call();
        _log('M3U parse trace=$traceId state=start '
            'elapsedMs=${stopwatch.elapsedMilliseconds}');
        final result = await compute(_parsePlaylist, body);
        _log(
          'M3U body chars=${body.length} '
          'header=${result.header} '
          'extinf=${result.extinfCount} '
          'html=${result.html}',
        );
        _log('M3U parse trace=$traceId state=complete '
            'diagnosticsMs=${result.diagnosticsMs} '
            'classifyMs=${result.classifyMs} groupMs=${result.groupMs} '
            'elapsedMs=${stopwatch.elapsedMilliseconds}');
        if (result.playlist == null) throw const EmptyPlaylistException();
        return result.playlist!;
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

typedef _PlaylistParseResult = ({
  bool header,
  bool html,
  int extinfCount,
  int diagnosticsMs,
  int classifyMs,
  int groupMs,
  M3uPlaylist? playlist,
});

_PlaylistParseResult _parsePlaylist(String body) {
  final stopwatch = Stopwatch()..start();
  final header =
      RegExp(r'^\s*\uFEFF?\s*#EXTM3U', caseSensitive: false).hasMatch(body);
  final html =
      RegExp(r'^\s*\uFEFF?\s*<(?:!doctype\s+html|html)', caseSensitive: false)
          .hasMatch(body);
  final extinfCount =
      RegExp(r'^[ \t]*#EXTINF', multiLine: true, caseSensitive: false)
          .allMatches(body)
          .length;
  final empty = !RegExp(r'\S').hasMatch(body);
  final diagnosticsMs = stopwatch.elapsedMilliseconds;
  var classifyMs = 0;
  var groupMs = 0;
  final playlist = empty
      ? null
      : M3uPlaylistParser.parse(
          body,
          onTiming: (classify, group) {
            classifyMs = classify;
            groupMs = group;
          },
        );
  return (
    header: header,
    html: html,
    extinfCount: extinfCount,
    diagnosticsMs: diagnosticsMs,
    classifyMs: classifyMs,
    groupMs: groupMs,
    playlist: playlist,
  );
}
