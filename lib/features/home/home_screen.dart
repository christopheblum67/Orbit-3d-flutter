import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/widgets/tv_key_handler_wrapper.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/services/refresh_freshness.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/features/startup/refresh_progress_screen.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PageController? _pageController;
  bool? _portraitPhone;
  final Map<String, FocusNode> _carouselFocusNodes = {};
  double _currentPage = 0.0;
  String? _focusedCarouselRoute;
  bool _autoRefreshing = false;
  DateTime? _lastSilentRefreshAttempt;
  String? _pendingRefreshMessage;
  String? _pendingRefreshSubscriptionId;
  GoRouter? _router;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // GARDE-FOU « à jour depuis » : le démarrage rapide (profil restauré →
    // /home) court-circuite l'écran de démarrage, donc ni le catalogue ni
    // l'horodatage n'étaient rechargés (affichage resté à « 98 h »). On
    // relance une mise à jour silencieuse au premier frame si les données
    // datent de plus de 8 h.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPendingRefreshMessage();
        _autoRefreshIfStale();
      }
    });
  }

  void _showPendingRefreshMessage() {
    final message = _pendingRefreshMessage;
    if (message == null) return;
    if (ref.read(activeSubscriptionProvider)?.id !=
        _pendingRefreshSubscriptionId) {
      _pendingRefreshMessage = null;
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if ((lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
        _router?.routeInformationProvider.value.uri.path != '/home' ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _pendingRefreshMessage = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final portraitPhone = size.width < 600 && size.height > size.width;
    if (_portraitPhone != portraitPhone) {
      final previous = _pageController;
      final page = _currentPage.round();
      _currentPage = page.toDouble();
      _portraitPhone = portraitPhone;
      final controller = PageController(
        initialPage: page,
        viewportFraction: portraitPhone ? 0.68 : 0.38,
      );
      controller.addListener(() {
        final value = controller.page ?? 0.0;
        if (!mounted ||
            !identical(_pageController, controller) ||
            (_currentPage - value).abs() < 0.0001) {
          return;
        }
        if (SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                identical(_pageController, controller) &&
                controller.hasClients) {
              setState(() => _currentPage = controller.page ?? value);
            }
          });
        } else {
          setState(() => _currentPage = value);
        }
      });
      _pageController = controller;
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    }
    final router = GoRouter.of(context);
    if (_router != router) {
      _router?.routeInformationProvider.removeListener(_onRouteChanged);
      _router = router;
      router.routeInformationProvider.addListener(_onRouteChanged);
    }
  }

  void _onRouteChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPendingRefreshMessage();
        _autoRefreshIfStale();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onRouteChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    _pageController?.dispose();
    for (final focusNode in _carouselFocusNodes.values) {
      focusNode.dispose();
    }
    _carouselFocusNodes.clear();
    super.dispose();
  }

  String _carouselItemKey(_OrbitItem item) => item.route ?? item.title;

  FocusNode _focusNodeFor(_OrbitItem item) {
    final key = _carouselItemKey(item);
    return _carouselFocusNodes.putIfAbsent(
      key,
      () => FocusNode(debugLabel: 'Home carousel: ${item.title}'),
    );
  }

  KeyEventResult _handleCarouselKey(
    List<_OrbitItem> items,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    if (direction == 0) return KeyEventResult.ignored;

    final currentIndex = items.indexWhere(
      (item) => _carouselItemKey(item) == _focusedCarouselRoute,
    );
    if (currentIndex < 0 || items.isEmpty) {
      return KeyEventResult.ignored;
    }
    final nextIndex = (currentIndex + direction + items.length) % items.length;

    final nextItem = items[nextIndex];
    final nextNode = _focusNodeFor(nextItem);
    _focusedCarouselRoute = _carouselItemKey(nextItem);
    if ((direction < 0 && currentIndex == 0) ||
        (direction > 0 && currentIndex == items.length - 1)) {
      _pageController!.jumpToPage(nextIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusedCarouselRoute == _carouselItemKey(nextItem)) {
          nextNode.requestFocus();
        }
      });
      return KeyEventResult.handled;
    }
    _pageController!
        .animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      if (mounted && _focusedCarouselRoute == _carouselItemKey(nextItem)) {
        nextNode.requestFocus();
      }
    });
    return KeyEventResult.handled;
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.power_settings_new_rounded,
              color: Colors.redAccent,
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'Quitter Orbit IPTV',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment fermer l\'application ?',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        backgroundColor: const Color(0xFF16181E),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Non',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            autofocus: true,
            style: ButtonStyle(
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? const BorderSide(color: Colors.white, width: 3)
                    : null,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Oui',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldExit == true && context.mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final multiTvEnabled =
        ref.watch(currentProfileProvider.select((p) => p?.multiTvEnabled)) ??
            true;
    final items = _OrbitItem.buildAll(
      multiTvEnabled: multiTvEnabled,
      l: l,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1117),
        body: TvKeyHandlerWrapper(
          onPlayPause: () {
            for (final item in items) {
              if (_carouselItemKey(item) == _focusedCarouselRoute &&
                  _focusNodeFor(item).hasFocus) {
                _openItem(context, item);
                break;
              }
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildOrbitCarousel(items)),
                _buildBottomBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    final l = AppLocalizations.of(context);
    final last = ref.read(lastRefreshTimestampProvider);
    // Garde-fou : si la dernière mise à jour date de moins de 8 h,
    // on évite de re-télécharger inutilement.
    if (isSubscriptionRefreshFresh(last)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.dataAlreadyFresh),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    // Écran de mise à jour (4 icônes + avancement), identique à celui du
    // démarrage et du changement d'abonnement : il invalide et recharge les six
    // sources, puis horodate la mise à jour. Plus de rechargement « caché ».
    final ok = await showRefreshProgress(context);
    if (!mounted) return;
    if (ok == null) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.homeRefreshFailed),
            duration: const Duration(seconds: 4),
          ),
        );
    }
  }

  /// Garde-fou de démarrage : si la dernière mise à jour date de plus de
  /// 8 h, on relance la mise à jour en silence, sans fenêtre de
  /// chargement. Le bouton « Mettre à jour » garde, lui, l'écran d'avancement.
  ///
  /// Le démarrage rapide (profil restauré → `/home`) court-circuite l'écran de
  /// démarrage : sans ce garde-fou, le bandeau « à jour depuis » restait figé
  /// sur une valeur ancienne (observé : 98 h) et les sections ne se rechargeaient
  /// jamais au lancement.
  Future<void> _autoRefreshIfStale() async {
    if (_autoRefreshing) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if ((lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
        _router?.routeInformationProvider.value.uri.path != '/home' ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (ref.read(startupRefreshAttemptProvider.notifier).consume()) return;
    final last = ref.read(lastRefreshTimestampProvider);
    if (isSubscriptionRefreshFresh(last)) {
      return;
    }
    // Un retour depuis une section ramène sur /home : sans délai, un échec
    // (timestamp non mis à jour) relancerait le lot à chaque appui sur Retour.
    final lastAttempt = _lastSilentRefreshAttempt;
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < const Duration(minutes: 5)) {
      return;
    }
    _lastSilentRefreshAttempt = DateTime.now();
    _autoRefreshing = true;
    final subscriptionId = ref.read(activeSubscriptionProvider)?.id;
    try {
      if (!mounted) return;
      final responded =
          await runSilentRefresh(ref: ref, isMounted: () => mounted);
      if (!mounted ||
          ref.read(activeSubscriptionProvider)?.id != subscriptionId) {
        return;
      }
      _pendingRefreshSubscriptionId = subscriptionId;
      final l = AppLocalizations.of(context);
      _pendingRefreshMessage = responded
          ? l.homeRefreshDone
          : l.homeRefreshEmpty;
      _showPendingRefreshMessage();
    } finally {
      _autoRefreshing = false;
    }
  }

  Widget _buildOrbitCarousel(List<_OrbitItem> items) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleCarouselKey(items, event),
      child: PageView.builder(
        controller: _pageController,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final rel = index - _currentPage;
          final scale = (1 - (rel.abs() * 0.22)).clamp(0.68, 1.0);
          final opacity = (1 - (rel.abs() * 0.35)).clamp(0.25, 1.0);
          final rotationY = (rel * 0.45).clamp(-0.7, 0.7);
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0018)
            ..rotateY(rotationY)
            ..scaleByDouble(scale, scale, scale, 1.0);
          final focused = rel.abs() < 0.4;
          final item = items[index];
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Opacity(
              opacity: opacity,
              child: TvFocus(
                key: ValueKey(_carouselItemKey(item)),
                focusNode: _focusNodeFor(item),
                enableTvEffects: false,
                autofocus: index == 0,
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    _focusedCarouselRoute = _carouselItemKey(item);
                  }
                  if (mounted) setState(() {});
                },
                onActivate: () => _openItem(context, item),
                child: _buildCard(item, focused, _focusNodeFor(item).hasFocus),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(_OrbitItem item, bool focused, bool hasFocus) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide.clamp(0.0, 290.0);
        return Center(
          child: GestureDetector(
            onTap: () => _openItem(context, item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              padding: EdgeInsets.all(size * 0.1),
              decoration: BoxDecoration(
                color:
                    focused ? const Color(0xFF1E222D) : const Color(0xFF141720),
                shape: BoxShape.circle,
                border: Border.all(
                  color: focused ? item.color : Colors.white10,
                  width: focused ? 2.5 : 1,
                ),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.35),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(size * 0.045),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon,
                              size: size * 0.2, color: item.color),
                        ),
                        SizedBox(height: size * 0.045),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: (size * 0.075).clamp(12.0, 22.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: size * 0.025),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            item.subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: (size * 0.045).clamp(10.0, 13.0),
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!item.hasRoute)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: item.color.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            AppLocalizations.of(context).comingSoon,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (item.route == '/favorites')
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final count = ref.watch(favoritesProvider).length;
                          if (count == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: item.color.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openItem(BuildContext context, _OrbitItem item) {
    final l = AppLocalizations.of(context);
    if (item.route != null) {
      context.go(item.route!);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.comingSoon),
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  Widget _buildBottomBar(BuildContext context) {
    final l = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final bar = Row(
      textDirection: TextDirection.ltr,
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _SubStatusChip(
          onOpenSubscriptions: () => context.go('/subscriptions'),
        ),
        const SizedBox(width: 10),
        _UpdateButton(
          tooltip: l.updateAllData,
          onPressed: _refreshAll,
        ),
        const SizedBox(width: 8),
        if (compact)
          const SizedBox(width: 120, child: _LastRefreshLabel())
        else
          const Flexible(child: _LastRefreshLabel()),
        if (compact) const SizedBox(width: 12) else const Spacer(),
        const _ProfileShortcut(),
        const SizedBox(width: 8),
        _SettingsShortcut(
          onPressed: () => context.go('/settings'),
        ),
      ],
    );
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: compact
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: bar)
          : bar,
    );
  }
}

