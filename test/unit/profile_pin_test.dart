import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/profile_pin.dart';

void main() {
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

  test('existing PINs still work and can explicitly be removed', () async {
    final existing = profile('1234');
    expect(await ProfilePin.verify(existing, '1234'), isTrue);
    expect(await ProfilePin.verify(existing, '0000'), isFalse);
    expect(existing.copyWith(firstName: 'Autre').pinHash, '1234');
    expect(existing.copyWith(clearPin: true).pinHash, isNull);
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
