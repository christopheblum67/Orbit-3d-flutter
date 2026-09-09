import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/navigation/route_meta.dart';
import 'package:orbit_3d_flutter/core/navigation/with_back_handling.dart';
import 'package:orbit_3d_flutter/features/profile/profile_edit_screen.dart';

class _ShellHome extends StatelessWidget {
  const _ShellHome({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

void main() {
  group('popOrFallback sur onglet shell', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/live',
        routes: [
          ShellRoute(
            builder: (context, state, child) => _ShellHome(child: child),
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const Scaffold(
                    body: Center(child: Text('HOME')),
                  ),
                ),
              ),
              GoRoute(
                path: '/live',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: WithBackHandling(
                    meta: RouteMeta.popOrFallback('/home', restorationId: 'live'),
                    child: const Scaffold(
                      body: Center(child: Text('LIVE')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });

    testWidgets(
        'back sur un onglet interne sans historique → retour à /home',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('LIVE'), findsOneWidget);

      // Simule un appui retour système : maybePop traverse le PopScope de
      // WithBackHandling et déclenche la logique popOrFallback.
      final context = tester.element(find.byType(WithBackHandling));
      final navigator = Navigator.of(context);
      navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('garde formulaire profil', () {
    testWidgets('back avec formulaire non modifié → pas de dialog, pop direct',
        (tester) async {
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/profile/create',
        routes: [
          GoRoute(
            path: '/profiles',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('PROFILES'))),
          ),
          GoRoute(
            path: '/profile/create',
            builder: (context, state) {
              final editKey = GlobalKey<ProfileEditScreenState>();
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) async {
                  if (didPop) return;
                  final canLeave =
                      (await editKey.currentState?.confirmLeave()) ?? true;
                  if (canLeave) {
                    router.go('/profiles');
                  }
                },
                child: ProfileEditScreen(key: editKey),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Créer un profil'), findsOneWidget);

      final context = tester.element(find.byType(ProfileEditScreen));
      Navigator.of(context).maybePop();
      await tester.pumpAndSettle();

      // Pas de dialog, on est partis.
      expect(find.text('Quitter sans sauvegarder ?'), findsNothing);
      expect(find.text('PROFILES'), findsOneWidget);
    });

    testWidgets('back avec formulaire modifié → dialog + annulation conserve',
        (tester) async {
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/profile/create',
        routes: [
          GoRoute(
            path: '/profiles',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('PROFILES'))),
          ),
          GoRoute(
            path: '/profile/create',
            builder: (context, state) {
              final editKey = GlobalKey<ProfileEditScreenState>();
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) async {
                  if (didPop) return;
                  final canLeave =
                      (await editKey.currentState?.confirmLeave()) ?? true;
                  if (canLeave) {
                    router.go('/profiles');
                  }
                },
                child: ProfileEditScreen(key: editKey),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      // Remplit le champ nom → le formulaire devient "sale".
      // La ListView construit ses enfants paresseusement : il faut d'abord
      // faire défiler jusqu'au champ.
      final nameField = find.byType(TextFormField);
      await tester.scrollUntilVisible(
        nameField,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(nameField, 'Alice');
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ProfileEditScreen));
      Navigator.of(context).maybePop();
      await tester.pumpAndSettle();

      // Le dialog de confirmation est affiché ; annulation conserve l'écran.
      expect(find.text('Quitter sans sauvegarder ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Créer un profil'), findsOneWidget);
    });
  });
}
