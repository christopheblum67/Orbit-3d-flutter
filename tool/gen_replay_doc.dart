// Générateur du document de référence Replay/Catch-up.
// Extraction fidèle (commentaires compris) des sources concernées :
// de la récupération des données du catch-up jusqu’à l’affichage.
// Usage : dart run tool/gen_replay_doc.dart
import 'dart:io';

void main() {
  final b = StringBuffer();
  void w(String s) => b.writeln(s);

  void code(String path, int a, int e) {
    final lines = File(path).readAsLinesSync();
    w('```dart');
    for (var i = a; i <= e && i <= lines.length; i++) {
      w(lines[i - 1]);
    }
    w('```');
  }

  void h(String path, int a, int e, String title) {
    w('');
    w('### $title');
    w('');
    w('`$path`  (lignes $a-$e)');
    w('');
    code(path, a, e);
  }

  const api = 'lib/services/api_service.dart';
  const prov = 'lib/providers/providers.dart';

  w('# Replay / Catch-up — de la récupération des données à l’affichage');
  w('');
  w('Document de référence généré depuis le code source (extraction fidèle, commentaires compris).');
  w('');
  w('## 0. Vue d’ensemble du pipeline');
  w('');
  w('```text');
  w('DONNÉES (panneau)                     CODE                                    AFFICHAGE');
  w('─────────────────────────────────────────────────────────────────────────────────────────');
  w('XMLTV global (dump) ─┐');
  w('                     ├─► ApiService.buildReplaysFromGlobalEpg ─┐');
  w('get_live_streams ────┘   (programmes TERMINÉS + supportsReplay) │');
  w('                                                                ├─► mergeReplays ─► replaysProvider ─► (cache)');
  w('get_short_epg ─► _fetchChannelReplayPrograms ─► replaysCache ───┘        │');
  w('  (sonde en tâche de fond : replaysProbeProvider)                       ▼');
  w('                                                                ReplayScreen (niveau 1 : chaînes)');
  w('                                                                        │  (tap chaîne)');
  w('get_simple_data_table ─► _fetchChannelFullEpg ─► fetchChannelReplays ─► channelReplaysProvider');
  w('      (repli) get_short_epg ─► _fetchChannelReplayPrograms                  │');
  w('                                                                            ▼');
  w('                                                                ReplayScreen (niveau 2 : jours + programmes)');
  w('                                                                        │  (tap programme)');
  w('replayStreamUrl : catchup-source (template) sinon /timeshift/…          ▼');
  w('                                                                /player (lecture)');
  w('');
  w('Chemin EPG (rattrapage depuis la grille) :');
  w('  EPG grille ─(appui long chaîne)─► CatchUpScreen ─► channelCatchUpProvider');
  w('             ─► fetchChannelEpgPrograms (get_short_epg) ─► _pastPrograms ─► tap ─► replayStreamUrl ─► /player');
  w('```');
  w('');
  w('## 1. Modèles de données');
  w('');
  w('### 1.1 `Channel` — attributs de replay (reçus de `get_live_streams`)');
  w('');
  w('`lib/models/channel.dart`  (lignes 1-163)');
  w('');
  code('lib/models/channel.dart', 1, 163);
  h('lib/models/replay_item.dart', 1, 82, '1.2 `ReplayItem` — un programme rejouable');
  h('lib/models/epg_program.dart', 1, 139, '1.3 `EPGProgram` — un programme EPG');
  h('lib/features/epg/replay_utils.dart', 1, 14, '1.4 `isReplayableProgram` — la règle « rejouable »');
  w('');
  w('## 2. Récupération des données — `ApiService`');
  w('');
  h(api, 1415, 1430, '2.1 Constantes de la fenêtre de replay');
  h(api, 1432, 1543, '2.2 Source 1 — EPG global : `buildReplaysFromGlobalEpg` + `mergeReplays`');
  h(api, 1545, 1701, '2.3 Source 2 — sonde : `fetchReplays`, `_fetchXtreamReplays`, `replayProbeSet`');
  h(api, 1991, 2136, '2.4 `_fetchChannelReplayPrograms` (get_short_epg)');
  h(api, 1769, 1990, '2.5 Source 3 — EPG complet d’une chaîne : `fetchChannelReplays`, `_fetchChannelFullEpg`, `replayStreamUrl`, `archiveWindow`');
  h(api, 1714, 1773, '2.6 EPG d’une chaîne : `fetchChannelEpgPrograms`');
  h(api, 2138, 2159, '2.7 Replay M3U + `_parseReplayDate`');
  h(api, 2204, 2228, '2.8 `_formatReplayTime`');
  w('');
  w('## 3. Construction de l’URL de replay (catch-up)');
  w('');
  h('lib/services/catchup_url_builder.dart', 1, 140, '3.1 `CatchupUrl` — template `catchup-source`');
  h(api, 2446, 2474, '3.2 `buildXtreamTimeshiftUrl` — convention Xtream (repli)');
  w('');
  w('## 4. Providers Riverpod (caches + états)');
  w('');
  h(prov, 762, 944, '4.1 `ReplaysCache`, `replaysProvider`, `replaysProbeProvider`, `channelReplaysProvider`');
  h(prov, 1119, 1179, '4.2 `channelCatchUpProvider` (+ `_pastPrograms`)');
  w('');
  w('## 5. Affichage');
  w('');
  h('lib/features/replay/replay_screen.dart', 1, 806, '5.1 `ReplayScreen` (niveau 1 : chaînes · niveau 2 : programmes)');
  h('lib/features/epg/widgets/catch_up_screen.dart', 1, 451, '5.2 `CatchUpScreen` (rattrapage depuis l’EPG)');
  w('');
  w('## 6. Points d’entrée et routes');
  w('');
  h('lib/main.dart', 663, 673, '6.1 Route `/replay`');
  h('lib/features/epg/epg_screen.dart', 620, 655, '6.2 Depuis la grille EPG (appui long sur une chaîne)');
  w('');
  w('## 7. Points de vigilance (résumé des commentaires du code)');
  w('');
  w('- **Deux formats d’URL** : le template `catchup-source` du provider prime ; `buildXtreamTimeshiftUrl` n’est qu’un repli (durée en minutes, date `YYYY-MM-DD:HH-mm`).');
  w('- **`get_short_epg` n’est pas la source du Replay** : il plafonne à 4 entrées futures ; la source complète est l’EPG global (XMLTV) et, par chaîne, `get_simple_data_table`.');
  w('- **Fenêtre** : `archiveWindow(channel)` = `tv_archive_duration` / `catchup-days` sinon 48 h. Un 48 h en dur filtrait à tort les replays d’un compte à 7/14 jours.');
  w('- **Budget anti-429** : la sonde est plafonnée (`replayProbeSet` : budget 40, 3 par groupe, concurrence 2) — sonder tout le catalogue déclenche l’anti-leech et vide EPG/Films.');
  w('- **Décodage base64** : titres et synopsis passent par `PanelText.decode` (les deux appels d’EPG encodent en base64 sur ce panneau).');
  w('- **Lecture** : l’URL finale passe par `replayStreamUrl` (template d’abord), puis `/player` avec `contentType: replay`.');

  final out = File('docs/replay-catchup-reference.md');
  out.writeAsStringSync(b.toString());
  stdout.writeln('wrote ${out.path} (${b.length} chars)');
}
