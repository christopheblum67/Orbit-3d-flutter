import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isM3u = ref.watch(sourceTypeProvider).valueOrNull == 'm3u';
    final profile = ref.watch(currentProfileProvider);
    final location = GoRouterState.of(context).uri.path;
    final isWide = MediaQuery.sizeOf(context).width > 720;

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_rounded),
        label: 'Accueil',
      ),
      const NavigationDestination(icon: Icon(Icons.live_tv), label: 'Live TV'),
if (!isM3u) ...[
            const NavigationDestination(icon: Icon(Icons.tv), label: 'Séries'),
            const NavigationDestination(icon: Icon(Icons.movie), label: 'VOD'),
            const NavigationDestination(icon: Icon(Icons.radio), label: 'Radio'),
          ],
          const NavigationDestination(
            icon: Icon(Icons.recommend),
            label: 'Pour vous',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Réglages',
          ),
    ];

    final railDestinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.home_rounded),
        label: Text('Accueil'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.live_tv),
        label: Text('Live TV'),
      ),
      if (!isM3u) ...[
        const NavigationRailDestination(
          icon: Icon(Icons.tv),
          label: Text('Séries'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.movie),
          label: Text('VOD'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.radio),
          label: Text('Radio'),
        ),
      ],
      const NavigationRailDestination(
        icon: Icon(Icons.recommend),
        label: Text('Pour vous'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.calendar_today),
        label: Text('EPG'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings),
        label: Text('Réglages'),
      ),
    ];

    final railIndex = _railIndex(location, isM3u);

    return Scaffold(
      drawer: isWide ? null : const _HomeMenuDrawer(),
      appBar: AppBar(
        title: Text(_titleForPath(location)),
        actions: [
          IconButton(
            tooltip: 'Recommandations IA',
            onPressed: () => context.go('/ai'),
            icon: const Icon(Icons.auto_awesome),
            color: scheme.tertiary,
          ),
          _ProfileSwitchButton(profile: profile),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: railIndex,
              onDestinationSelected: (index) {
                final route = _railRoute(index, isM3u);
                context.go(route);
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Icon(Icons.live_tv, size: 28, color: scheme.primary),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ProfileSwitchButton(profile: profile),
                  ),
                ),
              ),
              backgroundColor: scheme.surfaceContainerLow,
              indicatorColor: scheme.primaryContainer,
              selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
              unselectedIconTheme:
                  IconThemeData(color: scheme.onSurfaceVariant),
              selectedLabelTextStyle: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
              destinations: railDestinations,
            ),
          if (isWide)
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: Border(
            top:
                BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _calculateSelectedIndex(context, destinations),
            onDestinationSelected: (index) {
              final route = switch (index) {
                0 => '/home',
                1 => '/live',
                2 when isM3u => '/matchmaking',
                2 => '/series',
                3 => '/vod',
                4 => '/radio',
                5 => '/matchmaking',
                _ => '/settings',
              };
              context.go(route);
            },
            destinations: destinations,
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(
    BuildContext context,
    List<NavigationDestination> destinations,
  ) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/live')) return 1;
    if (location.startsWith('/series')) return 2;
    if (location.startsWith('/vod')) return 3;
    if (location.startsWith('/radio')) return 4;
    if (location.startsWith('/matchmaking')) {
      return destinations.length == 4 ? 2 : 5;
    }
    if (location.startsWith('/settings')) {
      return destinations.length - 1;
    }
    return 0;
  }

  String _titleForPath(String path) {
    if (path.startsWith('/live')) return 'Live TV';
    if (path.startsWith('/series')) return 'Séries';
    if (path.startsWith('/vod')) return 'VOD';
    if (path.startsWith('/radio')) return 'Radio';
    if (path.startsWith('/matchmaking')) return 'Pour vous';
    if (path.startsWith('/replay')) return 'Replay';
    if (path.startsWith('/epg')) return 'EPG';
    if (path.startsWith('/search')) return 'Recherche';
    if (path.startsWith('/ai')) return 'Orbit IA';
    if (path.startsWith('/vpn')) return 'VPN';
    if (path.startsWith('/subscriptions')) return 'Abonnements';
    if (path.startsWith('/settings/advanced')) return 'Configuration Avancée';
    if (path.startsWith('/settings')) return 'Réglages';
    return AppConstants.appName;
  }

  static int _railIndex(String location, bool isM3u) {
    if (location.startsWith('/live')) return 1;
    if (location.startsWith('/series')) return 2;
    if (location.startsWith('/vod')) return 3;
    if (location.startsWith('/radio')) return 4;
    if (location.startsWith('/matchmaking')) {
      return isM3u ? 2 : 5;
    }
    if (location.startsWith('/epg')) {
      return isM3u ? 3 : 6;
    }
    if (location.startsWith('/settings')) {
      return isM3u ? 4 : 7;
    }
    return 0;
  }

  static String _railRoute(int index, bool isM3u) {
    return switch (index) {
      0 => '/home',
      1 => '/live',
      2 when isM3u => '/matchmaking',
      2 => '/series',
      3 when isM3u => '/epg',
      3 => '/vod',
      4 when isM3u => '/settings',
      4 => '/radio',
      5 => '/matchmaking',
      6 => '/epg',
      _ => '/settings',
    };
  }
}

