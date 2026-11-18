import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/core/utils/json_retyping.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/services/epg_buffer_store.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/subscription_cloud_record.dart';

class ActiveSubscriptionSyncRemoval implements Exception {
  const ActiveSubscriptionSyncRemoval();
}

class StorageService {
  static const String _profilesBox = 'profiles';
  static const String _settingsBox = 'settings';
  static const String _subscriptionsBox = 'subscriptions';

  Future<void> init() async {
    await Hive.openBox(_profilesBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_subscriptionsBox);
    await HiveSync.writeAsync(
        _subscriptionsBox, _recoverCloudSubscriptionJournal);
    // Migration S1 : les secrets stockés EN CLAIR par les versions précédentes
    // (PIN parental en Hive, mots de passe Xtream en Hive) rejoignent le coffre
    // sécurisé, puis sont retirés de leur ancien emplacement.
    await _migrateLegacySecrets();
  }

  Future<void> _migrateLegacySecrets() async {
    await _migrateParentalPin();
    await _migrateSubscriptionPasswords();
  }

  Future<void> _migrateParentalPin() async {
    final legacy =
        await HiveSync.read(_settingsBox, (box) => box.get(_parentalPinKey));
    if (legacy is String && legacy.isNotEmpty) {
      await secretStore.write(_parentalPinKey, legacy);
      await HiveSync.writeAsync(
          _settingsBox, (box) => box.delete(_parentalPinKey));
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await HiveSync.writeAsync(
      _profilesBox,
      (box) => box.put(profile.id, profile.toMap()),
    );
  }

  Future<List<UserProfile>> getProfiles() async {
    return HiveSync.read(_profilesBox, (box) {
      // `try/catch` par entree : une seule fiche corrompue faisait echouer
      // tout `getProfiles()`, ce qui mettait `profilesProvider` en erreur et
      // faisait afficher « aucune affinite commune » alors que le catalogue
      // etait correct. Une panne silencieuse, la pire des deux.
      final out = <UserProfile>[];
      for (final e in box.values) {
        if (e is! Map) continue;
        try {
          // Retypage PROFOND : `Map<String, dynamic>.from` ne corrige que la
          // racine, et Hive ré-hydrate chaque map imbriquée en
          // `_Map<dynamic, dynamic>` → le premier cast profond du parseur
          // lèverait un TypeError (même défaut que les caches TMDB/TVmaze).
          out.add(UserProfile.fromMap(deepRetypeMap(e)));
        } catch (err) {
          LoggerService.instance.warning(
            'profil illisible, ignore',
            error: err,
          );
        }
      }
      return out;
    });
  }

  Future<List<UserProfile>> clearProfilePins() =>
      HiveSync.writeAsync(_profilesBox, (box) async {
        final profiles = <UserProfile>[];
        for (final key in box.keys.toList()) {
          final value = box.get(key);
          if (value is! Map) {
            throw const FormatException(
              'Une fiche de profil est illisible. Aucun PIN n’a été supprimé.',
            );
          }
          profiles.add(UserProfile.fromMap(deepRetypeMap(value)));
        }

        final timestamp = DateTime.now();
        final updated = profiles
            .where((profile) => profile.hasPin)
            .map((profile) => profile.copyWith(
                  clearPin: true,
                  updatedAt: timestamp,
                ))
            .toList();
        if (updated.isNotEmpty) {
          await box.putAll({
            for (final profile in updated) profile.id: profile.toMap(),
          });
        }
        return updated;
      });

  Future<void> deleteProfile(String id) async {
    await HiveSync.writeAsync(_profilesBox, (box) => box.delete(id));
  }

  static const String _prefsKey = 'user_preferences';
  static const String _parentalPinKey = 'parental_pin';

  Future<void> savePreferences(UserPreferences prefs) async {
    await HiveSync.writeAsync(
      _settingsBox,
      (box) => box.put(_prefsKey, prefs.toMap()),
    );
  }

  Future<UserPreferences> getPreferences() async {
    return HiveSync.read(_settingsBox, (box) {
      final map = box.get(_prefsKey);
      if (map is Map) {
        // Retypage profond : voir `getProfiles` (préférences lisibles par des
        // consommateurs qui pourraient caster des champs imbriqués).
        return UserPreferences.fromMap(deepRetypeMap(map));
      }
      return const UserPreferences();
    });
  }

  Future<void> setParentalPin(String pin) async {
    // Le PIN vit dans le coffre sécurisé (Keystore), plus jamais en clair
    // dans la boîte Hive, qui était lisible telle quelle.
    await secretStore.write(_parentalPinKey, pin);
    // Au cas où la migration de `init()` n'aurait pas encore tourné (lecture
    // directe avant init), on neutralise la valeur legacy.
    final legacy =
        await HiveSync.read(_settingsBox, (box) => box.get(_parentalPinKey));
    if (legacy != null) {
      await HiveSync.writeAsync(
          _settingsBox, (box) => box.delete(_parentalPinKey));
    }
  }

  Future<String?> getParentalPin() async {
    await _migrateParentalPin();
    return secretStore.read(_parentalPinKey);
  }

  Future<void> clearParentalPin() async {
    await secretStore.delete(_parentalPinKey);
    await HiveSync.writeAsync(
      _settingsBox,
      (box) => box.delete(_parentalPinKey),
    );
  }

  Future<void> setSetting(String key, dynamic value) async {
    await HiveSync.writeAsync(_settingsBox, (box) => box.put(key, value));
  }

  dynamic getSetting(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key);
  }

