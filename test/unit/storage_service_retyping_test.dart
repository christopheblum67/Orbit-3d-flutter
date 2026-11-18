import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/profile_pin.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

/// P6 — Retypage profond des lectures Hive.
///
/// `storage_service` lit les profils avec `Map<String, dynamic>.from(e)`, une
/// copie SUPERFICIELLE : la racine est retapée, mais une map imbriquée
/// (`profile.settings['subtree']`) reste un `_Map<dynamic, dynamic>` après le
/// round-trip Hive. Le premier futur parseur qui fera
/// `settings['subtree'] as Map<String, dynamic>` lèvera un `TypeError` —
/// exactement le bug intermittent déjà corrigé pour les caches TMDB/TVmaze.
///
/// Ces tests verrouillent que la lecture passe par [json_retyping] :
/// ils échouent si on re-shallow-copie le profil à la lecture.
void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit_hive_retype_');
    Hive.init(tempDir.path);
    storage = StorageService();
    await storage.init();
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('profile.settings relu de Hive reste castable en profondeur', () async {
    final profile = UserProfile(
      id: 'p1',
      firstName: 'A',
      dateOfBirth: DateTime(1990, 1, 1),
      gender: 'other',
      favoriteGenres: const [],
      settings: <String, dynamic>{
        'subtree': <String, dynamic>{'k': 'v'},
      },
    );
    await storage.saveProfile(profile);

    // Round-trip RÉEL : tant que la boîte est ouverte, Hive renvoie l'objet
    // en mémoire (celui qu'on vient d'écrire, toujours typé) et le défaut
    // reste invisible. Il faut fermer (flush sur disque) et rouvrir pour que
    // Hive ré-hydrate des `_Map<dynamic, dynamic>`.
    await Hive.close();
    await storage.init();

    final reloaded = await storage.getProfiles();
    expect(reloaded, hasLength(1));

    // Le consommateur futur fait un cast profond sur la map imbriquée.
    final settings = reloaded.first.settings;
    final subtree = settings['subtree'] as Map<String, dynamic>?;
    expect(
      subtree,
      isNotNull,
      reason: 'le round-trip Hive ne doit pas laisser de maps non retypées',
    );
    expect(subtree!['k'], 'v');
  });

  test('profile PIN survives reopening, replacement and removal', () async {
    final firstHash = await ProfilePin.create('1234');
    final profile = UserProfile(
      id: 'pin-profile',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: 'other',
      favoriteGenres: const [],
      pinHash: firstHash,
      settings: const {'multiTvEnabled': false},
    );
    await storage.saveProfile(profile);
    await Hive.close();
    await storage.init();
    var restored = (await storage.getProfiles()).single;
    expect(restored.hasPin, isTrue);
    expect(restored.pinHash, firstHash);
    expect(await ProfilePin.verify(restored, '1234'), isTrue);
    expect(await ProfilePin.verify(restored, '9999'), isFalse);
    expect(restored.multiTvEnabled, isFalse);

    final secondHash = await ProfilePin.create('5678');
    await storage.saveProfile(restored.copyWith(pinHash: secondHash));
    await Hive.close();
    await storage.init();
    restored = (await storage.getProfiles()).single;
    expect(restored.pinHash, secondHash);
    expect(await ProfilePin.verify(restored, '5678'), isTrue);
    expect(await ProfilePin.verify(restored, '1234'), isFalse);

    await storage.saveProfile(restored.copyWith(clearPin: true));
    await Hive.close();
    await storage.init();
    restored = (await storage.getProfiles()).single;
    expect(restored.hasPin, isFalse);
    expect(restored.pinHash, isNull);
    expect(restored.multiTvEnabled, isFalse);
  });

  test('clearProfilePins removes all PINs while preserving profile data',
      () async {
    final hash = await ProfilePin.create('1234');
    final protected = UserProfile(
      id: 'protected',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: 'other',
      favoriteGenres: const ['Action'],
      pinHash: hash,
    );
    final unprotected = UserProfile(
      id: 'unprotected',
      firstName: 'Camille',
      dateOfBirth: DateTime(1992),
      gender: 'other',
      favoriteGenres: const ['Drama'],
    );
    await storage.saveProfile(protected);
    await storage.saveProfile(unprotected);

    final cleared = await storage.clearProfilePins();
    final profiles = await storage.getProfiles();

    expect(cleared, hasLength(1));
    expect(cleared.single.id, 'protected');
    expect(profiles, hasLength(2));
    final reloaded =
        profiles.singleWhere((profile) => profile.id == 'protected');
    expect(reloaded.hasPin, isFalse);
    expect(reloaded.firstName, 'Alex');
    expect(reloaded.favoriteGenres, ['Action']);
    expect(
        profiles.singleWhere((profile) => profile.id == 'unprotected').hasPin,
        isFalse);
  });
}
