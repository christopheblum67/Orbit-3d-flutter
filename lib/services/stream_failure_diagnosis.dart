/// Origine probable d'un échec de lecture.
enum StreamFailureKind {
  noStream,
  subscription,
  removed,
  network,
  decoder,
  unknown,
}

class StreamFailure {
  const StreamFailure(this.kind, this.message);

  final StreamFailureKind kind;
  final String message;

  bool get isDecoder => kind == StreamFailureKind.decoder;
}

/// Déduit l'origine d'un échec à partir de l'URL et du texte d'erreur du
/// lecteur. Heuristique : le message ne cite jamais l'URL ni les identifiants.
StreamFailure diagnoseStreamFailure({
  required String streamUrl,
  Object? error,
}) {
  if (streamUrl.trim().isEmpty) {
    return const StreamFailure(
      StreamFailureKind.noStream,
      'Cette chaîne n\'a pas de flux chez ton fournisseur.',
    );
  }
  final text = '$error';

  if (text.contains('MediaCodecVideoRenderer') ||
      text.contains('Decoder init failed') ||
      text.contains('Decoder failed') ||
      text.contains('DecoderInitializationException')) {
    return const StreamFailure(
      StreamFailureKind.decoder,
      'Problème matériel : le décodeur vidéo de cet appareil n\'a pas pu '
      'lire ce flux. Le flux lui-même est valide.',
    );
  }

  final code = RegExp(r'Response code:\s*(\d{3})').firstMatch(text)?.group(1);
  if (code != null) {
    switch (code) {
      case '401':
      case '403':
      case '458':
      case '429':
        return StreamFailure(
          StreamFailureKind.subscription,
          'Problème d\'abonnement : accès refusé par le fournisseur '
          '(code $code). Vérifie que l\'abonnement est actif et que le '
          'nombre de connexions simultanées n\'est pas atteint.',
        );
      case '404':
      case '410':
        return StreamFailure(
          StreamFailureKind.removed,
          'Chaîne introuvable chez le fournisseur (code $code) : elle a '
          'sans doute été retirée ou renommée.',
        );
      default:
        return StreamFailure(
          StreamFailureKind.network,
          'Le serveur du fournisseur ne répond pas correctement '
          '(code $code).',
        );
    }
  }

  if (text.contains('UnknownHost') ||
      text.contains('ConnectException') ||
      text.contains('SocketTimeout') ||
      text.contains('SocketException') ||
      text.contains('TimeoutException') ||
      text.contains('Unable to connect') ||
      text.contains('Source error')) {
    return const StreamFailure(
      StreamFailureKind.network,
      'Problème réseau ou serveur : le flux ne répond pas. Vérifie la '
      'connexion, ou réessaie plus tard.',
    );
  }

  return const StreamFailure(
    StreamFailureKind.unknown,
    'Flux indisponible. Cause non identifiée.',
  );
}
