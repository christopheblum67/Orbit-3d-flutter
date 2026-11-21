import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/subscriptions/widgets/connection_error_dialog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';

void main() {
  group('ConnectionErrorAnalyzer', () {
    test('explains rejected Xtream credentials', () {
      final result = ConnectionErrorAnalyzer.analyze(
        'DioException: status code 401 Unauthorized',
        type: SubscriptionType.xtream,
        l: AppLocalizationsFr(),
      );

      expect(result.category, ConnectionErrorCategory.invalidCredentials);
      expect(result.title, 'Identifiants invalides');
      expect(result.suggestions, isNotEmpty);
    });

    test('recognizes a timeout', () {
      final result = ConnectionErrorAnalyzer.analyze(
        'Connection timed out',
        type: SubscriptionType.m3u,
        l: AppLocalizationsFr(),
      );

      expect(result.category, ConnectionErrorCategory.timeout);
      expect(result.title, 'Délai de réponse dépassé');
    });

    test('redacts credentials from technical details', () {
      final result = ConnectionErrorAnalyzer.analyze(
        'GET https://panel.example/player_api.php?username=alice&password=secret',
        type: SubscriptionType.xtream,
        l: AppLocalizationsFr(),
      );

      expect(result.technicalDetails, contains('username=[masqué]'));
      expect(result.technicalDetails, isNot(contains('alice')));
      expect(result.technicalDetails, isNot(contains('secret')));
    });
  });

  testWidgets('shows an actionable error dialog with retry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showConnectionErrorDialog(
                  context,
                  'DioException: status code 401 Unauthorized',
                  type: SubscriptionType.xtream,
                  onRetry: () => retries++,
                ),
                child: const Text('Tester'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tester'));
    await tester.pumpAndSettle();

    expect(find.text('Identifiants invalides'), findsOneWidget);
    expect(find.text('À vérifier'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('Réessayer'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Fermer'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Réessayer'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(retries, 1);
    expect(find.text('Identifiants invalides'), findsNothing);
  });

  testWidgets('focuses close when retry is unavailable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showConnectionErrorDialog(
                  context,
                  'timeout',
                  type: SubscriptionType.m3u,
                ),
                child: const Text('Tester'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tester'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Fermer'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Délai de réponse dépassé'), findsNothing);
  });

  testWidgets('localizes the connection diagnosis and actions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showConnectionErrorDialog(
              context,
              'HTTP 503',
              type: SubscriptionType.m3u,
              onRetry: () {},
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Server temporarily unavailable (503)'), findsOneWidget);
    expect(find.text('Things to check'), findsOneWidget);
    expect(find.text('Try again in a few minutes.'), findsOneWidget);
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
