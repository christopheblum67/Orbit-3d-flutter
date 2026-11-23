import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/epg/epg_screen.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/catch_up_screen.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/features/player/player_route_data.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Cache extends EPGDataCache {
  @override
  Future<List<EPGProgram>> loadFull(ApiService api,
          {bool forceRefresh = false}) async =>
      [];
}

class _Api extends ApiService {
  @override
  String replayStreamUrl({
    required Channel channel,
    required String baseUrl,
    required String username,
    required String password,
    required int startEpoch,
    required int endEpoch,
  }) =>
      'http://example.test/replay';
}

void main() {
  final channel = Channel(
    id: '1',
    name: 'Test TV',
    logoUrl: '',
    streamUrl: 'http://example.test/live',
    group: 'TV',
    supportsReplay: true,
  );
  final now = DateTime.now();
  final program = EPGProgram(
    channelId: '1',
    title: 'Programme terminé',
    description: '',
    start: now.subtract(const Duration(hours: 2)),
    end: now.subtract(const Duration(hours: 1)),
  );
  final sub = Subscription(
    id: 'test',
    name: 'test',
    type: SubscriptionType.xtream,
    baseUrl: 'http://example.test',
    username: 'test',
    password: 'test',
    createdAt: now,
  );

  testWidgets('catch-up follows the light theme with readable program text',
      (tester) async {
    final theme = ThemeData.light();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        channelCatchUpProvider.overrideWith((ref, id) async => [program]),
        activeSubscriptionProvider.overrideWith((ref) => sub),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CatchUpScreen(channel: channel),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        theme.scaffoldBackgroundColor);
    expect(tester.widget<Text>(find.text(program.title)).style!.color,
        theme.colorScheme.onSurface);
    expect(tester.takeException(), isNull);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const EpgScreen()),
      GoRoute(
        path: '/player',
        builder: (_, state) {
          final data = state.extra as PlayerRouteData;
          return Text('${data.contentType.name}:${data.streamUrl}',
              textDirection: TextDirection.ltr);
        },
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        liveChannelsProvider.overrideWith((ref) async => [channel]),
        activeSubscriptionProvider.overrideWith((ref) => sub),
        apiServiceProvider.overrideWith((ref) => _Api()),
        epgDataCacheProvider.overrideWith((ref) => _Cache()),
        channelEpgWindowProvider.overrideWith((ref, id) async => [program]),
        channelCatchUpProvider.overrideWith((ref, id) async => [program]),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        recentlyWatchedProvider.overrideWithBuild((ref, notifier) => {}),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> selectProgram(WidgetTester tester) async {
    tester.widget<EpgGrid2DView>(find.byType(EpgGrid2DView)).onProgramTap!(
        program, channel.name);
    await tester.pumpAndSettle();
  }

  testWidgets('catch-up dates use the selected language', (tester) async {
    final datedProgram = EPGProgram(
      channelId: '1',
      title: 'Program',
      description: '',
      start: DateTime(2020, 1, 2, 10),
      end: DateTime(2020, 1, 2, 11),
    );
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => CatchUpScreen(channel: channel)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        channelCatchUpProvider.overrideWith((ref, id) async => [datedProgram]),
        activeSubscriptionProvider.overrideWith((ref) => sub),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Jan 2'), findsOneWidget);
  });

  testWidgets('program sheet opens live player with typed data',
      (tester) async {
    await open(tester);
    await selectProgram(tester);
    await tester.tap(find.text(
        AppLocalizations.of(tester.element(find.byType(EpgScreen))).watchLive));
    await tester.pumpAndSettle();
    expect(
        find.text('${PlaybackContentType.live.name}:http://example.test/live'),
        findsOneWidget);
  });

  testWidgets('program sheet opens replay player', (tester) async {
    await open(tester);
    await selectProgram(tester);
    await tester.tap(find.byIcon(Icons.replay).last);
    await tester.pumpAndSettle();
    expect(
        find.text(
            '${PlaybackContentType.replay.name}:http://example.test/replay'),
        findsOneWidget);
  });

  testWidgets('program sheet opens catch-up and starts its replay',
      (tester) async {
    await open(tester);
    await selectProgram(tester);
    await tester.tap(find.text('Programmes en replay'));
    await tester.pumpAndSettle();
    expect(find.byType(CatchUpScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.replay).last);
    await tester.pumpAndSettle();
    expect(
        find.text(
            '${PlaybackContentType.replay.name}:http://example.test/replay'),
        findsOneWidget);
  });
}
