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
          if (navigator.canPop() && _hasModalRoute(context, navigator)) {
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
  ///
  /// A modal (dialog / bottom sheet) is pushed onto the Navigator on top of the
  /// page route. When one is open, the enclosing page route is no longer the
  /// current route (`isCurrent == false`) while the Navigator can still pop.
  /// This is more reliable than the old `navigator.canPop()` heuristic, which
  /// was almost always true on any pushed route. If a modal is present, we let
  /// the Navigator pop it (closing the dialog/bottom-sheet) before handling the
  /// route-level back behavior.
  bool _hasModalRoute(BuildContext context, NavigatorState navigator) {
    final route = ModalRoute.of(context);
    return navigator.canPop() && route != null && !route.isCurrent;
  }
}

/// Wrapper pour routes `builder:` (modales) qui ajoute un PopScope
/// avec comportement de retour standard (pop ou fallback).
class ModalBackHandling extends StatelessWidget {
  const ModalBackHandling({
    super.key,
    required this.child,
    this.meta = const RouteMeta.pop(),
  });

  final Widget child;
  final RouteMeta meta;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) return;

        final router = GoRouter.of(context);
        final navigator = Navigator.of(context);

        if (navigator.canPop() && _hasModalRoute(context, navigator)) {
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
    );
  }

  bool _hasModalRoute(BuildContext context, NavigatorState navigator) {
    final route = ModalRoute.of(context);
    return navigator.canPop() && route != null && !route.isCurrent;
  }
}
