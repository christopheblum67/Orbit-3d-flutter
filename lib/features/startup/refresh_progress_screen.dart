import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Ouvre l'écran de mise à jour et rend `true` si une source a répondu, `false`
/// si aucune n'a répondu ou `null` si l'utilisateur l'a quitté prématurément.
///
/// À utiliser par l'accueil : au lancement quand les données ont plus de 8 h
/// ([HomeScreen] → `_autoRefreshIfStale`), et sur le bouton « Mettre à jour ».
/// On pousse sur le Navigator racine pour couvrir toute la coquille
/// (`HomeShell`) sans perturber la navigation du routeur.
Future<bool?> showRefreshProgress(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final result = await navigator.push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => const RefreshProgressScreen(),
    ),
  );
  return result;
}

const _refreshSteps = {
  StartupStep.live,
  StartupStep.movies,
  StartupStep.series,
  StartupStep.radio,
  StartupStep.replay,
  StartupStep.epg,
};

final _activeRefreshLeases = <Object>{};

class _CatalogRefreshLease {
  final Object _token = Object();

  void acquire() {
    _activeRefreshLeases.add(_token);
    ApiService.bypassCatalogCache = true;
  }

  void release() {
    if (_activeRefreshLeases.remove(_token)) {
      ApiService.bypassCatalogCache = _activeRefreshLeases.isNotEmpty;
    }
  }
}

/// Régénère les six sources sans aucune fenêtre : utilisé au lancement quand
/// les données sont périmées. Rend `true` si au moins une source a répondu.
Future<bool> runSilentRefresh({
  required WidgetRef ref,
  required bool Function() isMounted,
}) async {
  final controller = RefreshStepsController(steps: _refreshSteps);
  try {
    final responded = await performCatalogRefresh(
      ref: ref,
      controller: controller,
      isMounted: isMounted,
      mode: 'silent',
    );
    return responded > 0;
  } finally {
    controller.dispose();
  }
}

/// Invalide puis recharge les sources, et horodate la mise à jour si au moins
/// l'une a répondu. Rend le nombre de sources ayant répondu.
Future<int> performCatalogRefresh({
  required WidgetRef ref,
  required RefreshStepsController controller,
  required bool Function() isMounted,
  String mode = 'manual',
}) =>
    _performCatalogRefresh(
      ref: ref,
      controller: controller,
      isMounted: isMounted,
      mode: mode,
    );

Future<int> _performCatalogRefresh({
  required WidgetRef ref,
  required RefreshStepsController controller,
  required bool Function() isMounted,
  String mode = 'manual',
  _CatalogRefreshLease? lease,
}) async {
  var responded = 0;
  final subscriptionId = ref.read(activeSubscriptionProvider)?.id;
  final parsingSubscription =
      ref.read(m3uParsingEventsProvider).stream.listen((_) {
    if (isMounted() &&
        ref.read(activeSubscriptionProvider)?.id == subscriptionId) {
      controller.markPlaylistParsing();
    }
  });
  // Force un vrai rechargement réseau : les providers sont NON `autoDispose`,
  // donc sans `invalidate` un simple `read(...future)` renverrait la valeur en
  // cache sans aucun appel réseau (rafraîchissement factice).
  logDiag('REFRESH mode=$mode providers=invalidate start');
  final refreshLease = lease ?? _CatalogRefreshLease();
  refreshLease.acquire();
  try {
    ref.invalidate(liveChannelsAllProvider);
    ref.invalidate(moviesProvider);
    ref.invalidate(seriesProvider);
    ref.invalidate(radioChannelsProvider);
    ref.invalidate(m3uPlaylistProvider);
    ref.invalidate(replaysProvider);

    await controller.run((step) async {
      if (!isMounted()) return;
      final List<dynamic> list = switch (step) {
        StartupStep.live => await ref.read(liveChannelsProvider.future),
        StartupStep.movies => await ref.read(moviesProvider.future),
        StartupStep.series => await ref.read(seriesProvider.future),
        StartupStep.radio => await ref.read(radioChannelsProvider.future),
        StartupStep.replay => await ref.read(replaysProvider.future),
        StartupStep.epg => await _refreshEpg(ref, isMounted),
        StartupStep.ai => const [],
      };
      logDiag('REFRESH dataset=${step.name} itemCount=${list.length}');
      if (list.isNotEmpty) responded++;
    });
  } finally {
    unawaited(parsingSubscription.cancel());
    refreshLease.release();
  }

  if (!isMounted()) return responded;

  // N'horodate que si au moins une source a répondu : sinon l'étiquette
  // « à jour depuis » mentirait (échec total du lot).
  if (responded > 0 &&
      subscriptionId != null &&
      subscriptionId.isNotEmpty &&
      ref.read(activeSubscriptionProvider)?.id == subscriptionId) {
    ref
        .read(lastRefreshTimestampProvider.notifier)
        .setTimestamp(DateTime.now(), subscriptionId: subscriptionId);
  }
  logDiag(
    'REFRESH mode=$mode complete responded=$responded '
    'timestampUpdated=${responded > 0}',
  );
  return responded;
}

