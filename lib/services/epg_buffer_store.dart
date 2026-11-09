import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:path_provider/path_provider.dart';

/// Lit et reconstruit les programmes hors du thread d'interface.
Future<List<EPGProgram>?> _readBufferInIsolate(
  ({String path, int nowMs, int maxAgeMs, int formatVersion}) args,
) async {
  final file = File(args.path);
  if (!await file.exists()) return null;
  final now = DateTime.fromMillisecondsSinceEpoch(args.nowMs);
  final modified = await file.lastModified();
  if (now.difference(modified).inMilliseconds > args.maxAgeMs) return null;
  final data = jsonDecode(await file.readAsString());
  if (data is! Map<String, dynamic> || data['v'] != args.formatVersion) {
    return null;
  }
  final writtenAt = data['writtenAt'];
  final list = data['programs'];
  if (writtenAt is! int || list is! List) return null;
  final written = DateTime.fromMillisecondsSinceEpoch(writtenAt);
  if (now.difference(written).inMilliseconds > args.maxAgeMs ||
      written.year != now.year ||
      written.month != now.month ||
      written.day != now.day) {
    return null;
  }
  return [
    for (final item in list)
      if (item is Map<String, dynamic>)
        EPGProgram(
          channelId: item['c'] as String? ?? '',
          title: item['t'] as String? ?? '',
          description: EpgBufferStore._clip(item['d'] as String? ?? ''),
          start: DateTime.fromMillisecondsSinceEpoch(item['s'] as int),
          end: DateTime.fromMillisecondsSinceEpoch(item['e'] as int),
        ),
  ];
}

/// Tampon EPG local : évite de retélécharger le dump XMLTV à chaque session.
///
/// ## Pourquoi
///
/// Le dump XMLTV fait plusieurs dizaines de mégaoctets pour ~394 000 programmes,
/// dont la quasi-totalité est inutile : seuls les programmes de la fenêtre
/// affichée servent. Sans persistance, l'application retéléchargeait et
/// reparsait l'intégralité du dump à CHAQUE session, puis le jetait à la
/// fermeture — le_download du même contenu, endlessly.
///
/// C'est aussi ce que fait TiviMate, joueur de référence sur Android TV : cache
/// EPG local, persistant entre les redémarrages, rafraîchi sur un intervalle
/// choisi (12 h est son compromis recommandé pour 200–500 chaînes) plutôt qu'à
/// chaque lancement.
///
/// ## Pourquoi un format JSON simple
///
/// Choix délibérément minimal : le format binaire ou compressé serait plus
/// compact, mais la taille réelle n'a PAS été mesurée sur l'appareil. On écrit
/// du JSON lisible, on relève la taille sur le terrain, et on n'optimise que si
/// la mesure le justifie. Optimiser avant de mesurer produirait un format
/// plus compliqué pour un gain supposé.
///
/// ## Ce qui n'est PAS écrit
///
/// Les blocs de comblage (`EpgGapFiller`) : ils sont régénérés au rendu, et les
/// persister gonflerait le fichier pour rien. Le drapeau `isDummy` n'est donc
/// pas stocké — ce qui est écrit est réel par construction.
class EpgBufferStore {
  EpgBufferStore._();

  static final EpgBufferStore instance = EpgBufferStore._();

  /// Version du format : permet d'invalider un fichier ancien sans le lire.
  ///
  /// Passé à 2 après la correction du parseur XMLTV. Les tampons v1 contiennent
  /// des programmes dont le TITRE est vide — le parseur cherchait le littéral
  /// `<title>` et le XMLTV réel écrit `<title lang="fr">`. Ces fichiers sont
  /// parfaitement lisibles, donc aucune erreur ne les ferait rejeter : il
  /// fallait invalider explicitement des données par ailleurs valides mais
  /// vides de contenu.
  static const int _formatVersion = 2;

  /// Rafraîchissement par défaut.
  ///
  /// 12 h : au-delà, un changement de programmation du matin peut manquer, et
  /// en deçà on retélécharge pour rien puisque les diffuseurs verrouillent
  /// souvent leur grille 24 h à l'avance.
  static const Duration maxAge = Duration(hours: 12);

  /// Fenêtre conservée, depuis minuit.
  ///
  /// La grille représente une journée entière, donc 24 h suffisent ; 30 h
  /// couvrent la journée affichée plus une marge de défilement. On ne garde pas
  /// les semaines du dump.
  static const int horizonHours = 30;

  String? _cachedDir;

