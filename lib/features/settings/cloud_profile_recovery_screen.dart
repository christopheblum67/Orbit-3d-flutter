import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/json_retyping.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_scope.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/features/settings/pairing_scanner_screen.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_activity_sync_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';

String _scopeLabel(String scope) => switch (scope) {
      'favorites' => 'favoris',
      'radioFavorites' => 'favoris radio',
      'recents' => 'historique récent',
      'watched' => 'épisodes vus',
      'playback' => 'positions de lecture',
      'preferences' => 'préférences générales',
      'profile' => 'fiche du profil',
      'subscriptions' => 'abonnements',
      _ => 'données',
    };

class CloudProfileRecoveryScreen extends ConsumerStatefulWidget {
  const CloudProfileRecoveryScreen(
      {super.key,
      this.auth,
      this.recovery,
      this.initialPhrase,
      this.initialProfileIds = const {}});

  final FirebaseAuth? auth;
  final CloudProfileRecovery? recovery;
  final String? initialPhrase;
  final Set<String> initialProfileIds;

  @override
  ConsumerState<CloudProfileRecoveryScreen> createState() =>
      _CloudProfileRecoveryScreenState();
}

class _CloudProfileRecoveryScreenState
    extends ConsumerState<CloudProfileRecoveryScreen> {
  final _phrase = TextEditingController();
  late final FirebaseAuth _auth;
  late final Stream<User?> _authChanges;
  late final CloudProfileRecovery _recovery;
  ProfileCatalogSnapshot? _catalog;
  String? _loadedUid;
  String? _message;
  bool _busy = false;
  String? _progress;
  bool _obscurePhrase = true;
  bool _legacyPhrase = false;
  bool _requestSyncCompletionDialog = false;
  final _selectedProfiles = <String>{};
  late final Set<String> _pendingAutoSyncProfiles;
  String? _activeUid;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _pendingAutoSyncProfiles = Set.of(widget.initialProfileIds);
    _auth = widget.auth ?? FirebaseAuth.instance;
    if (widget.initialPhrase != null) _phrase.text = widget.initialPhrase!;
    if (widget.initialPhrase?.isNotEmpty == true &&
        !RegExp(r'^[0-9]{3,10}$').hasMatch(widget.initialPhrase!)) {
      _legacyPhrase = true;
    }
    _authChanges = _auth.authStateChanges();
    _activeUid = _auth.currentUser?.uid;
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user?.uid == _activeUid) return;
      _activeUid = user?.uid;
      if (!mounted) return;
      setState(() {
        _phrase.clear();
        _catalog = null;
        _loadedUid = null;
        _message = null;
        _obscurePhrase = true;
        _legacyPhrase = false;
        _selectedProfiles.clear();
        _pendingAutoSyncProfiles.clear();
      });
    });
    _recovery = widget.recovery ??
        CloudProfileRecovery(
          catalog: EncryptedProfileCatalog(
            EncryptedCloudStore(
                store: FirestoreEncryptedDocumentStore(auth: _auth)),
          ),
          profileScopes: EncryptedScopeStore(
            EncryptedCloudStore(
                store: FirestoreEncryptedDocumentStore(auth: _auth)),
          ),
          currentUid: () {
            final user = _auth.currentUser;
            return user == null || user.isAnonymous ? null : user.uid;
          },
          addLocalProfile: addRecoveredLocalProfile,
        );
    final user = _auth.currentUser;
    if (widget.initialPhrase?.isNotEmpty == true &&
        user != null &&
        !user.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _auth.currentUser?.uid == user.uid &&
            _phrase.text == widget.initialPhrase &&
            !_busy) {
          unawaited(_load(user.uid));
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _phrase.dispose();
    super.dispose();
  }

  Future<bool> _run(
    Future<void> Function() action, {
    String? errorPrefix,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
      _progress = null;
    });
    var succeeded = false;
    try {
      await action();
      succeeded = true;
    } on CloudSyncConflict {
      _message = 'Le cloud a changé ailleurs. Rechargez avant de réessayer.';
      _catalog = null;
    } on SecretBoxAuthenticationError {
      _message = _legacyPhrase
          ? 'Phrase secrète incorrecte ou données cloud altérées.'
          : 'Code cloud incorrect ou données cloud altérées.';
      _catalog = null;
    } on FirebaseException {
      _message =
          'Accès cloud impossible. Vérifiez le réseau et la configuration Firebase.';
    } on FormatException {
      _message =
          'Données cloud invalides ou incompatibles ; aucune restauration effectuée.';
    } on StateError catch (error) {
      _message = error.message.toString();
    } catch (_) {
      _message =
          'Opération impossible. Vérifiez le réseau puis actualisez le Cloud.';
    } finally {
      if (!succeeded && errorPrefix != null && _message != null) {
        _message = '$errorPrefix $_message';
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
    return succeeded;
  }

  Future<bool> _confirm(String title, String detail,
          {bool focusConfirm = false}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => DpadScope(
          child: AlertDialog(
            title: Text(title),
            scrollable: true,
            content: Text(detail),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                autofocus: focusConfirm,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ) ??
      false;

  Future<bool> _confirmProfiles(List<UserProfile> profiles) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => DpadScope(
          child: AlertDialog(
            title: const Text('Partager ces profils ?'),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final profile in profiles)
                  ListTile(
                    leading: ProfileAvatar(profile: profile, size: 40),
                    title: Text(profile.firstName),
                    subtitle: profiles
                                .where((other) =>
                                    other.firstName.trim().toLowerCase() ==
                                    profile.firstName.trim().toLowerCase())
                                .length >
                            1
                        ? Text('Même nom — identifiant : ${profile.id}')
                        : null,
                  ),
                const Text(
                  'Les profils manquants seront ajoutés sans remplacer ceux '
                  'qui existent. Leurs favoris et leur activité seront '
                  'partagés, ainsi que les préférences et abonnements, avec '
                  'leurs identifiants IPTV. Ces données sont chiffrées.\n\n'
                  'Deux profils de même nom restent séparés. Si des données '
                  'sont différentes, vous choisirez lesquelles garder.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ) ??
      false;

  Future<ScopeConflictChoice?> _chooseInitialSource() =>
      showDialog<ScopeConflictChoice>(
        context: context,
        builder: (context) => DpadScope(
          child: AlertDialog(
            title: const Text('Choisir la source en cas de conflit'),
            scrollable: true,
            content: const Text(
              'Les ajouts différents seront réunis sur les deux appareils. '
              'Si une même donnée a été modifiée des deux côtés, la source '
              'choisie ici sera conservée et envoyée à l’autre appareil. '
              'Ce choix s’applique à tous les conflits du démarrage.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pop(context, ScopeConflictChoice.local),
                child: const Text('Cet appareil est la source'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, ScopeConflictChoice.cloud),
                child: const Text('Le Cloud est la source'),
              ),
            ],
          ),
        ),
      );

  Future<void> _load(String uid, {bool afterPublish = false}) async {
    ProfileCatalogSnapshot? loaded;
    final success = await _run(() async {
      if (_phrase.text.isEmpty) {
        throw StateError('Demande le code à un adulte.');
      }
      if (!_legacyPhrase && !RegExp(r'^[0-9]{3,10}$').hasMatch(_phrase.text)) {
        throw StateError('Le code doit contenir de 3 à 10 chiffres.');
      }
      final phrase = _phrase.text;
      final snapshot = await _recovery.load(uid, phrase);
      loaded = snapshot;
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid || _phrase.text != phrase) {
        throw StateError('Le compte ou le secret a changé. Recommencez.');
      }
      _catalog = snapshot;
      _loadedUid = uid;
      _message = afterPublish
          ? 'Fiche sauvegardée. Catalogue actualisé.'
          : snapshot.revision == 0
              ? snapshot.verified
                  ? 'Accès confirmé. Aucun profil sauvegardé.'
                  : 'Aucune sauvegarde trouvée : votre code ne peut pas encore être vérifié.'
              : snapshot.profiles.isEmpty
                  ? 'Accès confirmé. Aucun profil sauvegardé.'
                  : 'Accès confirmé. Choisissez les profils à partager.';
    },
        errorPrefix: afterPublish
            ? 'Fiche sauvegardée, mais le catalogue n’a pas pu être actualisé.'
            : null);
    if (!success ||
        !mounted ||
        afterPublish ||
        _pendingAutoSyncProfiles.isEmpty) {
      return;
    }
    final snapshot = loaded!;
    final requested = Set<String>.of(_pendingAutoSyncProfiles);
    _pendingAutoSyncProfiles.clear();
    final missing = requested.difference(snapshot.profiles.keys.toSet());
    if (missing.isNotEmpty) {
      setState(() => _message =
          'Les profils choisis sur le téléphone ne sont plus disponibles. '
              'Actualisez la liste et sélectionnez-les à nouveau.');
      return;
    }
    List<UserProfile>? localProfiles;
    final localLoadSucceeded = await _run(() async {
      localProfiles = await ref.read(profilesProvider.future);
    });
    if (!localLoadSucceeded || !mounted || localProfiles == null) return;
    setState(() {
      _selectedProfiles
        ..clear()
        ..addAll(requested);
      _message = 'Profils reçus du téléphone. Démarrage du partage…';
    });
    await _syncSelected(uid, localProfiles!, confirm: false);
  }

  Future<void> _publish(String uid, UserProfile profile) async {
    final phrase = _phrase.text;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmBackupDialog(
          name: profile.firstName, phrase: phrase, legacy: _legacyPhrase),
    );
    if (accepted != true) return;
    if (!mounted) return;
    if (_phrase.text != phrase || _auth.currentUser?.uid != uid) {
      setState(
          () => _message = 'Le compte ou la phrase a changé. Recommencez.');
      return;
    }
    final saved = await _run(() async {
      await _recovery.publish(uid, phrase, profile);
      if (!mounted) return;
      _catalog = null;
      _loadedUid = null;
    });
    if (saved &&
        mounted &&
        _auth.currentUser?.uid == uid &&
        _phrase.text == phrase) {
      await _load(uid, afterPublish: true);
    }
  }

  Future<void> _restore(String uid, String id, String name) async {
    if (!await _confirm(
      'Récupérer ce profil ?',
      'La fiche de $name sera ajoutée sans remplacer les profils locaux. '
          'Les favoris, historiques, abonnements et préférences ne seront pas restaurés.',
    )) return;
    if (!mounted) return;
    await _run(() async {
      await _recovery.restore(uid, _phrase.text, id);
      if (!mounted) return;
      ref.invalidate(profilesProvider);
      _message = 'Fiche récupérée. Sélectionnez ce profil dans l’application, '
          'puis revenez ici pour activer sa synchronisation.';
    });
  }

  Future<void> _deleteCloudProfile(String uid, String id, String name) async {
    if (!await _confirm(
      'Supprimer $name du Cloud ?',
      'La fiche et les données synchronisées de ce profil seront supprimées '
          'du Cloud. Le profil local sur cet appareil ne sera pas supprimé. '
          'Les autres appareils seront mis en pause et devront actualiser '
          'leur liste.',
    )) {
      return;
    }
    if (!mounted || _auth.currentUser?.uid != uid) return;
    final activity = ref.read(encryptedActivitySyncProvider);
    if (activity.busy) {
      setState(() => _message =
          'Attendez la fin de la synchronisation avant la suppression.');
      return;
    }
    if (activity.unlocked) {
      ref.read(encryptedActivitySyncProvider.notifier).lock();
    }
    final phrase = _phrase.text;
    final removed = await _run(() async {
      await _recovery.deleteCloudProfile(uid, phrase, id);
      if (!mounted) return;
      _selectedProfiles.remove(id);
      _catalog = null;
      _loadedUid = null;
    });
    if (removed && mounted && _auth.currentUser?.uid == uid) {
      await _load(uid);
    }
  }

  Future<String?> _requestCloudResetCode(String currentCode) async {
    var code = '';
    var confirmation = '';
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => DpadScope(
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Repartir de zéro sur le Cloud ?'),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tous les profils et leurs données partagées seront '
                  'supprimés du Cloud. Les profils locaux seront conservés. '
                  'Les autres appareils devront saisir ce nouveau code. '
                  'Cette action est irréversible.',
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('cloud-reset-code'),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => code = value,
                  decoration: const InputDecoration(labelText: 'Nouveau code'),
                ),
                TextField(
                  key: const ValueKey('cloud-reset-confirmation'),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => confirmation = value,
                  decoration:
                      const InputDecoration(labelText: 'Confirmer le code'),
                  onSubmitted: (_) {
                    if (!_validResetCode(code, confirmation, currentCode)) {
                      setDialogState(() => error =
                          'Saisissez un nouveau code de 3 à 10 chiffres et '
                              'confirmez-le à l’identique.');
                    } else {
                      Navigator.pop(dialogContext, code);
                    }
                  },
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  if (!_validResetCode(code, confirmation, currentCode)) {
                    setDialogState(() => error =
                        'Saisissez un nouveau code de 3 à 10 chiffres et '
                            'confirmez-le à l’identique.');
                  } else {
                    Navigator.pop(dialogContext, code);
                  }
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validResetCode(String code, String confirmation, String currentCode) =>
      RegExp(r'^[0-9]{3,10}$').hasMatch(code) &&
      code != currentCode &&
      confirmation == code;

  Future<void> _resetCloud(String uid) async {
    if (ref.read(encryptedActivitySyncProvider).busy) {
      setState(() => _message =
          'Attendez la fin de la synchronisation avant la réinitialisation.');
      return;
    }
    final newCode = await _requestCloudResetCode(_phrase.text);
    if (newCode == null || !mounted || _auth.currentUser?.uid != uid) return;
    if (ref.read(encryptedActivitySyncProvider).unlocked) {
      ref.read(encryptedActivitySyncProvider.notifier).lock();
    }
    final reset = await _run(() async {
      await _recovery.resetCloud(uid, newCode);
      if (!mounted) return;
      _phrase.text = newCode;
      _legacyPhrase = false;
      _selectedProfiles.clear();
      _catalog = ProfileCatalogSnapshot(
        revision: 0,
        profiles: const {},
        verified: true,
      );
      _loadedUid = uid;
      _message =
          'Cloud réinitialisé. Le nouveau code est actif ; les profils locaux '
          'ont été conservés.';
    });
    if (reset && mounted) setState(() {});
  }

  Future<void> _unlockActivity(
      String uid, ProfileCatalogSnapshot catalog) async {
    final phrase = _phrase.text;
    if (!await _confirm(
      'Synchroniser ce profil ?',
      'La fiche, les favoris vidéo et radio, historiques récents, épisodes vus et positions du profil '
          'actif, ainsi que les préférences et abonnements, seront synchronisés '
          'sous forme chiffrée pendant cette session. Les identifiants IPTV sont '
          'inclus. L’abonnement actif reste choisi sur chaque appareil.',
    )) return;
    final initialConflictChoice = await _chooseInitialSource();
    if (initialConflictChoice == null) return;
    if (!mounted) return;
    if (_phrase.text != phrase ||
        _auth.currentUser?.uid != uid ||
        !identical(_catalog, catalog)) {
      setState(
          () => _message = 'Le compte ou la phrase a changé. Recommencez.');
      return;
    }
    await _run(() async {
      await ref.read(encryptedActivitySyncProvider.notifier).unlock(
            auth: _auth,
            uid: uid,
            phrase: phrase,
            catalog: catalog,
            initialConflictChoice: initialConflictChoice,
          );
    });
  }

  Future<void> _syncSelected(
    String uid,
    List<UserProfile> localProfiles, {
    bool confirm = true,
  }) async {
    final catalog = _catalog;
    if (catalog == null) return;
    final localSelected = localProfiles
        .where((profile) => _selectedProfiles.contains(profile.id))
        .toList();
    final localIds = localProfiles.map((profile) => profile.id).toSet();
    final cloudOnly = catalog.profiles.entries
        .where((entry) =>
            !localIds.contains(entry.key) &&
            _selectedProfiles.contains(entry.key))
        .toList();
    if (localSelected.isEmpty && cloudOnly.isEmpty) return;
    final phrase = _phrase.text;
    final selectedProfiles = [
      ...localSelected,
      ...cloudOnly.map((entry) => UserProfile.fromMap(entry.value)),
    ];
    final names =
        selectedProfiles.map((profile) => profile.firstName).join(', ');
    if (confirm && !await _confirmProfiles(selectedProfiles)) return;
    final initialConflictChoice = await _chooseInitialSource();
    if (initialConflictChoice == null) return;
    if (!mounted) return;
    if (_auth.currentUser?.uid != uid ||
        _phrase.text != phrase ||
        !identical(_catalog, catalog)) {
      setState(
          () => _message = 'Le compte ou le secret a changé. Recommencez.');
      return;
    }
    if (confirm && catalog.revision == 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _ConfirmBackupDialog(
          name: names,
          phrase: phrase,
          legacy: _legacyPhrase,
          multiple: true,
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (ref.read(encryptedActivitySyncProvider).busy) {
      setState(() => _message =
          'Une synchronisation est en cours. Attendez la fin avant de modifier la sélection.');
      return;
    }
    if (ref.read(encryptedActivitySyncProvider).unlocked) {
      ref.read(encryptedActivitySyncProvider.notifier).lock();
    }
    ProfileCatalogSnapshot? updated;
    final saved = await _run(() async {
      if (_auth.currentUser?.uid != uid ||
          _phrase.text != phrase ||
          !identical(_catalog, catalog)) {
        throw StateError('Le compte ou le secret a changé. Recommencez.');
      }
      final fresh = await ref.refresh(profilesProvider.future);
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid ||
          _phrase.text != phrase ||
          !identical(_catalog, catalog)) {
        throw StateError('Le compte ou le secret a changé. Recommencez.');
      }
      final freshById = {for (final profile in fresh) profile.id: profile};
      for (final profile in localSelected) {
        if (freshById[profile.id] == null ||
            jsonEncode(freshById[profile.id]!.toMap()) !=
                jsonEncode(profile.toMap())) {
          throw StateError('Les profils ont changé. Vérifiez votre sélection.');
        }
      }
      for (final (index, entry) in cloudOnly.indexed) {
        if (freshById.containsKey(entry.key)) {
          throw StateError('Les profils ont changé. Vérifiez votre sélection.');
        }
        setState(() => _progress =
            'Récupération des fiches : ${index + 1} / ${cloudOnly.length}.');
        try {
          await _recovery.restore(uid, phrase, entry.key);
        } finally {
          if (mounted) ref.invalidate(profilesProvider);
        }
        if (!mounted ||
            _auth.currentUser?.uid != uid ||
            _phrase.text != phrase ||
            !identical(_catalog, catalog)) {
          throw StateError('Le compte ou le secret a changé. Recommencez.');
        }
      }
      final restoredProfiles = await ref.refresh(profilesProvider.future);
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid ||
          _phrase.text != phrase ||
          !identical(_catalog, catalog)) {
        throw StateError('Le compte ou le secret a changé. Recommencez.');
      }
      final restoredById = {
        for (final profile in restoredProfiles) profile.id: profile
      };
      final selected = <UserProfile>[...localSelected];
      for (final entry in cloudOnly) {
        final profile = restoredById[entry.key];
        if (profile == null) {
          throw StateError('Une fiche récupérée est introuvable. Réessayez.');
        }
        selected.add(profile);
      }
      void checkProfiles() {
        final box = Hive.box<dynamic>('profiles');
        for (final profile in selected) {
          final value = box.get(profile.id);
          if (value is! Map ||
              jsonEncode(validateCloudProfile(deepRetypeMap(value), profile.id)
                      .toMap()) !=
                  jsonEncode(profile.toMap())) {
            throw StateError(
                'Les profils ont changé. Vérifiez votre sélection.');
          }
        }
      }

      setState(
          () => _progress = 'Vérification et sauvegarde des fiches cloud.');
      updated = await _recovery.publishMissing(
        uid,
        phrase,
        selected,
        checkProfiles: checkProfiles,
      );
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid || _phrase.text != phrase) {
        throw StateError('Le compte ou le secret a changé. Recommencez.');
      }
      _catalog = updated;
      _loadedUid = uid;
    },
        errorPrefix: cloudOnly.isEmpty
            ? null
            : 'Certaines fiches ont peut-être été récupérées. Vérifiez la liste avant de réessayer.');
    if (!saved || !mounted || updated == null) return;
    final syncStarted = await _run(() async {
      setState(() => _progress = 'Démarrage de la synchronisation.');
      await ref.read(encryptedActivitySyncProvider.notifier).unlock(
            auth: _auth,
            uid: uid,
            phrase: phrase,
            catalog: updated!,
            profileIds: {
              ...localSelected.map((profile) => profile.id),
              ...cloudOnly.map((entry) => entry.key),
            },
            initialConflictChoice: initialConflictChoice,
          );
    }, errorPrefix: 'Les fiches ont été sauvegardées.');
    final activity = ref.read(encryptedActivitySyncProvider);
    if (confirm &&
        syncStarted &&
        mounted &&
        activity.error == null &&
        activity.lastSyncAt != null) {
      await _showSyncCompletionDialog();
    }
  }

  Future<void> _showSyncCompletionDialog() => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Synchronisation terminée'),
          content: const Text(
            'Les profils sélectionnés et leurs données ont bien été '
            'synchronisés avec le Cloud.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );

  Future<void> _resolveConflict(ScopeConflictChoice choice) async {
    final cloud = choice == ScopeConflictChoice.cloud;
    if (!await _confirm(
      'Résoudre le conflit ?',
      'Pour les éléments en conflit de cette catégorie, la version '
          '${cloud ? 'cloud' : 'de cet appareil'} sera conservée. '
          'L’autre version, y compris une éventuelle suppression, sera écrasée.',
      focusConfirm: true,
    )) return;
    if (!mounted) return;
    _requestSyncCompletionDialog = true;
    await ref
        .read(encryptedActivitySyncProvider.notifier)
        .resolveConflict(choice);
  }

  Future<void> _syncAllManually() async {
    final activity = ref.read(encryptedActivitySyncProvider);
    if (!activity.unlocked || activity.busy) return;
    _requestSyncCompletionDialog = true;
    await ref.read(encryptedActivitySyncProvider.notifier).syncAll();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(encryptedActivitySyncProvider, (previous, next) {
      if (previous?.busy != true || next.busy) {
        return;
      }
      if (next.error != null) {
        _requestSyncCompletionDialog = false;
        return;
      }
      if (next.lastSyncAt == null || _catalog == null) return;
      final showCompletionDialog = _requestSyncCompletionDialog;
      _requestSyncCompletionDialog = false;
      final uid = _loadedUid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            uid == null ||
            _busy ||
            ref.read(encryptedActivitySyncProvider).busy ||
            _auth.currentUser?.uid != uid ||
            _catalog == null ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        unawaited(() async {
          if (showCompletionDialog) {
            await _showSyncCompletionDialog();
          }
          if (mounted) await _load(uid);
        }());
      });
    });
    final activity = ref.watch(encryptedActivitySyncProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes profils sur mes appareils')),
      body: StreamBuilder<User?>(
        stream: _authChanges,
        builder: (context, auth) {
          final user = auth.data;
          if (user == null || user.isAnonymous) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Connectez-vous à un compte cloud pour continuer.'),
            );
          }

          final local = ref.watch(profilesProvider);
          final catalog = _loadedUid == user.uid ? _catalog : null;
          final activeProfile = ref.watch(currentProfileProvider);
          final activePublished = activeProfile != null &&
              (catalog?.profiles.containsKey(activeProfile.id) ?? false);
          return DpadScope(
              child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        catalog == null
                            ? Icons.cloud_outlined
                            : Icons.people_alt_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          catalog == null
                              ? 'Un adulte prépare le code. Ensuite, choisis '
                                  'les profils à partager.'
                              : 'Coche les profils que tu veux retrouver sur '
                                  'tes appareils, puis appuie sur Partager.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.hourglass_top_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La première mise à jour peut prendre plus de '
                          '10 minutes. Garde Orbit ouvert jusqu’à la fin.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phrase,
                obscureText: _obscurePhrase,
                enableSuggestions: false,
                autocorrect: false,
                enabled: !_busy,
                keyboardType:
                    _legacyPhrase ? TextInputType.text : TextInputType.number,
                inputFormatters: _legacyPhrase
                    ? null
                    : [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_busy) unawaited(_load(user.uid));
                },
                onChanged: (_) {
                  if (activity.unlocked) {
                    ref.read(encryptedActivitySyncProvider.notifier).lock();
                  }
                  setState(() {
                    _catalog = null;
                    _loadedUid = null;
                    _message = null;
                    _selectedProfiles.clear();
                    _pendingAutoSyncProfiles.clear();
                  });
                },
                decoration: InputDecoration(
                  labelText: _legacyPhrase
                      ? 'Phrase secrète (ancien format)'
                      : 'Code donné par l’adulte',
                  suffixIcon: IconButton(
                    tooltip: _legacyPhrase
                        ? (_obscurePhrase
                            ? 'Afficher la phrase secrète'
                            : 'Masquer la phrase secrète')
                        : (_obscurePhrase
                            ? 'Afficher le code cloud'
                            : 'Masquer le code cloud'),
                    icon: Icon(_obscurePhrase
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePhrase = !_obscurePhrase),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : () => _load(user.uid),
                child: Text(catalog == null
                    ? 'Voir mes profils'
                    : 'Actualiser la liste'),
              ),
              ExpansionTile(
                title: const Text('Options pour un adulte'),
                children: [
                  SwitchListTile(
                    title: const Text('Utiliser une ancienne phrase secrète'),
                    value: _legacyPhrase,
                    onChanged: _busy
                        ? null
                        : (value) {
                            if (activity.unlocked) {
                              ref
                                  .read(encryptedActivitySyncProvider.notifier)
                                  .lock();
                            }
                            setState(() {
                              _legacyPhrase = value;
                              _phrase.clear();
                              _catalog = null;
                              _loadedUid = null;
                              _message = null;
                              _selectedProfiles.clear();
                              _pendingAutoSyncProfiles.clear();
                            });
                          },
                  ),
                  if (qrPairingAvailable)
                    OutlinedButton(
                      onPressed: _busy ||
                              _phrase.text.isEmpty ||
                              catalog == null
                          ? null
                          : () {
                              final selected = Set<String>.of(
                                _selectedProfiles,
                              );
                              if (selected.any(
                                  (id) => !catalog.profiles.containsKey(id))) {
                                setState(() => _message =
                                    'Partagez d’abord les profils sélectionnés '
                                        'pour les rendre disponibles sur la TV.');
                                return;
                              }
                              Navigator.of(context)
                                  .push(MaterialPageRoute<void>(
                                builder: (_) => PairingScannerScreen(
                                  phrase: _phrase.text,
                                  uid: user.uid,
                                  profileIds: selected,
                                  profileNames: selected
                                      .map((id) => catalog
                                          .profiles[id]!['firstName'] as String)
                                      .toList(),
                                ),
                              ));
                            },
                      child: const Text('Associer une TV par QR code'),
                    ),
                  if (catalog != null)
                    TextButton(
                      onPressed: _busy ? null : () => _resetCloud(user.uid),
                      child: const Text(
                          'Supprimer tout le Cloud et repartir de zéro'),
                    ),
                ],
              ),
              if (_busy && !activity.busy) const LinearProgressIndicator(),
              if (_progress != null && !activity.busy) Text(_progress!),
              if (_message != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_message!),
                  ),
                ),
              if (activity.unlocked ||
                  activity.busy ||
                  activity.error != null) ...[
                const SizedBox(height: 12),
                if (activity.realtimeError != null)
                  Text(activity.realtimeError!),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              activity.busy
                                  ? Icons.sync_rounded
                                  : activity.conflictScope != null
                                      ? Icons.warning_amber_rounded
                                      : Icons.cloud_done_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                activity.busy
                                    ? 'Mise à jour en cours…'
                                    : activity.conflictScope != null
                                        ? 'Un adulte doit choisir les données à garder.'
                                        : activity.error ??
                                            'Le partage est activé.',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        if (activity.busy) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: activity.totalScopes == 0
                                ? null
                                : activity.completedScopes /
                                    activity.totalScopes,
                          ),
                          if (activity.totalScopes > 0)
                            Text(
                              'Fait : ${(100 * activity.completedScopes / activity.totalScopes).floor()} %',
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cela peut prendre plus de 10 minutes. Garde '
                            'Orbit ouvert.',
                          ),
                        ] else if (activity.error == null &&
                            activity.lastSyncAt != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Les changements sont partagés automatiquement.',
                            ),
                          ),
                        if (activity.busy && activity.currentScope != null)
                          Text(
                            'En ce moment : ${_scopeLabel(activity.currentScope!)}'
                            '${activity.currentProfileId == null ? '' : ' — ${catalog?.profiles[activity.currentProfileId]?['firstName'] ?? 'profil'}'}.',
                          ),
                      ],
                    ),
                  ),
                ),
                if (activity.conflictScope != null) ...[
                  const Text(
                    'Cet appareil et l’autre appareil ne sont pas d’accord. '
                    'Demande à un adulte de choisir la bonne version.',
                  ),
                  if (activity.conflictProfileId != null)
                    Text(
                        'Profil en conflit : ${catalog?.profiles[activity.conflictProfileId]?['firstName'] ?? activity.conflictProfileId} '
                        '(${activity.conflictProfileId})'),
                  Text('Données : ${_scopeLabel(activity.conflictScope!)}'),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _resolveConflict(ScopeConflictChoice.local),
                        child: const Text('Garder les données d’ici'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _resolveConflict(ScopeConflictChoice.cloud),
                        child: const Text(
                            'Garder les données de l’autre appareil'),
                      ),
                    ],
                  ),
                ],
                ExpansionTile(
                  title: const Text('Réglages du partage (adulte)'),
                  children: [
                    TextButton(
                      onPressed: activity.busy ? null : _syncAllManually,
                      child: const Text('Mettre à jour maintenant'),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(encryptedActivitySyncProvider.notifier)
                          .lock(),
                      child: const Text('Mettre en pause'),
                    ),
                  ],
                ),
              ],
              if (catalog != null) ...[
                const SizedBox(height: 16),
                Text(
                  activity.unlocked
                      ? 'Choisis les profils à partager'
                      : 'Quels profils veux-tu retrouver sur tes appareils ?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                local.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Profils locaux indisponibles.'),
                  data: (profiles) {
                    final allIds = {
                      ...profiles.map((profile) => profile.id),
                      ...catalog.profiles.keys,
                    };
                    final allProfiles = {
                      for (final entry in catalog.profiles.entries)
                        entry.key: UserProfile.fromMap(entry.value),
                      for (final profile in profiles) profile.id: profile,
                    };
                    bool hasSameName(UserProfile profile) =>
                        allProfiles.values
                            .where((other) =>
                                other.firstName.trim().toLowerCase() ==
                                profile.firstName.trim().toLowerCase())
                            .length >
                        1;
                    return Column(
                      children: [
                        if (allIds.isNotEmpty)
                          TextButton(
                            onPressed: _busy || activity.busy
                                ? null
                                : () => setState(() {
                                      if (allIds
                                          .every(_selectedProfiles.contains)) {
                                        _selectedProfiles.clear();
                                      } else {
                                        _selectedProfiles
                                          ..clear()
                                          ..addAll(allIds);
                                      }
                                    }),
                            child: Text(allIds.every(_selectedProfiles.contains)
                                ? 'Tout décocher'
                                : 'Tout cocher'),
                          ),
                        if (allIds.isNotEmpty)
                          FilledButton(
                            onPressed: _busy || activity.busy
                                ? null
                                : () {
                                    if (!allIds
                                        .any(_selectedProfiles.contains)) {
                                      setState(() =>
                                          _selectedProfiles.addAll(allIds));
                                    }
                                    unawaited(
                                        _syncSelected(user.uid, profiles));
                                  },
                            child: Text(allIds.any(_selectedProfiles.contains)
                                ? 'Partager les profils cochés'
                                : 'Partager tous les profils'),
                          ),
                        ...profiles.map((profile) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                key: ValueKey('profile-tile-${profile.id}'),
                                onTap: _busy || activity.busy
                                    ? null
                                    : () => setState(() {
                                          if (!_selectedProfiles
                                              .remove(profile.id)) {
                                            _selectedProfiles.add(profile.id);
                                          }
                                        }),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      key: ValueKey(
                                          'local-profile-${profile.id}'),
                                      value: _selectedProfiles
                                          .contains(profile.id),
                                      onChanged: _busy || activity.busy
                                          ? null
                                          : (selected) => setState(() {
                                                if (selected == true) {
                                                  _selectedProfiles
                                                      .add(profile.id);
                                                } else {
                                                  _selectedProfiles
                                                      .remove(profile.id);
                                                }
                                              }),
                                    ),
                                    ProfileAvatar(profile: profile, size: 48),
                                  ],
                                ),
                                title: Text(profile.firstName),
                                subtitle: hasSameName(profile)
                                    ? Text(
                                        'Même nom — identifiant : ${profile.id}')
                                    : null,
                              ),
                            )),
                        if (catalog.profiles.keys
                            .any((id) => !profiles.any((p) => p.id == id))) ...[
                          const SizedBox(height: 16),
                          const Text('Profils à ajouter'),
                        ],
                        for (final entry in catalog.profiles.entries)
                          if (!profiles.any((p) => p.id == entry.key))
                            Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                key: ValueKey('profile-tile-${entry.key}'),
                                onTap: _busy || activity.busy
                                    ? null
                                    : () => setState(() {
                                          if (!_selectedProfiles
                                              .remove(entry.key)) {
                                            _selectedProfiles.add(entry.key);
                                          }
                                        }),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      key: ValueKey(
                                          'cloud-profile-${entry.key}'),
                                      value:
                                          _selectedProfiles.contains(entry.key),
                                      onChanged: _busy || activity.busy
                                          ? null
                                          : (selected) => setState(() {
                                                if (selected == true) {
                                                  _selectedProfiles
                                                      .add(entry.key);
                                                } else {
                                                  _selectedProfiles
                                                      .remove(entry.key);
                                                }
                                              }),
                                    ),
                                    ProfileAvatar(
                                        profile: allProfiles[entry.key]!,
                                        size: 48),
                                  ],
                                ),
                                title: Text(entry.value['firstName'] as String),
                                subtitle: hasSameName(allProfiles[entry.key]!)
                                    ? Text(
                                        'Même nom — identifiant : ${entry.key}')
                                    : null,
                              ),
                            ),
                        ExpansionTile(
                          title: const Text('Autres options (adulte)'),
                          children: [
                            if (!activity.unlocked)
                              TextButton(
                                onPressed: _busy || !activePublished
                                    ? null
                                    : () => _unlockActivity(user.uid, catalog),
                                child: const Text(
                                    'Partager seulement le profil utilisé'),
                              ),
                            for (final profile in profiles)
                              if (!catalog.profiles.containsKey(profile.id))
                                ListTile(
                                  title: Text(profile.firstName),
                                  trailing: TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _publish(user.uid, profile),
                                    child: const Text('Sauvegarder'),
                                  ),
                                ),
                            for (final entry in catalog.profiles.entries)
                              ListTile(
                                title: Text(entry.value['firstName'] as String),
                                subtitle: profiles.any((p) => p.id == entry.key)
                                    ? const Text(
                                        'Le profil local est conservé.')
                                    : null,
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    if (!profiles.any((p) => p.id == entry.key))
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _restore(
                                                  user.uid,
                                                  entry.key,
                                                  entry.value['firstName']
                                                      as String,
                                                ),
                                        child: const Text('Récupérer'),
                                      ),
                                    TextButton(
                                      onPressed: _busy || activity.busy
                                          ? null
                                          : () => _deleteCloudProfile(
                                                user.uid,
                                                entry.key,
                                                entry.value['firstName']
                                                    as String,
                                              ),
                                      child: const Text('Supprimer du Cloud'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ));
        },
      ),
    );
  }
}

