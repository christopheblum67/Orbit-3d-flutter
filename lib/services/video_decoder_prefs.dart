import 'package:shared_preferences/shared_preferences.dart';

enum VideoDecoderMode { auto, hardware, software }

/// Stratégie de décodage vidéo, valable pour tout appareil.
///
/// - Auto : matériel d'abord. Si le matériel échoue et qu'un nouvel essai en
///   logiciel réussit, on le retient ; après [_learnThreshold] cas, ce modèle
///   d'appareil passe en logiciel d'abord.
/// - Matériel / Logiciel : choix manuel.
class VideoDecoderPrefs {
  VideoDecoderPrefs._();

  static const _modeKey = 'video_decoder_mode';
  static const _recoveredKey = 'video_decoder_sw_recoveries';
  static const _learnThreshold = 2;

  static VideoDecoderMode _mode = VideoDecoderMode.auto;
  static int _recoveries = 0;
  static bool _loaded = false;

  /// Réessai ponctuel en logiciel, après un échec du décodeur matériel.
  static bool forceSoftwareOnce = false;

  static VideoDecoderMode get mode => _mode;
  static bool get learnedSoftware => _recoveries >= _learnThreshold;

  /// Valeur transmise au lecteur natif : 0 = matériel d'abord, 2 = logiciel
  /// d'abord.
  static int get nativeMode {
    if (forceSoftwareOnce) return 2;
    return switch (_mode) {
      VideoDecoderMode.software => 2,
      VideoDecoderMode.hardware => 0,
      VideoDecoderMode.auto => learnedSoftware ? 2 : 0,
    };
  }

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_modeKey);
      _mode = VideoDecoderMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => VideoDecoderMode.auto,
      );
      _recoveries = prefs.getInt(_recoveredKey) ?? 0;
    } catch (_) {}
    _loaded = true;
  }

  static Future<void> setMode(VideoDecoderMode mode) async {
    _mode = mode;
    _recoveries = 0;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, mode.name);
      await prefs.setInt(_recoveredKey, 0);
    } catch (_) {}
  }

  /// Le décodeur logiciel a réussi là où le matériel venait d'échouer.
  static Future<void> reportSoftwareRecovered() async {
    if (_mode != VideoDecoderMode.auto) return;
    _recoveries++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_recoveredKey, _recoveries);
    } catch (_) {}
  }
}
