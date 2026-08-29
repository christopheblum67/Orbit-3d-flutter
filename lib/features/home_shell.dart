import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/live');
              break;
            case 1:
              context.go('/series');
              break;
            case 2:
              context.go('/vod');
              break;
            case 3:
              context.go('/radio');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.live_tv), label: 'Live TV'),
          NavigationDestination(icon: Icon(Icons.tv), label: 'Séries'),
          NavigationDestination(icon: Icon(Icons.movie), label: 'VOD'),
          NavigationDestination(icon: Icon(Icons.radio), label: 'Radio'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/live')) return 0;
    if (location.startsWith('/series')) return 1;
    if (location.startsWith('/vod')) return 2;
    if (location.startsWith('/radio')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }
}
