import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Drawer applicatif réutilisable (« chevalet » ☰) : menu de sous-navigation
/// organisé en sections Continuer / Découvrir / Mes contenus / Configuration.
///
/// Présent sur toutes les pages applicatives (hormis les médias de diffusion).
class HomeMenuDrawer extends ConsumerWidget {
  const HomeMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isM3u = ref.watch(sourceTypeProvider).valueOrNull == 'm3u';
    final profile = ref.watch(currentProfileProvider);
    final sections = <_MenuSection>[
      _MenuSection(
        header: 'Continuer',
        items: [
          const _MenuEntry(
            icon: Icons.home_rounded,
            label: 'Accueil',
            route: '/home',
          ),
          const _MenuEntry(
            icon: Icons.live_tv,
            label: 'Live TV',
            route: '/live',
          ),
          if (!isM3u) ...[
            const _MenuEntry(icon: Icons.tv, label: 'Séries', route: '/series'),
            const _MenuEntry(icon: Icons.movie, label: 'VOD', route: '/vod'),
          ],
        ],
      ),
      _MenuSection(
        header: 'Découvrir',
        items: [
          const _MenuEntry(
            icon: Icons.search,
            label: 'Recherche',
            route: '/search',
          ),
          const _MenuEntry(
            icon: Icons.calendar_today,
            label: 'EPG (grille)',
            route: '/epg',
          ),
          _MenuEntry(
            icon: Icons.recommend,
            label: 'Pour vous (matchmaking)',
            route: '/matchmaking',
            color: scheme.primary,
          ),
          const _MenuEntry(
            icon: Icons.replay_circle_filled,
            label: 'Replay',
            route: '/replay',
          ),
        ],
      ),
      _MenuSection(
        header: 'Mes contenus',
        items: [
          const _MenuEntry(
            icon: Icons.favorite,
            label: 'Favoris',
            route: '/favorites',
          ),
          const _MenuEntry(
            icon: Icons.history,
            label: 'Historique',
            route: '/history',
          ),
          _MenuEntry(
            icon: Icons.person_outline,
            label: profile?.firstName == null
                ? 'Profil'
                : 'Profil : ${profile!.firstName}',
            route: '/profiles',
          ),
        ],
      ),
      const _MenuSection(
        header: 'Configuration',
        items: [
          _MenuEntry(
            icon: Icons.dns_outlined,
            label: 'Abonnements',
            route: '/subscriptions',
          ),
          _MenuEntry(
            icon: Icons.settings,
            label: 'Réglages',
            route: '/settings',
          ),
          _MenuEntry(
            icon: Icons.tune,
            label: 'Configuration avancée',
            route: '/settings/advanced',
          ),
        ],
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.live_tv,
                    size: 40,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Sélectionnez un sous-menu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              scheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
            for (final section in sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  section.header,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                ),
              ),
              for (final item in section.items) _MenuTile(item: item),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuSection {
  const _MenuSection({required this.header, required this.items});

  final String header;
  final List<_MenuEntry> items;
}

class _MenuEntry {
  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.route,
    this.color,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color? color;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuEntry item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.path;
    final selected = location.startsWith(item.route);
    return ListTile(
      leading: Icon(item.icon, color: item.color ?? scheme.primary),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.of(context).pop();
        context.go(item.route);
      },
    );
  }
}