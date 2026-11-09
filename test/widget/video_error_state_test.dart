import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/video_error_state.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';

void main() {
  testWidgets('blocking playback error takes focus and supports D-pad actions',
      (tester) async {
    var retries = 0;
    var websiteOpened = 0;
    var waiting = 0;
    final previousFocus = FocusNode();
    addTearDown(previousFocus.dispose);
    final l = AppLocalizationsFr();
    Widget app(bool showError) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: showError
                ? VideoErrorState(
                    autoFocusRetry: true,
                    onRetry: () => retries++,
                    onContinueWaiting: () => waiting++,
                    onProviderWebsite: () => websiteOpened++,
                  )
                : TextButton(
                    focusNode: previousFocus,
                    autofocus: true,
                    onPressed: () {},
                    child: const Text('Previous'),
                  ),
          ),
        );
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();
    expect(previousFocus.hasFocus, isTrue);
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text(l.retry))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(retries, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
        Focus.of(tester.element(find.text(l.playbackContinueWaiting))).hasFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(waiting, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text(l.openProviderWebsite))).hasFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(websiteOpened, 1);
  });

  testWidgets('provider website action is explicit and user-triggered',
      (tester) async {
    var opened = false;
    final l = AppLocalizationsFr();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VideoErrorState(
            title: l.cloudflareCheckRequired,
            message: l.cloudflareChallengeHelp,
            onProviderWebsite: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text(l.openProviderWebsite), findsOneWidget);
    expect(find.text(l.cloudflareChallengeHelp), findsOneWidget);
    expect(opened, isFalse);

    await tester.tap(find.text(l.openProviderWebsite));
    expect(opened, isTrue);
  });

  testWidgets('provider actions remain reachable on a short screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var opened = false;
    final l = AppLocalizationsFr();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VideoErrorState(
            title: l.cloudflareCheckRequired,
            message: l.cloudflareChallengeHelp,
            autoFocusRetry: true,
            onRetry: () {},
            onProviderWebsite: () => opened = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(Focus.of(tester.element(find.text(l.retry))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text(l.openProviderWebsite))).hasFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(opened, isTrue);
  });
}
