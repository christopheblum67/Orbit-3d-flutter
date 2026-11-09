import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/delayed_playback_loading.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

void main() {
  Widget app({required VoidCallback onRetry}) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DelayedPlaybackLoading(
          delay: const Duration(seconds: 45),
          onRetry: onRetry,
          initialChild: const Text('Chargement'),
        ),
      ),
    );
  }

  testWidgets('offers retry only after the loading deadline', (tester) async {
    var retries = 0;
    await tester.pumpWidget(app(onRetry: () => retries++));
    await tester.pump(const Duration(seconds: 44));
    expect(find.text('Chargement'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('La lecture prend du temps'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    expect(retries, 1);
  });

  testWidgets('waiting restarts the delay without retrying', (tester) async {
    var retries = 0;
    await tester.pumpWidget(app(onRetry: () => retries++));
    await tester.pump(const Duration(seconds: 45));
    await tester.tap(find.text('Continuer à attendre'));
    await tester.pump();
    expect(find.text('Chargement'), findsOneWidget);
    expect(retries, 0);
    await tester.pump(const Duration(seconds: 45));
    expect(find.text('La lecture prend du temps'), findsOneWidget);
  });

  testWidgets('retry is focused and works with the TV select key',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(app(onRetry: () => retries++));
    await tester.pump(const Duration(seconds: 45));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('dismissal cancels the pending timer', (tester) async {
    await tester.pumpWidget(app(onRetry: () {}));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 45));
    expect(tester.takeException(), isNull);
  });
}
