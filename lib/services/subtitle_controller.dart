import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Contrôleur pour gérer le chargement et la sélection des pistes de sous-titres.
class SubtitleController extends ChangeNotifier {
  SubtitleTrack? _activeTrack;
  String? _activeTrackUrl;
  final Map<String, SubtitleTrack> _loadedTracks = {};

  /// Pistes adoptées depuis une source externe (recherche en ligne),
  /// indexées sur leur libellé faute d'URL connue.
  final Map<String, SubtitleTrack> _adoptedTracks = {};

  /// Pistes annoncées par le panel, discovery compris.
  ///
  /// On ne renvoie plus seulement [_loadedTracks] : l'onglet sous-titres
  /// affichait « aucune piste disponible » sur presque tous les films, parce
  /// que rien n'interrogeait le panel — la liste ne pouvait contenir que ce
  /// qui avait déjà été téléchargé, c'est-à-dire rien tant que l'utilisateur
  /// n'avait pas déjà choisi une piste (impossible, liste vide).
  final List<SubtitleTrackRef> _discovered = [];

  SubtitleTrack? get activeTrack => _activeTrack;

  /// URL de la piste active, pour comparer par identité et non par libellé.
  String? get activeTrackUrl => _activeTrackUrl;

  /// Pistes proposées à l'utilisateur : découverte d'abord, puis les pistes
  /// réellement chargées (une piste chargée peut venir d'une source externe,
  /// saisie manuelle, ou d'un flux live).
  List<SubtitleTrackRef> get availableTracks {
    final out = <SubtitleTrackRef>[];
    final seen = <String>{};

    // Les cues sont réinjectés : une piste découverte puis chargée doit
    // passer en « chargée » sans perdre sa position dans la liste.
    for (final t in _discovered) {
      if (!seen.add(t.url)) continue;
      out.add(SubtitleTrackRef(
        url: t.url,
        language: t.language,
        label: t.label,
        cues: _loadedTracks[t.url]?.cues,
      ));
    }
    for (final entry in _loadedTracks.entries) {
      if (!seen.add(entry.key)) continue;
      out.add(SubtitleTrackRef(
        url: entry.key,
        language: entry.value.language,
        label: entry.value.label,
        cues: entry.value.cues,
      ));
    }
    return out;
  }

  /// Renseigne les pistes annoncées par le panel.
  ///
  /// Volontairement tolérant : une réponse vide ou illisible laisse la liste
  /// précédente intacte plutôt que de la vider, pour qu'un échec réseau
  /// transitoire n'efface pas des pistes déjà connues.
  void setDiscovered(List<SubtitleTrackRef> tracks) {
    _discovered
      ..clear()
      ..addAll(tracks);
    notifyListeners();
  }

  Future<void> loadAndSetTrack(
    String url, {
    String language = 'und',
    String? label,
  }) async {
    final result = await safeAsync<void>(
      () async {
        final track = await SubtitleParser.parseFromUrl(
          url,
          language: language,
          label: label,
        );
        _loadedTracks[url] = track;
        _activeTrack = track;
        _activeTrackUrl = url;
        notifyListeners();
        // DIAGNOSTIC : la position d'un cue sert à distinguer « fichier vide »
        // d'un simple décalage avec la vidéo (voir ci-dessous).
        LoggerService.instance.info(
          'subs ok lang=$language cues=${track.cues.length} '
          'first=${_describeCue(track, 0)} '
          'last=${_describeCue(track, track.cues.length - 1)} '
          'file=${url.split('/').last}',
        );
      },
      context: 'SubtitleController.loadAndSetTrack',
    );
    if (result.isFailure) {
      throw result.errorOrNull!.originalError ?? result.errorOrNull!;
    }
  }

  /// Résultat de vérification d'une URL, mis en cache pour la session.
  ///
  /// `null` = pas encore testée. On ne mémorise que les issues DEFINITIVES
  /// (le fichier existe ou pas) : une erreur réseau ne doit pas faire
  /// disparaître une piste qui reviendra.
  static final Map<String, bool> _existsCache = {};

  /// L'URL est-elle mémorisée comme testée ?
  ///
  /// Exposé parce que le poison du cache n'est PAS observable à travers
  /// `verifyTracks` : les deux branches d'une panne réseau renvoient la même
  /// liste de pistes — seule la ligne en cache diffère. Sans cet accesseur,
  /// aucun test ne peut distinguer le comportement corrigé du bug.
  @visibleForTesting
  static bool isCached(String url) => _existsCache.containsKey(url);

