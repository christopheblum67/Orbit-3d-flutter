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
    final subject = (label == null || label.isEmpty)
        ? 'un flux'
        : 'le flux "$label"';
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