  /// Horloge du tampon, injectable pour les tests.
  ///
  /// Le défaut verrouillé par `epg_buffer_store_test` tient à un changement de
  /// JOUR : la seule façon de le reproduire sans attendre minuit est de
  /// déplacer l'horloge.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  Future<Directory> _dir() async {
    final known = _cachedDir;
    if (known != null) return Directory(known);
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/epg_buffer');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _cachedDir = dir.path;
    return dir;
  }

  /// Nom de fichier dérivé de l'abonnement, sans caractère interdit.
  String fileNameFor(String cacheKey) {
    var hash = 0;
    for (final unit in cacheKey.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return 'epg_$hash.json';
  }

  /// Programme à écrire dans le tampon.
  ///
  /// `end` après `windowStart` ET avant `horizon` : la borne basse est minuit,
  /// pas « maintenant », sinon la matinée affichée disparaît au chargement.
  static List<EPGProgram> project(
    List<EPGProgram> programs, {
    required DateTime windowStart,
    required DateTime horizon,
  }) =>
      programs
          .where((p) => p.end.isAfter(windowStart) && p.end.isBefore(horizon))
          .map(
            (p) => p.description.length <= _maxDescriptionChars
                ? p
                : EPGProgram(
                    channelId: p.channelId,
                    title: p.title,
                    description: _clip(p.description),
                    start: p.start,
                    end: p.end,
                  ),
          )
          .toList();

  /// Vrai si un tampon du jour, assez récent, est présent (sans le lire).
  /// Permet au démarrage de ne pas attendre le guide.
  Future<bool> hasUsable(
    String cacheKey, {
    Duration maxAgeLimit = maxAge,
  }) async {
    final result = await safeAsync<bool>(
      () async {
        final file = File('${(await _dir()).path}/${fileNameFor(cacheKey)}');
        if (!file.existsSync()) return false;
        final modifiedAt = file.lastModifiedSync();
        final now = clock();
        return now.difference(modifiedAt) <= maxAgeLimit &&
            _sameLocalDay(modifiedAt, now);
      },
      context: 'EpgBufferStore.hasUsable',
      fallbackValue: false,
    );
    return result.valueOrNull ?? false;
  }

  /// Relit le tampon, ou `null` s'il est absent, illisible, trop vieux ou d'un
  /// format inconnu.
  ///
  /// Toute erreur est un `null` et non une exception : un tampon corrompu doit
  /// coûter un téléchargement, pas une grille cassée.
  Future<List<EPGProgram>?> read(
    String cacheKey, {
    Duration maxAgeLimit = maxAge,
  }) async {
    int? fileBytes;
    final result = await safeAsync<List<EPGProgram>?>(
      () async {
        final file = File('${(await _dir()).path}/${fileNameFor(cacheKey)}');
        if (!await file.exists()) return null;
        fileBytes = await file.length();
        return compute(
          _readBufferInIsolate,
          (
            path: file.path,
            nowMs: clock().millisecondsSinceEpoch,
            maxAgeMs: maxAgeLimit.inMilliseconds,
            formatVersion: _formatVersion,
          ),
        );
      },
      context: 'EpgBufferStore.read',
      fallbackValue: null,
    );
    final parsed = result.valueOrNull;
    if (parsed != null) {
      LoggerService.instance.info(
        'EPG tampon: ${parsed.length} programmes, '
        '${_humanSize(fileBytes ?? 0)} sur disque',
      );
    }
    return parsed;
  }

  /// Écrit le tampon.
  ///
  /// Écriture par fichier temporaire puis renommage : une coupure au milieu
  /// laisserait un JSON tronqué, qui serait lu au démarrage suivant comme une
  /// donnée valide — et affiché comme une grille à moitié vide.
  Future<void> write(String cacheKey, List<EPGProgram> programs) async {
    await safeAsync<void>(
      () async {
        final dir = await _dir();
        final target = File('${dir.path}/${fileNameFor(cacheKey)}');
        final temp = File('${target.path}.tmp');
        final payload = jsonEncode({
          'v': _formatVersion,
          'writtenAt': clock().millisecondsSinceEpoch,
          'programs': [
            for (final p in programs)
              {
                'c': p.channelId,
                't': p.title,
                'd': _clip(p.description),
                's': p.start.millisecondsSinceEpoch,
                'e': p.end.millisecondsSinceEpoch,
              },
          ],
        });
        await temp.writeAsString(payload, flush: true);
        await temp.rename(target.path);
        // Taille réellement écrite : c'est le seul chiffre qui décide si le
        // format mérite d'être compressé. On le mesure, on ne le devine pas.
        LoggerService.instance.info(
          'EPG tampon: ${programs.length} programmes, '
          '${_humanSize(target.lengthSync())} écrits',
        );
      },
      context: 'EpgBufferStore.write',
    );
  }

  /// Supprime le tampon d'un abonnement (changement d'abonnement, vidage).
  Future<void> clear(String cacheKey) async {
    await safeAsync<void>(
      () async {
        final file = File('${(await _dir()).path}/${fileNameFor(cacheKey)}');
        if (file.existsSync()) file.deleteSync();
      },
      context: 'EpgBufferStore.clear',
    );
  }

  /// Supprime TOUS les tampons EPG (changement d'abonnement, réinitialisation complète).
  Future<void> clearAll() async {
    await safeAsync<void>(
      () async {
        final dir = await _dir();
        for (final file in dir.listSync()) {
          if (file is File &&
              file.path.contains('epg_') &&
              file.path.endsWith('.json')) {
            file.deleteSync();
          }
        }
      },
      context: 'EpgBufferStore.clearAll',
    );
  }

  @visibleForTesting
  void resetDirectoryCacheForTests() => _cachedDir = null;

  /// Vrai si [a] et [b] tombent le même jour civil, en heure locale.
  ///
  /// Volontairement en heure locale : la fenêtre du tampon est calée sur
  /// `EpgDayWindow`, qui est locale (le guide doit afficher l'heure du
  /// téléspectateur).
  static bool _sameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Les descriptions dominent la taille du tampon ; sur une TV à 2 Go,
  /// 167 000 descriptions complètes saturent la mémoire.
  static const int _maxDescriptionChars = 160;

  static String _clip(String text) => text.length <= _maxDescriptionChars
      ? text
      : '${text.substring(0, _maxDescriptionChars)}…';

  /// Taille lisible, sans l'unité « octets » qui masque l'ordre de grandeur.
  static String _humanSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '$bytes o';
  }

  /// Impose le répertoire du tampon.
  ///
  /// `path_provider` passe par Pigeon, dont le mock est hors de portée depuis un
  /// test unitaire ; on rend donc le point d'entrée injectable au lieu de
  /// dépendre d'un canal de plateforme dans la logique du tampon.
  @visibleForTesting
  void debugSetDirectory(String path) => _cachedDir = path;
}
