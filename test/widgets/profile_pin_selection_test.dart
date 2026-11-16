import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/features/profile/profile_edit_screen.dart';
import 'package:orbit_3d_flutter/features/profile/profile_selection_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/profile_pin.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _Storage extends StorageService {
  UserProfile? saved;
  @override
  Future<void> saveProfile(UserProfile profile) async => saved = profile;
  @override
  Future<void> setSetting(String key, dynamic value) async {}
}

void main() {
  late Directory cacheDirectory;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() {
    cacheDirectory = Directory.systemTemp.createTempSync('orbit_pin_widget_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            pathChannel, (_) async => cacheDirectory.path);
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    if (cacheDirectory.existsSync()) {
      await cacheDirectory.delete(recursive: true);
    }
  });
  for (final editing in [false, true]) {
    testWidgets(
        'confirmed PIN is saved when ${editing ? 'editing' : 'creating'}',
        (tester) async {
      final storage = _Storage();
      final existing = UserProfile(
        id: 'existing',
        firstName: 'Alex',
        dateOfBirth: DateTime(1990),
        gender: 'Homme',
        favoriteGenres: const [],
        pinHash: editing ? '9999' : null,
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
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
            builder: (_, __) =>
                ProfileEditScreen(profileId: editing ? 'existing' : null),
          ),
          GoRoute(
            path: '/profile/pin',
            builder: (context, state) {
              final args = state.extra! as PinPadArgs;
              return Scaffold(
                body: TextButton(
                  onPressed: () => context.pop('1234'),
                  child:
                      Text(args.confirmation ? 'Confirmer PIN' : 'Saisir PIN'),
                ),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            profilesProvider.overrideWith(
              (ref) async => editing ? [existing] : <UserProfile>[],
            ),
            currentProfileProvider.overrideWithBuild(
              (ref, notifier) => editing ? existing : null,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      if (!editing) {
        await tester.enterText(find.byType(TextFormField), 'Alex');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
      }
      final scrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      final pinSwitch = find.byType(SwitchListTile);
      await tester.scrollUntilVisible(pinSwitch, 300, scrollable: scrollable);
      if (editing) {
        await tester.scrollUntilVisible(
          find.text('Changer le code PIN'),
          100,
          scrollable: scrollable,
        );
        await tester.ensureVisible(find.text('Changer le code PIN'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Changer le code PIN'));
      } else {
        await tester.tap(pinSwitch);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saisir PIN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer PIN'));
      await tester.pumpAndSettle();
      final save = find.text(editing ? 'Enregistrer' : 'Créer le profil');
      await tester.scrollUntilVisible(save, 300, scrollable: scrollable);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      final saveButton = find.ancestor(
        of: save,
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      for (var i = 0; i < 50; i++) {
        if (saveButton.evaluate().isEmpty) {
          await tester.scrollUntilVisible(save, 300, scrollable: scrollable);
          await tester.ensureVisible(save);
          await tester.pump();
        }
        if (tester.widget<FilledButton>(saveButton).onPressed != null) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(storage.saved, isNotNull);
      expect(storage.saved!.hasPin, isTrue);
      expect(storage.saved!.pinHash, isNot('1234'));
      expect(
        await tester.runAsync(() => ProfilePin.verify(storage.saved!, '1234')),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });
  }

  testWidgets('real PIN pad confirms twice before saving protection',
      (tester) async {
    final storage = _Storage();
    final tvMode = TvModeNotifier();
    addTearDown(tvMode.dispose);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/create'),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      GoRoute(path: '/create', builder: (_, __) => const ProfileEditScreen()),
      GoRoute(
        path: '/profile/pin',
        builder: (_, state) => PinPadScreen(args: state.extra! as PinPadArgs),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tvModeNotifierProvider.overrideWithValue(tvMode),
        storageServiceProvider.overrideWithValue(storage),
        profilesProvider.overrideWith((ref) async => <UserProfile>[]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Alex');
    tester.testTextInput.hide();
    tvMode.enable();
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.byType(SwitchListTile), 300,
        scrollable: scrollable);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    expect(find.text('Choisissez un code à 4 chiffres'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Confirmez votre code à 4 chiffres'), findsOneWidget);
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(SwitchListTile), 300,
        scrollable: scrollable);
    for (var i = 0; i < 50; i++) {
      if (tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value) {
        break;
      }
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue);
    expect(storage.saved, isNull);
    await tester.scrollUntilVisible(find.text('Créer le profil'), 300,
        scrollable: scrollable);
    await tester.pumpAndSettle();
    final saveButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Créer le profil'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(saveButton.focusNode?.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.saved?.hasPin, isTrue);
    expect(
        await tester.runAsync(() => ProfilePin.verify(storage.saved!, '1234')),
        isTrue);
  });

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
              onPressed: () => context.pop(args.confirmation ? '9999' : '1234'),
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
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
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
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
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
