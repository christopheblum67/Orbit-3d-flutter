import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';

/// Configuration globale de la suite de tests.
///
/// `flutter_secure_storage` est un plugin natif : sous `flutter test`, aucune
/// implémentation Android n'existe. On branche [InMemorySecretStore] pour
/// toute la suite — chaque fichier qui teste une persistance précise repart
/// d'un coffre frais dans son `setUp`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() => overrideSecretStoreForTesting(InMemorySecretStore()));
  tearDownAll(restoreSecretStoreForTesting);
  await testMain();
}