class _ConfirmBackupDialog extends StatefulWidget {
  const _ConfirmBackupDialog(
      {required this.name,
      required this.phrase,
      required this.legacy,
      this.multiple = false});
  final String name;
  final String phrase;
  final bool legacy;
  final bool multiple;

  @override
  State<_ConfirmBackupDialog> createState() => _ConfirmBackupDialogState();
}

class _ConfirmBackupDialogState extends State<_ConfirmBackupDialog> {
  final _confirmation = TextEditingController();
  bool _mismatch = false;
  bool _obscurePhrase = true;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DpadScope(
        child: AlertDialog(
          title: Text(widget.multiple
              ? 'Confirmer votre code'
              : 'Sauvegarder cette fiche ?'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.multiple
                    ? 'Confirmez votre code pour les profils ${widget.name}. '
                        'Gardez-le en lieu sûr : sans lui, vous ne pourrez '
                        'plus retrouver vos données.'
                    : 'Seule la fiche de ${widget.name} sera sauvegardée, chiffrée. '
                        'Les favoris, historiques, abonnements et préférences ne sont pas inclus. '
                        'La perte du secret rend la sauvegarde irrécupérable.',
              ),
              TextField(
                controller: _confirmation,
                obscureText: _obscurePhrase,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType:
                    widget.legacy ? TextInputType.text : TextInputType.number,
                inputFormatters: widget.legacy
                    ? null
                    : [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: widget.legacy
                      ? 'Confirmer la phrase secrète'
                      : 'Confirmer le code cloud',
                  suffixIcon: IconButton(
                    tooltip: _obscurePhrase
                        ? 'Afficher la confirmation'
                        : 'Masquer la confirmation',
                    icon: Icon(_obscurePhrase
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePhrase = !_obscurePhrase),
                  ),
                  errorText:
                      _mismatch ? 'Les secrets ne correspondent pas.' : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (widget.phrase.isEmpty ||
                    _confirmation.text != widget.phrase) {
                  setState(() => _mismatch = true);
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
}
