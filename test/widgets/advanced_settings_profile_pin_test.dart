import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _MemoryStorage extends StorageService {
  _MemoryStorage(this.profiles);

  List<UserProfile> profiles;
  var clearCalls = 0;

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

  testWidgets('requires confirmation before removing every profile PIN',
      (tester) async {
    final storage = _MemoryStorage([
      _profile('active', pin: '1234'),
      _profile('second', pin: '5678'),
      _profile('unprotected'),
    ]);
    final container = ProviderContainer(overrides: [
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
        home: const AdvancedSettingsScreen(),
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
        home: AdvancedSettingsScreen(),
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
}
