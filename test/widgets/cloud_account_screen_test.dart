import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_account_screen.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_account_service.dart';

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);
}

class _FakeCredential extends Fake implements UserCredential {}

class _FakeUser extends Fake implements User {
  _FakeUser({required this.isAnonymous, this.linked = false});

  @override
  final bool isAnonymous;
  final bool linked;

  @override
  String? get email => null;
  @override
  List<UserInfo> get providerData => linked ? [_FakeGoogleInfo()] : [];
}

class _FakeGoogleInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';
}

class _FakeAccountService extends CloudAccountService {
  _FakeAccountService() : super(auth: _FakeAuth());

  String? email;
  String? password;
  bool fail = false;
  bool googleConflict = false;
  bool googleCanceled = false;
  int googleCalls = 0;
  User? user;

  @override
  Stream<User?> get authStateChanges => Stream.value(user);

  @override
  Future<UserCredential> signInWithGoogle() async {
    googleCalls++;
    if (googleConflict) {
      throw FirebaseAuthException(code: 'credential-already-in-use');
    }
    if (googleCanceled) {
      throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled);
    }
    return _FakeCredential();
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (fail) throw FirebaseAuthException(code: 'invalid-credential');
    this.email = email;
    this.password = password;
    return _FakeCredential();
  }
}

void main() {
  testWidgets('signs in and reports errors without exposing credentials',
      (tester) async {
    final service = _FakeAccountService();
    await tester.pumpWidget(
      MaterialApp(home: CloudAccountScreen(service: service)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'user@example.test');
    await tester.enterText(find.byType(TextField).last, 'private-password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(service.email, 'user@example.test');
    expect(service.password, 'private-password');
    expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        '');
    service.fail = true;
    await tester.enterText(find.byType(TextField).last, 'private-password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(
        find.text('Adresse e-mail ou mot de passe incorrect.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'private-password',
      ),
      findsNothing,
    );
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue);
  });

  testWidgets('links an anonymous account and explains Google conflicts',
      (tester) async {
    final service = _FakeAccountService()
      ..user = _FakeUser(isAnonymous: true)
      ..googleConflict = true;
    await tester
        .pumpWidget(MaterialApp(home: CloudAccountScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lier un compte Google'));
    await tester.tap(find.text('Lier un compte Google'));
    await tester.pumpAndSettle();
    expect(service.googleCalls, 1);
    expect(find.textContaining('Aucun compte ni donnée n’a été fusionné'),
        findsOneWidget);
  });

  testWidgets('disables linking when Google is already linked', (tester) async {
    final service = _FakeAccountService()
      ..user = _FakeUser(isAnonymous: false, linked: true);
    await tester
        .pumpWidget(MaterialApp(home: CloudAccountScreen(service: service)));
    await tester.pumpAndSettle();
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Compte Google déjà lié'),
    );
    expect(button.onPressed, isNull);
    expect(service.googleCalls, 0);
  });

  testWidgets('shows an actionable Google cancellation message',
      (tester) async {
    final service = _FakeAccountService()..googleCanceled = true;
    await tester
        .pumpWidget(MaterialApp(home: CloudAccountScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Se connecter avec Google'));
    await tester.tap(find.text('Se connecter avec Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connexion Google annulée ou impossible'),
        findsOneWidget);
  });
}
