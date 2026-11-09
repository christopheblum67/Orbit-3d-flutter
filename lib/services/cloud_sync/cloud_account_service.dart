import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase account operations, independent of the legacy cloud sync.
class CloudAccountService {
  CloudAccountService({
    FirebaseAuth? auth,
    Future<String> Function()? googleIdToken,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleIdToken = googleIdToken ?? _authenticateGoogle;

  final FirebaseAuth _auth;
  final Future<String> Function() _googleIdToken;
  static Future<void>? _googleInitialization;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> signInWithGoogle() async {
    final user = _auth.currentUser;
    if (user != null &&
        user.providerData
            .any((provider) => provider.providerId == 'google.com')) {
      throw FirebaseAuthException(code: 'provider-already-linked');
    }
    final idToken = await _googleIdToken();
    if (idToken.isEmpty) {
      throw StateError('Google n’a pas fourni de jeton d’identité.');
    }
    if (_auth.currentUser?.uid != user?.uid) {
      throw StateError('Le compte a changé pendant la connexion.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    if (user != null) {
      return user.linkWithCredential(credential);
    }
    return _auth.signInWithCredential(credential);
  }

  static Future<String> _authenticateGoogle() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'La connexion Google est uniquement configurée pour Android.',
      );
    }
    final google = GoogleSignIn.instance;
    try {
      await (_googleInitialization ??= google.initialize());
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
    if (!google.supportsAuthenticate()) {
      throw UnsupportedError(
        'La connexion Google n’est pas disponible sur cet appareil.',
      );
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google n’a pas fourni de jeton d’identité.');
    }
    return idToken;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialization != null) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
