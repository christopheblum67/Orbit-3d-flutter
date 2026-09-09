const playbackUserAgents = <String>[
  'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
  'Orbit3D/1.0 (Linux; Android 14; FireTV) ExoPlayerLib/2.19.1',
  'Mozilla/5.0',
  // UA exact de l'app XCIPTV (capture PCAP) : obtient systématiquement le
  // 302 vers le CDN signé sur les serveurs de type draap. Placé en dernier
  // car l'ordre de tentative par défaut est inversé (premier essayé).
  'XCIPTV-v7.0-2000',
];

String refererFor(Uri uri) {
  final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
  return '${uri.scheme}://${uri.host}:$port/';
}

Map<String, String> streamHeaders(
  String url, {
  int userAgentIndex = 0,
  Map<String, String>? additional,
}) {
  final uri = Uri.parse(url);
  final headers = <String, String>{
    'User-Agent': playbackUserAgents[userAgentIndex],
    'Accept': '*/*',
    'Referer': refererFor(uri),
  };
  if (additional != null) {
    headers.addAll(additional);
  }
  return headers;
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

/// Génère une liste d'URL candidates pour la lecture, en partant de l'URL
/// construite. Gère les deux structures Xtream :
///  - standard : `/movie/{u}/{p}/{id}` ou `/series/{u}/{p}/{id}` (avec ou
///    sans extension) ;
///  - « style live » : `/{u}/{p}/{id}`, redirigé vers un CDN signé
///    (utilisé par draap.online pour le VOD/live/radio).
/// On renvoie les variantes de la plus résiliente à la plus spécifique pour
/// que le player puisse retenter en cas d'échec.
List<String> streamUrlVariants(String url) {
  if (!isLikelyStreamUrl(url)) return <String>[url];
  final uri = Uri.tryParse(url);
  if (uri == null) return <String>[url];
  final segments = <String>[...uri.pathSegments];
  final variants = <String>{};

  // Variante 1 : telle quelle.
  variants.add(url);

  if (segments.length < 2) return variants.toList();

  final first = segments.first.toLowerCase();
  final isMediaFolder = first == 'movie' || first == 'series';

  if (isMediaFolder) {
    // /movie/{u}/{p}/{id}[.ext] ou /series/...
    final id = segments.last;
    final dotIdx = id.lastIndexOf('.');
    final baseId = dotIdx > 0 ? id.substring(0, dotIdx) : id;
    final ext = dotIdx > 0 ? id.substring(dotIdx + 1) : null;
    // Variante 2 : retirer l'éventuelle extension.
    if (dotIdx > 0) {
      final noExt = [...segments];
      noExt[noExt.length - 1] = baseId;
      variants.add(_rebuild(uri, noExt));
    }
    // Variante 3 : ajouter l'extension si absente.
    if (dotIdx <= 0) {
      final m4 = [...segments];
      m4[m4.length - 1] = '$baseId.mp4';
      variants.add(_rebuild(uri, m4));
      final mkv = [...segments];
      mkv[mkv.length - 1] = '$baseId.mkv';
      variants.add(_rebuild(uri, mkv));
    }
    // Variante 4 : tenter le style live /{u}/{p}/{id} (sans dossier).
    final liveStyle = <String>[...segments]..removeAt(0);
    variants.add(_rebuild(uri, liveStyle));
    if (ext != null && ext.isNotEmpty) {
      final withExt = [...liveStyle];
      withExt[withExt.length - 1] = '$baseId.$ext';
      variants.add(_rebuild(uri, withExt));
      final noExtLive = [...liveStyle];
      noExtLive[noExtLive.length - 1] = baseId;
      variants.add(_rebuild(uri, noExtLive));
    }
  } else {
    // Style live /{u}/{p}/{id}[.ext] : ne tenter QUE la forme sans extension.
    // Pour les flux retransmis, les chemins /movie/ et /series/ n'existent pas
    // et déclenchent l'anti-leech du panneau (401 et blocage IP temporaire).
    final id = segments.last;
    // Les chemins de scripts (timeshift.php, player_api.php, …) ne sont pas
    // des fichiers média : AUCUNE variante (anti-leech ~90 s sur draap).
    if (!id.toLowerCase().endsWith('.php')) {
      final dotIdx = id.lastIndexOf('.');
      final baseId = dotIdx > 0 ? id.substring(0, dotIdx) : id;
      if (dotIdx > 0) {
        final noExt = [...segments];
        noExt[noExt.length - 1] = baseId;
        variants.add(_rebuild(uri, noExt));
      }
    }
    // Ne PAS ajouter d'extension ici : sur ce type de panneau, seul le
    // chemin nu /live/{u}/{p}/{id} (ou l'URL d'origine avec son extension)
    // est valide. Tenter {id}.ts ou {id}.m3u8 renvoie 404 et les retries
    // successives maintiennent l'anti-leech du panneau (fenêtre ~90 s).
  }
  return variants.toList();
}

String _rebuild(Uri uri, List<String> segments) {
  return uri
      .replace(
        pathSegments: segments,
        queryParameters: uri.hasQuery ? uri.queryParameters : null,
      )
      .toString();
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
