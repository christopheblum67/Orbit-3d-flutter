// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get tabAccount => 'Konto';

  @override
  String get tabNetwork => 'Netzwerk';

  @override
  String get tabPlayer => 'Player';

  @override
  String get tabSecurity => 'Sicherheit';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabAdvanced => 'Erweitert';

  @override
  String get sectionAccountProfile => 'Konto & Profil';

  @override
  String get accountProfiles => 'Benutzerprofile';

  @override
  String get accountProfilesSubtitle =>
      'Profile und das aktive Profil verwalten';

  @override
  String get accountSubscriptions => 'Xtream/M3U-Abonnements';

  @override
  String get accountNoSubscription => 'Kein aktives Abonnement';

  @override
  String get accountPreferences => 'Profil-Einstellungen';

  @override
  String get accountPreferencesSubtitle =>
      'Sprache, Design, Altersbeschränkungen, PIN';

  @override
  String get accountDeviceProfile => 'Geräteprofil & Diagnose';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profil $label · Player-Diagnose';
  }

  @override
  String get sectionCloudSync => 'Cloud-Synchronisierung (mehrere Geräte)';

  @override
  String get cloudSyncEnabled => 'Synchronisierung aktiviert';

  @override
  String cloudSyncLastSync(String time) {
    return 'Letzte Synchronisierung: $time';
  }

  @override
  String get cloudSyncSubtitleOff =>
      'Favoriten, gesehene und zuletzt angesehen Inhalte mit der Cloud synchronisieren';

  @override
  String get cloudSyncNow => 'Jetzt synchronisieren';

  @override
  String get cloudSyncNowSubtitle =>
      'Lokale Änderungen in die Cloud übertragen';

  @override
  String get never => 'nie';

  @override
  String get sectionNotifications => 'Benachrichtigungen';

  @override
  String get testNotifications => 'Benachrichtigungen testen';

  @override
  String get testNotificationsSubtitle =>
      'Sendet eine lokale Test-Benachrichtigung';

  @override
  String get sectionBackup => 'Sicherung / Wiederherstellung';

  @override
  String get backupExport => 'Konfiguration exportieren';

  @override
  String get backupExportSubtitle =>
      'Die vollständige Konfiguration in die Zwischenablage kopieren';

  @override
  String get backupImport => 'Konfiguration importieren';

  @override
  String get backupImportSubtitle =>
      'Aus der Zwischenablage wiederherstellen (JSON)';

  @override
  String get snackBackupExported =>
      'Konfiguration in der Zwischenablage exportiert';

  @override
  String get snackNoBackup => 'Keine Sicherung gefunden';

  @override
  String get snackImportSuccess => 'Konfiguration erfolgreich importiert';

  @override
  String snackImportError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get sectionAntiThrottle => 'Schutz gegen ISP-Drosselung';

  @override
  String get tlsImpersonation => 'TLS-Impersonation (lokaler Proxy)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simuliert den Fingerabdruck eines modernen Browsers, um Cloudflare zu umgehen';

  @override
  String get dnsProvider => 'DNS-Anbieter (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server für DNS-over-HTTPS-Anfragen';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatisch (System)';

  @override
  String get sectionCloudflare => 'Cloudflare-Optimierung';

  @override
  String get cloudflareReset => 'Cloudflare-Konfiguration zurücksetzen';

  @override
  String get cloudflareResetSubtitle =>
      'Cookies löschen, TLS Impersonation=OFF, Standard ExoPlayer-UA';

  @override
  String get snackCloudflareReset => 'Cloudflare-Konfiguration zurückgesetzt';

  @override
  String get sectionEngines => 'Wiedergabe-Engines';

  @override
  String get enginesTile => 'Wiedergabe-Engines';

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
      'Nachtoptimierung, Dialog-Boost, A/V-Synchronisierung';

  @override
  String get sectionZapping => 'Zapping & Leistung';

  @override
  String get instantZapping => 'Sofort-Zapping (Vorabladen)';

  @override
  String get instantZappingSubtitle =>
      'Benachbarte Kanäle in den Puffer vorladen';

  @override
  String get sectionMemory => 'Speicher & Cache';

  @override
  String get sectionParental => 'Kindersicherung';

  @override
  String get parentalControl => 'Kindersicherung';

  @override
  String get parentalControlSubtitle =>
      'PIN-Code hinzufügen und Inhalte einschränken';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get certPinning => 'Certificate Pinning aktivieren';

  @override
  String get certPinningSubtitle =>
      'Prüft den SHA-256-Fingerabdruck des SSL-Zertifikats des Servers (Anti-MITM)';

  @override
  String get certPinningHint =>
      'Erlaubte Fingerabdrücke (einer pro Zeile, hexadezimal in Großbuchstaben):';

  @override
  String get certPinningAdd => 'Die obigen Fingerabdrücke hinzufügen';

  @override
  String get sectionResilience => 'Dienst-Resilienz';

  @override
  String get autoReconnectLive => 'Live-Autoverbindung';

  @override
  String get autoReconnectLiveSubtitle =>
      'Automatisch neu verbinden, wenn der Stream abbricht';

  @override
  String get sectionLegal => 'Rechtliche Hinweise';

  @override
  String get legalNotice => 'Lies mich · Rechtlicher Hinweis';

  @override
  String get legalNoticeSubtitle =>
      'Nutzung der App, Rechteinhaber und Datenschutz';

  @override
  String get nightFocusTitle => 'Night Focus (Nachmodus)';

  @override
  String get nightFocusEnable => 'Night Focus aktivieren';

  @override
  String get nightFocusEnableSubtitle =>
      'Echtzeit-Audioverarbeitung: Dialog-Boost, Bass-Cut, Synchronisierung';

  @override
  String get dialogueBoost => 'Dialog-Boost (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Hebt Stimmen gegenüber Effekten/Musik hervor';

  @override
  String get bassKiller => 'Bass Killer (Schnitt < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Dämpft tiefe Frequenzen, um Vibrationen zu vermeiden';

  @override
  String get sectionAvSync => 'A/V-Synchronisierung';

  @override
  String get audioShift => 'Konfigurierbarer Audio-Offset';

  @override
  String get audioShiftSubtitle => 'Manuelle Audio/Video-Verzögerung (ms)';

  @override
  String get manualAvCalibration => 'Manuelle A/V-Kalibrierung';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Aktueller Offset: $ms ms';
  }

  @override
  String get sectionOutput => 'Audioausgang';

  @override
  String get volumeNormalization => 'Lautstärke-Normalisierung';

  @override
  String get volumeNormalizationSubtitle =>
      'Grenzt Lautstärke-Spitzen zwischen Kanälen/Programmen ein (AGC)';

  @override
  String get avSyncDialogTitle => 'A/V-Kalibrierung';

  @override
  String get avSyncDialogLabel => 'Offset (ms)';

  @override
  String get avSyncDialogHint =>
      'Positiv = Audio voraus, Negativ = Audio verzögert';

  @override
  String get apply => 'Übernehmen';

  @override
  String get sectionAccessibility => 'Barrierefreiheit';

  @override
  String get highContrast => 'Hoher Kontrastmodus';

  @override
  String get highContrastSubtitle =>
      'Verbessert die Lesbarkeit für Sehbehinderte';

  @override
  String get dpadNavigation => 'Verstärkte D-Pad-Navigation';

  @override
  String get dpadNavigationSubtitle =>
      'Sichtbarer Fokus, Leuchtrahmen, Textumbruch (TV-Modus)';

  @override
  String get fontSize => 'Vergrößerte Textgröße';

  @override
  String get fontSizeSubtitle => 'Vergrößert Texte in der gesamten App';

  @override
  String get sectionTmdb => 'TMDB-Ranglisten';

  @override
  String get sectionRecommendations => 'Empfehlungen';

  @override
  String get matchmaking => 'Für dich (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Abgleich und personalisierte Vorschläge verwalten';

  @override
  String get sectionDiagnostics => 'Diagnose & Wartung';

  @override
  String get logsDiagnostic => 'Protokolle & Diagnose';

  @override
  String get logsDiagnosticSubtitle =>
      'Protokolle ansehen, exportieren, Cache leeren';

  @override
  String get clearCaches => 'Alle Caches leeren';

  @override
  String get clearCachesSubtitle => 'Bilder, Suchindex, TMDB/TVmaze-Metadaten';

  @override
  String get resetApp => 'App zurücksetzen';

  @override
  String get resetAppSubtitle =>
      'Löscht alle Benutzerdaten (Profile, Favoriten, Verlauf)';

  @override
  String get snackCacheCleared => 'Caches geleert (TODO)';

  @override
  String get resetAppDialogTitle => 'App zurücksetzen?';

  @override
  String get resetAppDialogBody =>
      'Alle Daten werden gelöscht: Profile, Favoriten, Verlauf, Einstellungen. Diese Aktion ist nicht umkehrbar.';

  @override
  String get resetAppDialogConfirm => 'Alles löschen';

  @override
  String get tmdbKeyLabel => 'Persönlicher TMDB-API-Schlüssel (optional)';

  @override
  String get tmdbKeyHint =>
      'Standardmäßig wird der eingebettete gemeinsame Schlüssel verwendet';

  @override
  String get tmdbKeyActive =>
      'Persönlicher Schlüssel aktiv – gemeinsamer Schlüssel wird ignoriert';

  @override
  String get tmdbKeyShared =>
      'Eingebetteter gemeinsamer Schlüssel in Verwendung (kein persönlicher Schlüssel)';

  @override
  String get tmdbKeyDelete => 'Persönlichen Schlüssel löschen';

  @override
  String get tmdbKeyColumn => 'TMDB-Schlüssel';

  @override
  String get language => 'Sprache';

  @override
  String get languagePreference => 'Anwendungssprache';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';
}
