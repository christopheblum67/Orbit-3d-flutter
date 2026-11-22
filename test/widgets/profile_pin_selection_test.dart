import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/navigation/app_router.dart' as app;
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/navigation/with_back_handling.dart';
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

Future<void> _enterProfileName(WidgetTester tester, String name) async {
  final scrollable = find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.byType(TextFormField),
    300,
    scrollable: scrollable,
  );
  await tester.enterText(find.byType(TextFormField), name);
}

Future<void> _waitForConfirmedPin(WidgetTester tester) async {
  final scrollable = find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.byType(SwitchListTile),
    300,
    scrollable: scrollable,
  );
  final confirmation =
      find.text('Code PIN confirmé. Enregistrez le profil pour l’activer.');
  for (var i = 0; i < 50 && confirmation.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(confirmation, findsOneWidget);
  expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
}

Future<void> _saveProtectedProfile(WidgetTester tester,
    {required bool editing}) async {
  final button = find.text(editing
      ? 'Enregistrer et activer la protection'
      : 'Créer le profil et activer la protection');
  final scrollable = find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(button, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  late Directory cacheDirectory;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  const pinChannel = MethodChannel('orbit/profile_pin');
  setUpAll(() {
    cacheDirectory = Directory.systemTemp.createTempSync('orbit_pin_widget_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            pathChannel, (_) async => cacheDirectory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pinChannel, (_) async => null);
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pinChannel, null);
    if (cacheDirectory.existsSync()) {
      await cacheDirectory.delete(recursive: true);
    }
  });
  testWidgets('PIN setup instructions follow the selected language',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PinPadScreen(args: PinPadArgs.set()),
      ),
    ));
    expect(find.text('Set a PIN'), findsOneWidget);
    expect(find.text('Choose a 4-digit code'), findsOneWidget);
    expect(find.text('After 4 digits, press ✓ to confirm.'), findsOneWidget);
    expect(find.byTooltip('Cancel'), findsOneWidget);
  });

  for (final editing in [false, true]) {
    testWidgets(
        'confirmed PIN is saved explicitly when ${editing ? 'editing' : 'creating'}',
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
        await _enterProfileName(tester, 'Alex');
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
      await _waitForConfirmedPin(tester);
      expect(storage.saved, isNull);
      await _saveProtectedProfile(tester, editing: editing);
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

  testWidgets('real PIN pad confirms twice and activates protection',
      (tester) async {
    final storage = _Storage();
    final tvMode = TvModeNotifier();
    addTearDown(tvMode.dispose);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/profile/create'),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      app.router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((route) => route.path == '/profile/create'),
      app.router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((route) => route.path == '/profile/pin'),
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
    await _enterProfileName(tester, 'Alex');
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
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
    }
    expect(find.text('Choisissez un code à 4 chiffres'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Confirmez votre code à 4 chiffres'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await _waitForConfirmedPin(tester);
    expect(storage.saved, isNull);
    await _saveProtectedProfile(tester, editing: false);
    expect(storage.saved?.hasPin, isTrue);
    expect(storage.saved?.firstName, 'Alex');
    expect(
        await tester.runAsync(() => ProfilePin.verify(storage.saved!, '1111')),
        isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('phone activates protection after the double PIN entry',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final profile = UserProfile(
      id: 'existing',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: 'Homme',
      favoriteGenres: const [],
    );
    final storage = _Storage();
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/profile/edit/existing'),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      app.router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((route) => route.path == '/profile/edit/:id'),
      app.router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((route) => route.path == '/profile/pin'),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        profilesProvider.overrideWith((ref) async => [profile]),
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
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
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.byType(TextFormField), 300,
        scrollable: scrollable);
    await tester.enterText(find.byType(TextFormField), 'Alex modifié');
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(find.byType(SwitchListTile), 300,
        scrollable: scrollable);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    for (var entry = 0; entry < 2; entry++) {
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();
    }
    await _waitForConfirmedPin(tester);
    expect(storage.saved, isNull);
    await _saveProtectedProfile(tester, editing: true);
    expect(storage.saved?.hasPin, isTrue);
    expect(storage.saved?.firstName, 'Alex modifié');
    expect(
      await tester.runAsync(() => ProfilePin.verify(storage.saved!, '1234')),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('TV PIN pad fits its controls in a 540p viewport',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/pin', routes: [
      GoRoute(
        path: '/pin',
        builder: (_, __) => const PinPadScreen(args: PinPadArgs.set()),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    for (final control in [
      for (var i = 0; i <= 9; i++) find.text('$i'),
      find.byIcon(Icons.backspace_outlined),
      find.byIcon(Icons.check_rounded),
      find.text('Après 4 chiffres, appuyez sur ✓ pour valider.'),
    ]) {
      final rect = tester.getRect(control);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(960));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(540), reason: '$control');
      expect(control.hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('D-pad reveals validation on a very short screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/pin'),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      GoRoute(
        path: '/pin',
        builder: (_, __) => const PinPadScreen(args: PinPadArgs.set()),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
    }
    expect(find.byIcon(Icons.check_rounded).hitTestable(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Ouvrir'), findsOneWidget);
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
        locale: const Locale('fr'),
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
    await tester.ensureVisible(pinSwitch);
    await tester.pumpAndSettle();
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
        locale: const Locale('fr'),
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

  testWidgets('verification attempts reset when the PIN pad is reopened',
      (tester) async {
    final profile = UserProfile(
      id: 'private',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
      pinHash: '1234',
    );
    bool? result;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await context.push<bool>(
                '/profile/pin',
                extra: PinPadArgs.verify(profile),
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/pin',
        builder: (_, state) => PinPadScreen(args: state.extra! as PinPadArgs),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));

    Future<void> enter(String pin) async {
      for (final digit in pin.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await enter('0000');
    expect(find.textContaining('2 essais restants'), findsOneWidget);
    await enter('0000');
    expect(find.textContaining('1 essai restant'), findsOneWidget);
    await enter('0000');
    expect(result, isFalse);
    expect(find.text('Ouvrir'), findsOneWidget);

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await enter('0000');
    expect(find.textContaining('2 essais restants'), findsOneWidget);
    await enter('1234');
    expect(result, isTrue);
  });

  testWidgets('PIN pad displays verification while derivation is pending',
      (tester) async {
    final pending = Completer<Uint8List?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pinChannel, (_) => pending.future);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pinChannel, (_) async => null);
    });
    final profile = UserProfile(
      id: 'private',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
      pinHash: 'pbkdf2-sha256\$120000\$AAECAwQFBgcICQoLDA0ODw==\$'
          'UHAyHKNNva/pslNx0cD4O8r+Bz+64fInTwCm1saOmJk=',
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PinPadScreen(args: PinPadArgs.verify(profile)),
      ),
    ));
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    expect(find.text('Vérification en cours…'), findsOneWidget);
    pending.complete(Uint8List(32));
    await tester.pumpAndSettle();
    expect(find.text('Vérification en cours…'), findsNothing);
    expect(find.textContaining('2 essais restants'), findsOneWidget);
  });

  testWidgets('adult PIN gates selection, editing and deletion',
      (tester) async {
    final protected = UserProfile(
      id: 'private',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
      pinHash: await tester.runAsync(() => ProfilePin.create('1234')),
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
        builder: (_, state) => ModalBackHandling(
          child: PinPadScreen(args: state.extra! as PinPadArgs),
        ),
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
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();

    Future<void> enterPin(String pin, Finder result) async {
      for (final digit in pin.split('')) {
        await tester.ensureVisible(find.text(digit));
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      for (var attempt = 0;
          attempt < 100 && result.evaluate().isEmpty;
          attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    final card = find.byKey(const ValueKey('private'));
    final avatar = find.descendant(
      of: card,
      matching: find.byType(ProfileAvatar),
    );
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.text('Code PIN requis'), findsOneWidget);
    expect(container.read(currentProfileProvider)?.id, 'previous');
    await enterPin('0000', find.textContaining('Code incorrect'));
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
    await enterPin('1234', find.text('Profil ouvert'));
    expect(find.text('Profil ouvert'), findsOneWidget);
    expect(container.read(currentProfileProvider)?.id, 'private');
  });
}
