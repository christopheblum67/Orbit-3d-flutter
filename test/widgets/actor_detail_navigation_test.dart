import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/cast_carousel.dart';
import 'package:orbit_3d_flutter/features/actors/actor_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/person.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('la naissance et le genre suivent la langue de la fiche',
      (tester) async {
    final actor = Actor(
      id: '42',
      name: 'Actor',
      character: '',
      profilePath: '',
      source: ActorSource.tmdb,
    );
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ActorDetailScreen(actor: actor),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tmdbPersonDetailProvider(42).overrideWith((ref) async =>
            const PersonDetail(
                id: 42, name: 'Actor', birthday: '1980-01-02', gender: 1)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Born on'), findsOneWidget);
    expect(find.textContaining('1980'), findsOneWidget);
    expect(find.textContaining('Female'), findsOneWidget);
  });

  testWidgets('fiche acteur, biographie et filmographie accessibles au D-pad',
      (tester) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actor = Actor(
      id: '42',
      name: 'Actrice',
      character: 'Rôle',
      profilePath: '',
      source: ActorSource.tmdb,
    );
    final credits = List.generate(
      12,
      (index) => MovieCredit(
        tmdbId: index + 1,
        title: 'Film $index',
        year: 2000 + index,
        character: 'Personnage $index',
        isTv: index == 8,
      ),
    );
    final person = PersonDetail(
      id: 42,
      name: actor.name,
      biography: List.filled(80, 'Biographie détaillée.').join(' '),
      knownFor: [credits.first],
      movieCredits: credits,
    );
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: CastCarousel(
            actors: [actor],
            onActorTap: (actor) => context.push('/actor/detail', extra: actor),
          ),
        ),
      ),
      GoRoute(
        path: '/actor/detail',
        builder: (_, state) => ActorDetailScreen(actor: state.extra as Actor),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tmdbPersonDetailProvider(42).overrideWith((ref) async => person),
        tmdbFilmographySynopsisProvider.overrideWith(
          (ref, credit) async => 'Synopsis du film ${credit.tmdbId}',
        ),
        moviesProvider.overrideWith((ref) async => <Movie>[]),
        seriesProvider.overrideWith((ref) async => <Series>[]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('Actrice'));
    await tester.pumpAndSettle();
    expect(find.byType(ActorDetailScreen), findsOneWidget);
    final page = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(page.controller!.offset, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Film 0'))).hasFocus, isTrue);
    for (var index = 1; index <= 8; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
          Focus.of(tester.element(find.text('Film $index'))).hasFocus, isTrue);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Synopsis du film 9'), findsOneWidget);
    expect(find.text('Personnage 8', findRichText: true), findsNothing);
    expect(find.text('Rôle : Personnage 8'), findsOneWidget);
    expect(find.text('Série'), findsOneWidget);
    expect(find.text('Correspondance non confirmée dans le catalogue.'),
        findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(Focus.of(tester.element(find.text('Film 8'))).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ouvre la série correspondante depuis la fiche du crédit',
      (tester) async {
    final actor = Actor(
      id: '42',
      name: 'Actrice',
      character: '',
      profilePath: '',
      source: ActorSource.tmdb,
    );
    const credit = MovieCredit(
      tmdbId: 99,
      title: 'Série test',
      year: 2020,
      isTv: true,
    );
    final series = Series(
      id: 'catalog-1',
      title: 'Série test',
      description: '',
      coverUrl: '',
      year: 2020,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: [],
    );
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ActorDetailScreen(actor: actor),
      ),
      GoRoute(
        path: '/series/detail',
        builder: (_, state) =>
            Text('Catalogue ${state.uri.queryParameters['id']}'),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tmdbPersonDetailProvider(42).overrideWith((ref) async =>
            const PersonDetail(id: 42, name: 'Actrice', credits: [credit])),
        tmdbFilmographySynopsisProvider.overrideWith(
          (ref, credit) async => List.filled(200, 'Synopsis long.').join(' '),
        ),
        seriesProvider.overrideWith((ref) async => [series]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    final dialogScroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(dialogScroll.controller!.offset, greaterThan(0));
    await tester.tap(find.text('Voir dans le catalogue'));
    await tester.pumpAndSettle();
    expect(find.text('Catalogue catalog-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fiche lisible sur écran étroit avec texte agrandi',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actor = Actor(
      id: '42',
      name: 'Actrice',
      character: '',
      profilePath: '',
      source: ActorSource.tmdb,
    );
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: ActorDetailScreen(actor: actor),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tmdbPersonDetailProvider(42)
            .overrideWith((ref) async => const PersonDetail(
                  id: 42,
                  name: 'Actrice',
                  credits: [
                    MovieCredit(
                      tmdbId: 1,
                      title: 'Un film avec un titre particulièrement long',
                    ),
                  ],
                )),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
