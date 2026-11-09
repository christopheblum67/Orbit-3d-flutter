import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Versioned, authenticated encryption for private cloud data.
class CloudSyncCipher {
  CloudSyncCipher() : _cipher = AesGcm.with256bits();

  static const int _version = 1;
  final AesGcm _cipher;

  Future<Map<String, Object>> encrypt({
    required String plaintext,
    required String passphrase,
    required String userId,
    required String documentId,
  }) async {
    _validateInputs(passphrase, userId, documentId);
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final key = await _deriveKey(passphrase, salt);
    final box = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      aad: _associatedData(userId, documentId),
    );
    return {
      'version': _version,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<String> decrypt({
    required Map<String, dynamic> envelope,
    required String passphrase,
    required String userId,
    required String documentId,
  }) async {
    _validateInputs(passphrase, userId, documentId);
    if (envelope['version'] != _version) {
      throw const FormatException('Unsupported encrypted data version.');
    }
    final salt = _decode(envelope, 'salt', expectedLength: 16);
    final nonce = _decode(envelope, 'nonce', expectedLength: 12);
    final ciphertext = _decode(envelope, 'ciphertext');
    final mac = _decode(envelope, 'mac', expectedLength: 16);
    final key = await _deriveKey(passphrase, salt);
    final plaintext = await _cipher.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
      secretKey: key,
      aad: _associatedData(userId, documentId),
    );
    return utf8.decode(plaintext);
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final bytes = await Isolate.run(() async {
      final kdf = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 600000,
        bits: 256,
      );
      final key = await kdf.deriveKey(
        secretKey: SecretKey(utf8.encode(passphrase)),
        nonce: salt,
      );
      return key.extractBytes();
    });
    return SecretKey(bytes);
  }

  List<int> _associatedData(String userId, String documentId) => utf8
      .encode(jsonEncode(['orbit-cloud-sync', _version, userId, documentId]));

  void _validateInputs(String passphrase, String userId, String documentId) {
    if (passphrase.isEmpty || userId.isEmpty || documentId.isEmpty) {
      throw ArgumentError('Passphrase, user ID and document ID are required.');
    }
  }

  List<int> _decode(
    Map<String, dynamic> envelope,
    String field, {
    int? expectedLength,
  }) {
    final value = envelope[field];
    if (value is! String) {
      throw FormatException('Invalid encrypted data field: $field.');
    }
    final bytes = base64Decode(value);
    if (expectedLength != null && bytes.length != expectedLength) {
      throw FormatException('Invalid encrypted data field: $field.');
    }
    return bytes;
  }
}
