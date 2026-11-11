import 'dart:async';

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
  String? _url;
  bool _wanted = false;
  bool _reconnecting = false;
  int _generation = 0;
  StreamSubscription<PlayerState>? _stateSub;

  static const _maxConnectAttempts = 2;
  static const _maxReconnects = 3;

  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  String? get error => _error;

  RadioService() {
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
  }

  void _onPlayerState(PlayerState state) {
    final playing = state.playing &&
        (state.processingState == ProcessingState.ready ||
            state.processingState == ProcessingState.buffering);
    if (!_reconnecting && !_isLoading && playing != _isPlaying) {
      _isPlaying = playing;
      notifyListeners();
    }
    // Coupure du flux alors que l'utilisateur écoute encore : on se reconnecte.
    if (_wanted &&
        !_reconnecting &&
        !_isLoading &&
        (state.processingState == ProcessingState.idle ||
            state.processingState == ProcessingState.completed)) {
      unawaited(_reconnect());
    }
  }

  Future<void> _reconnect() async {
    final url = _url;
    if (url == null) return;
    final generation = _generation;
    _reconnecting = true;
    try {
      for (var attempt = 1; attempt <= _maxReconnects; attempt++) {
        await Future<void>.delayed(Duration(seconds: attempt));
        if (!_wanted || generation != _generation) return;
        if (await _connect(url, generation) == null) {
          _isPlaying = true;
          _error = null;
          notifyListeners();
          return;
        }
      }
      if (generation == _generation) {
        _wanted = false;
        _isPlaying = false;
        _error = 'Le flux radio a été interrompu et la reconnexion a échoué. '
            'Réessaie ou choisis une autre station.';
        notifyListeners();
      }
    } finally {
      _reconnecting = false;
    }
  }

  /// Retourne `null` si la lecture a démarré, sinon un message d'erreur.
  Future<String?> _connect(String url, int generation) async {
    for (var attempt = 1; attempt <= _maxConnectAttempts; attempt++) {
      try {
        await _player.stop();
        await _player
            .setAudioSource(AudioSource.uri(Uri.parse(url)))
            .timeout(const Duration(seconds: 15));
        if (generation != _generation) return 'annulé';
        // `play()` ne se termine qu'à la fin de la lecture : ne pas l'attendre.
        unawaited(_player.play().catchError((Object _) {}));
        await _player.playerStateStream
            .firstWhere((s) =>
                s.playing && s.processingState == ProcessingState.ready)
            .timeout(const Duration(seconds: 12));
        return null;
      } on PlayerException catch (e) {
        final message = e.message ?? '';
        // Jeton expiré ou accès refusé : un nouvel essai identique est inutile.
        if (message.contains('403') || message.contains('401')) {
          return 'Accès refusé par le fournisseur (403). Rafraîchis '
              'l\'abonnement puis réessaie.';
        }
      } on Exception {
        // Délai dépassé ou autre échec réseau : nouvel essai ci-dessous.
      }
      if (generation != _generation) return 'annulé';
      if (attempt < _maxConnectAttempts) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
    return 'Impossible de lancer cette station. Le signal de l\'hébergeur '
        'est peut-être indisponible. Réessaie ou choisis une autre station.';
  }

  Future<void> play(String url) async {
    final generation = ++_generation;
    _url = url;
    _wanted = true;
    _isLoading = true;
    _isPlaying = false;
    _error = null;
    notifyListeners();
    final failure = await _connect(url, generation);
    if (generation != _generation) return;
    _isLoading = false;
    _isPlaying = failure == null;
    _error = failure;
    if (failure != null) _wanted = false;
    notifyListeners();
  }

  Future<void> stop() async {
    _generation++;
    _wanted = false;
    _error = null;
    _isLoading = false;
    _isPlaying = false;
    await _player.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _wanted = false;
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
