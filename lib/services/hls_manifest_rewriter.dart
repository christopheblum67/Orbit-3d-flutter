/// Réécrit les références HTTP(S) d'un manifeste HLS vers un relais local.
///
/// [manifestUri] doit être l'URL finale après redirection : les références
/// relatives du manifeste sont résolues par rapport à cette adresse.
String rewriteHlsManifest(
  String manifest,
  Uri manifestUri,
  Uri Function(Uri target) relay,
) {
  if (manifest.split('\n').first.replaceFirst(RegExp(r'\r$'), '') !=
      '#EXTM3U') {
    throw const FormatException('Manifeste HLS invalide');
  }
  if (!manifestUri.isAbsolute ||
      (manifestUri.scheme != 'http' && manifestUri.scheme != 'https')) {
    throw ArgumentError.value(manifestUri, 'manifestUri');
  }

  String rewrite(String value) {
    if (value.isEmpty) {
      throw const FormatException('URI HLS vide');
    }
    if (value.contains(r'{$')) {
      throw const FormatException('Variables HLS non prises en charge');
    }
    final target = manifestUri.resolve(value);
    if (target.scheme != 'http' && target.scheme != 'https') {
      throw const FormatException('Schéma de ressource HLS non pris en charge');
    }
    return relay(target).toString();
  }

  String rewriteAttributes(String attributes) {
    final parts = <String>[];
    var start = 0;
    var quoted = false;
    for (var i = 0; i < attributes.length; i++) {
      if (attributes[i] == '"') quoted = !quoted;
      if (attributes[i] == ',' && !quoted) {
        parts.add(attributes.substring(start, i));
        start = i + 1;
      }
    }
    if (quoted) throw const FormatException('Attribut HLS non terminé');
    parts.add(attributes.substring(start));
    final uriAttribute =
        RegExp(r'^(\s*(?:URI|SERVER-URI)\s*=\s*)"([^"]*)"(\s*)$');
    for (var i = 0; i < parts.length; i++) {
      final match = uriAttribute.firstMatch(parts[i]);
      if (match != null) {
        parts[i] = '${match[1]}"${rewrite(match[2]!)}"${match[3]}';
      } else if (RegExp(r'^\s*(?:URI|SERVER-URI)\s*=').hasMatch(parts[i])) {
        throw const FormatException('Attribut URI HLS invalide');
      }
    }
    return parts.join(',');
  }

  const uriTags = {
    '#EXT-X-KEY',
    '#EXT-X-SESSION-KEY',
    '#EXT-X-MAP',
    '#EXT-X-MEDIA',
    '#EXT-X-I-FRAME-STREAM-INF',
    '#EXT-X-IMAGE-STREAM-INF',
    '#EXT-X-SESSION-DATA',
    '#EXT-X-PART',
    '#EXT-X-PRELOAD-HINT',
    '#EXT-X-RENDITION-REPORT',
    '#EXT-X-CONTENT-STEERING',
  };
  return manifest.split('\n').map((line) {
    final cr = line.endsWith('\r') ? '\r' : '';
    final content = cr.isEmpty ? line : line.substring(0, line.length - 1);
    final trimmed = content.trim();
    if (trimmed.isEmpty) return line;
    if (!trimmed.startsWith('#')) {
      final start = content.indexOf(trimmed);
      return '${content.substring(0, start)}${rewrite(trimmed)}'
          '${content.substring(start + trimmed.length)}$cr';
    }
    final separator = content.indexOf(':');
    if (separator < 0) return line;
    if (!uriTags.contains(content.substring(0, separator).trim())) {
      if (RegExp(r'(?:^|,)\s*(?:URI|SERVER-URI)\s*=')
          .hasMatch(content.substring(separator + 1))) {
        throw const FormatException('Attribut URI HLS non pris en charge');
      }
      return line;
    }
    final attributes = content.substring(separator + 1);
    return '${content.substring(0, separator + 1)}'
        '${rewriteAttributes(attributes)}$cr';
  }).join('\n');
}
