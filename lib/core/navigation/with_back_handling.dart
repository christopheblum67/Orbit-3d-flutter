/// Wraps a route's content with [PopScope] and [RestorationScope]
/// driven by [RouteMeta] and optional [restorationId].
///
/// Place inside a [GoRoute.pageBuilder] → `MaterialPage(child: WithBackHandling(...))`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_meta.dart';

/// Wraps [child] with back handling per [meta] and restoration per [restorationId].
class WithBackHandling extends StatelessWidget {
  /// The route's metadata containing back behavior.
  final RouteMeta meta;

  /// The route's content.
  final Widget child;

  const WithBackHandling({
    super.key,
    required this.meta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RestorationScope(
      restorationId: meta.restorationId ?? '',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) async {
          if (didPop) return;

          final router = GoRouter.of(context);
          final navigator = Navigator.of(context);

          // If a modal/dialog is open, let it handle back first.
          if (navigator.canPop() && _hasModalRoute(navigator)) {
            navigator.pop();
            return;
          }

          switch (meta.backBehaviorType) {
            case BackBehaviorType.pop:
              if (router.canPop()) {
                router.pop();
              }
              break;

            case BackBehaviorType.popOrFallback:
              if (router.canPop()) {
                router.pop();
              } else if (meta.fallback != null) {
                router.go(meta.fallback!);
              }
              break;

            case BackBehaviorType.custom:
              meta.customHandler?.call(context, router);
              break;
          }
        },
        child: child,
      ),
    );
  }

  /// Checks if there's a modal route (dialog, bottom sheet) that should handle back first.
  bool _hasModalRoute(NavigatorState navigator) {
    // If navigator.canPop() but the router can't, it's likely a modal (dialog, bottom sheet).
    // This is a heuristic: modals are handled by Navigator directly, not GoRouter.
    return navigator.canPop();
  }
}
