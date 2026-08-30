import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/tv_focus.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/providers.dart';
import '../home_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isM3u = ref.watch(sourceTypeProvider).valueOrNull == 'm3u';
    final profile = ref.watch(currentProfileProvider);
    final tiles = _HomeTile.all(isM3u: isM3u, scheme: scheme);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _HomeHero(profileName: profile?.firstName),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 22, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(icon: Icons.apps_rounded, title: 'Explorer'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 165,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tile = tiles[index];
                  return _HomeTileCard(tile: tile, index: index);
                },
                childCount: tiles.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({this.profileName});

  final String? profileName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: _OrbitRing(size: 130, color: Colors.white.withOpacity(0.12)),
          ),
          Positioned(
            right: 30,
            bottom: -46,
            child: _OrbitRing(size: 118, color: Colors.white.withOpacity(0.10)),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.satellite_alt,
                size: 46,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profileName == null
                      ? 'Bienvenue sur ton IPTV'
                      : 'Bienvenue, $profileName',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _HomeTile {
  const _HomeTile({
    required this.route,
    required this.label,
    required this.icon,
    required this.color,
    this.sparkle = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final Color color;
  final bool sparkle;

  static List<_HomeTile> all({
    required bool isM3u,
    required ColorScheme scheme,
  }) {
    return [
      _HomeTile(
        route: '/live',
        label: 'Live TV',
        icon: Icons.live_tv,
        color: scheme.primary,
      ),
      if (!isM3u) ...[
        _HomeTile(
          route: '/series',
          label: 'Séries',
          icon: Icons.tv,
          color: scheme.tertiary,
        ),
        _HomeTile(
          route: '/vod',
          label: 'VOD',
          icon: Icons.movie,
          color: scheme.secondary,
        ),
        const _HomeTile(
          route: '/radio',
          label: 'Radio',
          icon: Icons.radio,
          color: Color(0xFF8A72FF),
        ),
      ],
      const _HomeTile(
        route: '/replay',
        label: 'Replay',
        icon: Icons.replay_circle_filled,
        color: Color(0xFF00CFE8),
      ),
      _HomeTile(
        route: '/search',
        label: 'Recherche',
        icon: Icons.search,
        color: scheme.secondary,
      ),
      const _HomeTile(
        route: '/epg',
        label: 'EPG',
        icon: Icons.calendar_view_day,
        color: Color(0xFF8A72FF),
      ),
      _HomeTile(
        route: '/ai',
        label: 'IA',
        icon: Icons.auto_awesome,
        color: scheme.tertiary,
        sparkle: true,
      ),
      const _HomeTile(
        route: '/favorites',
        label: 'Favoris',
        icon: Icons.favorite,
        color: Color(0xFFFF6FA8),
      ),
      _HomeTile(
        route: '/history',
        label: 'Historique',
        icon: Icons.history,
        color: scheme.primary,
      ),
      _HomeTile(
        route: '/multivideo',
        label: 'Multivideo',
        icon: Icons.ondemand_video,
        color: scheme.tertiary,
      ),
      const _HomeTile(
        route: '/vpn',
        label: 'VPN',
        icon: Icons.vpn_lock,
        color: Color(0xFF00CFE8),
      ),
      _HomeTile(
        route: '/settings',
        label: 'Réglages',
        icon: Icons.settings,
        color: scheme.secondary,
      ),
    ];
  }
}

class _HomeTileCard extends StatelessWidget {
  const _HomeTileCard({required this.tile, required this.index});

  final _HomeTile tile;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: Duration(milliseconds: 300 + (index * 40)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final opacity = value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: TvFocus(
        onActivate: () => context.go(tile.route),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          onTap: () => context.go(tile.route),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TileIcon(tile: tile),
              const SizedBox(height: 10),
              Text(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.tile});

  final _HomeTile tile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final IconData iconData = tile.sparkle ? Icons.auto_awesome : tile.icon;
    final Widget icon = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tile.sparkle
              ? [scheme.primary, scheme.tertiary]
              : [tile.color, Color.lerp(tile.color, Colors.white, 0.25)!],
        ),
        boxShadow: [
          BoxShadow(
            color: tile.color.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 26),
    );
    if (!tile.sparkle) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(Icons.star, size: 11, color: scheme.primary),
          ),
        ),
      ],
    );
  }
}