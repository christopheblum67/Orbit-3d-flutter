import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';

class ProfilePin {
  static const _iterations = 120000;
  static const _prefix = 'pbkdf2-sha256';
  static const _channel = MethodChannel('orbit/profile_pin');

  static Future<List<int>> _derive(
    String pin,
    List<int> salt,
    int iterations,
  ) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final result = await _channel.invokeMethod<Uint8List>('derive', {
        'pin': pin,
        'salt': Uint8List.fromList(salt),
        'iterations': iterations,
      });
      if (result != null) {
        if (result.length != 32) {
          throw StateError('Invalid native PIN hash length');
        }
        return result;
      }
    }
    return Isolate.run(() async {
      final key = await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      ).deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
      return key.extractBytes();
    });
  }

  static Future<String> create(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const FormatException('Le code PIN doit comporter 4 chiffres.');
    }
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = await _derive(pin, salt, _iterations);
    return '$_prefix\$$_iterations\$${base64Encode(salt)}\$${base64Encode(hash)}';
  }

  static Future<bool> verify(UserProfile profile, String input) async {
    final stored = profile.pinHash;
    if (stored == null || !RegExp(r'^\d{4}$').hasMatch(input)) return false;
    // Older profiles stored the four digits directly. Do not rewrite them.
    if (RegExp(r'^\d{4}$').hasMatch(stored)) return stored == input;
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _prefix) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1 || iterations > _iterations) {
      return false;
    }
    List<int> salt;
    List<int> expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }
    if (salt.length != 16 || expected.length != 32) return false;
    final actual = await _derive(input, salt, iterations);
    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= expected[i] ^ actual[i];
    }
    return difference == 0;
  }
}