  // --- Subscriptions ---

  /// Cache mémoire des mots de passe Xtream, indexés par id d'abonnement.
  ///
  /// Le secret vit dans [SecretStore] (Keystore), jamais dans Hive. Ce cache
  /// permet aux lecteurs SYNCHRONES ([getActiveSubscriptionSync]) de servir
  /// le mot de passe sans passer par un await, et fait tampon entre les
  /// lectures. Il est peuplé par [init] (migration) et par chaque écriture.
  final Map<String, String> _subscriptionPasswordCache = {};
  static const _cloudSubscriptionJournal = 'cloud_subscription_journal_v1';
  static const _cloudSubscriptionJournalPending =
      'cloud_subscription_journal_pending_v1';

  Future<void> _setSubscriptionSecret(String id, String? secret) async {
    final key = subscriptionPasswordSecretKey(id);
    if (secret == null || secret.isEmpty) {
      await deleteSecretStrict(key);
      _subscriptionPasswordCache.remove(id);
    } else {
      await writeSecretStrict(key, secret);
      _subscriptionPasswordCache[id] = secret;
    }
  }

  Future<void> _recoverCloudSubscriptionJournal(Box<dynamic> box) async {
    final pending = await HiveSync.read(
      _settingsBox,
      (settings) => settings.get(_cloudSubscriptionJournalPending),
    );
    if (pending == null || pending == false) return;
    if (pending != true) {
      throw const FormatException('Journal sécurisé des abonnements invalide.');
    }
    final raw = await readSecretStrict(_cloudSubscriptionJournal);
    if (raw == null) {
      await _clearCloudSubscriptionJournalPending();
      return;
    }
    final journal = jsonDecode(raw);
    if (journal is! Map<String, dynamic> ||
        !journal.keys.toSet().containsAll({
          'version',
          'id',
          'subscription',
          'secret',
        }) ||
        journal['version'] != 1 ||
        journal['id'] is! String ||
        (journal['id'] as String).isEmpty ||
        (journal['secret'] != null && journal['secret'] is! String) ||
        (journal['subscription'] != null && journal['subscription'] is! Map)) {
      throw const FormatException('Journal sécurisé des abonnements invalide.');
    }
    final id = journal['id'] as String;
    final old = journal['subscription'];
    Subscription? previous;
    if (old != null) {
      final data = Map<String, dynamic>.from(old as Map);
      final validationData = Map<String, dynamic>.from(data);
      if (validationData['type'] == SubscriptionType.m3u.name) {
        validationData['password'] = null;
      }
      SubscriptionCloudRecord.decode(id, jsonEncode(validationData));
      if (data['isActive'] is! bool ||
          !TestResultStatus.values
              .any((status) => status.name == data['lastTestResult'])) {
        throw const FormatException(
            'Journal sécurisé des abonnements invalide.');
      }
      previous = Subscription.fromMap(data);
    }
    await _setSubscriptionSecret(id, journal['secret'] as String?);
    if (previous == null) {
      await box.delete(id);
    } else {
      await _putSubscription(box, previous);
    }
    await deleteSecretStrict(_cloudSubscriptionJournal);
    await _clearCloudSubscriptionJournalPending();
  }

