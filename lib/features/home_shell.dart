import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/profile_avatar.dart';
import '../models/user_profile.dart';
import '../providers/providers.dart';
import '../services/subscription_manager.dart';

final sourceTypeProvider = FutureProvider<String?>((ref) async {
  final sub = await SubscriptionManager().getActiveSubscription();
  return sub['type'];
});

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isM3u = ref.watch(sourceTypeProvider).valueOrNull == 'm3u';
    final profile = ref.watch(currentProfileProvider);
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
        icon: Icon(Icons.settings),
        label: 'Réglages',
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForPath(GoRouterState.of(context).uri.path)),
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
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                2 when isM3u => '/settings',
                2 => '/series',
                3 => '/vod',
                4 => '/radio',
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
    if (path.startsWith('/replay')) return 'Replay';
    if (path.startsWith('/epg')) return 'EPG';
    if (path.startsWith('/search')) return 'Recherche';
    if (path.startsWith('/ai')) return 'Orbit IA';
    if (path.startsWith('/vpn')) return 'VPN';
    if (path.startsWith('/subscriptions')) return 'Abonnements';
    if (path.startsWith('/settings')) return 'Réglages';
    return AppConstants.appName;
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