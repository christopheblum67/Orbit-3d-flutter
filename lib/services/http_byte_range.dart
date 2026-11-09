/// Résultat de l'analyse d'une plage HTTP simple pour une ressource complète.
sealed class HttpByteRangeResult {
  const HttpByteRangeResult();
}

class HttpByteRange extends HttpByteRangeResult {
  const HttpByteRange(this.start, this.end);

  final int start;
  final int end;
  int get length => end - start + 1;
}

/// Une plage valide mais extérieure à la ressource (réponse HTTP 416).
class UnsatisfiableByteRange extends HttpByteRangeResult {
  const UnsatisfiableByteRange();
}

/// Syntaxe invalide ou plage multiple : à traiter par le serveur amont.
class UnsupportedByteRange extends HttpByteRangeResult {
  const UnsupportedByteRange();
}

HttpByteRangeResult parseHttpByteRange(String header, int size) {
  if (size < 0) throw ArgumentError.value(size, 'size');
  final match = RegExp(r'^bytes=(\d*)-(\d*)$', caseSensitive: false)
      .firstMatch(header.trim());
  if (match == null || (match[1]!.isEmpty && match[2]!.isEmpty)) {
    return const UnsupportedByteRange();
  }
  final first = match[1]!;
  final last = match[2]!;
  final startValue = first.isEmpty ? null : int.tryParse(first);
  final endValue = last.isEmpty ? null : int.tryParse(last);
  if ((first.isNotEmpty && startValue == null) ||
      (last.isNotEmpty && endValue == null)) {
    return const UnsupportedByteRange();
  }
  if (first.isNotEmpty && endValue != null && endValue < startValue!) {
    return const UnsupportedByteRange();
  }
  if (size == 0) return const UnsatisfiableByteRange();
  if (startValue == null) {
    if (endValue == 0) return const UnsatisfiableByteRange();
    return HttpByteRange(endValue! >= size ? 0 : size - endValue, size - 1);
  }
  if (startValue >= size) return const UnsatisfiableByteRange();
  return HttpByteRange(
    startValue,
    endValue == null || endValue >= size ? size - 1 : endValue,
  );
}
