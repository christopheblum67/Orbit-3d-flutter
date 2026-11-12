import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_profile_recovery_screen.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
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

  @override
  Future<ProfileCatalogSnapshot> load(String uid, String passphrase) async =>
      ProfileCatalogSnapshot(
        revision: 1,
        profiles: {
          'cloud': {'id': 'cloud', 'firstName': 'Alex'},
        },
      );

  @override
  Future<void> publish(
      String uid, String passphrase, UserProfile profile) async {
    published++;
  }

  @override
  Future<void> restore(String uid, String passphrase, String profileId) async {
    restored++;
  }
}

class _Activity extends EncryptedActivitySyncNotifier {
  int unlocks = 0;
  ScopeConflictChoice? choice;

  @override
  EncryptedActivitySyncState build() => const EncryptedActivitySyncState();

  @override
  Future<void> unlock({
    required FirebaseAuth auth,
    required String uid,
    required String phrase,
    required ProfileCatalogSnapshot catalog,
  }) async {
    unlocks++;
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
  testWidgets('requires confirmation to activate and resolve a conflict',
      (tester) async {
    final auth = _Auth();
    final activity = _Activity();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => []),
        encryptedActivitySyncProvider.overrideWith(() => activity),
      ],
      child: MaterialApp(
        home: CloudProfileRecoveryScreen(auth: auth, recovery: _Recovery()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'phrase');
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.text('Activer la synchronisation du profil actif'));
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
    await tester.enterText(find.byType(TextField), 'nouvelle phrase');
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
    await tester.enterText(find.byType(TextField), 'phrase');
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    expect(recovery.published, 0);
    expect(recovery.restored, 0);
    await tester.ensureVisible(find.text('Sauvegarder'));
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'autre');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(recovery.published, 0);
    expect(find.text('Les phrases secrètes ne correspondent pas.'),
        findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'phrase');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(recovery.published, 1);
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
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    expect(find.text('Profils dans le cloud'), findsOneWidget);
    auth.user = _User('another-account');
    auth.changes.add(auth.user);
    await tester.pumpAndSettle();
    expect(find.text('Profils dans le cloud'), findsNothing);
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
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('Charger le catalogue cloud'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Récupérer'));
    await tester.tap(find.text('Récupérer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(recovery.restored, 0);
    await tester.tap(find.text('Récupérer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(recovery.restored, 1);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });
}
