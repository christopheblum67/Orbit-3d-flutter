import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_monitoring_overlay.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/connectivity_monitor.dart';

class _OfflineMonitor extends ConnectivityMonitor {
  @override
  bool get isOnline => false;
}

void main() {
  testWidgets('network overlay focuses retry and accepts select', (tester) async {
    final monitor = _OfflineMonitor();
    addTearDown(monitor.dispose);
    var retries = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectivityMonitorProvider.overrideWithValue(monitor)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                PlayerMonitoringOverlay(onRetry: () => retries++),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Réessayer'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(retries, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
