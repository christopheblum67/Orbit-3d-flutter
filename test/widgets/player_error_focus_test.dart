import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/services/connectivity_monitor.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OnlineMonitor extends ConnectivityMonitor {
  int reads = 0;

  @override
  bool get isOnline {
    reads++;
    return true;
  }
}

class _SubtitleController extends SubtitleController {
  @override
  void resetForNewContent() {}
}

void main() {
  testWidgets('player error lets TV select retry instead of opening controls',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['orbit/night_focus', 'orbit/player_config']) {
      messenger.setMockMethodCallHandler(
          MethodChannel(name), (_) async => null);
      addTearDown(
          () => messenger.setMockMethodCallHandler(MethodChannel(name), null));
    }
    final monitor = _OnlineMonitor();
    addTearDown(monitor.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityMonitorProvider.overrideWithValue(monitor),
          subtitleControllerProvider
              .overrideWith((ref) => _SubtitleController()),
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlayerScreen(streamUrl: 'invalid'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Flux indisponible').evaluate().isNotEmpty) break;
    }
    expect(find.text('Flux indisponible'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('Réessayer'))).hasFocus, isTrue);
    final readsBeforeRetry = monitor.reads;
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(monitor.reads, greaterThan(readsBeforeRetry));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
