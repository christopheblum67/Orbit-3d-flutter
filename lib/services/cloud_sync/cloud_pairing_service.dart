import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const qrPairingEnabled =
    bool.fromEnvironment('ORBIT_QR_PAIRING_ENABLED', defaultValue: false);

const qrPairingRegion = 'europe-west9';

bool get qrPairingAvailable =>
    qrPairingEnabled &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android;

String _encode(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

List<int> _decode(Object? value, {int? length, int? maxLength}) {
  if (value is! String || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
    throw const FormatException('Données de couplage invalides.');
  }
  final bytes = base64Url.decode(base64Url.normalize(value));
  if (_encode(bytes) != value ||
      (length != null && bytes.length != length) ||
      (maxLength != null && bytes.length > maxLength)) {
    throw const FormatException('Données de couplage invalides.');
  }
  return bytes;
}

class PairingInvitation {
  PairingInvitation({required this.secret, required this.publicKey}) {
    _decode(secret, length: 32);
    _decode(publicKey, length: 32);
  }

  final String secret;
  final String publicKey;

  String get qrValue => Uri(
        scheme: 'orbit3d',
        host: 'pair',
        queryParameters: {'v': '1', 's': secret, 'k': publicKey},
      ).toString();

  String get verificationCode {
    final hash = hashes.sha256
        .convert([
          ..._decode(secret, length: 32),
          ..._decode(publicKey, length: 32),
        ])
        .toString()
        .substring(0, 16)
        .toUpperCase();
    return '${hash.substring(0, 4)} ${hash.substring(4, 8)} '
        '${hash.substring(8, 12)} ${hash.substring(12, 16)}';
  }

  factory PairingInvitation.parse(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'orbit3d' ||
        uri.host != 'pair' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.path.isNotEmpty ||
        uri.hasFragment ||
        uri.queryParametersAll.length != 3 ||
        uri.queryParametersAll.values.any((values) => values.length != 1) ||
        uri.queryParameters['v'] != '1' ||
        !uri.queryParameters.containsKey('s') ||
        !uri.queryParameters.containsKey('k')) {
      throw const FormatException('QR code de couplage invalide.');
    }
    return PairingInvitation(
      secret: uri.queryParameters['s']!,
      publicKey: uri.queryParameters['k']!,
    );
  }
}

class TvPairingSession {
  TvPairingSession({
    required this.invitation,
    required this.keyPair,
    required this.ownerUid,
    required this.expiresAt,
  });

  final PairingInvitation invitation;
  final SimpleKeyPair keyPair;
  final String ownerUid;
  final DateTime expiresAt;
}

class PairingResult {
  const PairingResult(
    this.uid,
    this.phrase, {
    this.cleanupFailed = false,
    this.profileIds = const {},
  });

  final String uid;
  final String phrase;
  final bool cleanupFailed;
  final Set<String> profileIds;
}

