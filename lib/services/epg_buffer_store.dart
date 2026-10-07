import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:path_provider/path_provider.dart';

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
  static const int _formatVersion = 1;

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
          .toList();

  /// Relit le tampon, ou `null` s'il est absent, illisible, trop vieux ou d'un
  /// format inconnu.
  ///
  /// Toute erreur est un `null` et non une exception : un tampon corrompu doit
  /// coûter un téléchargement, pas une grille cassée.
  Future<List<EPGProgram>?> read(
    String cacheKey, {
    Duration maxAgeLimit = maxAge,
  }) async {
    final result = await safeAsync<Map<String, dynamic>?>(
      () async {
        final file = File('${(await _dir()).path}/${fileNameFor(cacheKey)}');
        if (!file.existsSync()) return null;
        final writtenAt = DateTime.fromMillisecondsSinceEpoch(
          file.lastModifiedSync().millisecondsSinceEpoch,
        );
        if (DateTime.now().difference(writtenAt) > maxAgeLimit) return null;
        return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      },
      context: 'EpgBufferStore.read',
      fallbackValue: null,
    );
    final data = result.valueOrNull;
    if (data == null) return null;
    if (data['v'] != _formatVersion) return null;
    final writtenAt = data['writtenAt'];
    final list = data['programs'];
    if (writtenAt is! int || list is! List) return null;
    if (DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(writtenAt)) >
        maxAgeLimit) {
      return null;
    }
    try {
      return [
        for (final item in list)
          if (item is Map<String, dynamic>)
            EPGProgram(
              channelId: item['c'] as String? ?? '',
              title: item['t'] as String? ?? '',
              description: item['d'] as String? ?? '',
              start: DateTime.fromMillisecondsSinceEpoch(item['s'] as int),
              end: DateTime.fromMillisecondsSinceEpoch(item['e'] as int),
            ),
      ];
    } on Object {
      // Champ manquant ou mal typé : tampon inexploitable, on le disregard.
      return null;
    }
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
          'writtenAt': DateTime.now().millisecondsSinceEpoch,
          'programs': [
            for (final p in programs)
              {
                'c': p.channelId,
                't': p.title,
                'd': p.description,
                's': p.start.millisecondsSinceEpoch,
                'e': p.end.millisecondsSinceEpoch,
              },
          ],
        });
        await temp.writeAsString(payload, flush: true);
        await temp.rename(target.path);
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

  @visibleForTesting
  void resetDirectoryCacheForTests() => _cachedDir = null;

  /// Impose le répertoire du tampon.
  ///
  /// `path_provider` passe par Pigeon, dont le mock est hors de portée depuis un
  /// test unitaire ; on rend donc le point d'entrée injectable au lieu de
  /// dépendre d'un canal de plateforme dans la logique du tampon.
  @visibleForTesting
  void debugSetDirectory(String path) => _cachedDir = path;
}