import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/subscription_manager.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  String? _sourceType;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  Future<void> _loadSource() async {
    final sub = await SubscriptionManager().getActiveSubscription();
    if (mounted) setState(() => _sourceType = sub['type']);
  }

  @override
  Widget build(BuildContext context) {
    final isM3u = _sourceType == 'm3u';
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.live_tv), label: 'Live TV'),
      if (!isM3u) ...[
        const NavigationDestination(icon: Icon(Icons.tv), label: 'Séries'),
        const NavigationDestination(icon: Icon(Icons.movie), label: 'VOD'),
        const NavigationDestination(icon: Icon(Icons.radio), label: 'Radio'),
      ],
      const NavigationDestination(icon: Icon(Icons.settings), label: 'Réglages'),
    ];
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context, destinations),
        onDestinationSelected: (index) {
          final route = switch (index) {
            0 => '/live',
            1 when isM3u => '/settings',
            1 => '/series',
            2 => '/vod',
            3 => '/radio',
            _ => '/settings',
          };
          context.go(route);
        },
        destinations: destinations,
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context, List<NavigationDestination> destinations) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/live')) return 0;
    if (location.startsWith('/series')) return 1;
    if (location.startsWith('/vod')) return 2;
    if (location.startsWith('/radio')) return 3;
    if (location.startsWith('/settings')) {
      return destinations.length - 1;
    }
    return 0;
  }
}
