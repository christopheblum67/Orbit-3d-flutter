import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/auth/profile_preferences_screen.dart';
import 'package:orbit_3d_flutter/features/multivideo/multivideo_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _Storage extends StorageService {
  final profiles = <String, UserProfile>{};
  bool fail = false;
  Completer<void>? pending;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (fail) throw StateError('write failed');
    await pending?.future;
    profiles[profile.id] = UserProfile.fromMap(profile.toMap());
  }

  @override
  Future<List<UserProfile>> getProfiles() async => profiles.values.toList();
}

UserProfile _profile(String id) => UserProfile(
      id: id,
      firstName: id,
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
    );

Widget _app(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('Multi TV is saved and isolated per profile', (tester) async {
    final storage = _Storage();
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        preferencesProvider.overrideWithBuild(
          (ref, notifier) => const UserPreferences(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final profiles = container.read(currentProfileProvider.notifier);
    profiles.setUserProfile(_profile('a'));
    await tester.pumpWidget(_app(container, const ProfilePreferencesScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Live video preview'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Live video preview'), findsOneWidget);
    Finder switchTile() => find.widgetWithText(SwitchListTile, 'Multi TV');
    expect(tester.widget<SwitchListTile>(switchTile()).value, isTrue);
    await tester.ensureVisible(switchTile());
    await tester.tap(switchTile());
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(switchTile()).value, isFalse);
    expect(storage.profiles['a']!.multiTvEnabled, isFalse);
    Focus.of(tester.element(switchTile())).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(switchTile()).value, isTrue);
    await tester.tap(switchTile());
    await tester.pumpAndSettle();

    profiles.setUserProfile(_profile('b'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(switchTile()).value, isTrue);
    profiles.setUserProfile(storage.profiles['a']);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(switchTile()).value, isFalse);
    await tester.tap(switchTile());
    await tester.pumpAndSettle();
    expect(storage.profiles['a']!.multiTvEnabled, isTrue);
  });

  testWidgets('a failed save leaves the setting unchanged and reports it',
      (tester) async {
    final storage = _Storage()..fail = true;
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        preferencesProvider.overrideWithBuild(
          (ref, notifier) => const UserPreferences(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(currentProfileProvider.notifier)
        .setUserProfile(_profile('a'));
    await tester.pumpWidget(_app(container, const ProfilePreferencesScreen()));
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(SwitchListTile, 'Multi TV');
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(find.text('Could not save the Multi TV setting.'), findsOneWidget);
  });

  test('a late save does not replace the newly selected profile', () async {
    final storage = _Storage()..pending = Completer<void>();
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final profiles = container.read(currentProfileProvider.notifier);
    profiles.setUserProfile(_profile('a'));
    final save = profiles.setMultiTvEnabled(false);
    profiles.setUserProfile(_profile('b'));
    storage.pending!.complete();
    await save;
    expect(container.read(currentProfileProvider)!.id, 'b');
    expect(storage.profiles['a']!.multiTvEnabled, isFalse);
  });

  testWidgets('disabled profiles cannot open Multi TV directly',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const MultiVideoScreen()),
      ],
    );
    addTearDown(router.dispose);
    container.read(currentProfileProvider.notifier).setUserProfile(
          _profile('a').copyWith(settings: {'multiTvEnabled': false}),
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining('Multi TV is disabled for this profile'),
      findsOneWidget,
    );
  });
}
