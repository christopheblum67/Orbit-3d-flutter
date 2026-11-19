import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_profile_recovery_screen.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_activity_sync_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  bool get isAnonymous => false;
}

class _Auth extends Fake implements FirebaseAuth {
  User? user = _User('account');
  final changes = StreamController<User?>.broadcast();
  @override
  User? get currentUser => user;
  @override
  Stream<User?> authStateChanges() async* {
    yield user;
    yield* changes.stream;
  }
}

class _Store extends Fake implements EncryptedDocumentStore {}

class _Recovery extends CloudProfileRecovery {
  _Recovery()
      : super(
          catalog:
              EncryptedProfileCatalog(EncryptedCloudStore(store: _Store())),
          currentUid: () => 'account',
          addLocalProfile: (_, __) async {},
        );

  int published = 0;
  int restored = 0;
  int loads = 0;
  bool failReload = false;
  bool incorrectPhrase = false;
  bool emptyCatalog = false;
  String? deletedCloudProfile;
  String? resetCode;
  List<UserProfile>? publishedSelection;
  final restoredIds = <String>[];
  void Function(String)? onRestore;
  Map<String, Map<String, dynamic>> cloudProfiles = {
    'cloud': {'id': 'cloud', 'firstName': 'Alex', 'avatarUrl': 'icone:rocket'},
  };

  @override
  Future<ProfileCatalogSnapshot> load(String uid, String passphrase) async {
    loads++;
    if (failReload && published > 0) throw StateError('Connexion interrompue.');
    if (incorrectPhrase) throw SecretBoxAuthenticationError();
    if (emptyCatalog) {
      return ProfileCatalogSnapshot(revision: 0, profiles: const {});
    }
    return ProfileCatalogSnapshot(
      revision: 1,
      profiles: {
        ...cloudProfiles,
        if (published > 0) 'local': {'id': 'local', 'firstName': 'Alex'},
      },
    );
  }

  @override
  Future<void> publish(
      String uid, String passphrase, UserProfile profile) async {
    published++;
  }

  @override
  Future<ProfileCatalogSnapshot> publishMissing(
      String uid, String passphrase, List<UserProfile> profiles,
      {void Function()? checkProfiles}) async {
    publishedSelection = profiles;
    return ProfileCatalogSnapshot(
      revision: 1,
      profiles: {for (final p in profiles) p.id: p.toMap()},
    );
  }

  @override
  Future<void> restore(String uid, String passphrase, String profileId) async {
    restored++;
    onRestore?.call(profileId);
    restoredIds.add(profileId);
  }

  @override
  Future<void> deleteCloudProfile(
      String uid, String passphrase, String profileId) async {
    deletedCloudProfile = profileId;
    cloudProfiles.remove(profileId);
  }

  @override
  Future<void> resetCloud(String uid, String newPassphrase) async {
    resetCode = newPassphrase;
    cloudProfiles.clear();
  }
}

class _Activity extends EncryptedActivitySyncNotifier {
  int unlocks = 0;
  bool completeUnlock = false;
  Set<String>? selectedProfiles;
  ScopeConflictChoice? initialConflictChoice;
  ScopeConflictChoice? choice;

  void showProgress() {
    state = const EncryptedActivitySyncState(
      profileId: 'cloud',
      busy: true,
      currentProfileId: 'cloud',
      currentScope: 'favorites',
      completedScopes: 2,
      totalScopes: 8,
    );
  }

  void showCompleted() {
    state = EncryptedActivitySyncState(
      profileId: 'cloud',
      lastSyncAt: DateTime.utc(2026),
    );
  }

  @override
  EncryptedActivitySyncState build() => const EncryptedActivitySyncState();

  @override
  Future<void> unlock({
    required FirebaseAuth auth,
    required String uid,
    required String phrase,
    required ProfileCatalogSnapshot catalog,
    Set<String>? profileIds,
    ScopeConflictChoice? initialConflictChoice,
  }) async {
    unlocks++;
    selectedProfiles = profileIds;
    this.initialConflictChoice = initialConflictChoice;
    if (completeUnlock) {
      state = const EncryptedActivitySyncState(
        profileId: 'cloud',
        busy: true,
        currentProfileId: 'cloud',
        currentScope: 'favorites',
        totalScopes: 1,
      );
      await Future<void>.delayed(Duration.zero);
      showCompleted();
      return;
    }
    state = const EncryptedActivitySyncState(
      profileId: 'cloud',
      error: 'Conflit',
      conflictScope: 'favorites',
    );
  }

  @override
  Future<void> resolveConflict(ScopeConflictChoice selected) async {
    choice = selected;
  }
}

