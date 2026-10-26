import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/features/history/history_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';

void main() {
  late HistoryService historyService;
  late Box<dynamic> historyBox;

  setUpAll(() async {
    final directory =
        await Directory.systemTemp.createTemp('orbit_history_ui_');
    Hive.init(directory.path);
  });

  setUp(() async {
    historyService = HistoryService();
    await historyService.init();
    historyBox = Hive.box('history');
    await historyBox.clear();
    await historyService.addEntry(
      'vod',
      'Film récent',
      'https://media.example.test/movie.m3u8',
    );
  });

  tearDown(() async {
    await historyBox.clear();
  });

  testWidgets('affiche une entrée et ouvre le lecteur avec ses paramètres',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/player',
          builder: (context, state) => Scaffold(
            body: Text(
              '${state.uri.queryParameters['title']}|'
              '${state.uri.queryParameters['url']}|'
              '${state.uri.queryParameters['type']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyServiceProvider.overrideWithValue(historyService),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Film récent'), findsOneWidget);
    expect(find.text('vod'), findsOneWidget);
    await tester.tap(find.text('Film récent'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Film récent|https://media.example.test/movie.m3u8|vod',
      ),
      findsOneWidget,
    );
  });
}
