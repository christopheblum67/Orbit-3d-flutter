import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/readme_contact_dialog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    for (final size in [const Size(360, 720), const Size(640, 360)]) {
      testWidgets('contact dialog fits $language at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async => false);
        addTearDown(() => TestDefaultBinaryMessengerBinding
            .instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null));
        await tester.pumpWidget(MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => ReadmeContactDialog(onLegal: () {}),
                      ),
                      child: const Text('Open'),
                    )),
          ),
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(language));
        expect(find.text(l.contactTeamTitle), findsOneWidget);
        expect(find.text(l.contactTeamIntro), findsOneWidget);
        expect(find.text(l.contactTeamWarning), findsOneWidget);
        expect(find.text('alsaceiptv@gmail.com'), findsOneWidget);
        expect(find.text(l.contactMailUnavailable), findsOneWidget);
        expect(find.text(l.contactCompose), findsNothing);
        expect(find.byType(Image), findsOneWidget);
        final dialog = tester.getRect(find.byType(AlertDialog));
        expect(dialog.left, greaterThanOrEqualTo(0));
        expect(dialog.right, lessThanOrEqualTo(size.width));
        expect(dialog.top, greaterThanOrEqualTo(0));
        expect(dialog.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('email opens a composer when available and reports failure',
      (tester) async {
    final calls = <MethodCall>[];
    var launchSucceeds = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'canLaunch' ? true : launchSucceeds;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    var legalOpened = false;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ReadmeContactDialog(
                      onLegal: () => legalOpened = true,
                    ),
                  ),
                  child: const Text('Open'),
                )),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Fermer'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Écrire un e-mail'))).hasFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'launch'), hasLength(1));
    expect(calls.last.arguments['url'], 'mailto:alsaceiptv@gmail.com');
    launchSucceeds = false;
    await tester.tap(find.text('Écrire un e-mail'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune application de messagerie disponible.'),
        findsOneWidget);
    await tester.tap(find.text('Mentions légales'));
    expect(legalOpened, isTrue);
  });
}
