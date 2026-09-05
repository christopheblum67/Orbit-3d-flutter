import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/content_filter_provider.dart';

Movie _movie({
  String id = 'm1',
  String title = 'Film',
  String genre = '',
  String pegi = '',
  String description = '',
}) {
  return Movie(
    id: id,
    title: title,
    description: description,
    posterUrl: '',
    year: 2020,
    genre: genre,
    director: '',
    rating: 0,
    pegi: pegi,
    streamUrl: '',
  );
}

Series _series({
  String id = 's1',
  String title = 'Série',
  String genre = '',
  String pegi = '',
}) {
  return Series(
    id: id,
    title: title,
    description: '',
    coverUrl: '',
    year: 2020,
    genre: genre,
    director: '',
    rating: 0,
    pegi: pegi,
    episodes: const [],
  );
}

Channel _channel({String id = 'c1', String name = 'Chaîne'}) {
  return Channel(
    id: id,
    name: name,
    logoUrl: '',
    streamUrl: '',
    group: '',
  );
}

ReplayItem _replay({String id = 'r1', String title = 'Replay'}) {
  return ReplayItem(
    id: id,
    title: title,
    streamUrl: '',
    startTime: '',
    endTime: '',
  );
}

ContentFilter _filter({
  bool hideAdult = false,
  bool hideViolent = false,
  Set<String> ids = const {},
}) {
  return ContentFilter(
    hiddenContentIds: ids,
    hideAdultContent: hideAdult,
    hideViolentContent: hideViolent,
  );
}

void main() {
  group('Heuristique adulte', () {
    test('PEGI 18 → film masqué quand hideAdultContent', () {
      final filter = _filter(hideAdult: true);
      final movie = _movie(pegi: '18', genre: 'Action');
      expect(filter.isAdultMovie(movie), isTrue);
      expect(filter.isHiddenMovie(movie), isTrue);
    });

    test('NC-17 et R sont classés adultes', () {
      final filter = _filter(hideAdult: true);
      expect(filter.isHiddenMovie(_movie(pegi: 'NC-17')), isTrue);
      expect(filter.isHiddenMovie(_movie(pegi: 'R')), isTrue);
    });

    test('genre Érotique (accent) → adulte', () {
      final filter = _filter(hideAdult: true);
      expect(filter.isAdultMovie(_movie(genre: 'Érotique')), isTrue);
    });

    test('genre Porn → adulte, série aussi', () {
      final filter = _filter(hideAdult: true);
      expect(filter.isAdultMovie(_movie(genre: 'Porn')), isTrue);
      expect(filter.isAdultSeries(_series(genre: 'XXX')), isTrue);
    });

    test('description explicit → adulte', () {
      final filter = _filter(hideAdult: true);
      expect(
        filter.isHiddenMovie(_movie(description: 'Contenu explicite')),
        isTrue,
      );
    });

    test('sans flag, un film 18+ reste visible (pas de sur-masquage)', () {
      final filter = _filter();
      expect(filter.isHiddenMovie(_movie(pegi: '18')), isFalse);
    });

    test('frontière de mot : pas de faux positif sur genre banal', () {
      final filter = _filter(hideAdult: true);
      expect(filter.isAdultMovie(_movie(genre: 'Action')), isFalse);
      expect(filter.isAdultMovie(_movie(title: 'Péronisme')), isFalse);
      expect(filter.isAdultSeries(_series(genre: 'Science-Fiction')), isFalse);
    });
  });

  group('Heuristique violence', () {
    test('genre Horreur → violent, masqué quand hideViolentContent', () {
      final filter = _filter(hideViolent: true);
      final movie = _movie(genre: 'Horreur');
      expect(filter.isViolentMovie(movie), isTrue);
      expect(filter.isHiddenMovie(movie), isTrue);
    });

    test('genre Thriller → violent', () {
      final filter = _filter(hideViolent: true);
      expect(filter.isHiddenSeries(_series(genre: 'Thriller')), isTrue);
    });

    test('description gore → violent', () {
      final filter = _filter(hideViolent: true);
      expect(
        filter.isHiddenMovie(_movie(description: 'Scène gore intense')),
        isTrue,
      );
    });

    test('chaîne Horreur masquée quand hideViolentContent', () {
      final filter = _filter(hideViolent: true);
      expect(filter.isHiddenChannel(_channel(name: 'Horror Night')), isTrue);
    });

    test('sans flag, un contenu violent reste visible', () {
      final filter = _filter();
      expect(filter.isHiddenSeries(_series(genre: 'Gore')), isFalse);
    });
  });

  group('Masquage manuel par id', () {
    test('id dans hiddenContentIds masque quel que soit le type', () {
      final filter = _filter(ids: const {'m42', 's42', 'c42', 'r42'});
      expect(filter.isHiddenMovie(_movie(id: 'm42')), isTrue);
      expect(filter.isHiddenSeries(_series(id: 's42')), isTrue);
      expect(filter.isHiddenChannel(_channel(id: 'c42')), isTrue);
      expect(filter.isHiddenReplay(_replay(id: 'r42')), isTrue);
    });

    test('id hors liste non masqué', () {
      final filter = _filter(ids: const {'m42'});
      expect(filter.isHiddenMovie(_movie(id: 'm43')), isFalse);
    });
  });

  group('visibleList générique', () {
    test('filtre films et séries et chaînes en une passe', () {
      final filter = _filter(hideAdult: true, hideViolent: true);
      final movies = [
        _movie(id: 'm1', genre: 'Comédie'),
        _movie(id: 'm2', pegi: '18'),
      ];
      final series = [
        _series(id: 's1', genre: 'Horreur'),
        _series(id: 's2', genre: 'Drame'),
      ];
      final channels = [_channel(id: 'c1'), _channel(id: 'c2', name: 'XXX TV')];

      expect(filter.visibleList(movies).map((m) => m.id), ['m1']);
      expect(filter.visibleList(series).map((s) => s.id), ['s2']);
      expect(filter.visibleList(channels).map((c) => c.id), ['c1']);
      final replays = [_replay(id: 'r1'), _replay(id: 'r2', title: 'Adulte')];
      expect(filter.visibleList(replays).length, 1);
    });
  });

  group('fromProfile', () {
    test('mappe les booléens et les ids du profil', () {
      final profile = UserProfile(
        id: 'p1',
        firstName: 'Enfant1',
        dateOfBirth: DateTime(2016, 1, 1),
        gender: 'Non spécifié',
        favoriteGenres: const ['Animation'],
        hideAdultContent: true,
        hideViolentContent: true,
        hiddenContentIds: const ['m99'],
      );
      final filter = ContentFilter.fromProfile(profile);
      expect(filter.hideAdultContent, isTrue);
      expect(filter.hideViolentContent, isTrue);
      expect(filter.hiddenContentIds, {'m99'});
      expect(filter.isHiddenSeries(_series(id: 'm99')), isTrue);
    });

    test('profil null → aucun filtre actif', () {
      final filter = ContentFilter.fromProfile(null);
      expect(filter.hideAdultContent, isFalse);
      expect(filter.hideViolentContent, isFalse);
      expect(filter.hiddenContentIds, isEmpty);
    });
  });
}
