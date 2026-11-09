import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';

/// Manual profile-identity backup. Profile activity is not yet restored.
class CloudProfileRecovery {
  CloudProfileRecovery({
    required EncryptedProfileCatalog catalog,
    required String? Function() currentUid,
    required Future<void> Function(
      UserProfile profile,
      void Function() checkAccount,
    ) addLocalProfile,
  })  : _catalog = catalog,
        _currentUid = currentUid,
        _addLocalProfile = addLocalProfile;

  final EncryptedProfileCatalog _catalog;
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

  Future<void> restore(
    String uid,
    String passphrase,
    String profileId,
  ) async {
    final catalog = await load(uid, passphrase);
    final data = catalog.profiles[profileId];
    if (data == null) throw StateError('Ce profil cloud n’existe plus.');
    final profile = validateCloudProfile(data, profileId);
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
