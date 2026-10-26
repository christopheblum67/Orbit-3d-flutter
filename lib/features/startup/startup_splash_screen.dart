import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';
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
///
/// ## Première frame allégée
///
/// Le logo animé n'est monté qu'après le premier frame (flag [_showBranding]) :
/// la première frame ne construit pas le sous-arbre Image + BoxShadow + Text
/// animé, ce qui réduit le coût de rendu initial. L'animation démarre dès la
/// frame suivante, imperceptibleément plus tard.
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

  /// Le logo animé n'est monté qu'après la première frame (première frame allégée).
  bool _showBranding = false;

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
    // pendant la phase de build. La première frame est allégée (pas de logo
    // animé), le branding est activé dès la frame suivante.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showBranding = true);
        _kickOff();
      }
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
    try {
      setState(() {});
    } catch (e, st) {
      // Capture l'erreur "Bad state: No element" qui peut provenir d'un
      // firstWhere sans orElse dans l'arbre de widgets pendant le rebuild.
      // On loggue et on continue pour ne pas crasher l'app.
      LoggerService.instance.error(
        '_onProgress setState crashed',
        error: e,
        stackTrace: st,
      );
    }
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

    // Sur TV : redirige vers l'écran de pré-configuration TV si pas déjà fait
    final isTv = ref.watch(tvModeProvider);
    if (isTv) {
      final preconfigAsync = ref.watch(tvPreconfigDoneProvider);
      if (preconfigAsync.hasValue && preconfigAsync.value == false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/tv-preconfig');
        });
        return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      body: TvSafeArea(
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
                showBranding: _showBranding,
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

  // Micro-optimisations post-chargement (gain de temps après le splash)
  // 1. Pré-charger les posters des premiers films visibles
  final movies = ref.read(moviesProvider).value ?? [];
  for (final m in movies.take(20)) {
    if (m.posterUrl.isNotEmpty && mounted) {
      precacheImage(NetworkImage(m.posterUrl), context);
    }
  }
  // 2. Pré-résoudre l'EPG des 10 premières chaînes visibles
  final channels = ref.read(liveChannelsProvider).value ?? [];
  final firstChannels = channels.take(10).toList();
  if (firstChannels.isNotEmpty) {
    unawaited(ref.read(epgResolverServiceProvider).resolveBatch(
      channels: firstChannels,
      includePast: false,
    ));
  }
  // 3. Pré-ouvrir les boîtes Hive fréquemment utilisées
  unawaited(Hive.openBox('epg_cache'));
  unawaited(Hive.openBox('favorites'));
  unawaited(Hive.openBox('recently_watched'));
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
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint(
                '☁️ Cloudflare init timeout (15s) during splash, proceeding anyway...',
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
    final progress = ref.read(playbackProgressProvider('last_session'));
    if (progress != null &&
        progress.positionMs > 60000 &&
        progress.hasProgress) {
      final title = _getResumeTitle(progress);
      final timestamp = _formatTimestamp(progress.positionMs);

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
              FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TvFocus(
                      onActivate: () => Navigator.pop(ctx, false),
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          l.later,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TvFocus(
                      autofocus: true,
                      onActivate: () => Navigator.pop(ctx, true),
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
                ),
              ),
            ],
          );
        },
      );
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
