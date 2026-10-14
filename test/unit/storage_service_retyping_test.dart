import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:orbit_3d_flutter/models/user_profile.dart';
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
    expect(subtree, isNotNull,
        reason: 'le round-trip Hive ne doit pas laisser de maps non retypées');
    expect(subtree!['k'], 'v');
  });
}