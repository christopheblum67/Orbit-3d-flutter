const playbackUserAgents = <String>[
  'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
  'Orbit3D/1.0 (Linux; Android 14; FireTV) ExoPlayerLib/2.19.1',
  'ExoPlayer/2.19.1',
];

String refererFor(Uri uri) {
  final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
  return '${uri.scheme}://${uri.host}:$port/';
}

Map<String, String> streamHeaders(String url, {int userAgentIndex = 0}) {
  final uri = Uri.parse(url);
  return {
    'User-Agent': playbackUserAgents[userAgentIndex],
    'Accept': '*/*',
    'Referer': refererFor(uri),
  };
}

class StreamUrlEmptyException implements Exception {
  StreamUrlEmptyException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool isLikelyStreamUrl(String url) {
  if (url.trim().isEmpty) return false;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  if (uri.host.isEmpty) return false;
  return true;
}

String requireStreamUrl(String url, {String? label}) {
  if (!isLikelyStreamUrl(url)) {
    final subject =
        (label == null || label.isEmpty) ? 'un flux' : 'le flux "$label"';
    throw StreamUrlEmptyException(
      'Impossible de lire $subject : URL vide ou invalide. '
      'Vérifiez votre abonnement (identifiants Xtream ou URL M3U) '
      'et la configuration du serveur.',
    );
  }
  return url.trim();
}

Future<T> retryStream<T>(
  Future<T> Function() fn, {
  int attempts = 2,
  Duration delay = const Duration(milliseconds: 800),
  bool Function(Object error)? shouldRetry,
}) async {
  if (attempts < 1) attempts = 1;
  Object? lastError;
  for (var attempt = 0; attempt < attempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      final retriable =
          shouldRetry?.call(error) ?? (error is! StreamUrlEmptyException);
      if (!retriable || attempt == attempts - 1) break;
      await Future<void>.delayed(delay);
    }
  }
  throw lastError ?? StateError('Lecture du flux impossible.');
}

final RegExp _xmltvDatePattern =
    RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?: ([+-]\d{4}))?$');

DateTime? parseXmltvDate(String raw) {
  final m = _xmltvDatePattern.firstMatch(raw.trim());
  if (m == null) return null;
  final year = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final day = int.parse(m.group(3)!);
  final hour = int.parse(m.group(4)!);
  final minute = int.parse(m.group(5)!);
  final second = int.parse(m.group(6)!);
  DateTime value = DateTime.utc(year, month, day, hour, minute, second);
  final offset = m.group(7);
  if (offset != null && offset.length == 5) {
    final sign = offset[0] == '-' ? -1 : 1;
    final hours = int.parse(offset.substring(1, 3));
    final minutes = int.parse(offset.substring(3, 5));
    value =
        value.subtract(Duration(hours: sign * hours, minutes: sign * minutes));
  }
  return value.toLocal();
}
