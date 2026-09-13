import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Contrôleur pour gérer le chargement et la sélection des pistes de sous-titres.
class SubtitleController extends ChangeNotifier {
  SubtitleTrack? _activeTrack;
  final Map<String, SubtitleTrack> _loadedTracks = {};

  SubtitleTrack? get activeTrack => _activeTrack;
  List<SubtitleTrack> get availableTracks => _loadedTracks.values.toList();

  Future<void> loadAndSetTrack(String url, {String language = 'und', String? label}) async {
    try {
      final track = await SubtitleParser.parseFromUrl(url, language: language, label: label);
      _loadedTracks[url] = track;
      _activeTrack = track;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load subtitle: $e');
      rethrow;
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