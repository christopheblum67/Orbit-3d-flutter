import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Écran de démarrage : régénère les flux d'abonnement et affiche leur
/// progression (Chaînes TV / Films & VOD / Séries / EPG).
///
/// ## Ce que l'écran affiche
///
/// Uniquement le nom de l'application (« Orbit IPTV ») et la progression des
/// sections d'abonnement, via [RefreshProgressView] — le même composant que le
/// rafraîchissement à la demande. Le carrousel de recommandations (« Pour
/// vous ») a été retiré : il dupliquait une sélection disponible dans
/// l'application et détournait l'attention de la seule information utile ici,
/// l'avancement de la mise à jour.
class StartupSplashScreen extends ConsumerStatefulWidget {
  const StartupSplashScreen({super.key, this.remainingPhase = false});

  final bool remainingPhase;

  @override
  ConsumerState<StartupSplashScreen> createState() =>
      _StartupSplashScreenState();
}

class _StartupSplashScreenState extends ConsumerState<StartupSplashScreen> {
  late final StartupRefreshController _controller;
  Timer? _stallTimer;
  bool _navigated = false;
  bool _showBranding = false;
  bool _refreshStalled = false;

  @override
  void initState() {
    super.initState();
    final api = ref.read(apiServiceProvider);
    _controller = StartupRefreshController(
      api,
      loadLiveChannels: () => ref.read(liveChannelsProvider.future),
      loadMovies: () => ref.read(moviesProvider.future),
      loadSeries: () => ref.read(seriesProvider.future),
      loadRadioChannels: () => ref.read(radioChannelsProvider.future),
      epgCache: ref.read(epgDataCacheProvider),
      steps: widget.remainingPhase
          ? StartupRefreshController.remainingSteps
          : StartupRefreshController.initialSteps,
    );
    _controller.addListener(_onProgress);
    _armStallTimer();
    // Lance le préchargement après le premier frame pour ne pas muter l'état
    // pendant la phase de build. Le branding est monté à partir de la frame
    // suivante pour alléger le rendu initial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showBranding = true);
        _kickOff();
      }
    });
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    _controller.removeListener(_onProgress);
    _controller.dispose();
    super.dispose();
  }

  void _onProgress() {
    if (!mounted) return;
    _stallTimer?.cancel();
    setState(() => _refreshStalled = false);
    _armStallTimer();
    if (_controller.isFinished && !_navigated) {
      _navigated = true;
      if (widget.remainingPhase) {
        _finishRemainingPhase();
      } else {
        _finishInitialPhase();
      }
    }
  }

  void _armStallTimer() {
    _stallTimer?.cancel();
    if (_controller.isFinished) return;
    _stallTimer = Timer(kRefreshStallTimeout, () {
      if (mounted && !_controller.isFinished) {
        setState(() => _refreshStalled = true);
      }
    });
  }

  Future<void> _finishInitialPhase() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go('/profiles?startup=true');
  }

  Future<void> _finishRemainingPhase() async {
    ref
        .read(lastRefreshTimestampProvider.notifier)
        .setTimestamp(DateTime.now());
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final resumed = await _checkAutoResume();
    if (!mounted || resumed) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    // Initialise le certificate pinning depuis les réglages avancés
    ref.watch(certificatePinningInitializerProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshProgressView(
                percent: _controller.percent,
                currentStep: _controller.currentStep,
                doneSteps: _controller.doneSteps,
                isFinished: _controller.isFinished,
                title: widget.remainingPhase
                    ? 'Chargement des radios et replays'
                    : 'Chargement du direct, des films, séries et du guide TV',
                visibleSteps: widget.remainingPhase
                    ? StartupRefreshController.remainingSteps.toList()
                    : StartupRefreshController.initialSteps.toList(),
                showBranding: _showBranding,
                failureMessage: _refreshStalled
                    ? _stalledMessage(_controller.currentStep?.label)
                    : null,
                onOpenSubscriptions:
                    _refreshStalled ? () => context.go('/subscriptions') : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kickOff() async {
    if (!widget.remainingPhase) {
      // Check subscription validity before starting the catalog requests.
      await _refreshSubscriptionValidity();
    }
    if (!mounted) return;
    await _controller.start();
  }

  Future<bool> _checkAutoResume() async {
    final progress =
        ref.read(playbackProgressServiceProvider).get('last_session');
    if (progress != null &&
        progress.positionMs > 60000 &&
        progress.hasProgress) {
      final title = _getResumeTitle(progress);
      final timestamp = _formatTimestamp(progress.positionMs);

      final cancelFocus = FocusNode();
      final confirmFocus = FocusNode();

      void requestFocus(FocusNode focus) {
        if (mounted) {
          FocusScope.of(context).requestFocus(focus);
        }
      }

      final shouldResume = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final l = AppLocalizations.of(ctx);
          return AlertDialog(
            backgroundColor: const Color(0xFF1E222D),
            title: Text(
              l.resumePlayback,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              'Reprendre "$title" à $timestamp ?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              Focus(
                focusNode: cancelFocus,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                    Navigator.pop(ctx, false);
                    return KeyEventResult.handled;
                  }
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                          event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                    requestFocus(confirmFocus);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    l.later,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              Focus(
                focusNode: confirmFocus,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                    Navigator.pop(ctx, true);
                    return KeyEventResult.handled;
                  }
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                          event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                    requestFocus(cancelFocus);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00CFE8),
                  ),
                  child: const Text(
                    'Reprendre',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          );
        },
      );
      cancelFocus.dispose();
      confirmFocus.dispose();
      if (shouldResume == true && mounted) {
        context.go(
          '/player',
          extra: PlayerRouteData(
            streamUrl: '',
            title: title,
            initialPositionMs: progress.positionMs,
            progressId: 'last_session',
          ),
        );
        return true;
      }
    }
    return false;
  }

  String _getResumeTitle(PlaybackProgress progress) {
    // Try to get title from recently watched history
    final history = ref.read(mediaLibraryManagerProvider).recentlyWatched;
    if (history.isNotEmpty) {
      return history.first.title;
    }
    return 'Dernière session';
  }

  String _formatTimestamp(int positionMs) {
    final minutes = (positionMs / 60000).floor();
    final seconds = ((positionMs % 60000) / 1000).floor();
    return '${minutes}m ${seconds}s';
  }

  Future<void> _refreshSubscriptionValidity() async {
    await safeAsync(
      () async {
        // Attend la résolution du provider actif
        final active = ref.read(activeSubscriptionProvider);
        if (active != null && active.type == SubscriptionType.xtream) {
          await ref
              .read(subscriptionsProvider.notifier)
              .refreshValidity(active.id, api: ref.read(apiServiceProvider));
        }
      },
      context: '_refreshSubscriptionValidity',
    );
    // Non bloquant : l'affichage retombera sur « Sans limite ».
  }

  String _stalledMessage(String? step) {
    final label =
        step == null ? 'la vérification de l’abonnement' : '« $step »';
    return '$label ne signale aucune progression depuis '
        '${kRefreshStallTimeout.inSeconds} secondes. Le serveur peut être '
        'lent ou indisponible ; vous pouvez vérifier l’abonnement.';
  }
}
