import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/vod/movie_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

class _EmptyProgress extends PlaybackProgressService {
  @override
  PlaybackProgress? get(String id) => null;
}

void main() {
  final movie = Movie(
    id: '1',
    title: 'Film source',
    description: '',
    posterUrl: '',
    year: 2020,
    genre: '',
    director: '',
    rating: 0,
    pegi: '',
    streamId: '',
  );
  const recommendation = TmdbRankEntry(
    tmdbId: 99,
    title: 'Film recommandé',
    posterPath: '',
  );
  const secondRecommendation = TmdbRankEntry(
    tmdbId: 100,
    title: 'Deuxième film',
    posterPath: '',
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    required int tmdbId,
    required Future<List<TmdbRankEntry>> Function() load,
  }) async {
    final detail = MovieDetail.fromMovie(movie).copyWith(
      tmdbId: tmdbId,
      cast: [
        Actor(id: '1', name: 'Acteur test', character: '', profilePath: '')
      ],
    );
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => MovieDetailScreen(movie: movie)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        movieDetailProvider(movie).overrideWith((ref) async => detail),
        tmdbMovieRecommendationsProvider.overrideWith((ref, id) => load()),
        tmdbSimilarMoviesProvider.overrideWith((ref, id) async => []),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        playbackProgressServiceProvider.overrideWith((ref) => _EmptyProgress()),
        downloadTasksStreamProvider.overrideWith((ref) => const AsyncData([])),
        moviesProvider.overrideWith((ref) async => <Movie>[]),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  testWidgets('recommendations appear after cast and open by remote',
      (tester) async {
    await pumpPage(tester, tmdbId: 42, load: () async => [recommendation]);
    expect(tester.getTopLeft(find.text('Recommandations TMDB')).dy,
        greaterThan(tester.getTopLeft(find.text('Distribution')).dy));
    final card = find.text('Film recommandé');
    Focus.of(tester.element(card)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Film recommandé'), findsWidgets);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('empty and unidentified films explain missing recommendations',
      (tester) async {
    await pumpPage(tester, tmdbId: 42, load: () async => []);
    expect(
        find.text('Aucune recommandation TMDB pour ce film.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pumpPage(tester, tmdbId: 0, load: () async => [recommendation]);
    expect(find.text('Recommandations TMDB indisponibles pour ce film.'),
        findsOneWidget);
  });

  testWidgets('recommendation opens by touch', (tester) async {
    await pumpPage(tester, tmdbId: 42, load: () async => [recommendation]);
    await tester.tap(find.text('Film recommandé'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('remote moves horizontally between recommendations',
      (tester) async {
    await pumpPage(tester,
        tmdbId: 42,
        load: () async => [
              recommendation,
              secondRecommendation,
            ]);
    Focus.of(tester.element(find.text('Film recommandé'))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
        Focus.of(tester.element(find.text('Deuxième film'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Deuxième film'), findsWidgets);
  });

  testWidgets('failed request can be retried', (tester) async {
    var attempts = 0;
    await pumpPage(tester, tmdbId: 42, load: () async {
      if (++attempts == 1) throw StateError('offline');
      return [recommendation];
    });
    expect(find.text('Impossible de charger les recommandations TMDB.'),
        findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Film recommandé'), findsOneWidget);
    expect(attempts, 2);
  });
}
