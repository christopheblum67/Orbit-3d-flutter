import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/auth/profile_preferences_screen.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';
import 'package:orbit_3d_flutter/services/profile_pin_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CloudflareSession extends Fake implements CloudflareSessionManager {
  _CloudflareSession({required this.ready, this.fail = false});

  final bool ready;
  final bool fail;
  final calls = <bool>[];

  @override
  bool get isReady => ready;

  @override
  Future<void> renewSession({bool force = false}) async {
    calls.add(force);
    if (fail) throw StateError('renewal failed');
  }
}

class _MemoryStorage extends StorageService {
  _MemoryStorage(this.profiles);

  List<UserProfile> profiles;
  var clearCalls = 0;

  @override
  Future<UserPreferences> getPreferences() async => const UserPreferences();

  @override
  Future<List<UserProfile>> getProfiles() async => profiles;

  @override
  Future<List<UserProfile>> clearProfilePins() async {
    clearCalls++;
    final cleared = <UserProfile>[];
    profiles = profiles.map((profile) {
      if (!profile.hasPin) return profile;
      final updated = profile.copyWith(clearPin: true);
      cleared.add(updated);
      return updated;
    }).toList();
    return cleared;
  }
}

UserProfile _profile(String id, {String? pin}) => UserProfile(
      id: id,
      firstName: id,
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
      pinHash: pin,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('free mode is a saved placeholder accessible by remote',
      (tester) async {
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWith((ref) => null),
    ]);
    addTearDown(container.dispose);
    await container.read(advancedSettingsProvider.notifier).load();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdvancedSettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final title = find.text('Mode gratuit');
    final toggle = find.widgetWithText(SwitchListTile, 'Mode gratuit');
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(
        find.text(
            'Option à configurer ultérieurement, sans effet pour le moment.'),
        findsOneWidget);
    Focus.of(tester.element(title)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    final reloaded = ProviderContainer();
    addTearDown(reloaded.dispose);
    await reloaded.read(advancedSettingsProvider.notifier).load();
    expect(reloaded.read(advancedSettingsProvider).freeMode, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
        (await SharedPreferences.getInstance())
            .getBool(AdvancedSettings.kFreeMode),
        isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  test('free mode is translated in all supported languages', () {
    for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
      final l = lookupAppLocalizations(Locale(language));
      expect(l.freeMode, isNotEmpty);
      expect(l.freeModePending, isNotEmpty);
    }
  });

  for (final scenario in ['ready', 'absent', 'error']) {
    testWidgets('Cloudflare action reports $scenario correctly',
        (tester) async {
      final session = _CloudflareSession(
        ready: scenario != 'absent',
        fail: scenario == 'error',
      );
      final container = ProviderContainer(overrides: [
        cloudflareSessionProvider.overrideWithValue(session),
        activeSubscriptionProvider.overrideWith((ref) => null),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdvancedSettingsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      final action = find.text('Réinitialiser la session Cloudflare');
      await tester.scrollUntilVisible(action, 250,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      if (scenario == 'ready') {
        final tile =
            find.ancestor(of: action, matching: find.byType(TvFocus)).first;
        final focusChild = find
            .descendant(
              of: tile,
              matching: find.byType(ExcludeFocus),
            )
            .first;
        Focus.of(tester.element(focusChild)).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
      } else {
        await tester.tap(action);
      }
      await tester.pumpAndSettle();
      expect(session.calls, scenario == 'absent' ? isEmpty : [true]);
      final l = lookupAppLocalizations(const Locale('fr'));
      expect(
        find.text(scenario == 'ready'
            ? l.snackCloudflareReset
            : scenario == 'absent'
                ? l.cloudflareNoActiveSession
                : l.connectionServerUnreachable),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('requires confirmation before removing every profile PIN',
      (tester) async {
    final storage = _MemoryStorage([
      _profile('active', pin: '1234'),
      _profile('second', pin: '5678'),
      _profile('unprotected'),
    ]);
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(storage),
      currentProfileProvider.overrideWithBuild(
        (ref, notifier) => _profile('active', pin: '1234'),
      ),
      profilesProvider.overrideWith((ref) async => storage.profiles),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfilePreferencesScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final action = find.text('Supprimer les codes PIN des profils');
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(action, 250, scrollable: scrollable);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Supprimer les codes PIN des profils ?'), findsOneWidget);
    expect(storage.clearCalls, 0);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(storage.clearCalls, 0);
    expect(storage.profiles.where((profile) => profile.hasPin), hasLength(2));

    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer les PIN'));
    await tester.pumpAndSettle();

    expect(storage.clearCalls, 1);
    expect(storage.profiles.where((profile) => profile.hasPin), isEmpty);
    expect(container.read(currentProfileProvider)?.hasPin, isFalse);
    expect(find.text('Codes PIN supprimés de 2 profil(s).'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('PIN removal warning uses the selected language', (tester) async {
    final storage = _MemoryStorage([_profile('active', pin: '1234')]);
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(storage),
      currentProfileProvider.overrideWithBuild(
        (ref, notifier) => _profile('active', pin: '1234'),
      ),
      profilesProvider.overrideWith((ref) async => storage.profiles),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePreferencesScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final action = find.text('Remove profile PINs');
    await tester.scrollUntilVisible(action, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Remove profile PINs?'), findsOneWidget);
    expect(
      find.text(
        'PINs will be removed from 1 profile(s). Profiles and their data will remain on this device. The changes may be synchronized with devices shared through the cloud.',
      ),
      findsOneWidget,
    );
    expect(storage.clearCalls, 0);
  });

  testWidgets('bulk PIN removal checks for locks again after confirmation',
      (tester) async {
    var now = DateTime(2026, 1, 1);
    final guard = ProfilePinGuard(clock: () => now);
    final locked = _profile('locked', pin: '1234');
    final storage = _MemoryStorage([locked, _profile('other', pin: '5678')]);
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(storage),
      profilePinGuardProvider.overrideWithValue(guard),
      profilesProvider.overrideWith((ref) async => storage.profiles),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePreferencesScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final action = find.text('Supprimer les codes PIN des profils');
    await tester.scrollUntilVisible(action, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(action);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await guard.verify(locked, '0000');
    }
    await tester.tap(find.text('Supprimer les PIN'));
    await tester.pumpAndSettle();
    expect(storage.clearCalls, 0);
    expect(storage.profiles.where((profile) => profile.hasPin), hasLength(2));
    expect(find.textContaining('Un profil est temporairement bloqué'),
        findsOneWidget);

    now = now.add(const Duration(hours: 2));
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer les PIN'));
    await tester.pumpAndSettle();
    expect(storage.clearCalls, 1);
    expect(storage.profiles.where((profile) => profile.hasPin), isEmpty);
  });
}
