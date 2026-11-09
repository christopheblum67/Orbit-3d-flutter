import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/video_error_state.dart';
import 'package:orbit_3d_flutter/features/player/playback_error_policy.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

class PlayerErrorView extends StatelessWidget {
  const PlayerErrorView({
    super.key,
    required this.externalPlaybackLaunched,
    required this.errorDescription,
    required this.contentType,
    required this.onRetry,
    required this.onProviderWebsite,
  });

  final bool externalPlaybackLaunched;
  final String? errorDescription;
  final PlaybackContentType contentType;
  final VoidCallback onRetry;
  final VoidCallback onProviderWebsite;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final providerBlocked = isPlaybackProviderBlock(errorDescription);
    final cloudflare = isPlaybackCloudflareError(errorDescription);
    final isLive = contentType == PlaybackContentType.live;
    return VideoErrorState(
      title: externalPlaybackLaunched
          ? 'Lecture ouverte dans un lecteur externe'
          : providerBlocked
              ? 'Flux temporairement bloqué par le fournisseur'
              : cloudflare
                  ? l.cloudflareCheckRequired
                  : isLive
                      ? 'Flux indisponible'
                      : l.playbackUnavailableTitle,
      message: externalPlaybackLaunched
          ? 'De retour dans Orbit, vous pouvez réessayer la lecture.'
          : providerBlocked
              ? 'La lecture a été coupée par la protection anti-leech '
                  'du serveur. Patientez 3 à 5 minutes sans lecture, '
                  'puis relancez cette chaîne (sans zapper).'
              : cloudflare
                  ? l.cloudflareChallengeHelp
                  : isLive
                      ? 'Impossible de lancer cette chaîne. '
                          'Vérifie ton abonnement ou réessaie.'
                      : l.playbackUnavailableMessage,
      onRetry: onRetry,
      autoFocusRetry: true,
      onProviderWebsite: cloudflare ? onProviderWebsite : null,
    );
  }
}
