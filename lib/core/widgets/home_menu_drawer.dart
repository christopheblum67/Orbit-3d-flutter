import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Drawer applicatif réutilisable (« chevalet » ☰) : menu de sous-navigation
/// organisé en sections Continuer / Découvrir / Mes contenus / Configuration.
///
/// Présent sur toutes les pages applicatives (hormis les médias de diffusion).
class HomeMenuDrawer extends ConsumerWidget {
  const HomeMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isM3u = ref.watch(sourceTypeProvider).value == 'm3u';
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
          _MenuEntry(
            icon: Icons.live_tv,
            label: l.liveTv,
            route: '/live',
          ),
          if (!isM3u) ...[
            _MenuEntry(icon: Icons.tv, label: l.series, route: '/series'),
            _MenuEntry(icon: Icons.movie, label: l.films, route: '/vod'),
          ],
        ],
      ),
      _MenuSection(
        header: 'Découvrir',
        items: [
          // Plus d'entrée « Recherche » unifiée : le projet a été abandonné au
          // profit des recherches par section (chaînes / films / séries /
          // replay / radio), accessibles depuis l'icône ☰ propre à chaque
          // écran de section. L'entrée du tiroir pointait vers `/search`,
          // devenue sans objet : la route renvoie maintenant vers `/home`.
          _MenuEntry(
            icon: Icons.calendar_today,
            label: l.epgGrille,
            route: '/epg',
          ),
          _MenuEntry(
            icon: Icons.recommend,
            label: l.forYouMatchmaking,
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
        header: l.myContent,
        items: [
          // Une seule entrée pour les deux listes. Elles sont sur le même
          // écran, en onglets : deux entrées qui ouvrent le même écran sur deux
          // onglets différents n'aidaient pas à choisir.
          _MenuEntry(
            icon: Icons.favorite,
            label: l.favoritesAndDownloads,
            route: '/favorites',
          ),
          _MenuEntry(
            icon: Icons.history,
            label: l.history,
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
      _MenuSection(
        header: 'Configuration',
        items: [
          const _MenuEntry(
            icon: Icons.dns_outlined,
            label: 'Abonnements',
            route: '/subscriptions',
          ),
          _MenuEntry(
            icon: Icons.settings,
            label: l.settings,
            route: '/settings',
          ),
        ],
      ),
    ];

    return Drawer(
      // `TvSafeArea` et non `SafeArea` : en mode TV, le tiroir s'ouvre collé au
      // bord gauche de la dalle, précisément la zone rognée par l'overscan (5 à
      // 10 %). Sans la marge de 48/27 dp, les sections et les premiers caractères
      // des libellés étaient coupés sur un téléviseur. En mode téléphone le
      // retrait est nul : rien ne bouge.
      child: TvSafeArea(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const OrbitLogoIcon(size: 40),
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
              for (final item in section.items)
                _MenuTile(
                  item: item,
                  autofocus: identical(item, sections.first.items.first),
                ),
            ],
            const SizedBox(height: 16),
          ],
        ),
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
  const _MenuTile({required this.item, this.autofocus = false});

  final _MenuEntry item;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.path;
    final selected = location.startsWith(item.route);
    void navigate() {
      Navigator.of(context).pop();
      context.go(item.route);
    }

    return TvFocus(
      autofocus: autofocus,
      onActivate: navigate,
      child: ListTile(
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
        onTap: navigate,
      ),
    );
  }
}
