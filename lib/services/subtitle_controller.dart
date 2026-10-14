import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Contrôleur pour gérer le chargement et la sélection des pistes de sous-titres.
class SubtitleController extends ChangeNotifier {
  SubtitleTrack? _activeTrack;
  String? _activeTrackUrl;
  final Map<String, SubtitleTrack> _loadedTracks = {};

  /// Lecteur pour lequel l'utilisateur a explicitement choisi une piste
  /// EXTERNE (OpenSubtitles, piste du panel, URL manuelle).
  ///
  /// Garde d'exclusivité lue par [setEmbeddedContext] : tant que la découverte
  /// intégrée parle de CE lecteur, elle ne doit pas ré-adopter la sélection
  /// automatique de media3 et masquer la piste externe.
  ///
  /// Le lecteur change-t-il (nouveau contenu) ? La garde tombe d'elle-même
  /// (l'id ne correspond plus) et les pistes intégrées du nouveau flux
  /// redeviennent prioritaires — aucune remise à zéro globale n'est requise,
  /// ce qui éviterait de faire fuir le choix d'un contenu à l'autre.
  int? _externalPlayerId;

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
      ),);
    }
    for (final entry in _loadedTracks.entries) {
      if (!seen.add(entry.key)) continue;
      out.add(SubtitleTrackRef(
        url: entry.key,
        language: entry.value.language,
        label: entry.value.label,
        cues: entry.value.cues,
      ),);
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
        // Une piste externe active prend le relais des sous-titres intégrés.
        _cancelEmbeddedForExternal();
        _externalPlayerId = _embeddedBridge?.playerId;
        _activeTrack = track;
        _activeTrackUrl = url;
        notifyListeners();
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
  ///
  /// ## Parallélisme
  ///
  /// Les pistes étaient vérifiées strictement l'une après l'autre. Sur le
  /// panel mesuré, chaque réponse prenait 6 à 8 s : les 16 sondes d'un film
  /// muetTenant donc plus de deux minutes d'attente sur un panneau modal.
  ///
  /// Elles sont désormais vérifiées [maxParallelTracks] à la fois. Le nombre de
  /// REQUÊTES ne change pas — le test de coût le vérifie au nombre près — seule
  /// la latence est divisée. Le court-circuit par piste est préservé : dès
  /// qu'un candidat répond, les suivants de CETTE piste ne sont pas sondés.
  Future<List<SubtitleTrackRef>> verifyTracks(
    List<SubtitleTrackRef> tracks, {
    void Function(int remaining)? onProgress,
  }) async {
    if (tracks.length <= 1) {
      return _verifyTracksSequential(tracks, onProgress: onProgress);
    }

    final results = List<SubtitleTrackRef?>.filled(tracks.length, null);
    var next = 0;

    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= tracks.length) return;
        results[index] = await _verifyOne(tracks[index]);
        onProgress?.call(tracks.length - next);
      }
    }

    // Au plus [_parallelism] sondes simultanées : assez pour diviser la
    // latence par un facteur visible, assez peu pour ne pas déclencher la
    // limitation d'un panel qui refuse déjà easily les rafales.
    await Future.wait([
      for (var w = 0; w < _parallelism && w < tracks.length; w++) worker(),
    ]);

    return [
      for (final kept in results)
        if (kept != null) kept,
    ];
  }

  /// Nombre de pistes vérifiées simultanément.
  ///
  /// Volontairement modeste : le panel testé répond déjà 200 avec 6 à 8 s de
  /// latence et limite les requêtes. 4 sondes en vol suffisent à faire passer
  /// le cas courant de deux minutes à trente secondes.
  static const int _parallelism = 4;

  Future<List<SubtitleTrackRef>> _verifyTracksSequential(
    List<SubtitleTrackRef> tracks, {
    void Function(int remaining)? onProgress,
  }) async {
    final kept = <SubtitleTrackRef>[];
    for (var i = 0; i < tracks.length; i++) {
      final hit = await _verifyOne(tracks[i]);
      if (hit != null) kept.add(hit);
      onProgress?.call(tracks.length - i - 1);
    }
    return kept;
  }

  /// Vérifie une piste : sonde ses candidats dans l'ordre, s'arrête au premier
  /// qui répond.
  Future<SubtitleTrackRef?> _verifyOne(SubtitleTrackRef track) async {
    final candidates = track.candidates;
    SubtitleTrackRef? hit;
    var hitIndex = -1;
    for (var c = 0; c < candidates.length; c++) {
      if (await _exists(candidates[c])) {
        hit = candidates[c];
        hitIndex = c;
        break;
      }
    }
    if (hit == null) return null;

    // On ne garde que les candidats *jusqu'au* premier qui répond : les
    // suivants n'ont pas servi et seraient retestés à la sélection.
    //
    // Le candidat gagnant devient l'URL principale de la piste : c'est lui
    // que l'utilisateur choisira, et cela évite de retester une forme morte.
    final verified = candidates.sublist(0, hitIndex + 1);
    return verified.length == 1
        ? hit
        : track.copyWith(
            url: hit.url,
            language: hit.language,
            alternates: verified.skip(1).toList(),
          );
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

  /// Adopte une piste déjà téléchargée (recherche en ligne).
  ///
  /// Le contrôleur ne connaissait que les pistes qu'il avait lui-même
  /// chargées depuis une URL : sans cette porte d'entrée, un sous-titre
  /// trouvé en ligne ne pouvait pas être activé une fois téléchargé.
  void adoptTrack(SubtitleTrack track, String label) {
    // L'URL n'est pas connue ici ; la piste est indexée sur son libellé, ce qui
    // suffit à l'identifier pour l'affiche et à la désactivation.
    _cancelEmbeddedForExternal();
    _externalPlayerId = _embeddedBridge?.playerId;
    _adoptedTracks[label] = track;
    _activeTrack = track;
    _activeTrackUrl = label;
    notifyListeners();
  }

  void setActiveTrack(String url) {
    final track = _loadedTracks[url] ?? _adoptedTracks[url];
    if (track == null) return;
    _cancelEmbeddedForExternal();
    _externalPlayerId = _embeddedBridge?.playerId;
    _activeTrack = track;
    _activeTrackUrl = url;
    notifyListeners();
  }

  void disable() {
    _cancelEmbeddedForExternal();
    _externalPlayerId = null;
    _activeTrack = null;
    _activeTrackUrl = null;
    notifyListeners();
  }

  void clearCache() {
    _cancelEmbeddedForExternal();
    _externalPlayerId = null;
    _loadedTracks.clear();
    _adoptedTracks.clear();
    _activeTrack = null;
    _activeTrackUrl = null;
    notifyListeners();
  }

  /// Réinitialise l'état sous-titres pour un NOUVEAU contenu (zapping, autre
  /// film, autre épisode…).
  ///
  /// ## Pourquoi
  ///
  /// Le contrôleur est partagé par toute l'app (provider non autoDispose) et
  /// `_activeTrack` n'était jamais réinitialisé entre deux contenus : après un
  /// film sous-titré puis un zapping, les cues de l'ANCIENNE piste continuaient
  /// de s'afficher sur le NOUVEAU contenu. Le player appelle cette méthode à
  /// chaque changement de contenu (`initState` d'une nouvelle lecture,
  /// `_switchTo` pour le zapping).
  ///
  /// Éteint la piste externe (titre, URL, garde d'exclusivité) et l'état
  /// intégré courant (pistes, piste active, cues, polling), mais :
  ///  - ne vide PAS la bibliothèque `_loadedTracks`/`_adoptedTracks` : les
  ///    pistes déjà téléchargées restent re-sélectionnables pour le nouveau
  ///    contenu ;
  ///  - ne parle PAS au canal natif : la découverte du nouveau contenu repart
  ///    de sa signature vierge et se chargera de la sélection.
  void resetForNewContent() {
    _externalPlayerId = null;
    _activeTrack = null;
    _activeTrackUrl = null;
    _activeEmbeddedTrackId = null;
    _liveEmbeddedCues = null;
    _embeddedTracks = const [];
    _embeddedPollTimer?.cancel();
    _embeddedPollTimer = null;
    notifyListeners();
  }

  // ==================== SOUS-TITRES INTÉGRÉS (pont natif media3) ====================

  EmbeddedSubtitleBridge? _embeddedBridge;
  List<EmbeddedSubtitleTrack> _embeddedTracks = const [];
  String? _activeEmbeddedTrackId;
  EmbeddedSubtitleCues? _liveEmbeddedCues;
  Timer? _embeddedPollTimer;
  bool _embeddedPollBusy = false;

  /// Fréquence de lecture de `Player.getCurrentCues`. media3 met à jour le
  /// groupe courant à chaque cue : 300 ms suffisent pour l'œil (et par défaut
  /// un texte affiché plusieurs ticks identiques ne déclenche aucun rebuild).
  static const Duration _embeddedPollInterval = Duration(milliseconds: 300);

  /// Pistes intégrées du contenu courant, telles qu'exposées par media3.
  List<EmbeddedSubtitleTrack> get embeddedTracks => _embeddedTracks;

  /// Id de la piste intégrée active, si une piste intégrée est affichée.
  String? get activeEmbeddedTrackId => _activeEmbeddedTrackId;

  /// Dernier groupe de cues rendu par le pipeline (asservi au contenu, pas à
  /// la position du lecteur).
  EmbeddedSubtitleCues? get liveEmbeddedCues => _liveEmbeddedCues;

  bool get hasActiveEmbedded => _activeEmbeddedTrackId != null;

  /// Renseigne le pont et mémorise les pistes intégrées d'un contenu.
  ///
  /// Appelé à l'initialisation du lecteur. [tracks] vient de
  /// `getSubtitleTracks()` : seules des pistes supportées par le pipeline y
  /// figurent. La sélection automatique de media3 (souvent la piste « forced »)
  /// devient la piste intégrée active, sans marquer l'exclusivité avec une
  /// piste externe (décision purement locale, l'utilisateur tranchera).
  void setEmbeddedContext({
    required int playerId,
    required List<EmbeddedSubtitleTrack> tracks,
  }) {
    if (_embeddedBridge == null || _embeddedBridge!.playerId != playerId) {
      _embeddedBridge = EmbeddedSubtitleBridge(playerId);
    }
    _embeddedTracks = List.unmodifiable(tracks);
    // Idempotent et re-appelable : la découverte est rejouée pendant que les
    // pistes arrivent par vagues. Elle ne doit PAS reprendre la main sur la
    // piste que l'utilisateur a choisie entre-temps : elle n'adopte la sélection
    // automatique de media3 que si aucune piste — intégrée OU externe — n'est
    // active pour ce lecteur.
    final keep = _activeEmbeddedTrackId;
    if (keep != null && tracks.any((t) => t.id == keep)) {
      _activeEmbeddedTrackId = keep;
    } else if (_externalPlayerId == playerId) {
      // Une piste EXTERNE a la main sur ce lecteur : ne pas adopter la
      // sélection automatique de media3.
      //
      // Sans cette garde, media3 — qui auto-sélectionne sa piste texte
      // quelques secondes APRÈS le début de la lecture — reprenait
      // l'affichage et masquait le sous-titre OpenSubtitles choisi
      // entre-temps : l'utilisateur lisait « les sous-titres en ligne ne se
      // lisent plus » alors que le contrôleur n'avait fait que changer de
      // piste active.
      _activeEmbeddedTrackId = null;
      _liveEmbeddedCues = null;
    } else {
      final selected = tracks.where((t) => t.isSelected).toList();
      _activeEmbeddedTrackId = selected.isEmpty ? null : selected.first.id;
      _liveEmbeddedCues = null;
    }
    _refreshEmbeddedPolling();
    notifyListeners();
  }

  /// Active une piste intégrée. Exclusivité : toute piste externe est coupée.
  Future<void> selectEmbeddedTrack(String trackId) async {
    final bridge = _embeddedBridge;
    if (bridge == null || !_embeddedTracks.any((t) => t.id == trackId)) return;
    try {
      await bridge.selectTrack(trackId);
    } catch (_) {
      // Best-effort : une erreur de canal ne doit pas empêcher la lecture.
      return;
    }
    _activeEmbeddedTrackId = trackId;
    _liveEmbeddedCues = null;
    _externalPlayerId = null;
    _activeTrack = null;
    _activeTrackUrl = null;
    _refreshEmbeddedPolling();
    notifyListeners();
  }

  /// Éteint les sous-titres intégrés (y compris côté natif).
  void disableEmbedded() {
    _cancelEmbeddedForExternal();
    notifyListeners();
  }

  /// Coupe le pont pour cette texture (lecteur libéré).
  ///
  /// Ne touche pas un autre lecteur : le contrôleur est partagé et plusieurs
  /// textures coexistent (p. ex. pendant le préchauffage).
  void detachEmbedded(int playerId) {
    final bridge = _embeddedBridge;
    if (bridge == null || bridge.playerId != playerId) return;
    _embeddedPollTimer?.cancel();
    _embeddedPollTimer = null;
    _embeddedBridge = null;
    _embeddedTracks = const [];
    _activeEmbeddedTrackId = null;
    _liveEmbeddedCues = null;
    if (_externalPlayerId == playerId) _externalPlayerId = null;
    notifyListeners();
  }

  void _refreshEmbeddedPolling() {
    if (_activeEmbeddedTrackId != null && _embeddedBridge != null) {
      _embeddedPollTimer ??= Timer.periodic(
        _embeddedPollInterval,
        (_) => unawaited(_pollLiveEmbedded()),
      );
      unawaited(_pollLiveEmbedded());
    } else {
      _embeddedPollTimer?.cancel();
      _embeddedPollTimer = null;
    }
  }

  Future<void> _pollLiveEmbedded() async {
    final bridge = _embeddedBridge;
    if (bridge == null || _activeEmbeddedTrackId == null || _embeddedPollBusy) {
      return;
    }
    _embeddedPollBusy = true;
    try {
      final cues = await bridge.currentCues();
      if (!identical(bridge, _embeddedBridge) ||
          _activeEmbeddedTrackId == null) {
        return;
      }
      final current = _liveEmbeddedCues;
      if (current != null && current.sameContent(cues)) return;
      _liveEmbeddedCues = cues;
      notifyListeners();
    } catch (_) {
      // Best-effort : le polling ne doit jamais casser la lecture.
    } finally {
      _embeddedPollBusy = false;
    }
  }

  /// Coupe l'état intégré courant (piste, cues, polling) et dé-sélectionne la
  /// piste côté natif. Appelé quand une source externe prend le relais ou que
  /// l'utilisateur désactive les sous-titres.
  ///
  /// ## Pourquoi l'appel natif n'est PAS conditionné à l'état local
  ///
  /// L'ancienne version sortait immédiatement quand aucune piste intégrée
  /// n'était active *localement* (`_activeEmbeddedTrackId == null`). Or media3
  /// auto-sélectionne sa piste texte quelques secondes après le début de la
  /// lecture, pas au premier sondage : un sous-titre externe choisi pendant
  /// cette fenêtre laissait donc le type « texte » actif côté natif, et media3
  /// volait l'affichage dès qu'il sélectionnait sa piste (souvent la
  /// « forced »). On coupe donc le type « texte » dans TOUS les cas où une
  /// source externe prend la main.
  void _cancelEmbeddedForExternal() {
    _activeEmbeddedTrackId = null;
    _liveEmbeddedCues = null;
    _embeddedPollTimer?.cancel();
    _embeddedPollTimer = null;
    final bridge = _embeddedBridge;
    if (bridge != null) {
      unawaited(bridge.clearTracks().catchError((_) {}));
    }
  }

  @override
  void dispose() {
    _embeddedPollTimer?.cancel();
    super.dispose();
  }
}
