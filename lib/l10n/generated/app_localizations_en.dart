// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tabAccount => 'Account';

  @override
  String get tabNetwork => 'Network';

  @override
  String get tabPlayer => 'Player';

  @override
  String get tabSecurity => 'Security';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabAdvanced => 'Advanced';

  @override
  String get sectionAccountProfile => 'Account & Profile';

  @override
  String get accountProfiles => 'User profiles';

  @override
  String get accountProfilesSubtitle =>
      'Manage profiles and the active profile';

  @override
  String get accountSubscriptions => 'Xtream/M3U subscriptions';

  @override
  String get accountNoSubscription => 'No active subscription';

  @override
  String get accountPreferences => 'Profile preferences';

  @override
  String get accountPreferencesSubtitle =>
      'Language, theme, age restrictions, PIN';

  @override
  String get accountDeviceProfile => 'Device profile & Diagnostics';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profile $label · player diagnostics';
  }

  @override
  String get sectionCloudSync => 'Cloud Sync (multi-device)';

  @override
  String get cloudSyncEnabled => 'Sync enabled';

  @override
  String cloudSyncLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get cloudSyncSubtitleOff =>
      'Sync favorites, watched and recents to the cloud';

  @override
  String get cloudSyncNow => 'Sync now';

  @override
  String get cloudSyncNowSubtitle => 'Push local changes to the cloud';

  @override
  String get never => 'never';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get testNotifications => 'Test notifications';

  @override
  String get testNotificationsSubtitle => 'Send a local test notification';

  @override
  String get sectionBackup => 'Backup / Restore';

  @override
  String get backupExport => 'Export configuration';

  @override
  String get backupExportSubtitle => 'Copy the full config to the clipboard';

  @override
  String get backupImport => 'Import configuration';

  @override
  String get backupImportSubtitle => 'Restore from the clipboard (JSON)';

  @override
  String get snackBackupExported => 'Configuration exported to the clipboard';

  @override
  String get snackNoBackup => 'No backup found';

  @override
  String get snackImportSuccess => 'Configuration imported successfully';

  @override
  String snackImportError(String message) {
    return 'Error: $message';
  }

  @override
  String get sectionAntiThrottle => 'ISP throttling protection';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Local Proxy)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simulates a modern browser fingerprint to bypass Cloudflare';

  @override
  String get dnsProvider => 'DNS provider (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server used for DNS over HTTPS queries';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatic (System)';

  @override
  String get sectionCloudflare => 'Cloudflare optimization';

  @override
  String get cloudflareReset => 'Reset Cloudflare config';

  @override
  String get cloudflareResetSubtitle =>
      'Clears cookies, sets TLS Impersonation=OFF, default ExoPlayer UA';

  @override
  String get snackCloudflareReset => 'Cloudflare config reset';

  @override
  String get sectionEngines => 'Playback engines';

  @override
  String get enginesTile => 'Playback engines';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live: $live · VOD: $vod';
  }

  @override
  String get sectionAudioNight => 'Audio & Night Focus';

  @override
  String get audioAndNightFocus => 'Audio & Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Night optimization, dialogue boost, A/V sync';

  @override
  String get sectionZapping => 'Zapping & Performance';

  @override
  String get instantZapping => 'Instant Zapping (Prefetch)';

  @override
  String get instantZappingSubtitle =>
      'Prefetch adjacent channels into the buffer';

  @override
  String get sectionMemory => 'Memory & Cache';

  @override
  String get sectionParental => 'Parental control';

  @override
  String get parentalControl => 'Parental control';

  @override
  String get parentalControlSubtitle => 'Add a PIN code and restrict content';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get certPinning => 'Enable Certificate Pinning';

  @override
  String get certPinningSubtitle =>
      'Checks the SHA-256 fingerprint of the server SSL certificate (anti-MITM)';

  @override
  String get certPinningHint =>
      'Allowed fingerprints (one per line, uppercase hex):';

  @override
  String get certPinningAdd => 'Add the fingerprints above';

  @override
  String get sectionResilience => 'Service resilience';

  @override
  String get autoReconnectLive => 'Live auto-reconnect';

  @override
  String get autoReconnectLiveSubtitle =>
      'Automatically reconnect if the stream drops';

  @override
  String get sectionLegal => 'Legal information';

  @override
  String get legalNotice => 'Read me · Legal notice';

  @override
  String get legalNoticeSubtitle => 'App usage, rights holders and privacy';

  @override
  String get nightFocusTitle => 'Night Focus (Night Mode)';

  @override
  String get nightFocusEnable => 'Enable Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Real-time audio processing: dialogue boost, bass cut, sync';

  @override
  String get dialogueBoost => 'Dialogue Boost (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifies voices relative to effects/music';

  @override
  String get bassKiller => 'Bass Killer (cut < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Attenuates low frequencies to avoid vibrations';

  @override
  String get sectionAvSync => 'A/V sync';

  @override
  String get audioShift => 'Configurable audio offset';

  @override
  String get audioShiftSubtitle => 'Manual audio/video offset (ms)';

  @override
  String get manualAvCalibration => 'Manual A/V calibration';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Current offset: $ms ms';
  }

  @override
  String get sectionOutput => 'Audio output';

  @override
  String get volumeNormalization => 'Volume normalization';

  @override
  String get volumeNormalizationSubtitle =>
      'Limits volume peaks between channels/programs (AGC)';

  @override
  String get avSyncDialogTitle => 'A/V calibration';

  @override
  String get avSyncDialogLabel => 'Offset (ms)';

  @override
  String get avSyncDialogHint =>
      'Positive = audio ahead, Negative = audio delayed';

  @override
  String get apply => 'Apply';

  @override
  String get sectionAccessibility => 'Accessibility';

  @override
  String get highContrast => 'High contrast mode';

  @override
  String get highContrastSubtitle =>
      'Improves readability for the visually impaired';

  @override
  String get dpadNavigation => 'Enhanced D-pad navigation';

  @override
  String get dpadNavigationSubtitle =>
      'Visible focus, glow halo, text wrap (TV mode)';

  @override
  String get fontSize => 'Increased text size';

  @override
  String get fontSizeSubtitle => 'Enlarges text throughout the app';

  @override
  String get sectionTmdb => 'TMDB rankings';

  @override
  String get sectionRecommendations => 'Recommendations';

  @override
  String get matchmaking => 'For you (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Manage pairing and personalized suggestions';

  @override
  String get sectionDiagnostics => 'Diagnostics & Maintenance';

  @override
  String get logsDiagnostic => 'Logs & Diagnostics';

  @override
  String get logsDiagnosticSubtitle => 'View logs, export, clear cache';

  @override
  String get clearCaches => 'Clear all caches';

  @override
  String get clearCachesSubtitle =>
      'Images, search index, TMDB/TVmaze metadata';

  @override
  String get resetApp => 'Reset application';

  @override
  String get resetAppSubtitle =>
      'Erases all user data (profiles, favorites, history)';

  @override
  String get snackCacheCleared => 'Caches cleared (TODO)';

  @override
  String get resetAppDialogTitle => 'Reset application?';

  @override
  String get resetAppDialogBody =>
      'All data will be erased: profiles, favorites, history, settings. This action is irreversible.';

  @override
  String get resetAppDialogConfirm => 'Erase everything';

  @override
  String get tmdbKeyLabel => 'Personal TMDB API key (optional)';

  @override
  String get tmdbKeyHint => 'The embedded shared key is used by default';

  @override
  String get tmdbKeyActive => 'Personal key active - the shared key is ignored';

  @override
  String get tmdbKeyShared => 'Embedded shared key in use (no personal key)';

  @override
  String get tmdbKeyDelete => 'Delete personal key';

  @override
  String get tmdbKeyColumn => 'TMDB keys';

  @override
  String get language => 'Language';

  @override
  String get languagePreference => 'Application language';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';
}
