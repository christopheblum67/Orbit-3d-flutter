import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/features/vod/movie_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

class _EmptyProgress extends PlaybackProgressService {
  @override
  PlaybackProgress? get(String id) => null;
}

void main() {
  testWidgets('movie detail shows its poster without the backdrop',
      (tester) async {
    final movie = Movie(
      id: '1',
      title: 'Film test',
      description: '',
      posterUrl: '',
      year: 2020,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      streamId: '',
    );
    final detail = MovieDetail.fromMovie(movie).copyWith(
      posterUrl: 'https://example.test/poster.jpg',
      backdropUrl: 'https://example.test/backdrop.jpg',
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MovieDetailScreen(movie: movie),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieDetailProvider(movie).overrideWith((ref) async => detail),
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
          favoritesProvider.overrideWithBuild((ref, notifier) => {}),
          playbackProgressServiceProvider
              .overrideWith((ref) => _EmptyProgress()),
          downloadTasksStreamProvider
              .overrideWith((ref) => const AsyncData([])),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final images = tester.widgetList<OrbitCachedImage>(
      find.byType(OrbitCachedImage),
    );
    expect(images.map((image) => image.imageUrl), [detail.posterUrl]);
    expect(find.text('Démarrer'), findsOneWidget);
    expect(find.text('Reprendre'), findsOneWidget);
  });
}
