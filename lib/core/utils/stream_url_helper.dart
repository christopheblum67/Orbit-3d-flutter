/// Utilitaire de nettoyage d'URL de flux M3U.
///
/// Gère le "pipe stripping" : retire les paramètres collés à l'URL via un pipe
/// (ex: `http://server/live/123.ts|User-Agent=VLC&referer=...`) et extrait les
/// en-têtes HTTP optionnels (User-Agent, Referer).
class StreamUrlHelper {
  static ParsedStream parse(String rawUrl) {
    String url = rawUrl.trim();
    final headers = <String, String>{};

    if (url.contains('|')) {
      final parts = url.split('|');
      url = parts[0].trim();
      final options = parts.length > 1 ? parts[1] : '';

      for (final option in options.split(RegExp(r'[&;]'))) {
        final kv = option.split('=');
        if (kv.length == 2) {
          final key = kv[0].trim().toLowerCase();
          final value = kv[1].trim();
          if (key == 'user-agent') headers['User-Agent'] = value;
          if (key == 'referer') headers['Referer'] = value;
        }
      }
    }
    return ParsedStream(url: url, headers: headers);
  }
}

class ParsedStream {
  final String url;
  final Map<String, String> headers;
  ParsedStream({required this.url, required this.headers});
}