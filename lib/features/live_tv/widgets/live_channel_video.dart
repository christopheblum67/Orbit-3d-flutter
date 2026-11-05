import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

/// Cadre de diffusion EN COURS de la chaîne sélectionnée.
///
/// ## Pourquoi un vrai flux
///
/// L'aperçu montre la diffusion en direct : c'est ce qui permet de choisir une
/// chaîne sans jongler entre le lecteur plein écran et la grille. Conséquence
/// directe, le lecteur est **muet** (parcourir les chaînes ne doit déclencher
/// aucun son) et isolé (`mixWithOthers: false`).
///
/// ## Pourquoi un délai avant d'ouvrir
///
/// La navigation D-pad fait défiler la liste chaîne après chaîne. Créer un
/// ExoPlayer à chaque changement de focus ouvrirait une requête HTTP par
/// chaîne parcourue — exactement ce qui déclenche l'anti-leech du panneau. On
/// attend que la sélection se stabilise avant d'émettre.
///
/// Nœud de focus du bouton « Regarder » : la liste de chaînes y envoie le
/// focus sur la flèche droite, car la recherche directionnelle seule ne
/// l'atteignait pas depuis les chaînes du haut de la liste.
final FocusNode liveWatchFocusNode = FocusNode(debugLabel: 'LiveWatchButton');

class LiveChannelVideo extends ConsumerStatefulWidget {
  const LiveChannelVideo({
    super.key,
    required this.channel,
    this.onWatch,
    this.active = true,
  });

  final Channel channel;

  /// `false` quand un autre écran (lecteur plein écran) recouvre l'aperçu : le
  /// flux est alors fermé pour ne pas jouer deux fois la même diffusion.
  final bool active;

  /// Action de lecture plein écran (superposée sur le cadre).
  final VoidCallback? onWatch;

  @override
  ConsumerState<LiveChannelVideo> createState() => _LiveChannelVideoState();
}

class _LiveChannelVideoState extends ConsumerState<LiveChannelVideo> {
  /// Délai de stabilisation de la sélection avant d'ouvrir le flux.
  static const Duration _startDelay = Duration(milliseconds: 450);

  /// Délai maximal d'initialisation : l'aperçu affiche un message au lieu de
  /// rester indéfiniment en chargement.
  static const Duration _initTimeout = Duration(seconds: 15);

  /// Volume de l'aperçu. L'aperçu est sonore (voir [_startDelay] pour le
  /// risque de rafales).
  static const double _previewVolume = 1.0;

  VideoPlayerController? _controller;
  Timer? _startTimer;
  int _generation = 0;
  bool _failed = false;
  bool _decoderUnsupported = false;

