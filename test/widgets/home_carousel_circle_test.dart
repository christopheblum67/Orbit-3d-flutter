import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/home/home_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('carousel circles navigate with the remote', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/vod', builder: (_, __) => const Text('VOD ouverte')),
    ]);
    addTearDown(router.dispose);
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tvModeNotifierProvider.overrideWith((ref) => tvMode),
        sourceTypeProvider.overrideWith((ref) async => 'xtream'),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        activeSubscriptionProvider.overrideWith((ref) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        lastRefreshTimestampProvider.overrideWithBuild(
          (ref, notifier) => DateTime.now(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    Finder circleFor(String route) => find.descendant(
          of: find.byKey(ValueKey(route)),
          matching: find.byWidgetPredicate((widget) =>
              widget is AnimatedContainer &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle),
        );
    BoxDecoration circleDecoration(String route) =>
        tester.widget<AnimatedContainer>(circleFor(route)).decoration!
            as BoxDecoration;

    expect(
      find.byWidgetPredicate((widget) =>
          widget is AnimatedContainer &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle),
      findsWidgets,
    );
    expect(circleDecoration('/live').boxShadow, isNotEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('/vod'));
    expect(tester.widget<TvFocus>(tile).enableTvEffects, isFalse);
    final decoration = circleDecoration('/vod');
    expect(circleDecoration('/live').boxShadow, isEmpty);
    expect(decoration.boxShadow, isNotEmpty);
    final node = tester.widget<TvFocus>(tile).focusNode!;
    node.unfocus();
    await tester.pumpAndSettle();
    expect(circleDecoration('/vod').boxShadow, isEmpty);
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(circleDecoration('/vod').boxShadow, isNotEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('VOD ouverte'), findsOneWidget);
  });
}
