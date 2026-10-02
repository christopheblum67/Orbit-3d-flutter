import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Les attributs de catch-up d'un `#EXTINF` sont la description du chemin de
/// replay : mode, fenêtre de l'abonnement, modèle d'URL.
///
/// Ils étaient lus sur la ligne d'URL qui suit le `#EXTINF`, où ils n'existent
/// pas. Résultat : `catchup`, `catchup-days` et `timeshift` valaient toujours
/// zéro, `supportsReplay` était toujours `false` sur une playlist M3U, et le
/// replay était considéré comme absent alors que le provider le publiait.
/// Ces tests verrouillent la lecture des bons attributs.
void main() {
  final api = ApiService();

  test('les attributs catch-up sont lus sur la ligne #EXTINF', () {
    const playlist = '''
#EXTM3U
#EXTINF:-1 tvg-id="fr1" group-title="France" catchup="default" catchup-days="7" catchup-source="?start={utc}&duration={duration}",|FR| TF1 FHD
http://panel.example/live/user/pass/101.ts
''';
    final channels = api.parseM3u(playlist);
    expect(channels, hasLength(1));
    final tf1 = channels.first;
    expect(tf1.name, '|FR| TF1 FHD');
    expect(tf1.supportsReplay, isTrue);
    expect(tf1.catchupMode, 'default');
    // La fenêtre vient du provider, plus d'un 48 h deviné.
    expect(tf1.archiveDays, 7);
    expect(tf1.catchupSource, '?start={utc}&duration={duration}');
  });

  test('catchup="none" ne compte pas comme un mode de substitution', () {
    const playlist = '''
#EXTINF:-1 group-title="France" catchup="none",TF1
http://panel.example/live/101.ts
''';
    final channels = api.parseM3u(playlist);
    expect(channels.single.supportsReplay, isFalse);
    expect(channels.single.catchupMode, 'none');
  });

  test('catchup-days seul suffit à rendre la chaîne rejouable', () {
    const playlist = '''
#EXTINF:-1 catchup-days="14",Arte
http://panel.example/live/102.ts
''';
    final channel = api.parseM3u(playlist).single;
    expect(channel.supportsReplay, isTrue);
    expect(channel.archiveDays, 14);
  });

  test('catchup-source seul suffit à rendre la chaîne rejouable', () {
    const playlist = '''
#EXTINF:-1 catchup-source="/ts-{utc}-{duration}.ts",Arte
http://panel.example/live/102.ts
''';
    final channel = api.parseM3u(playlist).single;
    expect(channel.supportsReplay, isTrue);
    expect(channel.catchupSource, '/ts-{utc}-{duration}.ts');
  });

  test('les attributs ne fuient pas d\'une entrée à la suivante', () {
    // Régression : les attributs étaient conservés d'une ligne à l'autre, donc
    // une chaîne sans catchup héritait du `catchup` de la précédente et
    // devenait rejouable à tort.
    const playlist = '''
#EXTINF:-1 catchup="default" catchup-days="7" catchup-source="?start={utc}",TF1
http://panel.example/live/101.ts
#EXTINF:-1,M6
http://panel.example/live/102.ts
''';
    final channels = api.parseM3u(playlist);
    expect(channels, hasLength(2));
    expect(channels[0].supportsReplay, isTrue);
    expect(channels[1].supportsReplay, isFalse);
    expect(channels[1].catchupSource, isEmpty);
    expect(channels[1].archiveDays, 0);
  });

  test('le mode est normalisé en minuscules', () {
    const playlist = '''
#EXTINF:-1 catchup="Flussonic" catchup-source="/ts-{utc}.ts",Arte
http://panel.example/live/102.ts
''';
    expect(api.parseM3u(playlist).single.catchupMode, 'flussonic');
  });

  test('timeshift seul rend la chaîne rejouable', () {
    const playlist = '''
#EXTINF:-1 timeshift="172800",TF1
http://panel.example/live/101.ts
''';
    final channel = api.parseM3u(playlist).single;
    expect(channel.supportsReplay, isTrue);
    expect(channel.timeshift, const Duration(hours: 48));
  });

  test('le groupe et le nom restent intacts après la lecture des attributs', () {
    const playlist = '''
#EXTINF:-1 group-title="Italie" catchup="default" catchup-days="7",|IT| RAI 1
http://panel.example/live/201.ts
''';
    final channel = api.parseM3u(playlist).single;
    expect(channel.group, 'Italie');
    expect(channel.name, '|IT| RAI 1');
  });
}