class _HomeMenuDrawer extends ConsumerWidget {
  const _HomeMenuDrawer();

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
              icon: Icons.home_rounded, label: 'Accueil', route: '/home',),
          const _MenuEntry(
              icon: Icons.live_tv, label: 'Live TV', route: '/live',),
          if (!isM3u) ...[
            const _MenuEntry(icon: Icons.tv, label: 'Séries', route: '/series'),
            const _MenuEntry(icon: Icons.movie, label: 'VOD', route: '/vod'),
            const _MenuEntry(
                icon: Icons.radio, label: 'Radio', route: '/radio',),
          ],
        ],
      ),
      _MenuSection(
        header: 'Découvrir',
        items: [
          const _MenuEntry(
              icon: Icons.search, label: 'Recherche', route: '/search',),
          const _MenuEntry(
              icon: Icons.calendar_today, label: 'EPG (grille)', route: '/epg',),
          _MenuEntry(
            icon: Icons.recommend,
            label: 'Pour vous (matchmaking)',
            route: '/matchmaking',
            color: scheme.primary,
          ),
          const _MenuEntry(
              icon: Icons.replay_circle_filled,
              label: 'Replay',
              route: '/replay',),
          _MenuEntry(
            icon: Icons.auto_awesome,
            label: 'Orbit IA',
            route: '/ai',
            color: scheme.tertiary,
          ),
        ],
      ),
      _MenuSection(
        header: 'Mes contenus',
        items: [
          const _MenuEntry(
              icon: Icons.favorite, label: 'Favoris', route: '/favorites',),
          const _MenuEntry(
              icon: Icons.history, label: 'Historique', route: '/history',),
          const _MenuEntry(icon: Icons.vpn_lock, label: 'VPN', route: '/vpn'),
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
              icon: Icons.settings, label: 'Réglages', route: '/settings',),
          _MenuEntry(
              icon: Icons.tune, label: 'Configuration avancée', route: '/settings/advanced',),
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
                  Icon(Icons.live_tv,
                      size: 40, color: scheme.onPrimaryContainer,),
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

class _ProfileSwitchButton extends StatelessWidget {
  const _ProfileSwitchButton({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget avatar;
    if (profile == null) {
      avatar = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(
          Icons.person_outline,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
      );
    } else {
      avatar = ProfileAvatar(profile: profile!, size: 34);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 10),
      child: Tooltip(
        message: profile == null ? 'Choisir un profil' : 'Changer de profil',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go('/profiles'),
          child: avatar,
        ),
      ),
    );
  }
}
