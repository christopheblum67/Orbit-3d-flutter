import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moteur de lecture sélectionnable pour chaque type de contenu.
///
/// `ExoPlayer (Interne)` correspond au lecteur embarqué (Media3) de l'application.
/// `libVLC` et `MX Player` sont des lecteurs externes déclenchés via un intent
/// Android (application installée sur le device).
enum PlayerEngine { exoPlayer, vlc, mxPlayer }

extension PlayerEngineX on PlayerEngine {
  String get label => switch (this) {
        PlayerEngine.exoPlayer => 'ExoPlayer (Interne)',
        PlayerEngine.vlc => 'libVLC (Externe)',
        PlayerEngine.mxPlayer => 'MX Player (Externe)',
      };

  /// `true` si ce moteur est une application externe (intent Android).
  bool get isExternal => this != PlayerEngine.exoPlayer;

  static PlayerEngine fromLabel(String? label) =>
      PlayerEngine.values.firstWhere((e) => e.label == label,
          orElse: () => PlayerEngine.exoPlayer,);
}

enum PlaybackContentType { live, vod, series, replay }

extension PlaybackContentTypeX on PlaybackContentType {
  String get label => switch (this) {
        PlaybackContentType.live => 'Live',
        PlaybackContentType.vod => 'VOD',
        PlaybackContentType.series => 'Séries',
        PlaybackContentType.replay => 'Replays',
      };
}

/// Configuration d'un lecteur pour un type de contenu : un moteur principal
/// (par défaut) et un moteur de secours (fallback) en cas d'échec.
class PlayerPerTypeConfig {
  const PlayerPerTypeConfig({
    this.primary = PlayerEngine.exoPlayer,
    this.fallback = PlayerEngine.vlc,
  });

  final PlayerEngine primary;
  final PlayerEngine fallback;

