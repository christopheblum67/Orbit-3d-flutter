import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_account_service.dart';

class _FakeCredential extends Fake implements UserCredential {}

class _FakeUserInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';
}

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid, {this.isAnonymous = false, this.linked = false});

  @override
  final String uid;
  @override
  final bool isAnonymous;
  final bool linked;
  int linkCalls = 0;
  FirebaseAuthException? linkError;

  @override
  List<UserInfo> get providerData => linked ? [_FakeUserInfo()] : [];

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    linkCalls++;
    expect(credential.providerId, 'google.com');
    if (linkError != null) throw linkError!;
    return _FakeCredential();
  }
}

class _FakeAuth extends Fake implements FirebaseAuth {
  String? email;
  String? password;
  String? action;
  User? user;
  int googleSignInCalls = 0;

  @override
  User? get currentUser => user;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    googleSignInCalls++;
    expect(credential.providerId, 'google.com');
    return _FakeCredential();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    this.email = email;
    this.password = password;
    action = 'signIn';
    return _FakeCredential();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    this.email = email;
    this.password = password;
    action = 'register';
    return _FakeCredential();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    this.email = email;
    action = 'reset';
  }
}

void main() {
  test('email account operations use Firebase and preserve the password',
      () async {
    final auth = _FakeAuth();
    final service = CloudAccountService(auth: auth);
    await service.registerWithEmail(' user@example.test ', ' password ');
    expect(auth.action, 'register');
    expect(auth.email, 'user@example.test');
    expect(auth.password, ' password ');
    await service.signInWithEmail(' user@example.test ', ' password ');
    expect(auth.action, 'signIn');
    expect(auth.password, ' password ');
    await service.sendPasswordReset(' user@example.test ');
    expect(auth.action, 'reset');
    expect(auth.email, 'user@example.test');
  });

  test('Google signs in only when there is no existing account', () async {
    final auth = _FakeAuth();
    final service =
        CloudAccountService(auth: auth, googleIdToken: () async => 'token');
    await service.signInWithGoogle();
    expect(auth.googleSignInCalls, 1);
  });

  for (final anonymous in [true, false]) {
    test('Google links existing ${anonymous ? 'anonymous' : 'email'} account',
        () async {
      final user = _FakeUser('existing-uid', isAnonymous: anonymous);
      final auth = _FakeAuth()..user = user;
      final service =
          CloudAccountService(auth: auth, googleIdToken: () async => 'token');
      await service.signInWithGoogle();
      expect(user.linkCalls, 1);
      expect(auth.googleSignInCalls, 0);
      expect(auth.currentUser!.uid, 'existing-uid');
    });
  }

  test('Google conflict never switches accounts automatically', () async {
    final user = _FakeUser('existing-uid')
      ..linkError = FirebaseAuthException(code: 'credential-already-in-use');
    final auth = _FakeAuth()..user = user;
    final service =
        CloudAccountService(auth: auth, googleIdToken: () async => 'token');
    await expectLater(
        service.signInWithGoogle(), throwsA(isA<FirebaseAuthException>()));
    expect(user.linkCalls, 1);
    expect(auth.googleSignInCalls, 0);
    expect(auth.currentUser!.uid, 'existing-uid');
  });

  test('already linked Google account does not start Google sign-in', () async {
    final auth = _FakeAuth()..user = _FakeUser('existing-uid', linked: true);
    var started = false;
    final service = CloudAccountService(
        auth: auth,
        googleIdToken: () async {
          started = true;
          return 'token';
        });
    await expectLater(
      service.signInWithGoogle(),
      throwsA(isA<FirebaseAuthException>().having(
        (error) => error.code,
        'code',
        'provider-already-linked',
      )),
    );
    expect(started, isFalse);
    expect(auth.googleSignInCalls, 0);
  });

  test('account changes or missing Google token abort without linking',
      () async {
    final original = _FakeUser('original');
    final auth = _FakeAuth()..user = original;
    final service = CloudAccountService(
        auth: auth,
        googleIdToken: () async {
          auth.user = _FakeUser('other');
          return 'token';
        });
    await expectLater(service.signInWithGoogle(), throwsStateError);
    expect(original.linkCalls, 0);
    expect(auth.googleSignInCalls, 0);

    final emptyTokenService =
        CloudAccountService(auth: auth, googleIdToken: () async => '');
    await expectLater(emptyTokenService.signInWithGoogle(), throwsStateError);
    expect((auth.user! as _FakeUser).linkCalls, 0);
  });
}
