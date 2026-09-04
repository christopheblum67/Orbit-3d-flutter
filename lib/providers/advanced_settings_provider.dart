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

  static PlayerEngine fromLabel(String? label) => PlayerEngine.values
      .firstWhere((e) => e.label == label, orElse: () => PlayerEngine.exoPlayer);
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

/// Mode d'affichage du guide TV (EPG) :
///  - [EpgDisplayMode.grid2D] : grille classique chaînes × temps (XCIPTV) ;
///  - [EpgDisplayMode.grid3D] : rendu 3D (en conception, placeholder pour
///    l'instant).
enum EpgDisplayMode { grid2D, grid3D }

extension EpgDisplayModeX on EpgDisplayMode {
  String get label => switch (this) {
        EpgDisplayMode.grid2D => 'Grille 2D',
        EpgDisplayMode.grid3D => '3D immersive',
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
  final bool useCustomDNS;
  final String dnsProvider;
  final bool enableP2PHybrid;

  // Lecteur & Performance
  final String livePlayer;
  final bool autoFrameRate;
  final bool zeroLagPrefetch;
  final bool enableAiUpscaling;

  // Lecteurs par type de contenu (moteur principal + moteur de secours).
  final PlayerPerTypeConfig playerLive;
  final PlayerPerTypeConfig playerVod;
  final PlayerPerTypeConfig playerSeries;
  final PlayerPerTypeConfig playerReplay;

  // Sécurité & Failover
  final bool smartFailover;
  final bool hideCredentials;

  // Ergonomie & TV
  final bool directToLive;
  final EpgDisplayMode epgDisplayMode;

  // Audio & Night Focus
  final bool nightFocusEnabled;
  final bool nightFocusDialogueBoost;
  final bool nightFocusBassKiller;
  final double nightFocusVocalGainDb;
  final int nightFocusAudioShiftMs;

  // Options IA
  final bool localAiSubtitles;
  final bool sportsHighlightsDetection;

  const AdvancedSettings({
    this.useTlsImpersonation = true,
    this.useCustomDNS = true,
    this.dnsProvider = '1.1.1.1 (Cloudflare DoH)',
    this.enableP2PHybrid = false,
    this.livePlayer = 'ExoPlayer (Interne)',
    this.autoFrameRate = true,
    this.zeroLagPrefetch = true,
    this.enableAiUpscaling = false,
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
    this.smartFailover = true,
    this.hideCredentials = true,
    this.directToLive = false,
    this.epgDisplayMode = EpgDisplayMode.grid2D,
    this.nightFocusEnabled = false,
    this.nightFocusDialogueBoost = true,
    this.nightFocusBassKiller = true,
    this.nightFocusVocalGainDb = 3.0,
    this.nightFocusAudioShiftMs = 0,
    this.localAiSubtitles = false,
    this.sportsHighlightsDetection = true,
  });

  AdvancedSettings copyWith({
    bool? useTlsImpersonation,
    bool? useCustomDNS,
    String? dnsProvider,
    bool? enableP2PHybrid,
    String? livePlayer,
    bool? autoFrameRate,
    bool? zeroLagPrefetch,
    bool? enableAiUpscaling,
    PlayerPerTypeConfig? playerLive,
    PlayerPerTypeConfig? playerVod,
    PlayerPerTypeConfig? playerSeries,
    PlayerPerTypeConfig? playerReplay,
    bool? smartFailover,
    bool? hideCredentials,
    bool? directToLive,
    EpgDisplayMode? epgDisplayMode,
    bool? nightFocusEnabled,
    bool? nightFocusDialogueBoost,
    bool? nightFocusBassKiller,
    double? nightFocusVocalGainDb,
    int? nightFocusAudioShiftMs,
    bool? localAiSubtitles,
    bool? sportsHighlightsDetection,
  }) {
    return AdvancedSettings(
      useTlsImpersonation:
          useTlsImpersonation ?? this.useTlsImpersonation,
      useCustomDNS: useCustomDNS ?? this.useCustomDNS,
      dnsProvider: dnsProvider ?? this.dnsProvider,
      enableP2PHybrid: enableP2PHybrid ?? this.enableP2PHybrid,
      livePlayer: livePlayer ?? this.livePlayer,
      autoFrameRate: autoFrameRate ?? this.autoFrameRate,
      zeroLagPrefetch: zeroLagPrefetch ?? this.zeroLagPrefetch,
      enableAiUpscaling: enableAiUpscaling ?? this.enableAiUpscaling,
      playerLive: playerLive ?? this.playerLive,
      playerVod: playerVod ?? this.playerVod,
      playerSeries: playerSeries ?? this.playerSeries,
      playerReplay: playerReplay ?? this.playerReplay,
      smartFailover: smartFailover ?? this.smartFailover,
      hideCredentials: hideCredentials ?? this.hideCredentials,
      directToLive: directToLive ?? this.directToLive,
      epgDisplayMode: epgDisplayMode ?? this.epgDisplayMode,
      nightFocusEnabled: nightFocusEnabled ?? this.nightFocusEnabled,
      nightFocusDialogueBoost:
          nightFocusDialogueBoost ?? this.nightFocusDialogueBoost,
      nightFocusBassKiller: nightFocusBassKiller ?? this.nightFocusBassKiller,
      nightFocusVocalGainDb:
          nightFocusVocalGainDb ?? this.nightFocusVocalGainDb,
      nightFocusAudioShiftMs:
          nightFocusAudioShiftMs ?? this.nightFocusAudioShiftMs,
      localAiSubtitles: localAiSubtitles ?? this.localAiSubtitles,
      sportsHighlightsDetection:
          sportsHighlightsDetection ?? this.sportsHighlightsDetection,
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
  static const kCustomDNS = 'custom_dns';
  static const kDnsProvider = 'dns_provider';
  static const kP2PHybrid = 'p2p_hybrid';
  static const kLivePlayer = 'live_player';
  static const kAutoFrameRate = 'auto_frame_rate';
  static const kZeroLagPrefetch = 'zero_lag_prefetch';
  static const kAiUpscaling = 'ai_upscaling';

  // Clés de persistance des lecteurs par type de contenu (moteur par index).
  static const kPlayerEngine = 'player_engine';
  static const _kPrimary = 'primary';
  static const _kFallback = 'fallback';

  /// Index du type de contenu dans [PlaybackContentType.values].
  static String kPlayerPrimary(PlaybackContentType t) =>
      '$kPlayerEngine.$_kPrimary.${t.name}';
  static String kPlayerFallback(PlaybackContentType t) =>
      '$kPlayerEngine.$_kFallback.${t.name}';
  static const kSmartFailover = 'smart_failover';
  static const kHideCredentials = 'hide_credentials';
  static const kDirectToLive = 'direct_to_live';
  static const kEpgDisplayMode = 'epg_display_mode';
  static const kNightFocus = 'night_focus';
  static const kNightFocusDialogueBoost = 'night_focus_dialogue_boost';
  static const kNightFocusBassKiller = 'night_focus_bass_killer';
  static const kNightFocusVocalGainDb = 'night_focus_vocal_gain_db';
  static const kNightFocusAudioShiftMs = 'night_focus_audio_shift_ms';
  static const kLocalAiSubtitles = 'local_ai_subtitles';
  static const kSportsHighlights = 'sports_highlights';
}

class AdvancedSettingsNotifier extends StateNotifier<AdvancedSettings> {
  AdvancedSettingsNotifier() : super(const AdvancedSettings());

  SharedPreferences? _prefs;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    state = AdvancedSettings(
      useTlsImpersonation:
          prefs.getBool(AdvancedSettings.kTlsImpersonation) ??
              true,
      useCustomDNS: prefs.getBool(AdvancedSettings.kCustomDNS) ?? true,
      dnsProvider: prefs.getString(AdvancedSettings.kDnsProvider) ??
          '1.1.1.1 (Cloudflare DoH)',
      enableP2PHybrid: prefs.getBool(AdvancedSettings.kP2PHybrid) ?? false,
      livePlayer: prefs.getString(AdvancedSettings.kLivePlayer) ??
          'ExoPlayer (Interne)',
      autoFrameRate: prefs.getBool(AdvancedSettings.kAutoFrameRate) ?? true,
      zeroLagPrefetch:
          prefs.getBool(AdvancedSettings.kZeroLagPrefetch) ?? true,
      enableAiUpscaling: prefs.getBool(AdvancedSettings.kAiUpscaling) ?? false,
      playerLive: _readPlayerConfig(
        prefs,
        PlaybackContentType.live,
      ),
      playerVod: _readPlayerConfig(prefs, PlaybackContentType.vod),
      playerSeries: _readPlayerConfig(prefs, PlaybackContentType.series),
      playerReplay: _readPlayerConfig(prefs, PlaybackContentType.replay),
      smartFailover: prefs.getBool(AdvancedSettings.kSmartFailover) ?? true,
      hideCredentials:
          prefs.getBool(AdvancedSettings.kHideCredentials) ?? true,
      directToLive: prefs.getBool(AdvancedSettings.kDirectToLive) ?? false,
      epgDisplayMode: _readEpgDisplayMode(
        prefs.getString(AdvancedSettings.kEpgDisplayMode),
      ),
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
      localAiSubtitles:
          prefs.getBool(AdvancedSettings.kLocalAiSubtitles) ?? false,
      sportsHighlightsDetection:
          prefs.getBool(AdvancedSettings.kSportsHighlights) ?? true,
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

  Future<void> setCustomDNS(bool value) async {
    state = state.copyWith(useCustomDNS: value);
    await _persistBool(AdvancedSettings.kCustomDNS, value);
  }

  Future<void> setDnsProvider(String value) async {
    state = state.copyWith(dnsProvider: value);
    await _persistString(AdvancedSettings.kDnsProvider, value);
  }

  Future<void> setP2PHybrid(bool value) async {
    state = state.copyWith(enableP2PHybrid: value);
    await _persistBool(AdvancedSettings.kP2PHybrid, value);
  }

  Future<void> setLivePlayer(String value) async {
    state = state.copyWith(livePlayer: value);
    await _persistString(AdvancedSettings.kLivePlayer, value);
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

  Future<void> setAutoFrameRate(bool value) async {
    state = state.copyWith(autoFrameRate: value);
    await _persistBool(AdvancedSettings.kAutoFrameRate, value);
  }

  Future<void> setZeroLagPrefetch(bool value) async {
    state = state.copyWith(zeroLagPrefetch: value);
    await _persistBool(AdvancedSettings.kZeroLagPrefetch, value);
  }

  Future<void> setAiUpscaling(bool value) async {
    state = state.copyWith(enableAiUpscaling: value);
    await _persistBool(AdvancedSettings.kAiUpscaling, value);
  }

  Future<void> setSmartFailover(bool value) async {
    state = state.copyWith(smartFailover: value);
    await _persistBool(AdvancedSettings.kSmartFailover, value);
  }

  Future<void> setHideCredentials(bool value) async {
    state = state.copyWith(hideCredentials: value);
    await _persistBool(AdvancedSettings.kHideCredentials, value);
  }

  Future<void> setDirectToLive(bool value) async {
    state = state.copyWith(directToLive: value);
    await _persistBool(AdvancedSettings.kDirectToLive, value);
  }

  Future<void> setEpgDisplayMode(EpgDisplayMode value) async {
    state = state.copyWith(epgDisplayMode: value);
    await _persistString(AdvancedSettings.kEpgDisplayMode, value.name);
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

  Future<void> setLocalAiSubtitles(bool value) async {
    state = state.copyWith(localAiSubtitles: value);
    await _persistBool(AdvancedSettings.kLocalAiSubtitles, value);
  }

  Future<void> setSportsHighlights(bool value) async {
    state = state.copyWith(sportsHighlightsDetection: value);
    await _persistBool(AdvancedSettings.kSportsHighlights, value);
  }
}

final advancedSettingsProvider = StateNotifierProvider<
    AdvancedSettingsNotifier, AdvancedSettings>(
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

EpgDisplayMode _readEpgDisplayMode(String? raw) => EpgDisplayMode.values
    .firstWhere((m) => m.name == raw, orElse: () => EpgDisplayMode.grid2D);
