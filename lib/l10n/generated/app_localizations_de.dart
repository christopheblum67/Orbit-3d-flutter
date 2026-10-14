// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get accountDeviceProfile => 'GerÃ¤teprofil & Diagnose';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profil $label Â· Player-Diagnose';
  }

  @override
  String get accountNoSubscription => 'Kein aktives Abonnement';

  @override
  String get accountPreferences => 'Profil-Einstellungen';

  @override
  String get accountPreferencesSubtitle =>
      'Sprache, Design, AltersbeschrÃ¤nkungen, PIN';

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
  String get addSubscription => 'Abonnement hinzufÃ¼gen';

  @override
  String addedToFavorites(Object title) {
    return 'â€ž$titleâ€œ zu Favoriten hinzugefÃ¼gt';
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
  String get ageRange55plus => '55 Jahre und Ã¤lter';

  @override
  String get ageRangeUnder12 => '- 12 Jahre';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'In Suchen und Empfehlungen erscheinen';

  @override
  String get apply => 'Ãœbernehmen';

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
  String get audioShiftSubtitle => 'Manuelle Audio/Video-VerzÃ¶gerung (ms)';

  @override
  String get autoQualityDescription =>
      'LÃ¤sst den Player die beste QualitÃ¤t wÃ¤hlen';

  @override
  String get autoReconnectLive => 'Live-Autoverbindung';

  @override
  String get autoReconnectLiveSubtitle =>
      'Automatisch neu verbinden, wenn der Stream abbricht';

  @override
  String get avSyncDialogHint =>
      'Positiv = Audio voraus, Negativ = Audio verzÃ¶gert';

  @override
  String get avSyncDialogLabel => 'Offset (ms)';

  @override
  String get avSyncDialogTitle => 'A/V-Kalibrierung';

  @override
  String get backupExport => 'Konfiguration exportieren';

  @override
  String get backupExportSubtitle =>
      'Die vollstÃ¤ndige Konfiguration in die Zwischenablage kopieren';

  @override
  String get backupImport => 'Konfiguration importieren';

  @override
  String get backupImportSubtitle =>
      'Aus der Zwischenablage wiederherstellen (JSON)';

  @override
  String get bassKiller => 'Bass Killer (Schnitt < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'DÃ¤mpft tiefe Frequenzen, um Vibrationen zu vermeiden';

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
  String get certPinningAdd => 'Die obigen FingerabdrÃ¼cke hinzufÃ¼gen';

  @override
  String get certPinningHint =>
      'Erlaubte FingerabdrÃ¼cke (einer pro Zeile, hexadezimal in GroÃŸbuchstaben):';

  @override
  String get certPinningSubtitle =>
      'PrÃ¼ft den SHA-256-Fingerabdruck des SSL-Zertifikats des Servers (Anti-MITM)';

  @override
  String get changePinCode => 'PIN-Code Ã¤ndern';

  @override
  String get channelsUnavailable => 'Sender nicht verfÃ¼gbar';

  @override
  String get chooseProfile => 'Profil auswÃ¤hlen';

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
      'Lokale Ã„nderungen in die Cloud Ã¼bertragen';

  @override
  String get cloudSyncSubtitleOff =>
      'Favoriten, gesehene und zuletzt angesehen Inhalte mit der Cloud synchronisieren';

  @override
  String get cloudflareReset => 'Cloudflare-Konfiguration zurÃ¼cksetzen';

  @override
  String get cloudflareResetSubtitle =>
      'Cookies lÃ¶schen, TLS Impersonation=OFF, Standard ExoPlayer-UA';

  @override
  String get comingSoon => 'Bald verfÃ¼gbar';

  @override
  String get confirmAndContinue => 'BestÃ¤tigen und fortfahren';

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
  String get deleteAll => 'Alle lÃ¶schen';

  @override
  String get deleteAllConfirm => 'Alle lÃ¶schen?';

  @override
  String get deletePin => 'PIN lÃ¶schen';

  @override
  String get deleteProfileConfirm => 'Profil lÃ¶schen?';

  @override
  String get detailUnavailable => 'Details nicht verfÃ¼gbar';

  @override
  String get diagnosticUnavailable => 'Diagnose nicht verfÃ¼gbar';

  @override
  String get dialogueBoost => 'Dialog-Boost (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Hebt Stimmen gegenÃ¼ber Effekten/Musik hervor';

  @override
  String get disableSubtitles => 'Untertitel deaktivieren';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'DNS-Anbieter (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server fÃ¼r DNS-over-HTTPS-Anfragen';

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
  String get dpadNavigation => 'VerstÃ¤rkte D-Pad-Navigation';

  @override
  String get dpadNavigationSubtitle =>
      'Sichtbarer Fokus, Leuchtrahmen, Textumbruch (TV-Modus)';

  @override
  String get enableParentalControl => 'Kindersicherung aktivieren';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live: $live Â· VOD: $vod';
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
  String get fontSize => 'VergrÃ¶ÃŸerte TextgrÃ¶ÃŸe';

  @override
  String get fontSizeSubtitle => 'VergrÃ¶ÃŸert Texte in der gesamten App';

  @override
  String get forYou => 'FÃ¼r dich';

  @override
  String get forYouAndDuo => 'FÃ¼r dich & Im Duo';

  @override
  String get forYouMatchmaking => 'FÃ¼r dich (Matchmaking)';

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
      'Verbessert die Lesbarkeit fÃ¼r Sehbehinderte';

  @override
  String get historyUnavailable => 'Verlauf nicht verfÃ¼gbar';

  @override
  String get instantZapping => 'Sofort-Zapping (Vorabladen)';

  @override
  String get instantZappingSubtitle =>
      'Benachbarte KanÃ¤le in den Puffer vorladen';

  @override
  String get langArabic => 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©';

  @override
  String get langFrench => 'FranÃ§ais';

  @override
  String get langPortuguese => 'PortuguÃªs';

  @override
  String get langSpanish => 'EspaÃ±ol';

  @override
  String get language => 'Sprache';

  @override
  String get languageExample => 'FranÃ§ais, English, etc.';

  @override
  String get languagePreference => 'Anwendungssprache';

  @override
  String get languageUndetermined => 'Unbestimmt';

  @override
  String get later => 'SpÃ¤ter';

  @override
  String get legalNotice => 'Lies mich Â· Rechtlicher Hinweis';

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
  String get matchmaking => 'FÃ¼r dich (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Abgleich und personalisierte VorschlÃ¤ge verwalten';

  @override
  String maxProfilesReached(Object max) {
    return 'Maximale Anzahl an Profilen erreicht ($max)';
  }

  @override
  String get memory => 'Speicher';

  @override
  String get moreResults => 'Mehr Ergebnisse anzeigen';

  @override
  String get moviesUnavailable => 'Filme nicht verfÃ¼gbar';

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
  String get navigateToOkToSelect => 'Zu OK navigieren zum AuswÃ¤hlen';

  @override
  String get networkDisconnected => 'Netzwerk getrennt';

  @override
  String get never => 'nie';

  @override
  String get newAnd4K => 'Filme auf Abruf';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get nextChannel => 'NÃ¤chster Sender';

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
  String get noChannelsAvailable => 'Keine Sender verfÃ¼gbar';

  @override
  String get noChromecastDeviceFound => 'Kein Chromecast-GerÃ¤t gefunden.';

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
  String get noGroupAffinity => 'Keine gemeinsame AffinitÃ¤t gefunden';

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
  String get noMoviesAvailable => 'Keine Filme verfÃ¼gbar';

  @override
  String get noProfileAvailable => 'Kein Profil verfÃ¼gbar';

  @override
  String get noProfilesYet => 'Noch keine Profile vorhanden';

  @override
  String get noProgramInfoAvailable => 'Keine Programminformationen verfÃ¼gbar';

  @override
  String get noRankings => 'Keine Rankings';

  @override
  String get noRecommendations => 'Keine Empfehlungen verfÃ¼gbar';

  @override
  String get noReplaysInCategory => 'Keine Wiederholungen in dieser Kategorie';

  @override
  String noResultsFor(Object query) {
    return 'Keine Ergebnisse fÃ¼r $query';
  }

  @override
  String get noSeriesAvailable => 'Keine Serien verfÃ¼gbar';

  @override
  String get noStationsAvailable => 'Keine Stationen verfÃ¼gbar';

  @override
  String get noVideoQualityDetected => 'Keine VideoqualitÃ¤t erkannt';

  @override
  String get notAvailableInCatalog => 'Nicht im Katalog verfÃ¼gbar';

  @override
  String get offline => 'Offline';

  @override
  String get parentalControl => 'Kindersicherung';

  @override
  String get parentalControlSubtitle =>
      'PIN-Code hinzufÃ¼gen und Inhalte einschrÃ¤nken';

  @override
  String get pauseDownload => 'Pausieren';

  @override
  String get play => 'Abspielen';

  @override
  String get pinCode => 'PIN-Code';

  @override
  String get pinDeleted => 'PIN gelÃ¶scht';

  @override
  String get pinMustBe4Digits => 'PIN muss genau 4 Ziffern enthalten';

  @override
  String get pinSaved => 'PIN gespeichert';

  @override
  String get pip => 'Bild-in-Bild (PiP)';

  @override
  String get pipUnavailable =>
      'Bild-in-Bild (PiP) auf diesem GerÃ¤t nicht verfÃ¼gbar';

  @override
  String get playHistoryCleared => 'Wiedergabeverlauf gelÃ¶scht.';

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
    return '$count Profile ausgewÃ¤hlt';
  }

  @override
  String get profileVisible => 'Profil sichtbar';

  @override
  String get programGrid => 'Programmgrundriss';

  @override
  String get protectWithPin => 'Mit PIN-Code schÃ¼tzen';

  @override
  String get rankingsUnavailable => 'Rankings nicht verfÃ¼gbar';

  @override
  String get recentSearch => 'Letzte Suche';

  @override
  String get recentSearches => 'Zuletzt gesucht';

  @override
  String get recentlyWatched => 'KÃ¼rzlich gesehen';

  @override
  String get removeAll => 'Alle entfernen';

  @override
  String get removeFromWatchedConfirm => 'Alle aus â€žGesehenâ€ entfernen?';

  @override
  String get replaysUnavailable => 'Wiederholungen nicht verfÃ¼gbar';

  @override
  String get reset => 'ZurÃ¼cksetzen';

  @override
  String get resetApp => 'App zurÃ¼cksetzen';

  @override
  String get resetAppDialogBody =>
      'Alle Daten werden gelÃ¶scht: Profile, Favoriten, Verlauf, Einstellungen. Diese Aktion ist nicht umkehrbar.';

  @override
  String get resetAppDialogConfirm => 'Alles lÃ¶schen';

  @override
  String get resetAppDialogTitle => 'App zurÃ¼cksetzen?';

  @override
  String get resetAppSubtitle =>
      'LÃ¶scht alle Benutzerdaten (Profile, Favoriten, Verlauf)';

  @override
  String get resetCompleted => 'ZurÃ¼cksetzen abgeschlossen';

  @override
  String get resumePlayback => 'Wiedergabe fortsetzen?';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get retrySearch => 'Suche erneut versuchen';

  @override
  String get rewind10s => '10s zurÃ¼ck';

  @override
  String get rewind30s => '30s zurÃ¼ck';

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
  String get seasonsAndEpisodes => 'Serien auf Abruf';

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
  String get sectionCloudSync => 'Cloud-Synchronisierung (mehrere GerÃ¤te)';

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
  String get select => 'AuswÃ¤hlen';

  @override
  String selectAtLeastOneProfile(int count) {
    return 'WÃ¤hle mindestens 1 weiteres Profil ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'WÃ¤hlen Sie ein Profil fÃ¼r Empfehlungen';

  @override
  String get series => 'Serien';

  @override
  String get seriesNotFound => 'Serie nicht gefunden';

  @override
  String get seriesUnavailable => 'Serien nicht verfÃ¼gbar';

  @override
  String get seriesUnavailableTemporarily => 'Serie derzeit nicht verfÃ¼gbar.';

  @override
  String get serverProtectedAntiLeech => 'Server geschÃ¼tzt (Anti-Leech)';

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
  String get similarMovies => 'Ã„hnliche Filme';

  @override
  String get snackBackupExported =>
      'Konfiguration in der Zwischenablage exportiert';

  @override
  String get snackCacheCleared => 'Caches geleert';

  @override
  String get snackCloudflareReset => 'Cloudflare-Konfiguration zurÃ¼ckgesetzt';

  @override
  String snackImportError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get snackImportSuccess => 'Konfiguration erfolgreich importiert';

  @override
  String get snackNoBackup => 'Keine Sicherung gefunden';

  @override
  String get sortAffinity => 'Nach AffinitÃ¤t';

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
  String get sortLatestM3UXtream => 'Neueste M3U/Xtream-ErgÃ¤nzungen';

  @override
  String get sortNameAToZ => 'Name (A â†’ Z)';

  @override
  String get sortNameZToA => 'Name (Z â†’ A)';

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
  String get stationsUnavailable => 'Stationen nicht verfÃ¼gbar';

  @override
  String get stopCasting => 'Senden beenden';

  @override
  String get streamDetails => 'Stream-Details';

  @override
  String subtitleLoadError(Object error) {
    return 'Untertitel-Ladefehler: $error';
  }

  @override
  String get subtitlesUnavailable => 'Untertitel: nicht verfÃ¼gbar';

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
      'PersÃ¶nlicher SchlÃ¼ssel aktiv â€“ gemeinsamer SchlÃ¼ssel wird ignoriert';

  @override
  String get tmdbKeyColumn => 'TMDB-SchlÃ¼ssel';

  @override
  String get tmdbKeyDelete => 'PersÃ¶nlichen SchlÃ¼ssel lÃ¶schen';

  @override
  String get tmdbKeyHint =>
      'StandardmÃ¤ÃŸig wird der eingebettete gemeinsame SchlÃ¼ssel verwendet';

  @override
  String get tmdbKeyLabel => 'PersÃ¶nlicher TMDB-API-SchlÃ¼ssel (optional)';

  @override
  String get tmdbKeyShared =>
      'Eingebetteter gemeinsamer SchlÃ¼ssel in Verwendung (kein persÃ¶nlicher SchlÃ¼ssel)';

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
  String get updating => 'Aktualisierung lÃ¤uftâ€¦';

  @override
  String get updatingMediaContent => 'Medieninhalte werden aktualisiertâ€¦';

  @override
  String get volumeNormalization => 'LautstÃ¤rke-Normalisierung';

  @override
  String get volumeNormalizationSubtitle =>
      'Grenzt LautstÃ¤rke-Spitzen zwischen KanÃ¤len/Programmen ein (AGC)';

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
  String get noneOption => 'Keine';

  @override
  String get subtitleNotApplicable => 'Nicht zutreffend';

  @override
  String get subtitleNotApplicableInfo =>
      'Ein Livestream stellt keine Untertitelspur bereit.';

  @override
  String get subtitleUnavailable => 'Nicht verfÃ¼gbar';

  @override
  String get subtitleNoTrack => 'Keine Spur';

  @override
  String get subtitleNoTrackInfo =>
      'Der Anbieter liefert fÃ¼r diesen Inhalt keine Untertitel.';

  @override
  String get subtitleGuessed => 'Ermittelte Spuren';

  @override
  String get subtitleGuessedInfo =>
      'Der Anbieter deklariert keine Untertitel: Diese Spuren werden aus einer URL-Konvention abgeleitet. Eine nicht vorhandene Spur meldet beim Aktivieren einen Fehler.';

  @override
  String get subtitleUnavailableToast => 'Untertitel nicht verfÃ¼gbar';

  @override
  String get audioTrackFallback => 'Tonspur';

  @override
  String get subtitleLoading => 'Untertitel werden geladenâ€¦';

  @override
  String get videoQualityFallback => 'VideoqualitÃ¤t';

  @override
  String get close => 'SchlieÃŸen';

  @override
  String get streamTracksError =>
      'Die Spuren dieses Streams konnten nicht gelesen werden.';

  @override
  String get subtitleProviderNoAnswer => 'Der Anbieter hat nicht geantwortet.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Untertitel nicht verfÃ¼gbar: $reason';
  }

  @override
  String get epgNoDataTitle => 'Keine Programmdaten';

  @override
  String get epgLiveNow => 'Live';

  @override
  String get epgSelectChannelHint =>
      'WÃ¤hlen Sie einen Sender, um sein Programm zu sehen';

  @override
  String get epgNow => 'Jetzt';

  @override
  String get epgZoomIn => 'VergrÃ¶ÃŸern';

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
  String get replayNoAvailable => 'Kein Replay verfÃ¼gbar';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'Kein bereits ausgestrahltes Programm innerhalb der $days-Tage-Archivs dieses Kontos fÃ¼r diesen Sender.';
  }

  @override
  String get replayNonePublished =>
      'Der Anbieter verÃ¶ffentlicht kein bereits ausgestrahltes Programm fÃ¼r diesen Sender.';

  @override
  String get epgActionFavorite => 'Favorit';

  @override
  String get epgActionRecording => 'Aufn.';

  @override
  String get epgActionReminder => 'Erinnerung';

  @override
  String get epgStartReplay => 'Replay starten';

  @override
  String get epgBack => 'ZurÃ¼ck';

  @override
  String epgWatchChannel(Object name) {
    return '$name ansehen';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'Der Anbieter liefert keine Untertitel fÃ¼r diesen Inhalt.';

  @override
  String subtitleVerifying(Object count) {
    return 'Untertitel werden geprÃ¼ftâ€¦ ($count)';
  }

  @override
  String get subtitleSearchOnline => 'Online suchen';

  @override
  String get subtitleSearchOnlineInfo =>
      'Der Anbieter bietet fÃ¼r diesen Inhalt nichts an. Eine Online-Suche findet mÃ¶glicherweise einen Untertitel.';

  @override
  String get subtitleSearchOnlineRunning => 'Suche lÃ¤uftâ€¦';

  @override
  String get subtitleOnlineResults => 'Online gefundene Untertitel';

  @override
  String get subtitleOnlineEmpty =>
      'Kein Untertitel online fÃ¼r diesen Inhalt gefunden.';

  @override
  String subtitleOnlineDownloads(Object count) {
    return '$count Downloads';
  }

  @override
  String get subtitleOnlineNoTmdb =>
      'Dieser Inhalt konnte auf TMDB nicht identifiziert werden: Die Online-Suche benÃ¶tigt seine Kennung.';

  @override
  String get opensubtitlesKeyLabel => 'Online-Untertitelsuche (OpenSubtitles)';

  @override
  String get opensubtitlesKeyHint => 'API-SchlÃ¼ssel â€” optional';

  @override
  String get opensubtitlesKeyActive =>
      'SchlÃ¼ssel gespeichert: hÃ¶heres Download-Limit.';

  @override
  String get opensubtitlesKeyAnonymous =>
      'Kein SchlÃ¼ssel: Suche mÃ¶glich, 5 Downloads pro IP und 24 h.';

  @override
  String get opensubtitlesKeyDelete => 'SchlÃ¼ssel lÃ¶schen';

  @override
  String get opensubtitlesKeyCheck => 'SchlÃ¼ssel prÃ¼fen';

  @override
  String get opensubtitlesKeyChecking => 'PrÃ¼fung lÃ¤uftâ€¦';

  @override
  String get opensubtitlesKeyValid =>
      'GÃ¼ltiger SchlÃ¼ssel: Der Dienst akzeptiert ihn.';

  @override
  String get opensubtitlesKeyRejected =>
      'SchlÃ¼ssel vom Dienst abgelehnt: PrÃ¼fen Sie, ob Sie ihn vollstÃ¤ndig eingefÃ¼gt haben.';

  @override
  String get opensubtitlesKeyUnreachable =>
      'Dienst nicht erreichbar: PrÃ¼fen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get opensubtitlesLoginLabel => 'Anmeldung am OpenSubtitles-Konto';

  @override
  String get opensubtitlesLoginHintUsername => 'Benutzername';

  @override
  String get opensubtitlesLoginHintPassword => 'Passwort';

  @override
  String get opensubtitlesLoginActive =>
      'Konto gespeichert: Downloads kÃ¶nnen sich anmelden.';

  @override
  String get opensubtitlesLoginNone =>
      'Kein Konto: Downloads bleiben abgelehnt (503).';

  @override
  String get opensubtitlesLoginDelete => 'Konto lÃ¶schen';

  @override
  String get opensubtitlesLoginConnect => 'Anmelden / prÃ¼fen';

  @override
  String get opensubtitlesLoginConnecting => 'Anmeldung lÃ¤uftâ€¦';

  @override
  String get opensubtitlesLoginValid =>
      'Konto akzeptiert: Der Dienst hat ein Token ausgestellt.';

  @override
  String get opensubtitlesLoginRejected =>
      'Zugangsdaten abgelehnt: PrÃ¼fen Sie Benutzername und Passwort.';

  @override
  String get opensubtitlesLoginUnreachable =>
      'Dienst nicht erreichbar: PrÃ¼fen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get subtitleOnlineNoApiKey =>
      'OpenSubtitles-API-SchlÃ¼ssel fehlt: In den Einstellungen eintragen, um die Online-Suche zu aktivieren.';

  @override
  String get subtitleOnlineKeyRejected =>
      'OpenSubtitles-API-SchlÃ¼ssel abgelehnt: Er ist eingetragen, aber der Dienst weist ihn zurÃ¼ck. PrÃ¼fen Sie ihn in den Einstellungen.';

  @override
  String get subtitleOnlineQuota =>
      'OpenSubtitles-Download-Limit fÃ¼r heute erreicht. Morgen erneut versuchen.';

  @override
  String get subtitleOnlineNeedsLogin =>
      'Der OpenSubtitles-Download erfordert ein angemeldetes Konto, nicht nur den API-SchlÃ¼ssel: Die Suche funktioniert, aber der Download wird abgelehnt.';

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
      'Inhalte Ã¼ber die Detailseite eines Films oder einer Serie hinzufÃ¼gen.';

  @override
  String get downloadsLocation => 'Dateien';

  @override
  String get advancedSettingsTitle => 'Erweiterte Einstellungen';

  @override
  String get advancedSettingsIntro =>
      'API-Zugangsdaten und Netzwerkeinstellungen. Diese Einstellungen binden Ihr Konto an Drittanbieter: Ein geteilter SchlÃ¼ssel verbraucht dessen Kontingent, und eine falsche Netzwerkeinstellung kann den Start der App verhindern.';

  @override
  String get advancedSubtitlesProvider => 'Untertitel-Anbieter';

  @override
  String get advancedStatus => 'Status der Zugangsdaten';

  @override
  String get advancedAccessTitle => 'GeschÃ¼tzter Zugang';

  @override
  String get advancedAccessHint => 'Code';

  @override
  String get advancedAccessConfirm => 'Ã–ffnen';

  @override
  String get advancedAccessWrong => 'Falscher Code';

  @override
  String get advancedHiddenHint =>
      'FÃ¼r erweiterte Einstellungen gedrÃ¼ckt halten';

  @override
  String get favoritesAndDownloads => 'Favoriten & Downloads';

  @override
  String get activeAudio => 'Ton auf diesem Bildschirm';

  @override
  String get addChannel => 'Sender hinzufÃ¼gen';

  @override
  String get noChannelSelected => 'Kein Sender ausgewÃ¤hlt';

  @override
  String get removeChannel => 'Sender entfernen';

  @override
  String get avatarCategoryAll => 'Alle';

  @override
  String get avatarCategoryCharacters => 'Figuren';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Schwarz & WeiÃŸ';

  @override
  String get avatarCategoryPixels => 'Pixel';
}