  PlayerPerTypeConfig copyWith({
    PlayerEngine? primary,
    PlayerEngine? fallback,
  }) {
    return PlayerPerTypeConfig(
      primary: primary ?? this.primary,
      fallback: fallback ?? this.fallback,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerPerTypeConfig &&
      other.primary == primary &&
      other.fallback == fallback;

  @override
  int get hashCode => Object.hash(primary, fallback);
}

/// Modèle immuable des réglages "avancés" (Réseau, Lecteur, Sécurité,
/// Ergonomie, IA). Persistés via [SharedPreferences].
class AdvancedSettings {
  // Réseau & Bypass
  final bool useTlsImpersonation;
  final String dnsProvider;
  final bool zeroLagPrefetch;

  // Lecteurs par type de contenu (moteur principal + moteur de secours).
  final PlayerPerTypeConfig playerLive;
  final PlayerPerTypeConfig playerVod;
  final PlayerPerTypeConfig playerSeries;
  final PlayerPerTypeConfig playerReplay;

  // Audio & Night Focus
  final bool nightFocusEnabled;
  final bool nightFocusDialogueBoost;
  final bool nightFocusBassKiller;
  final double nightFocusVocalGainDb;
  final int nightFocusAudioShiftMs;

  // Accessibilité
  final bool highContrast;

  const AdvancedSettings({
    this.useTlsImpersonation = true,
    this.dnsProvider = '1.1.1.1 (Cloudflare DoH)',
    this.zeroLagPrefetch = true,
    this.playerLive = const PlayerPerTypeConfig(
      primary: PlayerEngine.exoPlayer,
      fallback: PlayerEngine.vlc,
    ),
    this.playerVod = const PlayerPerTypeConfig(
      primary: PlayerEngine.exoPlayer,
      fallback: PlayerEngine.vlc,
    ),
    this.playerSeries = const PlayerPerTypeConfig(
      primary: PlayerEngine.exoPlayer,
      fallback: PlayerEngine.vlc,
    ),
    this.playerReplay = const PlayerPerTypeConfig(
      primary: PlayerEngine.exoPlayer,
      fallback: PlayerEngine.vlc,
    ),
    this.nightFocusEnabled = false,
    this.nightFocusDialogueBoost = true,
    this.nightFocusBassKiller = true,
    this.nightFocusVocalGainDb = 3.0,
    this.nightFocusAudioShiftMs = 0,
    this.highContrast = false,
  });

  AdvancedSettings copyWith({
    bool? useTlsImpersonation,
    String? dnsProvider,
    bool? zeroLagPrefetch,
    PlayerPerTypeConfig? playerLive,
    PlayerPerTypeConfig? playerVod,
    PlayerPerTypeConfig? playerSeries,
    PlayerPerTypeConfig? playerReplay,
    bool? nightFocusEnabled,
    bool? nightFocusDialogueBoost,
    bool? nightFocusBassKiller,
    double? nightFocusVocalGainDb,
    int? nightFocusAudioShiftMs,
    bool? highContrast,
  }) {
    return AdvancedSettings(
      useTlsImpersonation: useTlsImpersonation ?? this.useTlsImpersonation,
      dnsProvider: dnsProvider ?? this.dnsProvider,
      zeroLagPrefetch: zeroLagPrefetch ?? this.zeroLagPrefetch,
      playerLive: playerLive ?? this.playerLive,
      playerVod: playerVod ?? this.playerVod,
      playerSeries: playerSeries ?? this.playerSeries,
      playerReplay: playerReplay ?? this.playerReplay,
      nightFocusEnabled: nightFocusEnabled ?? this.nightFocusEnabled,
      nightFocusDialogueBoost:
          nightFocusDialogueBoost ?? this.nightFocusDialogueBoost,
      nightFocusBassKiller: nightFocusBassKiller ?? this.nightFocusBassKiller,
      nightFocusVocalGainDb:
          nightFocusVocalGainDb ?? this.nightFocusVocalGainDb,
      nightFocusAudioShiftMs:
          nightFocusAudioShiftMs ?? this.nightFocusAudioShiftMs,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  /// Récupère la configuration de lecteur du type de contenu demandé.
  PlayerPerTypeConfig configFor(PlaybackContentType type) => switch (type) {
        PlaybackContentType.live => playerLive,
        PlaybackContentType.vod => playerVod,
        PlaybackContentType.series => playerSeries,
        PlaybackContentType.replay => playerReplay,
      };

  /// Clés de persistance (partagées avec la page de référence).
  static const kTlsImpersonation = 'tls_impersonation';
  static const kDnsProvider = 'dns_provider';
  static const kZeroLagPrefetch = 'zero_lag_prefetch';

  // Clés de persistance des lecteurs par type de contenu (moteur par index).
  static const kPlayerEngine = 'player_engine';
  static const _kPrimary = 'primary';
  static const _kFallback = 'fallback';

  /// Index du type de contenu dans [PlaybackContentType.values].
  static String kPlayerPrimary(PlaybackContentType t) =>
      '$kPlayerEngine.$_kPrimary.${t.name}';
  static String kPlayerFallback(PlaybackContentType t) =>
      '$kPlayerEngine.$_kFallback.${t.name}';
  static const kNightFocus = 'night_focus';
  static const kNightFocusDialogueBoost = 'night_focus_dialogue_boost';
  static const kNightFocusBassKiller = 'night_focus_bass_killer';
  static const kNightFocusVocalGainDb = 'night_focus_vocal_gain_db';
  static const kNightFocusAudioShiftMs = 'night_focus_audio_shift_ms';
  static const kHighContrast = 'high_contrast';
}

class AdvancedSettingsNotifier extends StateNotifier<AdvancedSettings> {
  AdvancedSettingsNotifier() : super(const AdvancedSettings());

  SharedPreferences? _prefs;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    state = AdvancedSettings(
      useTlsImpersonation:
          prefs.getBool(AdvancedSettings.kTlsImpersonation) ?? true,
      dnsProvider: prefs.getString(AdvancedSettings.kDnsProvider) ??
          '1.1.1.1 (Cloudflare DoH)',
      zeroLagPrefetch: prefs.getBool(AdvancedSettings.kZeroLagPrefetch) ?? true,
      playerLive: _readPlayerConfig(
        prefs,
        PlaybackContentType.live,
      ),
      playerVod: _readPlayerConfig(prefs, PlaybackContentType.vod),
      playerSeries: _readPlayerConfig(prefs, PlaybackContentType.series),
      playerReplay: _readPlayerConfig(prefs, PlaybackContentType.replay),
      nightFocusEnabled: prefs.getBool(AdvancedSettings.kNightFocus) ?? false,
      nightFocusDialogueBoost: prefs.getBool(
            AdvancedSettings.kNightFocusDialogueBoost,
          ) ??
          true,
      nightFocusBassKiller:
          prefs.getBool(AdvancedSettings.kNightFocusBassKiller) ?? true,
      nightFocusVocalGainDb:
          prefs.getDouble(AdvancedSettings.kNightFocusVocalGainDb) ?? 3.0,
      nightFocusAudioShiftMs:
          prefs.getInt(AdvancedSettings.kNightFocusAudioShiftMs) ?? 0,
      highContrast: prefs.getBool(AdvancedSettings.kHighContrast) ?? false,
    );
  }

  Future<void> _persistBool(String key, bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(key, value);
  }

  Future<void> _persistString(String key, String value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(key, value);
  }

  Future<void> _persistDouble(String key, double value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(key, value);
  }

  Future<void> _persistInt(String key, int value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(key, value);
  }

  Future<void> setTlsImpersonation(bool value) async {
    state = state.copyWith(useTlsImpersonation: value);
    await _persistBool(AdvancedSettings.kTlsImpersonation, value);
  }

  Future<void> setDnsProvider(String value) async {
    state = state.copyWith(dnsProvider: value);
    await _persistString(AdvancedSettings.kDnsProvider, value);
  }

  Future<void> setPlayerPrimary(
    PlaybackContentType type,
    PlayerEngine engine,
  ) async {
    final current = state.configFor(type);
    state = state.copyWith(
      playerLive: type == PlaybackContentType.live
          ? current.copyWith(primary: engine)
          : state.playerLive,
      playerVod: type == PlaybackContentType.vod
          ? current.copyWith(primary: engine)
          : state.playerVod,
      playerSeries: type == PlaybackContentType.series
          ? current.copyWith(primary: engine)
          : state.playerSeries,
      playerReplay: type == PlaybackContentType.replay
          ? current.copyWith(primary: engine)
          : state.playerReplay,
    );
    await _persistString(
      AdvancedSettings.kPlayerPrimary(type),
      engine.name,
    );
  }

  Future<void> setPlayerFallback(
    PlaybackContentType type,
    PlayerEngine engine,
  ) async {
    final current = state.configFor(type);
    state = state.copyWith(
      playerLive: type == PlaybackContentType.live
          ? current.copyWith(fallback: engine)
          : state.playerLive,
      playerVod: type == PlaybackContentType.vod
          ? current.copyWith(fallback: engine)
          : state.playerVod,
      playerSeries: type == PlaybackContentType.series
          ? current.copyWith(fallback: engine)
          : state.playerSeries,
      playerReplay: type == PlaybackContentType.replay
          ? current.copyWith(fallback: engine)
          : state.playerReplay,
    );
    await _persistString(
      AdvancedSettings.kPlayerFallback(type),
      engine.name,
    );
  }

  Future<void> setZeroLagPrefetch(bool value) async {
    state = state.copyWith(zeroLagPrefetch: value);
    await _persistBool(AdvancedSettings.kZeroLagPrefetch, value);
  }

  Future<void> setNightFocus(bool value) async {
    state = state.copyWith(nightFocusEnabled: value);
    await _persistBool(AdvancedSettings.kNightFocus, value);
  }

  Future<void> setNightFocusDialogueBoost(bool value) async {
    state = state.copyWith(nightFocusDialogueBoost: value);
    await _persistBool(AdvancedSettings.kNightFocusDialogueBoost, value);
  }

  Future<void> setNightFocusBassKiller(bool value) async {
    state = state.copyWith(nightFocusBassKiller: value);
    await _persistBool(AdvancedSettings.kNightFocusBassKiller, value);
  }

  Future<void> setNightFocusVocalGainDb(double value) async {
    state = state.copyWith(nightFocusVocalGainDb: value);
    await _persistDouble(AdvancedSettings.kNightFocusVocalGainDb, value);
  }

  Future<void> setNightFocusAudioShiftMs(int value) async {
    state = state.copyWith(nightFocusAudioShiftMs: value);
    await _persistInt(AdvancedSettings.kNightFocusAudioShiftMs, value);
  }

  Future<void> setHighContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    await _persistBool(AdvancedSettings.kHighContrast, value);
  }

  Future<void> importFromJson(AdvancedSettings imported) async {
    state = imported;
    await _persistBool(AdvancedSettings.kTlsImpersonation, imported.useTlsImpersonation);
    await _persistString(AdvancedSettings.kDnsProvider, imported.dnsProvider);
    await _persistBool(AdvancedSettings.kZeroLagPrefetch, imported.zeroLagPrefetch);
    await _persistString(AdvancedSettings.kPlayerPrimary(PlaybackContentType.live), imported.playerLive.primary.name);
    await _persistString(AdvancedSettings.kPlayerFallback(PlaybackContentType.live), imported.playerLive.fallback.name);
    await _persistString(AdvancedSettings.kPlayerPrimary(PlaybackContentType.vod), imported.playerVod.primary.name);
    await _persistString(AdvancedSettings.kPlayerFallback(PlaybackContentType.vod), imported.playerVod.fallback.name);
    await _persistString(AdvancedSettings.kPlayerPrimary(PlaybackContentType.series), imported.playerSeries.primary.name);
    await _persistString(AdvancedSettings.kPlayerFallback(PlaybackContentType.series), imported.playerSeries.fallback.name);
    await _persistString(AdvancedSettings.kPlayerPrimary(PlaybackContentType.replay), imported.playerReplay.primary.name);
    await _persistString(AdvancedSettings.kPlayerFallback(PlaybackContentType.replay), imported.playerReplay.fallback.name);
    await _persistBool(AdvancedSettings.kNightFocus, imported.nightFocusEnabled);
    await _persistBool(AdvancedSettings.kNightFocusDialogueBoost, imported.nightFocusDialogueBoost);
    await _persistBool(AdvancedSettings.kNightFocusBassKiller, imported.nightFocusBassKiller);
    await _persistDouble(AdvancedSettings.kNightFocusVocalGainDb, imported.nightFocusVocalGainDb);
    await _persistInt(AdvancedSettings.kNightFocusAudioShiftMs, imported.nightFocusAudioShiftMs);
    await _persistBool(AdvancedSettings.kHighContrast, imported.highContrast);
  }
}

final advancedSettingsProvider =
    StateNotifierProvider<AdvancedSettingsNotifier, AdvancedSettings>(
  (ref) => AdvancedSettingsNotifier(),
);

PlayerPerTypeConfig _readPlayerConfig(
  SharedPreferences prefs,
  PlaybackContentType type,
) {
  return PlayerPerTypeConfig(
    primary: PlayerEngineX.fromLabel(
      prefs.getString(AdvancedSettings.kPlayerPrimary(type)),
    ),
    fallback: PlayerEngineX.fromLabel(
      prefs.getString(AdvancedSettings.kPlayerFallback(type)),
    ),
  );
}
