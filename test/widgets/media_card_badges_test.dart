import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';

class _Session extends Fake implements CloudflareSessionManager {
  @override
  String get baseUrl => 'https://panel.example';

  @override
  Map<String, String> get videoHeaders => {'X-Test-Session': 'marker'};
}

class _TestPreferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

void main() {
  testWidgets('poster fallback is used only when missing or loading fails',
      (tester) async {
    var calls = 0;
    Widget card(String poster) => ProviderScope(
          overrides: [preferencesProvider.overrideWith(_TestPreferences.new)],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 160,
                height: 300,
                child: MediaCard(
                  title: 'Film',
                  posterUrl: poster,
                  year: 0,
                  genre: '',
                  rating: 0,
                  ageLabel: null,
                  fallbackIcon: Icons.movie,
                  posterFallbackBuilder: (context, fallback) {
                    calls++;
                    return const Text('Repli');
                  },
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(card('https://example.invalid/poster.jpg'));
    expect(calls, 0);
    final image =
        tester.widget<OrbitCachedImage>(find.byType(OrbitCachedImage));
    final result = image.errorWidget!(
      tester.element(find.byType(OrbitCachedImage)),
      image.imageUrl,
      Exception(),
    );
    expect(result, isA<Text>());
    expect(calls, 1);
    await tester.pumpWidget(card(''));
    expect(find.text('Repli'), findsOneWidget);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('highlighted titles are red and bold in $brightness',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [preferencesProvider.overrideWith(_TestPreferences.new)],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const Scaffold(
              body: Row(
                children: [
                  SizedBox(
                    width: 160,
                    height: 300,
                    child: MediaCard(
                      title: 'Nouveauté',
                      posterUrl: '',
                      year: 0,
                      genre: '',
                      rating: 0,
                      ageLabel: null,
                      fallbackIcon: Icons.movie,
                      highlightTitle: true,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    height: 300,
                    child: MediaCard(
                      title: 'Existant',
                      posterUrl: '',
                      year: 0,
                      genre: '',
                      rating: 0,
                      ageLabel: null,
                      fallbackIcon: Icons.movie,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final highlighted = tester.widget<Text>(find.text('Nouveauté'));
      final existing = tester.widget<Text>(find.text('Existant'));
      expect(highlighted.style!.color,
          Theme.of(tester.element(find.text('Nouveauté'))).colorScheme.error);
      expect(highlighted.style!.fontWeight, FontWeight.w900);
      expect(existing.style!.color, isNot(highlighted.style!.color));
    });
  }

  testWidgets('rating is above affinity and new badge avoids age badge',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWith(_TestPreferences.new)],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 300,
                child: MediaCard(
                  title: 'Film ou série',
                  posterUrl: '',
                  year: 0,
                  genre: '',
                  rating: 7.5,
                  ageLabel: '12+',
                  fallbackIcon: Icons.movie,
                  isNew: true,
                  matchPercent: 87,
                  ratingAboveAffinity: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final rating = tester.getRect(find.text('7.5'));
    final affinity = tester.getRect(find.text('87%'));
    final age = tester.getRect(find.text('12+'));
    final newBadge = tester.getRect(find.text('NOUVEAU'));
    expect(rating.bottom, lessThan(affinity.top));
    expect(rating.left, greaterThanOrEqualTo(affinity.left));
    expect(newBadge.top, greaterThan(age.bottom));
    expect(tester.widget<Text>(find.text('NOUVEAU')).style?.fontSize, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('badges do not overlap in the normal layout', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWith(_TestPreferences.new)],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 300,
              child: MediaCard(
                title: 'Film',
                posterUrl: '',
                year: 0,
                genre: '',
                rating: 0,
                ageLabel: '12+',
                fallbackIcon: Icons.movie,
                isNew: true,
                topBadge: Text('1'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.text('1')).bottom,
        lessThan(tester.getRect(find.text('12+')).top));
    expect(tester.getRect(find.text('12+')).bottom,
        lessThan(tester.getRect(find.text('NOUVEAU')).top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('poster headers are not sent to URLs with user info',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(_TestPreferences.new),
        cloudflareSessionProvider.overrideWith((ref) => _Session()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 300,
            child: MediaCard(
              title: 'Film',
              posterUrl: 'https://user@panel.example/poster.jpg',
              year: 0,
              genre: '',
              rating: 0,
              ageLabel: null,
              fallbackIcon: Icons.movie,
            ),
          ),
        ),
      ),
    ));
    expect(
      tester.widget<OrbitCachedImage>(find.byType(OrbitCachedImage)).httpHeaders,
      isNull,
    );
  });
}
