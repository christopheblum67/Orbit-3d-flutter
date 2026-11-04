import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/subscriptions/widgets/connection_error_dialog.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';

void main() {
  group('ConnectionErrorAnalyzer', () {
    test('explains rejected Xtream credentials', () {
      final result = ConnectionErrorAnalyzer.analyze(
        'DioException: status code 401 Unauthorized',
        type: SubscriptionType.xtream,
      );

      expect(result.category, ConnectionErrorCategory.invalidCredentials);
      expect(result.title, 'Identifiants invalides');
      expect(result.suggestions, isNotEmpty);
    });

    test('recognizes a timeout', () {
      final result = ConnectionErrorAnalyzer.analyze(
        'Connection timed out',
        type: SubscriptionType.m3u,
      );

      expect(result.category, ConnectionErrorCategory.timeout);
      expect(result.title, 'Délai de réponse dépassé');
    });

    test('redacts credentials from technical details', () {
      final result = ConnectionErrorAnalyzer.analyze(
        'GET https://panel.example/player_api.php?username=alice&password=secret',
        type: SubscriptionType.xtream,
      );

      expect(result.technicalDetails, contains('username=[masqué]'));
      expect(result.technicalDetails, isNot(contains('alice')));
      expect(result.technicalDetails, isNot(contains('secret')));
    });
  });

  testWidgets('shows an actionable error dialog with retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showConnectionErrorDialog(
                  context,
                  'DioException: status code 401 Unauthorized',
                  type: SubscriptionType.xtream,
                  onRetry: () {},
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
  });
}
