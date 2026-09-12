/// Navigation back behavior metadata attached to routes.
///
/// Centralizes the "what happens on back" decision in the route definition,
/// not in widgets. Read via [GoRouterState.meta] or [RouteMetaX].
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Defines how a route reacts to a back request (gesture, button, system).
enum BackBehaviorType {
  /// Standard pop — route was pushed onto a stack.
  pop,

  /// Pop if possible, otherwise navigate to a fallback route.
  popOrFallback,

  /// Custom logic — receives context and router for full control.
  custom,
}

/// Immutable metadata attached to a route via `GoRoute.extra` or `pageBuilder`.
@immutable
class RouteMeta {
  /// How this route handles back.
  final BackBehaviorType type;

  /// Fallback route for [BackBehaviorType.popOrFallback].
  final String? fallback;

  /// Custom handler for [BackBehaviorType.custom].
  final void Function(BuildContext context, GoRouter router)? customHandler;

  /// Optional restoration ID for state restoration after process death.
  final String? restorationId;

  const RouteMeta._({
    required this.type,
    this.fallback,
    this.customHandler,
    this.restorationId,
  });

  /// Standard pop behavior.
  const RouteMeta.pop({String? restorationId})
      : this._(
          type: BackBehaviorType.pop,
          fallback: null,
          customHandler: null,
          restorationId: restorationId,
        );

  /// Pop if possible, otherwise go to [fallback].
  const RouteMeta.popOrFallback(String fallback, {String? restorationId})
      : this._(
          type: BackBehaviorType.popOrFallback,
          fallback: fallback,
          customHandler: null,
          restorationId: restorationId,
        );

  /// Custom back handling.
  const RouteMeta.custom(
    void Function(BuildContext context, GoRouter router) handler, {
    String? restorationId,
  }) : this._(
          type: BackBehaviorType.custom,
          fallback: null,
          customHandler: handler,
          restorationId: restorationId,
        );
}

/// Typed accessors on [GoRouterState] for route metadata.
extension RouteMetaX on GoRouterState {
  /// The [RouteMeta] attached to this route, or null if none.
  RouteMeta? get meta => extra as RouteMeta?;

  /// The back behavior for this route, defaulting to pop.
  BackBehaviorType get backBehaviorType => meta?.type ?? BackBehaviorType.pop;

  /// The fallback route for popOrFallback, if any.
  String? get fallback => meta?.fallback;

  /// The custom handler, if any.
  void Function(BuildContext context, GoRouter router)? get customHandler =>
      meta?.customHandler;

  /// The restoration ID for this route, if any.
  String? get restorationId => meta?.restorationId;
}

/// Convenience extension on [RouteMeta] for direct access.
extension RouteMetaExt on RouteMeta {
  BackBehaviorType get backBehaviorType => type;
}