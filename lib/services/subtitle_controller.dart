import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Contrôleur pour gérer le chargement et la sélection des pistes de sous-titres.
class SubtitleController extends ChangeNotifier {
  SubtitleTrack? _activeTrack;
  final Map<String, SubtitleTrack> _loadedTracks = {};

  SubtitleTrack? get activeTrack => _activeTrack;
  List<SubtitleTrack> get availableTracks => _loadedTracks.values.toList();

  Future<void> loadAndSetTrack(String url, {String language = 'und', String? label}) async {
    final result = await safeAsync<void>(
      () async {
        final track = await SubtitleParser.parseFromUrl(url, language: language, label: label);
        _loadedTracks[url] = track;
        _activeTrack = track;
        notifyListeners();
      },
      context: 'SubtitleController.loadAndSetTrack',
    );
    if (result.isFailure) {
      throw result.errorOrNull!.originalError ?? result.errorOrNull!;
    }
  }

  void setActiveTrack(String url) {
    if (_loadedTracks.containsKey(url)) {
      _activeTrack = _loadedTracks[url];
      notifyListeners();
    }
  }

  void disable() {
    _activeTrack = null;
    notifyListeners();
  }

  void clearCache() {
    _loadedTracks.clear();
    _activeTrack = null;
    notifyListeners();
  }
}