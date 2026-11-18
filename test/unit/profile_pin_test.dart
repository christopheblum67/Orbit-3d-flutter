import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/profile_pin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const nativeChannel = MethodChannel('orbit/profile_pin');
  const knownHash = 'pbkdf2-sha256\$120000\$AAECAwQFBgcICQoLDA0ODw==\$'
      'UHAyHKNNva/pslNx0cD4O8r+Bz+64fInTwCm1saOmJk=';
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeChannel, null);
  });

  UserProfile profile(String? pin) => UserProfile(
        id: 'one',
        firstName: 'Alex',
        dateOfBirth: DateTime(1990),
        gender: '',
        favoriteGenres: const [],
        pinHash: pin,
      );

  test('new PINs are salted and verify without exposing the digits', () async {
    final first = await ProfilePin.create('1234');
    final second = await ProfilePin.create('1234');
    expect(first.split(r'$').first, 'pbkdf2-sha256');
    expect(first, isNot(second));
    expect(await ProfilePin.verify(profile(first), '1234'), isTrue);
    expect(await ProfilePin.verify(profile(first), '9999'), isFalse);
    expect(
        await ProfilePin.verify(
            profile('pbkdf2-sha256\$999999999\$x\$y'), '1234'),
        isFalse);
  });

  test('existing PBKDF2 vector works on the Dart fallback', () async {
    expect(await ProfilePin.verify(profile(knownHash), '1234'), isTrue);
    expect(await ProfilePin.verify(profile(knownHash), '0000'), isFalse);
  });

  test('Android uses the native result and falls back only if unsupported',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeChannel, null);
    });
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var calls = 0;
    messenger.setMockMethodCallHandler(nativeChannel, (call) async {
      calls++;
      expect(call.method, 'derive');
      expect(call.arguments['iterations'], 120000);
      expect(call.arguments['pin'], '1234');
      expect(
        call.arguments['salt'],
        Uint8List.fromList(List.generate(16, (i) => i)),
      );
      return Uint8List.fromList(base64Decode(knownHash.split(r'$').last));
    });
    expect(await ProfilePin.verify(profile(knownHash), '1234'), isTrue);
    expect(calls, 1);
    messenger.setMockMethodCallHandler(nativeChannel, (_) async => null);
    expect(await ProfilePin.verify(profile(knownHash), '1234'), isTrue);
    messenger.setMockMethodCallHandler(nativeChannel, (_) async {
      throw PlatformException(code: 'DERIVATION_FAILED');
    });
    await expectLater(
      ProfilePin.verify(profile(knownHash), '1234'),
      throwsA(isA<PlatformException>()),
    );
  });

  test('existing PINs still work and can explicitly be removed', () async {
    final existing = profile('1234');
    expect(await ProfilePin.verify(existing, '1234'), isTrue);
    expect(await ProfilePin.verify(existing, '0000'), isFalse);
    expect(existing.copyWith(firstName: 'Autre').pinHash, '1234');
    expect(existing.copyWith(clearPin: true).pinHash, isNull);
  });

  test('malformed or unsupported PIN hashes never verify', () async {
    for (final hash in [
      'unknown\$120000\$salt\$hash',
      'pbkdf2-sha256\$120000\$%%%\$bad',
      'pbkdf2-sha256\$0\$c2FsdA==\$aGFzaA==',
      'pbkdf2-sha256\$120000\$c2FsdA==\$aGFzaA==',
    ]) {
      expect(await ProfilePin.verify(profile(hash), '1234'), isFalse);
    }
  });

  test('PIN state and legacy key are read without reviving a cleared PIN', () {
    expect(profile(null).hasPin, isFalse);
    expect(profile('  ').hasPin, isFalse);
    expect(profile('hash').hasPin, isTrue);
    final map = profile('hash').toMap();
    expect(UserProfile.fromMap(map).pinHash, 'hash');
    map.remove('pinHash');
    map['pin_hash'] = 'legacy-hash';
    expect(UserProfile.fromMap(map).pinHash, 'legacy-hash');
    map['pinHash'] = null;
    expect(UserProfile.fromMap(map).hasPin, isFalse);
  });
}
