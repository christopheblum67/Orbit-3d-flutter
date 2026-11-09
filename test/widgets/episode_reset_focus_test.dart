import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/series/series_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

class _Progress extends PlaybackProgressService {
  bool cleared = false;

  @override
  PlaybackProgress? get(String id) => cleared
      ? null
      : const PlaybackProgress(
          positionMs: 850000,
          durationMs: 900000,
          updatedAt: 0,
        );

  @override
  Future<void> clear(String id) async {
    cleared = true;
    notifyListeners();
  }
}

void main() {
  testWidgets('long press opens reset with navigable TV buttons',
      (tester) async {
    final progress = _Progress();
    final series = Series(
      id: 'series',
      title: 'Série',
      description: '',
      coverUrl: '',
      year: 2020,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: [
        Episode(
          id: 'episode',
          title: 'Départ',
          season: 1,
          episodeNumber: 1,
          streamUrl: '',
        ),
      ],
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const SeriesDetailScreen(seriesId: 'series'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
          seriesInfoProvider('series').overrideWith((ref) async => series),
          seriesDetailProvider(series)
              .overrideWith((ref) async => SeriesDetail.fromSeries(series)),
          playbackProgressServiceProvider.overrideWith((ref) => progress),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final episode = find.textContaining('Départ');
    await tester.scrollUntilVisible(
      episode,
      400,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    void focusEpisode() {
      var node = Focus.of(tester.element(episode.first));
      while (!node.canRequestFocus) {
        node = node.parent!;
      }
      node.requestFocus();
    }

    focusEpisode();
    await tester.pumpAndSettle();

    Future<void> openDialog() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.text("Réinitialiser l'épisode ?"), findsOneWidget);
    }

    await openDialog();
    expect(Focus.of(tester.element(find.text('Annuler'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
        Focus.of(tester.element(find.text('Réinitialiser'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Annuler'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(progress.cleared, isFalse);

    focusEpisode();
    await tester.pumpAndSettle();
    await openDialog();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(progress.cleared, isFalse);

    focusEpisode();
    await tester.pumpAndSettle();
    await openDialog();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(progress.cleared, isTrue);
    expect(find.text("Réinitialiser l'épisode ?"), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
