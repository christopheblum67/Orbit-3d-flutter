import 'dart:convert';

import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';

/// Manual profile-identity backup. Profile activity is not yet restored.
class CloudProfileRecovery {
  CloudProfileRecovery({
    required EncryptedProfileCatalog catalog,
    EncryptedScopeStore? profileScopes,
    required String? Function() currentUid,
    required Future<void> Function(
      UserProfile profile,
      void Function() checkAccount,
    ) addLocalProfile,
  })  : _catalog = catalog,
        _profileScopes = profileScopes,
        _currentUid = currentUid,
        _addLocalProfile = addLocalProfile;

  final EncryptedProfileCatalog _catalog;
  final EncryptedScopeStore? _profileScopes;
  final String? Function() _currentUid;
  final Future<void> Function(UserProfile, void Function()) _addLocalProfile;

  void _checkAccount(String uid) {
    if (uid.isEmpty || _currentUid() != uid) {
      throw StateError('Le compte cloud a changé. Recommencez.');
    }
  }

  Future<ProfileCatalogSnapshot> load(String uid, String passphrase) async {
    _checkAccount(uid);
    final result = await _catalog.load(uid: uid, passphrase: passphrase);
    _checkAccount(uid);
    return result;
  }

  Future<void> publish(
    String uid,
    String passphrase,
    UserProfile profile,
  ) async {
    _checkAccount(uid);
    validateCloudProfile(profile.toMap(), profile.id);
    final catalog = await load(uid, passphrase);
    if (catalog.profiles.containsKey(profile.id)) {
      throw StateError('Ce profil existe déjà dans le cloud.');
    }
    _checkAccount(uid);
    await _catalog.save(
      uid: uid,
      passphrase: passphrase,
      snapshot: ProfileCatalogSnapshot(
        revision: catalog.revision,
        profiles: {...catalog.profiles, profile.id: profile.toMap()},
      ),
    );
    _checkAccount(uid);
  }

  /// Publishes missing identities together without replacing existing ones.
  Future<ProfileCatalogSnapshot> publishMissing(
    String uid,
    String passphrase,
    List<UserProfile> profiles, {
    void Function()? checkProfiles,
  }) async {
    _checkAccount(uid);
    final selected = <String, Map<String, dynamic>>{};
    for (final profile in profiles) {
      if (selected.containsKey(profile.id)) {
        throw StateError('Un profil a été sélectionné plusieurs fois.');
      }
      final data = profile.toMap();
      validateCloudProfile(data, profile.id);
      selected[profile.id] = data;
    }
    if (selected.isEmpty) throw StateError('Sélectionnez au moins un profil.');
    final catalog = await load(uid, passphrase);
    checkProfiles?.call();
    final missing = Map<String, Map<String, dynamic>>.fromEntries(
      selected.entries
          .where((entry) => !catalog.profiles.containsKey(entry.key)),
    );
    if (missing.isEmpty) return catalog;
    _checkAccount(uid);
    final combined = {...catalog.profiles, ...missing};
    final revision = await _catalog.save(
      uid: uid,
      passphrase: passphrase,
      snapshot: ProfileCatalogSnapshot(
          revision: catalog.revision, profiles: combined),
      checkSession: () {
        _checkAccount(uid);
        checkProfiles?.call();
      },
    );
    _checkAccount(uid);
    return ProfileCatalogSnapshot(revision: revision, profiles: combined);
  }

  Future<void> deleteCloudProfile(
    String uid,
    String passphrase,
    String profileId,
  ) async {
    _checkAccount(uid);
    final catalog = await load(uid, passphrase);
    if (!catalog.profiles.containsKey(profileId)) {
      throw StateError('Ce profil cloud n’existe plus.');
    }
    await _catalog.advanceGeneration(
      uid: uid,
      passphrase: passphrase,
      reset: false,
    );
    _checkAccount(uid);
    await _profileScopes?.deleteProfile(uid: uid, profileId: profileId);
    _checkAccount(uid);
    final remaining = Map<String, Map<String, dynamic>>.from(catalog.profiles)
      ..remove(profileId);
    await _catalog.save(
      uid: uid,
      passphrase: passphrase,
      snapshot: ProfileCatalogSnapshot(
        revision: catalog.revision,
        profiles: remaining,
      ),
      checkSession: () => _checkAccount(uid),
    );
    _checkAccount(uid);
  }

  Future<void> resetCloud(String uid, String newPassphrase) async {
    _checkAccount(uid);
    if (newPassphrase.isEmpty) {
      throw StateError('Saisissez un nouveau code cloud.');
    }
    await _catalog.advanceGeneration(
      uid: uid,
      passphrase: newPassphrase,
      reset: true,
    );
    _checkAccount(uid);
    await _catalog.deleteAllData(uid);
    _checkAccount(uid);
  }

  Future<void> restore(
    String uid,
    String passphrase,
    String profileId,
  ) async {
    final catalog = await load(uid, passphrase);
    final data = catalog.profiles[profileId];
    if (data == null) throw StateError('Ce profil cloud n’existe plus.');
    var profile = validateCloudProfile(data, profileId);
    final scopes = _profileScopes;
    if (scopes != null) {
      final current = await scopes.read(
        uid: uid,
        profileId: profileId,
        scope: 'profile',
        passphrase: passphrase,
      );
      _checkAccount(uid);
      if (current != null) {
        if (current.entries.length != 1 ||
            !current.entries.containsKey(profileId)) {
          throw const FormatException('Fiche cloud invalide.');
        }
        final value = jsonDecode(current.entries[profileId]!);
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Fiche cloud invalide.');
        }
        profile = validateCloudProfile(value, profileId);
      }
    }
    _checkAccount(uid);
    await _addLocalProfile(profile, () => _checkAccount(uid));
  }
}

/// Reject incomplete/corrupt data instead of accepting permissive defaults,
/// especially those that would turn a child profile into an adult profile.
UserProfile validateCloudProfile(Map<String, dynamic> data, String id) {
  bool stringList(Object? value) =>
      value is List && value.every((element) => element is String);
  bool date(Object? value) =>
      value is String && DateTime.tryParse(value) != null;

  if (id.isEmpty ||
      id.contains(':') ||
      data['id'] != id ||
      data['firstName'] is! String ||
      (data['firstName'] as String).trim().isEmpty ||
      !date(data['dateOfBirth']) ||
      data['gender'] is! String ||
      !stringList(data['favoriteGenres']) ||
      data['avatarUrl'] is! String ||
      !ProfileType.values.any((type) => type.name == data['profileType']) ||
      (data['pinHash'] != null && data['pinHash'] is! String) ||
      data['settings'] is! Map ||
      (data['lastActiveAt'] != null && !date(data['lastActiveAt'])) ||
      !stringList(data['hiddenContentIds']) ||
      data['maxProfilesAllowed'] is! int ||
      data['hideAdultContent'] is! bool ||
      data['hideViolentContent'] is! bool ||
      !date(data['createdAt']) ||
      !date(data['updatedAt'])) {
    throw const FormatException('Le profil cloud est incomplet ou invalide.');
  }
  return UserProfile.fromMap(data);
}

/// Only creates an absent identity; neither local profiles nor activity change.
Future<void> addRecoveredLocalProfile(
  UserProfile profile,
  void Function() checkAccount,
) =>
    HiveSync.writeAsync('profiles', (box) async {
      checkAccount();
      if (box.containsKey(profile.id)) {
        throw StateError('Cet identifiant existe déjà sur cet appareil.');
      }
      await box.put(profile.id, profile.toMap());
    });
