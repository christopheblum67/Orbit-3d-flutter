import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/navigation/app_router.dart' as routes;
import 'package:orbit_3d_flutter/main.dart' as app;
import 'package:orbit_3d_flutter/orbit_app.dart' as root;

Iterable<String> _paths(List<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) yield route.path;
    yield* _paths(route.routes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('main preserves the public application widget', () {
    expect(const app.OrbitApp(), isA<root.OrbitApp>());
  });

  test('router uses the startup location and remains exported by main', () {
    routes.routerInitialLocation = '/onboarding';
    final router = routes.router;
    expect(app.router, same(router));
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    final paths = _paths(router.configuration.routes).toSet();
    expect(
      paths,
      containsAll([
        '/legal',
        '/profiles',
        '/onboarding',
        '/home',
        '/live',
        '/vod',
        '/series',
        '/player',
        '/episode/detail',
        '/subscriptions',
        '/settings',
      ]),
    );
    router.go('/profiles?startup=true');
    expect(router.routeInformationProvider.value.uri.path, '/profiles');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['startup'],
      'true',
    );
  });
}