  /// L'aperçu était auparavant non surveillé : un gel y restait muet, alors
  /// que le lecteur principal, lui, remontait un message. Même traitement
  /// qu'ailleurs, avec des seuils plus courts (l'aperçu n'a pas besoin
  /// d'attendre 15 s pour qu'on sache qu'il ne va pas).
  late final StallDetector _stallDetector = StallDetector(
    checkInterval: const Duration(seconds: 3),
    stallThreshold: const Duration(seconds: 9),
    minChecksForStall: 3,
  )..addListener(_onStallChanged);
  void _onStallChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _scheduleStart();
  }

  @override
  void didUpdateWidget(LiveChannelVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) {
      if (oldWidget.active) _suspend();
    } else if (!oldWidget.active ||
        oldWidget.channel.streamUrl != widget.channel.streamUrl) {
      _scheduleStart();
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _stallDetector
      ..removeListener(_onStallChanged)
      ..dispose();
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    // Le détecteur ne doit jamais rester attaché à un contrôleur détruit.
    _stallDetector.stop();
    c?.dispose();
  }

  void _suspend() {
    _startTimer?.cancel();
    _generation++;
    _disposeController();
    setState(() => _failed = false);
  }

  void _scheduleStart() {
    _startTimer?.cancel();
    _disposeController();
    _failed = false;
    _decoderUnsupported = false;
    final gen = ++_generation;
    if (mounted) setState(() {});
    if (!widget.active) return;
    _startTimer = Timer(_startDelay, () => _start(gen));
  }

  Future<void> _start(int gen) async {
    final channel = widget.channel;
    if (gen != _generation || !mounted) return;

    // Le profil media3 est lu à la CONSTRUCTION de l'ExoPlayer : le push
    // précède la création, sans quoi l'aperçu tournerait avec les seuils par
    // défaut (tampons de 50 s) et sans plafond de résolution.
    try {
      await PlayerProfileService.pushForDevice(
        ref.read(deviceProfileProvider),
      );
    } catch (error) {
      LoggerService.instance.warning(
        'Live preview profile unavailable (${error.runtimeType})',
      );
    }
    if (gen != _generation || !mounted) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(channel.streamUrl),
      httpHeaders: streamHeaders(channel.streamUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );

    final result = await safeAsync(
      () => controller.initialize().timeout(_initTimeout),
      context: 'LiveChannelVideo.start',
    );
    // La sélection a changé (ou le widget est parti) pendant l'init : on jette.
    if (gen != _generation || !mounted) {
      controller.dispose();
      return;
    }
    if (result.isFailure || controller.value.hasError) {
      final detail =
          '${result.errorOrNull} ${controller.value.errorDescription}';
      controller.dispose();
      if (mounted) {
        setState(() {
          _failed = true;
          _decoderUnsupported = detail.contains('MediaCodecVideoRenderer') ||
              detail.contains('Decoder init failed') ||
              detail.contains('Decoder failed');
        });
      }
      return;
    }

    // L'aperçu est SONORE : c'est le but —-on écoute la chaîne pour savoir ce
    // qu'on regarde, comme avec une vraie télé. C'est le délai de
    // stabilisation ([_startDelay]) qui évite les rafales de son : le flux
    // n'est ouvert qu'après 450 ms de sélection stable, donc défiler vite avec
    // le D-pad n'émet aucun son, seule la chaîne sur laquelle on s'arrête
    // joue. `mixWithOthers: false` empêche par ailleurs de superposer cette
    // diffusion à une autre application.
    try {
      await controller.setVolume(_previewVolume);
      await controller.play();
    } catch (error) {
      LoggerService.instance.warning(
        'Live preview playback failed (${error.runtimeType})',
      );
      controller.dispose();
      if (gen == _generation && mounted) setState(() => _failed = true);
      return;
    }
    if (gen != _generation || !mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    // L'aperçu est surveillé comme le lecteur : sans cela un gel y restait
    // totalement muet, alors que le lecteur principal signalait le sien.
    _stallDetector.start(VideoPlayerWatchable(controller));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;

    final Widget content;
    if (controller != null && controller.value.isInitialized) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          // Gel constaté : on le dit, et on propose de relancer. Sans cela
          // l'aperçu restait figé sans aucune explication.
          if (_stallDetector.isStalling) _StaleOverlay(onRetry: _scheduleStart),
        ],
      );
    } else if (_failed) {
      content = _Message(
        icon: Icons.tv_off_rounded,
        text: _decoderUnsupported
            ? 'Format vidéo (4K / HEVC) non pris en charge par ce téléviseur'
            : 'Flux indisponible',
        color: scheme.onSurfaceVariant,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 10),
          Text(
            widget.channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.white70),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: content),
          if (widget.onWatch != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: _WatchButton(onPressed: widget.onWatch!),
            ),
        ],
      ),
    );
  }
}

/// Voile affiché quand l'aperçu est gelé, avec une relance.
class _StaleOverlay extends StatelessWidget {
  const _StaleOverlay({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              color: Colors.white,
              size: 34,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aperçu figé',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Relancer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: scheme.outlineVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchButton extends StatelessWidget {
  const _WatchButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: liveWatchFocusNode,
      builder: (context, _) {
        final focused = liveWatchFocusNode.hasFocus;
        return AnimatedScale(
          scale: focused ? 1.3 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: focused
                  ? const [
                      BoxShadow(
                        color: Color(0xFFFFC107),
                        blurRadius: 22,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: FilledButton.icon(
              focusNode: liveWatchFocusNode,
              onPressed: onPressed,
              icon: Icon(Icons.play_arrow_rounded, size: focused ? 34 : 24),
              label: Text(
                focused ? 'REGARDER' : 'Regarder',
                style: TextStyle(
                  fontWeight: focused ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: focused ? 1.2 : 0,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor:
                    focused ? const Color(0xFFFFC107) : scheme.primary,
                foregroundColor: focused ? Colors.black : scheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                visualDensity: VisualDensity.compact,
              ).copyWith(
                side: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? const BorderSide(color: Colors.white, width: 4)
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 34),
        const SizedBox(height: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
