// Mesure de l'empreinte reelle d'un catalogue VOD en memoire.
//
// Le profil des champs est celui REELLEMENT observe sur le panel
// (99 569 entrees) : `plot`, `director`, `genre` et `year` sont ABSENTS, et
// `name`/`stream_icon`/`rating`/`category_id` mesurent 26/46/2.6/4 caracteres.
// On ne suppose pas : on reproduit les longueurs mesurees.
import 'dart:convert';
import 'dart:io';

const n = 20000;

Map<String, dynamic> entry(int i) => {
      'num': i + 1,
      'name': 'The Shawshank Redemption ${i + 1}',
      'stream_type': 'movie',
      'stream_id': 100000 + i,
      'stream_icon': 'http://logott.firstcloud.me/posters/${734000 + i}.jpg',
      'rating': '9.3',
      'added': '1706360000',
      'category_id': '${100 + (i % 140)}',
      'container_extension': 'mkv',
    };

class Movie {
  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.director,
    required this.rating,
    required this.pegi,
    required this.streamUrl,
    required this.categoryId,
  });
  final String id, title, description, posterUrl, genre, director, pegi;
  final String streamUrl, categoryId;
  final int year;
  final double rating;
}

/// Variante « grille » : ni `description`, ni `streamUrl`, ni `director`.
class Compact {
  Compact({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.rating,
    required this.categoryId,
  });
  final String id, title, posterUrl, genre, categoryId;
  final int year;
  final double rating;
}

double mb(num b) => b / 1024 / 1024;
double per(num total) => total / n;

void main() {
  final raw = <Map<String, dynamic>>[];
  for (var i = 0; i < n; i++) {
    raw.add(entry(i));
  }

  final json = jsonEncode(raw);
  print('=== jeu de donnees (profil reel du panel) ===');
  print('entrees      : $n');
  print('JSON         : ${(json.length / 1024).toStringAsFixed(1)} Ko');
  print('projection   : ${mb(json.length * 99569 / n).toStringAsFixed(1)} Mo'
      ' pour 99 569 films');

  // 1. Maps decodees (transitoire de Dio)
  final rss0 = ProcessInfo.currentRss;
  final decoded = <Map<String, dynamic>>[];
  for (final e in raw) {
    decoded.add(Map<String, dynamic>.from(e));
  }
  final rss1 = ProcessInfo.currentRss;

  // 2. Movie complet
  final movies = <Movie>[];
  for (final m in decoded) {
    movies.add(Movie(
      id: m['stream_id'].toString(),
      title: m['name'].toString(),
      description: '',
      posterUrl: m['stream_icon'].toString(),
      year: 0,
      genre: 'Action / Aventure / Drame',
      director: '',
      rating: double.tryParse(m['rating'].toString()) ?? 0,
      pegi: '',
      streamUrl:
          'http://1.888000.eu/player_api.php?username=Premchrisfr25&password=xwQt75SyX2jK&action=stream&type=movie&stream_id=${m['stream_id']}&extension=mkv',
      categoryId: m['category_id'].toString(),
    ));
  }
  final rss2 = ProcessInfo.currentRss;

  // 3. Version compacte
  final compact = <Compact>[];
  for (final m in decoded) {
    compact.add(Compact(
      id: m['stream_id'].toString(),
      title: m['name'].toString(),
      posterUrl: m['stream_icon'].toString(),
      year: 0,
      genre: 'Action / Aventure / Drame',
      rating: double.tryParse(m['rating'].toString()) ?? 0,
      categoryId: m['category_id'].toString(),
    ));
  }
  final rss3 = ProcessInfo.currentRss;

  print('');
  print('=== empreinte (RSS) ===');
  print('Maps decodees  : ${mb(rss1 - rss0).toStringAsFixed(1)} Mo'
      ' (${per(rss1 - rss0).toStringAsFixed(0)} o/entree)');
  print('Movie complet  : ${mb(rss2 - rss1).toStringAsFixed(1)} Mo'
      ' (${per(rss2 - rss1).toStringAsFixed(0)} o/entree)');
  print('Compact grille : ${mb(rss3 - rss2).toStringAsFixed(1)} Mo'
      ' (${per(rss3 - rss2).toStringAsFixed(0)} o/entree)');

  final scale = 99569.0 / n;
  print('');
  print('=== projection catalogue reel (99 569 films) ===');
  print('Maps transitoire : ${mb((rss1 - rss0) * scale).toStringAsFixed(0)} Mo');
  print('Movie complet    : ${mb((rss2 - rss1) * scale).toStringAsFixed(0)} Mo');
  print('Compact grille   : ${mb((rss3 - rss2) * scale).toStringAsFixed(0)} Mo');
  final gain = (rss2 - rss1) - (rss3 - rss2);
  print('gain si compact  : ${mb(gain * scale).toStringAsFixed(0)} Mo'
      ' (${(gain * 100.0 / (rss2 - rss1)).toStringAsFixed(0)} %)');

  // Poids du streamUrl, le plus gros chaine du modele
  final urlChars = movies.fold<int>(0, (a, m) => a + m.streamUrl.length);
  final totalChars = movies.fold<int>(
      0,
      (a, m) =>
          a +
          m.id.length +
          m.title.length +
          m.description.length +
          m.posterUrl.length +
          m.genre.length +
          m.director.length +
          m.pegi.length +
          m.streamUrl.length +
          m.categoryId.length);
  print('');
  print('=== poids des chaines (projection 99 569) ===');
  print('streamUrl        : ${mb(urlChars * scale).toStringAsFixed(0)} Mo'
      ' (${(urlChars * 100.0 / totalChars).toStringAsFixed(0)} % des caracteres)');
  print('total caracteres : ${mb(totalChars * scale).toStringAsFixed(0)} Mo');
  print('=> 9 String par film : ~${mb(9 * 20 * scale).toStringAsFixed(0)} Mo'
      ' de simples en-tetes d objet String');

  print('');
  print('controle : ${movies.length} movies, ${compact.length} compacts');
  print('titre[0] : ${movies.first.title} | poster ${movies.first.posterUrl}');
}
