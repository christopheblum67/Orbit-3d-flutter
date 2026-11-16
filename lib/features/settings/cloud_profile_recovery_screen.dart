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

class CloudProfileRecoveryScreen extends ConsumerStatefulWidget {
  const CloudProfileRecoveryScreen(
      {super.key, this.auth, this.recovery, this.initialPhrase});

  final FirebaseAuth? auth;
  final CloudProfileRecovery? recovery;
  final String? initialPhrase;

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
  bool _obscurePhrase = true;
  bool _legacyPhrase = false;
  final _selectedProfiles = <String>{};
  String? _activeUid;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
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
      _message = 'Opération impossible. Aucune donnée cloud n’a été supprimée.';
    } finally {
      if (!succeeded && errorPrefix != null && _message != null) {
        _message = '$errorPrefix $_message';
      }
      if (mounted) setState(() => _busy = false);
    }
    return succeeded;
  }

  Future<bool> _confirm(String title, String detail) async =>
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
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ) ??
      false;

  Future<void> _load(String uid, {bool afterPublish = false}) async {
    await _run(() async {
      if (_phrase.text.isEmpty) {
        throw StateError(_legacyPhrase
            ? 'Saisissez votre phrase secrète.'
            : 'Saisissez votre code cloud.');
      }
      if (!_legacyPhrase && !RegExp(r'^[0-9]{3,10}$').hasMatch(_phrase.text)) {
        throw StateError('Saisissez un code de 3 à 10 chiffres.');
      }
      final loaded = await _recovery.load(uid, _phrase.text);
      if (!mounted) return;
      _catalog = loaded;
      _loadedUid = uid;
      _message = afterPublish
          ? 'Fiche sauvegardée. Catalogue actualisé.'
          : loaded.revision == 0
              ? 'Aucun catalogue cloud : le secret ne peut pas encore être vérifié.'
              : loaded.profiles.isEmpty
                  ? 'Secret valide. Aucun profil dans ce catalogue cloud.'
                  : 'Secret valide. Catalogue chargé. Choisissez un profil.';
    },
        errorPrefix: afterPublish
            ? 'Fiche sauvegardée, mais le catalogue n’a pas pu être actualisé.'
            : null);
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
          );
    });
  }

  Future<void> _syncSelected(
      String uid, List<UserProfile> localProfiles) async {
    final selected = localProfiles
        .where((profile) => _selectedProfiles.contains(profile.id))
        .toList();
    if (selected.isEmpty) return;
    final phrase = _phrase.text;
    final catalog = _catalog;
    final names = selected
        .map((profile) => '${profile.firstName} (${profile.id})')
        .join(', ');
    if (!await _confirm(
      'Synchroniser les profils sélectionnés ?',
      'Profils : $names. Les fiches absentes seront sauvegardées, puis '
          'leurs favoris, historiques, épisodes vus et positions seront '
          'synchronisés. Les préférences et abonnements communs, y compris '
          'les identifiants IPTV, sont aussi synchronisés sous forme chiffrée. '
          'Un conflit nécessitera votre choix.',
    )) return;
    if (!mounted) return;
    if (_auth.currentUser?.uid != uid ||
        _phrase.text != phrase ||
        !identical(_catalog, catalog)) {
      setState(
          () => _message = 'Le compte ou le secret a changé. Recommencez.');
      return;
    }
    if (catalog?.revision == 0) {
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
    ProfileCatalogSnapshot? updated;
    final saved = await _run(() async {
      if (_auth.currentUser?.uid != uid ||
          _phrase.text != phrase ||
          !identical(_catalog, catalog)) {
        throw StateError('Le compte ou le secret a changé. Recommencez.');
      }
      final fresh = await ref.refresh(profilesProvider.future);
      final freshById = {for (final profile in fresh) profile.id: profile};
      for (final profile in selected) {
        if (freshById[profile.id] == null ||
            jsonEncode(freshById[profile.id]!.toMap()) !=
                jsonEncode(profile.toMap())) {
          throw StateError('Les profils ont changé. Vérifiez votre sélection.');
        }
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
    });
    if (!saved || !mounted || updated == null) return;
    await _run(() async {
      await ref.read(encryptedActivitySyncProvider.notifier).unlock(
            auth: _auth,
            uid: uid,
            phrase: phrase,
            catalog: updated!,
            profileIds: selected.map((profile) => profile.id).toSet(),
          );
    }, errorPrefix: 'Les fiches ont été sauvegardées.');
  }

  Future<void> _resolveConflict(ScopeConflictChoice choice) async {
    final cloud = choice == ScopeConflictChoice.cloud;
    if (!await _confirm(
      'Résoudre le conflit ?',
      'Pour les éléments en conflit de cette catégorie, la version '
          '${cloud ? 'cloud' : 'de cet appareil'} sera conservée. '
          'L’autre version, y compris une éventuelle suppression, sera écrasée.',
    )) return;
    if (!mounted) return;
    await ref
        .read(encryptedActivitySyncProvider.notifier)
        .resolveConflict(choice);
  }

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(encryptedActivitySyncProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation chiffrée')),
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
              const Text(
                '1. Connectez le téléphone à un compte cloud non anonyme '
                '(Google ou e-mail). Pour associer une TV, ouvrez le QR code '
                'sur la TV, scannez-le sur le téléphone et confirmez les codes.\n'
                '2. Saisissez votre code cloud et validez pour charger le catalogue.\n'
                '3. Cochez les profils de cet appareil à synchroniser, puis confirmez. '
                'Pour un profil présent uniquement dans le cloud, récupérez-le d’abord.\n'
                '4. La synchronisation démarre après confirmation. '
                'En cas de conflit, choisissez la version à conserver.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Un code court peut être deviné si les données chiffrées sont '
                'copiées. Préférez un code long et unique. Utilisez le même '
                'secret sur chaque appareil : sa perte rend les données '
                'chiffrées irrécupérables.',
              ),
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
                        });
                      },
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
                  });
                },
                decoration: InputDecoration(
                  labelText: _legacyPhrase
                      ? 'Phrase secrète'
                      : 'Code cloud (3 à 10 chiffres)',
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
                child: const Text('Charger le catalogue cloud'),
              ),
              if (qrPairingAvailable)
                OutlinedButton(
                  onPressed: _busy || _phrase.text.isEmpty || catalog == null
                      ? null
                      : () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => PairingScannerScreen(
                              phrase: _phrase.text,
                              uid: user.uid,
                            ),
                          )),
                  child: const Text('Associer une TV par QR code'),
                ),
              if (_busy) const LinearProgressIndicator(),
              if (_message != null) Text(_message!),
              if (activity.unlocked) ...[
                const SizedBox(height: 12),
                Text(activity.busy
                    ? 'Synchronisation chiffrée en cours…'
                    : activity.error ?? 'Synchronisation chiffrée active.'),
                if (activity.conflictScope != null) ...[
                  if (activity.conflictProfileId != null)
                    Text(
                        'Profil en conflit : ${catalog?.profiles[activity.conflictProfileId]?['firstName'] ?? activity.conflictProfileId} '
                        '(${activity.conflictProfileId})'),
                  Text(
                      'Catégorie en conflit : ${switch (activity.conflictScope) {
                    'favorites' => 'favoris',
                    'radioFavorites' => 'favoris radio',
                    'recents' => 'historique récent',
                    'watched' => 'épisodes vus',
                    'playback' => 'positions de lecture',
                    'preferences' => 'préférences générales',
                    'profile' => 'fiche du profil',
                    'subscriptions' => 'abonnements',
                    _ => 'données',
                  }}'),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _resolveConflict(ScopeConflictChoice.local),
                        child: const Text('Garder cet appareil'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _resolveConflict(ScopeConflictChoice.cloud),
                        child: const Text('Garder le cloud'),
                      ),
                    ],
                  ),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: activity.busy
                          ? null
                          : () => ref
                              .read(encryptedActivitySyncProvider.notifier)
                              .syncAll(),
                      child: const Text('Synchroniser maintenant'),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(encryptedActivitySyncProvider.notifier)
                          .lock(),
                      child: const Text('Verrouiller la synchronisation'),
                    ),
                  ],
                ),
              ],
              if (catalog != null) ...[
                const SizedBox(height: 16),
                Text(activeProfile == null
                    ? 'Sélectionnez d’abord un profil dans l’application.'
                    : activePublished
                        ? 'Profil actif prêt à synchroniser : ${activeProfile.firstName}.'
                        : 'Sauvegardez d’abord le profil actif : ${activeProfile.firstName}.'),
                if (!activity.unlocked)
                  FilledButton(
                    onPressed: _busy || !activePublished
                        ? null
                        : () => _unlockActivity(user.uid, catalog),
                    child: const Text(
                        'Activer la synchronisation du profil actif'),
                  ),
                const Text('Profils sur cet appareil'),
                local.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Profils locaux indisponibles.'),
                  data: (profiles) => Column(
                    children: [
                      if (profiles.isNotEmpty)
                        TextButton(
                          onPressed: _busy || activity.unlocked
                              ? null
                              : () => setState(() {
                                    if (profiles.every((profile) =>
                                        _selectedProfiles
                                            .contains(profile.id))) {
                                      _selectedProfiles.clear();
                                    } else {
                                      _selectedProfiles
                                        ..clear()
                                        ..addAll(profiles
                                            .map((profile) => profile.id));
                                    }
                                  }),
                          child: Text(profiles.every((profile) =>
                                  _selectedProfiles.contains(profile.id))
                              ? 'Tout désélectionner'
                              : 'Tout sélectionner'),
                        ),
                      if (profiles.isNotEmpty)
                        FilledButton(
                          onPressed: _busy ||
                                  activity.unlocked ||
                                  !profiles.any(
                                      (p) => _selectedProfiles.contains(p.id))
                              ? null
                              : () => _syncSelected(user.uid, profiles),
                          child: const Text(
                              'Synchroniser les profils sélectionnés'),
                        ),
                      ...profiles.map((profile) => ListTile(
                            leading: Checkbox(
                              value: _selectedProfiles.contains(profile.id),
                              onChanged: _busy || activity.unlocked
                                  ? null
                                  : (selected) => setState(() {
                                        if (selected == true) {
                                          _selectedProfiles.add(profile.id);
                                        } else {
                                          _selectedProfiles.remove(profile.id);
                                        }
                                      }),
                            ),
                            title: Text(profile.firstName),
                            subtitle: Text('Identifiant : ${profile.id}'),
                            trailing: catalog.profiles.containsKey(profile.id)
                                ? const Text('Déjà dans le cloud')
                                : TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _publish(user.uid, profile),
                                    child: const Text('Sauvegarder'),
                                  ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Profils dans le cloud'),
                for (final entry in catalog.profiles.entries)
                  ListTile(
                    title: Text(entry.value['firstName'] as String),
                    subtitle: Text('Identifiant : ${entry.key}'),
                    trailing: local.value?.any((p) => p.id == entry.key) == true
                        ? const Text('Déjà sur cet appareil')
                        : TextButton(
                            onPressed:
                                _busy || local.isLoading || local.hasError
                                    ? null
                                    : () => _restore(
                                          user.uid,
                                          entry.key,
                                          entry.value['firstName'] as String,
                                        ),
                            child: const Text('Récupérer'),
                          ),
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
              ? 'Confirmer le secret du nouveau catalogue'
              : 'Sauvegarder cette fiche ?'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.multiple
                    ? 'Confirmez le secret pour les profils ${widget.name}. '
                        'La perte du secret rend les données irrécupérables.'
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
