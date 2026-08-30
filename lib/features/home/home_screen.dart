import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/tv_focus.dart';
import '../../core/widgets/widgets.dart';
import '../../models/user_profile.dart';
import '../../providers/providers.dart';
import '../home_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isM3u = ref.watch(sourceTypeProvider).valueOrNull == 'm3u';
    final mediaTiles = _HomeTile.media(isM3u: isM3u, scheme: Theme.of(context).colorScheme);
    final persoTiles = _HomeTile.perso(scheme: Theme.of(context).colorScheme);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverToBoxAdapter(child: _TopBanner()),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 22, 16, 0),
            sliver: SliverToBoxAdapter(child: _ProfilesSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
            sliver: SliverToBoxAdapter(
              child: _MediaLayout(
                mediaTiles: mediaTiles,
                persoTiles: persoTiles,
                isM3u: isM3u,
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverToBoxAdapter(child: _SearchBanner()),
          ),
        ],
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final dateLabel = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(today);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 20, color: Colors.white.withOpacity(0.95)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _capitalize(dateLabel),
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _SubEndChip(),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _SubEndChip extends ConsumerWidget {
  const _SubEndChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(sourceTypeProvider).valueOrNull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Fin d\'abo · ${_endCaption(type)}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  String _endCaption(String? type) {
    if (type == null) return '—';
    if (type == 'm3u') return 'M3U';
    return 'actif';
  }
}

class _ProfilesSection extends ConsumerWidget {
  const _ProfilesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final current = ref.watch(currentProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          icon: Icons.people_alt_rounded,
          title: 'Profils',
          subtitle: 'Changer',
          padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
        ),
        SizedBox(
          height: 92,
          child: profilesAsync.when(
            data: (profiles) {
              if (profiles.isEmpty) {
                return const _ProfilesEmpty();
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final selected = current?.id == profile.id;
                  return _ProfileChip(
                    profile: profile,
                    selected: selected,
                    onTap: () => context.go('/profiles'),
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
            error: (error, _) => const _ProfilesEmpty(),
          ),
        ),
      ],
    );
  }
}

class _ProfilesEmpty extends StatelessWidget {
  const _ProfilesEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aucun profil pour l\'instant',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final UserProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TvFocus(
      onActivate: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            color: selected
                ? scheme.secondaryContainer.withOpacity(0.55)
                : scheme.surfaceContainerLow,
            border: Border.all(
              color: selected ? scheme.secondary : scheme.outlineVariant.withOpacity(0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProfileAvatar(profile: profile, size: 40),
              const SizedBox(height: 6),
              Text(
                profile.firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.onSecondaryContainer : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaLayout extends StatelessWidget {
  const _MediaLayout({
    required this.mediaTiles,
    required this.persoTiles,
    required this.isM3u,
  });

  final List<_HomeTile> mediaTiles;
  final List<_HomeTile> persoTiles;
  final bool isM3u;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final media = _SectionColumn(
          icon: Icons.ondemand_video_rounded,
          title: 'Média',
          tiles: mediaTiles,
          startIndex: 0,
        );
        final perso = _SectionColumn(
          icon: Icons.widgets_rounded,
          title: 'Perso & Services',
          tiles: persoTiles,
          startIndex: mediaTiles.length,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: media),
              const SizedBox(width: 16),
              Expanded(child: perso),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            media,
            const SizedBox(height: 4),
            perso,
          ],
        );
      },
    );
  }
}

class _SectionColumn extends StatelessWidget {
  const _SectionColumn({
    required this.icon,
    required this.title,
    required this.tiles,
    required this.startIndex,
  });

  final IconData icon;
  final String title;
  final List<_HomeTile> tiles;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(
            icon: icon,
            title: title,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: tiles.length,
            itemBuilder: (context, index) {
              final tile = tiles[index];
              return _HomeTileCard(tile: tile, index: startIndex + index);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchBanner extends StatelessWidget {
  const _SearchBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TvFocus(
      onActivate: () => context.go('/search'),
      child: GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            color: scheme.surfaceContainerLow,
            border: Border.all(color: scheme.primary.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Chercher une chaîne, un film, une série…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(Icons.arrow_forward, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTile {
  const _HomeTile({
    required this.label,
    required this.icon,
    required this.color,
    this.route,
    this.sparkle = false,
  });

  final String? route;
  final String label;
  final IconData icon;
  final Color color;
  final bool sparkle;

  static List<_HomeTile> media({
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
          label: 'Films & VOD',
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
    ];
  }

  static List<_HomeTile> perso({required ColorScheme scheme}) {
    return [
      const _HomeTile(
        route: '/favorites',
        label: 'Favoris',
        icon: Icons.favorite,
        color: Color(0xFFFF6FA8),
      ),
      _HomeTile(
        route: '/ai',
        label: 'Orbit IA',
        icon: Icons.auto_awesome,
        color: scheme.tertiary,
        sparkle: true,
      ),
      const _HomeTile(
        label: 'Match',
        icon: Icons.sports_soccer,
        color: Color(0xFF8A72FF),
      ),
      _HomeTile(
        route: '/history',
        label: 'Historique',
        icon: Icons.history,
        color: scheme.primary,
      ),
      const _HomeTile(
        route: '/epg',
        label: 'EPG',
        icon: Icons.calendar_view_day,
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

  void _handleTap(BuildContext context) {
    final route = tile.route;
    if (route != null) {
      context.go(route);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Match — bientôt disponible'),
          duration: Duration(milliseconds: 1600),
        ),
      );
  }

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
        onActivate: () => _handleTap(context),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          onTap: () => _handleTap(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TileIcon(tile: tile),
              const SizedBox(height: 10),
              Text(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
