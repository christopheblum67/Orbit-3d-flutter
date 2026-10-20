import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/features/startup/refresh_progress_screen.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  double _currentPage = 0.0;
  bool _autoRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.38,
    );
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
    // GARDE-FOU « à jour depuis » : le démarrage rapide (profil restauré →
    // /home) court-circuite l'écran de démarrage, donc ni le catalogue ni
    // l'horodatage n'étaient rechargés (affichage resté à « 98 h »). On
    // relance une mise à jour silencieuse au premier frame si les données
    // datent de plus de 30 min (TTL EPG).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _autoRefreshIfStale();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    final isM3u = ref.watch(sourceTypeProvider).value == 'm3u';
    final items = _OrbitItem.buildAll(isM3u: isM3u, l: l);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1117),
        body: TvSafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(child: _buildOrbitCarousel(items)),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final l = AppLocalizations.of(context);
    final today = DateTime.now();
    final dateLabel = DateFormat('EEE d MMM', 'fr_FR').format(today);
    final timeLabel = DateFormat('HH:mm', 'fr_FR').format(today);
    final lastRefresh = ref.watch(lastRefreshTimestampProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _ClockBlock(date: _capitalize(dateLabel), time: timeLabel),
              const Spacer(),
              TvFocus(
                onActivate: () => context.go('/settings'),
                child: GestureDetector(
                  onTap: () => context.go('/settings'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _UpdateStack(
                tooltip: l.updateAllData,
                onPressed: _refreshAll,
                lastRefresh: lastRefresh,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _refreshAll() async {
    final l = AppLocalizations.of(context);
    final last = ref.read(lastRefreshTimestampProvider);
    // Garde-fou : si la dernière mise à jour date de moins de 30 min
    // (TTL EPG), on évite de re-télécharger inutilement.
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 30)) {
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
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Échec de la mise à jour : aucune source n\'a répondu.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
    }
  }

  /// Garde-fou de démarrage : si la dernière mise à jour date de plus de
  /// 30 min (TTL EPG), on ouvre l'écran de mise à jour (4 icônes + avancement)
  /// — le rechargement n'est plus silencieux.
  ///
  /// Le démarrage rapide (profil restauré → `/home`) court-circuite l'écran de
  /// démarrage : sans ce garde-fou, le bandeau « à jour depuis » restait figé
  /// sur une valeur ancienne (observé : 98 h) et les sections ne se rechargeaient
  /// jamais au lancement.
  Future<void> _autoRefreshIfStale() async {
    if (_autoRefreshing) return;
    final last = ref.read(lastRefreshTimestampProvider);
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 30)) {
      return;
    }
    _autoRefreshing = true;
    try {
      if (!mounted) return;
      await showRefreshProgress(context);
    } finally {
      _autoRefreshing = false;
    }
  }

  Widget _buildOrbitCarousel(List<_OrbitItem> items) {
    // En mode TV, les flèches gauche/droite du D-pad font défiler le
    // carrousel : le Focus intercepte les touches et pilote le PageController.
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
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
                autofocus: index == 0,
                onActivate: () => _openItem(context, item),
                child: _buildCard(item, focused),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(_OrbitItem item, bool focused) {
    return Center(
      child: GestureDetector(
        onTap: () => _openItem(context, item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 290,
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: focused ? const Color(0xFF1E222D) : const Color(0xFF141720),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: focused ? item.color : Colors.white10,
              width: focused ? 2.5 : 1,
            ),
            boxShadow: focused
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 58, color: item.color),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
              if (!item.hasRoute)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: item.color.withValues(alpha: 0.3)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Bientôt',
                        style: TextStyle(
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
    final profilesAsync = ref.watch(profilesProvider);
    final current = ref.watch(currentProfileProvider);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          const _SubStatusChip(),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/profiles'),
            child: Row(
              children: [
                Text(
                  'Profil : ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                _buildProfileAvatar(
                  context,
                  current,
                  profilesAsync.value ?? const <UserProfile>[],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    UserProfile? current,
    List<UserProfile> profiles,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (current == null || profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            const Text(
              'Choisir',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    final idx = profiles.indexWhere((p) => p.id == current.id);
    final color = _profileColor(idx);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: color.withValues(alpha: 0.3),
            child: Text(
              current.firstName.isNotEmpty
                  ? current.firstName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            current.firstName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static const List<Color> _profileColors = [
    Color(0xFF00CFE8),
    Color(0xFFFFB300),
    Color(0xFFB388FF),
    Color(0xFFFF6FA8),
  ];

  Color _profileColor(int index) {
    if (index < 0) return _profileColors.first;
    return _profileColors[index % _profileColors.length];
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _SubStatusChip extends ConsumerWidget {
  const _SubStatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(activeSubscriptionProvider);
    final scheme = Theme.of(context).colorScheme;
    final name = sub?.name ?? '';
    final validity = sub?.validityLabel ?? '';
    if (name.isEmpty) {
      return const _NoSubscriptionChip();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        InkWell(
          onTap: () => context.go('/subscriptions'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00CFE8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF00CFE8).withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'Changer',
              style: TextStyle(
                color: Color(0xFF00CFE8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoSubscriptionChip extends StatelessWidget {
  const _NoSubscriptionChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
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
                'Aucun abo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.go('/subscriptions'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00CFE8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF00CFE8).withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'Changer',
              style: TextStyle(
                color: Color(0xFF00CFE8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
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
    required bool isM3u,
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
      if (!isM3u) ...[
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
      ],
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
      _OrbitItem(
        title: l.multiScreen,
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF26A69A),
        subtitle: 'Jusqu\'à 4 flux à la fois',
        route: '/multivideo',
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
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
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
    );
  }
}

/// Horloge affichée à gauche de la barre d'accueil (date + heure réelles).
class _ClockBlock extends StatelessWidget {
  const _ClockBlock({required this.date, required this.time});

  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF00CFE8)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Formate un timestamp en « il y a XhYY » ou « il y a X min ».
String _formatRelative(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  // Un rafraîchissement vient d'avoir lieu : « il y a 0 min » se lit comme un
  // compteur bloqué ou une donnée périmée. « à l'instant » est exact et lisible
  // sur une TV où l'on regarde l'écran quelques secondes.
  if (diff.inMinutes < 1) return 'À jour à l\'instant';
  if (diff.inHours > 0) {
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    return 'À jour il y a ${diff.inHours}h$minutes';
  }
  return 'À jour il y a ${diff.inMinutes} min';
}

/// Bouton de mise à jour avec la date de la dernière actualisation en dessous.
///
/// Stateful : [Timer.periodic] force un rebuild chaque minute, sinon le libellé
/// « mis à jour il y a X min » resterait figé jusqu'au prochain changement de
/// provider (donc potentiellement des heures).
class _UpdateStack extends StatefulWidget {
  const _UpdateStack({
    required this.onPressed,
    required this.tooltip,
    required this.lastRefresh,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final DateTime? lastRefresh;

  @override
  State<_UpdateStack> createState() => _UpdateStackState();
}

class _UpdateStackState extends State<_UpdateStack> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (widget.lastRefresh) {
      null => 'Jamais mis à jour',
      final ts => _formatRelative(ts),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UpdateButton(
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
