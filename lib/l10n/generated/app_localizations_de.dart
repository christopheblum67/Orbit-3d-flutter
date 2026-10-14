// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get accountDeviceProfile => 'Ger├ñteprofil & Diagnose';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profil $label ┬À Player-Diagnose';
  }

  @override
  String get accountNoSubscription => 'Kein aktives Abonnement';

  @override
  String get accountPreferences => 'Profil-Einstellungen';

  @override
  String get accountPreferencesSubtitle =>
      'Sprache, Design, Altersbeschr├ñnkungen, PIN';

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
  String get addSubscription => 'Abonnement hinzuf├╝gen';

  @override
  String addedToFavorites(Object title) {
    return 'ÔÇ×$titleÔÇ£ zu Favoriten hinzugef├╝gt';
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
  String get ageRange55plus => '55 Jahre und ├ñlter';

  @override
  String get ageRangeUnder12 => '- 12 Jahre';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'In Suchen und Empfehlungen erscheinen';

  @override
  String get apply => '├£bernehmen';

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
  String get audioShiftSubtitle => 'Manuelle Audio/Video-Verz├Âgerung (ms)';

  @override
  String get autoQualityDescription =>
      'L├ñsst den Player die beste Qualit├ñt w├ñhlen';

  @override
  String get autoReconnectLive => 'Live-Autoverbindung';

  @override
  String get autoReconnectLiveSubtitle =>
      'Automatisch neu verbinden, wenn der Stream abbricht';

  @override
  String get avSyncDialogHint =>
      'Positiv = Audio voraus, Negativ = Audio verz├Âgert';

  @override
  String get avSyncDialogLabel => 'Offset (ms)';

  @override
  String get avSyncDialogTitle => 'A/V-Kalibrierung';

  @override
  String get backupExport => 'Konfiguration exportieren';

  @override
  String get backupExportSubtitle =>
      'Die vollst├ñndige Konfiguration in die Zwischenablage kopieren';

  @override
  String get backupImport => 'Konfiguration importieren';

  @override
  String get backupImportSubtitle =>
      'Aus der Zwischenablage wiederherstellen (JSON)';

  @override
  String get bassKiller => 'Bass Killer (Schnitt < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'D├ñmpft tiefe Frequenzen, um Vibrationen zu vermeiden';

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
  String get certPinningAdd => 'Die obigen Fingerabdr├╝cke hinzuf├╝gen';

  @override
  String get certPinningHint =>
      'Erlaubte Fingerabdr├╝cke (einer pro Zeile, hexadezimal in Gro├ƒbuchstaben):';

  @override
  String get certPinningSubtitle =>
      'Pr├╝ft den SHA-256-Fingerabdruck des SSL-Zertifikats des Servers (Anti-MITM)';

  @override
  String get changePinCode => 'PIN-Code ├ñndern';

  @override
  String get channelsUnavailable => 'Sender nicht verf├╝gbar';

  @override
  String get chooseProfile => 'Profil ausw├ñhlen';

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
      'Lokale ├änderungen in die Cloud ├╝bertragen';

  @override
  String get cloudSyncSubtitleOff =>
      'Favoriten, gesehene und zuletzt angesehen Inhalte mit der Cloud synchronisieren';

  @override
  String get cloudflareReset => 'Cloudflare-Konfiguration zur├╝cksetzen';

  @override
  String get cloudflareResetSubtitle =>
      'Cookies l├Âschen, TLS Impersonation=OFF, Standard ExoPlayer-UA';

  @override
  String get comingSoon => 'Bald verf├╝gbar';

  @override
  String get confirmAndContinue => 'Best├ñtigen und fortfahren';

  @override
  String get coverCacheCleared => 'Cover-Cache geleert.';

  @override
  String get createKidProfile => 'Kinderprofil erstellen';

  @override
  String get createNewProfile => 'Neues Profil erstellen';

  @override
  String get createProfile => 'Profil erstellen';

  @override
  String currentProfileLabel(String name) {
    return 'Aktuelles Profil: $name';
  }

  @override
  String get dataAlreadyFresh => 'Daten bereits aktuell (weniger als 30 Min.)';

  @override
  String get dataAndPrivacy => 'Daten & Datenschutz';

  @override
  String get deleteAll => 'Alle l├Âschen';

  @override
  String get deleteAllConfirm => 'Alle l├Âschen?';

  @override
  String get deletePin => 'PIN l├Âschen';

  @override
  String get deleteProfileConfirm => 'Profil l├Âschen?';

  @override
  String get detailUnavailable => 'Details nicht verf├╝gbar';

  @override
  String get diagnosticUnavailable => 'Diagnose nicht verf├╝gbar';

  @override
  String get dialogueBoost => 'Dialog-Boost (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Hebt Stimmen gegen├╝ber Effekten/Musik hervor';

  @override
  String get disableSubtitles => 'Untertitel deaktivieren';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'DNS-Anbieter (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server f├╝r DNS-over-HTTPS-Anfragen';

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
  String get dpadNavigation => 'Verst├ñrkte D-Pad-Navigation';

  @override
  String get dpadNavigationSubtitle =>
      'Sichtbarer Fokus, Leuchtrahmen, Textumbruch (TV-Modus)';

  @override
  String get enableParentalControl => 'Kindersicherung aktivieren';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live: $live ┬À VOD: $vod';
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
  String get fontSize => 'Vergr├Â├ƒerte Textgr├Â├ƒe';

  @override
  String get fontSizeSubtitle => 'Vergr├Â├ƒert Texte in der gesamten App';

  @override
  String get forYou => 'F├╝r dich';

  @override
  String get forYouAndDuo => 'F├╝r dich & Im Duo';

  @override
  String get forYouMatchmaking => 'F├╝r dich (Matchmaking)';

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
      'Verbessert die Lesbarkeit f├╝r Sehbehinderte';

  @override
  String get historyUnavailable => 'Verlauf nicht verf├╝gbar';

  @override
  String get instantZapping => 'Sofort-Zapping (Vorabladen)';

  @override
  String get instantZappingSubtitle =>
      'Benachbarte Kan├ñle in den Puffer vorladen';

  @override
  String get langArabic => 'Ïº┘äÏ╣Ï▒Ï¿┘èÏ®';

  @override
  String get langFrench => 'Fran├ºais';

  @override
  String get langPortuguese => 'Portugu├¬s';

  @override
  String get langSpanish => 'Espa├▒ol';

  @override
  String get language => 'Sprache';

  @override
  String get languageExample => 'Deutsch, English, etc.';

  @override
  String get noneOption => 'Keine';

  @override
  String get play => 'Abspielen';

  @override
  String get newAnd4K => 'Filme auf Abruf';

  @override
  String get seasonsAndEpisodes => 'Serien auf Abruf';

  @override
  String get languagePreference => 'Anwendungssprache';

  @override
  String get languageUndetermined => 'Unbestimmt';

  @override
  String get later => 'Sp├ñter';

  @override
  String get legalNotice => 'Lies mich ┬À Rechtlicher Hinweis';

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
  String get matchmaking => 'F├╝r dich (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Abgleich und personalisierte Vorschl├ñge verwalten';

  @override
  String maxProfilesReached(Object max) {
    return 'Maximale Anzahl an Profilen erreicht ($max)';
  }

  @override
  String get memory => 'Speicher';

  @override
  String get moreResults => 'Mehr Ergebnisse anzeigen';

  @override
  String get moviesUnavailable => 'Filme nicht verf├╝gbar';

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
  String get navigateToOkToSelect => 'Zu OK navigieren zum Ausw├ñhlen';

  @override
  String get networkDisconnected => 'Netzwerk getrennt';

  @override
  String get never => 'nie';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get nextChannel => 'N├ñchster Sender';

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
  String get noChannelsAvailable => 'Keine Sender verf├╝gbar';

  @override
  String get noChromecastDeviceFound => 'Kein Chromecast-Ger├ñt gefunden.';

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
  String get noGroupAffinity => 'Keine gemeinsame Affinit├ñt gefunden';

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
  String get noMoviesAvailable => 'Keine Filme verf├╝gbar';

  @override
  String get noProfileAvailable => 'Kein Profil verf├╝gbar';

  @override
  String get noProfilesYet => 'Noch keine Profile vorhanden';

  @override
  String get noProgramInfoAvailable => 'Keine Programminformationen verf├╝gbar';

  @override
  String get noRankings => 'Keine Rankings';

  @override
  String get noRecommendations => 'Keine Empfehlungen verf├╝gbar';

  @override
  String get noReplaysInCategory => 'Keine Wiederholungen in dieser Kategorie';

  @override
  String noResultsFor(Object query) {
    return 'Keine Ergebnisse f├╝r $query';
  }

  @override
  String get noSeriesAvailable => 'Keine Serien verf├╝gbar';

  @override
  String get noStationsAvailable => 'Keine Stationen verf├╝gbar';

  @override
  String get noVideoQualityDetected => 'Keine Videoqualit├ñt erkannt';

  @override
  String get notAvailableInCatalog => 'Nicht im Katalog verf├╝gbar';

  @override
  String get offline => 'Offline';

  @override
  String get parentalControl => 'Kindersicherung';

  @override
  String get parentalControlSubtitle =>
      'PIN-Code hinzuf├╝gen und Inhalte einschr├ñnken';

  @override
  String get pauseDownload => 'Pausieren';

  @override
  String get pinCode => 'PIN-Code';

  @override
  String get pinDeleted => 'PIN gel├Âscht';

  @override
  String get pinMustBe4Digits => 'PIN muss genau 4 Ziffern enthalten';

  @override
  String get pinSaved => 'PIN gespeichert';

  @override
  String get pip => 'Bild-in-Bild (PiP)';

  @override
  String get pipUnavailable =>
      'Bild-in-Bild (PiP) auf diesem Ger├ñt nicht verf├╝gbar';

  @override
  String get playHistoryCleared => 'Wiedergabeverlauf gel├Âscht.';

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
  String profilesSelected(int count) {
    return '$count Profile ausgew├ñhlt';
  }

  @override
  String get profileVisible => 'Profil sichtbar';

  @override
  String get programGrid => 'Programmgrundriss';

  @override
  String get protectWithPin => 'Mit PIN-Code sch├╝tzen';

  @override
  String get rankingsUnavailable => 'Rankings nicht verf├╝gbar';

  @override
  String get recentSearch => 'Letzte Suche';

  @override
  String get recentSearches => 'Zuletzt gesucht';

  @override
  String get recentlyWatched => 'K├╝rzlich gesehen';

  @override
  String get removeAll => 'Alle entfernen';

  @override
  String get removeFromWatchedConfirm => 'Alle aus ÔÇ×GesehenÔÇØ entfernen?';

  @override
  String get replaysUnavailable => 'Wiederholungen nicht verf├╝gbar';

  @override
  String get reset => 'Zur├╝cksetzen';

  @override
  String get resetApp => 'App zur├╝cksetzen';

  @override
  String get resetAppDialogBody =>
      'Alle Daten werden gel├Âscht: Profile, Favoriten, Verlauf, Einstellungen. Diese Aktion ist nicht umkehrbar.';

  @override
  String get resetAppDialogConfirm => 'Alles l├Âschen';

  @override
  String get resetAppDialogTitle => 'App zur├╝cksetzen?';

  @override
  String get resetAppSubtitle =>
      'L├Âscht alle Benutzerdaten (Profile, Favoriten, Verlauf)';

  @override
  String get resetCompleted => 'Zur├╝cksetzen abgeschlossen';

  @override
  String get resumePlayback => 'Wiedergabe fortsetzen?';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get retrySearch => 'Suche erneut versuchen';

  @override
  String get rewind10s => '10s zur├╝ck';

  @override
  String get rewind30s => '30s zur├╝ck';

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
  String get sectionCloudSync => 'Cloud-Synchronisierung (mehrere Ger├ñte)';

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
  String get select => 'Ausw├ñhlen';

  @override
  String selectAtLeastOneProfile(int count) {
    return 'W├ñhle mindestens 1 weiteres Profil ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'W├ñhlen Sie ein Profil f├╝r Empfehlungen';

  @override
  String get series => 'Serien';

  @override
  String get seriesNotFound => 'Serie nicht gefunden';

  @override
  String get seriesUnavailable => 'Serien nicht verf├╝gbar';

  @override
  String get seriesUnavailableTemporarily => 'Serie derzeit nicht verf├╝gbar.';

  @override
  String get serverProtectedAntiLeech => 'Server gesch├╝tzt (Anti-Leech)';

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
  String get similarMovies => '├ähnliche Filme';

  @override
  String get snackBackupExported =>
      'Konfiguration in der Zwischenablage exportiert';

  @override
  String get snackCacheCleared => 'Caches geleert';

  @override
  String get snackCloudflareReset => 'Cloudflare-Konfiguration zur├╝ckgesetzt';

  @override
  String snackImportError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get snackImportSuccess => 'Konfiguration erfolgreich importiert';

  @override
  String get snackNoBackup => 'Keine Sicherung gefunden';

  @override
  String get sortAffinity => 'Nach Affinit├ñt';

  @override
  String get sortAffinityDescription =>
      'Sortiert nach deinem im Profil angegebenen Geschmack (Matchmaking)';

  @override
  String get sortAscending => 'Aufsteigende Reihenfolge';

  @override
  String get sortByDuration => 'Nach Dauer';

  @override
  String get sortByRating => 'Nach Bewertung';

  @override
  String get sortByYear => 'Nach Jahr';

  @override
  String get sortDescending => 'Absteigende Reihenfolge';

  @override
  String get sortLatestM3UXtream => 'Neueste M3U/Xtream-Erg├ñnzungen';

  @override
  String get sortNameAToZ => 'Name (A ÔåÆ Z)';

  @override
  String get sortNameZToA => 'Name (Z ÔåÆ A)';

  @override
  String get sortResumePriority => 'Fortsetzen priorisieren';

  @override
  String specialGuestsSeason(Object season) {
    return 'Gastschauspieler - Staffel $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'Starten';

  @override
  String get stationsUnavailable => 'Stationen nicht verf├╝gbar';

  @override
  String get stopCasting => 'Senden beenden';

  @override
  String get streamDetails => 'Stream-Details';

  @override
  String subtitleLoadError(Object error) {
    return 'Untertitel-Ladefehler: $error';
  }

  @override
  String get subtitlesUnavailable => 'Untertitel: nicht verf├╝gbar';

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
  String get theme => 'Thema';

  @override
  String get tlsImpersonation => 'TLS-Impersonation (lokaler Proxy)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simuliert den Fingerabdruck eines modernen Browsers, um Cloudflare zu umgehen';

  @override
  String get tmdbKeyActive =>
      'Pers├Ânlicher Schl├╝ssel aktiv ÔÇô gemeinsamer Schl├╝ssel wird ignoriert';

  @override
  String get tmdbKeyColumn => 'TMDB-Schl├╝ssel';

  @override
  String get tmdbKeyDelete => 'Pers├Ânlichen Schl├╝ssel l├Âschen';

  @override
  String get tmdbKeyHint =>
      'Standardm├ñ├ƒig wird der eingebettete gemeinsame Schl├╝ssel verwendet';

  @override
  String get tmdbKeyLabel => 'Pers├Ânlicher TMDB-API-Schl├╝ssel (optional)';

  @override
  String get tmdbKeyShared =>
      'Eingebetteter gemeinsamer Schl├╝ssel in Verwendung (kein pers├Ânlicher Schl├╝ssel)';

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
  String get aiTopicsTitle => 'KI-Empfohlene Themen';

  @override
  String get updateThisCategory => 'Diese Kategorie aktualisieren';

  @override
  String get updating => 'Aktualisierung l├ñuftÔÇª';

  @override
  String get updatingMediaContent => 'Medieninhalte werden aktualisiertÔÇª';

  @override
  String get volumeNormalization => 'Lautst├ñrke-Normalisierung';

  @override
  String get volumeNormalizationSubtitle =>
      'Grenzt Lautst├ñrke-Spitzen zwischen Kan├ñlen/Programmen ein (AGC)';

  @override
  String get watchLive => 'Live ansehen';

  @override
  String get whoIsWatching => 'Wer schaut zu?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Ihre Sender & Inhalte';

  @override
  String get subtitleSection => 'Untertitel';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'Video';

  @override
  String get autoQuality => 'Automatisch';

  @override
  String get subtitleNotApplicable => 'Nicht zutreffend';

  @override
  String get subtitleNotApplicableInfo =>
      'Ein Livestream stellt keine Untertitelspur bereit.';

  @override
  String get subtitleUnavailable => 'Nicht verf├╝gbar';

  @override
  String get subtitleNoTrack => 'Keine Spur';

  @override
  String get subtitleNoTrackInfo =>
      'Der Anbieter liefert f├╝r diesen Inhalt keine Untertitel.';

  @override
  String get subtitleGuessed => 'Ermittelte Spuren';

  @override
  String get subtitleGuessedInfo =>
      'Der Anbieter deklariert keine Untertitel: Diese Spuren werden aus einer URL-Konvention abgeleitet. Eine nicht vorhandene Spur meldet beim Aktivieren einen Fehler.';

  @override
  String get subtitleUnavailableToast => 'Untertitel nicht verf├╝gbar';

  @override
  String get audioTrackFallback => 'Tonspur';

  @override
  String get subtitleLoading => 'Untertitel werden geladenÔÇª';

  @override
  String get videoQualityFallback => 'Videoqualit├ñt';

  @override
  String get close => 'Schlie├ƒen';

  @override
  String get streamTracksError =>
      'Die Spuren dieses Streams konnten nicht gelesen werden.';

  @override
  String get subtitleProviderNoAnswer => 'Der Anbieter hat nicht geantwortet.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Untertitel nicht verf├╝gbar: $reason';
  }

  @override
  String get epgNoDataTitle => 'Keine Programmdaten';

  @override
  String get epgLiveNow => 'Live';

  @override
  String get epgSelectChannelHint =>
      'W├ñhlen Sie einen Sender, um sein Programm zu sehen';

  @override
  String get epgNow => 'Jetzt';

  @override
  String get epgZoomIn => 'Vergr├Â├ƒern';

  @override
  String get epgZoomOut => 'Verkleinern';

  @override
  String get epgNoCurrentProgram => 'Kein laufendes Programm';

  @override
  String replayWindowBadge(Object days) {
    return 'Replay $days T';
  }

  @override
  String replayWindowBadgeHours(Object hours) {
    return 'Replay $hours Std';
  }

  @override
  String get replayNoAvailable => 'Kein Replay verf├╝gbar';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'Kein bereits ausgestrahltes Programm innerhalb der $days-Tage-Archivs dieses Kontos f├╝r diesen Sender.';
  }

  @override
  String get replayNonePublished =>
      'Der Anbieter ver├Âffentlicht kein bereits ausgestrahltes Programm f├╝r diesen Sender.';

  @override
  String get epgActionFavorite => 'Favorit';

  @override
  String get epgActionRecording => 'Aufn.';

  @override
  String get epgActionReminder => 'Erinnerung';

  @override
  String get epgStartReplay => 'Replay starten';

  @override
  String get epgBack => 'Zur├╝ck';

  @override
  String epgWatchChannel(Object name) {
    return '$name ansehen';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'Der Anbieter liefert keine Untertitel f├╝r diesen Inhalt.';

  @override
  String subtitleVerifying(Object count) {
    return 'Untertitel werden gepr├╝ftÔÇª ($count)';
  }

  @override
  String get subtitleSearchOnline => 'Online suchen';

  @override
  String get subtitleSearchOnlineInfo =>
      'Der Anbieter bietet f├╝r diesen Inhalt nichts an. Eine Online-Suche findet m├Âglicherweise einen Untertitel.';

  @override
  String get subtitleSearchOnlineRunning => 'Suche l├ñuftÔÇª';

  @override
  String get subtitleOnlineResults => 'Online gefundene Untertitel';

  @override
  String get subtitleOnlineEmpty =>
      'Kein Untertitel online f├╝r diesen Inhalt gefunden.';

  @override
  String subtitleOnlineDownloads(Object count) {
    return '$count Downloads';
  }

  @override
  String get subtitleOnlineNoTmdb =>
      'Dieser Inhalt konnte auf TMDB nicht identifiziert werden: Die Online-Suche ben├Âtigt seine Kennung.';

  @override
  String get opensubtitlesKeyLabel => 'Online-Untertitelsuche (OpenSubtitles)';

  @override
  String get opensubtitlesKeyHint => 'API-Schl├╝ssel ÔÇö optional';

  @override
  String get opensubtitlesKeyActive =>
      'Schl├╝ssel gespeichert: h├Âheres Download-Limit.';

  @override
  String get opensubtitlesKeyAnonymous =>
      'Kein Schl├╝ssel: Suche m├Âglich, 5 Downloads pro IP und 24 h.';

  @override
  String get opensubtitlesKeyDelete => 'Schl├╝ssel l├Âschen';

  @override
  String get opensubtitlesKeyCheck => 'Schl├╝ssel pr├╝fen';

  @override
  String get opensubtitlesKeyChecking => 'Pr├╝fung l├ñuftÔÇª';

  @override
  String get opensubtitlesKeyValid =>
      'G├╝ltiger Schl├╝ssel: Der Dienst akzeptiert ihn.';

  @override
  String get opensubtitlesKeyRejected =>
      'Schl├╝ssel vom Dienst abgelehnt: Pr├╝fen Sie, ob Sie ihn vollst├ñndig eingef├╝gt haben.';

  @override
  String get opensubtitlesKeyUnreachable =>
      'Dienst nicht erreichbar: Pr├╝fen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get opensubtitlesLoginLabel => 'Anmeldung am OpenSubtitles-Konto';

  @override
  String get opensubtitlesLoginHintUsername => 'Benutzername';

  @override
  String get opensubtitlesLoginHintPassword => 'Passwort';

  @override
  String get opensubtitlesLoginActive =>
      'Konto gespeichert: Downloads k├Ânnen sich anmelden.';

  @override
  String get opensubtitlesLoginNone =>
      'Kein Konto: Downloads bleiben abgelehnt (503).';

  @override
  String get opensubtitlesLoginDelete => 'Konto l├Âschen';

  @override
  String get opensubtitlesLoginConnect => 'Anmelden / pr├╝fen';

  @override
  String get opensubtitlesLoginConnecting => 'Anmeldung l├ñuftÔÇª';

  @override
  String get opensubtitlesLoginValid =>
      'Konto akzeptiert: Der Dienst hat ein Token ausgestellt.';

  @override
  String get opensubtitlesLoginRejected =>
      'Zugangsdaten abgelehnt: Pr├╝fen Sie Benutzername und Passwort.';

  @override
  String get opensubtitlesLoginUnreachable =>
      'Dienst nicht erreichbar: Pr├╝fen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get subtitleOnlineNoApiKey =>
      'OpenSubtitles-API-Schl├╝ssel fehlt: In den Einstellungen eintragen, um die Online-Suche zu aktivieren.';

  @override
  String get subtitleOnlineKeyRejected =>
      'OpenSubtitles-API-Schl├╝ssel abgelehnt: Er ist eingetragen, aber der Dienst weist ihn zur├╝ck. Pr├╝fen Sie ihn in den Einstellungen.';

  @override
  String get subtitleOnlineQuota =>
      'OpenSubtitles-Download-Limit f├╝r heute erreicht. Morgen erneut versuchen.';

  @override
  String get subtitleOnlineNeedsLogin =>
      'Der OpenSubtitles-Download erfordert ein angemeldetes Konto, nicht nur den API-Schl├╝ssel: Die Suche funktioniert, aber der Download wird abgelehnt.';

  @override
  String get favorites => 'Favoriten';

  @override
  String get films => 'Filme';

  @override
  String get replay => 'Replay';

  @override
  String get myContent => 'Meine Inhalte';

  @override
  String get contentTypeSelector => 'Inhaltstyp';

  @override
  String get downloadStatusDownloading => 'Wird heruntergeladen';

  @override
  String get downloadStatusPreparing => 'Vorbereitung';

  @override
  String get downloadStatusPaused => 'Pausiert';

  @override
  String get downloadStatusCompleted => 'Fertig';

  @override
  String get downloadStatusFailed => 'Fehlgeschlagen';

  @override
  String get downloadStatusCancelled => 'Abgebrochen';

  @override
  String get downloadStatusQueued => 'In der Warteschlange';

  @override
  String get history => 'Verlauf';

  @override
  String get explore => 'Entdecken';

  @override
  String get downloadsEmptyHint =>
      'Inhalte ├╝ber die Detailseite eines Films oder einer Serie hinzuf├╝gen.';

  @override
  String get downloadsLocation => 'Dateien';

  @override
  String get advancedSettingsTitle => 'Erweiterte Einstellungen';

  @override
  String get advancedSettingsIntro =>
      'API-Zugangsdaten und Netzwerkeinstellungen. Diese Einstellungen binden Ihr Konto an Drittanbieter: Ein geteilter Schl├╝ssel verbraucht dessen Kontingent, und eine falsche Netzwerkeinstellung kann den Start der App verhindern.';

  @override
  String get advancedSubtitlesProvider => 'Untertitel-Anbieter';

  @override
  String get advancedStatus => 'Status der Zugangsdaten';

  @override
  String get advancedAccessTitle => 'Gesch├╝tzter Zugang';

  @override
  String get advancedAccessHint => 'Code';

  @override
  String get advancedAccessConfirm => '├ûffnen';

  @override
  String get advancedAccessWrong => 'Falscher Code';

  @override
  String get advancedHiddenHint =>
      'F├╝r erweiterte Einstellungen gedr├╝ckt halten';

  @override
  String get favoritesAndDownloads => 'Favoriten & Downloads';

  @override
  String get activeAudio => 'Ton auf diesem Bildschirm';

  @override
  String get addChannel => 'Sender hinzuf├╝gen';

  @override
  String get noChannelSelected => 'Kein Sender ausgew├ñhlt';

  @override
  String get removeChannel => 'Sender entfernen';

  @override
  String get avatarCategoryAll => 'Alle';

  @override
  String get avatarCategoryCharacters => 'Figuren';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Schwarz & Wei├ƒ';

  @override
  String get avatarCategoryPixels => 'Pixel';
}
