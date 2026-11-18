import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Functions extends Fake implements FirebaseFunctions {}

class _User extends Fake implements User {
  _User(this.uid, this.isAnonymous);
  @override
  final String uid;
  @override
  final bool isAnonymous;
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User? user;
}

class _MutableAuth extends Fake implements FirebaseAuth {
  _MutableAuth(this.user);
  User? user;
  String? token;
  @override
  User? get currentUser => user;
  @override
  Future<UserCredential> signInWithCustomToken(String value) async {
    token = value;
    user = _User('account', false);
    return _Credential(user);
  }
}

void main() {
  final service = CloudPairingService(auth: _Auth(), functions: _Functions());
  const secret = 'CQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQk';
  const publicKey = 'E75P6uryBMf9M1j8nAByGIHRdCeBKCJ-xnTzf3_pe20';

  test('accepts only canonical, complete pairing invitations', () {
    final invite = PairingInvitation(secret: secret, publicKey: publicKey);
    final decoded = PairingInvitation.parse(invite.qrValue);
    expect(decoded.secret, secret);
    expect(decoded.publicKey, publicKey);
    expect(decoded.verificationCode, invite.verificationCode);
    for (final invalid in [
      '4892',
      'https://orbit.app/pair?code=4892',
      '${invite.qrValue}&v=1',
      '${invite.qrValue}&extra=1',
      invite.qrValue.replaceFirst('orbit3d://pair', 'orbit3d://user@pair'),
      invite.qrValue.replaceFirst(secret, 'short'),
    ]) {
      expect(() => PairingInvitation.parse(invalid), throwsFormatException);
    }
  });

  test('encrypts the phrase for the TV and rejects tampering', () async {
    final key = await X25519().newKeyPair();
    final invite = PairingInvitation(
      secret: secret,
      publicKey: base64Url
          .encode((await key.extractPublicKey()).bytes)
          .replaceAll('=', ''),
    );
    final session = TvPairingSession(
      invitation: invite,
      keyPair: key,
      ownerUid: 'temporary',
      expiresAt: DateTime.utc(2030),
    );
    final envelope = await service.encryptPhrase(invite, 'phrase secrète');
    expect(envelope.values.join(), isNot(contains('phrase')));
    expect(
      await service.decrypt(envelope, session, 'phrase'),
      'phrase secrète',
    );
    final tampered = Map<String, String>.from(envelope)
      ..['mac'] = base64Url.encode(List<int>.filled(16, 0)).replaceAll('=', '');
    await expectLater(
      service.decrypt(tampered, session, 'phrase'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    await expectLater(
      service.decrypt(envelope, session, 'token'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('encrypts selected profile IDs and rejects invalid selections',
      () async {
    final key = await X25519().newKeyPair();
    final invite = PairingInvitation(
      secret: secret,
      publicKey: base64Url
          .encode((await key.extractPublicKey()).bytes)
          .replaceAll('=', ''),
    );
    final session = TvPairingSession(
      invitation: invite,
      keyPair: key,
      ownerUid: 'temporary',
      expiresAt: DateTime.utc(2030),
    );
    final envelope = await service.encryptProfileIds(invite, ['p1', 'p2']);
    expect(envelope.values.join(), isNot(contains('p1')));
    expect(
      jsonDecode(await service.decrypt(envelope, session, 'profiles')),
      ['p1', 'p2'],
    );
    await expectLater(
      service.encryptProfileIds(invite, ['same', 'same']),
      throwsStateError,
    );
  });

  test('decrypts a token encrypted by the Node.js Firebase function', () async {
    final key = await X25519().newKeyPairFromSeed(List<int>.filled(32, 7));
    expect(
      base64Url
          .encode((await key.extractPublicKey()).bytes)
          .replaceAll('=', ''),
      publicKey,
    );
    final session = TvPairingSession(
      invitation: PairingInvitation(secret: secret, publicKey: publicKey),
      keyPair: key,
      ownerUid: 'temporary',
      expiresAt: DateTime.utc(2030),
    );
    expect(
      await service.decrypt(
        {
          'key': '-NdKuysICRnYhdXNPty5yJ490VPI-UC3G-w7o_oN-jQ',
          'nonce': 'fChyiJMSw8IxOBvR',
          'ciphertext': 'sJspKHUQbzR4jA',
          'mac': '-ZVXe4m86oQnLnaDSSszaQ',
        },
        session,
        'token',
      ),
      'test-token',
    );
  });

  test(
      'consumes once, decrypts both payloads and signs in only an empty account',
      () async {
    final key = await X25519().newKeyPairFromSeed(List<int>.filled(32, 7));
    final invitation = PairingInvitation(secret: secret, publicKey: publicKey);
    final session = TvPairingSession(
      invitation: invitation,
      keyPair: key,
      ownerUid: 'temporary',
      expiresAt: DateTime.utc(2030),
    );
    final phrase = await service.encryptPhrase(invitation, 'phrase secrète');
    final profiles = await service.encryptProfileIds(invitation, ['p1', 'p2']);
    final owner = _MutableAuth(_User('temporary', true));
    final target = _MutableAuth(null);
    var calls = 0;
    final pairing = CloudPairingService(
      auth: owner,
      functions: _Functions(),
      call: (name, data) async {
        expect(name, 'consumeTvPairing');
        expect(data['secret'], secret);
        calls++;
        return {
          'uid': 'account',
          'phrase': phrase,
          'profiles': profiles,
          'token': {
            'key': '-NdKuysICRnYhdXNPty5yJ490VPI-UC3G-w7o_oN-jQ',
            'nonce': 'fChyiJMSw8IxOBvR',
            'ciphertext': 'sJspKHUQbzR4jA',
            'mac': '-ZVXe4m86oQnLnaDSSszaQ',
          },
        };
      },
    );
    final result = await pairing.consume(session, target);
    expect(result.uid, 'account');
    expect(result.phrase, 'phrase secrète');
    expect(result.profileIds, {'p1', 'p2'});
    expect(target.token, 'test-token');
    await expectLater(pairing.consume(session, target), throwsStateError);
    expect(calls, 1);
    owner.user = _User('different', true);
    await expectLater(pairing.check(session), throwsStateError);
    expect(calls, 1);
  });
}