class CloudPairingService {
  CloudPairingService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    @visibleForTesting
    Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)? call,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: qrPairingRegion),
        _testCall = call;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
      _testCall;
  final _exchange = X25519();
  final _cipher = AesGcm.with256bits();
  static final _appChecks = <String, Future<void>>{};

  static Future<void> prepareAppCheck({FirebaseApp? app}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Le couplage est disponible sur Android uniquement.',
      );
    }
    try {
      final selected = app ?? Firebase.app();
      await (_appChecks[selected.name] ??=
          FirebaseAppCheck.instanceFor(app: selected).activate());
    } catch (_) {
      _appChecks.remove((app ?? Firebase.app()).name);
      rethrow;
    }
  }

  static void forgetApp(FirebaseApp app) => _appChecks.remove(app.name);

  void _checkUser(String uid, {required bool anonymous}) {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid || user.isAnonymous != anonymous) {
      throw StateError('Le compte cloud a changé.');
    }
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final testCall = _testCall;
    if (testCall != null) return testCall(name, data);
    final result =
        await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
    return result.data;
  }

  Future<TvPairingSession> create(String ownerUid) async {
    _checkUser(ownerUid, anonymous: true);
    final keyPair = await _exchange.newKeyPair();
    final publicKey = _encode((await keyPair.extractPublicKey()).bytes);
    final response = await _call('createTvPairing', {'publicKey': publicKey});
    _checkUser(ownerUid, anonymous: true);
    final secret = response['secret'];
    final expires = response['expiresAt'];
    if (secret is! String || expires is! int) {
      throw const FormatException('Réponse de couplage invalide.');
    }
    return TvPairingSession(
      invitation: PairingInvitation(secret: secret, publicKey: publicKey),
      keyPair: keyPair,
      ownerUid: ownerUid,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires, isUtc: true),
    );
  }

  @visibleForTesting
  Future<Map<String, String>> encryptPhrase(
    PairingInvitation invite,
    String phrase,
  ) =>
      _encryptPayload(invite, phrase, 'phrase');

  @visibleForTesting
  Future<Map<String, String>> encryptProfileIds(
    PairingInvitation invite,
    Iterable<String> profileIds,
  ) async {
    final ids = profileIds.toList();
    if (ids.length > 100 ||
        ids.toSet().length != ids.length ||
        ids.any((id) =>
            id.isEmpty ||
            id.length > 128 ||
            id.contains('/') ||
            id.contains(':'))) {
      throw StateError('La sélection des profils est invalide.');
    }
    return _encryptPayload(invite, jsonEncode(ids), 'profiles');
  }

  Future<Map<String, String>> _encryptPayload(
    PairingInvitation invite,
    String plaintext,
    String kind,
  ) async {
    final data = utf8.encode(plaintext);
    if (data.isEmpty || data.length > 2048) {
      throw StateError(
        'Les données de couplage doivent contenir entre 1 et 2048 octets.',
      );
    }
    final ephemeral = await _exchange.newKeyPair();
    final shared = await _exchange.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        _decode(invite.publicKey, length: 32),
        type: KeyPairType.x25519,
      ),
    );
    final label = 'orbit-pairing/v1/$kind';
    final key = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared,
      nonce: _decode(invite.secret, length: 32),
      info: utf8.encode(label),
    );
    final box =
        await _cipher.encrypt(data, secretKey: key, aad: utf8.encode(label));
    return {
      'key': _encode((await ephemeral.extractPublicKey()).bytes),
      'nonce': _encode(box.nonce),
      'ciphertext': _encode(box.cipherText),
      'mac': _encode(box.mac.bytes),
    };
  }

  @visibleForTesting
  Future<String> decrypt(
    Object? data,
    TvPairingSession session,
    String kind,
  ) async {
    if (data is! Map ||
        data.length != 4 ||
        !data.keys.toSet().containsAll({'key', 'nonce', 'ciphertext', 'mac'})) {
      throw const FormatException('Données de couplage invalides.');
    }
    final remote = SimplePublicKey(
      _decode(data['key'], length: 32),
      type: KeyPairType.x25519,
    );
    final shared = await _exchange.sharedSecretKey(
      keyPair: session.keyPair,
      remotePublicKey: remote,
    );
    final label = 'orbit-pairing/v1/$kind';
    final key = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared,
      nonce: _decode(session.invitation.secret, length: 32),
      info: utf8.encode(label),
    );
    final box = SecretBox(
      _decode(data['ciphertext'], maxLength: 8192),
      nonce: _decode(data['nonce'], length: 12),
      mac: Mac(_decode(data['mac'], length: 16)),
    );
    return utf8.decode(
      await _cipher.decrypt(box, secretKey: key, aad: utf8.encode(label)),
    );
  }

  Future<void> approve(PairingInvitation invite, String phrase, String uid,
      {Iterable<String> profileIds = const []}) async {
    _checkUser(uid, anonymous: false);
    final encrypted = await encryptPhrase(invite, phrase);
    final encryptedProfiles = await encryptProfileIds(invite, profileIds);
    _checkUser(uid, anonymous: false);
    await _call('approveTvPairing', {
      'secret': invite.secret,
      'publicKey': invite.publicKey,
      'phrase': encrypted,
      'profiles': encryptedProfiles,
    });
    _checkUser(uid, anonymous: false);
  }

  Future<String?> check(TvPairingSession session) async {
    _checkUser(session.ownerUid, anonymous: true);
    final response =
        await _call('checkTvPairing', {'secret': session.invitation.secret});
    _checkUser(session.ownerUid, anonymous: true);
    if (response['status'] == 'pending') return null;
    if (response['status'] == 'approved' &&
        response['accountLabel'] is String) {
      return response['accountLabel'] as String;
    }
    throw const FormatException('Réponse de couplage invalide.');
  }

  Future<PairingResult> consume(
    TvPairingSession session,
    FirebaseAuth targetAuth,
  ) async {
    _checkUser(session.ownerUid, anonymous: true);
    if (targetAuth.currentUser != null) {
      throw StateError('Déconnectez le compte cloud avant le couplage.');
    }
    final response =
        await _call('consumeTvPairing', {'secret': session.invitation.secret});
    _checkUser(session.ownerUid, anonymous: true);
    final uid = response['uid'];
    if (uid is! String || uid.isEmpty) {
      throw const FormatException('Compte invalide.');
    }
    final phrase = await decrypt(response['phrase'], session, 'phrase');
    final token = await decrypt(response['token'], session, 'token');
    if (phrase.isEmpty || token.isEmpty) {
      throw const FormatException('Données de couplage invalides.');
    }
    final rawProfiles = response['profiles'];
    final profileIds = rawProfiles == null
        ? <String>{}
        : _decodeProfileIds(
            await decrypt(rawProfiles, session, 'profiles'),
          );
    _checkUser(session.ownerUid, anonymous: true);
    if (targetAuth.currentUser != null) {
      throw StateError('Le compte cloud a changé.');
    }
    final credential = await targetAuth.signInWithCustomToken(token);
    if (credential.user?.uid != uid) {
      if (targetAuth.currentUser?.uid == credential.user?.uid) {
        await targetAuth.signOut();
      }
      throw StateError('Le compte associé ne correspond pas.');
    }
    if (targetAuth.currentUser?.uid != uid) {
      throw StateError('Le compte cloud a changé.');
    }
    return PairingResult(uid, phrase, profileIds: profileIds);
  }

  Set<String> _decodeProfileIds(String plaintext) {
    final decoded = jsonDecode(plaintext);
    if (decoded is! List ||
        decoded.length > 100 ||
        decoded.any((id) =>
            id is! String ||
            id.isEmpty ||
            id.length > 128 ||
            id.contains('/') ||
            id.contains(':'))) {
      throw const FormatException('Sélection des profils invalide.');
    }
    final ids = decoded.cast<String>();
    if (ids.toSet().length != ids.length) {
      throw const FormatException('Sélection des profils invalide.');
    }
    return Set.unmodifiable(ids);
  }

  Future<void> cancel(TvPairingSession session) async {
    _checkUser(session.ownerUid, anonymous: true);
    await _call('cancelTvPairing', {'secret': session.invitation.secret});
  }
}
