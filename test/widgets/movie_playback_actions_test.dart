import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/vod/widgets/movie_playback_actions.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

void main() {
  Widget app({
    required VoidCallback onStart,
    VoidCallback? onResume,
    VoidCallback? onTrailer,
  }) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MoviePlaybackActions(
          onStart: onStart,
          onResume: onResume,
          onTrailer: onTrailer,
        ),
      ),
    );
  }

  testWidgets('TV actions share a row and are navigable by remote',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var started = 0;
    var resumed = 0;
    var trailers = 0;
    await tester.pumpWidget(app(
      onStart: () => started++,
      onResume: () => resumed++,
      onTrailer: () => trailers++,
    ));
    await tester.pumpAndSettle();
    final buttons = find.byType(FilledButton);
    final start = tester.getRect(buttons.first);
    final resume = tester.getRect(buttons.last);
    final trailer = tester.getRect(buttons.last);
    expect(tester.widgetList<FilledButton>(buttons).length, 3);
    expect(tester.getSize(buttons.first).height, closeTo(48, 1));
    expect(resume.width, greaterThanOrEqualTo(165));
    expect(start.center.dy, closeTo(resume.center.dy, 1));
    expect(resume.center.dy, closeTo(trailer.center.dy, 1));
    final row = find.descendant(
      of: find.byType(MoviePlaybackActions),
      matching: find.byType(Wrap),
    );
    expect(tester.getRect(row).center.dx, closeTo(640, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(started, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(resumed, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(trailers, 1);
  });

  testWidgets('mobile actions fit and resume is disabled without progress',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(onStart: () {}));
    await tester.pumpAndSettle();
    final resume = tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(resume.onPressed, isNull);
    expect(tester.takeException(), isNull);
    expect(find.text('Reprendre'), findsOneWidget);
  });
}
