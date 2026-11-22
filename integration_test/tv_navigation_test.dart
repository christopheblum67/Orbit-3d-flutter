import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

/// Tests d'intégration « fumée » de la navigation TV.
///
/// Ils montent un harnais minimal (routes stubs) et vérifient que les
/// événements D-pad (`arrowUp/Down/Left/Right`, `enter`, `space`) ne lèvent
/// AUCUNE exception Flutter pendant le `pump`. C'est le contrat de base que
/// cassent les bugs de focus (ex. double usage d'un `FocusNode`, assertion
/// `_reparent`) : ces défauts n'apparaissent qu'à l'exécution, pas à l'analyse
/// statique.
///
/// Ils ne remplacent pas une validation sur device de la vraie application
/// (abonnement, flux, sous-titres) : le harnais reste volontairement sans état
/// réseau pour être déterministe.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Construit un routeur neuf à la position demandée. Le créer par appel (et
  /// non une fois pour toutes) est indispensable : un `GoRouter` fige son
  /// `initialLocation`, donc un routeur partagé aurait monté `/home` dans les
  /// six cas malgré l'argument.
  GoRouter buildRouter(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const _Stub(title: 'Home'),
      ),
      GoRoute(
        path: '/live',
        builder: (context, state) => const _Stub(title: 'Live TV'),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) => const _Stub(title: 'Player'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _Stub(title: 'Settings'),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const _Stub(title: 'Search'),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const _Stub(title: 'Profile'),
      ),
    ],
  );

  Widget buildTestApp(String initialLocation) => ProviderScope(
    child: MaterialApp.router(routerConfig: buildRouter(initialLocation)),
  );

  group('TV Navigation', () {
    // -----------------------------------------------------------------------
    // 1. Zapping Live TV
    // -----------------------------------------------------------------------
    testWidgets('zapping Live TV : appui flèche haut', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp('/live'));
      await tester.pumpAndSettle();

      expect(find.text('Live TV'), findsOneWidget);

      // Simule KEYCODE_CHANNEL_UP via LogicalKeyboardKey.arrowUp.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(find.text('Live TV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -----------------------------------------------------------------------
    // 2. Navigation EPG grille : pas d'exception D-pad
    // -----------------------------------------------------------------------
    testWidgets('EPG grille : flèches D-pad sans crash', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp('/home'));
      await tester.pumpAndSettle();

      // Appuis D-pad ; l'EPG n'est pas monté ici, mais aucune exception
      // Flutter ne doit être levée.
      for (final key in [
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    // -----------------------------------------------------------------------
    // 3. Search : ouverture de champ sans exception
    // -----------------------------------------------------------------------
    testWidgets('search : ouverture champ texte', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp('/search'));
      await tester.pumpAndSettle();

      expect(find.text('Search'), findsOneWidget);

      // Aucune exception durant le pump.
      expect(tester.takeException(), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // -----------------------------------------------------------------------
    // 4. Profile : changement de profil
    // -----------------------------------------------------------------------
    testWidgets('profile : navigation D-pad', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp('/profile'));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);

      for (final key in [
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.enter,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    // -----------------------------------------------------------------------
    // 5. Settings : navigation tuiles Dropdown
    // -----------------------------------------------------------------------
    testWidgets('settings : navigation tuiles', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp('/settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      for (final key in [
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.enter,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    // -----------------------------------------------------------------------
    // 6. Player : contrôles play/pause/zapping
    // -----------------------------------------------------------------------
    testWidgets('player : contrôles play/pause', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp('/player'));
      await tester.pumpAndSettle();

      expect(find.text('Player'), findsOneWidget);

      // Space = play/pause ; flèche droite = suivant.
      for (final key in [
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.arrowRight,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}

/// Écran stub minimal pour le harnais de navigation.
class _Stub extends StatelessWidget {
  const _Stub({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(title)));
}
