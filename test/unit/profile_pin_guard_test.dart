import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/profile_pin_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  UserProfile profile(String id) => UserProfile(
        id: id,
        firstName: id,
        dateOfBirth: DateTime(1990),
        gender: '',
        favoriteGenres: const [],
        pinHash: '1234',
      );

  test('three failures lock only the affected profile for two hours', () async {
    var now = DateTime(2026, 1, 1, 12);
    final guard = ProfilePinGuard(clock: () => now);
    final first = profile('first');
    final second = profile('second');
    expect((await guard.verify(first, '0000')).remainingAttempts, 2);
    expect((await guard.verify(first, '0000')).remainingAttempts, 1);
    final locked = await guard.verify(first, '0000');
    expect(locked.lockedUntil, now.add(const Duration(hours: 2)));
    expect((await guard.verify(first, '1234')).verified, isFalse);
    expect((await guard.verify(second, '1234')).verified, isTrue);
    final reopened = ProfilePinGuard(clock: () => now);
    expect((await reopened.status(first.id)).lockedUntil, locked.lockedUntil);
    now = now.add(const Duration(hours: 2) - const Duration(seconds: 1));
    expect((await reopened.verify(first, '1234')).verified, isFalse);
    now = now.add(const Duration(seconds: 1));
    expect((await reopened.verify(first, '1234')).verified, isTrue);
    expect((await reopened.status(first.id)).remainingAttempts, 3);
  });

  test('successful verification and explicit removal reset failed attempts',
      () async {
    final guard = ProfilePinGuard();
    final user = profile('one');
    await guard.verify(user, '0000');
    expect((await guard.verify(user, '1234')).verified, isTrue);
    expect((await guard.verify(user, '0000')).remainingAttempts, 2);
    await guard.clear(user.id);
    expect((await guard.status(user.id)).remainingAttempts, 3);
  });

  test('concurrent attempts cannot bypass the lock', () async {
    final guard = ProfilePinGuard();
    final user = profile('one');
    final attempts = await Future.wait([
      guard.verify(user, '0000'),
      guard.verify(user, '0000'),
      guard.verify(user, '0000'),
      guard.verify(user, '1234'),
    ]);
    expect(attempts[2].lockedUntil, isNotNull);
    expect(attempts[3].verified, isFalse);
  });

  test('PIN changes are blocked until every targeted lock expires', () async {
    var now = DateTime(2026, 1, 1);
    final guard = ProfilePinGuard(clock: () => now);
    final locked = profile('locked');
    final other = profile('other');
    for (var i = 0; i < 3; i++) {
      await guard.verify(locked, '0000');
    }
    var changes = 0;
    Future<void> change() async => changes++;
    await expectLater(
      guard.withUnlockedProfiles(() async => [other.id, locked.id], change),
      throwsA(isA<ProfilePinLockedException>()),
    );
    await expectLater(guard.clear(locked.id),
        throwsA(isA<ProfilePinLockedException>()));
    expect(changes, 0);
    await guard.withUnlockedProfiles(() async => [other.id], change);
    expect(changes, 1);
    now = now.add(const Duration(hours: 2));
    await guard.withUnlockedProfiles(() async => [locked.id], change);
    await guard.clear(locked.id);
    expect(changes, 2);
  });
}
