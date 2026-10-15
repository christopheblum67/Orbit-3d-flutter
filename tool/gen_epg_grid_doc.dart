// Générateur des fiches de référence « EPG — grille ».
//
// Même principe que tool/gen_replay_doc.dart (extraction fidèle du code,
// commentaires compris), mais DÉCOUPÉ en plusieurs fichiers courts :
//  - un fichier par couche logique (modèles, providers, grille, écran…) ;
//  - chaque fichier est borné à [_maxFileCodeLines] lignes de code : au-delà,
//    il est paginé en « part1 », « part2 »… ;
//  - à l'intérieur, chaque bloc est borné à [_maxCodeLines] lignes.
// Résultat : aucun copier-coller ne dépasse [_maxCodeLines] lignes de code.
//
// Usage : dart run tool/gen_epg_grid_doc.dart
// Sortie : docs/epg-grid/*.md
//
// `require_trailing_commas` est ignoré : ce script enchaîne des tableaux de
// sources courts, la virgule finale n'apporte rien et alourdirait la lecture.
// ignore_for_file: require_trailing_commas
import 'dart:io';

/// Lignes de code maximum par bloc copiable.
const int _maxCodeLines = 200;

/// Lignes de code maximum par fichier de sortie (au-delà : pagination).
const int _maxFileCodeLines = 400;

const String _outDir = 'docs/epg-grid';

/// Un morceau de code à documenter.
class _Block {
  _Block(this.title, this.path, this.a, this.e);
  final String title;
  final String path;
  final int a;
  final int e;
  int get length => e - a + 1;
}

List<String> _lines(String path) => File(path).readAsLinesSync();

int _find(List<String> lines, String needle, {int from = 1}) {
  for (var i = from; i <= lines.length; i++) {
    if (lines[i - 1].contains(needle)) return i;
  }
  throw StateError('Marqueur introuvable : "$needle"');
}

// --- état du chapitre en cours -------------------------------------------
List<_Block> _blocks = <_Block>[];
String _chapterTitle = '';
String _chapterSources = '';

void _startChapter(String title, List<String> sources) {
  _blocks = <_Block>[];
  _chapterTitle = title;
  _chapterSources = sources.map((s) => '`$s`').join(', ');
}

void _whole(String path, String title) {
  _blocks.add(_Block(title, path, 1, _lines(path).length));
}

void _section(String path, String title,
    {required String from, required String to}) {
  final lines = _lines(path);
  final a = _find(lines, from);
  final end = _find(lines, to, from: a + 1);
  _blocks.add(_Block(title, path, a, end - 1));
}

void _oneLine(String path, String marker, String title) {
  final a = _find(_lines(path), marker);
  _blocks.add(_Block(title, path, a, a));
}

/// Écrit [a]..[e] dans [buf], scindé en blocs de [_maxCodeLines] lignes.
void _appendCode(StringBuffer buf, String path, int a, int e) {
  final lines = _lines(path);
  final last = e > lines.length ? lines.length : e;
  final parts = ((last - a + 1) / _maxCodeLines).ceil();
  var start = a;
  var part = 1;
  while (start <= last) {
    final stop = (start + _maxCodeLines - 1) > last
        ? last
        : start + _maxCodeLines - 1;
    buf.writeln('');
    buf.writeln('#### `$path` · lignes $start–$stop · partie $part/$parts');
    buf.writeln('');
    buf.writeln('```dart');
    for (var i = start; i <= stop; i++) {
      buf.writeln(lines[i - 1]);
    }
    buf.writeln('```');
    start = stop + 1;
    part++;
  }
}

