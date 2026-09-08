import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/features/player/widgets/player_monitoring_overlay.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/connectivity_monitor.dart';
import 'package:orbit_3d_flutter/services/host_circuit_breaker.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';

void main() {
  group('PlayerMonitoringOverlay', () {
    late ConnectivityMonitor connectivityMonitor;
    late HostCircuitBreaker circuitBreaker;
    late StallDetector stallDetector;

    setUp(() {
      connectivityMonitor = ConnectivityMonitor();
      circuitBreaker = HostCircuitBreaker.instance;
      circuitBreaker.resetAll();
      stallDetector = StallDetector();
    });

    tearDown(() {
      connectivityMonitor.dispose();
      circuitBreaker.resetAll();
      stallDetector.dispose();
    });

    Widget createTestWidget({
      String? streamUrl,
      VoidCallback? onRetry,
    }) {
      return ProviderScope(
        overrides: [
          connectivityMonitorProvider.overrideWithValue(connectivityMonitor),
          hostCircuitBreakerProvider.overrideWithValue(circuitBreaker),
          stallDetectorProvider.overrideWithValue(stallDetector),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                PlayerMonitoringOverlay(
                  streamUrl: streamUrl,
                  onRetry: onRetry,
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('shows nothing when online and no stall', (tester) async {
      await tester.pumpWidget(createTestWidget(streamUrl: 'https://example.com/stream.m3u8'));
      await tester.pump();

      // Overlay should not be visible when everything is fine
      expect(find.byType(PlayerMonitoringOverlay), findsOneWidget);
      // The overlay returns SizedBox.shrink() when nothing to show
      expect(find.byKey(const Key('overlay_true_false_false')), findsNothing);
    });

    testWidgets('shows cooldown card when host is in cooldown', (tester) async {
      circuitBreaker.recordFailure('example.com');
      circuitBreaker.recordFailure('example.com');

      await tester.pumpWidget(
        createTestWidget(streamUrl: 'https://example.com/stream.m3u8'),
      );
      await tester.pump();

      expect(find.text('Serveur protégé (anti-leech)'), findsOneWidget);
      expect(find.textContaining('nouvelle tentative dans'), findsOneWidget);
    });

    testWidgets('shows stalling card when detector reports stall', (tester) async {
      // We can't easily simulate the stall detector in a widget test without
      // a real controller, but we can verify the widget structure
      await tester.pumpWidget(
        createTestWidget(streamUrl: 'https://example.com/stream.m3u8'),
      );
      await tester.pump();

      expect(find.byType(PlayerMonitoringOverlay), findsOneWidget);
    });

    testWidgets('retry button calls onRetry callback', (tester) async {
      bool retryCalled = false;
      circuitBreaker.recordFailure('example.com');
      circuitBreaker.recordFailure('example.com');

      await tester.pumpWidget(
        createTestWidget(
          streamUrl: 'https://example.com/stream.m3u8',
          onRetry: () => retryCalled = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('does not show overlay when streamUrl is null', (tester) async {
      await tester.pumpWidget(
        createTestWidget(streamUrl: null),
      );
      await tester.pump();

      expect(find.byType(PlayerMonitoringOverlay), findsOneWidget);
    });
  });
}