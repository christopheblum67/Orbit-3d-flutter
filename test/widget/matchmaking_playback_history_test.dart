import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/matchmaking/matchmaking_screen.dart';
import 'package:orbit_3d_flutter/features/player/player_route_data.dart';
import 'package:orbit_3d_flutter/features/vod/movie_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

class _EmptyProgress extends PlaybackProgressService {
  @override
  PlaybackProgress? get(String id) => null;
}

void main() {
  testWidgets('movie opens detail, plays with catalog ID and returns to list',
      (tester) async {
    final profile = UserProfile(
      id: 'primary',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final movie = Movie(
      id: 'movie-42',
      title: 'Film',
      description: '',
      posterUrl: '',
      year: 2020,
      genre: 'Action',
      director: '',
      rating: 7,
      pegi: '',
      streamId: 'https://example.test/stream',
    );
    final series = Series(
      id: 'series-42',
      title: 'Serie',
      description: '',
      coverUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: const [],
    );
    PlayerRouteData? playerData;
    String? seriesId;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Column(children: [
            TextButton(
              onPressed: () => openRecommendation(
                context,
                Recommendation(kind: RecommendationKind.movie, movie: movie),
              ),
              child: const Text('movie'),
            ),
            TextButton(
              onPressed: () => openRecommendation(
                context,
                Recommendation(kind: RecommendationKind.series, series: series),
              ),
              child: const Text('series'),
            ),
          ]),
        ),
      ),
      GoRoute(
        path: '/vod/detail',
        builder: (_, state) => MovieDetailScreen(movie: state.extra as Movie),
      ),
      GoRoute(
        path: '/player',
        builder: (_, state) {
          playerData = state.extra as PlayerRouteData;
          return const Text('player');
        },
      ),
      GoRoute(
        path: '/series/detail',
        builder: (_, state) {
          seriesId = state.uri.queryParameters['id'];
          return const Text('series detail');
        },
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        movieDetailProvider(movie)
            .overrideWith((ref) async => MovieDetail.fromMovie(movie)),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        playbackProgressServiceProvider.overrideWith((ref) => _EmptyProgress()),
        downloadTasksStreamProvider.overrideWith((ref) => const AsyncData([])),
        moviesProvider.overrideWith((ref) async => <Movie>[]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('movie'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(playerData, isNull);
    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();
    expect(playerData!.favorite!.id, movie.id);
    expect(playerData!.favorite!.type, ContentType.vod);
    expect(
      playerData!.progressId,
      PlaybackProgressService.idForProfile('primary', 'movie-${movie.id}'),
    );
    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('movie'), findsOneWidget);
    await tester.tap(find.text('series'));
    await tester.pumpAndSettle();
    expect(seriesId, series.id);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
