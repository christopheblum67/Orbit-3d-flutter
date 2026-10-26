import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  const StartupSplashScreen({super.key});

  @override
  ConsumerState<StartupSplashScreen> createState() =>
      _StartupSplashScreenState();
}

class _StartupSplashScreenState extends ConsumerState<StartupSplashScreen> {
  late final StartupRefreshController _controller;
  bool _navigated = false;
  bool _cfLoading = false;

  @override
  void initState() {
    super.initState();
    final api = ref.read(apiServiceProvider);
    _controller = StartupRefreshController(
      api,
      epgCache: ref.read(epgDataCacheProvider),
    );
    _controller.addListener(_onProgress);
    // Lance le préchargement après le premier frame pour ne pas muter l'état
    // pendant la phase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _kickOff();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onProgress);
    _controller.dispose();
    super.dispose();
  }

  void _onProgress() {
    if (!mounted) return;
    setState(() {});
    if (_controller.isFinished && !_navigated) {
      _navigated = true;
      // Marque la mise à jour comme faite pour que le bouton d'accueil
      // affiche l'horodatage au lieu de « Jamais mis à jour ».
      ref
          .read(lastRefreshTimestampProvider.notifier)
          .setTimestamp(DateTime.now());
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/profiles');
      });
    }
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
            if (_cfLoading)
              Container(
                height: 4,
                color: Colors.cyanAccent,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
                ),
              ),
            Expanded(
              child: RefreshProgressView(
                percent: _controller.percent,
                currentStep: _controller.currentStep,
                doneSteps: _controller.doneSteps,
                isFinished: _controller.isFinished,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kickOff() async {
    // GARDE-FOU ABONNEMENT — interrogé EN PREMIER, avant le raz-de-marée de
    // requêtes catalogue déclenché par `_controller.start()`. Placé après, le
    // `get_user_info` partait en DERNIER et se faisait refuser par le panel
    // (`429`, quota déjà consommé) : `fetchExpiration` retombait sur `null` via
    // `safeAsync` et la validité n'était jamais mise à jour (« Sans limite »).
    await _refreshSubscriptionValidity();
    if (!mounted) return;
    await _controller.start();
    if (!mounted) return;
    // Initialise la session Cloudflare pour le zapping (cookies cf_clearance + UA).
    // Récupère l'URL de base du fournisseur IPTV actif.
    // ATTENDRE la fin de l'initialisation (max 30s) pour éviter "flux indisponible" au 1er play.
    setState(() => _cfLoading = true);
    await safeAsync(
      () async {
        final sub =
            await ref.read(subscriptionManagerProvider).getActiveSubscription();
        if (sub['type'] == 'xtream') {
          final baseUrl = 'https://${Uri.parse(sub['baseUrl']!).host}';
          await ref
              .read(cloudflareSessionProvider)
              .initialize(baseUrl: baseUrl)
              .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              debugPrint(
                '☁️ Cloudflare init timeout (60s) during splash, proceeding anyway...',
              );
            },
          );
        }
      },
      context: 'StartupSplashScreen Cloudflare session init',
    );
    if (mounted) setState(() => _cfLoading = false);
    // Auto-resume: check for last session playback progress
    if (mounted) {
      await _checkAutoResume();
    }
  }

  Future<void> _checkAutoResume() async {
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
      }
    }
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
}
