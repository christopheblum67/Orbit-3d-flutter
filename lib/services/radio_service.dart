import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Lecteur audio pour les stations de radio Xtream.
///
/// Suit la redirection HTTP (/u/p/{id} → HLS ou MP3 hébergé sur un CDN
/// externe), expose l'état de chargement et propage les erreurs de façon
/// lisible pour l'utilisateur (flux indisponible côté hébergeur).
class RadioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  String? get error => _error;

  Future<void> play(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.play();
      // just_audio se connecte vraiment au moment du play : on attend un peu
      // pour détecter un échec réseau de l'hébergeur externe.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (_player.playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
        _error =
            'Impossible de lancer cette station. Le signal de l\'hébergeur '
            'est peut-être indisponible. Réessaie ou choisis une autre '
            'station.';
      }
    } on Exception {
      _isPlaying = false;
      _error =
          'Flux radio indisponible. Le serveur d\'hébergement de cette '
          'station ne répond pas. Réessaie ou choisis une autre station.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _error = null;
    _isLoading = false;
    _isPlaying = false;
    await _player.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
