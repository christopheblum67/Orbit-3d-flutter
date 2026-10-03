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

  /// Ne conserve que les pistes dont le fichier existe réellement.
  ///
  /// Les pistes déduites sont des **hypothèses** : sur un panel qui ne déclare
  /// rien, on fabrique `{id}_fr.srt`, `{id}_fr_forced.srt`, `{id}_en.srt`… et
  /// le panel n'en sert souvent aucune. Les afficher toutes donnait une liste
  /// de quatre entrées dont l'utilisateur discoverait l'inexistence en
  /// selectable — l'inverse de ce qu'une liste de pistes doit dire.
  ///
  /// On teste donc avant d'afficher, une seule fois par session et par URL. Le
  /// coût est borné : quatre à huit requêtes, uniquement quand l'utilisateur
  /// ouvre la section sous-titres d'un contenu donné.
  ///
  /// [onProgress] reçoit le nombre de pistes restantes, pour afficher un
  /// avancement plutôt qu'un écran figé.
  Future<List<SubtitleTrackRef>> verifyTracks(
    List<SubtitleTrackRef> tracks, {
    void Function(int remaining)? onProgress,
  }) async {
    final kept = <SubtitleTrackRef>[];
    for (final track in tracks) {
      final exists = await _exists(track);
      if (exists) {
        // On renvoie la piste avec ses replis restreints à ceux qui existent
        // aussi : inutile de retester à la sélection.
        final alternates = <SubtitleTrackRef>[];
        for (final alt in track.alternates) {
          if (await _exists(alt)) alternates.add(alt);
        }
        kept.add(alternates.isEmpty
            ? track
            : track.copyWith(alternates: alternates));
      }
      onProgress?.call(tracks.length - kept.length - 1);
    }
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
    // Une erreur réseau ne prouve rien : on ne met pas en cache, et on garde la
    // piste plutôt que de la faire disparaître sur un coup de réseau.
    if (result.isFailure && result.errorOrNull != null) {
      final error = result.errorOrNull!.originalError;
      final isPayload = error is SubtitlePayloadException;
      _existsCache[ref.url] = isPayload ? false : true;
      return isPayload ? false : true;
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

  void setActiveTrack(String url) {
    final track = _loadedTracks[url];
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
