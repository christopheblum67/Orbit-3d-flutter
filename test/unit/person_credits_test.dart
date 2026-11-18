import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/person.dart';

void main() {
  test('combined credits retain both films and series with shared IDs', () {
    final person = PersonDetail.fromTmdbJson(
      {'id': 42, 'name': 'Actor'},
      creditsJson: {
        'cast': [
          {
            'id': 5,
            'media_type': 'movie',
            'title': 'Film',
            'release_date': '2020-01-01'
          },
          {
            'id': 5,
            'media_type': 'tv',
            'name': 'Série',
            'first_air_date': '2021-01-01'
          },
        ],
        'crew': [
          {'id': 5, 'media_type': 'movie', 'title': 'Film'},
        ],
      },
    );
    expect(person.credits.length, 2);
    expect(person.movieCredits.single.title, 'Film');
    expect(person.credits.last.title, 'Série');
    expect(person.credits.last.year, 2021);
    expect(person.credits.last.isTv, isTrue);
  });
}
