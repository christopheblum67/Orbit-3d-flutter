import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/features/player/widgets/stream_details_sheet.dart';
import 'package:orbit_3d_flutter/features/player/widgets/time_progress_bar.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Conteneur commun de la footerbar unifiée : barre basse translucide
/// arrondie, ancrée en bas (SafeArea), que l'on place en overlay du lecteur.
class ContentFooterBar extends StatelessWidget {
  const ContentFooterBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Icône compacte de la footerbar (blanche sur fond translucide).
Widget _fbIcon(
  IconData icon,
  VoidCallback? onPressed, {
  String? tooltip,
  Color color = Colors.white,
  double size = 22,
}) {
  return IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
    style: _fbFocusStyle(color),
    onPressed: onPressed,
    icon: Icon(icon, size: size),
  );
}

/// Style D-pad des icônes de la footerbar : fond ambre, icône noire et bordure
/// blanche quand le bouton a le focus, pour qu'on voie où l'on se trouve.
ButtonStyle _fbFocusStyle(Color normal) {
  return ButtonStyle(
    iconColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.focused) ? Colors.black : normal,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.focused) ? const Color(0xFFFFC107) : null,
    ),
    side: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.focused)
          ? const BorderSide(color: Colors.white, width: 2)
          : null,
    ),
  );
}

/// Bouton pause/lecture proéminent de la footerbar.
Widget _fbPlayPause({
  required bool isPlaying,
  required VoidCallback onPressed,
  required AppLocalizations l,
  FocusNode? focusNode,
}) {
  return IconButton(
    focusNode: focusNode,
    tooltip: isPlaying ? l.playerPause : l.play,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.22),
    ).merge(_fbFocusStyle(Colors.white)),
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints(minWidth: 46, minHeight: 44),
    onPressed: onPressed,
    icon: Icon(
      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: 28,
    ),
  );
}

/// Icône Night Focus de la footerbar : l'icône et la couleur changent selon
/// l'état ON/OFF du maître (toggle direct, sans ouvrir de sous-menu).
Widget _fbNightFocus({
  required VoidCallback onPressed,
  required WidgetRef ref,
  required AppLocalizations l,
}) {
  final enabled = ref.watch(
    advancedSettingsProvider.select((s) => s.nightFocusEnabled),
  );
  return IconButton(
    tooltip: enabled ? l.playerNightFocusOn : l.playerNightFocusOff,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
    style: _fbFocusStyle(enabled ? const Color(0xFFFFC107) : Colors.white70),
    onPressed: onPressed,
    icon: Icon(
      enabled ? Icons.nightlight_round : Icons.nightlight_outlined,
      size: 22,
    ),
  );
}

/// Petit badge numéro de chaîne / étiquette genre (#num ou chip métadonnée).
class _ChannelBadge extends StatelessWidget {
  const _ChannelBadge({
    required this.label,
    this.color = const Color(0xFF4FC3F7),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Barre de progression du programme EPG en cours : (now - start)/(end - start).
class _LiveProgressBar extends StatelessWidget {
  const _LiveProgressBar({required this.program});

  final EPGProgram program;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalMs = program.end.difference(program.start).inMilliseconds;
    var ratio = 0.0;
    if (totalMs > 0) {
      ratio = now.difference(program.start).inMilliseconds / totalMs;
    }
    ratio = ratio.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 4,
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
      ),
    );
  }
}

/// Rangée de contrôles de seek : 2x retour rapide / play-pause / 2x avance rapide.
/// Vitesses : -10s / -30s  |  play/pause  |  +10s / +30s
/// Footerbar Live / Replay : nom de chaîne + #numéro + EPG (titre/horaires
/// + progression du programme) puis actions (zapping, pause/play, seek si
/// replay, menu détails du flux, Night Focus, retour).
class LiveFooterBar extends ConsumerWidget {
  const LiveFooterBar({
    super.key,
    required this.channel,
    required this.fallbackTitle,
    this.subtitle,
    this.controller,
    required this.index,
    required this.total,
    required this.isPlaying,
    required this.showSeek,
    required this.onExit,
    this.onPrevious,
    this.onNext,
    required this.onTogglePlayPause,
    this.playPauseFocusNode,
    this.onPip,
    this.onSeekBack30,
    this.onSeekForward30,
    this.castButton,
    required this.streamDetails,
    required this.onToggleNightFocus,
    this.onProgressInteraction,
  });

