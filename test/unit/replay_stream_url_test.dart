import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Construit une chaîne Xtream minimale.
Channel channel({String catchupSource = ''}) =>
    Channel(
      id: '7819',
      name: 'TF1 HD',
      logoUrl: '',
      streamUrl: 'http://x/live/7819.ts',
      group: 'FRANCE HD',
      epgChannelId: '7819',
      catchupSource: catchupSource,
    );

void main() {
  final api = ApiService();
  final start = DateTime.now().subtract(const Duration(hours: 3));
  final end = start.add(const Duration(hours: 1));
  final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
  final endEpoch = end.millisecondsSinceEpoch ~/ 1000;

  group('replayStreamUrl — un seul format, celui qui fonctionne', () {
    test('sans catchup-source, applique la convention Xtream /timeshift', () {
      // C'est le format de ce panel : `get_live_streams` n'expose pas de
      // `catchup-source`, contrairement aux playlists M3U.
      final url = api.replayStreamUrl(
        channel: channel(),
        baseUrl: 'http://panel.example.com:8080/',
        username: 'user',
        password: 'pass',
        startEpoch: startEpoch,
        endEpoch: endEpoch,
      );
      expect(url, contains('/timeshift/user/pass/'));
      expect(url, contains('/7819.'));
    });

    test('la durée est arrondie au minute supérieur', () {
      // Un programme de 90 min doit demander 90, pas 89 : une durée
      // tronquée fait rejouer une partie du programme en erreur.
      final s = DateTime.now().subtract(const Duration(hours: 2));
      final url = api.replayStreamUrl(
        channel: channel(),
        baseUrl: 'http://panel.example.com:8080',
        username: 'u',
        password: 'p',
        startEpoch: s.millisecondsSinceEpoch ~/ 1000,
        endEpoch: s.add(const Duration(minutes: 90)).millisecondsSinceEpoch ~/ 1000,
      );
      expect(url, contains('/90/'));
    });

    test('le catchup-source du panel prime sur la convention', () {
      // Un template explicite décrit le chemin RÉEL du replay ; l'ignorer
      // produisait des liens morts alors que le programme était listé.
      final url = api.replayStreamUrl(
        channel: channel(
          catchupSource:
              'http://panel.example.com:8080/timeshift/{start}-{duration}.ts',
        ),
        baseUrl: 'http://panel.example.com:8080',
        username: 'u',
        password: 'p',
        startEpoch: startEpoch,
        endEpoch: endEpoch,
      );
      expect(url, isNot(contains('{start}')));
      expect(url, startsWith('http://panel.example.com:8080/timeshift/'));
      expect(url, isNot(contains('/timeshift/u/p/')));
    });

    test('ne renvoie jamais le format /streaming/timeshift.php', () {
      // Régression : deux constructeurs coexistaient, et celui des écrans EPG
      // produisait ce format, qui ne fonctionne pas sur ce panel. Le replay
      // depuis la grille échouait là où le Replay aboutissait.
      final url = api.replayStreamUrl(
        channel: channel(),
        baseUrl: 'http://panel.example.com:8080',
        username: 'u',
        password: 'p',
        startEpoch: startEpoch,
        endEpoch: endEpoch,
      );
      expect(url, isNot(contains('timeshift.php')));
      expect(url, isNot(contains('stream=')));
    });

    test('les slashs de fin du baseUrl ne sont pas doublés', () {
      final url = api.replayStreamUrl(
        channel: channel(),
        baseUrl: 'http://panel.example.com:8080///',
        username: 'u',
        password: 'p',
        startEpoch: startEpoch,
        endEpoch: endEpoch,
      );
      expect(url, isNot(contains('8080///')));
    });
  });
}