import 'dart:async';

import 'package:cast/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/cast_button.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/cast_provider.dart';
import 'package:orbit_3d_flutter/services/cast_playback_service.dart';

class _FakeCastService extends CastPlaybackService {
  final scan = Completer<List<CastDevice>>();
  final messages = StreamController<CastPlaybackMessage>.broadcast();

  @override
  Stream<CastPlaybackMessage> get messageStream => messages.stream;

  @override
  void dispose() {
    messages.close();
    super.dispose();
  }

  @override
  Future<List<CastDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 5),
  }) =>
      scan.future;
}

void main() {
  testWidgets('cast discovery is localized', (tester) async {
    final service = _FakeCastService();
    addTearDown(service.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [castServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CastButton(streamUrl: '', isLive: false)),
      ),
    ));
    await tester.tap(find.byType(CastButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Searching for Cast devices…'), findsOneWidget);
    service.scan.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No Chromecast device found.'), findsOneWidget);
  });

  testWidgets('cast receiver status is localized without changing its messages',
      (tester) async {
    final service = _FakeCastService();
    addTearDown(service.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [castServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CastButton(streamUrl: '', isLive: false)),
      ),
    ));
    await tester.tap(find.byType(CastButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    service.scan.complete([]);
    await tester.pumpAndSettle();
    service.messages.add(const CastReceiverNotReady());
    await tester.pumpAndSettle();
    expect(find.text('Receiver is not ready yet'), findsOneWidget);
    service.messages.add(const CastReceiverMessage('Receiver message'));
    await tester.pumpAndSettle();
    expect(find.text('Receiver message'), findsOneWidget);
  });
}
