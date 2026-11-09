import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_primary_button.dart';
import 'package:orbit_3d_flutter/features/vod/widgets/movie_playback_actions.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

void main() {
  Widget app({required VoidCallback onStart, VoidCallback? onResume}) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MoviePlaybackActions(onStart: onStart, onResume: onResume),
      ),
    );
  }

  testWidgets('TV actions are centered, large and navigable by remote',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var started = 0;
    var resumed = 0;
    await tester.pumpWidget(app(
      onStart: () => started++,
      onResume: () => resumed++,
    ));
    await tester.pumpAndSettle();
    final buttons = find.byType(FilledButton);
    final start = tester.getRect(buttons.first);
    final resume = tester.getRect(buttons.last);
    expect(start.width, greaterThanOrEqualTo(220));
    expect(start.height, greaterThanOrEqualTo(64));
    expect(resume.width, greaterThanOrEqualTo(220));
    final layoutStart = tester.getRect(find.byType(TvPrimaryButton).first);
    final layoutResume = tester.getRect(find.byType(TvPrimaryButton).last);
    expect((layoutStart.left + layoutResume.right) / 2, closeTo(640, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(started, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(resumed, 1);
  });

  testWidgets('mobile actions fit and resume is disabled without progress',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(onStart: () {}));
    await tester.pumpAndSettle();
    final resume = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(resume.onPressed, isNull);
    expect(tester.takeException(), isNull);
    expect(find.text('Reprendre'), findsOneWidget);
  });
}