Future<List<dynamic>> _refreshEpg(
  WidgetRef ref,
  bool Function() isMounted,
) async {
  final cache = ref.read(epgDataCacheProvider);
  final api = ref.read(apiServiceProvider);
  final programs = await cache.loadFull(api, forceRefresh: true);
  if (isMounted()) ref.invalidate(epgProgramsProvider);
  return programs;
}

/// Écran plein écran de régénération des flux.
///
/// Réutilise `RefreshProgressView` (les mêmes 4 icônes + barre que l'écran de
/// démarrage) et un [RefreshStepsController] dont chaque étape invalide puis
/// attend le provider Riverpod correspondant : contrairement à un simple
/// rechargement « caché », l'interface se met bien à jour avec les nouvelles
/// données à la fin.
class RefreshProgressScreen extends ConsumerStatefulWidget {
  const RefreshProgressScreen({super.key});

  @override
  ConsumerState<RefreshProgressScreen> createState() =>
      _RefreshProgressScreenState();
}

class _RefreshProgressScreenState extends ConsumerState<RefreshProgressScreen> {
  late final RefreshStepsController _controller;
  Timer? _stallTimer;
  bool _refreshStalled = false;
  bool _leaving = false;
  final _lease = _CatalogRefreshLease();

  @override
  void initState() {
    super.initState();
    _controller = RefreshStepsController(steps: _refreshSteps)
      ..addListener(_onProgress);
    _armStallTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _run();
    });
  }

  @override
  void dispose() {
    _lease.release();
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

  void _leaveLoading(String destination) {
    if (_leaving) return;
    _leaving = true;
    _lease.release();
    final router = GoRouter.of(context);
    Navigator.of(context, rootNavigator: true).pop<bool?>();
    router.go(destination);
  }

  Future<void> _run() async {
    final responded = await _performCatalogRefresh(
      ref: ref,
      controller: _controller,
      isMounted: () => mounted && !_leaving,
      lease: _lease,
    );
    if (!mounted || _leaving) return;
    Navigator.of(context).pop(responded > 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshProgressView(
              percent: _controller.percent,
              currentStep: _controller.currentStep,
              doneSteps: _controller.doneSteps,
              isFinished: _controller.isFinished,
              title: _controller.isParsingPlaylist
                  ? l.startupParsingPlaylist
                  : null,
              failureMessage: _refreshStalled
                  ? _stalledMessage(l, _controller.currentStep)
                  : null,
              onOpenHome: _refreshStalled ? () => _leaveLoading('/home') : null,
              onOpenSubscriptions: _refreshStalled
                  ? () => _leaveLoading('/subscriptions')
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  String _stalledMessage(AppLocalizations l, StartupStep? step) {
    final label = step == null ? l.startupRefresh : refreshStepLabel(l, step);
    return l.startupRefreshStalled(label, kRefreshStallTimeout.inSeconds);
  }
}