/// Découpe les blocs du chapitre en fichiers bornés, écrits sur disque.
/// Renvoie les noms de fichiers produits.
List<String> _flushChapter(int num, String slug) {
  // 1. Découpe préalable de tout bloc plus gros qu'un fichier : sinon un seul
  //    fichier source (la grille, 1400 lignes) resterait d'un seul tenant.
  final expanded = <_Block>[];
  for (final bl in _blocks) {
    if (bl.length <= _maxFileCodeLines) {
      expanded.add(bl);
      continue;
    }
    final suiteCount = (bl.length / _maxFileCodeLines).ceil();
    var a = bl.a;
    var k = 1;
    while (a <= bl.e) {
      final e = (a + _maxFileCodeLines - 1) > bl.e
          ? bl.e
          : a + _maxFileCodeLines - 1;
      expanded.add(
        _Block('${bl.title} — suite $k/$suiteCount', bl.path, a, e),
      );
      a = e + 1;
      k++;
    }
  }

  // 2. Empilement en fichiers bornés.
  final packs = <List<_Block>>[];
  var current = <_Block>[];
  var used = 0;
  for (final bl in expanded) {
    if (current.isNotEmpty && used + bl.length > _maxFileCodeLines) {
      packs.add(current);
      current = <_Block>[];
      used = 0;
    }
    current.add(bl);
    used += bl.length;
  }
  if (current.isNotEmpty) packs.add(current);

  final names = <String>[];
  for (var i = 0; i < packs.length; i++) {
    final part = i + 1;
    final name = packs.length == 1
        ? '${num.toString().padLeft(2, '0')}-$slug.md'
        : '${num.toString().padLeft(2, '0')}-$slug-part$part.md';
    final buf = StringBuffer();
    buf.writeln('# $_chapterTitle');
    if (packs.length > 1) {
      buf.writeln('');
      buf.writeln('> **Partie $part/${packs.length}**');
    }
    buf.writeln('');
    buf.writeln('> Fiche générée depuis le code source — extraction fidèle, '
        'commentaires compris. Chaque bloc est limité à $_maxCodeLines lignes '
        'pour rester copiable sans saturer le presse-papier.');
    if (_chapterSources.isNotEmpty) {
      buf.writeln('');
      buf.writeln('Sources : $_chapterSources');
    }
    for (final bl in packs[i]) {
      buf.writeln('');
      buf.writeln('### ${bl.title}');
      buf.writeln('');
      buf.writeln('`${bl.path}` · lignes ${bl.a}–${bl.e}');
      _appendCode(buf, bl.path, bl.a, bl.e);
    }
    final f = File('$_outDir/$name');
    f.writeAsStringSync(buf.toString());
    stdout.writeln('wrote ${f.path} (${buf.length} chars)');
    names.add(name);
  }
  return names;
}

/// Manifeste pour l'index : (numéro, titre, fichiers produits).
final List<String> _manifest = <String>[];

void _chapter(int num, String slug, String title, List<String> sources) {
  final names = _flushChapter(num, slug);
  final label = names.length == 1 ? names.first : '${names.first} … ${names.last}';
  _manifest.add('| $num | $title | $label |');
}

