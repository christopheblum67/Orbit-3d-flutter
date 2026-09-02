/// Utilitaires d'extraction défensive des métadonnées média
/// (synopsis, classification d'âge) quelle que soit la source (Xtream, M3U...).
library;

String firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
}

String? ageBadgeLabel(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  final upper = text.toUpperCase();
  if (upper == 'ALL' ||
      upper == 'TOUS' ||
      upper == 'NA' ||
      upper == 'N/A' ||
      upper == '0') {
    return null;
  }
  if (RegExp(r'^\d{1,2}$').hasMatch(text)) {
    return '$text+';
  }
  return text;
}
