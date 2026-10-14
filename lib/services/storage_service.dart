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

class StorageService {
  static const String _profilesBox = 'profiles';
  static const String _settingsBox = 'settings';
  static const String _subscriptionsBox = 'subscriptions';

  Future<void> init() async {
    await Hive.openBox(_profilesBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_subscriptionsBox);
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
      await HiveSync.writeAsync(_settingsBox, (box) => box.delete(_parentalPinKey));
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await HiveSync.writeAsync(
        _profilesBox, (box) => box.put(profile.id, profile.toMap()),);
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

  Future<void> deleteProfile(String id) async {
    await HiveSync.writeAsync(_profilesBox, (box) => box.delete(id));
  }

  static const String _prefsKey = 'user_preferences';
  static const String _parentalPinKey = 'parental_pin';

  Future<void> savePreferences(UserPreferences prefs) async {
    await HiveSync.writeAsync(
        _settingsBox, (box) => box.put(_prefsKey, prefs.toMap()),);
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
      await HiveSync.writeAsync(_settingsBox, (box) => box.delete(_parentalPinKey));
    }
  }

  Future<String?> getParentalPin() async {
    await _migrateParentalPin();
    return secretStore.read(_parentalPinKey);
  }

  Future<void> clearParentalPin() async {
    await secretStore.delete(_parentalPinKey);
    await HiveSync.writeAsync(
        _settingsBox, (box) => box.delete(_parentalPinKey),);
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

  /// Écriture d'une subscription dans Hive en GARANTISSANT que le mot de
  /// passe n'y est jamais écrit : le secret va au coffre, Hive ne reçoit
  /// qu'une valeur vide. Les flux qui réécrivent un objet hydraté
  /// (`copyWith`, `setActiveSubscription`) ne doivent pas faire repasser le
  /// secret en clair — tout passe par ce point unique.
  void _putSubscription(Box<dynamic> box, Subscription subscription) {
    box.put(subscription.id, subscription.copyWith(password: ''));
  }

  Future<void> _saveSubscriptionWithSecret(Subscription subscription) async {
    final password = subscription.password;
    if (password != null && password.isNotEmpty) {
      // Saisie ou objet hydraté : le secret est (ré)écrit dans le coffre.
      await secretStore.write(
        subscriptionPasswordSecretKey(subscription.id),
        password,
      );
      _subscriptionPasswordCache[subscription.id] = password;
    }
    // password absent/null : l'objet est peut-être NON hydraté (un flux qui
    // réécrit sans connaître le secret) — le coffre conserve la valeur déjà
    // enregistrée, seul Hive est réécrit sans secret.
    await HiveSync.writeAsync(
      _subscriptionsBox,
      (box) async {
        _putSubscription(box, subscription);
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
          await secretStore.read(subscriptionPasswordSecretKey(sub.id));
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
        await secretStore.write(
          subscriptionPasswordSecretKey(sub.id),
          legacy,
        );
        box.put(sub.id, sub.copyWith(password: ''));
      }
    }
    await _refreshSubscriptionPasswordCache();
  }

  Future<void> saveSubscription(Subscription subscription) async {
    await _saveSubscriptionWithSecret(subscription);
  }

  Future<List<Subscription>> getSubscriptions() async {
    final subs = await HiveSync.read(
        _subscriptionsBox, (box) => box.values.cast<Subscription>().toList(),);
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
        if (s.isActive) return s;
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
          s.password = secret;
        }
        return s;
      }
    }
    return null;
  }

  Future<void> deleteSubscription(String id) async {
    await HiveSync.writeAsync(_subscriptionsBox, (box) => box.delete(id));
    await secretStore.delete(subscriptionPasswordSecretKey(id));
    _subscriptionPasswordCache.remove(id);
  }

  Future<void> clearSubscriptions() async {
    final ids = await HiveSync.read(
      _subscriptionsBox,
      (box) => box.values.cast<Subscription>().map((s) => s.id).toList(),
    );
    await HiveSync.writeAsync(_subscriptionsBox, (box) => box.clear());
    for (final id in ids) {
      await secretStore.delete(subscriptionPasswordSecretKey(id));
    }
    _subscriptionPasswordCache.clear();
  }

  Future<void> setActiveSubscription(String id) async {
    await HiveSync.writeAsync(_subscriptionsBox, (box) async {
      for (final sub in box.values) {
        final updated = sub.copyWith(isActive: sub.id == id);
        // `_putSubscription` plutôt que `box.put` : un abonnement hydraté
        // (mot de passe en mémoire) ne doit pas réécrire le secret en clair
        // dans Hive — le coffre le conserve déjà.
        _putSubscription(box, updated);
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