  Future<void> _clearCloudSubscriptionJournalPending() => HiveSync.writeAsync(
        _settingsBox,
        (box) => box.delete(_cloudSubscriptionJournalPending),
      );

  Future<Map<String, String>> _readCloudSubscriptions(Box<dynamic> box) async {
    final result = <String, String>{};
    for (final key in box.keys) {
      final item = box.get(key);
      if (key is! String ||
          item is! Subscription ||
          item.id != key ||
          key.isEmpty) {
        throw const FormatException('Abonnement local invalide.');
      }
      final password = item.type == SubscriptionType.xtream
          ? await readSecretStrict(subscriptionPasswordSecretKey(key))
          : null;
      result[key] =
          SubscriptionCloudRecord.fromSubscription(item, password).encode();
    }
    return result;
  }

  Future<Map<String, String>> readCloudSubscriptions() =>
      HiveSync.writeAsync(_subscriptionsBox, (box) async {
        await _recoverCloudSubscriptionJournal(box);
        return _readCloudSubscriptions(box);
      });

  Future<void> applyCloudSubscriptionsIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  ) async {
    final records = <String, SubscriptionCloudRecord>{
      for (final entry in merged.entries)
        entry.key: SubscriptionCloudRecord.decode(entry.key, entry.value),
    };
    await HiveSync.writeAsync(_subscriptionsBox, (box) async {
      checkSession();
      await _recoverCloudSubscriptionJournal(box);
      checkSession();
      if (!mapEquals(await _readCloudSubscriptions(box), expected)) {
        throw StateError('Les abonnements locaux ont changé. Réessayez.');
      }
      checkSession();
      for (final id in expected.keys) {
        final old = box.get(id) as Subscription;
        if (!merged.containsKey(id) && old.isActive) {
          throw const ActiveSubscriptionSyncRemoval();
        }
      }
      final changed = <String>{
        for (final id in {...expected.keys, ...merged.keys})
          if (expected[id] != merged[id]) id,
      };
      for (final id in changed) {
        checkSession();
        final old = box.get(id) as Subscription?;
        final secret =
            await readSecretStrict(subscriptionPasswordSecretKey(id));
        checkSession();
        await HiveSync.writeAsync(
          _settingsBox,
          (settings) => settings.put(_cloudSubscriptionJournalPending, true),
        );
        try {
          await writeSecretStrict(
            _cloudSubscriptionJournal,
            jsonEncode({
              'version': 1,
              'id': id,
              'subscription': old?.copyWith(password: '').toMap(),
              'secret': secret,
            }),
          );
          checkSession();
          final record = records[id];
          if (record == null || record.type == SubscriptionType.xtream) {
            await _setSubscriptionSecret(id, record?.password);
          }
          checkSession();
          if (record == null) {
            await box.delete(id);
          } else {
            await _putSubscription(box, record.toSubscription(old));
          }
          checkSession();
          await deleteSecretStrict(_cloudSubscriptionJournal);
          await _clearCloudSubscriptionJournalPending();
        } catch (_) {
          await _recoverCloudSubscriptionJournal(box);
          rethrow;
        }
      }
    });
  }

  /// Écriture d'une subscription dans Hive en GARANTISSANT que le mot de
  /// passe n'y est jamais écrit : le secret va au coffre, Hive ne reçoit
  /// qu'une valeur vide. Les flux qui réécrivent un objet hydraté
  /// (`copyWith`, `setActiveSubscription`) ne doivent pas faire repasser le
  /// secret en clair — tout passe par ce point unique.
  Future<void> _putSubscription(Box<dynamic> box, Subscription subscription) =>
      box.put(subscription.id, subscription.copyWith(password: ''));

  Future<void> _saveSubscriptionWithSecret(Subscription subscription) async {
    final password = subscription.password;
    await HiveSync.writeAsync(
      _subscriptionsBox,
      (box) async {
        await _recoverCloudSubscriptionJournal(box);
        final key = subscriptionPasswordSecretKey(subscription.id);
        final replaceSecret = password != null && password.isNotEmpty;
        final previous = replaceSecret ? await readSecretStrict(key) : null;
        if (replaceSecret) await writeSecretStrict(key, password);
        try {
          await _putSubscription(box, subscription);
        } catch (_) {
          if (replaceSecret) {
            if (previous == null) {
              await deleteSecretStrict(key);
            } else {
              await writeSecretStrict(key, previous);
            }
          }
          rethrow;
        }
        if (replaceSecret)
          _subscriptionPasswordCache[subscription.id] = password;
      },
    );
  }

  /// Remplit [subscriptionPasswordCache] depuis le coffre (appelé par [init]).
  Future<void> _refreshSubscriptionPasswordCache() async {
    await HiveSync.read(_subscriptionsBox, (box) {
      for (final sub in box.values.cast<Subscription>()) {
        _subscriptionPasswordCache.remove(sub.id);
      }
    });
    final box = Hive.box(_subscriptionsBox);
    for (final sub in box.values.cast<Subscription>().toList()) {
      final secret =
          await readSecretStrict(subscriptionPasswordSecretKey(sub.id));
      if (secret != null && secret.isNotEmpty) {
        _subscriptionPasswordCache[sub.id] = secret;
      }
    }
  }

  /// Migration S1 : les mots de passe Xtream encore en clair dans Hive (écrits
  /// par une version antérieure) rejoignent le coffre, puis sont retirés de
  /// Hive. Idempotent : les abonnements déjà migrés n'ont pas de `password`.
  Future<void> _migrateSubscriptionPasswords() async {
    final box = Hive.box(_subscriptionsBox);
    for (final sub in box.values.cast<Subscription>().toList()) {
      final legacy = sub.password;
      if (legacy != null && legacy.isNotEmpty) {
        await writeSecretStrict(
          subscriptionPasswordSecretKey(sub.id),
          legacy,
        );
        await box.put(sub.id, sub.copyWith(password: ''));
      }
    }
    await _refreshSubscriptionPasswordCache();
  }

  Future<void> saveSubscription(Subscription subscription) async {
    await _saveSubscriptionWithSecret(subscription);
  }

  Future<List<Subscription>> getSubscriptions() async {
    final subs = await HiveSync.read(
      _subscriptionsBox,
      (box) =>
          box.values.cast<Subscription>().map((s) => s.copyWith()).toList(),
    );
    // Hydrate le mot de passe depuis le coffre pour chaque abonnement (le
    // cache mémoire évite les lectures disques répétées).
    for (final sub in subs) {
      var secret = _subscriptionPasswordCache[sub.id];
      if (secret == null) {
        secret = await secretStore.read(subscriptionPasswordSecretKey(sub.id));
        if (secret != null && secret.isNotEmpty) {
          _subscriptionPasswordCache[sub.id] = secret;
        }
      }
      if (secret != null && secret.isNotEmpty) {
        sub.password = secret;
      }
    }
    return subs;
  }

  Future<Subscription?> getActiveSubscription() async {
    final sub = await HiveSync.read(_subscriptionsBox, (box) {
      for (final s in box.values) {
        if (s.isActive) return (s as Subscription).copyWith();
      }
      return null;
    });
    if (sub == null) return null;
    var secret = _subscriptionPasswordCache[sub.id];
    if (secret == null) {
      secret = await secretStore.read(subscriptionPasswordSecretKey(sub.id));
      if (secret != null && secret.isNotEmpty) {
        _subscriptionPasswordCache[sub.id] = secret;
      }
    }
    if (secret != null && secret.isNotEmpty) {
      sub.password = secret;
    }
    return sub;
  }

  Subscription? getActiveSubscriptionSync() {
    final box = Hive.box(_subscriptionsBox);
    for (final s in box.values) {
      if (s.isActive) {
        final secret = _subscriptionPasswordCache[s.id];
        if (secret != null && secret.isNotEmpty) {
          return (s as Subscription).copyWith(password: secret);
        }
        return (s as Subscription).copyWith();
      }
    }
    return null;
  }

  Future<void> deleteSubscription(String id) async {
    await HiveSync.writeAsync(_subscriptionsBox, (box) async {
      await _recoverCloudSubscriptionJournal(box);
      await box.delete(id);
      await deleteSecretStrict(subscriptionPasswordSecretKey(id));
      _subscriptionPasswordCache.remove(id);
    });
  }

  Future<void> clearSubscriptions() async {
    await HiveSync.writeAsync(_subscriptionsBox, (box) async {
      await _recoverCloudSubscriptionJournal(box);
      final ids = box.values.cast<Subscription>().map((s) => s.id).toList();
      await box.clear();
      for (final id in ids) {
        await deleteSecretStrict(subscriptionPasswordSecretKey(id));
      }
      _subscriptionPasswordCache.clear();
    });
  }

  Future<void> setActiveSubscription(String id) async {
    await HiveSync.writeAsync(_subscriptionsBox, (box) async {
      await _recoverCloudSubscriptionJournal(box);
      for (final sub in box.values) {
        final updated = sub.copyWith(isActive: sub.id == id);
        // `_putSubscription` plutôt que `box.put` : un abonnement hydraté
        // (mot de passe en mémoire) ne doit pas réécrire le secret en clair
        // dans Hive — le coffre le conserve déjà.
        await _putSubscription(box, updated);
      }
    });
    // Invalider le tampon EPG : l'ancien abonnement n'est plus valide,
    // le nouveau doit recharger son propre tampon.
    await EpgBufferStore.instance.clearAll();
  }

  Future<void> migrateFromSharedPreferences() async {
    final hasExisting =
        await HiveSync.read(_subscriptionsBox, (box) => box.isNotEmpty);
    if (hasExisting) return;

    final prefs = await SharedPreferences.getInstance();
    final activeSource = prefs.getString('active_source');
    final xtreamBaseUrl = prefs.getString('xtream_base_url');
    final xtreamUsername = prefs.getString('xtream_username');
    final xtreamPassword = prefs.getString('xtream_password');
    final m3uUrl = prefs.getString('m3u_url');

    Subscription? sub;
    if (activeSource == 'xtream' &&
        xtreamBaseUrl != null &&
        xtreamUsername != null) {
      sub = Subscription(
        id: const Uuid().v4(),
        name: 'Abonnement principal',
        type: SubscriptionType.xtream,
        baseUrl: xtreamBaseUrl,
        username: xtreamUsername,
        password: xtreamPassword,
        isActive: true,
        createdAt: DateTime.now(),
      );
    } else if (activeSource == 'm3u' && m3uUrl != null) {
      sub = Subscription(
        id: const Uuid().v4(),
        name: 'Playlist M3U',
        type: SubscriptionType.m3u,
        m3uUrl: m3uUrl,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }

    if (sub != null) {
      await _saveSubscriptionWithSecret(sub);
    }
  }
}
