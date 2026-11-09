import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_cipher.dart';

void main() {
  test('encrypts private data and authenticates its context', () async {
    final cipher = CloudSyncCipher();
    const secret = 'une phrase secrete pour mes appareils';
    const plaintext = '{"url":"https://example.test/secret?password=private"}';
    final first = await cipher.encrypt(
      plaintext: plaintext,
      passphrase: secret,
      userId: 'account-a',
      documentId: 'profile-a',
    );
    final second = await cipher.encrypt(
      plaintext: plaintext,
      passphrase: secret,
      userId: 'account-a',
      documentId: 'profile-a',
    );
    expect(jsonEncode(first), isNot(contains('password')));
    expect(first['salt'], isNot(second['salt']));
    expect(first['nonce'], isNot(second['nonce']));
    expect(
      await cipher.decrypt(
        envelope: first,
        passphrase: secret,
        userId: 'account-a',
        documentId: 'profile-a',
      ),
      plaintext,
    );
    await expectLater(
      cipher.decrypt(
        envelope: first,
        passphrase: 'phrase incorrecte',
        userId: 'account-a',
        documentId: 'profile-a',
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      cipher.decrypt(
        envelope: first,
        passphrase: secret,
        userId: 'account-b',
        documentId: 'profile-a',
      ),
      throwsA(isA<Exception>()),
    );
    final mac = base64Decode(first['mac']! as String);
    mac[0] ^= 1;
    await expectLater(
      cipher.decrypt(
        envelope: {...first, 'mac': base64Encode(mac)},
        passphrase: secret,
        userId: 'account-a',
        documentId: 'profile-a',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects invalid formats and missing inputs', () async {
    final cipher = CloudSyncCipher();
    await expectLater(
      cipher.decrypt(
        envelope: {'version': 2},
        passphrase: 'secret',
        userId: 'user',
        documentId: 'document',
      ),
      throwsFormatException,
    );
    await expectLater(
      cipher.encrypt(
        plaintext: 'data',
        passphrase: '',
        userId: 'user',
        documentId: 'document',
      ),
      throwsArgumentError,
    );
  });
}