  final Channel? channel;
  final String fallbackTitle;
  final String? subtitle;
  final VideoPlayerController? controller;
  final int index;
  final int total;
  final bool isPlaying;
  final bool showSeek;
  final VoidCallback onExit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onTogglePlayPause;
  final FocusNode? playPauseFocusNode;
  final VoidCallback? onPip;
  final VoidCallback? onSeekBack30;
  final VoidCallback? onSeekForward30;
  final Widget? castButton;
  final FooterStreamDetails streamDetails;
  final VoidCallback onToggleNightFocus;
  final VoidCallback? onProgressInteraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final currentChannel = channel;
    final epgAsync = currentChannel != null
        ? ref.watch(channelEpgProvider(currentChannel.primaryEpgChannelId))
        : null;
    final (nowProgram, nextProgram) = currentChannel != null && epgAsync != null
        ? _nowAndNext(epgAsync.value ?? const [])
        : (null, null);
    final channelName = currentChannel?.name ?? fallbackTitle;
    final canZap = total > 1;
    final player = controller;
    final hasEpg =
        currentChannel != null && (nowProgram != null || nextProgram != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (currentChannel != null)
              _ChannelBadge(
                label:
                    '#${currentChannel.orderNum > 0 ? currentChannel.orderNum : index + 1}',
              ),
            if (currentChannel != null) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canZap)
              Text(
                '${index + 1} / $total',
                style: const TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
          ],
        ),
        if (hasEpg) ...[
          const SizedBox(height: 8),
          _EpgRow(now: nowProgram, next: nextProgram),
          if (nowProgram != null) ...[
            const SizedBox(height: 8),
            _LiveProgressBar(program: nowProgram),
          ],
        ] else if (currentChannel != null &&
            epgAsync != null &&
            epgAsync.isLoading) ...[
          const SizedBox(height: 8),
          Text(
            l.playerLoadingProgram,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
        if (showSeek && player != null) ...[
          const SizedBox(height: 8),
          TimeProgressBar(
            controller: player,
            allowScrubbing: true,
            onInteraction: onProgressInteraction,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            _fbIcon(Icons.arrow_back_rounded, onExit,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip),
            const Spacer(),
            if (onPrevious != null)
              _fbIcon(
                Icons.skip_previous_rounded,
                onPrevious,
                tooltip: l.previousChannel,
              ),
            if (showSeek)
              _fbIcon(
                Icons.replay_30,
                onSeekBack30,
                tooltip: l.rewind30s,
                color: Colors.white,
              ),
            _fbPlayPause(
              l: l,
              isPlaying: isPlaying,
              onPressed: onTogglePlayPause,
              focusNode: playPauseFocusNode,
            ),
            if (showSeek) ...[
              _fbIcon(
                Icons.forward_30,
                onSeekForward30,
                tooltip: l.forward30s,
                color: Colors.white,
              ),
            ],
            if (onNext != null)
              _fbIcon(
                Icons.skip_next_rounded,
                onNext,
                tooltip: l.nextChannel,
              ),
            const SizedBox(width: 8),
            _fbNightFocus(onPressed: onToggleNightFocus, ref: ref, l: l),
            if (onPip != null)
              _fbIcon(
                Icons.picture_in_picture_alt_rounded,
                onPip,
                tooltip: l.pip,
              ),
            if (castButton != null) castButton!,
            streamDetails,
          ],
        ),
      ],
    );
  }
}

/// Footerbar VOD / Séries : titre + note ★ + genre (+ épisode), barre de
/// progression de lecture puis 2x retour / play-pause / 2x avance, et menu
/// détails du flux / Night Focus.
class VodFooterBar extends ConsumerWidget {
  const VodFooterBar({
    super.key,
    required this.controller,
    required this.title,
    this.rating,
    this.genre,
    this.subtitle,
    this.seriesName,
    this.episodeLabel,
    required this.isPlaying,
    required this.onExit,
    required this.onTogglePlayPause,
    this.playPauseFocusNode,
    required this.onSeekBack30,
    required this.onSeekForward30,
    this.onPip,
    this.castButton,
    required this.streamDetails,
    required this.onToggleNightFocus,
    required this.onProgressInteraction,
  });

