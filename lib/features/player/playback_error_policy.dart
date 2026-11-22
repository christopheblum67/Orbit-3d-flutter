const protectedPlaybackUnsupported = 'protected-playback-unsupported';

/// Un échec de décodeur ne doit pas être assimilé à un blocage du serveur.
bool isPlaybackDecoderError(Object? error) {
  final message = '$error';
  return message.contains('MediaCodecVideoRenderer') ||
      message.contains('DecoderInitializationException') ||
      message.contains('Decoder init failed');
}

bool isPlaybackProviderBlock(String? description) {
  if (description == null || description.isEmpty) return false;
  return description.contains('401') || description.contains('Source error');
}

bool isPlaybackCloudflareError(String? description) {
  if (description == null || description.isEmpty) return false;
  final message = description.toLowerCase();
  return message.contains('403') ||
      message.contains('cloudflare') ||
      message.contains('challenge') ||
      message.contains('cf_clearance') ||
      message.contains('blocked') ||
      message.contains('access denied') ||
      message.contains('forbidden');
}

enum PlaybackRecoveryAction { retry, showError, externalIfConfigured }

/// Le challenge fournisseur a priorité sur les tentatives et le secours.
PlaybackRecoveryAction playbackRecoveryAction({
  required String? description,
  required int attempts,
}) {
  if (description == protectedPlaybackUnsupported) {
    return PlaybackRecoveryAction.showError;
  }
  if (isPlaybackCloudflareError(description)) {
    return PlaybackRecoveryAction.showError;
  }
  if (attempts < 2) return PlaybackRecoveryAction.retry;
  return isPlaybackDecoderError(description)
      ? PlaybackRecoveryAction.externalIfConfigured
      : PlaybackRecoveryAction.showError;
}