class _SubStatusChip extends ConsumerWidget {
  const _SubStatusChip({required this.onOpenSubscriptions});

  final VoidCallback onOpenSubscriptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(activeSubscriptionProvider);
    final scheme = Theme.of(context).colorScheme;
    final name = sub?.name ?? '';
    final validity = sub?.validityLabel ?? '';
    if (name.isEmpty) {
      return _NoSubscriptionChip(onTap: onOpenSubscriptions);
    }
    return IntrinsicHeight(
        child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (validity.isNotEmpty)
                Text(
                  validity,
                  style: TextStyle(
                    color: scheme.primary.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TvFocus(
          onActivate: onOpenSubscriptions,
          child: GestureDetector(
            onTap: onOpenSubscriptions,
            child: Tooltip(
              message: AppLocalizations.of(context).homeChangeSubscription,
              child: Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CFE8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00CFE8).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).homeManageSubscription,
                  style: const TextStyle(
                    color: Color(0xFF00CFE8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ));
  }
}

class _NoSubscriptionChip extends StatelessWidget {
  const _NoSubscriptionChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
        child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.credit_card_rounded,
                color: Colors.amberAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).homeNoSubscription,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TvFocus(
          onActivate: onTap,
          child: GestureDetector(
            onTap: onTap,
            child: Tooltip(
              message: AppLocalizations.of(context).homeAddOrChangeSubscription,
              child: Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CFE8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00CFE8).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'Gestion Abonnement',
                  style: TextStyle(
                    color: Color(0xFF00CFE8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ));
  }
}

class _ProfileShortcut extends ConsumerWidget {
  const _ProfileShortcut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider);
    final label = profile?.firstName.trim();
    final displayName = label == null || label.isEmpty ? l.menuProfile : label;
    return TvFocus(
      onActivate: () => context.go('/profiles'),
      child: Semantics(
        button: true,
        label: label == null || label.isEmpty
            ? l.chooseProfile
            : '${l.menuProfile} $label',
        child: GestureDetector(
          onTap: () => context.go('/profiles'),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile != null)
                  ProfileAvatar(profile: profile, size: 30)
                else
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFF00CFE8),
                    size: 30,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsShortcut extends StatelessWidget {
  const _SettingsShortcut({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TvFocus(
        onActivate: onPressed,
        child: GestureDetector(
          onTap: onPressed,
          child: Tooltip(
            message: AppLocalizations.of(context).settings,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00CFE8).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00CFE8).withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: Color(0xFF00CFE8),
              ),
            ),
          ),
        ),
      );
}

/// Catégories rafraîchissables depuis l'accueil.
enum _RefreshCategory { live, series, vod, replay, epg }

class _OrbitItem {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String? route;
  final _RefreshCategory? refreshCategory;

  const _OrbitItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.route,
    this.refreshCategory,
  });

