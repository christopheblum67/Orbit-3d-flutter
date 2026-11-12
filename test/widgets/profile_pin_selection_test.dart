import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/features/profile/profile_edit_screen.dart';
import 'package:orbit_3d_flutter/features/profile/profile_selection_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _Storage extends StorageService {
  UserProfile? saved;
  @override
  Future<void> saveProfile(UserProfile profile) async => saved = profile;
  @override
  Future<void> setSetting(String key, dynamic value) async {}
}

void main() {
  testWidgets('a mismatched confirmation does not enable a PIN',
      (tester) async {
    final router = GoRouter(initialLocation: '/create', routes: [
      GoRoute(
        path: '/create',
        builder: (_, __) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/pin',
        builder: (context, state) {
          final args = state.extra! as PinPadArgs;
          return Scaffold(
            body: TextButton(
              onPressed: () =>
                  context.pop(args.confirmation ? '9999' : '1234'),
              child: Text(args.confirmation ? 'Confirmer PIN' : 'Saisir PIN'),
            ),
          );
        },
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    ).first;
    final pinSwitch = find.byType(SwitchListTile);
    await tester.scrollUntilVisible(pinSwitch, 300, scrollable: scrollable);
    await tester.tap(pinSwitch);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saisir PIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer PIN'));
    await tester.pumpAndSettle();
    expect(find.text('Les codes PIN ne correspondent pas.'), findsOneWidget);
    await tester.scrollUntilVisible(pinSwitch, 300, scrollable: scrollable);
    expect(tester.widget<SwitchListTile>(pinSwitch).value, isFalse);
  });

  testWidgets('disabling a PIN is persisted by the editor', (tester) async {
    final profile = UserProfile(
      id: 'private',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
      pinHash: '1234',
    );
    final storage = _Storage();
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/edit'),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      GoRoute(
        path: '/edit',
        builder: (_, __) => const ProfileEditScreen(profileId: 'private'),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [profile]),
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    final pinSwitch = find.byType(SwitchListTile);
    final scrollable = find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(pinSwitch, 300, scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(pinSwitch).value, isTrue);
    await tester.tap(pinSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(pinSwitch).value, isFalse);
    await tester.scrollUntilVisible(find.text('Enregistrer'), 300,
        scrollable: scrollable);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(storage.saved, isNotNull);
    expect(storage.saved!.pinHash, isNull);
  });

  testWidgets('adult PIN gates selection, editing and deletion',
      (tester) async {
    final protected = UserProfile(
      id: 'private',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
      pinHash: '1234',
    );
    final previous = UserProfile(
      id: 'previous',
      firstName: 'Camille',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final router = GoRouter(initialLocation: '/profiles', routes: [
      GoRoute(
        path: '/profiles',
        builder: (_, __) => const ProfileSelectionScreen(startupFlow: true),
      ),
      GoRoute(
        path: '/profile/pin',
        builder: (_, state) => PinPadScreen(args: state.extra! as PinPadArgs),
      ),
      GoRoute(
        path: '/profile/edit/:id',
        builder: (_, __) => const Scaffold(body: Text('Édition ouverte')),
      ),
      GoRoute(
        path: '/startup',
        builder: (_, __) => const Scaffold(body: Text('Profil ouvert')),
      ),
    ]);
    addTearDown(router.dispose);
    final container = ProviderContainer(overrides: [
      profilesProvider.overrideWith((ref) async => [protected, previous]),
      currentProfileProvider.overrideWithBuild((ref, notifier) => previous),
      storageServiceProvider.overrideWithValue(_Storage()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('private'));
    final avatar = find.descendant(
      of: card,
      matching: find.byType(ProfileAvatar),
    );
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.text('Code PIN requis'), findsOneWidget);
    expect(container.read(currentProfileProvider)?.id, 'previous');
    for (final digit in ['0', '0', '0', '0']) {
      await tester.ensureVisible(find.text(digit));
      await tester.tap(find.text(digit));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Code incorrect'), findsOneWidget);
    await tester.tap(find.byTooltip('Annuler'));
    await tester.pumpAndSettle();
    expect(container.read(currentProfileProvider)?.id, 'previous');

    await tester.tap(find.descendant(
      of: card,
      matching: find.byIcon(Icons.edit_rounded),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Code PIN requis'), findsOneWidget);
    await tester.tap(find.byTooltip('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Édition ouverte'), findsNothing);

    await tester.tap(find.descendant(
      of: card,
      matching: find.byIcon(Icons.delete_outline_rounded),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Code PIN requis'), findsOneWidget);
    await tester.tap(find.byTooltip('Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    for (final digit in ['1', '2', '3', '4']) {
      await tester.ensureVisible(find.text(digit));
      await tester.tap(find.text(digit));
      await tester.pumpAndSettle();
    }
    expect(find.text('Profil ouvert'), findsOneWidget);
    expect(container.read(currentProfileProvider)?.id, 'private');
  });
}
