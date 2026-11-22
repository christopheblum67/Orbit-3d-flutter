import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/replay/replay_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';

void main() {
  testWidgets('jours anciens accessibles et jour récent visible au départ',
      (tester) async {
    tester.view.physicalSize = const Size(600, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = DateTime.now();
    final channel = Channel(
      id: '1',
      name: 'France',
      group: '',
      logoUrl: '',
      streamUrl: '',
      supportsReplay: true,
    );
    final items = List.generate(8, (index) {
      final date = DateTime(today.year, today.month, today.day - index, 2);
      return ReplayItem(
        id: '$index',
        title: 'Programme $index',
        streamUrl: '',
        startTime: '',
        endTime: '',
        startAt: date,
        endAt: date.add(const Duration(hours: 1)),
      );
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        liveChannelsProvider.overrideWith((ref) async => [channel]),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        recentlyWatchedProvider.overrideWithBuild((ref, notifier) => {}),
        preferencesProvider.overrideWithBuild(
          (ref, notifier) => const UserPreferences(),
        ),
        channelReplaysProvider.overrideWith((ref, id) async => items),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplayScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    expect(find.text('Programme 0'), findsOneWidget);
    expect(find.text('Replay 48 h'), findsNothing);
    expect(tester.getRect(find.text("Aujourd'hui")).right, lessThan(600));
    Focus.of(tester.element(find.text("Aujourd'hui"))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Hier'))).hasPrimaryFocus, isTrue);

    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(horizontal, const Offset(1200, 0));
    await tester.pumpAndSettle();
    final oldest = items.last.startAt!;
    final locale =
        MaterialLocalizations.of(tester.element(find.text('France')));
    await tester
        .tap(find.text(locale.formatShortMonthDay(oldest).toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.text('Programme 7'), findsOneWidget);

    await tester.tap(find.byTooltip(locale.backButtonTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Programme 7'), findsNothing);
    expect(find.text('France'), findsOneWidget);
  });

  for (final hasPreviousRoute in [false, true]) {
    testWidgets(
        'retour de la grille ${hasPreviousRoute ? 'vers la page précédente' : 'vers l’accueil'}',
        (tester) async {
      final router = GoRouter(
        initialLocation: hasPreviousRoute ? '/previous' : '/replay',
        routes: [
          GoRoute(
            path: '/previous',
            builder: (_, __) => const Scaffold(body: Text('Previous')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(path: '/replay', builder: (_, __) => const ReplayScreen()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          liveChannelsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      if (hasPreviousRoute) {
        router.push('/replay');
        await tester.pumpAndSettle();
      }

      final locale = MaterialLocalizations.of(
        tester.element(find.byType(ReplayScreen)),
      );
      await tester.tap(find.byTooltip(locale.backButtonTooltip));
      await tester.pumpAndSettle();
      expect(find.text(hasPreviousRoute ? 'Previous' : 'Home'), findsOneWidget);
    });
  }
}