  /// Ne conserve que les pistes dont le fichier existe réellement.
  ///
  /// Les pistes déduites sont des **hypothèses** : sur un panel qui ne déclare
  /// rien, on fabrique `{id}_fr.srt`, `{id}_fr_forced.srt`, `{id}_en.srt`… et
  /// le panel n'en sert souvent aucune. Les afficher toutes donnait une liste
  /// de quatre entrées dont l'utilisateur decouvrait l'inexistence en
  /// selectionnant — l'inverse de ce qu'une liste de pistes doit dire.
  ///
  /// ## Coût et exactitude
  ///
  /// Les candidats sont essayés **dans l'ordre, jusqu'au premier succès**, et
  /// l'on s'arrête là. Deux raisons, l'une économique et l'autre corrective :
  ///
  /// - auparavant, si la forme principale répondait vide, les replis n'étaient
  ///   jamais testés et la piste disparaissait — à tort, puisqu'elle pouvait
  ///   exister sous une autre forme d'URL ;
  /// - si la forme principale répondait, on testait *tous* les replis alors que
  ///   la sélection n'utiliserait que le premier. Chaque réponse positive
  /// inutile, sur un panel qui répond lentement.
  ///
  /// Le cas courant coûte donc une requête par piste au lieu d'une requête
  /// plus tous les replis, et le cache de session rend les ouvertures
  /// suivantes gratuites.
  ///
  /// [onProgress] reçoit le nombre de pistes restantes, pour afficher un
  /// avancement plutôt qu'un écran figé.
  Future<List<SubtitleTrackRef>> verifyTracks(
    List<SubtitleTrackRef> tracks, {
    void Function(int remaining)? onProgress,
  }) async {
    final kept = <SubtitleTrackRef>[];
    var probes = 0;
    for (var i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final candidates = track.candidates;
      SubtitleTrackRef? hit;
      var hitIndex = -1;
      for (var c = 0; c < candidates.length; c++) {
        probes++;
        if (await _exists(candidates[c])) {
          hit = candidates[c];
          hitIndex = c;
          break;
        }
      }

      if (hit != null) {
        // On ne garde que les candidats *jusqu'au* premier qui répond : les
        // suivants n'ont pas servi et seraient retestés à la sélection.
        //
        // Le candidat gagnant devient l'URL principale de la piste : c'est lui
        // que l'utilisateur choisira, et pour éviter de retester une forme morte.
        final verified = candidates.sublist(0, hitIndex + 1);
        kept.add(
          verified.length == 1
              ? hit
              : track.copyWith(
                  url: hit.url,
                  language: hit.language,
                  alternates: verified.skip(1).toList(),
                ),
        );
      }
      onProgress?.call(tracks.length - i - 1);
    }
    LoggerService.instance.info(
      'Sous-titres : ${tracks.length} piste(s) déduites, $probes requête(s) '
      'de vérification, ${kept.length} retenue(s)',
      tag: 'subtitle',
    );
    return kept;
  }

  /// Le fichier de cette piste répond-il avec un vrai sous-titre ?
  Future<bool> _exists(SubtitleTrackRef ref) async {
    final cached = _existsCache[ref.url];
    if (cached != null) return cached;

    final result = await safeAsync<SubtitleTrack>(
      () => SubtitleParser.parseFromUrl(
        ref.url,
        language: ref.language,
        label: ref.label,
      ),
      context: 'SubtitleController._exists',
    );
    final error = result.errorOrNull?.originalError;

    // Seule une réponse VIDE (ou un 4xx/5xx, que le parseur convertit en
    // `SubtitlePayloadException`) prouve l'absence : c'est une conclusion
    // DÉFINITIVE, donc mémorable.
    if (error is SubtitlePayloadException) {
      _existsCache[ref.url] = false;
      return false;
    }

    // Erreur RÉSEAU : on ne sait rien. Le code inversait les deux et
    // inscrivait `true`, ce qui rendait une piste « vérifiée » pour toute la
    // session — sur un cache statique sans TTL, dont la clé contient les
    // identifiants du panel, donc jamais invalide au changement de compte.
    // Le commentaire affirmait déjà le contraire de ce que le code faisait.
    if (error != null) {
      LoggerService.instance.warning(
        'Sous-titre: vérification inconclusive pour ${ref.url}',
        error: error,
      );
      return true;
    }

    _existsCache[ref.url] = true;
    return true;
  }

  /// Active une piste *déclarée* par le panel, en la téléchargeant d'abord.
  ///
  /// Une piste découverte ne contient aucun cue : la sélectionner consiste donc
  /// à la charger puis à l'activer.
  Future<void> selectDiscoveredTrack(SubtitleTrackRef ref) async {
    await loadAndSetTrack(ref.url, language: ref.language, label: ref.label);
  }

  /// Décrit un cue pour le journal de diagnostic.
  static String _describeCue(SubtitleTrack track, int index) {
    if (index < 0 || index >= track.cues.length) return '-';
    final c = track.cues[index];
    return '${c.startMs}-${c.endMs} "${c.text.length > 40 ? c.text.substring(0, 40) : c.text}"';
  }

/// Adopte une piste déjà téléchargée (recherche en ligne).
  ///
  /// Le contrôleur ne connaissait que les pistes qu'il avait lui-même
  /// chargées depuis une URL : sans cette porte d'entrée, un sous-titre
  /// trouvé en ligne ne pouvait pas être activé une fois téléchargé.
  void adoptTrack(SubtitleTrack track, String label) {
    // L'URL n'est pas connue ici ; la piste est indexée sur son libellé, ce qui
    // suffit à l'identifier pour l'affiche et à la désactivation.
    _adoptedTracks[label] = track;
    _activeTrack = track;
    _activeTrackUrl = label;
    notifyListeners();
  }

  void setActiveTrack(String url) {
    final track = _loadedTracks[url] ?? _adoptedTracks[url];
    if (track == null) return;
    _activeTrack = track;
    _activeTrackUrl = url;
    notifyListeners();
  }

  void disable() {
    _activeTrack = null;
    _activeTrackUrl = null;
    notifyListeners();
  }

  void clearCache() {
    _loadedTracks.clear();
    _activeTrack = null;
    _activeTrackUrl = null;
    notifyListeners();
  }
}
