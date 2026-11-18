import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/video_error_state.dart';
import 'package:orbit_3d_flutter/features/player/playback_error_policy.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

class PlayerErrorView extends StatelessWidget {
  const PlayerErrorView({
    super.key,
    required this.externalPlaybackLaunched,
    this.greenScreenDetected = false,
    required this.errorDescription,
    required this.contentType,
    required this.onRetry,
    required this.onProviderWebsite,
    this.nextEpisodeTitle,
    this.nextEpisodeSeconds,
    this.nextEpisodeFocus,
    this.cancelNextEpisodeFocus,
    this.onNextEpisode,
    this.onCancelNextEpisode,
  });

  final bool externalPlaybackLaunched;
  final bool greenScreenDetected;
  final String? errorDescription;
  final PlaybackContentType contentType;
  final VoidCallback onRetry;
  final VoidCallback onProviderWebsite;
  final String? nextEpisodeTitle;
  final int? nextEpisodeSeconds;
  final FocusNode? nextEpisodeFocus;
  final FocusNode? cancelNextEpisodeFocus;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onCancelNextEpisode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final providerBlocked = isPlaybackProviderBlock(errorDescription);
    final cloudflare = isPlaybackCloudflareError(errorDescription);
    final isLive = contentType == PlaybackContentType.live;
    return VideoErrorState(
      title: greenScreenDetected
          ? l.greenScreenDetectedTitle
          : externalPlaybackLaunched
              ? 'Lecture ouverte dans un lecteur externe'
              : providerBlocked
                  ? 'Flux temporairement bloqué par le fournisseur'
                  : cloudflare
                      ? l.cloudflareCheckRequired
                      : isLive
                          ? 'Flux indisponible'
                          : l.playbackUnavailableTitle,
      message: greenScreenDetected
          ? l.greenScreenDetectedMessage
          : externalPlaybackLaunched
              ? 'Choisissez les pistes audio et les sous-titres dans le '
                  'lecteur externe : les préférences d’Orbit ne lui sont pas transmises.'
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
      additionalActions: externalPlaybackLaunched && onNextEpisode != null
          ? Column(
              children: [
                FilledButton(
                  focusNode: nextEpisodeFocus,
                  onPressed: onNextEpisode,
                  child: Text(
                    'Épisode suivant : $nextEpisodeTitle'
                    '${nextEpisodeSeconds == null ? '' : ' (${nextEpisodeSeconds!} s)'}',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (onCancelNextEpisode != null)
                  TextButton(
                    focusNode: cancelNextEpisodeFocus,
                    onPressed: onCancelNextEpisode,
                    child: Text(l.cancel),
                  ),
              ],
            )
          : null,
    );
  }
}
