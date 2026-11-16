import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';

class _UnusedDocumentStore implements EncryptedDocumentStore {
  @override
  Future<Map<String, dynamic>?> read(String uid, String documentId) =>
      throw UnimplementedError();

  @override
  Future<void> writeIfRevisionMatches(
    String uid,
    String documentId,
    int expectedRevision,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();
}

class _Remote extends EncryptedScopeStore {
  _Remote() : super(EncryptedCloudStore(store: _UnusedDocumentStore()));
  EncryptedScopeSnapshot? snapshot;
  bool failWrite = false;
  void Function()? onWrite;

  @override
  Future<EncryptedScopeSnapshot?> read({
    required String uid,
    required String profileId,
    required String scope,
    required String passphrase,
  }) async =>
      snapshot;

  @override
  Future<int> write({
    required String uid,
    required String profileId,
    required String scope,
    required String passphrase,
    required EncryptedScopeSnapshot snapshot,
    void Function()? checkSession,
  }) async {
    if (failWrite) throw StateError('offline');
    onWrite?.call();
    checkSession?.call();
    if ((this.snapshot?.revision ?? 0) != snapshot.revision) {
      throw const CloudSyncConflict();
    }
    this.snapshot = EncryptedScopeSnapshot(
      revision: snapshot.revision + 1,
      entries: snapshot.entries,
    );
    return this.snapshot!.revision;
  }
}

class _Baselines implements ScopeBaselineStore {
  final values = <String, ScopeBaseline>{};
  String key(String uid, String profile, String scope) =>
      '$uid/$profile/$scope';

  @override
  Future<ScopeBaseline?> read(
          String uid, String profileId, String scope) async =>
      values[key(uid, profileId, scope)];

  @override
  Future<void> write(
    String uid,
    String profileId,
    String scope,
    Map<String, String> entries,
  ) async {
    values[key(uid, profileId, scope)] =
        ScopeBaseline.fromEntries(entries, List.filled(32, 7));
  }
}

class _Local implements LocalSyncScope {
  Map<String, String> entries = {};

  @override
  void validate(Map<String, String> entries) {}

  @override
  Future<Map<String, String>> read() async => Map.of(entries);

  @override
  Future<void> applyIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  ) async {
    checkSession();
    if (entries.length != expected.length ||
        expected.entries.any((e) => entries[e.key] != e.value)) {
      throw StateError('local changed');
    }
    entries = Map.of(merged);
  }
}

void main() {
  late _Remote remote;
  late _Baselines baselines;
  late _Local local;
  late EncryptedScopeSynchronizer sync;
  var account = 'user';
  Future<bool> run() => sync.synchronize(
        uid: 'user',
        profileId: 'profile',
        scope: 'favorites',
        passphrase: 'phrase',
        local: local,
        checkSession: () {
          if (account != 'user') throw StateError('account changed');
        },
      );

  setUp(() {
    account = 'user';
    remote = _Remote();
    baselines = _Baselines();
    local = _Local();
    sync = EncryptedScopeSynchronizer(remote: remote, baselines: baselines);
  });

  test('merges updates and deletes from separate devices', () async {
    local.entries = {'a': 'old', 'b': 'old'};
    await run();
    local.entries = {'a': 'local'};
    remote.snapshot = EncryptedScopeSnapshot(
      revision: 2,
      entries: {'a': 'old', 'b': 'old', 'c': 'remote'},
    );
    await run();
    expect(local.entries, {'a': 'local', 'c': 'remote'});
    expect(remote.snapshot!.entries, local.entries);
    expect(baselines.values.values.single.fingerprints.toString(),
        isNot(contains('local')));
  });

  test('failed push never advances the mirror or changes local data', () async {
    local.entries = {'a': 'value'};
    remote.failWrite = true;
    await expectLater(run(), throwsStateError);
    expect(baselines.values, isEmpty);
    expect(local.entries, {'a': 'value'});
  });

  test('changes during push are preserved and do not advance the mirror',
      () async {
    local.entries = {'a': 'old'};
    remote.onWrite = () => local.entries = {'a': 'new'};
    await expectLater(run(), throwsStateError);
    expect(local.entries, {'a': 'new'});
    expect(baselines.values, isEmpty);
  });

  test('account changes and missing cloud documents fail closed', () async {
    local.entries = {'a': 'old'};
    remote.onWrite = () => account = 'other';
    await expectLater(run(), throwsStateError);
    expect(baselines.values, isEmpty);
    account = 'user';
    remote.onWrite = null;
    await run();
    remote.snapshot = null;
    await expectLater(run(), throwsStateError);
    expect(local.entries, {'a': 'old'});
  });

  test('conflicts leave both sides untouched', () async {
    local.entries = {'a': 'base'};
    await run();
    local.entries = {'a': 'local'};
    remote.snapshot = EncryptedScopeSnapshot(
      revision: 2,
      entries: {'a': 'remote'},
    );
    await expectLater(run(), throwsA(isA<ScopeMergeConflict>()));
    expect(local.entries['a'], 'local');
    expect(remote.snapshot!.entries['a'], 'remote');
  });

  test('explicit conflict choice applies only to conflicting keys', () {
    final baseline = ScopeBaseline.fromEntries(
      {'a': 'base', 'b': 'base'},
      List.filled(32, 7),
    );
    expect(
      mergeScopeWithBaseline(
        baseline: baseline,
        local: {'a': 'local', 'b': 'local'},
        remote: {'a': 'cloud', 'b': 'base', 'c': 'cloud'},
        conflictChoice: ScopeConflictChoice.cloud,
      ),
      {'a': 'cloud', 'b': 'local', 'c': 'cloud'},
    );
    expect(
      mergeScopeWithBaseline(
        baseline: baseline,
        local: {'b': 'base'},
        remote: {'a': 'cloud', 'b': 'base'},
        conflictChoice: ScopeConflictChoice.local,
      ),
      {'b': 'base'},
    );
  });
}
