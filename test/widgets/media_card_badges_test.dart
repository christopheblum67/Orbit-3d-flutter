import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

class _TestPreferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

void main() {
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
      expect(
          highlighted.style!.color,
          brightness == Brightness.dark
              ? Colors.redAccent.shade100
              : Colors.red.shade800);
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
}