void main() {
  testWidgets('shows actual cloud synchronization progress', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final activity = _Activity();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => []),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    activity.showProgress();
    await tester.pump();
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        0.25);
    expect(find.text('Fait : 25 %'), findsOneWidget);
    expect(find.text('En ce moment : favoris — Alex.'), findsOneWidget);
    activity.showCompleted();
    await tester.pumpAndSettle();
    expect(find.text('Synchronisation terminée'), findsNothing);
    expect(find.text('Les changements sont partagés automatiquement.'),
        findsOneWidget);
    expect(recovery.loads, 2);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('remote can select a cloud-only profile on a TV screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: _Recovery(),
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    const key = ValueKey('cloud-profile-cloud');
    bool cloudFocused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ListTile>()
            ?.key ==
        const ValueKey('profile-tile-cloud');
    for (var i = 0; i < 12 && !cloudFocused(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(cloudFocused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byKey(key)).value, isTrue);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('confirms and synchronizes all checked profiles', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    final activity = _Activity();
    UserProfile profile(String id) => UserProfile(
          id: id,
          firstName: 'Alex',
          dateOfBirth: DateTime.utc(1990),
          gender: '',
          favoriteGenres: const [],
          avatarUrl: id == 'p1' ? 'icone:film' : 'icone:music',
        );
    final profiles = [profile('p1'), profile('p2')];
    recovery.onRestore = (id) => profiles.add(profile(id));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => profiles),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(find.byType(ProfileAvatar), findsNWidgets(3));
    expect(
      tester.widgetList<ProfileAvatar>(find.byType(ProfileAvatar)).map(
            (avatar) => avatar.profile.avatarUrl,
          ),
      ['icone:film', 'icone:music', 'icone:rocket'],
    );
    expect(find.textContaining('Même nom — identifiant'), findsNWidgets(3));
    expect(find.text('Partager tous les profils'), findsOneWidget);
    await tester.tap(find.text('Partager tous les profils'));
    await tester.pumpAndSettle();
    expect(find.text('Partager ces profils ?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(ProfileAvatar),
      ),
      findsNWidgets(3),
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((c) => c.value == true),
        isTrue);
    await tester.tap(find.text('Partager les profils cochés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(recovery.publishedSelection, isNull);
    expect(recovery.restoredIds, isEmpty);
    await tester.tap(find.text('Partager les profils cochés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();
    expect(recovery.restoredIds, ['cloud']);
    expect(
        recovery.publishedSelection!.map((p) => p.id), ['p1', 'p2', 'cloud']);
    expect(activity.selectedProfiles, {'p1', 'p2', 'cloud'});
    expect(activity.initialConflictChoice, ScopeConflictChoice.cloud);
    await tester.tap(find.text('Tout décocher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout cocher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager les profils cochés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();
    expect(activity.unlocks, 2);
    expect(recovery.restoredIds, ['cloud']);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('shows completion after a user-started full sync',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    final activity = _Activity()..completeUnlock = true;
    final local = UserProfile(
      id: 'local',
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final profiles = <UserProfile>[local];
    recovery.onRestore = (id) => profiles.add(UserProfile(
          id: id,
          firstName: 'Alex',
          dateOfBirth: DateTime.utc(1990),
          gender: '',
          favoriteGenres: const [],
        ));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => profiles),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager tous les profils'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();

    expect(activity.unlocks, 1);
    expect(activity.state.lastSyncAt, isNotNull);
    expect(find.text('Synchronisation terminée'), findsOneWidget);
    expect(
      find.text(
        'Les profils sélectionnés et leurs données ont bien été '
        'synchronisés avec le Cloud.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('automatically selects phone profiles after TV pairing',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final activity = _Activity();
    final profile = UserProfile(
      id: 'phone-profile',
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final recovery = _Recovery()..cloudProfiles = {profile.id: profile.toMap()};
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [profile]),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
          initialProfileIds: {profile.id},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();

    expect(activity.selectedProfiles, {profile.id});
    expect(activity.unlocks, 1);
    expect(activity.initialConflictChoice, ScopeConflictChoice.cloud);
    expect(recovery.publishedSelection!.map((item) => item.id), [profile.id]);
    expect(
        tester
            .widget<Checkbox>(find.byKey(
              ValueKey('local-profile-${profile.id}'),
            ))
            .value,
        isTrue);

    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets(
      'a partial cloud recovery can be retried without replacing profiles',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery()
      ..cloudProfiles = {
        'cloud1': {'id': 'cloud1', 'firstName': 'Alex'},
        'cloud2': {'id': 'cloud2', 'firstName': 'Alex'},
      };
    final activity = _Activity();
    final profiles = <UserProfile>[];
    var fail = true;
    recovery.onRestore = (id) {
      if (id == 'cloud2' && fail) throw StateError('Connexion interrompue.');
      profiles.add(UserProfile(
        id: id,
        firstName: 'Alex',
        dateOfBirth: DateTime.utc(1990),
        gender: '',
        favoriteGenres: const [],
      ));
    };
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => List.of(profiles)),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout cocher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager les profils cochés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();
    expect(recovery.restoredIds, ['cloud1']);
    expect(activity.unlocks, 0);
    expect(find.textContaining('Certaines fiches ont peut-être été récupérées'),
        findsOneWidget);
    fail = false;
    await tester.tap(find.text('Partager les profils cochés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();
    expect(recovery.restoredIds, ['cloud1', 'cloud2']);
    expect(activity.selectedProfiles, {'cloud1', 'cloud2'});
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('requires secret confirmation for a new grouped catalogue',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery()..emptyCatalog = true;
    final activity = _Activity();
    final profile = UserProfile(
      id: 'p1',
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [profile]),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager les profils cochés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmer votre code'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.text('Les secrets ne correspondent pas.'), findsOneWidget);
    expect(recovery.publishedSelection, isNull);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(activity.selectedProfiles, {'p1'});
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('accepts numeric codes from 3 to 10 digits', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
        find.text('Le code doit contenir de 3 à 10 chiffres.'), findsOneWidget);
    expect(recovery.loads, 0);
    await tester.enterText(find.byType(TextField), '123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(recovery.loads, 1);
    expect(find.textContaining('plus de 10 minutes'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(recovery.loads, 2);
    await tester.enterText(find.byType(TextField), '12345678901');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
        find.text('Le code doit contenir de 3 à 10 chiffres.'), findsOneWidget);
    expect(recovery.loads, 2);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('can load existing data with a legacy phrase', (tester) async {
    final auth = _Auth();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
      find.text(
          'Un adulte prépare le code. Ensuite, choisis les profils à partager.'),
      findsOneWidget,
    );
    expect(find.text('Code donné par l’adulte'), findsOneWidget);
    expect(find.text('Saisir le même code sur les deux appareils.'),
        findsOneWidget);
    expect(find.textContaining('plus de 10 minutes'), findsOneWidget);
    expect(find.text('Utiliser une ancienne phrase secrète'), findsNothing);
    await tester.tap(find.text('Options pour un adulte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Utiliser une ancienne phrase secrète'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ancienne phrase');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(recovery.loads, 1);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('loads the catalogue automatically after QR pairing',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(recovery.loads, 1);
    expect(find.textContaining('Accès confirmé.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('loads the catalogue when submitting the secret', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(recovery.loads, 1);
    expect(find.textContaining('Accès confirmé.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('remote can leave the phrase field and load the catalogue',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: _Recovery()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final button = find.text('Voir mes profils');
    expect(Focus.of(tester.element(button)).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.textContaining('Accès confirmé.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('only validates a phrase against an existing cloud catalogue',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Accès confirmé.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '654321');
    await tester.pumpAndSettle();
    expect(find.textContaining('Accès confirmé.'), findsNothing);
    recovery.incorrectPhrase = true;
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Code cloud incorrect'), findsOneWidget);

    recovery.incorrectPhrase = false;
    recovery.emptyCatalog = true;
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    expect(find.textContaining('votre code ne peut pas encore être vérifié'),
        findsOneWidget);
    expect(find.textContaining('Accès confirmé.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('reveals and hides the phrase without changing it',
      (tester) async {
    final auth = _Auth();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: _Recovery(),
          initialPhrase: 'phrase secrète',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Afficher la phrase secrète'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
    expect(field.controller!.text, 'phrase secrète');
    await tester.tap(find.byTooltip('Masquer la phrase secrète'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('enables QR pairing only after loading a catalogue',
      (tester) async {
    final auth = _Auth();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: _Recovery()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Options pour un adulte'));
    await tester.pumpAndSettle();
    final button =
        find.widgetWithText(OutlinedButton, 'Associer une TV par QR code');
    if (qrPairingAvailable) {
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    } else {
      expect(button, findsNothing);
    }
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    if (qrPairingAvailable) {
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
      await tester.enterText(find.byType(TextField), 'autre phrase');
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    }
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('requires confirmation to activate and resolve a conflict',
      (tester) async {
    final auth = _Auth();
    final activity = _Activity();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => []),
        currentProfileProvider.overrideWithBuild((ref, notifier) => UserProfile(
              id: 'cloud',
              firstName: 'Alex',
              dateOfBirth: DateTime.utc(1990),
              gender: '',
              favoriteGenres: const [],
            )),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: _Recovery()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Autres options (adulte)'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Partager seulement le profil utilisé'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager seulement le profil utilisé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(activity.unlocks, 0);
    await tester
        .ensureVisible(find.text('Partager seulement le profil utilisé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager seulement le profil utilisé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Cloud est la source'));
    await tester.pumpAndSettle();
    expect(activity.unlocks, 1);
    await tester.ensureVisible(find.byTooltip('Afficher le code cloud'));
    await tester.tap(find.byTooltip('Afficher le code cloud'));
    await tester.pumpAndSettle();
    expect(find.text('Garder les données de l’autre appareil'), findsOneWidget);
    await tester
        .ensureVisible(find.text('Garder les données de l’autre appareil'));
    await tester.tap(find.text('Garder les données de l’autre appareil'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
        isTrue);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(activity.choice, isNull);
    await tester.tap(find.text('Garder les données de l’autre appareil'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(activity.choice, ScopeConflictChoice.cloud);
    await tester.scrollUntilVisible(find.byType(TextField), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), '987654');
    await tester.pumpAndSettle();
    expect(find.text('Profils à ajouter'), findsNothing);
    expect(find.text('Garder les données de l’autre appareil'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('requires explicit selection and matching phrase to publish',
      (tester) async {
    final auth = _Auth();
    final recovery = _Recovery();
    final local = UserProfile(
      id: 'local',
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [local])
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    expect(recovery.published, 0);
    expect(recovery.restored, 0);
    await tester.scrollUntilVisible(find.text('Autres options (adulte)'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sauvegarder'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '654321');
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue);
    await tester.tap(find.byTooltip('Afficher la confirmation'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(recovery.published, 0);
    expect(find.text('Les secrets ne correspondent pas.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    if (!Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus) {
      expect(Focus.of(tester.element(find.text('Annuler'))).hasPrimaryFocus,
          isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(recovery.published, 1);
    await tester.scrollUntilVisible(
        find.text('Fiche sauvegardée. Catalogue actualisé.'), -200,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.text('Fiche sauvegardée. Catalogue actualisé.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('explains prerequisites and reports a failed reload after saving',
      (tester) async {
    final auth = _Auth();
    final recovery = _Recovery()..failReload = true;
    final local = UserProfile(
      id: 'local',
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [local]),
        currentProfileProvider.overrideWithBuild((ref, notifier) => local),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Quels profils veux-tu retrouver sur tes appareils ?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Quels profils veux-tu retrouver sur tes appareils ?'),
        findsOneWidget);
    await tester.scrollUntilVisible(find.text('Autres options (adulte)'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(
            TextButton,
            'Partager seulement le profil utilisé',
          ))
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(find.text('Sauvegarder'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(recovery.published, 1);
    expect(find.textContaining('Fiche sauvegardée, mais le catalogue'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('can remove a cloud profile without deleting the local profile',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    final localProfile = UserProfile(
      id: 'cloud',
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [localProfile]),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Autres options (adulte)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Supprimer du Cloud'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Supprimer du Cloud'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(recovery.deletedCloudProfile, 'cloud');
    expect(find.byKey(const ValueKey('profile-tile-cloud')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('cloud reset requires a new code and keeps local profiles',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = _Auth();
    final recovery = _Recovery();
    final localProfile = UserProfile(
      id: 'local',
      firstName: 'Local',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [localProfile]),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(
          auth: auth,
          recovery: recovery,
          initialPhrase: '123456',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Options pour un adulte'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Options pour un adulte'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Supprimer tout le Cloud et repartir de zéro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Supprimer tout le Cloud et repartir de zéro'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('cloud-reset-code')), '987654');
    await tester.enterText(
        find.byKey(const ValueKey('cloud-reset-confirmation')), '987654');
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();

    expect(recovery.resetCode, '987654');
    expect(find.textContaining('Cloud réinitialisé'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('changing accounts clears the phrase and catalogue',
      (tester) async {
    final auth = _Auth();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Profils à ajouter'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Profils à ajouter'), findsOneWidget);
    auth.user = _User('another-account');
    auth.changes.add(auth.user);
    await tester.pumpAndSettle();
    expect(find.text('Profils à ajouter'), findsNothing);
    await tester.scrollUntilVisible(find.byType(TextField), -200,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('restoration requires an explicit confirmation', (tester) async {
    final auth = _Auth();
    final recovery = _Recovery();
    await tester.pumpWidget(ProviderScope(
      overrides: [profilesProvider.overrideWith((ref) async => [])],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: recovery),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Voir mes profils'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Autres options (adulte)'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autres options (adulte)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Récupérer'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Récupérer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(recovery.restored, 0);
    await tester.ensureVisible(find.text('Récupérer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Récupérer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(recovery.restored, 1);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });
}
