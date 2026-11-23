import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_account_screen.dart';
import 'package:orbit_3d_flutter/features/settings/tv_pairing_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_account_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';

class _TestApp extends MaterialApp {
  _TestApp({
    super.key,
    required super.home,
    super.navigatorObservers = const <NavigatorObserver>[],
    Locale locale = const Locale('fr'),
  }) : super(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
}

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

class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) pushes++;
  }
}

void main() {
  Future<bool> notTv() async => false;

  testWidgets('TV pairing explains the verification step in English',
      (tester) async {
    await tester.pumpWidget(_TestApp(
      locale: const Locale('en'),
      home: const TvPairingScreen(),
    ));
    expect(find.text('Link this TV'), findsOneWidget);
    expect(find.textContaining('Compare the displayed codes'), findsOneWidget);
    expect(find.text('Create a QR code'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('offers the experimental TV pairing screen only when enabled',
      (tester) async {
    final service = _FakeAccountService();
    await tester.pumpWidget(_TestApp(
        home: CloudAccountScreen(service: service, tvDetector: notTv)));
    await tester.pumpAndSettle();
    final button = find.text('Associer cette TV par QR code');
    if (qrPairingAvailable) {
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Créer un QR code'), findsOneWidget);
    } else {
      expect(button, findsNothing);
    }
  });

  testWidgets('cloud synchronization help is inside the account screen',
      (tester) async {
    await tester.pumpWidget(_TestApp(
      home:
          CloudAccountScreen(service: _FakeAccountService(), tvDetector: notTv),
    ));
    await tester.pumpAndSettle();
    final help = find
        .text(lookupAppLocalizations(const Locale('fr')).cloudSyncProfileHelp);
    await tester.scrollUntilVisible(help, 250,
        scrollable: find.byType(Scrollable).first);
    expect(help, findsOneWidget);
  });

  testWidgets('TV hides Google options and opens QR pairing with the remote',
      (tester) async {
    if (!qrPairingAvailable) return;
    final service = _FakeAccountService();
    final detection = Completer<bool>();
    await tester.pumpWidget(_TestApp(
      home: CloudAccountScreen(
          service: service, tvDetector: () => detection.future),
    ));
    expect(find.text('Se connecter avec Google'), findsNothing);
    detection.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Se connecter avec Google'), findsNothing);
    expect(find.textContaining('Google lui sera lié'), findsNothing);
    final button = find.text('Associer cette TV par QR code');
    expect(button, findsOneWidget);
    expect(Focus.of(tester.element(button)).hasPrimaryFocus, isTrue);
    final qrButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Associer cette TV par QR code'),
    );
    expect(
      qrButton.style!.backgroundColor!.resolve({WidgetState.focused}),
      const Color(0xFFFFC107),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    final createButton = find.text('Créer un QR code');
    expect(createButton, findsOneWidget);
    expect(Focus.of(tester.element(createButton)).hasPrimaryFocus, isTrue);
  });

  testWidgets('TV can move up from the email field to the pairing button',
      (tester) async {
    if (!qrPairingAvailable) return;
    await tester.pumpWidget(_TestApp(
      home: CloudAccountScreen(
        service: _FakeAccountService(),
        tvDetector: () async => true,
      ),
    ));
    await tester.pumpAndSettle();

    final pairingButton = find.text('Associer cette TV par QR code');
    final emailField = find.byType(TextField).first;
    await tester.ensureVisible(emailField);
    await tester.tap(emailField);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(pairingButton)).hasPrimaryFocus, isTrue);
  });

  testWidgets(
      'TV hides Google linking for connected accounts when QR is enabled',
      (tester) async {
    if (!qrPairingAvailable) return;
    for (final user in [
      _FakeUser(isAnonymous: true),
      _FakeUser(isAnonymous: false, linked: true),
    ]) {
      final service = _FakeAccountService()..user = user;
      await tester.pumpWidget(_TestApp(
        key: UniqueKey(),
        home:
            CloudAccountScreen(service: service, tvDetector: () async => true),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Lier un compte Google'), findsNothing);
      expect(find.text('Compte Google déjà lié'), findsNothing);
    }
  });

  testWidgets('TV focuses and opens encrypted sync with the remote',
      (tester) async {
    final service = _FakeAccountService()..user = _FakeUser(isAnonymous: false);
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(_TestApp(
      navigatorObservers: [observer],
      home: CloudAccountScreen(service: service, tvDetector: () async => true),
    ));
    await tester.pumpAndSettle();
    final button = find.text('Retrouver mes profils sur mes appareils');
    expect(Focus.of(tester.element(button)).hasPrimaryFocus, isTrue);
    final syncButton = tester.widget<TextButton>(
      find.widgetWithText(
          TextButton, 'Retrouver mes profils sur mes appareils'),
    );
    expect(syncButton.style!.backgroundColor!.resolve({WidgetState.focused}),
        const Color(0xFFFFC107));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(observer.pushes, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Google remains available on TV when QR is disabled',
      (tester) async {
    if (qrPairingAvailable) return;
    await tester.pumpWidget(_TestApp(
      home: CloudAccountScreen(
        service: _FakeAccountService(),
        tvDetector: () async => true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter avec Google'), findsOneWidget);
    expect(find.text('Associer cette TV par QR code'), findsNothing);
  });

  testWidgets('signs in and reports errors without exposing credentials',
      (tester) async {
    final service = _FakeAccountService();
    await tester.pumpWidget(
      _TestApp(home: CloudAccountScreen(service: service, tvDetector: notTv)),
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
    await tester.pumpWidget(_TestApp(
        home: CloudAccountScreen(service: service, tvDetector: notTv)));
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
    await tester.pumpWidget(_TestApp(
        home: CloudAccountScreen(service: service, tvDetector: notTv)));
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
    await tester.pumpWidget(_TestApp(
        home: CloudAccountScreen(service: service, tvDetector: notTv)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Se connecter avec Google'));
    await tester.tap(find.text('Se connecter avec Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connexion Google annulée ou impossible'),
        findsOneWidget);
  });

  testWidgets('explains account-link conflicts in English', (tester) async {
    final service = _FakeAccountService()
      ..user = _FakeUser(isAnonymous: true)
      ..googleConflict = true;
    await tester.pumpWidget(_TestApp(
      locale: const Locale('en'),
      home: CloudAccountScreen(service: service, tvDetector: notTv),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Cloud account'), findsOneWidget);
    await tester.ensureVisible(find.text('Link a Google account'));
    await tester.tap(find.text('Link a Google account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No accounts or data were merged.'),
        findsOneWidget);
    expect(find.textContaining('sign out and then sign in with Google'),
        findsOneWidget);
  });
}
