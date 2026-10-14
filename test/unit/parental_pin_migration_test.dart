import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

/// Migration S1 du PIN parental : il quitte la boîte Hive (en clair) pour le
/// coffre sécurisé. Une installation existante doit retrouver son PIN, et la
/// valeur legacy doit disparaître de Hive.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_pin_migration');
    Hive.init(tempDir.path);
    overrideSecretStoreForTesting(InMemorySecretStore());
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
    restoreSecretStoreForTesting();
  });

  test('le PIN écrit par l\'ancienne version migre vers le coffre, puis en vit',
      () async {
    // Installation existante : PIN écrit EN CLAIR dans la boîte settings.
    final settings = await Hive.openBox<dynamic>('settings');
    settings.put('parental_pin', '2468');
    await Hive.close();

    // Nouvelle version : le premier accès migre puis sert depuis le coffre.
    final storage = StorageService();
    await storage.init();

    expect(
      await storage.getParentalPin(),
      '2468',
      reason: 'le PIN existant reste utilisable après migration',
    );
    final store = secretStore as InMemorySecretStore;
    expect(
      await store.read('parental_pin'),
      '2468',
      reason: 'le PIN doit désormais vivre dans le stockage sécurisé',
    );
    expect(
      Hive.box<dynamic>('settings').get('parental_pin'),
      isNull,
      reason: 'la valeur en clair doit avoir quitté Hive',
    );
  });

  test('set/clear du PIN passent par le coffre, jamais par Hive', () async {
    final storage = StorageService();
    await storage.init();

    await storage.setParentalPin('1357');
    expect(await storage.getParentalPin(), '1357');

    await storage.clearParentalPin();
    expect(await storage.getParentalPin(), isNull);
    expect(
      Hive.box<dynamic>('settings').get('parental_pin'),
      isNull,
      reason: 'rien ne doit repasser en clair dans Hive',
    );
  });
}