  bool get hasRoute => route != null;

  static List<_OrbitItem> buildAll({
    required bool multiTvEnabled,
    required AppLocalizations l,
  }) {
    return [
      _OrbitItem(
        title: l.tvChannels,
        icon: Icons.tv_rounded,
        color: const Color(0xFF00CFE8),
        subtitle: l.liveChannelsAndZapping,
        route: '/live',
        refreshCategory: _RefreshCategory.live,
      ),
      _OrbitItem(
        title: 'Films',
        icon: Icons.movie_outlined,
        color: const Color(0xFF8A72FF),
        subtitle: l.newAnd4K,
        route: '/vod',
        refreshCategory: _RefreshCategory.vod,
      ),
      _OrbitItem(
        title: l.series,
        icon: Icons.video_library_rounded,
        color: const Color(0xFFB388FF),
        subtitle: l.seasonsAndEpisodes,
        route: '/series',
        refreshCategory: _RefreshCategory.series,
      ),
      _OrbitItem(
        title: 'EPG',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF00CFE8),
        subtitle: l.programGrid,
        route: '/epg',
        refreshCategory: _RefreshCategory.epg,
      ),
      _OrbitItem(
        title: l.favoritesAndDownloads,
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF6FA8),
        subtitle: l.yourChannelsAndContent,
        route: '/favorites',
      ),
      _OrbitItem(
        title: l.matchmaking,
        icon: Icons.auto_awesome,
        color: const Color(0xFFFF3D3D),
        subtitle: l.forYouAndDuo,
        route: '/matchmaking',
      ),
      _OrbitItem(
        title: 'Replay',
        icon: Icons.replay_rounded,
        color: const Color(0xFFFFB300),
        subtitle: l.catchUpTv,
        route: '/replay',
        refreshCategory: _RefreshCategory.replay,
      ),
      if (multiTvEnabled)
        _OrbitItem(
          title: l.multiScreen,
          icon: Icons.grid_view_rounded,
          color: const Color(0xFF26A69A),
          subtitle: l.homeMultiStream,
          route: '/multivideo',
        ),
      _OrbitItem(
        title: 'Radio',
        icon: Icons.radio_rounded,
        color: const Color(0xFFEF6C00),
        subtitle: l.homeRadioStations,
        route: '/radio',
      ),
    ];
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({
    required this.onPressed,
    this.tooltip = 'Mettre à jour',
  });

  final VoidCallback onPressed;
  final String tooltip;

  /// Teinte et icône fixes : aucun appelant ne les surchargait, les paramètres
  /// ne servaient donc à rien et le.style était mort.
  static const Color _tint = Color(0xFF00CFE8);
  static const IconData _glyph = Icons.refresh_rounded;

  @override
  Widget build(BuildContext context) {
    return TvFocus(
      onActivate: onPressed,
      child: GestureDetector(
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _tint.withValues(alpha: 0.4)),
            ),
            child: const Icon(_glyph, size: 18, color: _tint),
          ),
        ),
      ),
    );
  }
}

class _LastRefreshLabel extends ConsumerStatefulWidget {
  const _LastRefreshLabel();

  @override
  ConsumerState<_LastRefreshLabel> createState() => _LastRefreshLabelState();
}

class _LastRefreshLabelState extends ConsumerState<_LastRefreshLabel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = ref.watch(lastRefreshTimestampProvider);
    final age = last == null ? null : DateTime.now().difference(last);
    final l = AppLocalizations.of(context);
    final text = age == null || age.isNegative
        ? l.homeRefreshUnknown
        : l.homeRefreshMinutes(age.inMinutes);
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white70, fontSize: 11),
    );
  }
}
