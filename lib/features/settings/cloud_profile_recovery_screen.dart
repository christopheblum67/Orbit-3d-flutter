import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';

class CloudProfileRecoveryScreen extends ConsumerStatefulWidget {
  const CloudProfileRecoveryScreen({super.key, this.auth, this.recovery});

  final FirebaseAuth? auth;
  final CloudProfileRecovery? recovery;

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
  String? _activeUid;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseAuth.instance;
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
      });
    });
    _recovery = widget.recovery ??
        CloudProfileRecovery(
          catalog: EncryptedProfileCatalog(
            EncryptedCloudStore(
                store: FirestoreEncryptedDocumentStore(auth: _auth)),
          ),
          currentUid: () {
            final user = _auth.currentUser;
            return user == null || user.isAnonymous ? null : user.uid;
          },
          addLocalProfile: addRecoveredLocalProfile,
        );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on CloudSyncConflict {
      _message = 'Le cloud a changé ailleurs. Rechargez avant de réessayer.';
      _catalog = null;
    } on SecretBoxAuthenticationError {
      _message = 'Phrase secrète incorrecte ou données cloud altérées.';
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String detail) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
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
      ) ??
      false;

  Future<void> _load(String uid) => _run(() async {
        if (_phrase.text.isEmpty) {
          throw StateError('Saisissez votre phrase secrète.');
        }
        final loaded = await _recovery.load(uid, _phrase.text);
        if (!mounted) return;
        _catalog = loaded;
        _loadedUid = uid;
        _message = loaded.profiles.isEmpty
            ? 'Aucun profil dans ce catalogue cloud.'
            : 'Catalogue chargé. Choisissez un profil.';
      });

  Future<void> _publish(String uid, UserProfile profile) async {
    final phrase = _phrase.text;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ConfirmBackupDialog(name: profile.firstName, phrase: phrase),
    );
    if (accepted != true) return;
    if (!mounted) return;
    if (_phrase.text != phrase || _auth.currentUser?.uid != uid) {
      setState(
          () => _message = 'Le compte ou la phrase a changé. Recommencez.');
      return;
    }
    await _run(() async {
      await _recovery.publish(uid, _phrase.text, profile);
      if (!mounted) return;
      _catalog = null;
      _message = 'Fiche sauvegardée. Rechargez le catalogue.';
    });
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
      _message = 'Fiche récupérée sur cet appareil.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Fiches de profils chiffrées')),
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
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Sauvegarde manuelle des fiches de profils uniquement. '
                  'La synchronisation des favoris, historiques, abonnements '
                  'et préférences n’est pas encore disponible.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Utilisez une phrase secrète longue et unique, indépendante '
                  'du compte, et identique sur chaque appareil. '
                  'Si vous la perdez, les données chiffrées sont irrécupérables.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phrase,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  enabled: !_busy,
                  onChanged: (_) => setState(() {
                    _catalog = null;
                    _loadedUid = null;
                  }),
                  decoration:
                      const InputDecoration(labelText: 'Phrase secrète'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : () => _load(user.uid),
                  child: const Text('Charger le catalogue cloud'),
                ),
                if (_busy) const LinearProgressIndicator(),
                if (_message != null) Text(_message!),
                if (catalog != null) ...[
                  const SizedBox(height: 16),
                  const Text('Profils sur cet appareil'),
                  local.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) =>
                        const Text('Profils locaux indisponibles.'),
                    data: (profiles) => Column(
                      children: profiles
                          .map((profile) => ListTile(
                                title: Text(profile.firstName),
                                subtitle: Text('Identifiant : ${profile.id}'),
                                trailing: catalog.profiles
                                        .containsKey(profile.id)
                                    ? const Text('Déjà dans le cloud')
                                    : TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _publish(user.uid, profile),
                                        child: const Text('Sauvegarder'),
                                      ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Profils dans le cloud'),
                  for (final entry in catalog.profiles.entries)
                    ListTile(
                      title: Text(entry.value['firstName'] as String),
                      subtitle: Text('Identifiant : ${entry.key}'),
                      trailing: TextButton(
                        onPressed: _busy
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
            );
          },
        ),
      );
}

class _ConfirmBackupDialog extends StatefulWidget {
  const _ConfirmBackupDialog({required this.name, required this.phrase});
  final String name;
  final String phrase;

  @override
  State<_ConfirmBackupDialog> createState() => _ConfirmBackupDialogState();
}

class _ConfirmBackupDialogState extends State<_ConfirmBackupDialog> {
  final _confirmation = TextEditingController();
  bool _mismatch = false;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Sauvegarder cette fiche ?'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seule la fiche de ${widget.name} sera sauvegardée, chiffrée. '
              'Les favoris, historiques, abonnements et préférences ne sont pas inclus. '
              'La perte de la phrase secrète rend la sauvegarde irrécupérable.',
            ),
            TextField(
              controller: _confirmation,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Confirmer la phrase secrète',
                errorText: _mismatch
                    ? 'Les phrases secrètes ne correspondent pas.'
                    : null,
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
      );
}
