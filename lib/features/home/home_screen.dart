import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  double _currentPage = 0.0;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isM3u = ref.watch(sourceTypeProvider).valueOrNull == 'm3u';
    final items = _OrbitItem.buildAll(isM3u: isM3u);
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildOrbitCarousel(items)),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final today = DateTime.now();
    final dateLabel = DateFormat('EEE d MMM', 'fr_FR').format(today);
    final timeLabel = DateFormat('HH:mm', 'fr_FR').format(today);
    final lastRefresh = ref.watch(lastRefreshTimestampProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _ClockBlock(date: _capitalize(dateLabel), time: timeLabel),
          const SizedBox(width: 16),
          Expanded(
            child: TvFocus(
              onActivate: () => context.go('/search'),
              child: GestureDetector(
                onTap: () => context.go('/search'),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 20,),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rechercher une chaîne, un film…',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _UpdateStack(
            tooltip: 'Mettre à jour toutes les données',
            onPressed: _refreshAll,
            lastRefresh: lastRefresh,
          ),
          const SizedBox(width: 16),
          const ShaderMask(
            shaderCallback: _logoGradient,
            child: Text(
              'Orbit 3D',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshAll() {
    ref.invalidate(liveChannelsProvider);
    ref.invalidate(moviesProvider);
    ref.invalidate(seriesProvider);
    ref.invalidate(radioChannelsProvider);
    ref.invalidate(replaysProvider);
    ref.invalidate(epgProgramsProvider);
    ref.invalidate(epgDataCacheProvider);
    ref.read(lastRefreshTimestampProvider.notifier).state = DateTime.now();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Mise à jour en cours…'),
          duration: Duration(milliseconds: 1800),
        ),
      );
  }

  void _refreshOne(_RefreshCategory category) {
    switch (category) {
      case _RefreshCategory.live:
        ref.invalidate(liveChannelsProvider);
      case _RefreshCategory.series:
        ref.invalidate(seriesProvider);
      case _RefreshCategory.vod:
        ref.invalidate(moviesProvider);
      case _RefreshCategory.radio:
        ref.invalidate(radioChannelsProvider);
      case _RefreshCategory.replay:
        ref.invalidate(replaysProvider);
      case _RefreshCategory.epg:
        ref.invalidate(epgProgramsProvider);
        ref.invalidate(epgDataCacheProvider);
      case _RefreshCategory.ai:
        ref.invalidate(aiRecommendationsProvider);
    }
  }

  Widget _buildOrbitCarousel(List<_OrbitItem> items) {
    return PageView.builder(
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
              onActivate: () => _openItem(context, item),
              child: _buildCard(item, focused),
            ),
          ),
        );
      },
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
              if (item.refreshCategory != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _UpdateButton(
                    tooltip: 'Mettre à jour cette catégorie',
                    icon: Icons.update_rounded,
                    color: item.color,
                    onPressed: () => _refreshOne(item.refreshCategory!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openItem(BuildContext context, _OrbitItem item) {
    if (item.route != null) {
      context.go(item.route!);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Bientôt disponible'),
          duration: Duration(milliseconds: 1600),
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
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),),
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
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 13,),
                ),
                const SizedBox(width: 8),
                _buildProfileAvatar(context, current,
                    profilesAsync.valueOrNull ?? const <UserProfile>[],),
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
                  fontWeight: FontWeight.w700,),
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
              spreadRadius: 1,),
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
                  color: color, fontWeight: FontWeight.bold, fontSize: 11,),
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
    final sub = ref.watch(activeSubscriptionProvider).valueOrNull;
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
                  color: const Color(0xFF00CFE8).withValues(alpha: 0.4),),
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
                  color: const Color(0xFF00CFE8).withValues(alpha: 0.4),),
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

enum _RefreshCategory { live, series, vod, radio, replay, epg, ai }

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

  static List<_OrbitItem> buildAll({required bool isM3u}) {
    return [
      const _OrbitItem(
        title: 'Chaînes TV',
        icon: Icons.tv_rounded,
        color: Color(0xFF00CFE8),
        subtitle: 'Chaînes en direct & Zapping',
        route: '/live',
        refreshCategory: _RefreshCategory.live,
      ),
      if (!isM3u) ...[
        const _OrbitItem(
          title: 'Films',
          icon: Icons.movie_outlined,
          color: Color(0xFF8A72FF),
          subtitle: 'Nouveautés & 4K',
          route: '/vod',
          refreshCategory: _RefreshCategory.vod,
        ),
        const _OrbitItem(
          title: 'Séries',
          icon: Icons.video_library_rounded,
          color: Color(0xFFB388FF),
          subtitle: 'Saisons & Épisodes',
          route: '/series',
          refreshCategory: _RefreshCategory.series,
        ),
      ],
      const _OrbitItem(
        title: 'EPG',
        icon: Icons.calendar_month_rounded,
        color: Color(0xFF00CFE8),
        subtitle: 'Grille des programmes',
        route: '/epg',
        refreshCategory: _RefreshCategory.epg,
      ),
      const _OrbitItem(
        title: 'Favoris',
        icon: Icons.favorite_rounded,
        color: Color(0xFFFF6FA8),
        subtitle: 'Vos chaînes & contenus',
        route: '/favorites',
      ),
      const _OrbitItem(
        title: 'Recommandations IA',
        icon: Icons.auto_awesome,
        color: Color(0xFF4CAF50),
        subtitle: 'Recommandations personnalisées',
        route: '/ai',
        refreshCategory: _RefreshCategory.ai,
      ),
      const _OrbitItem(
        title: 'Matchmaking',
        icon: Icons.sports_soccer_rounded,
        color: Color(0xFFFF3D3D),
        subtitle: 'Directs & Scores',
      ),
      const _OrbitItem(
        title: 'Replay',
        icon: Icons.replay_rounded,
        color: Color(0xFFFFB300),
        subtitle: 'Rattrapage des chaînes',
        route: '/replay',
        refreshCategory: _RefreshCategory.replay,
      ),
      const _OrbitItem(
        title: 'Multi-écrans',
        icon: Icons.grid_view_rounded,
        color: Color(0xFF26A69A),
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
    this.icon = Icons.refresh_rounded,
    this.color = const Color(0xFF00CFE8),
  });

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Color color;

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
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// Dégradé du logo Orbit 3D.
Shader _logoGradient(Rect bounds) => const LinearGradient(
      colors: [Color(0xFF00CFE8), Color(0xFFB388FF)],
    ).createShader(bounds);

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

/// Formate un timestamp en "il y a XhYY" ou "il y a X min".
String _formatRelative(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inHours > 0) {
    return 'Mis à jour il y a ${diff.inHours}h${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}';
  }
  return 'Mis à jour il y a ${diff.inMinutes} min';
}

/// Bouton de mise à jour avec la date de la dernière actualisation en dessous.
class _UpdateStack extends StatelessWidget {
  const _UpdateStack({
    required this.onPressed,
    required this.tooltip,
    required this.lastRefresh,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final DateTime? lastRefresh;

  @override
  Widget build(BuildContext context) {
    final label = switch (lastRefresh) {
      null => 'Jamais mis à jour',
      final ts => _formatRelative(ts.toLocal()),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UpdateButton(
          tooltip: tooltip,
          onPressed: onPressed,
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
