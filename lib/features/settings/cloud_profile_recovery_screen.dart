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
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_activity_sync_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';

String _scopeLabel(AppLocalizations l, String scope) => switch (scope) {
      'favorites' => l.cloudScopeFavorites,
      'radioFavorites' => l.cloudScopeRadioFavorites,
      'recents' => l.cloudScopeRecents,
      'watched' => l.cloudScopeWatched,
      'playback' => l.cloudScopePlayback,
      'preferences' => l.cloudScopePreferences,
      'profile' => l.cloudScopeProfile,
      'subscriptions' => l.cloudScopeSubscriptions,
      _ => l.cloudScopeData,
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
    final l = AppLocalizations.of(context);
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
      _message = l.cloudChangedElsewhere;
      _catalog = null;
    } on SecretBoxAuthenticationError {
      _message = _legacyPhrase ? l.cloudBadPhrase : l.cloudBadCode;
      _catalog = null;
    } on FirebaseException {
      _message = l.cloudAccessFailed;
    } on FormatException {
      _message = l.cloudInvalidData;
    } on StateError catch (error) {
      _message = error.message.toString();
    } catch (_) {
      _message = l.cloudOperationFailed;
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
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                autofocus: focusConfirm,
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).cloudConfirm),
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
            title: Text(AppLocalizations.of(context).cloudShareProfilesTitle),
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
                        ? Text(AppLocalizations.of(context)
                            .cloudDuplicateProfileId(profile.id))
                        : null,
                  ),
                Text(AppLocalizations.of(context).cloudShareProfilesHelp),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).cloudConfirm),
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
            title: Text(AppLocalizations.of(context).cloudChooseSourceTitle),
            scrollable: true,
            content: Text(AppLocalizations.of(context).cloudChooseSourceHelp),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pop(context, ScopeConflictChoice.local),
                child: Text(AppLocalizations.of(context).cloudSourceLocal),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, ScopeConflictChoice.cloud),
                child: Text(AppLocalizations.of(context).cloudSourceRemote),
              ),
            ],
          ),
        ),
      );

  Future<void> _load(String uid, {bool afterPublish = false}) async {
    final l = AppLocalizations.of(context);
    ProfileCatalogSnapshot? loaded;
    final success = await _run(() async {
      if (_phrase.text.isEmpty) {
        throw StateError(l.cloudAskAdult);
      }
      if (!_legacyPhrase && !RegExp(r'^[0-9]{3,10}$').hasMatch(_phrase.text)) {
        throw StateError(l.cloudCodeLength);
      }
      final phrase = _phrase.text;
      final snapshot = await _recovery.load(uid, phrase);
      loaded = snapshot;
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid || _phrase.text != phrase) {
        throw StateError(l.cloudAccountChanged);
      }
      _catalog = snapshot;
      _loadedUid = uid;
      _message = afterPublish
          ? l.cloudBackupRefreshed
          : snapshot.revision == 0
              ? snapshot.verified
                  ? l.cloudAccessEmpty
                  : l.cloudCodeUnverified
              : snapshot.profiles.isEmpty
                  ? l.cloudAccessEmpty
                  : l.cloudAccessChoose;
    }, errorPrefix: afterPublish ? l.cloudBackupRefreshFailed : null);
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
      setState(() => _message = l.cloudPhoneProfilesMissing);
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
      _message = l.cloudPhoneProfilesReceived;
    });
    await _syncSelected(uid, localProfiles!, confirm: false);
  }

  Future<void> _publish(String uid, UserProfile profile) async {
    final l = AppLocalizations.of(context);
    final phrase = _phrase.text;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmBackupDialog(
          name: profile.firstName, phrase: phrase, legacy: _legacyPhrase),
    );
    if (accepted != true) return;
    if (!mounted) return;
    if (_phrase.text != phrase || _auth.currentUser?.uid != uid) {
      setState(() => _message = l.cloudPhraseChanged);
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
    final l = AppLocalizations.of(context);
    if (!await _confirm(
      l.cloudRestoreTitle,
      l.cloudRestoreHelp(name),
    )) return;
    if (!mounted) return;
    await _run(() async {
      await _recovery.restore(uid, _phrase.text, id);
      if (!mounted) return;
      ref.invalidate(profilesProvider);
      _message = l.cloudProfileRestored;
    });
  }

  Future<void> _deleteCloudProfile(String uid, String id, String name) async {
    final l = AppLocalizations.of(context);
    if (!await _confirm(
      l.cloudDeleteTitle(name),
      l.cloudDeleteHelp,
    )) {
      return;
    }
    if (!mounted || _auth.currentUser?.uid != uid) return;
    final activity = ref.read(encryptedActivitySyncProvider);
    if (activity.busy) {
      setState(() => _message = l.cloudWaitDelete);
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
            title: Text(AppLocalizations.of(context).cloudResetTitle),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).cloudResetHelp),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('cloud-reset-code'),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => code = value,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).cloudNewCode,
                  ),
                ),
                TextField(
                  key: const ValueKey('cloud-reset-confirmation'),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => confirmation = value,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).cloudConfirmCode,
                  ),
                  onSubmitted: (_) {
                    if (!_validResetCode(code, confirmation, currentCode)) {
                      setDialogState(() => error =
                          AppLocalizations.of(context).cloudResetCodeError);
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
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (!_validResetCode(code, confirmation, currentCode)) {
                    setDialogState(() => error =
                        AppLocalizations.of(context).cloudResetCodeError);
                  } else {
                    Navigator.pop(dialogContext, code);
                  }
                },
                child: Text(AppLocalizations.of(context).reset),
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
    final l = AppLocalizations.of(context);
    if (ref.read(encryptedActivitySyncProvider).busy) {
      setState(() => _message = l.cloudWaitReset);
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
      _message = l.cloudResetComplete;
    });
    if (reset && mounted) setState(() {});
  }

  Future<void> _unlockActivity(
      String uid, ProfileCatalogSnapshot catalog) async {
    final phrase = _phrase.text;
    final l = AppLocalizations.of(context);
    if (!await _confirm(
      l.cloudSyncProfileTitle,
      l.cloudSyncProfileHelp,
    )) return;
    final initialConflictChoice = await _chooseInitialSource();
    if (initialConflictChoice == null) return;
    if (!mounted) return;
    if (_phrase.text != phrase ||
        _auth.currentUser?.uid != uid ||
        !identical(_catalog, catalog)) {
      setState(() => _message = l.cloudPhraseChanged);
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
    final l = AppLocalizations.of(context);
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
      setState(() => _message = l.cloudAccountChanged);
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
      setState(() => _message = l.cloudWaitSelection);
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
        throw StateError(l.cloudAccountChanged);
      }
      final fresh = await ref.refresh(profilesProvider.future);
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid ||
          _phrase.text != phrase ||
          !identical(_catalog, catalog)) {
        throw StateError(l.cloudAccountChanged);
      }
      final freshById = {for (final profile in fresh) profile.id: profile};
      for (final profile in localSelected) {
        if (freshById[profile.id] == null ||
            jsonEncode(freshById[profile.id]!.toMap()) !=
                jsonEncode(profile.toMap())) {
          throw StateError(l.cloudProfilesChanged);
        }
      }
      for (final (index, entry) in cloudOnly.indexed) {
        if (freshById.containsKey(entry.key)) {
          throw StateError(l.cloudProfilesChanged);
        }
        setState(() =>
            _progress = l.cloudRestoringProfiles(index + 1, cloudOnly.length));
        try {
          await _recovery.restore(uid, phrase, entry.key);
        } finally {
          if (mounted) ref.invalidate(profilesProvider);
        }
        if (!mounted ||
            _auth.currentUser?.uid != uid ||
            _phrase.text != phrase ||
            !identical(_catalog, catalog)) {
          throw StateError(l.cloudAccountChanged);
        }
      }
      final restoredProfiles = await ref.refresh(profilesProvider.future);
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid ||
          _phrase.text != phrase ||
          !identical(_catalog, catalog)) {
        throw StateError(l.cloudAccountChanged);
      }
      final restoredById = {
        for (final profile in restoredProfiles) profile.id: profile
      };
      final selected = <UserProfile>[...localSelected];
      for (final entry in cloudOnly) {
        final profile = restoredById[entry.key];
        if (profile == null) {
          throw StateError(l.cloudRestoredProfileMissing);
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
            throw StateError(l.cloudProfilesChanged);
          }
        }
      }

      setState(() => _progress = l.cloudCheckingProfiles);
      updated = await _recovery.publishMissing(
        uid,
        phrase,
        selected,
        checkProfiles: checkProfiles,
      );
      if (!mounted) return;
      if (_auth.currentUser?.uid != uid || _phrase.text != phrase) {
        throw StateError(l.cloudAccountChanged);
      }
      _catalog = updated;
      _loadedUid = uid;
    }, errorPrefix: cloudOnly.isEmpty ? null : l.cloudPartialRestore);
    if (!saved || !mounted || updated == null) return;
    final syncStarted = await _run(() async {
      setState(() => _progress = l.cloudStartingSync);
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
    }, errorPrefix: l.cloudProfilesBackedUp);
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
          title: Text(AppLocalizations.of(dialogContext).cloudSyncFinished),
          content:
              Text(AppLocalizations.of(dialogContext).cloudSyncFinishedHelp),
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
    final l = AppLocalizations.of(context);
    if (!await _confirm(
      l.cloudResolveTitle,
      cloud ? l.cloudResolveRemoteHelp : l.cloudResolveLocalHelp,
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.cloudProfilesTitle)),
      body: StreamBuilder<User?>(
        stream: _authChanges,
        builder: (context, auth) {
          final user = auth.data;
          if (user == null || user.isAnonymous) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l.cloudSignInToContinue),
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
                              ? l.cloudPrepareCodeHelp
                              : l.cloudChooseProfilesHelp,
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.hourglass_top_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.cloudFirstSyncHelp),
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
                  labelText:
                      _legacyPhrase ? l.cloudLegacyPhrase : l.cloudAdultCode,
                  helperText: _legacyPhrase
                      ? l.cloudSamePhraseHelp
                      : l.cloudSameCodeHelp,
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    tooltip: _legacyPhrase
                        ? (_obscurePhrase
                            ? l.cloudShowPhrase
                            : l.cloudHidePhrase)
                        : (_obscurePhrase ? l.cloudShowCode : l.cloudHideCode),
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
                child: Text(
                    catalog == null ? l.cloudSeeProfiles : l.cloudRefreshList),
              ),
              ExpansionTile(
                title: Text(l.cloudAdultOptions),
                children: [
                  SwitchListTile(
                    title: Text(l.cloudUseLegacyPhrase),
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
                                setState(
                                    () => _message = l.cloudShareBeforePairing);
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
                      child: Text(l.cloudPairTv),
                    ),
                  if (catalog != null)
                    TextButton(
                      onPressed: _busy ? null : () => _resetCloud(user.uid),
                      child: Text(l.cloudResetAction),
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
                                    ? l.cloudUpdating
                                    : activity.conflictScope != null
                                        ? l.cloudAdultMustChoose
                                        : activity.error ??
                                            l.cloudSharingEnabled,
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
                              l.cloudProgressPercent(
                                (100 *
                                        activity.completedScopes /
                                        activity.totalScopes)
                                    .floor(),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(l.cloudKeepOpen),
                        ] else if (activity.error == null &&
                            activity.lastSyncAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(l.cloudAutoSharing),
                          ),
                        if (activity.busy && activity.currentScope != null)
                          Text(activity.currentProfileId == null
                              ? l.cloudProgressScope(
                                  _scopeLabel(l, activity.currentScope!))
                              : l.cloudProgressProfile(
                                  _scopeLabel(l, activity.currentScope!),
                                  catalog?.profiles[activity.currentProfileId]
                                          ?['firstName'] as String? ??
                                      l.cloudProfileFallback,
                                )),
                      ],
                    ),
                  ),
                ),
                if (activity.conflictScope != null) ...[
                  Text(l.cloudConflictHelp),
                  if (activity.conflictProfileId != null)
                    Text(l.cloudConflictProfile(
                      catalog?.profiles[activity.conflictProfileId]
                              ?['firstName'] as String? ??
                          activity.conflictProfileId!,
                      activity.conflictProfileId!,
                    )),
                  Text(l.cloudConflictData(
                      _scopeLabel(l, activity.conflictScope!))),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _resolveConflict(ScopeConflictChoice.local),
                        child: Text(l.cloudKeepLocal),
                      ),
                      TextButton(
                        onPressed: () =>
                            _resolveConflict(ScopeConflictChoice.cloud),
                        child: Text(l.cloudKeepRemote),
                      ),
                    ],
                  ),
                ],
                ExpansionTile(
                  title: Text(l.cloudShareSettings),
                  children: [
                    TextButton(
                      onPressed: activity.busy ? null : _syncAllManually,
                      child: Text(l.cloudUpdateNow),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(encryptedActivitySyncProvider.notifier)
                          .lock(),
                      child: Text(l.cloudPause),
                    ),
                  ],
                ),
              ],
              if (catalog != null) ...[
                const SizedBox(height: 16),
                Text(
                  activity.unlocked
                      ? l.cloudSelectProfiles
                      : l.cloudWhichProfiles,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                local.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Text(l.cloudLocalProfilesUnavailable),
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
                                ? l.cloudUnselectAll
                                : l.cloudSelectAll),
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
                                ? l.cloudShareSelected
                                : l.cloudShareAll),
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
                                    ? Text(AppLocalizations.of(context)
                                        .cloudDuplicateProfileId(profile.id))
                                    : null,
                              ),
                            )),
                        if (catalog.profiles.keys
                            .any((id) => !profiles.any((p) => p.id == id))) ...[
                          const SizedBox(height: 16),
                          Text(l.cloudProfilesToAdd),
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
                                    ? Text(AppLocalizations.of(context)
                                        .cloudDuplicateProfileId(entry.key))
                                    : null,
                              ),
                            ),
                        ExpansionTile(
                          title: Text(l.cloudOtherOptions),
                          children: [
                            if (!activity.unlocked)
                              TextButton(
                                onPressed: _busy || !activePublished
                                    ? null
                                    : () => _unlockActivity(user.uid, catalog),
                                child: Text(l.cloudShareActiveOnly),
                              ),
                            for (final profile in profiles)
                              if (!catalog.profiles.containsKey(profile.id))
                                ListTile(
                                  title: Text(profile.firstName),
                                  trailing: TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _publish(user.uid, profile),
                                    child: Text(l.cloudBackupAction),
                                  ),
                                ),
                            for (final entry in catalog.profiles.entries)
                              ListTile(
                                title: Text(entry.value['firstName'] as String),
                                subtitle: profiles.any((p) => p.id == entry.key)
                                    ? Text(l.cloudLocalProfileKept)
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
                                        child: Text(l.cloudRecover),
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
                                      child: Text(l.cloudDeleteAction),
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
              ? AppLocalizations.of(context).cloudConfirmYourCode
              : AppLocalizations.of(context).cloudBackupTitle),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.multiple
                    ? AppLocalizations.of(context)
                        .cloudConfirmProfilesHelp(widget.name)
                    : AppLocalizations.of(context).cloudBackupHelp(widget.name),
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
                      ? AppLocalizations.of(context).cloudConfirmPhrase
                      : AppLocalizations.of(context).cloudConfirmCloudCode,
                  suffixIcon: IconButton(
                    tooltip: _obscurePhrase
                        ? AppLocalizations.of(context).cloudShowConfirmation
                        : AppLocalizations.of(context).cloudHideConfirmation,
                    icon: Icon(_obscurePhrase
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePhrase = !_obscurePhrase),
                  ),
                  errorText: _mismatch
                      ? AppLocalizations.of(context).cloudSecretsMismatch
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
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
              child: Text(AppLocalizations.of(context).cloudConfirm),
            ),
          ],
        ),
      );
}
