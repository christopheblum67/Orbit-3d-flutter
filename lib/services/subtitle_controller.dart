import 'package:flutter/material.dart';
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

  Future<void> loadAndSetTrack(String url,
      {String language = 'und', String? label,}) async {
    final result = await safeAsync<void>(
      () async {
        final track = await SubtitleParser.parseFromUrl(url,
            language: language, label: label,);
        _loadedTracks[url] = track;
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

  /// Active une piste *déclarée* par le panel, en la téléchargeant d'abord.
  ///
  /// Une piste découverte ne contient aucun cue : la sélectionner consiste donc
  /// à la charger puis à l'activer.
  Future<void> selectDiscoveredTrack(SubtitleTrackRef ref) async {
    await loadAndSetTrack(ref.url, language: ref.language, label: ref.label);
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
