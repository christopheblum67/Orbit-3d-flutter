// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get accountDeviceProfile => 'Geräteprofil & Diagnose';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profil $label · Player-Diagnose';
  }

  @override
  String get accountNoSubscription => 'Kein aktives Abonnement';

  @override
  String get accountPreferences => 'Profil-Einstellungen';

  @override
  String get accountPreferencesSubtitle =>
      'Sprache, Design, Altersbeschränkungen, PIN';

  @override
  String get accountProfiles => 'Benutzerprofile';

  @override
  String get accountProfilesSubtitle =>
      'Profile und das aktive Profil verwalten';

  @override
  String get accountSubscriptions => 'Xtream/M3U-Abonnements';

  @override
  String activeCountOngoing(Object count) {
    return '$count laufend';
  }

  @override
  String get addSubscription => 'Abonnement hinzufügen';

  @override
  String addedToFavorites(Object title) {
    return '„$title“ zu Favoriten hinzugefügt';
  }

  @override
  String get age => 'Alter';

  @override
  String get ageRange13to17 => '13 - 17 Jahre';

  @override
  String get ageRange18to24 => '18 - 24 Jahre';

  @override
  String get ageRange25to34 => '25 - 34 Jahre';

  @override
  String get ageRange35to44 => '35 - 44 Jahre';

  @override
  String get ageRange45to54 => '45 - 54 Jahre';

  @override
  String get ageRange55plus => '55 Jahre und älter';

  @override
  String get ageRangeUnder12 => '- 12 Jahre';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'In Suchen und Empfehlungen erscheinen';

  @override
  String get apply => 'Übernehmen';

  @override
  String get audioAndNightFocus => 'Audio & Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Nachtoptimierung, Dialog-Boost, A/V-Synchronisierung';

  @override
  String get audioShift => 'Konfigurierbarer Audio-Offset';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'Manuelle Audio/Video-Verzögerung (ms)';

  @override
  String get autoQualityDescription =>
      'Lässt den Player die beste Qualität wählen';

  @override
  String get autoReconnectLive => 'Live-Autoverbindung';

  @override
  String get autoReconnectLiveSubtitle =>
      'Automatisch neu verbinden, wenn der Stream abbricht';

  @override
  String get avSyncDialogHint =>
      'Positiv = Audio voraus, Negativ = Audio verzögert';

  @override
  String get avSyncDialogLabel => 'Offset (ms)';

  @override
  String get avSyncDialogTitle => 'A/V-Kalibrierung';

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
  String get bassKiller => 'Bass Killer (Schnitt < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Dämpft tiefe Frequenzen, um Vibrationen zu vermeiden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get castToChromecast => 'Auf Chromecast senden';

  @override
  String get catchUpTv => 'Sendungen nachholen';

  @override
  String get categories => 'Kategorien';

  @override
  String get certPinning => 'Certificate Pinning aktivieren';

  @override
  String get certPinningAdd => 'Die obigen Fingerabdrücke hinzufügen';

  @override
  String get certPinningHint =>
      'Erlaubte Fingerabdrücke (einer pro Zeile, hexadezimal in Großbuchstaben):';

  @override
  String get certPinningSubtitle =>
      'Prüft den SHA-256-Fingerabdruck des SSL-Zertifikats des Servers (Anti-MITM)';

  @override
  String get changePinCode => 'PIN-Code ändern';

  @override
  String get channelsUnavailable => 'Sender nicht verfügbar';

  @override
  String get chooseProfile => 'Profil auswählen';

  @override
  String get clearCaches => 'Alle Caches leeren';

  @override
  String get clearCachesSubtitle => 'Bilder, Suchindex, TMDB/TVmaze-Metadaten';

  @override
  String get cloudSyncEnabled => 'Synchronisierung aktiviert';

  @override
  String cloudSyncLastSync(String time) {
    return 'Letzte Synchronisierung: $time';
  }

  @override
  String get cloudSyncNow => 'Jetzt synchronisieren';

  @override
  String get cloudSyncNowSubtitle =>
      'Lokale Änderungen in die Cloud übertragen';

  @override
  String get cloudSyncSubtitleOff =>
      'Favoriten, gesehene und zuletzt angesehen Inhalte mit der Cloud synchronisieren';

  @override
  String get cloudflareReset => 'Cloudflare-Konfiguration zurücksetzen';

  @override
  String get cloudflareResetSubtitle =>
      'Cookies löschen, TLS Impersonation=OFF, Standard ExoPlayer-UA';

  @override
  String get comingSoon => 'Bald verfügbar';

  @override
  String get confirmAndContinue => 'Bestätigen und fortfahren';

  @override
  String get coverCacheCleared => 'Cover-Cache geleert.';

  @override
  String get createKidProfile => 'Kinderprofil erstellen';

  @override
  String get createNewProfile => 'Neues Profil erstellen';

  @override
  String get createProfile => 'Profil erstellen';

  @override
  String get dataAlreadyFresh => 'Daten bereits aktuell (weniger als 30 Min.)';

  @override
  String get dataAndPrivacy => 'Daten & Datenschutz';

  @override
  String get deleteAll => 'Alle löschen';

  @override
  String get deleteAllConfirm => 'Alle löschen?';

  @override
  String get deletePin => 'PIN löschen';

  @override
  String get deleteProfileConfirm => 'Profil löschen?';

  @override
  String get detailUnavailable => 'Details nicht verfügbar';

  @override
  String get diagnosticUnavailable => 'Diagnose nicht verfügbar';

  @override
  String get dialogueBoost => 'Dialog-Boost (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Hebt Stimmen gegenüber Effekten/Musik hervor';

  @override
  String get disableSubtitles => 'Untertitel deaktivieren';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'DNS-Anbieter (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server für DNS-over-HTTPS-Anfragen';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatisch (System)';

  @override
  String downloadFailed(Object error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get dpadNavigation => 'Verstärkte D-Pad-Navigation';

  @override
  String get dpadNavigationSubtitle =>
      'Sichtbarer Fokus, Leuchtrahmen, Textumbruch (TV-Modus)';

  @override
  String get enableParentalControl => 'Kindersicherung aktivieren';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live: $live · VOD: $vod';
  }

  @override
  String get enginesTile => 'Wiedergabe-Engines';

  @override
  String get enterNew4DigitPin => 'Neuen 4-stelligen Code eingeben';

  @override
  String get epgGrille => 'EPG (Programmzeitschrift)';

  @override
  String get epgGuideTv => 'TV-Guide (EPG)';

  @override
  String get episode => 'Episode';

  @override
  String errorGeneric(Object error) {
    return 'Fehler: $error';
  }

  @override
  String errorLoading(Object error) {
    return 'Ladefehler: $error';
  }

  @override
  String get errorSaving => 'Fehler beim Speichern';

  @override
  String get exitWithoutSaving => 'Ohne Speichern beenden?';

  @override
  String get failedToLoadProfiles => 'Profile konnten nicht geladen werden';

  @override
  String get fallbackEngine => 'Ausweich-Engine';

  @override
  String get favoriteGenres => 'Lieblingsgenres';

  @override
  String get filmsVod => 'Filme (VOD)';

  @override
  String get firstName => 'Vorname';

  @override
  String get fontSize => 'Vergrößerte Textgröße';

  @override
  String get fontSizeSubtitle => 'Vergrößert Texte in der gesamten App';

  @override
  String get forYou => 'Für dich';

  @override
  String get forYouAndDuo => 'Für dich & Im Duo';

  @override
  String get forYouMatchmaking => 'Für dich (Matchmaking)';

  @override
  String get forward10s => '10s vor';

  @override
  String get forward30s => '30s vor';

  @override
  String get groupMode => 'In der Gruppe';

  @override
  String get highContrast => 'Hoher Kontrastmodus';

  @override
  String get highContrastSubtitle =>
      'Verbessert die Lesbarkeit für Sehbehinderte';

  @override
  String get historyUnavailable => 'Verlauf nicht verfügbar';

  @override
  String get instantZapping => 'Sofort-Zapping (Vorabladen)';

  @override
  String get instantZappingSubtitle =>
      'Benachbarte Kanäle in den Puffer vorladen';

  @override
  String get kidsContent => 'Kinderfreundliche Inhalte';

  @override
  String get kidsMode => 'Kindermode';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langSpanish => 'Español';

  @override
  String get language => 'Sprache';

  @override
  String get languageExample => 'Français, English, etc.';

  @override
  String get languagePreference => 'Anwendungssprache';

  @override
  String get languageUndetermined => 'Unbestimmt';

  @override
  String get later => 'Später';

  @override
  String get legalNotice => 'Lies mich · Rechtlicher Hinweis';

  @override
  String get legalNoticeSubtitle =>
      'Nutzung der App, Rechteinhaber und Datenschutz';

  @override
  String get liveChannelsAndZapping => 'Live-Sender & Zapping';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'Protokolle & Diagnose';

  @override
  String get logsDiagnosticSubtitle =>
      'Protokolle ansehen, exportieren, Cache leeren';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'M3U-Playlist-URL';

  @override
  String get mainCast => 'Hauptbesetzung';

  @override
  String get manualAvCalibration => 'Manuelle A/V-Kalibrierung';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Aktueller Offset: $ms ms';
  }

  @override
  String get matchmaking => 'Für dich (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Abgleich und personalisierte Vorschläge verwalten';

  @override
  String maxProfilesReached(Object max) {
    return 'Maximale Anzahl an Profilen erreicht ($max)';
  }

  @override
  String get memory => 'Speicher';

  @override
  String get moviesUnavailable => 'Filme nicht verfügbar';

  @override
  String get multiScreen => 'Mehr Bildschirme';

  @override
  String get multiVideo => 'Multi-Video';

  @override
  String get myProfile => 'Mein Profil';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get nameOrNickname => 'Name / Spitzname';

  @override
  String get navigateToOkToSelect => 'Zu OK navigieren zum Auswählen';

  @override
  String get networkDisconnected => 'Netzwerk getrennt';

  @override
  String get never => 'nie';

  @override
  String get newAnd4K => 'Neuerscheinungen & 4K';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get nextChannel => 'Nächster Sender';

  @override
  String get nightFocusEnable => 'Night Focus aktivieren';

  @override
  String get nightFocusEnableSubtitle =>
      'Echtzeit-Audioverarbeitung: Dialog-Boost, Bass-Cut, Synchronisierung';

  @override
  String get nightFocusTitle => 'Night Focus (Nachmodus)';

  @override
  String get noAudioTrackDetected => 'Kein Audiotrack erkannt';

  @override
  String get noChannelsAvailable => 'Keine Sender verfügbar';

  @override
  String get noChromecastDeviceFound => 'Kein Chromecast-Gerät gefunden.';

  @override
  String get noDownloads => 'Keine Downloads';

  @override
  String get noEpisodes => 'Keine Episoden';

  @override
  String get noFavoriteChannels => 'Keine Lieblingssender';

  @override
  String get noFavoriteMovies => 'Keine Lieblingsfilme';

  @override
  String get noFavoriteReplays => 'Keine Lieblingswiederholungen';

  @override
  String get noFavoriteSeries => 'Keine Lieblingsserien';

  @override
  String get noHistory => 'Kein Verlauf';

  @override
  String get noKidsChannels => 'Keine Kindersender';

  @override
  String get noKidsMovies => 'Keine Kinderfilme';

  @override
  String get noKidsReplays => 'Keine Kinderwiederholungen';

  @override
  String get noKidsSeries => 'Keine Kinderserien';

  @override
  String get noMoviesAvailable => 'Keine Filme verfügbar';

  @override
  String get noProfileAvailable => 'Kein Profil verfügbar';

  @override
  String get noProfilesYet => 'Noch keine Profile vorhanden';

  @override
  String get noProgramInfoAvailable => 'Keine Programminformationen verfügbar';

  @override
  String get noRankings => 'Keine Rankings';

  @override
  String get noReplaysInCategory => 'Keine Wiederholungen in dieser Kategorie';

  @override
  String noResultsFor(Object query) {
    return 'Keine Ergebnisse für $query';
  }

  @override
  String get noSeriesAvailable => 'Keine Serien verfügbar';

  @override
  String get noStationsAvailable => 'Keine Stationen verfügbar';

  @override
  String get noVideoQualityDetected => 'Keine Videoqualität erkannt';

  @override
  String get notAvailableInCatalog => 'Nicht im Katalog verfügbar';

  @override
  String get offline => 'Offline';

  @override
  String get parentalControl => 'Kindersicherung';

  @override
  String get parentalControlSubtitle =>
      'PIN-Code hinzufügen und Inhalte einschränken';

  @override
  String get pauseDownload => 'Pausieren';

  @override
  String get pinCode => 'PIN-Code';

  @override
  String get pinDeleted => 'PIN gelöscht';

  @override
  String get pinMustBe4Digits => 'PIN muss genau 4 Ziffern enthalten';

  @override
  String get pinSaved => 'PIN gespeichert';

  @override
  String get pip => 'Bild-in-Bild (PiP)';

  @override
  String get pipUnavailable =>
      'Bild-in-Bild (PiP) auf diesem Gerät nicht verfügbar';

  @override
  String get playHistoryCleared => 'Wiedergabeverlauf gelöscht.';

  @override
  String plusAgeYears(Object age) {
    return '+$age Jahre';
  }

  @override
  String get preferences => 'Einstellungen';

  @override
  String get previousChannel => 'Vorheriger Sender';

  @override
  String get primaryEngine => 'Haupt-Engine';

  @override
  String get profileVisible => 'Profil sichtbar';

  @override
  String get programGrid => 'Programmgrundriss';

  @override
  String get protectWithPin => 'Mit PIN-Code schützen';

  @override
  String get rankingsUnavailable => 'Rankings nicht verfügbar';

  @override
  String get receiveAlertsAndTips => 'Benachrichtigungen und Tipps erhalten';

  @override
  String get recentSearch => 'Letzte Suche';

  @override
  String get recentSearches => 'Zuletzt gesucht';

  @override
  String get recentlyWatched => 'Kürzlich gesehen';

  @override
  String get removeAll => 'Alle entfernen';

  @override
  String get removeFromWatchedConfirm => 'Alle aus „Gesehen” entfernen?';

  @override
  String get replaysUnavailable => 'Wiederholungen nicht verfügbar';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resetApp => 'App zurücksetzen';

  @override
  String get resetAppDialogBody =>
      'Alle Daten werden gelöscht: Profile, Favoriten, Verlauf, Einstellungen. Diese Aktion ist nicht umkehrbar.';

  @override
  String get resetAppDialogConfirm => 'Alles löschen';

  @override
  String get resetAppDialogTitle => 'App zurücksetzen?';

  @override
  String get resetAppSubtitle =>
      'Löscht alle Benutzerdaten (Profile, Favoriten, Verlauf)';

  @override
  String get resetCompleted => 'Zurücksetzen abgeschlossen';

  @override
  String get resumePlayback => 'Wiedergabe fortsetzen?';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get retrySearch => 'Suche erneut versuchen';

  @override
  String get rewind10s => '10s zurück';

  @override
  String get rewind30s => '30s zurück';

  @override
  String get rightsHolders => 'Rechteinhaber';

  @override
  String get save => 'Speichern';

  @override
  String get sdkAndroid => 'SDK Android';

  @override
  String get searchChannel => 'Sender suchen';

  @override
  String get searchError => 'Suchfehler';

  @override
  String get searchMovie => 'Film suchen';

  @override
  String get searchSeries => 'Serie suchen';

  @override
  String seasonNumber(Object season) {
    return 'Staffel $season';
  }

  @override
  String get seasonsAndEpisodes => 'Staffeln & Episoden';

  @override
  String get sectionAccessibility => 'Barrierefreiheit';

  @override
  String get sectionAccountProfile => 'Konto & Profil';

  @override
  String get sectionAntiThrottle => 'Schutz gegen ISP-Drosselung';

  @override
  String get sectionAudioNight => 'Audio & Night Focus';

  @override
  String get sectionAvSync => 'A/V-Synchronisierung';

  @override
  String get sectionBackup => 'Sicherung / Wiederherstellung';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get sectionCloudSync => 'Cloud-Synchronisierung (mehrere Geräte)';

  @override
  String get sectionCloudflare => 'Cloudflare-Optimierung';

  @override
  String get sectionDiagnostics => 'Diagnose & Wartung';

  @override
  String get sectionEngines => 'Wiedergabe-Engines';

  @override
  String get sectionLegal => 'Rechtliche Hinweise';

  @override
  String get sectionMemory => 'Speicher & Cache';

  @override
  String get sectionNotifications => 'Benachrichtigungen';

  @override
  String get sectionOutput => 'Audioausgang';

  @override
  String get sectionParental => 'Kindersicherung';

  @override
  String get sectionRecommendations => 'Empfehlungen';

  @override
  String get sectionResilience => 'Dienst-Resilienz';

  @override
  String get sectionTmdb => 'TMDB-Ranglisten';

  @override
  String get sectionZapping => 'Zapping & Leistung';

  @override
  String get select => 'Auswählen';

  @override
  String get selectProfileForRecommendations =>
      'Wählen Sie ein Profil für Empfehlungen';

  @override
  String get series => 'Serien';

  @override
  String get seriesNotFound => 'Serie nicht gefunden';

  @override
  String get seriesUnavailable => 'Serien nicht verfügbar';

  @override
  String get seriesUnavailableTemporarily => 'Serie derzeit nicht verfügbar.';

  @override
  String get serverProtectedAntiLeech => 'Server geschützt (Anti-Leech)';

  @override
  String get serverUrlPlaceholder => 'Server-URL (z.B. https://provider.com)';

  @override
  String get serviceNature => 'Art des Dienstes';

  @override
  String get setAsDefaultServer => 'Als Standardserver festlegen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get similarMovies => 'Ähnliche Filme';

  @override
  String get snackBackupExported =>
      'Konfiguration in der Zwischenablage exportiert';

  @override
  String get snackCacheCleared => 'Caches geleert (TODO)';

  @override
  String get snackCloudflareReset => 'Cloudflare-Konfiguration zurückgesetzt';

  @override
  String snackImportError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get snackImportSuccess => 'Konfiguration erfolgreich importiert';

  @override
  String get snackNoBackup => 'Keine Sicherung gefunden';

  @override
  String get sortBestRated => 'Bestbewertet (XCIPTV)';

  @override
  String get sortLatestM3UXtream => 'Neueste M3U/Xtream-Ergänzungen';

  @override
  String get sortNameAToZ => 'Name (A → Z)';

  @override
  String get sortNameZToA => 'Name (Z → A)';

  @override
  String get sortResumePriority => 'Fortsetzen priorisieren';

  @override
  String get sortYearRecentToOld => 'Erscheinungsjahr (Neu → Alt)';

  @override
  String specialGuestsSeason(Object season) {
    return 'Gastschauspieler - Staffel $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'Starten';

  @override
  String get stationsUnavailable => 'Stationen nicht verfügbar';

  @override
  String get stopCasting => 'Senden beenden';

  @override
  String get streamDetails => 'Stream-Details';

  @override
  String subtitleLoadError(Object error) {
    return 'Untertitel-Ladefehler: $error';
  }

  @override
  String get subtitlesUnavailable => 'Untertitel: nicht verfügbar';

  @override
  String get system => 'System';

  @override
  String get tabAccount => 'Konto';

  @override
  String get tabAdvanced => 'Erweitert';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabNetwork => 'Netzwerk';

  @override
  String get tabPlayer => 'Player';

  @override
  String get tabSecurity => 'Sicherheit';

  @override
  String get testNotifications => 'Benachrichtigungen testen';

  @override
  String get testNotificationsSubtitle =>
      'Sendet eine lokale Test-Benachrichtigung';

  @override
  String get theme => 'Thema';

  @override
  String get tlsImpersonation => 'TLS-Impersonation (lokaler Proxy)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simuliert den Fingerabdruck eines modernen Browsers, um Cloudflare zu umgehen';

  @override
  String get tmdbKeyActive =>
      'Persönlicher Schlüssel aktiv – gemeinsamer Schlüssel wird ignoriert';

  @override
  String get tmdbKeyColumn => 'TMDB-Schlüssel';

  @override
  String get tmdbKeyDelete => 'Persönlichen Schlüssel löschen';

  @override
  String get tmdbKeyHint =>
      'Standardmäßig wird der eingebettete gemeinsame Schlüssel verwendet';

  @override
  String get tmdbKeyLabel => 'Persönlicher TMDB-API-Schlüssel (optional)';

  @override
  String get tmdbKeyShared =>
      'Eingebetteter gemeinsamer Schlüssel in Verwendung (kein persönlicher Schlüssel)';

  @override
  String get tvChannels => 'TV-Sender';

  @override
  String get unableToBuildReplayUrl =>
      'Wiedergabe-URL konnte nicht erstellt werden.';

  @override
  String get unlockCloudflare => 'Entsperren (Cloudflare)';

  @override
  String get unstableConnection => 'Unstabile Verbindung';

  @override
  String get updateAllData => 'Alle Daten aktualisieren';

  @override
  String get updateThisCategory => 'Diese Kategorie aktualisieren';

  @override
  String get updating => 'Aktualisierung läuft…';

  @override
  String get volumeNormalization => 'Lautstärke-Normalisierung';

  @override
  String get volumeNormalizationSubtitle =>
      'Grenzt Lautstärke-Spitzen zwischen Kanälen/Programmen ein (AGC)';

  @override
  String get watchLive => 'Live ansehen';

  @override
  String get whoIsWatching => 'Wer schaut zu?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Ihre Sender & Inhalte';
}