  final VideoPlayerController controller;
  final String title;
  final double? rating;
  final String? genre;
  final String? subtitle;
  final String? seriesName;
  final String? episodeLabel;
  final bool isPlaying;
  final VoidCallback onExit;
  final VoidCallback onTogglePlayPause;
  final FocusNode? playPauseFocusNode;
  final VoidCallback? onPip;
  final VoidCallback onSeekBack30;
  final VoidCallback onSeekForward30;
  final Widget? castButton;
  final FooterStreamDetails streamDetails;
  final VoidCallback onToggleNightFocus;
  final VoidCallback onProgressInteraction;

  String? get _subLine {
    if (seriesName != null && episodeLabel != null) {
      return '$seriesName · $episodeLabel';
    }
    return episodeLabel ??
        (subtitle != null && subtitle!.isNotEmpty ? subtitle : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final showRating = rating != null && rating! > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_subLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showRating) ...[
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(width: 4),
              Text(
                rating!.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (genre != null && genre!.isNotEmpty) ...[
              const SizedBox(width: 8),
              _ChannelBadge(label: genre!, color: scheme.tertiary),
            ],
          ],
        ),
        const SizedBox(height: 10),
        TimeProgressBar(
          controller: controller,
          allowScrubbing: true,
          onInteraction: onProgressInteraction,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _fbIcon(Icons.arrow_back_rounded, onExit,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip),
            const Spacer(),
            _fbIcon(
              Icons.replay_30,
              onSeekBack30,
              tooltip: l.rewind30s,
              color: Colors.white,
            ),
            _fbPlayPause(
              l: l,
              isPlaying: isPlaying,
              onPressed: onTogglePlayPause,
              focusNode: playPauseFocusNode,
            ),
            _fbIcon(
              Icons.forward_30,
              onSeekForward30,
              tooltip: l.forward30s,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            _fbNightFocus(onPressed: onToggleNightFocus, ref: ref, l: l),
            if (onPip != null)
              _fbIcon(
                Icons.picture_in_picture_alt_rounded,
                onPip,
                tooltip: l.pip,
              ),
            if (castButton != null) castButton!,
            streamDetails,
          ],
        ),
      ],
    );
  }
}

/// Icône ⚙️ de la footerbar : ouvre le panneau « Détails du flux » (pistes
/// audio / qualité vidéo / sous-titres).
///
/// Tant que la sous-fenêtre est ouverte on gèle le timer d'auto-masquage (via
/// [onOpened]) et on le relance à la fermeture ([onClosed]).
class FooterStreamDetails extends StatelessWidget {
  const FooterStreamDetails({
    super.key,
    required this.controller,
    required this.mediaKey,
    required this.isLive,
    required this.onOpened,
    required this.onClosed,
  });

  final VideoPlayerController controller;
  final String? mediaKey;
  final bool isLive;
  final VoidCallback onOpened;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return IconButton(
      tooltip: l.streamDetails,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      style: _fbFocusStyle(Colors.white),
      onPressed: () async {
        onOpened();
        await showStreamDetailsSheet(
          context,
          controller,
          mediaKey ?? '',
          isLive: isLive,
        );
        if (context.mounted) onClosed();
      },
      icon: const Icon(Icons.settings_rounded, size: 22),
    );
  }
}

class _EpgRow extends StatelessWidget {
  const _EpgRow({required this.now, required this.next});

  final EPGProgram? now;
  final EPGProgram? next;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = now;
    if (current == null) {
      return const Row(
        children: [
          Icon(Icons.tv_off_rounded, size: 14, color: Colors.white54),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Programme non disponible',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.graphic_eq_rounded, size: 14, color: scheme.tertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${_fmt(current.start)} - ${_fmt(current.end)}   ${current.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (next != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Colors.white54,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Suivant : ${_fmt(next!.start)}   ${next!.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

(EPGProgram?, EPGProgram?) _nowAndNext(List<EPGProgram> programs) =>
    epgCurrentAndNext(programs, DateTime.now());

String _fmt(DateTime time) => DateFormat('HH:mm').format(time);
