import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/services/refresh_freshness.dart';
import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
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
  Timer? _slowTimer;
  StreamSubscription<void>? _m3uParsingSubscription;
  bool _providerSlow = false;
  bool _navigated = false;
  bool _finishing = false;
  bool _invalidConfiguration = false;
  bool _abandoned = false;
  bool _showBranding = false;
  bool _refreshStalled = false;
  final Stopwatch _splashWatch = Stopwatch()..start();
  final Completer<void> _disposedSignal = Completer<void>();
  String? _startingSubscriptionId;
  Future<bool>? _configurationCheck;
  Future<void>? _sessionPreparation;

  @override
  void initState() {
    super.initState();
    _startingSubscriptionId = ref.read(activeSubscriptionProvider)?.id;
    final api = ref.read(apiServiceProvider);
    // Le container survit au splash : le préchargement différé des catalogues
    // continue après la navigation vers l'accueil.
    final container = ProviderScope.containerOf(context, listen: false);
    _controller = StartupRefreshController(
      api,
      loadLiveChannels: () => container.read(liveChannelsProvider.future),
      loadMovies: () => container.read(moviesProvider.future),
      loadSeries: () => container.read(seriesProvider.future),
      loadRadioChannels: () => container.read(radioChannelsProvider.future),
      epgCache: ref.read(epgDataCacheProvider),
      deferredStillValid: () =>
          !_invalidConfiguration &&
          !_abandoned &&
          container.read(activeSubscriptionProvider)?.id ==
              _startingSubscriptionId,
      steps: widget.remainingPhase
          ? StartupRefreshController.remainingSteps
          : StartupRefreshController.initialSteps,
    );
    _controller.addListener(_onProgress);
    _m3uParsingSubscription =
        ref.read(m3uParsingEventsProvider).stream.listen((_) {
      if (mounted &&
          ref.read(activeSubscriptionProvider)?.id == _startingSubscriptionId &&
          ref.read(activeSubscriptionProvider)?.type == SubscriptionType.m3u) {
        _controller.markPlaylistParsing();
      }
    });
    _armStallTimer();
    // Lance le préchargement après le premier frame pour ne pas muter l'état
    // pendant la phase de build. Le branding est monté à partir de la frame
    // suivante pour alléger le rendu initial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.remainingPhase) {
        // Tout est déjà chargé : plus de second écran de chargement après le
        // choix du profil.
        _navigated = true;
        _finishRemainingPhase();
        return;
      }
      _sessionPreparation = _prepareSession();
      if (_startingSubscriptionId != null &&
          _startingSubscriptionId!.isNotEmpty &&
          ref.read(activeSubscriptionProvider)?.id == _startingSubscriptionId &&
          isSubscriptionRefreshFresh(ref.read(lastRefreshTimestampProvider))) {
        unawaited(_openFreshProfiles());
        return;
      }
      setState(() => _showBranding = true);
      _kickOff();
    });
  }

  @override
  void dispose() {
    _disposedSignal.complete();
    _stallTimer?.cancel();
    _slowTimer?.cancel();
    unawaited(_m3uParsingSubscription?.cancel());
    _controller.removeListener(_onProgress);
    _controller.dispose();
    super.dispose();
  }

  void _onProgress() {
    if (!mounted) return;
    _stallTimer?.cancel();
    setState(() {
      _refreshStalled = false;
      _providerSlow = false;
    });
    _armStallTimer();
    if (_controller.isFinished && !_navigated && !_finishing) {
      _finishing = true;
      if (widget.remainingPhase) {
        _navigated = true;
        _finishRemainingPhase();
      } else {
        _finishInitialPhase();
      }
    }
  }

  void _armStallTimer() {
    _stallTimer?.cancel();
    _slowTimer?.cancel();
    if (_controller.isFinished) return;
    // Signal précoce : un fournisseur derrière Cloudflare peut mettre du temps
    // à répondre ; on le dit bien avant l'alerte de blocage.
    _slowTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_controller.isFinished) {
        logDiag(
          'STARTUP slowMessageShown step=${_controller.currentStep?.name} '
          'afterMs=${_splashWatch.elapsedMilliseconds}',
        );
        setState(() => _providerSlow = true);
      }
    });
    _stallTimer = Timer(kRefreshStallTimeout, () {
      if (mounted && !_controller.isFinished) {
        setState(() => _refreshStalled = true);
      }
    });
  }

  Future<void> _finishInitialPhase() async {
    final invalid = await _configurationCheck;
    await _sessionPreparation;
    if (!mounted || _navigated) return;
    if (invalid == true &&
        ref.read(activeSubscriptionProvider)?.id == _startingSubscriptionId) {
      _openInvalidSubscription();
      return;
    }
    _navigated = true;
    // Le catalogue vient d'être chargé : horodater tout de suite évite qu'un
    // rafraîchissement « périmé » ne relance un second chargement complet.
    final subscription = ref.read(activeSubscriptionProvider);
    if (subscription?.id == _startingSubscriptionId) {
      ref.read(startupRefreshAttemptProvider.notifier).markCompleted();
    }
    if (_controller.error == null &&
        _controller.hasCatalogData &&
        subscription != null &&
        subscription.id.isNotEmpty &&
        subscription.id == _startingSubscriptionId) {
      ref.read(lastRefreshTimestampProvider.notifier).setTimestamp(
            DateTime.now(),
            subscriptionId: subscription.id,
          );
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    logDiag('STARTUP splashToProfilesMs=${_splashWatch.elapsedMilliseconds}');
    if (mounted) context.go('/profiles?startup=true');
  }

  Future<void> _openFreshProfiles() async {
    await _sessionPreparation;
    if (!mounted || _navigated ||
        ref.read(activeSubscriptionProvider)?.id != _startingSubscriptionId) {
      return;
    }
    _navigated = true;
    context.go('/profiles?startup=true');
  }

  Future<void> _prepareSession() async {
    final subscription = ref.read(activeSubscriptionProvider);
    if (subscription == null || subscription.type != SubscriptionType.xtream) {
      return;
    }
    final uri = Uri.tryParse(subscription.baseUrl ?? '');
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      logDiag('STARTUP sessionPreparation invalidOrigin');
      return;
    }
    try {
      final prepared = await _waitWhileMounted(
        ref
            .read(cloudflareSessionProvider)
            .initialize(baseUrl: uri.origin)
            .then((_) => true),
      );
      if (prepared == null && mounted) {
        logDiag('STARTUP sessionPreparation timedOut');
      }
    } catch (_) {
      logDiag('STARTUP sessionPreparation failed');
    }
  }

  Future<void> _finishRemainingPhase() async {
    if (!mounted) return;
    final resumed = await _checkAutoResume();
    if (!mounted || resumed) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                title: _controller.isParsingPlaylist
                    ? l.startupParsingPlaylist
                    : _providerSlow && _controller.percent < 100
                        ? l.startupProviderSlow
                        : widget.remainingPhase
                            ? l.startupLoadingRemaining
                            : l.startupLoadingInitial,
                visibleSteps: widget.remainingPhase
                    ? StartupRefreshController.remainingSteps.toList()
                    : StartupRefreshController.initialSteps.toList(),
                showBranding: _showBranding,
                failureMessage: _refreshStalled
                    ? _stalledMessage(l, _controller.currentStep)
                    : null,
                onOpenHome:
                    _refreshStalled ? () => _leaveLoading('/home') : null,
                onOpenSubscriptions: _refreshStalled
                    ? () => _leaveLoading('/subscriptions')
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kickOff() async {
    if (!widget.remainingPhase) {
      final subscription = ref.read(activeSubscriptionProvider);
      if (subscription != null &&
          subscription.type == SubscriptionType.xtream) {
        _configurationCheck = _checkConfiguration(subscription);
        unawaited(
          _configurationCheck!.then((invalid) {
            if (invalid &&
                mounted &&
                !_navigated &&
                ref.read(activeSubscriptionProvider)?.id ==
                    _startingSubscriptionId) {
              _openInvalidSubscription();
            }
          }),
        );
      }
      // Vérification de validité en parallèle : elle ne doit pas retarder le
      // chargement des chaînes quand le panel répond lentement.
      unawaited(_refreshSubscriptionValidity());
    }
    if (!mounted) return;
    await _controller.start();
  }

  Future<bool> _checkConfiguration(Subscription subscription) async {
    final result = await safeAsync<bool>(
      () async {
        final invalid = await _waitWhileMounted(
          ref
              .read(apiServiceProvider)
              .isXtreamConfigurationInvalid(subscription),
        );
        if (invalid == null && mounted) {
          logDiag('STARTUP configurationCheck timedOut');
        }
        return invalid ?? false;
      },
      context: 'StartupSplashScreen.checkConfiguration',
    );
    return result.valueOrNull ?? false;
  }

  Future<T?> _waitWhileMounted<T>(Future<T> task) async {
    final timeout = Completer<T?>();
    final timer = Timer(
      const Duration(seconds: 20),
      () => timeout.complete(null),
    );
    try {
      return await Future.any<T?>([
        task,
        timeout.future,
        _disposedSignal.future.then((_) => null),
      ]);
    } finally {
      timer.cancel();
    }
  }

  void _openInvalidSubscription() {
    _invalidConfiguration = true;
    _navigated = true;
    context.go('/subscriptions?connectionError=1');
  }

  void _leaveLoading(String destination) {
    if (_navigated) return;
    _navigated = true;
    _abandoned = true;
    if (destination == '/home') {
      ref.read(startupRefreshAttemptProvider.notifier).markCompleted();
    }
    context.go(destination);
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
              l.startupResumeQuestion(title, timestamp),
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
                  child: Text(
                    l.resumeAction,
                    style: const TextStyle(color: Colors.black),
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
    return AppLocalizations.of(context).startupLastSession;
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

  String _stalledMessage(AppLocalizations l, StartupStep? step) {
    final label = step == null
        ? l.startupCheckingSubscription
        : refreshStepLabel(l, step);
    return l.startupStalled(label, kRefreshStallTimeout.inSeconds);
  }
}
