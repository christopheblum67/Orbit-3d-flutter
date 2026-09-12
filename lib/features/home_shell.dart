import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/home_menu_drawer.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isM3u = ref.watch(sourceTypeProvider).value == 'm3u';
    final profile = ref.watch(currentProfileProvider);
    final location = GoRouterState.of(context).uri.path;
    final isWide = MediaQuery.sizeOf(context).width > 720;

    final entries = _navEntries(isM3u);
    final railEntries = _railEntries(isM3u);
    final selectedIndex = _indexFor(location, entries);
    final railIndex = _indexFor(location, railEntries);

    return Scaffold(
        drawer: isWide ? null : const HomeMenuDrawer(),
        appBar: AppBar(
          title: Text(_titleForPath(location)),
          actions: [
            _ProfileSwitchButton(profile: profile),
          ],
        ),
        body: Row(
          children: [
            if (isWide)
              NavigationRail(
                selectedIndex: railIndex,
                onDestinationSelected: (index) {
                  context.go(railEntries[index].route);
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
                selectedIconTheme:
                    IconThemeData(color: scheme.onPrimaryContainer),
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
                destinations: [
                  for (final e in railEntries)
                    NavigationRailDestination(
                      icon: Icon(e.icon),
                      label: Text(e.label),
                    ),
                ],
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
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
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
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      context.go(entries[index].route);
                    },
                    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                      (states) => TextStyle(
                        fontSize: 11,
                        fontWeight:
                            states.contains(WidgetState.selected)
                                ? FontWeight.w700
                                : FontWeight.w500,
                        color: states.contains(WidgetState.selected)
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    destinations: [
                      for (final e in entries)
                        NavigationDestination(
                          icon: Icon(e.icon),
                          label: e.label,
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  /// Entrées de la barre inférieure (navigation mobile).
  /// Ordre non-M3U : Accueil, Chaînes TV, Films, Séries, Matchmaking, Réglages.
  /// En mode M3U (pas de VOD/Séries dédiées) : Contenus à la place.
  static List<_NavEntry> _navEntries(bool isM3u) => [
        const _NavEntry(
          icon: Icons.home_rounded,
          label: 'Accueil',
          route: '/home',
        ),
        const _NavEntry(
          icon: Icons.live_tv,
          label: 'Chaînes TV',
          route: '/live',
        ),
        if (!isM3u) ...[
          const _NavEntry(
            icon: Icons.movie,
            label: 'Films',
            route: '/vod',
          ),
          const _NavEntry(
            icon: Icons.tv,
            label: 'Séries',
            route: '/series',
          ),
        ],
        if (isM3u)
          const _NavEntry(
            icon: Icons.explore_rounded,
            label: 'Contenus',
            route: '/browse',
          ),
        if (!isM3u)
          const _NavEntry(
            icon: Icons.recommend,
            label: 'Matchmaking',
            route: '/matchmaking',
          ),
        const _NavEntry(
          icon: Icons.settings,
          label: 'Réglages',
          route: '/settings',
        ),
      ];

  /// Entrées du rail (navigation large) : même base que la barre inférieure,
  /// avec l'accès EPG inséré après « Chaînes TV ».
  static List<_NavEntry> _railEntries(bool isM3u) {
    final base = _navEntries(isM3u);
    return [
      ...base.take(2),
      const _NavEntry(
        icon: Icons.calendar_today,
        label: 'EPG',
        route: '/epg',
      ),
      ...base.skip(2),
    ];
  }

  /// Index de l'entrée dont la route est un préfixe de la position courante.
  /// Repli sur la première entrée (Accueil) si rien ne correspond.
  static int _indexFor(String location, List<_NavEntry> entries) {
    for (var i = 0; i < entries.length; i++) {
      if (location.startsWith(entries[i].route)) return i;
    }
    return 0;
  }

  String _titleForPath(String path) {
    if (path.startsWith('/live')) return 'Chaînes TV';
    if (path.startsWith('/series')) return 'Séries';
    if (path.startsWith('/vod')) return 'Films';
    if (path.startsWith('/matchmaking')) return 'Pour vous';
    if (path.startsWith('/browse')) return 'Contenus';
    if (path.startsWith('/replay')) return 'Replay';
    if (path.startsWith('/epg')) return 'EPG';
    if (path.startsWith('/search')) return 'Recherche';
    if (path.startsWith('/subscriptions')) return 'Abonnements';
    if (path.startsWith('/settings/advanced')) return 'Configuration Avancée';
    if (path.startsWith('/settings')) return 'Réglages';
    return AppConstants.appName;
  }
}

/// Entrée de navigation partagée (barre inférieure / rail) : icône, libellé
/// et route associée. L'index sélectionné et la route cible se déduisent de
/// cette table, évitant les switchs fragiles index -> route.
class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
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
