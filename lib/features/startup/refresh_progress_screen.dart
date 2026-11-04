import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Ouvre l'écran de mise à jour et rend `true` si une source a répondu, `false`
/// si aucune n'a répondu ou `null` si l'utilisateur l'a quitté prématurément.
///
/// À utiliser par l'accueil : au lancement quand les données ont plus de 30 min
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
  int _responded = 0;
  Timer? _stallTimer;
  bool _refreshStalled = false;

  @override
  void initState() {
    super.initState();
    _controller = RefreshStepsController(
      steps: const {
        StartupStep.live,
        StartupStep.movies,
        StartupStep.series,
        StartupStep.radio,
        StartupStep.replay,
        StartupStep.epg,
      },
    )..addListener(_onProgress);
    _armStallTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _run();
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

  void _openSubscriptions() {
    final router = GoRouter.of(context);
    Navigator.of(context, rootNavigator: true).pop<bool?>();
    router.go('/subscriptions');
  }

  Future<void> _run() async {
    // Force un vrai rechargement réseau : les providers sont NON `autoDispose`,
    // donc sans `invalidate` un simple `read(...future)` renverrait la valeur en
    // cache sans aucun appel réseau (rafraîchissement factice).
    logDiag('REFRESH mode=manual providers=invalidate start');
    ref.invalidate(liveChannelsProvider);
    ref.invalidate(moviesProvider);
    ref.invalidate(seriesProvider);
    ref.invalidate(radioChannelsProvider);
    ref.invalidate(m3uPlaylistProvider);
    ref.invalidate(replaysProvider);
    ref.invalidate(epgProgramsProvider);

    await _controller.run((step) async {
      final List<dynamic> list = switch (step) {
        StartupStep.live => await ref.read(liveChannelsProvider.future),
        StartupStep.movies => await ref.read(moviesProvider.future),
        StartupStep.series => await ref.read(seriesProvider.future),
        StartupStep.radio => await ref.read(radioChannelsProvider.future),
        StartupStep.replay => await ref.read(replaysProvider.future),
        StartupStep.epg => await ref.read(epgProgramsProvider.future),
        StartupStep.ai => const [],
      };
      logDiag('REFRESH dataset=${step.name} itemCount=${list.length}');
      if (list.isNotEmpty) _responded++;
    });

    if (!mounted) return;

    // N'horodate que si au moins une source a répondu : sinon l'étiquette
    // « à jour depuis » mentirait (échec total du lot).
    if (_responded > 0) {
      ref.invalidate(epgDataCacheProvider);
      ref
          .read(lastRefreshTimestampProvider.notifier)
          .setTimestamp(DateTime.now());
    }
    logDiag(
      'REFRESH mode=manual complete responded=$_responded '
      'timestampUpdated=${_responded > 0}',
    );
    Navigator.of(context).pop(_responded > 0);
  }

  @override
  Widget build(BuildContext context) {
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
              failureMessage: _refreshStalled
                  ? _stalledMessage(_controller.currentStep?.label)
                  : null,
              onOpenSubscriptions: _refreshStalled ? _openSubscriptions : null,
            ),
          ),
        ),
      ),
    );
  }

  String _stalledMessage(String? step) {
    final label = step == null ? 'la mise à jour' : '« $step »';
    return '$label ne signale aucune progression depuis '
        '${kRefreshStallTimeout.inSeconds} secondes. Le serveur peut être '
        'lent ou indisponible ; vous pouvez vérifier l’abonnement.';
  }
}