void main() {
  final dir = Directory(_outDir);
  dir.createSync(recursive: true);
  // Purge des fiches précédentes (les noms changent selon le découpage).
  for (final f in dir.listSync()) {
    if (f is File && f.path.endsWith('.md')) f.deleteSync();
  }

  const epgScreen = 'lib/features/epg/epg_screen.dart';
  const gridView = 'lib/features/epg/widgets/epg_grid_2d_view.dart';
  const prov = 'lib/providers/providers.dart';
  const api = 'lib/services/api_service.dart';

  // --------------------------------------------------------------- 1
  _startChapter('EPG — grille : 1. modèles et utilitaires purs', [
    'lib/models/epg_program.dart',
    'lib/models/epg_models.dart',
    'lib/models/epg_search.dart',
    'lib/core/utils/epg_day_window.dart',
    'lib/core/utils/epg_lookup.dart',
    'lib/features/epg/replay_utils.dart',
  ]);
  _whole('lib/models/epg_program.dart', '1.1 `EPGProgram` — un programme EPG');
  _whole('lib/models/epg_models.dart', '1.2 `epg_models` — types annexes');
  _whole('lib/models/epg_search.dart', '1.3 `epg_search` — modèle de recherche');
  _whole('lib/core/utils/epg_day_window.dart',
      '1.4 Fenêtre de jour (`epg_day_window`)');
  _whole('lib/core/utils/epg_lookup.dart', '1.5 Lookup EPG (`epg_lookup`)');
  _whole('lib/features/epg/replay_utils.dart',
      '1.6 `isReplayableProgram` — la règle « rejouable »');
  _chapter(1, 'modeles', '1. modèles et utilitaires purs', [
    'lib/models/epg_program.dart',
    'lib/models/epg_models.dart',
    'lib/models/epg_search.dart',
    'lib/core/utils/epg_day_window.dart',
    'lib/core/utils/epg_lookup.dart',
    'lib/features/epg/replay_utils.dart',
  ]);

  // --------------------------------------------------------------- 2
  _startChapter('EPG — grille : 2. cache et providers Riverpod', [
    prov,
    'lib/services/short_epg_service.dart',
  ]);
  _section(prov, '2.1 `EPGDataCache` — le dump XMLTV indexé par chaîne',
      from: 'class EPGDataCache', to: 'final epgDataCacheProvider');
  _section(prov, '2.2 Caches et providers EPG (court, précharge)',
      from: 'final epgDataCacheProvider',
      to: "/// Programmes **terminés** d'une chaîne pour le rattrapage");
  _section(prov,
      '2.3 `_resolveChannelEpg` — cœur de la résolution (grille + lecteur)',
      from: '/// Cherche une entrée du cache court',
      to: 'class EPGProgramsNotifier');
  _section(prov, '2.4 `EPGProgramsNotifier` — dump global partagé',
      from: 'class EPGProgramsNotifier',
      to: '/// Moniteur de connectivité temps réel');
  _whole('lib/services/short_epg_service.dart',
      '2.5 `ShortEpgCache` + `EpgPreloadService`');
  _chapter(2, 'cache-providers', '2. cache et providers Riverpod', [prov]);

  // --------------------------------------------------------------- 3
  _startChapter('EPG — grille : 3. récupération (ApiService) et parseurs', [
    api,
    'lib/services/epg_stream_parser.dart',
    'lib/services/epg_buffer_store.dart',
  ]);
  _section(api, '3.1 `fetchEpg` — dump XMLTV global (+ décodage)',
      from: '// ---------- EPG (XMLTV) ----------',
      to: "/// Décode une réponse JSON dont l'encodage HTTP est absent ou faux");
  _section(api, '3.2 Décodage XMLTV (`_decodeXmltvPayload`, `_decodeCharset`)',
      from: 'static String _decodeXmltvPayload', to: 'static String _trimBaseUrl');
  _oneLine(api, 'List<EPGProgram> parseXmltv(String content)',
      '3.3 `parseXmltv` — délégation au parseur de flux');
  _section(api, '3.4 EPG d’une chaîne — aperçu court + parseur commun',
      from: "/// Programmes EPG d'une chaîne via",
      to: "/// EPG **complet** d'une chaîne (passé compris)");
  _section(api, '3.5 EPG complet d’une chaîne — source du rattrapage',
      from: "/// EPG **complet** d'une chaîne (passé compris)",
      to: "/// Programmes rejouables d'**une seule** chaîne");
  _whole('lib/services/epg_stream_parser.dart',
      '3.6 `EpgStreamParser` — parseur XMLTV');
  _whole('lib/services/epg_buffer_store.dart', '3.7 `epg_buffer_store` — tampon EPG');
  _chapter(3, 'api-epg', '3. récupération (ApiService) et parseurs', [api]);

  // --------------------------------------------------------------- 4
  _startChapter('EPG — grille : 4. la grille 2D', [
    gridView,
    'lib/features/epg/widgets/epg_row_diagnostics.dart',
  ]);
  _whole(gridView, '4.1 `EpgGrid2dView` — la grille');
  _whole('lib/features/epg/widgets/epg_row_diagnostics.dart',
      '4.2 `epg_row_diagnostics` — diagnostics de ligne');
  _chapter(4, 'grille-2d', '4. la grille 2D',
      [gridView, 'lib/features/epg/widgets/epg_row_diagnostics.dart']);

  // --------------------------------------------------------------- 5
  _startChapter('EPG — grille : 5. timeline, gestes et en-têtes', [
    'lib/features/epg/widgets/epg_timeline.dart',
    'lib/features/epg/widgets/epg_timeline_controller.dart',
    'lib/features/epg/widgets/epg_scroll_gesture.dart',
    'lib/features/epg/widgets/epg_headbar.dart',
    'lib/features/epg/widgets/epg_mini_program_bar.dart',
    'lib/features/epg/widgets/epg_preview_header.dart',
  ]);
  _whole('lib/features/epg/widgets/epg_timeline.dart',
      '5.1 `epg_timeline` — échelle horaire');
  _whole('lib/features/epg/widgets/epg_timeline_controller.dart',
      '5.2 `epg_timeline_controller` — contrôle d’échelle/défilement');
  _whole('lib/features/epg/widgets/epg_scroll_gesture.dart',
      '5.3 `epg_scroll_gesture` — gestes de défilement');
  _whole('lib/features/epg/widgets/epg_headbar.dart',
      '5.4 `epg_headbar` — barre de titre/filtres');
  _whole('lib/features/epg/widgets/epg_mini_program_bar.dart',
      '5.5 `epg_mini_program_bar` — aperçu programme survolé');
  _whole('lib/features/epg/widgets/epg_preview_header.dart',
      '5.6 `epg_preview_header` — aperçu programme sélectionné');
  _chapter(5, 'timeline-headers', '5. timeline, gestes et en-têtes', []);

  // --------------------------------------------------------------- 6
  _startChapter('EPG — grille : 6. l’écran EPG', [epgScreen]);
  _whole(epgScreen, '6.1 `EpgScreen`');
  _chapter(6, 'ecran-epg', '6. l’écran EPG', [epgScreen]);

  // --------------------------------------------------------------- 7
  _startChapter('EPG — grille : 7. rattrapage et recherche', [
    'lib/features/epg/widgets/catch_up_screen.dart',
    'lib/utils/epg_search.dart',
    'lib/utils/epg_gap_filler.dart',
    'lib/services/epg_ai_search.dart',
  ]);
  _whole('lib/features/epg/widgets/catch_up_screen.dart',
      '7.1 `CatchUpScreen` — rattrapage depuis la grille');
  _whole('lib/utils/epg_search.dart', '7.2 `epg_search` — recherche locale');
  _whole('lib/utils/epg_gap_filler.dart', '7.3 `epg_gap_filler` — comblement de trous');
  _whole('lib/services/epg_ai_search.dart', '7.4 `epg_ai_search` — recherche IA');
  _chapter(7, 'rattrapage-recherche', '7. rattrapage et recherche', []);

  // --------------------------------------------------------------- 8
  _startChapter('EPG — grille : 8. annexe — orbite 3D', [
    'lib/features/epg/widgets/constellation_dual_screen.dart',
    'lib/features/epg/widgets/favorites_orbit_system_3d.dart',
    'lib/features/epg/widgets/gravity_focus_node.dart',
    'lib/features/epg/widgets/nebula_search_space.dart',
    'lib/features/epg/widgets/orbit_planet_node.dart',
  ]);
  _whole('lib/features/epg/widgets/constellation_dual_screen.dart',
      '8.1 `constellation_dual_screen`');
  _whole('lib/features/epg/widgets/favorites_orbit_system_3d.dart',
      '8.2 `favorites_orbit_system_3d`');
  _whole('lib/features/epg/widgets/gravity_focus_node.dart',
      '8.3 `gravity_focus_node`');
  _whole('lib/features/epg/widgets/nebula_search_space.dart',
      '8.4 `nebula_search_space`');
  _whole('lib/features/epg/widgets/orbit_planet_node.dart',
      '8.5 `orbit_planet_node`');
  _chapter(8, 'orbite-3d-annexe', '8. annexe — orbite 3D', []);

  // --------------------------------------------------------------- index
  final index = StringBuffer();
  index.writeln('# EPG — grille : index');
  index.writeln();
  index.writeln('> Fiches générées par `tool/gen_epg_grid_doc.dart` (extraction '
      'fidèle du code, commentaires compris). Découpage : un fichier par couche, '
      'borné à $_maxFileCodeLines lignes de code, puis chaque bloc borné à '
      '$_maxCodeLines lignes — un copier-coller ne dépasse jamais cette taille.');
  index.writeln();
  index.writeln('## Pipeline de la grille EPG');
  index.writeln();
  index.writeln('```text');
  index.writeln('DONNÉES (panneau)              CODE                                      AFFICHAGE');
  index.writeln('───────────────────────────────────────────────────────────────────────────────────');
  index.writeln('xmltv.php (dump ~94k) ─► fetchEpg ─► EpgStreamParser.parse (isolate)');
  index.writeln('                                      │');
  index.writeln('                                      ▼');
  index.writeln('                                EPGDataCache.loadFull ─┐');
  index.writeln('                                                        ▼');
  index.writeln('get_short_epg ─► fetchChannelEpgPrograms ─► shortEpg  _resolveChannelEpg');
  index.writeln('                                          Cache       (cache court → XMLTV');
  index.writeln('                                                       → repli réseau borné)');
  index.writeln('                                                          │');
  index.writeln('        ┌─────────────────────────────────────────────────┼──────────────────┐');
  index.writeln('        ▼                        ▼                                 ▼');
  index.writeln(' channelEpgWindowProvider   channelEpgProvider            EPGProgramsNotifier');
  index.writeln('  (GRILLE, passé compris,    (barre lecteur :              (dump global partagé)');
  index.writeln('   AUCUN réseau)              « en cours + à venir »)');
  index.writeln('        │');
  index.writeln('        ▼');
  index.writeln(' EpgGrid2dView ◄─ EpgTimeline (heures) ◄─ EpgHeadbar / EpgScrollGesture');
  index.writeln('        ├─ EpgMiniProgramBar / EpgPreviewHeader');
  index.writeln('        └─ appui long sur une CHAÎNE ─► CatchUpScreen');
  index.writeln('             └─ channelCatchUpProvider ─► fetchChannelCatchUpPrograms');
  index.writeln('                                          (get_simple_data_table)');
  index.writeln('```');
  index.writeln();
  index.writeln('## Fiches');
  index.writeln();
  index.writeln('| # | Couche | Fichiers |');
  index.writeln('|---|--------|----------|');
  for (final m in _manifest) {
    index.writeln(m);
  }
  index.writeln();
  index.writeln('## Note de découpage');
  index.writeln();
  index.writeln('- Les fiches `…-partN.md` sont des **morceaux du même module** : à '
      'lire/coller dans l’ordre.');
  index.writeln('- Les numéros de ligne sont ceux du dépôt au moment de la génération ; '
      'relancer le générateur après une modification du code.');
  File('$_outDir/00-index.md').writeAsStringSync(index.toString());
  stdout.writeln('wrote $_outDir/00-index.md (${index.length} chars)');
  stdout.writeln('Terminé : $_outDir');
}
