/// Construit les URLs de lecture Xtream sans dépendance à l'état API.
class XtreamUrlBuilder {
  const XtreamUrlBuilder._();

  static String trimBaseUrl(String baseUrl) {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    const suffix = '/player_api.php';
    if (url.toLowerCase().endsWith(suffix)) {
      url = url.substring(0, url.length - suffix.length);
    }
    return url;
  }

  static String buildStreamUrl(
    String baseUrl,
    String username,
    String password,
    String? streamId, {
    String type = '',
    String? extension,
    bool withExtension = false,
    Map<String, String> extra = const {},
  }) {
    if (streamId == null || streamId.isEmpty) return '';
    final uri = Uri.parse(trimBaseUrl(baseUrl));
    final mediaType = type.toLowerCase();
    final segments = <String>[];
    // VOD and series paths use their media type; live and radio do not.
    if (mediaType == 'movie' || mediaType == 'series') {
      segments.add(mediaType);
    }
    segments.addAll(<String>[
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      username,
      password,
    ]);
    var mediaId = streamId;
    // Many panels reject extensions; append one only for legacy servers.
    if ((mediaType == 'movie' || mediaType == 'series') && withExtension) {
      final ext = _normalizeExtension(extension);
      mediaId = '$streamId.$ext';
    }
    segments.add(mediaId);
    final query = extra.isEmpty ? null : extra;
    return uri
        .replace(pathSegments: segments, queryParameters: query)
        .toString();
  }

  /// URL de lecture timeshift Xtream, dont la durée est exprimée en minutes.
  static String buildTimeshiftUrl(
    String baseUrl,
    String username,
    String password,
    String streamId, {
    required int start,
    required int end,
    String? extension,
  }) {
    final uri = Uri.parse(trimBaseUrl(baseUrl));
    // Xtream expects a minute duration and YYYY-MM-DD:HH-mm local timestamp.
    final durationMinutes = ((end - start) / 60).ceil().clamp(1, 1 << 20);
    final startLocal = DateTime.fromMillisecondsSinceEpoch(start * 1000);
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${startLocal.year}-${two(startLocal.month)}-${two(startLocal.day)}'
        ':${two(startLocal.hour)}-${two(startLocal.minute)}';
    final ext = _normalizeTimeshiftExtension(extension);

    final segments = <String>[
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      'timeshift',
      username,
      password,
      '$durationMinutes',
      stamp,
      '$streamId.$ext',
    ];
    return uri.replace(pathSegments: segments).toString();
  }

  static String _normalizeTimeshiftExtension(String? extension) {
    var ext = (extension ?? 'ts').trim().replaceFirst(RegExp(r'^\.'), '');
    ext = ext.toLowerCase();
    if (ext.isEmpty) return 'ts';
    if (ext == 'mpegts' || ext == 'mpeg-ts') return 'ts';
    if (ext == 'hls' || ext == 'm3u8') return 'm3u8';
    return ext;
  }

  static String _normalizeExtension(String? extension) {
    if (extension == null || extension.trim().isEmpty) return 'mp4';
    return extension.trim().replaceFirst(RegExp(r'^\.'), '').toLowerCase();
  }
}
