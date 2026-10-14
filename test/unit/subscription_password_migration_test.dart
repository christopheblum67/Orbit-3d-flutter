import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

/// Migration S1 du mot de passe Xtream : il quitte la boîte Hive (en clair)
/// pour le coffre sécurisé, SANS casser l'authentification — l'écran de
/// l'utilisateur doit continuer de voir le même mot de passe (hydraté), et
/// l'écriture dans Hive ne doit plus jamais contenir le secret.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_pwd_migration');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(SubscriptionAdapter().typeId)) {
      Hive.registerAdapter<Subscription>(SubscriptionAdapter());
    }
    if (!Hive.isAdapterRegistered(SubscriptionTypeAdapter().typeId)) {
      Hive.registerAdapter<SubscriptionType>(SubscriptionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(TestResultStatusAdapter().typeId)) {
      Hive.registerAdapter<TestResultStatus>(TestResultStatusAdapter());
    }
    overrideSecretStoreForTesting(InMemorySecretStore());
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
    restoreSecretStoreForTesting();
  });

  Subscription xtreamSub(String id, {String? password}) => Subscription(
        id: id,
        name: 'Xtream',
        type: SubscriptionType.xtream,
        baseUrl: 'https://draap.online',
        username: 'user',
        password: password,
        isActive: true,
        createdAt: DateTime.now(),
      );

  test('saveSubscription n\'écrit plus le mot de passe en clair dans Hive',
      () async {
    final storage = StorageService();
    await storage.init();

    await storage.saveSubscription(xtreamSub('sub-1', password: 's3cret'));

    final persisted =
        Hive.box<dynamic>('subscriptions').get('sub-1') as Subscription;
    expect(
      (persisted.password ?? '').isEmpty,
      isTrue,
      reason: 'le secret doit quitter Hive dès l\'écriture (i.e. ne plus y '
          'figurer en clair)',
    );
    expect(
      await secretStore.read(subscriptionPasswordSecretKey('sub-1')),
      's3cret',
      reason: 'le secret doit vivre dans le coffre sécurisé',
    );
    // L'authentification (lecture de l'abonnement actif) continue de marcher.
    final active = await storage.getActiveSubscription();
    expect(active?.password, 's3cret');
  });

  test('une base existante (password en Hive) migre au premier init', () async {
    final storage = StorageService();
    await storage.init();

    // État d'une installation d'avant la migration : password en clair dans Hive.
    await Hive.box<dynamic>('subscriptions')
        .put('old', xtreamSub('old', password: 'legacy-pass'));

    // Nouvelle version : init() migre les valeurs legacy vers le coffre.
    await storage.init();

    expect(
      secretStore.read(subscriptionPasswordSecretKey('old')),
      completion('legacy-pass'),
    );
    final persisted =
        Hive.box<dynamic>('subscriptions').get('old') as Subscription;
    expect((persisted.password ?? '').isEmpty, isTrue);

    final reloaded = await storage.getSubscriptions();
    expect(reloaded.single.password, 'legacy-pass');
  });

  test('deleteSubscription efface aussi le secret du coffre', () async {
    final storage = StorageService();
    await storage.init();
    await storage.saveSubscription(xtreamSub('sub-d', password: 'secret-d'));

    await storage.deleteSubscription('sub-d');

    expect(
      await secretStore.read(subscriptionPasswordSecretKey('sub-d')),
      isNull,
    );
  });
}