import 'package:just_audio/just_audio.dart';

class RadioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String url) async {
    await _player.setUrl(url);
    _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }
}
