import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/profile_pin.dart';

class ProfilePinAttempt {
  const ProfilePinAttempt({
    this.verified = false,
    this.remainingAttempts = 3,
    this.lockedUntil,
  });

  final bool verified;
  final int remainingAttempts;
  final DateTime? lockedUntil;
}

class ProfilePinLockedException implements Exception {
  const ProfilePinLockedException();
}

final profilePinGuardProvider = Provider<ProfilePinGuard>(
  (ref) => ProfilePinGuard(),
);

class ProfilePinGuard {
  ProfilePinGuard({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const maxAttempts = 3;
  static const lockDuration = Duration(hours: 2);
  final DateTime Function() _clock;
  Future<void> _pending = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  String _key(String profileId) => 'profile_pin_attempts_$profileId';

  ProfilePinAttempt _read(SharedPreferences prefs, String profileId) {
    final saved = prefs.getString(_key(profileId));
    if (saved == null) return const ProfilePinAttempt();
    final json = jsonDecode(saved);
    if (json is! Map ||
        json['failures'] is! int ||
        (json['lockedUntil'] != null && json['lockedUntil'] is! int)) {
      throw const FormatException('Invalid profile PIN attempt state');
    }

    final failures = json['failures'] as int;
    if (failures < 0 || failures > maxAttempts) {
      throw const FormatException('Invalid profile PIN attempt count');
    }
    final timestamp = json['lockedUntil'] as int?;
    if ((failures == maxAttempts) != (timestamp != null)) {
      throw const FormatException('Invalid profile PIN lock state');
    }
    final lockedUntil = timestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (lockedUntil != null && !_clock().isBefore(lockedUntil)) {
      return const ProfilePinAttempt();
    }
    return ProfilePinAttempt(
      remainingAttempts: maxAttempts - failures,
      lockedUntil: lockedUntil,
    );
  }

  Future<ProfilePinAttempt> status(String profileId) => _synchronized(() async {
        final prefs = await SharedPreferences.getInstance();
        return _read(prefs, profileId);
      });

  Future<T> withUnlockedProfiles<T>(
    Future<Iterable<String>> Function() profileIds,
    Future<T> Function() action,
  ) =>
      _synchronized(() async {
        final prefs = await SharedPreferences.getInstance();
        for (final id in await profileIds()) {
          if (_read(prefs, id).lockedUntil != null) {
            throw const ProfilePinLockedException();
          }
        }
        return action();
      });

  Future<void> clear(String profileId) => _synchronized(() async {
        final prefs = await SharedPreferences.getInstance();
        if (_read(prefs, profileId).lockedUntil != null) {
          throw const ProfilePinLockedException();
        }
        if (!await prefs.remove(_key(profileId))) {
          throw StateError('Could not clear profile PIN attempts');
        }
      });

  Future<ProfilePinAttempt> verify(UserProfile profile, String pin) =>
      _synchronized(() async {
        final prefs = await SharedPreferences.getInstance();
        final current = _read(prefs, profile.id);
        if (current.lockedUntil != null) return current;
        if (await ProfilePin.verify(profile, pin)) {
          if (!await prefs.remove(_key(profile.id))) {
            throw StateError('Could not clear profile PIN attempts');
          }
          return const ProfilePinAttempt(verified: true);
        }
        final failures = maxAttempts - current.remainingAttempts + 1;
        final until =
            failures == maxAttempts ? _clock().add(lockDuration) : null;
        final saved = await prefs.setString(
          _key(profile.id),
          jsonEncode({
            'failures': failures,
            'lockedUntil': until?.millisecondsSinceEpoch,
          }),
        );
        if (!saved) throw StateError('Could not save profile PIN attempts');
        return ProfilePinAttempt(
          remainingAttempts: maxAttempts - failures,
          lockedUntil: until,
        );
      });
}
