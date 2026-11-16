import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  List<UserProfile>? publishedSelection;

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
        'cloud': {'id': 'cloud', 'firstName': 'Alex'},
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
  }
}

class _Activity extends EncryptedActivitySyncNotifier {
  int unlocks = 0;
  Set<String>? selectedProfiles;
  ScopeConflictChoice? choice;

  @override
  EncryptedActivitySyncState build() => const EncryptedActivitySyncState();

  @override
  Future<void> unlock({
    required FirebaseAuth auth,
    required String uid,
    required String phrase,
    required ProfileCatalogSnapshot catalog,
    Set<String>? profileIds,
  }) async {
    unlocks++;
    selectedProfiles = profileIds;
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
        );
    final profiles = [profile('p1'), profile('p2')];
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
    expect(find.byType(Checkbox), findsNWidgets(2));
    await tester.tap(find.text('Tout sélectionner'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((c) => c.value == true),
        isTrue);
    await tester.tap(find.text('Synchroniser les profils sélectionnés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(recovery.publishedSelection, isNull);
    await tester.tap(find.text('Synchroniser les profils sélectionnés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(recovery.publishedSelection!.map((p) => p.id), ['p1', 'p2']);
    expect(activity.selectedProfiles, {'p1', 'p2'});
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
    await tester.tap(find.text('Synchroniser les profils sélectionnés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(
        find.text('Confirmer le secret du nouveau catalogue'), findsOneWidget);
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
    expect(find.text('Saisissez un code de 3 à 10 chiffres.'), findsOneWidget);
    expect(recovery.loads, 0);
    await tester.enterText(find.byType(TextField), '123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(recovery.loads, 1);
    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(recovery.loads, 2);
    await tester.enterText(find.byType(TextField), '12345678901');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Saisissez un code de 3 à 10 chiffres.'), findsOneWidget);
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
    expect(find.textContaining('Secret valide.'), findsOneWidget);
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
    expect(find.textContaining('Secret valide.'), findsOneWidget);
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
    final button = find.text('Charger le catalogue cloud');
    expect(Focus.of(tester.element(button)).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.textContaining('Secret valide.'), findsOneWidget);
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
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Secret valide.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '654321');
    await tester.pumpAndSettle();
    expect(find.textContaining('Secret valide.'), findsNothing);
    recovery.incorrectPhrase = true;
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Code cloud incorrect'), findsOneWidget);

    recovery.incorrectPhrase = false;
    recovery.emptyCatalog = true;
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    expect(find.textContaining('le secret ne peut pas encore être vérifié'),
        findsOneWidget);
    expect(find.textContaining('Secret valide.'), findsNothing);
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
    final button =
        find.widgetWithText(OutlinedButton, 'Associer une TV par QR code');
    if (qrPairingAvailable) {
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    } else {
      expect(button, findsNothing);
    }
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Charger le catalogue cloud'));
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
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Activer la synchronisation du profil actif'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activer la synchronisation du profil actif'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(activity.unlocks, 0);
    await tester.tap(find.text('Activer la synchronisation du profil actif'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(activity.unlocks, 1);
    await tester.ensureVisible(find.byTooltip('Afficher le code cloud'));
    await tester.tap(find.byTooltip('Afficher le code cloud'));
    await tester.pumpAndSettle();
    expect(find.text('Garder le cloud'), findsOneWidget);
    await tester.ensureVisible(find.text('Garder le cloud'));
    await tester.tap(find.text('Garder le cloud'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(activity.choice, isNull);
    await tester.tap(find.text('Garder le cloud'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(activity.choice, ScopeConflictChoice.cloud);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '987654');
    await tester.pumpAndSettle();
    expect(find.text('Profils dans le cloud'), findsNothing);
    expect(find.text('Garder le cloud'), findsNothing);
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
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    expect(recovery.published, 0);
    expect(recovery.restored, 0);
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
    expect(
        find.text('Fiche sauvegardée. Catalogue actualisé.'), findsOneWidget);
    expect(find.text('Déjà dans le cloud'), findsOneWidget);
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
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sauvegardez d’abord le profil actif : Alex.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sauvegardez d’abord le profil actif : Alex.'),
        findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(
            FilledButton,
            'Activer la synchronisation du profil actif',
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
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Profils dans le cloud'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Profils dans le cloud'), findsOneWidget);
    auth.user = _User('another-account');
    auth.changes.add(auth.user);
    await tester.pumpAndSettle();
    expect(find.text('Profils dans le cloud'), findsNothing);
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
    await tester.tap(find.text('Charger le catalogue cloud'));
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
