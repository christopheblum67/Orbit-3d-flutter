import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

void main() {
  group('MovieCredits.fromMap (formats panels Xtream)', () {
    test('liste d\'objets TMDB-like', () {
      final credits = MovieCredits.fromMap({
        'cast': [
          {'id': 1, 'name': 'Tom Hanks', 'character': 'Forrest', 'order': 0},
          {'id': 2, 'name': 'Robin Wright', 'character': 'Jenny', 'order': 1},
        ],
        'crew': [
          {
            'id': 3,
            'name': 'Robert Zemeckis',
            'job': 'Director',
            'department': 'Directing',
            'order': 0,
          },
        ],
      });
      expect(credits.cast, hasLength(2));
      expect(credits.cast.first.name, 'Tom Hanks');
      expect(credits.cast.first.character, 'Forrest');
      expect(credits.crew.single.department, 'Directing');
    });

    test('liste de simples chaînes (noms seuls)', () {
      final credits = MovieCredits.fromMap({
        'cast': ['Tom Hanks', 'Robin Wright'],
        'crew': ['Robert Zemeckis'],
      });
      expect(credits.cast, hasLength(2));
      expect(credits.cast.first.name, 'Tom Hanks');
      expect(credits.cast.first.hasProfile, isFalse);
      expect(credits.crew.single.name, 'Robert Zemeckis');
      expect(credits.cast.map((a) => a.id), everyElement(startsWith('xtream-')));
    });

    test('cast en chaîne unique délimitée', () {
      final credits = MovieCredits.fromMap({
        'cast': 'Tom Hanks; Robin Wright; Gary Sinise',
        'crew': 'Robert Zemeckis / Eric Roth',
      });
      expect(credits.cast, hasLength(3));
      expect(credits.crew, hasLength(2));
    });

    test('entrées manquantes ou corrompues ignorées', () {
      final credits = MovieCredits.fromMap({
        'cast': [
          {'name': '  '},
          null,
          'Al Pacino',
        ],
        'crew': [],
      });
      expect(credits.cast, hasLength(1));
      expect(credits.cast.single.name, 'Al Pacino');
    });

    test('cast vide → listes vides', () {
      final credits = MovieCredits.fromMap({'cast': null, 'crew': <Object>[]});
      expect(credits.cast, isEmpty);
      expect(credits.crew, isEmpty);
    });

    test('tri par ordre au générique', () {
      final credits = MovieCredits.fromMap({
        'cast': [
          {'name': 'Second', 'order': 1},
          {'name': 'Premier', 'order': 0},
        ],
      });
      expect(credits.cast.first.name, 'Premier');
    });
  });

  group('TmdbService.normalizeSearchTitle', () {
    test('retire année et tags qualité', () {
      expect(
        TmdbService.normalizeSearchTitle('Avatar (2009) FRENCH 1080p WEB-DL'),
        'Avatar',
      );
    });

    test('conserve un titre simple', () {
      expect(TmdbService.normalizeSearchTitle('Interstellar'), 'Interstellar');
    });

    test('retire les segments entre parenthèses', () {
      expect(
        TmdbService.normalizeSearchTitle('Le Seigneur des Anneaux [4K] (2001)'),
        'Le Seigneur des Anneaux',
      );
    });

    test('nettoie séparateurs et espaces multiples', () {
      expect(
        TmdbService.normalizeSearchTitle('  Inception. 2010 - CAM '),
        'Inception',
      );
    });
  });
}