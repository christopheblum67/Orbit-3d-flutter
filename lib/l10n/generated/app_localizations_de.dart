// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get castSearching => 'Suche nach Cast-Geräten…';

  @override
  String get castReceiverNotReady => 'Empfänger ist noch nicht bereit';

  @override
  String castConnectedTo(String name) {
    return 'Mit $name verbunden';
  }

  @override
  String castConnectionFailed(String name) {
    return 'Verbindung mit $name nicht möglich.';
  }

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNightFocusOn => 'Night Focus (an)';

  @override
  String get playerNightFocusOff => 'Night Focus (aus)';

  @override
  String get playerLoadingProgram => 'Sendung wird geladen…';

  @override
  String get audioNightHelp =>
      'Die Klangoptimierung gilt für die native Wiedergabe, wenn Night Focus aktiviert ist. Die Einstellungen werden für die nächste Wiedergabe gespeichert.';

  @override
  String get audioNightTitle => 'Nachtoptimierung (Night Focus)';

  @override
  String get audioDialogueBoost => 'Dialogverstärkung';

  @override
  String get audioDialogueHelp =>
      'Verstärkt den Frequenzbereich von Stimmen (1–4 kHz)';

  @override
  String get audioBassLimiter => 'Bassreduzierung und Limiter';

  @override
  String get audioBassHelp =>
      'Dämpft tiefe Bässe und komprimiert plötzliche Spitzen';

  @override
  String get audioVocalGain => 'Stimmenverstärkung:';

  @override
  String get audioSyncTitle => 'Audioverzögerung (A/V-Sync)';

  @override
  String startupResumeQuestion(String title, String position) {
    return '„$title“ bei $position fortsetzen?';
  }

  @override
  String get startupLastSession => 'Letzte Sitzung';

  @override
  String get seriesExternalTracksHint =>
      'Wählen Sie Tonspuren und Untertitel bei einem externen Player dort aus. Die folgenden Einstellungen gelten für den internen Player.';

  @override
  String seriesResetWatchedBody(int count, String title) {
    return 'Die $count angesehenen Folgen von „$title“ werden für dieses Profil als ungesehen markiert.';
  }

  @override
  String seriesResetWatchedDone(String title) {
    return '„$title“ aus den angesehenen Inhalten entfernt.';
  }

  @override
  String get recommendationAffinity => 'Affinität';

  @override
  String get recommendationLoadingCatalog => 'Katalog wird geladen…';

  @override
  String get recommendationBuilding => 'Ihre Empfehlungen werden erstellt…';

  @override
  String get recommendationLoadingDuration =>
      'Dies kann bis zu 1 Minute dauern.';

  @override
  String get memoryPanelTitle => 'Speicher und Cache';

  @override
  String get memoryPanelHelp =>
      'Verlauf und Bildcache im Arbeitsspeicher leeren.';

  @override
  String get memoryHistoryTitle => 'Wiedergabeverlauf löschen';

  @override
  String get memoryHistoryHelp =>
      'Löscht den globalen Verlauf und ältere zuletzt angesehene Einträge sowie zuletzt angesehene Inhalte und Wiedergabepositionen des aktuellen Profils.';

  @override
  String get memoryClear => 'Löschen';

  @override
  String get memoryImagesTitle => 'Bildcache im Arbeitsspeicher leeren';

  @override
  String get memoryImagesHelp =>
      'Gibt Bilder im Arbeitsspeicher frei; zwischengespeicherte Dateien auf dem Datenträger bleiben erhalten.';

  @override
  String get memoryPurge => 'Leeren';

  @override
  String get sortOptionsTitle => 'Erweiterte Sortieroptionen';

  @override
  String get sortOptionsHelp => 'Wählen Sie einen Modus mit der Fernbedienung:';

  @override
  String get sortRecentDescription => 'Kürzlich importierte Inhalte';

  @override
  String get sortResumeDescription =>
      'Begonnene, nicht abgeschlossene Inhalte zuerst';

  @override
  String get sortRatingDescription => 'Sortierung nach Bewertungen';

  @override
  String get sortYearDescription =>
      'Chronologische Sortierung nach Produktionsjahr';

  @override
  String get sortDurationDescription => 'Sortierung nach Dauer';

  @override
  String get sortActive => 'Aktiv';

  @override
  String get onboardingWelcome => 'Willkommen bei Orbit IPTV';

  @override
  String get onboardingSubtitle => 'Automatische Geräteeinrichtung';

  @override
  String get onboardingDeviceDetected => 'Gerät erkannt';

  @override
  String get onboardingDevice => 'Gerät';

  @override
  String get onboardingConnection => 'Verbindung';

  @override
  String get onboardingMobileNetwork => 'Mobilfunknetz';

  @override
  String get onboardingOtherNetwork => 'Sonstige';

  @override
  String get onboardingUnknownMemory => 'Unbekannt';

  @override
  String onboardingMemoryMb(String value) {
    return '$value MB';
  }

  @override
  String onboardingMemoryGb(String value) {
    return '$value GB';
  }

  @override
  String get onboardingEco => 'Sparmodus';

  @override
  String onboardingProfile(String name) {
    return 'Profil $name';
  }

  @override
  String get onboardingEcoDescription =>
      'Schnellstart (1,5 s) · max. 1080p · 3D und Multiview aus';

  @override
  String get onboardingStandardDescription =>
      'Schnellstart (2 s) · flüssiges 3D · Multiview x2';

  @override
  String get onboardingUltraDescription =>
      'Schneller Senderwechsel (3 s · 4K HDR möglich) · Multiview x4';

  @override
  String get onboardingResetRecommendation => 'Empfehlung zurücksetzen';

  @override
  String get onboardingAdjust => 'Manuell anpassen';

  @override
  String get onboardingChooseProfile => 'Profil auswählen';

  @override
  String get onboardingRecommendedProfile => 'Empfohlenes Profil';

  @override
  String get onboardingEcoHint => '3D-Effekte und Multiview deaktiviert.';

  @override
  String get duoTitle => 'Duo-Modus';

  @override
  String duoChooseOthers(int max) {
    return 'Wählen Sie 1 bis $max weitere Profile';
  }

  @override
  String duoChooseWith(String name, int max) {
    return 'Mit „$name“ — wählen Sie 1 bis $max weitere Profile';
  }

  @override
  String get duoCreateProfile => 'Erstellen Sie mindestens ein zweites Profil';

  @override
  String get duoNeedsProfiles =>
      'Der Duo-Modus benötigt insgesamt mindestens 2 Profile.';

  @override
  String get duoFull => '4 Profile — das Duo-Team ist komplett';

  @override
  String duoReady(int count) {
    return '$count Profile ausgewählt — bereit für Duo';
  }

  @override
  String duoSelectOne(int count) {
    return 'Wählen Sie mindestens 1 weiteres Profil ($count/4)';
  }

  @override
  String get duoStart => 'Duo starten';

  @override
  String get duoSelected => 'Ausgewählt';

  @override
  String get duoMaximum => 'Maximum erreicht';

  @override
  String get legalIntroTitle => 'Orbit IPTV · Bitte lesen';

  @override
  String get legalIntro =>
      'Vor dem Start finden Sie hier kurze Informationen zur Nutzung dieser App und zu den Rechten an den angezeigten Inhalten.';

  @override
  String get legalServicePlayer =>
      'Orbit IPTV ist ein IPTV-Player: Er zeigt Streams von Drittservern (M3U- / Xtream-Codes-Abonnement) an, ohne Video-, Audio- oder Untertitelinhalte zu hosten.';

  @override
  String get legalServiceMetadata =>
      'Die App bündelt und zeigt Metadaten (Poster, Inhaltsangaben, EPG) aus öffentlichen APIs an. Sie dient als spezialisierter Browser für HLS-/DASH-Streams.';

  @override
  String get legalRightsProvider =>
      'Der IPTV-Abonnementanbieter ist allein für Senderlizenzen, Übertragungsrechte und Geoblocking der bereitgestellten Streams verantwortlich.';

  @override
  String get legalRightsMetadata =>
      'Poster und Inhaltsangaben stammen unter API-Lizenz von TMDb; der TMDb-Hinweis steht am Ende der Ranglistenseite.';

  @override
  String get legalRightsContent =>
      'Orbit IPTV speichert, verbreitet und monetarisiert keine gestreamten Inhalte.';

  @override
  String get legalUsageTitle => 'Nutzung der App';

  @override
  String get legalUsageRights =>
      'Nur mit einem Abonnement nutzen, für das Sie die Übertragungsrechte besitzen.';

  @override
  String get legalUsageRestrictions =>
      'Geoblocking oder DRM dürfen nicht umgangen und Konten nicht außerhalb des Haushalts geteilt werden.';

  @override
  String get legalUsageEditorial =>
      'Die App trifft keine redaktionelle Auswahl der gestreamten Inhalte und hat keine Kontrolle über Streams von Drittservern.';

  @override
  String get legalPrivacyStorage =>
      'Profile, Favoriten, Verlauf und Einstellungen werden lokal gespeichert. Wenn Sie die Cloud-Freigabe aktivieren, werden ausgewählte Daten zusätzlich verschlüsselt synchronisiert.';

  @override
  String get legalPrivacyConsent =>
      'Standardmäßig werden keine Daten erhoben; Benachrichtigungen und optionale Zugriffe erfordern eine ausdrückliche Zustimmung.';

  @override
  String get legalWarningTitle => 'Warnung';

  @override
  String get legalWarningBody =>
      'Dieses Dokument stellt keine Rechtsberatung dar. Die Regeln unterscheiden sich je nach Rechtsgebiet: Prüfen Sie, ob Ihre Nutzung in Ihrem Land zulässig ist (geltendes Recht, Mindestalter).';

  @override
  String get legalAccept => 'Gelesen und akzeptiert · Weiter';

  @override
  String get epgReplayAvailableOnChannel =>
      'Replay auf diesem Sender verfügbar';

  @override
  String actorBornOn(String date) {
    return 'Geboren am $date';
  }

  @override
  String get actorGenderMale => 'Männlich';

  @override
  String get actorGenderFemale => 'Weiblich';

  @override
  String get crewTitle => 'Filmteam';

  @override
  String get crewDirecting => 'Regie';

  @override
  String get crewWriting => 'Drehbuch';

  @override
  String get crewProduction => 'Produktion';

  @override
  String get crewSound => 'Ton';

  @override
  String get crewCamera => 'Kamera';

  @override
  String get crewEditing => 'Schnitt';

  @override
  String get crewArt => 'Szenenbild';

  @override
  String get crewCostume => 'Kostüm und Maske';

  @override
  String get crewVisualEffects => 'Visuelle Effekte';

  @override
  String get crewLighting => 'Beleuchtung';

  @override
  String get menuContinue => 'Fortsetzen';

  @override
  String get menuDiscover => 'Entdecken';

  @override
  String get menuHome => 'Startseite';

  @override
  String get menuSearch => 'Suche';

  @override
  String get menuProfile => 'Profil';

  @override
  String get menuSubscriptions => 'Abonnements';

  @override
  String get menuSelect => 'Untermenü auswählen';

  @override
  String get menuContent => 'Inhalte';

  @override
  String get profileMustKeepOne =>
      'Mindestens ein Profil muss auf dem Gerät verbleiben';

  @override
  String profileDeleteBody(String name) {
    return '„$name“ und die zugehörigen Einstellungen werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get profileChange => 'Profil wechseln';

  @override
  String get profileEdit => 'Bearbeiten';

  @override
  String get profileDelete => 'Löschen';

  @override
  String get profileBack => 'Zurück';

  @override
  String get profileAdult => 'Erwachsene';

  @override
  String get profileChild => 'Kind';

  @override
  String get profileExpert => 'Experte';

  @override
  String get categoryTitle => 'Kategorien';

  @override
  String get categoryShowAll => 'Alle anzeigen';

  @override
  String get categoryScanFailed =>
      'Scan fehlgeschlagen: Der Anbieter antwortet nicht.';

  @override
  String get categoryEmptyLive =>
      'Keine Live-TV-Kategorien bei diesem Anbieter.';

  @override
  String get categoryEmptyMovies => 'Keine Filmkategorien bei diesem Anbieter.';

  @override
  String get categoryEmptySeries =>
      'Keine Serienkategorien bei diesem Anbieter.';

  @override
  String categoryHidden(String label, int count) {
    return '$label ($count ausgeblendet)';
  }

  @override
  String get categoryNeverScanned => 'Nie gescannt';

  @override
  String get categoryScannedToday => 'Heute gescannt';

  @override
  String get categoryScannedYesterday => 'Gestern gescannt';

  @override
  String categoryScannedDaysAgo(int days) {
    return 'Vor $days Tagen gescannt';
  }

  @override
  String categorySubscriptionSettings(String status) {
    return 'Einstellungen für dieses Abonnement — $status';
  }

  @override
  String get categoryScanning => 'Wird gescannt…';

  @override
  String get categoryRescan => 'Kategorien erneut scannen';

  @override
  String categoryChannelsCount(int count) {
    return '$count Sender';
  }

  @override
  String categoryTitlesCount(int count) {
    return '$count Titel';
  }

  @override
  String get liveWatchAction => 'Ansehen';

  @override
  String get livePreviewDisabled =>
      'Die Videovorschau ist deaktiviert. Drücke auf Ansehen, um den Sender zu öffnen.';

  @override
  String get livePreviewFrozen => 'Vorschau eingefroren';

  @override
  String get livePreviewRetry => 'Erneut versuchen';

  @override
  String get episodeMarkWatchedFailed =>
      'Die Episode konnte nicht als angesehen markiert werden.';

  @override
  String get episodeAlreadyWatched => 'Episode bereits angesehen';

  @override
  String get episodeMarkWatched => 'Als angesehen markieren';

  @override
  String episodeResumeAt(String position) {
    return 'Fortsetzen bei $position';
  }

  @override
  String get episodeActionsHelp =>
      'OK gedrückt halten, um als angesehen zu markieren oder zurückzusetzen.';

  @override
  String episodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episoden',
      one: '1 Episode',
    );
    return '$_temp0';
  }

  @override
  String episodesInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episoden angefangen',
      one: '1 Episode angefangen',
    );
    return '$_temp0';
  }

  @override
  String episodesWatchedCount(int seen, int total) {
    return '$seen/$total angesehen';
  }

  @override
  String get episodeWatched => 'Angesehen';

  @override
  String get homeRefreshFailed =>
      'Aktualisierung fehlgeschlagen: Keine Quelle hat geantwortet.';

  @override
  String get homeRefreshDone => 'Aktualisierung abgeschlossen.';

  @override
  String get homeRefreshEmpty =>
      'Aktualisierung abgeschlossen, keine Daten verfügbar.';

  @override
  String get homeChangeSubscription => 'Abonnement wechseln';

  @override
  String get homeManageSubscription => 'Abonnement verwalten';

  @override
  String get homeNoSubscription => 'Kein Abo';

  @override
  String get homeAddOrChangeSubscription =>
      'Abonnement hinzufügen oder wechseln';

  @override
  String get homeMultiStream => 'Bis zu 4 Streams gleichzeitig';

  @override
  String get homeRadioStations => 'Live-Sender';

  @override
  String get homeRefreshUnknown => 'Letzte Aktualisierung unbekannt';

  @override
  String homeRefreshMinutes(int minutes) {
    return 'Vor $minutes Min. aktualisiert';
  }

  @override
  String get catalogAll => 'Alle';

  @override
  String get catalogUngrouped => 'Nicht gruppiert';

  @override
  String get catalogSort => 'Sortieren';

  @override
  String get browseLoading => 'Wird geladen…';

  @override
  String get startupRadio => 'Radiosender';

  @override
  String get profileCreateFirstHint =>
      'Erstelle dein erstes Profil, um loszulegen.';

  @override
  String downloadDirectoryMissing(String path) {
    return 'Verzeichnis nicht gefunden: $path';
  }

  @override
  String downloadFileMissing(String path, String names) {
    return 'Datei nicht gefunden: $path. Vorhandene Dateien: $names';
  }

  @override
  String get widevineSelectSubscription => 'Wähle ein aktives Abonnement';

  @override
  String get widevineLoading => 'Konfiguration wird geladen';

  @override
  String get widevineLoadFailed => 'Konfiguration konnte nicht geladen werden';

  @override
  String widevineNoLicense(String subscription) {
    return '$subscription: keine Lizenz konfiguriert';
  }

  @override
  String get widevineSelectFirst => 'Wähle zuerst ein aktives Abonnement.';

  @override
  String get widevineUnavailable =>
      'Die Widevine-Konfiguration ist nicht verfügbar.';

  @override
  String widevineSaveFailed(String error) {
    return 'Widevine konnte nicht gespeichert werden: $error';
  }

  @override
  String widevineClearFailed(String error) {
    return 'Widevine konnte nicht gelöscht werden: $error';
  }

  @override
  String get widevineLicenseUrl => 'URL des Lizenzservers';

  @override
  String get widevineInvalidUrl => 'Gib eine gültige HTTPS-URL ein.';

  @override
  String get widevineHeaders => 'HTTP-Header (JSON, optional)';

  @override
  String get widevineInvalidHeaders =>
      'Die Header müssen ein JSON-Objekt aus Zeichenfolgen sein.';

  @override
  String get widevineCertificate => 'Base64-Zertifikat (optional)';

  @override
  String get widevineStorageHelp =>
      'Die Konfiguration wird sicher gespeichert und ist mit diesem Abonnement verknüpft. Sie macht keinen Player kompatibel, der Widevine nicht unterstützt.';

  @override
  String get widevineCopyLegacy => 'Vorherige globale Konfiguration kopieren';

  @override
  String get widevineClear => 'Löschen';

  @override
  String get preferenceMultiTvFailed =>
      'Die Multi-TV-Einstellung konnte nicht gespeichert werden.';

  @override
  String get preferenceLight => 'Hell';

  @override
  String get preferenceDark => 'Dunkel';

  @override
  String get preferenceDisabled => 'Deaktiviert';

  @override
  String preferenceParentalEnabled(String restriction) {
    return 'Aktiviert · Altersbeschränkung $restriction';
  }

  @override
  String get preferenceMultiTvHelp =>
      'Multibildschirm-Wiedergabe für dieses Profil anzeigen und zulassen.';

  @override
  String get preferenceAllowRecording => 'Aufnahme erlauben';

  @override
  String get preferenceRecordingHelp =>
      'Aufnahme meiner Lieblingsinhalte erlauben';

  @override
  String get preferenceLivePreview => 'Live-Videovorschau';

  @override
  String get preferenceLivePreviewHelp =>
      'Zeigt Live-Video beim Durchsuchen der Sender. Diese Einstellung gilt für das Gerät.';

  @override
  String get preferenceProfileHelp =>
      'Deine Einstellungen werden auf dein Profil angewendet.';

  @override
  String get parentalAgeLimit => 'Altersbeschränkung';

  @override
  String get parentalNone => 'Keine';

  @override
  String get parentalHideAdult => 'Erwachsenen-Inhalte ausblenden';

  @override
  String get parentalHideAdultHelp =>
      'Filme, Serien und Sender ab 18 oder mit erotischen Inhalten';

  @override
  String get parentalHideViolence => 'Gewalt ausblenden';

  @override
  String get parentalHideViolenceHelp => 'Gore / Horror / Thriller / Mord';

  @override
  String get parentalCurrentPin => 'Aktuelle PIN: ••••';

  @override
  String get parentalSetPin => 'PIN festlegen';

  @override
  String get parentalNewPin => 'Neue PIN (4 Ziffern)';

  @override
  String get parentalPin => 'PIN (4 Ziffern)';

  @override
  String get parentalShowPin => 'PIN anzeigen';

  @override
  String get parentalHidePin => 'PIN verbergen';

  @override
  String get parentalUpdatePin => 'PIN aktualisieren';

  @override
  String get subtitleAvailableTracks => 'Verfügbare Spuren';

  @override
  String get subtitleAddUrl => 'Untertitel hinzufügen (.srt/.vtt-URL)';

  @override
  String get subtitleLoadAction => 'Laden';

  @override
  String subtitleTrackCues(String language, int count) {
    return '$language · $count Einträge';
  }

  @override
  String multiMaxStreams(int count) {
    return 'Maximum: $count Streams auf diesem Gerät.';
  }

  @override
  String get multiDisabledProfile =>
      'Multi TV ist für dieses Profil deaktiviert. Aktiviere es in den Profileinstellungen.';

  @override
  String get multiAnalyzingDevice => 'Gerät wird analysiert…';

  @override
  String get multiDeviceAnalysisFailed => 'Geräteanalyse fehlgeschlagen';

  @override
  String get multiDisabledEconomy =>
      'Multiview ist im Sparprofil deaktiviert.\nÄndere das Profil unter Gerät konfigurieren.';

  @override
  String engineInternal(String name) {
    return '$name (Intern)';
  }

  @override
  String engineExternal(String name) {
    return '$name (Extern)';
  }

  @override
  String get engineSelectionHelp =>
      'Wähle für jeden Inhaltstyp den Player und den Ersatzplayer bei Wiedergabefehlern.';

  @override
  String get engineVideoDecoding => 'Videodekodierung';

  @override
  String get engineAutoRecommended => 'Auto (empfohlen)';

  @override
  String get engineHardware => 'Hardware';

  @override
  String get engineSoftware => 'Software';

  @override
  String get engineAutoSoftware => 'Auto: Software für dieses Gerät ausgewählt';

  @override
  String get engineSubtitleDefault => 'Standard';

  @override
  String get engineSubtitleDisabled => 'Keine Untertitel';

  @override
  String get engineSubtitleForced => 'Erzwungene Untertitel';

  @override
  String get engineVodSubtitles => 'VOD-Untertitel';

  @override
  String get profilePinsNone => 'Kein Profil besitzt eine PIN.';

  @override
  String get profilePinsRemoveQuestion => 'PINs der Profile entfernen?';

  @override
  String profilePinsRemoveConfirmation(int count) {
    return 'Die PINs werden von $count Profil(en) entfernt. Profile und ihre Daten bleiben auf diesem Gerät. Die Änderungen können mit über die Cloud geteilten Geräten synchronisiert werden.';
  }

  @override
  String get profilePinsRemove => 'PINs entfernen';

  @override
  String get profilePinsNothingToRemove => 'Keine PINs zu entfernen.';

  @override
  String profilePinsRemoved(int count) {
    return 'PINs von $count Profil(en) entfernt.';
  }

  @override
  String get profilePinsRemoveFailed =>
      'PINs konnten nicht entfernt werden. Versuche es erneut.';

  @override
  String get profileProtection => 'Profilschutz';

  @override
  String get profilePinsRemoveHelp =>
      'Entferne die PINs aller Profile auf diesem Gerät. Die Profile und ihre Daten werden nicht gelöscht.';

  @override
  String get profilePinsRemoving => 'PINs werden entfernt…';

  @override
  String get profilePinsRemoveAll => 'PINs der Profile entfernen';

  @override
  String get radioEmptyHint => 'Füge Radiosender in den Einstellungen hinzu.';

  @override
  String get radioStations => 'Sender';

  @override
  String radioStationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sender',
      one: '1 Sender',
    );
    return '$_temp0';
  }

  @override
  String get radioStreamUnavailable =>
      'Radiostream für diesen Sender nicht verfügbar';

  @override
  String get livePreviousCategory => 'Vorherige Kategorie';

  @override
  String get liveNextCategory => 'Nächste Kategorie';

  @override
  String get liveGuideUnavailable => 'Programmübersicht nicht verfügbar';

  @override
  String get liveNoPrograms => 'Keine Sendungen verfügbar';

  @override
  String get liveNoUpcomingPrograms => 'Keine kommenden Sendungen';

  @override
  String get liveNoDescription => 'Keine Zusammenfassung verfügbar.';

  @override
  String get recommendationSubscriptionChanged =>
      'Das Abonnement hat sich geändert. Bitte beginne erneut.';

  @override
  String get recommendationCannotFavorite =>
      'Dieser Inhalt kann nicht zu den Favoriten hinzugefügt werden.';

  @override
  String get recommendationFavoriteFailed =>
      'Dieser Inhalt konnte nicht zu den Favoriten hinzugefügt werden.';

  @override
  String get recommendationMovieQuestion => 'Gehört dir dieser Film?';

  @override
  String get recommendationSeriesQuestion => 'Gehört dir diese Serie?';

  @override
  String get recommendationMovieSeen => 'Film bereits gesehen';

  @override
  String get recommendationSeriesSeen => 'Serie bereits gesehen';

  @override
  String get recommendationRemovedFuture =>
      'Aus zukünftigen Vorschlägen entfernt';

  @override
  String get recommendationNotInterested => 'Kein Interesse';

  @override
  String get recommendationExcluded =>
      'Dauerhaft aus Vorschlägen ausgeschlossen';

  @override
  String get recommendationFavoriteProfile =>
      'Zu den Favoriten des aktuellen Profils hinzugefügt';

  @override
  String get startupParsingPlaylist => 'M3U-Playlist wird analysiert…';

  @override
  String get startupProviderSlow =>
      'Der Anbieter antwortet langsam (möglicherweise läuft eine Sicherheitsprüfung). Bitte warten…';

  @override
  String get startupLoadingRemaining => 'Radiosender und Replay werden geladen';

  @override
  String get startupLoadingInitial =>
      'Live-Sender, Filme, Serien und TV-Programm werden geladen';

  @override
  String get startupCheckingSubscription => 'Die Abonnementprüfung';

  @override
  String get startupRefresh => 'Die Aktualisierung';

  @override
  String startupStalled(String step, int seconds) {
    return '$step: seit $seconds Sekunden kein Fortschritt. Der Server ist möglicherweise langsam oder nicht erreichbar.';
  }

  @override
  String startupRefreshStalled(String step, int seconds) {
    return '$step: seit $seconds Sekunden kein Fortschritt. Der Server ist möglicherweise langsam oder nicht erreichbar; überprüfe gegebenenfalls dein Abonnement.';
  }

  @override
  String get startupMovies => 'Filme & VOD';

  @override
  String get startupLive => 'Live-Sender';

  @override
  String get startupReady => 'Bereit!';

  @override
  String get startupBackHome => 'Zurück zur Startseite';

  @override
  String get startupCheckSubscription => 'Abonnement überprüfen';

  @override
  String get browseRankings => 'Ranglisten';

  @override
  String get browsePopularRankings => 'Beliebte Ranglisten';

  @override
  String get browseRankingsUnavailableHint =>
      'TMDB-Trends sind nicht verfügbar. Füge in den Einstellungen einen TMDB-API-Schlüssel hinzu (oder TMDB_API_KEY in assets/config/runtime.env).';

  @override
  String get browseTmdbData => 'Daten © TMDB';

  @override
  String get browsePopular => 'Beliebt';

  @override
  String get browseNowPlaying => 'Im Kino';

  @override
  String get browseTopRated => 'Bestbewertet';

  @override
  String get browseUpcoming => 'Demnächst';

  @override
  String get browseTrendingWeek => 'Trends der Woche';

  @override
  String get browseOnTheAir => 'In Ausstrahlung';

  @override
  String get browseAiringToday => 'Heute ausgestrahlt';

  @override
  String get browseSeriesType => 'Serie';

  @override
  String get browseSynopsis => 'Inhalt';

  @override
  String get browseNotInSubscription =>
      'Dieser Titel ist nicht in deinem aktiven Abonnement enthalten. Entdecke ihn auf einer von TMDB aufgeführten Plattform.';

  @override
  String get browseExploreCategories => 'Nach Kategorie entdecken';

  @override
  String get browseFavoriteHint =>
      'Halte ein Element gedrückt, um es hier wiederzufinden.';

  @override
  String get browseRecentHint => 'Angesehene Inhalte erscheinen hier.';

  @override
  String get browseSearchEmpty => 'Keine Inhalte entsprechen dieser Suche.';

  @override
  String browseTitlesCount(int visible, int total) {
    return '$visible Titel (von $total)';
  }

  @override
  String get catalogSearchMovies => 'Film oder Genre suchen…';

  @override
  String get catalogSearchSeries => 'Serie oder Genre suchen…';

  @override
  String get catalogLoading =>
      'Katalog wird geladen…\nBitte einen Moment warten.';

  @override
  String get catalogNoMovies => 'Die Filmbibliothek ist derzeit leer.';

  @override
  String get catalogNoSeries => 'Die Serienbibliothek ist derzeit leer.';

  @override
  String get catalogNoRecentMovies => 'Keine zuletzt angesehenen Filme';

  @override
  String get catalogNoRecentSeries => 'Keine zuletzt angesehenen Serien';

  @override
  String get catalogNoResults => 'Keine Ergebnisse';

  @override
  String get catalogNoMoviesInCategory => 'Keine Filme in dieser Kategorie';

  @override
  String get catalogMovieFavoriteHint =>
      'Wähle das Herz eines Films, um ihn hier zu finden.';

  @override
  String get catalogSeriesFavoriteHint =>
      'Wähle das Herz einer Serie, um sie hier zu finden.';

  @override
  String get catalogRecentMoviesHint => 'Angesehene Filme erscheinen hier.';

  @override
  String get catalogRecentSeriesHint => 'Angesehene Serien erscheinen hier.';

  @override
  String get catalogMovieSearchEmpty => 'Keine Filme entsprechen dieser Suche.';

  @override
  String get catalogSeriesSearchEmpty =>
      'Keine Serien entsprechen dieser Suche.';

  @override
  String get catalogMovieCategoryEmpty =>
      'Keine Filme entsprechen dieser Kategorie.';

  @override
  String removedFromFavorites(String title) {
    return '„$title“ aus den Favoriten entfernt';
  }

  @override
  String get liveBackToChannels => 'Zurück zu den Sendern';

  @override
  String get liveAddSourceHint =>
      'Füge in den Einstellungen eine Senderquelle hinzu.';

  @override
  String get liveNoChannelFound => 'Keine Sender gefunden';

  @override
  String get liveNoRecentChannel => 'Keine zuletzt angesehenen Sender';

  @override
  String get liveNoChannelInGroup => 'Keine Sender in dieser Gruppe';

  @override
  String get liveTryAnotherSearch => 'Versuche einen anderen Suchbegriff.';

  @override
  String get liveFavoriteHint =>
      'Wähle das Herz eines Senders, um ihn hier zu finden.';

  @override
  String get liveRecentHint => 'Angesehene Sender erscheinen hier.';

  @override
  String get liveEmptyGroupHint => 'Diese Gruppe enthält keine Sender.';

  @override
  String get liveLoadingHint =>
      'Sender werden geladen…\nBitte warte, bevor du einen Stream startest.';

  @override
  String get replayNoChannels =>
      'Kein Sender dieses Abonnements meldet Catch-up-Unterstützung.';

  @override
  String get replayEmptyGroup =>
      'Diese Gruppe enthält keine Sender mit Replay.';

  @override
  String get epgLoadingBanner =>
      'TV-Programm wird geladen… Sendungen erscheinen in Kürze.';

  @override
  String get epgNoChannelsInCategory => 'Keine Sender in dieser Kategorie';

  @override
  String get epgLoadingChannels => 'Sender werden geladen…';

  @override
  String get epgChannelsLoadFailed => 'Sender konnten nicht geladen werden.';

  @override
  String get replayToday => 'Heute';

  @override
  String get replayYesterday => 'Gestern';

  @override
  String searchWithinHint(String type) {
    return 'In $type suchen…';
  }

  @override
  String get searchAllHint =>
      'Live-TV, Filme, Serien, Replay, TV-Programm suchen…';

  @override
  String get searchHint => 'Suchen…';

  @override
  String searchWithinTitle(String type) {
    return 'Suche in $type';
  }

  @override
  String get searchUnifiedTitle => 'Übergreifende Suche';

  @override
  String searchWithinHelp(String type) {
    return 'Eingeben, um nur in $type zu suchen.';
  }

  @override
  String get searchUnifiedHelp =>
      'Suche nach Live-Sendern, Filmen, Serien, Replays oder TV-Sendungen.';

  @override
  String get searchOffline => 'Offline-Modus — nur lokale Ergebnisse';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultsHelp =>
      'Versuche andere Begriffe oder prüfe die Schreibweise.';

  @override
  String get searchAllCategories => 'Alle';

  @override
  String get searchClearHistory => 'Verlauf löschen';

  @override
  String get settingsPlaybackEngines => 'Wiedergabe-Engines';

  @override
  String get settingsCloudAccount => 'Cloud-Konto';

  @override
  String get settingsCloudSignIn => 'Anmeldung mit Google oder E-Mail';

  @override
  String get settingsSyncUnavailable =>
      'Vollständige Synchronisierung nicht verfügbar';

  @override
  String get settingsSyncUnavailableHelp =>
      'Die alte unverschlüsselte Synchronisierung ist deaktiviert. Profildaten können im Cloud-Konto manuell gesichert werden; andere Daten werden nicht synchronisiert.';

  @override
  String get settingsSystemAutomatic => 'Automatisch (System)';

  @override
  String get settingsSubtitleDefault => 'Standarduntertitel';

  @override
  String get settingsSubtitleForced => 'Erzwungene Untertitel';

  @override
  String get settingsSubtitleOff => 'Untertitel aus';

  @override
  String get settingsSubtitles => 'Untertitel';

  @override
  String get settingsProtectedPlayback => 'Geschützte Wiedergabe';

  @override
  String get settingsCategoryFilters => 'Kategoriefilter';

  @override
  String get settingsCategoryFiltersHelp =>
      'Ausgeblendete Kategorien pro Abonnement';

  @override
  String get episodeSelectProfile =>
      'Wähle ein Profil, um diese Episode zu ändern.';

  @override
  String get episodeProfileChanged =>
      'Das Profil wurde geändert. Bitte versuche es erneut.';

  @override
  String get episodeStatusFailed =>
      'Der Status dieser Episode konnte nicht geändert werden.';

  @override
  String get episodeResetQuestion => 'Episode zurücksetzen?';

  @override
  String get episodeMarkWatchedQuestion => 'Als angesehen markieren?';

  @override
  String episodeResetProgressMessage(String title) {
    return '„$title“ wird als nicht angesehen markiert und der Wiedergabefortschritt gelöscht.';
  }

  @override
  String episodeMarkUnwatchedMessage(String title) {
    return '„$title“ wird für dieses Profil als nicht angesehen markiert.';
  }

  @override
  String episodeMarkWatchedMessage(String title) {
    return '„$title“ wird für dieses Profil als angesehen markiert.';
  }

  @override
  String get episodeMarkUnwatched => 'Als nicht angesehen markieren';

  @override
  String get detailAiData => 'KI-generierte Daten';

  @override
  String detailSourceData(String source) {
    return '$source-Daten';
  }

  @override
  String get detailUnavailableValue => 'Nicht verfügbar';

  @override
  String get detailKeywords => 'Stichwörter';

  @override
  String get detailGenres => 'Genres';

  @override
  String get detailCast => 'Besetzung';

  @override
  String get detailTrailerFailed => 'Der Trailer konnte nicht geöffnet werden';

  @override
  String get detailShowCrew => 'Filmteam anzeigen';

  @override
  String get detailHideCrew => 'Filmteam ausblenden';

  @override
  String seriesRuntimePerEpisode(int minutes) {
    return '$minutes Min./Episode';
  }

  @override
  String seriesNetwork(String network) {
    return 'Sender: $network';
  }

  @override
  String seriesFirstAired(String date) {
    return 'Erstausstrahlung: $date';
  }

  @override
  String seriesSeasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Staffeln',
      one: '1 Staffel',
    );
    return '$_temp0';
  }

  @override
  String get profileDiscardHelp =>
      'Ungespeicherte Änderungen gehen verloren. Trotzdem verlassen?';

  @override
  String get profileLeave => 'Verlassen';

  @override
  String get profileEditTitle => 'Profil bearbeiten';

  @override
  String get profileAvatarTheme => 'Avatar-Thema';

  @override
  String get profileAvatarThemeHelp =>
      'Wähle einen Stil und dann einen Avatar aus dem Raster';

  @override
  String get profileAvatars => 'Avatare';

  @override
  String profileCurrentTheme(String theme) {
    return 'Aktuelles Thema: $theme';
  }

  @override
  String get profileRequired => 'Erforderlich';

  @override
  String get profileFavoriteMovieGenres => 'Bevorzugte Filmgenres';

  @override
  String get profileGenresHelp =>
      'Wähle einen oder mehrere Stile für Empfehlungen';

  @override
  String get profilePinMismatch => 'Die PINs stimmen nicht überein.';

  @override
  String get profilePinCreateFailed => 'Die PIN konnte nicht erstellt werden.';

  @override
  String get profilePinActive => 'Eine vierstellige PIN ist aktiv';

  @override
  String get profilePinPending =>
      'PIN bestätigt. Speichere das Profil, um sie zu aktivieren.';

  @override
  String get profilePinRequest => 'Bei der Profilauswahl nach einer PIN fragen';

  @override
  String get profilePinCreating => 'PIN wird erstellt…';

  @override
  String get profileNotFound => 'Kein Profil zum Bearbeiten';

  @override
  String get profileSaveActivate => 'Speichern und Schutz aktivieren';

  @override
  String get profileCreateActivate => 'Profil erstellen und Schutz aktivieren';

  @override
  String get profileSaveAction => 'Speichern';

  @override
  String get profileCreateAction => 'Profil erstellen';

  @override
  String get genreAction => 'Action';

  @override
  String get genreAdventure => 'Abenteuer';

  @override
  String get genreAnimation => 'Animation';

  @override
  String get genreComedy => 'Komödie';

  @override
  String get genreRomanticComedy => 'Romantische Komödie';

  @override
  String get genreDrama => 'Drama';

  @override
  String get genreHorror => 'Horror';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreDetective => 'Krimi';

  @override
  String get genreCrime => 'Verbrechen';

  @override
  String get genreWar => 'Krieg';

  @override
  String get genreHistorical => 'Historienfilm';

  @override
  String get genreWestern => 'Western';

  @override
  String get genreSciFi => 'Science-Fiction';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreSuperheroes => 'Superhelden';

  @override
  String get genreMystery => 'Mystery';

  @override
  String get genreRomance => 'Romanze';

  @override
  String get genreMusical => 'Musical';

  @override
  String get genreMusic => 'Musik';

  @override
  String get genreBiopic => 'Filmbiografie';

  @override
  String get genreDocumentary => 'Dokumentation';

  @override
  String get genreTournament => 'Turnier';

  @override
  String get genreChildren => 'Kinder';

  @override
  String get genreFamily => 'Familie';

  @override
  String get genreSuspense => 'Spannung';

  @override
  String get genreBlackWhite => 'Schwarz-Weiß';

  @override
  String get genreClassic => 'Klassiker';

  @override
  String get cloudConfirm => 'Bestätigen';

  @override
  String get cloudShareProfilesTitle => 'Diese Profile teilen?';

  @override
  String cloudDuplicateProfileId(String id) {
    return 'Gleicher Name — ID: $id';
  }

  @override
  String get cloudShareProfilesHelp =>
      'Fehlende Profile werden hinzugefügt, ohne bestehende zu ersetzen. Ihre Favoriten und Aktivitäten sowie Einstellungen und Abonnements einschließlich IPTV-Zugangsdaten werden geteilt. Diese Daten sind verschlüsselt.\n\nProfile mit demselben Namen bleiben getrennt. Bei unterschiedlichen Daten wählst du, welche behalten werden.';

  @override
  String get cloudChooseSourceTitle => 'Quelle bei Konflikten wählen';

  @override
  String get cloudChooseSourceHelp =>
      'Unterschiedliche Ergänzungen werden auf beiden Geräten zusammengeführt. Wurden dieselben Daten auf beiden Seiten geändert, wird die hier gewählte Quelle behalten und an das andere Gerät gesendet. Diese Wahl gilt für alle anfänglichen Konflikte.';

  @override
  String get cloudSourceLocal => 'Dieses Gerät als Quelle verwenden';

  @override
  String get cloudSourceRemote => 'Die Cloud als Quelle verwenden';

  @override
  String get cloudResetTitle => 'In der Cloud von vorne beginnen?';

  @override
  String get cloudResetHelp =>
      'Alle Profile und ihre geteilten Daten werden aus der Cloud gelöscht. Lokale Profile bleiben erhalten. Auf anderen Geräten muss der neue Code eingegeben werden. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get cloudNewCode => 'Neuer Code';

  @override
  String get cloudConfirmCode => 'Code bestätigen';

  @override
  String get cloudResetCodeError =>
      'Gib einen neuen Code mit 3 bis 10 Ziffern ein und bestätige ihn identisch.';

  @override
  String get cloudRestoreTitle => 'Dieses Profil wiederherstellen?';

  @override
  String cloudRestoreHelp(String name) {
    return 'Das Profil von $name wird hinzugefügt, ohne lokale Profile zu ersetzen. Favoriten, Verlauf, Abonnements und Einstellungen werden nicht wiederhergestellt.';
  }

  @override
  String cloudDeleteTitle(String name) {
    return '$name aus der Cloud löschen?';
  }

  @override
  String get cloudDeleteHelp =>
      'Das Profil und seine synchronisierten Daten werden aus der Cloud gelöscht. Das lokale Profil auf diesem Gerät wird nicht gelöscht. Andere Geräte werden pausiert und müssen ihre Liste aktualisieren.';

  @override
  String get cloudSyncFinished => 'Synchronisierung abgeschlossen';

  @override
  String get cloudSyncFinishedHelp =>
      'Die ausgewählten Profile und ihre Daten wurden mit der Cloud synchronisiert.';

  @override
  String get cloudResolveTitle => 'Konflikt lösen?';

  @override
  String get cloudResolveLocalHelp =>
      'Bei Konflikten in dieser Kategorie bleibt die Version dieses Geräts erhalten. Die andere Version, einschließlich einer möglichen Löschung, wird überschrieben.';

  @override
  String get cloudResolveRemoteHelp =>
      'Bei Konflikten in dieser Kategorie bleibt die Cloud-Version erhalten. Die andere Version, einschließlich einer möglichen Löschung, wird überschrieben.';

  @override
  String get cloudProfilesTitle => 'Meine Profile auf meinen Geräten';

  @override
  String get cloudSignInToContinue =>
      'Melde dich bei einem Cloud-Konto an, um fortzufahren.';

  @override
  String get cloudFirebaseUnavailable =>
      'Firebase ist auf diesem Gerät nicht verfügbar.';

  @override
  String get cloudGoogleCanceled =>
      'Die Google-Anmeldung wurde abgebrochen oder ist fehlgeschlagen. Prüfe bei anhaltenden Problemen die Google-Konfiguration dieser App.';

  @override
  String get cloudGoogleConfiguration =>
      'Falsche Google-Konfiguration: Prüfe den OAuth-Client und die Signatur dieser App.';

  @override
  String get cloudGoogleUnavailable =>
      'Die Google-Anmeldung ist auf diesem Gerät nicht verfügbar.';

  @override
  String get cloudSignInUnavailable =>
      'Der Anmeldedienst ist auf diesem Gerät nicht verfügbar.';

  @override
  String get cloudSignInRetry => 'Anmeldung nicht möglich. Versuche es erneut.';

  @override
  String get cloudInvalidEmail => 'Ungültige E-Mail-Adresse.';

  @override
  String get cloudWeakPassword => 'Das Passwort ist zu schwach.';

  @override
  String get cloudEmailInUse => 'Diese E-Mail-Adresse wird bereits verwendet.';

  @override
  String get cloudInvalidCredentials =>
      'E-Mail-Adresse oder Passwort ist falsch.';

  @override
  String get cloudNetworkUnavailable => 'Netzwerkverbindung nicht verfügbar.';

  @override
  String get cloudTooManyAttempts =>
      'Zu viele Versuche. Versuche es später erneut.';

  @override
  String get cloudMethodDisabled => 'Diese Anmeldemethode ist nicht aktiviert.';

  @override
  String get cloudGoogleAlreadyLinked =>
      'Dieses Konto ist bereits mit Google verknüpft.';

  @override
  String get cloudGoogleOtherAccount =>
      'Dieses Google-Konto ist bereits mit einem anderen Firebase-Konto verbunden. Es wurden weder Konten noch Daten zusammengeführt. Um das andere Konto zu verwenden, melde dich ab und dann mit Google an.';

  @override
  String get cloudFirebaseSignInFailed =>
      'Anmeldung nicht möglich. Versuche es erneut oder prüfe die Firebase-Konfiguration.';

  @override
  String get cloudAccountIntro =>
      'Melde dich an, um auf deinen Geräten auf deine Profile und deren Daten zuzugreifen. Deine Daten sind verschlüsselt.';

  @override
  String get cloudAccountLinkHelp =>
      'Wenn bereits ein Konto angemeldet ist, wird Google damit verknüpft, ohne dessen Kennung zu ändern. Getrennte Konten werden nicht zusammengeführt.';

  @override
  String get cloudAccountStateError =>
      'Kontostatus konnte nicht gelesen werden.';

  @override
  String get cloudAccountChecking => 'Konto wird überprüft…';

  @override
  String get cloudAccountNone => 'Kein Cloud-Konto angemeldet.';

  @override
  String get cloudPairingCleanupFailed =>
      'Konto verknüpft, aber die Bereinigung der temporären Sitzung ist fehlgeschlagen.';

  @override
  String get cloudPairTv => 'TV per QR-Code koppeln';

  @override
  String get pairSignOutFirst => 'Melde das Cloud-Konto vor der Kopplung ab.';

  @override
  String get pairScannerAccountChanged =>
      'Das Cloud-Konto hat sich geändert. Schließe diesen Bildschirm und beginne erneut.';

  @override
  String get pairScannerAccountCheckFailed =>
      'Das Cloud-Konto konnte nicht überprüft werden.';

  @override
  String get pairScannerCameraFailed =>
      'Die Kamera konnte nicht verwendet werden.';

  @override
  String get pairScannerInvalidQr =>
      'Dieser QR-Code gehört nicht zu einer Orbit-3D-Sitzung.';

  @override
  String get pairScannerAssociationFailed =>
      'Kopplung fehlgeschlagen. Prüfe das Netzwerk oder erstelle am Fernseher einen neuen QR-Code.';

  @override
  String get pairScannerTitle => 'Fernseher koppeln';

  @override
  String get pairScannerSent =>
      'Anfrage gesendet. Bestätige das auf dem Fernseher angezeigte Konto.';

  @override
  String get pairScannerCameraPermission =>
      'Kamera nicht verfügbar. Erlaube den Zugriff in den Einstellungen.';

  @override
  String get pairScannerCompareCode =>
      'Vergleiche diesen Code mit dem Code auf dem Fernseher:';

  @override
  String get pairScannerVerifyWarning =>
      'Bestätige nur, wenn beide Codes übereinstimmen und du den Fernseher kontrollierst.';

  @override
  String pairScannerSelectedProfiles(String profiles) {
    return 'Der Fernseher wählt automatisch: $profiles.';
  }

  @override
  String get pairScannerConfirm => 'Bestätigen und koppeln';

  @override
  String get pairScannerRescan => 'Erneut scannen';

  @override
  String get pairTemporaryUnavailable =>
      'Die temporäre Sitzung ist nicht verfügbar.';

  @override
  String get pairCleanupIncomplete =>
      'Bereinigung unvollständig: Die Sitzung läuft automatisch ab.';

  @override
  String get pairCleanupFailed =>
      'Bereinigung fehlgeschlagen: Die Sitzung läuft automatisch ab.';

  @override
  String get pairUnavailable =>
      'Kopplung nicht verfügbar. Prüfe das Netzwerk und die Firebase-Konfiguration.';

  @override
  String get pairRestart => 'Starte die Kopplung erneut.';

  @override
  String get pairTvTitle => 'Diesen Fernseher verknüpfen';

  @override
  String get pairInstructions =>
      'Öffne auf dem angemeldeten Telefon die verschlüsselte Synchronisierung und scanne diesen QR-Code. Vergleiche die angezeigten Codes vor der Bestätigung.';

  @override
  String get pairCreateQr => 'QR-Code erstellen';

  @override
  String pairVerificationCode(String code) {
    return 'Bestätigungscode: $code';
  }

  @override
  String get pairExpires => 'Der QR-Code läuft nach fünf Minuten ab.';

  @override
  String pairAccount(String account) {
    return 'Zu verknüpfendes Konto: $account';
  }

  @override
  String get pairConfirmAccount => 'Dieses Konto bestätigen';

  @override
  String get pairWaiting => 'Warten auf Bestätigung auf dem Telefon…';

  @override
  String get cloudTemporaryAccount =>
      'Auf diesem Gerät ist ein temporäres Konto angemeldet.';

  @override
  String cloudAccountConnected(String account) {
    return 'Angemeldetes Konto: $account';
  }

  @override
  String get cloudRecoverProfiles => 'Meine Profile auf meinen Geräten finden';

  @override
  String get cloudEmail => 'E-Mail-Adresse';

  @override
  String get cloudSignIn => 'Anmelden';

  @override
  String get cloudCreateAccount => 'Konto erstellen';

  @override
  String get cloudResetEmailSent =>
      'Falls das Konto existiert, kann eine E-Mail zum Zurücksetzen gesendet werden.';

  @override
  String get cloudForgotPassword => 'Passwort vergessen';

  @override
  String get cloudGoogleLinked => 'Google-Konto bereits verknüpft';

  @override
  String get cloudSignInWithGoogle => 'Mit Google anmelden';

  @override
  String get cloudLinkGoogle => 'Google-Konto verknüpfen';

  @override
  String get cloudSignOut => 'Abmelden';

  @override
  String get cloudPrepareCodeHelp =>
      'Ein Erwachsener erstellt den Code. Wähle danach die Profile zum Teilen.';

  @override
  String get cloudChooseProfilesHelp =>
      'Wähle die Profile für deine Geräte und drücke dann auf Teilen.';

  @override
  String get cloudFirstSyncHelp =>
      'Die erste Aktualisierung kann länger als 10 Minuten dauern. Lass Orbit bis zum Abschluss geöffnet.';

  @override
  String get cloudLegacyPhrase => 'Geheimer Satz (altes Format)';

  @override
  String get cloudAdultCode => 'Code von einem Erwachsenen';

  @override
  String get cloudSamePhraseHelp =>
      'Gib auf beiden Geräten denselben Satz ein.';

  @override
  String get cloudSameCodeHelp => 'Gib auf beiden Geräten denselben Code ein.';

  @override
  String get cloudShowPhrase => 'Geheimen Satz anzeigen';

  @override
  String get cloudHidePhrase => 'Geheimen Satz verbergen';

  @override
  String get cloudShowCode => 'Cloud-Code anzeigen';

  @override
  String get cloudHideCode => 'Cloud-Code verbergen';

  @override
  String get cloudSeeProfiles => 'Meine Profile anzeigen';

  @override
  String get cloudRefreshList => 'Liste aktualisieren';

  @override
  String get cloudAdultOptions => 'Optionen für Erwachsene';

  @override
  String get cloudUseLegacyPhrase => 'Alten geheimen Satz verwenden';

  @override
  String get cloudResetAction => 'Alle Cloud-Daten löschen und neu beginnen';

  @override
  String get cloudShareBeforePairing =>
      'Teile zuerst die ausgewählten Profile, damit sie auf dem TV verfügbar sind.';

  @override
  String get cloudConfirmYourCode => 'Code bestätigen';

  @override
  String get cloudBackupTitle => 'Dieses Profil sichern?';

  @override
  String cloudConfirmProfilesHelp(String name) {
    return 'Bestätige deinen Code für die Profile $name. Bewahre ihn sicher auf: Ohne ihn kannst du deine Daten nicht wiederherstellen.';
  }

  @override
  String cloudBackupHelp(String name) {
    return 'Nur das Profil von $name wird verschlüsselt gesichert. Favoriten, Verlauf, Abonnements und Einstellungen sind nicht enthalten. Geht das Geheimnis verloren, kann die Sicherung nicht wiederhergestellt werden.';
  }

  @override
  String get cloudConfirmPhrase => 'Geheimen Satz bestätigen';

  @override
  String get cloudConfirmCloudCode => 'Cloud-Code bestätigen';

  @override
  String get cloudShowConfirmation => 'Bestätigung anzeigen';

  @override
  String get cloudHideConfirmation => 'Bestätigung verbergen';

  @override
  String get cloudSecretsMismatch => 'Die Geheimnisse stimmen nicht überein.';

  @override
  String get cloudSyncProfileTitle => 'Dieses Profil synchronisieren?';

  @override
  String get cloudSyncProfileHelp =>
      'Das aktive Profil, Video- und Radiofavoriten, der jüngste Verlauf, gesehene Episoden und Wiedergabepositionen sowie Einstellungen und Abonnements werden während dieser Sitzung verschlüsselt synchronisiert. IPTV-Zugangsdaten sind enthalten. Das aktive Abonnement bleibt auf jedem Gerät individuell gewählt.';

  @override
  String get cloudUpdating => 'Aktualisierung läuft…';

  @override
  String get cloudAdultMustChoose =>
      'Ein Erwachsener muss wählen, welche Daten behalten werden.';

  @override
  String get cloudSharingEnabled => 'Das Teilen ist aktiviert.';

  @override
  String get cloudKeepOpen =>
      'Dies kann länger als 10 Minuten dauern. Lass Orbit geöffnet.';

  @override
  String get cloudAutoSharing => 'Änderungen werden automatisch geteilt.';

  @override
  String get cloudConflictHelp =>
      'Dieses Gerät und das andere Gerät stimmen nicht überein. Bitte einen Erwachsenen, die richtige Version zu wählen.';

  @override
  String get cloudKeepLocal => 'Daten dieses Geräts behalten';

  @override
  String get cloudKeepRemote => 'Daten des anderen Geräts behalten';

  @override
  String get cloudShareSettings => 'Freigabeeinstellungen (Erwachsene)';

  @override
  String get cloudUpdateNow => 'Jetzt aktualisieren';

  @override
  String get cloudPause => 'Pausieren';

  @override
  String get cloudSelectProfiles => 'Profile zum Teilen wählen';

  @override
  String get cloudWhichProfiles =>
      'Welche Profile möchtest du auf deinen Geräten verwenden?';

  @override
  String get cloudLocalProfilesUnavailable =>
      'Lokale Profile sind nicht verfügbar.';

  @override
  String get cloudUnselectAll => 'Alle abwählen';

  @override
  String get cloudSelectAll => 'Alle auswählen';

  @override
  String get cloudShareSelected => 'Ausgewählte Profile teilen';

  @override
  String get cloudShareAll => 'Alle Profile teilen';

  @override
  String get cloudProfilesToAdd => 'Hinzuzufügende Profile';

  @override
  String get cloudOtherOptions => 'Weitere Optionen (Erwachsene)';

  @override
  String get cloudShareActiveOnly => 'Nur das aktive Profil teilen';

  @override
  String get cloudLocalProfileKept => 'Das lokale Profil bleibt erhalten.';

  @override
  String get cloudRecover => 'Wiederherstellen';

  @override
  String get cloudDeleteAction => 'Aus der Cloud löschen';

  @override
  String get cloudBackupAction => 'Sichern';

  @override
  String get cloudScopeFavorites => 'Favoriten';

  @override
  String get cloudScopeRadioFavorites => 'Radiofavoriten';

  @override
  String get cloudScopeRecents => 'jüngster Verlauf';

  @override
  String get cloudScopeWatched => 'gesehene Episoden';

  @override
  String get cloudScopePlayback => 'Wiedergabepositionen';

  @override
  String get cloudScopePreferences => 'allgemeine Einstellungen';

  @override
  String get cloudScopeProfile => 'Profildaten';

  @override
  String get cloudProfileFallback => 'Profil';

  @override
  String get cloudScopeSubscriptions => 'Abonnements';

  @override
  String get cloudScopeData => 'Daten';

  @override
  String cloudProgressPercent(int percent) {
    return 'Abgeschlossen: $percent %';
  }

  @override
  String cloudProgressScope(String scope) {
    return 'Aktuell: $scope.';
  }

  @override
  String cloudProgressProfile(String scope, String profile) {
    return 'Aktuell: $scope — $profile.';
  }

  @override
  String cloudConflictProfile(String name, String id) {
    return 'Profil im Konflikt: $name ($id)';
  }

  @override
  String cloudConflictData(String scope) {
    return 'Daten: $scope';
  }

  @override
  String get cloudChangedElsewhere =>
      'Die Cloud wurde anderswo geändert. Lade sie vor einem erneuten Versuch neu.';

  @override
  String get cloudBadPhrase =>
      'Geheimer Satz falsch oder Cloud-Daten beschädigt.';

  @override
  String get cloudBadCode => 'Cloud-Code falsch oder Cloud-Daten beschädigt.';

  @override
  String get cloudAccessFailed =>
      'Kein Cloud-Zugriff möglich. Prüfe Netzwerk und Firebase-Konfiguration.';

  @override
  String get cloudInvalidData =>
      'Cloud-Daten ungültig oder inkompatibel; es wurde nichts wiederhergestellt.';

  @override
  String get cloudOperationFailed =>
      'Vorgang fehlgeschlagen. Prüfe das Netzwerk und aktualisiere die Cloud.';

  @override
  String get cloudAskAdult => 'Bitte einen Erwachsenen um den Code.';

  @override
  String get cloudCodeLength => 'Der Code muss 3 bis 10 Ziffern enthalten.';

  @override
  String get cloudAccountChanged =>
      'Konto oder Geheimnis haben sich geändert. Beginne erneut.';

  @override
  String get cloudPhraseChanged =>
      'Konto oder Satz haben sich geändert. Beginne erneut.';

  @override
  String get cloudBackupRefreshed => 'Profil gesichert. Katalog aktualisiert.';

  @override
  String get cloudAccessEmpty => 'Zugriff bestätigt. Keine Profile gesichert.';

  @override
  String get cloudCodeUnverified =>
      'Keine Sicherung gefunden: Dein Code kann noch nicht überprüft werden.';

  @override
  String get cloudAccessChoose =>
      'Zugriff bestätigt. Wähle die zu teilenden Profile.';

  @override
  String get cloudBackupRefreshFailed =>
      'Profil gesichert, aber der Katalog konnte nicht aktualisiert werden.';

  @override
  String get cloudPhoneProfilesMissing =>
      'Die auf dem Telefon gewählten Profile sind nicht mehr verfügbar. Aktualisiere die Liste und wähle sie erneut.';

  @override
  String get cloudPhoneProfilesReceived =>
      'Profile vom Telefon empfangen. Teilen wird gestartet…';

  @override
  String get cloudProfileRestored =>
      'Profil wiederhergestellt. Wähle es in der App und kehre zurück, um die Synchronisierung zu aktivieren.';

  @override
  String get cloudWaitDelete =>
      'Warte vor dem Löschen, bis die Synchronisierung abgeschlossen ist.';

  @override
  String get cloudWaitReset =>
      'Warte vor dem Zurücksetzen, bis die Synchronisierung abgeschlossen ist.';

  @override
  String get cloudResetComplete =>
      'Cloud zurückgesetzt. Der neue Code ist aktiv; lokale Profile bleiben erhalten.';

  @override
  String get cloudWaitSelection =>
      'Eine Synchronisierung läuft. Warte vor dem Ändern der Auswahl auf ihren Abschluss.';

  @override
  String get cloudProfilesChanged =>
      'Profile wurden geändert. Überprüfe deine Auswahl.';

  @override
  String get cloudRestoredProfileMissing =>
      'Ein wiederhergestelltes Profil wurde nicht gefunden. Versuche es erneut.';

  @override
  String cloudRestoringProfiles(int current, int total) {
    return 'Profile werden wiederhergestellt: $current / $total.';
  }

  @override
  String get cloudCheckingProfiles =>
      'Cloud-Profile werden überprüft und gesichert.';

  @override
  String get cloudPartialRestore =>
      'Einige Profile wurden möglicherweise wiederhergestellt. Prüfe die Liste vor einem erneuten Versuch.';

  @override
  String get cloudStartingSync => 'Synchronisierung wird gestartet.';

  @override
  String get cloudProfilesBackedUp => 'Die Profile wurden gesichert.';

  @override
  String get subscriptionTitle => 'Abonnements';

  @override
  String get subscriptionRefreshSuccess =>
      'Aktualisierung abgeschlossen: Mindestens eine Quelle wurde aktualisiert.';

  @override
  String get subscriptionRefreshFailed =>
      'Aktualisierung fehlgeschlagen: keine Daten empfangen.';

  @override
  String get subscriptionConnectionHelp =>
      'Verbindung fehlgeschlagen oder Zugangsdaten abgelehnt. Prüfe Serveradresse, Benutzername, Passwort und Internetverbindung.';

  @override
  String get subscriptionDuplicateHelp =>
      'Mögliches Duplikat: Mehrere Abonnements haben dieselbe Konfiguration. Keines wurde gelöscht; ihre Favoriten können unterschiedlich sein.';

  @override
  String get subscriptionRefreshActive =>
      'Aktualisierung des aktiven Abonnements erzwingen';

  @override
  String get subscriptionActivationFailed =>
      'Das Abonnement konnte nicht aktiviert werden.';

  @override
  String get subscriptionDeleteTitle => 'Abonnement löschen?';

  @override
  String subscriptionDeleteHelp(String name) {
    return '„$name“ löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get subscriptionNoActive =>
      'Kein aktives Abonnement. Wähle eines aus oder füge ein neues hinzu.';

  @override
  String get subscriptionActivate => 'Aktivieren';

  @override
  String get subscriptionNone => 'Keine Abonnements';

  @override
  String get subscriptionEmptyHelp =>
      'Füge zum Start dein erstes Xtream-Codes- oder M3U-Abonnement hinzu.';

  @override
  String get subscriptionFilterHelp =>
      'Auszublendende Kategorien werden unter Einstellungen > Erweiterte Einstellungen > Kategoriefilter festgelegt.';

  @override
  String get subscriptionPossibleDuplicate => 'Mögliches Duplikat';

  @override
  String get subscriptionInactive => 'Inaktiv';

  @override
  String get subscriptionTesting => 'Test läuft…';

  @override
  String get subscriptionUntested => 'Nicht getestet';

  @override
  String get subscriptionTestOk => 'Test OK';

  @override
  String subscriptionTestLatency(int latency) {
    return 'Test OK • $latency ms';
  }

  @override
  String get subscriptionTestFailed => 'Fehlgeschlagen';

  @override
  String get subscriptionTestAction => 'Testen';

  @override
  String get subscriptionIncomplete => 'Unvollständige Konfiguration';

  @override
  String get connectionInvalidConfiguration =>
      'Die Einstellungen dieses Abonnements fehlen oder sind ungültig.';

  @override
  String get connectionCheckServerOrPlaylist =>
      'Prüfen Sie die Server- oder Wiedergabelisten-URL.';

  @override
  String get connectionCheckCredentials =>
      'Prüfen Sie auch Benutzername und Passwort.';

  @override
  String get connectionCertificateExpired => 'SSL-Zertifikat abgelaufen';

  @override
  String get connectionSslError => 'SSL/TLS-Fehler';

  @override
  String get connectionCertificateExpiredHelp =>
      'Das Sicherheitszertifikat des Servers ist abgelaufen.';

  @override
  String get connectionSslHelp =>
      'Die sichere Verbindung zum Server konnte nicht hergestellt werden.';

  @override
  String get connectionCheckDateTime =>
      'Prüfen Sie Datum und Uhrzeit Ihres Geräts.';

  @override
  String get connectionContactProvider =>
      'Wenden Sie sich an Ihren Anbieter, wenn das Problem weiterhin besteht.';

  @override
  String get connectionDnsFailure => 'Server nicht gefunden (DNS)';

  @override
  String get connectionDnsFailureHelp =>
      'Der Server wurde nicht gefunden. Prüfen Sie seine Adresse und Ihre Internetverbindung.';

  @override
  String get connectionNetworkUnavailable => 'Netzwerk nicht erreichbar';

  @override
  String get connectionNetworkUnavailableHelp =>
      'Das Netzwerk des Servers ist nicht erreichbar. Prüfen Sie Ihre Internetverbindung.';

  @override
  String get connectionServerError => 'Server vorübergehend nicht verfügbar';

  @override
  String get connectionServerUnreachable => 'Server nicht erreichbar';

  @override
  String get connectionServerUnreachableHelp =>
      'Der Server ist nicht erreichbar. Prüfen Sie die Adresse und Ihre Internetverbindung.';

  @override
  String get connectionCheckUrl => 'Prüfen Sie die URL auf Tippfehler.';

  @override
  String get connectionTryAnotherNetwork =>
      'Versuchen Sie es über ein anderes Netzwerk.';

  @override
  String get connectionContactUnreachableProvider =>
      'Wenden Sie sich an Ihren Anbieter, wenn der Server nicht erreichbar bleibt.';

  @override
  String get connectionTimeout => 'Zeitüberschreitung';

  @override
  String get connectionTimeoutHelp =>
      'Der Server hat nicht rechtzeitig geantwortet. Er ist möglicherweise langsam oder vorübergehend überlastet.';

  @override
  String get connectionTryLater =>
      'Versuchen Sie es in einigen Minuten erneut.';

  @override
  String get connectionCheckInternet => 'Prüfen Sie Ihre Internetverbindung.';

  @override
  String get connectionInvalidCredentials => 'Ungültige Zugangsdaten';

  @override
  String get connectionAccessDenied => 'Zugriff verweigert';

  @override
  String get connectionXtreamRejected =>
      'Der Server hat den Xtream-Benutzernamen oder das Passwort abgelehnt.';

  @override
  String get connectionM3uAuthorization =>
      'Die M3U-Wiedergabeliste erfordert eine Berechtigung oder eine gültige URL.';

  @override
  String get connectionCheckCredentialsCase =>
      'Prüfen Sie Benutzername und Passwort einschließlich der Groß- und Kleinschreibung.';

  @override
  String get connectionConfirmCredentials =>
      'Bitten Sie Ihren Anbieter, die Zugangsdaten zu bestätigen.';

  @override
  String get connectionAccountUnavailable =>
      'Abonnement oder Konto nicht verfügbar';

  @override
  String get connectionAccountUnavailableHelp =>
      'Das Konto ist möglicherweise abgelaufen, deaktiviert oder hat das Verbindungslimit erreicht.';

  @override
  String get connectionCheckSubscription =>
      'Prüfen Sie den Abonnementstatus bei Ihrem Anbieter.';

  @override
  String get connectionCloseOtherDevices =>
      'Beenden Sie Verbindungen auf anderen Geräten und versuchen Sie es erneut.';

  @override
  String get connectionForbidden => 'Zugriff verboten';

  @override
  String get connectionForbiddenHelp =>
      'Der Server verweigert die Verbindung. Das Konto oder die IP-Adresse ist möglicherweise gesperrt.';

  @override
  String get connectionCheckActiveSubscription =>
      'Prüfen Sie, ob das Abonnement noch aktiv ist.';

  @override
  String get connectionCheckProviderAccess =>
      'Wenden Sie sich an Ihren Anbieter, um den Zugriff zu prüfen.';

  @override
  String get connectionNotFound => 'Adresse nicht gefunden (404)';

  @override
  String get connectionInvalidRequest => 'Ungültige Anfrage';

  @override
  String get connectionInvalidAddress =>
      'Die Serveradresse oder der Endpunkt scheint nicht korrekt zu sein.';

  @override
  String get connectionCheckBaseUrl =>
      'Prüfen Sie die Server-Basis-URL oder die M3U-URL.';

  @override
  String get connectionUseXtreamPanel =>
      'Verwenden Sie die Adresse des Xtream-Panels ohne player_api.php.';

  @override
  String connectionServerUnavailable(int status) {
    return 'Server vorübergehend nicht verfügbar ($status)';
  }

  @override
  String get connectionServerProblem =>
      'Auf dem Server des Anbieters ist ein Problem aufgetreten.';

  @override
  String get connectionInvalidPlaylist =>
      'Ungültige oder leere M3U-Wiedergabeliste';

  @override
  String get connectionInvalidPlaylistHelp =>
      'Die Wiedergabeliste enthält keine lesbaren Daten im erwarteten Format.';

  @override
  String get connectionCheckPlaylistUrl =>
      'Prüfen Sie, ob die URL auf eine aktuelle M3U-Wiedergabeliste verweist.';

  @override
  String get connectionRequestNewUrl =>
      'Bitten Sie Ihren Anbieter um eine neue URL.';

  @override
  String get connectionTestFailed => 'Verbindungstest fehlgeschlagen';

  @override
  String get connectionUnexpectedError =>
      'Ein unerwarteter Fehler hat die Verbindung zu diesem Abonnement verhindert.';

  @override
  String get connectionCheckSubscriptionAndInternet =>
      'Prüfen Sie die Abonnementdaten und Ihre Internetverbindung.';

  @override
  String get connectionRetryOrContact =>
      'Versuchen Sie es erneut oder wenden Sie sich an Ihren Anbieter, wenn das Problem bestehen bleibt.';

  @override
  String get connectionThingsToCheck => 'Zu prüfen';

  @override
  String get connectionTechnicalDetails => 'Technische Details';

  @override
  String subscriptionSemantic(String name) {
    return 'Abonnement $name';
  }

  @override
  String get subscriptionSemanticActive => 'aktiv';

  @override
  String get subscriptionSemanticDuplicate => 'mögliches Duplikat';

  @override
  String get subscriptionAdded => 'Abonnement hinzugefügt';

  @override
  String subscriptionAddedHelp(String name) {
    return '„$name“ wurde gespeichert. Du kannst die Verbindung testen und dann das Abonnement aktivieren.';
  }

  @override
  String get subscriptionTestRunning => 'Verbindung wird getestet…';

  @override
  String get subscriptionTestSuccess => 'Verbindungstest erfolgreich.';

  @override
  String get subscriptionTestUnavailable =>
      'Das Testergebnis ist nicht verfügbar.';

  @override
  String get subscriptionTestError =>
      'Der Verbindungstest konnte nicht abgeschlossen werden.';

  @override
  String get subscriptionEditTitle => 'Abonnement bearbeiten';

  @override
  String get subscriptionNewTitle => 'Neues Abonnement';

  @override
  String get subscriptionName => 'Name des Abonnements';

  @override
  String get subscriptionUsername => 'Benutzername';

  @override
  String get subscriptionPassword => 'Passwort';

  @override
  String get subscriptionShowPassword => 'Passwort anzeigen';

  @override
  String get subscriptionHidePassword => 'Passwort verbergen';

  @override
  String get subscriptionAdd => 'Hinzufügen';

  @override
  String get playerExternalOpened =>
      'Wiedergabe in einem externen Player geöffnet';

  @override
  String get playerExternalTrackHelp =>
      'Wählen Sie Tonspuren und Untertitel im externen Player: Die Einstellungen von Orbit werden nicht übertragen.';

  @override
  String get playerProviderBlocked =>
      'Stream vorübergehend vom Anbieter blockiert';

  @override
  String get playerStreamNotStarting =>
      'Der Stream wird empfangen, aber die Wiedergabe startet nicht. Die Spur ist möglicherweise zu anspruchsvoll für dieses Gerät.';

  @override
  String get playerStreamFrozen =>
      'Der Stream wird empfangen, aber die Wiedergabe ist eingefroren.';

  @override
  String get playerStreamRecovering =>
      'Der Stream läuft nicht weiter. Wiederherstellung wird versucht…';

  @override
  String playerCooldown(int seconds) {
    return 'Geschützter Server (Anti-Leech), erneuter Versuch in ${seconds}s';
  }

  @override
  String get playerProviderBlockedHelp =>
      'Die Wiedergabe wurde durch den Anti-Leech-Schutz des Servers beendet. Warten Sie 3 bis 5 Minuten ohne Wiedergabe und starten Sie diesen Sender erneut, ohne umzuschalten.';

  @override
  String get playerLiveUnavailable => 'Stream nicht verfügbar';

  @override
  String get playerLiveUnavailableHelp =>
      'Dieser Sender kann nicht gestartet werden. Prüfen Sie Ihr Abonnement oder versuchen Sie es erneut.';

  @override
  String playerNextEpisode(String title) {
    return 'Nächste Episode: $title';
  }

  @override
  String playerNextEpisodeCountdown(String title, int seconds) {
    return 'Nächste Episode: $title ($seconds s)';
  }

  @override
  String get profileSelectToContinue => 'Wähle ein Profil, um fortzufahren';

  @override
  String get profileCreateToWatch =>
      'Erstelle dein erstes Profil, um loszulegen.';

  @override
  String get profileNavigationHelp =>
      'Pfeiltasten + OK zum Navigieren · Tippe auf eine Karte zur Auswahl';

  @override
  String get profileActive => 'Aktiv';

  @override
  String get resumeAction => 'Fortsetzen';

  @override
  String get refreshRecommendations => 'Empfehlungen aktualisieren';

  @override
  String get localVideoProxy => 'Experimenteller lokaler Video-Proxy';

  @override
  String get localVideoProxySubtitle =>
      'Für Filme und Serien im internen Player, mit begrenztem Festplattencache.';

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
  String get accountPreferencesSubtitle => 'Sprache, PIN';

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
  String get deleteDownload => 'Löschen';

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
    return 'Letzte Synchronisierung (diese Installation): $time';
  }

  @override
  String get cloudSyncNow => 'Jetzt synchronisieren';

  @override
  String get cloudSyncNowSubtitle =>
      'Favoriten, Verlauf und Wiedergabefortschritt dieser Installation mit der Cloud synchronisieren';

  @override
  String get cloudSyncSubtitleOff =>
      'Favoriten, gesehene Folgen, zuletzt angesehene Inhalte und Wiedergabefortschritt dieser Installation synchronisieren';

  @override
  String get cloudflareReset => 'Cloudflare-Konfiguration zurücksetzen';

  @override
  String get cloudflareResetSubtitle =>
      'Deaktiviert TLS-Impersonation und stellt den Standard-User-Agent des Players wieder her';

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
  String currentProfileLabel(String name) {
    return 'Aktuelles Profil: $name';
  }

  @override
  String get dataAlreadyFresh => 'Daten bereits aktuell (weniger als 8 Std.)';

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
  String downloadAdded(String title) {
    return '„$title“ zu Downloads hinzugefügt';
  }

  @override
  String get downloadCompleted => 'Heruntergeladen';

  @override
  String get downloadInProgress => 'Download läuft';

  @override
  String get downloadOffline => 'Für die Offline-Nutzung herunterladen';

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
  String get moreResults => 'Mehr Ergebnisse anzeigen';

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
  String get noGroupAffinity => 'Keine gemeinsame Affinität gefunden';

  @override
  String get noHistory => 'Kein Verlauf';

  @override
  String get historyLoading => 'Verlauf wird geladen…';

  @override
  String get historyEmptyHint =>
      'Deine zuletzt angesehenen Inhalte erscheinen hier.';

  @override
  String get refreshAction => 'Aktualisieren';

  @override
  String get favoritesAdd => 'Zu Favoriten hinzufügen';

  @override
  String get favoritesRemove => 'Aus Favoriten entfernen';

  @override
  String get favoritesNeedScope =>
      'Ein aktives Profil und Abonnement sind erforderlich.';

  @override
  String get favoritesReplayHint =>
      'Tippe bei einer Wiederholung auf das Herz, um sie hier zu finden.';

  @override
  String favoritesClearPrompt(int total) {
    return 'Die $total gespeicherten Favoriten entfernen? Die Favoritenliste wird geleert.';
  }

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
  String get noRecommendations => 'Keine Empfehlungen verfügbar';

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
  String get pinRequired => 'PIN erforderlich';

  @override
  String get pinSet => 'PIN festlegen';

  @override
  String get pinThisProfile => 'dieses Profil';

  @override
  String pinEnterForProfile(String name) {
    return 'Gib die PIN für $name ein';
  }

  @override
  String get pinConfirmFourDigits => 'Bestätige deinen 4-stelligen Code';

  @override
  String get pinChooseFourDigits => 'Wähle einen 4-stelligen Code';

  @override
  String get pinVerifyFailed => 'Die PIN konnte nicht überprüft werden.';

  @override
  String get pinConfirmInstruction =>
      'Drücke nach 4 Ziffern ✓ zur Bestätigung.';

  @override
  String pinIncorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versuche verbleiben',
      one: '1 Versuch verbleibt',
    );
    return 'Falscher Code — $_temp0';
  }

  @override
  String get pinChecking => 'Überprüfung läuft…';

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
  String profilesSelected(int count) {
    return '$count Profile ausgewählt';
  }

  @override
  String get profileVisible => 'Profil sichtbar';

  @override
  String get programGrid => 'Programmgrundriss';

  @override
  String get protectWithPin => 'Mit PIN-Code schützen';

  @override
  String get rankingsUnavailable => 'Rankings nicht verfügbar';

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
  String get tmdbMovieRecommendations => 'TMDB-Empfehlungen';

  @override
  String get tmdbRecommendationsEmpty =>
      'Keine TMDB-Empfehlungen für diesen Film.';

  @override
  String get tmdbRecommendationsError =>
      'TMDB-Empfehlungen konnten nicht geladen werden.';

  @override
  String get tmdbRecommendationsUnavailable =>
      'TMDB-Empfehlungen für diesen Film sind nicht verfügbar.';

  @override
  String get playbackDelayedTitle => 'Die Wiedergabe dauert zu lange';

  @override
  String get playbackDelayedMessage =>
      'Die Wiedergabe startet nicht oder wird nicht fortgesetzt. Der Stream, die Verbindung oder das Videoformat können die Ursache sein.';

  @override
  String get playbackContinueWaiting => 'Weiter warten';

  @override
  String get playbackUnavailableTitle => 'Wiedergabe nicht verfügbar';

  @override
  String get playbackUnavailableMessage =>
      'Dieser Film oder diese Folge kann derzeit nicht abgespielt werden. Versuche es erneut oder überprüfe Verbindung und Dateiformat.';

  @override
  String get protectedPlaybackUnsupportedMessage =>
      'Der integrierte Player kann diesen DASH- oder weitergeleiteten Stream mit geschützten Headern nicht sicher abspielen.';

  @override
  String get greenScreenDetectedTitle => 'Bildanzeigeproblem erkannt';

  @override
  String get externalPlayerLimitationsTitle =>
      'Einschränkungen externer Player';

  @override
  String get externalPlayerLimitationsDescription =>
      'Orbit überträgt Audio- und Untertiteleinstellungen nicht an VLC oder MX Player: Wähle die Spuren im externen Player. Bei Serien startet die nächste Folge nur automatisch, wenn MX Player das Wiedergabeende bestätigt; andernfalls starte sie nach der Rückkehr zu Orbit manuell. Dies gilt auch für den Ersatz-Player.';

  @override
  String get actorShowFilmography => 'Filmografie ansehen';

  @override
  String get actorFilmographyUnavailable => 'Filmografie nicht verfügbar.';

  @override
  String get actorCreditFilm => 'Film';

  @override
  String get actorCreditSeries => 'Serie';

  @override
  String actorCreditRole(String role) {
    return 'Rolle: $role';
  }

  @override
  String get actorCreditTmdbUnavailable => 'TMDB-Details nicht verfügbar.';

  @override
  String get actorCreditSynopsisUnavailable => 'Inhaltsangabe nicht verfügbar.';

  @override
  String get actorCreditCatalogUnconfirmed =>
      'Keine bestätigte Übereinstimmung im Katalog.';

  @override
  String get actorCreditOpenCatalog => 'Im Katalog ansehen';

  @override
  String get greenScreenDetectedMessage =>
      'Ein Bildproblem (grüner Bildschirm) wurde erkannt. Der aktuelle Player kann diesen Stream möglicherweise nicht korrekt dekodieren. Versuche einen anderen Player unter Einstellungen > Player > Wiedergabemotoren und starte die Wiedergabe erneut.';

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
  String selectAtLeastOneProfile(int count) {
    return 'Wähle mindestens 1 weiteres Profil ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'Wählen Sie ein Profil für Empfehlungen';

  @override
  String get series => 'Serien';

  @override
  String get seriesNotFound => 'Serie nicht gefunden';

  @override
  String get seriesMissingId =>
      'Die Serien-ID fehlt (fehlerhafte Navigation). Kehre zur Liste zurück und versuche es erneut.';

  @override
  String get seriesEnriching => 'Metadaten werden ergänzt…';

  @override
  String get seriesLoading => 'Serie wird geladen…';

  @override
  String get seriesNoEpisodesHint => 'Diese Serie hat noch keine Episoden.';

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
  String get snackCacheCleared => 'Caches geleert';

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
  String get sortAffinity => 'Nach Affinität';

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
  String get sortLatestM3UXtream => 'Neueste M3U/Xtream-Ergänzungen';

  @override
  String get sortNameAToZ => 'Name (A → Z)';

  @override
  String get sortNameZToA => 'Name (Z → A)';

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
  String get tmdbKeyValid => 'TMDB-Schlüssel ist gültig';

  @override
  String get tmdbKeyValidationFailed =>
      'TMDB hat den Schlüssel abgelehnt oder das Netzwerk ist nicht verfügbar: Schlüssel überprüfen';

  @override
  String get tvChannels => 'TV-Sender';

  @override
  String get unableToBuildReplayUrl =>
      'Wiedergabe-URL konnte nicht erstellt werden.';

  @override
  String get unlockCloudflare => 'Entsperren (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'Anbieterbestätigung erforderlich';

  @override
  String get cloudflareChallengeHelp =>
      'Der Anbieter verlangt eine Cloudflare-Prüfung. Schließen Sie sie in diesem Fenster ab, schließen Sie es und versuchen Sie es erneut. Die Cookies dieser Seite werden nicht an den Player weitergegeben; die Wiedergabe kann weiterhin blockiert sein.';

  @override
  String get openProviderWebsite => 'Website des Anbieters öffnen';

  @override
  String get providerWebsiteUnavailable =>
      'Die Website des Anbieters konnte nicht geöffnet werden. Prüfen Sie die Abonnementadresse und versuchen Sie es erneut.';

  @override
  String get unstableConnection => 'Unstabile Verbindung';

  @override
  String get updateAllData => 'Alle Daten aktualisieren';

  @override
  String get aiTopicsTitle => 'KI-Empfohlene Themen';

  @override
  String get updateThisCategory => 'Diese Kategorie aktualisieren';

  @override
  String get updating => 'Aktualisierung läuft…';

  @override
  String get updatingMediaContent => 'Medieninhalte werden aktualisiert…';

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

  @override
  String get subtitleSection => 'Untertitel';

  @override
  String get seriesDefaultAudioLanguage => 'Standard-Audiosprache';

  @override
  String get seriesDefaultSubtitleLanguage => 'Standard-Untertitelsprache';

  @override
  String get seriesSelectLanguage => 'Sprache auswählen';

  @override
  String get seriesStreamDefault => '(Stream-Standard)';

  @override
  String get seriesChooseLanguageFirst => 'Wähle zuerst eine Sprache';

  @override
  String get seriesDefaultAllEpisodes =>
      'Stream-Standard für alle Episoden verwenden';

  @override
  String get seriesDefaultUnlessEpisodeChoice =>
      'Stream-Standard verwenden, sofern nicht pro Episode gewählt';

  @override
  String get seriesForceLanguageAllEpisodes =>
      'Diese Sprache für alle Episoden erzwingen';

  @override
  String get seriesApplyIfAvailable => 'Anwenden, falls verfügbar';

  @override
  String get seriesSearchingAudio => 'Audiospuren werden gesucht…';

  @override
  String get seriesSubtitlesDisabled => '(Deaktiviert)';

  @override
  String get seriesDisableSubtitlesAll =>
      'Untertitel für alle Episoden deaktivieren';

  @override
  String get seriesDisableSubtitlesDefault =>
      'Untertitel standardmäßig deaktivieren';

  @override
  String get seriesSearchingSubtitles => 'Untertitelspuren werden gesucht…';

  @override
  String get seriesNoSubtitleTracks =>
      'Keine Spuren gefunden: Wähle eine Sprache, sie wird verwendet, falls verfügbar.';

  @override
  String get seriesLanguageFrench => 'Französisch';

  @override
  String get seriesLanguageEnglish => 'Englisch';

  @override
  String get seriesLanguageSpanish => 'Spanisch';

  @override
  String get seriesLanguageGerman => 'Deutsch';

  @override
  String get seriesLanguageItalian => 'Italienisch';

  @override
  String get seriesLanguageArabic => 'Arabisch';

  @override
  String get subtitleEmbeddedSection => 'Eingebettete Untertitel';

  @override
  String get subtitleForcedLabel => 'Erzwungen';

  @override
  String get subtitleEmbeddedLabel => 'Eingebettet';

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
  String get subtitleUnavailable => 'Nicht verfügbar';

  @override
  String get subtitleNoTrack => 'Keine Spur';

  @override
  String get subtitleNoTrackInfo =>
      'Der Anbieter liefert für diesen Inhalt keine Untertitel.';

  @override
  String get subtitleGuessed => 'Ermittelte Spuren';

  @override
  String get subtitleGuessedInfo =>
      'Der Anbieter deklariert keine Untertitel: Diese Spuren werden aus einer URL-Konvention abgeleitet. Eine nicht vorhandene Spur meldet beim Aktivieren einen Fehler.';

  @override
  String get subtitleUnavailableToast => 'Untertitel nicht verfügbar';

  @override
  String get audioTrackFallback => 'Tonspur';

  @override
  String get subtitleLoading => 'Untertitel werden geladen…';

  @override
  String get videoQualityFallback => 'Videoqualität';

  @override
  String get close => 'Schließen';

  @override
  String get streamTracksError =>
      'Die Spuren dieses Streams konnten nicht gelesen werden.';

  @override
  String get subtitleProviderNoAnswer => 'Der Anbieter hat nicht geantwortet.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Untertitel nicht verfügbar: $reason';
  }

  @override
  String get epgNoDataTitle => 'Keine Programmdaten';

  @override
  String get epgLiveNow => 'Live';

  @override
  String get epgSelectChannelHint =>
      'Wählen Sie einen Sender, um sein Programm zu sehen';

  @override
  String get epgNow => 'Jetzt';

  @override
  String get epgZoomIn => 'Vergrößern';

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
  String get replayNoAvailable => 'Kein Replay verfügbar';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'Kein bereits ausgestrahltes Programm im $days-Tage-Archiv dieses Kontos für diesen Sender.';
  }

  @override
  String get replayNonePublished =>
      'Der Anbieter veröffentlicht kein bereits ausgestrahltes Programm für diesen Sender.';

  @override
  String get epgActionFavorite => 'Favorit';

  @override
  String get epgActionRecording => 'Aufn.';

  @override
  String get epgActionReminder => 'Erinnerung';

  @override
  String get epgStartReplay => 'Replay starten';

  @override
  String get epgBack => 'Zurück';

  @override
  String epgWatchChannel(Object name) {
    return '$name ansehen';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'Der Anbieter liefert keine Untertitel für diesen Inhalt.';

  @override
  String subtitleVerifying(Object count) {
    return 'Untertitel werden geprüft… ($count)';
  }

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
      'Inhalte über die Detailseite eines Films oder einer Serie hinzufügen.';

  @override
  String get downloadsLocation => 'Dateien';

  @override
  String get advancedSettingsTitle => 'Erweiterte Einstellungen';

  @override
  String get advancedSettingsIntro =>
      'API-Zugangsdaten und Netzwerkeinstellungen. Diese Einstellungen binden Ihr Konto an Drittanbieter: Ein geteilter Schlüssel verbraucht dessen Kontingent, und eine falsche Netzwerkeinstellung kann den Start der App verhindern.';

  @override
  String get advancedStatus => 'Status der Zugangsdaten';

  @override
  String get advancedAccessTitle => 'Geschützter Zugang';

  @override
  String get advancedAccessHint => 'Code';

  @override
  String get advancedAccessConfirm => 'Öffnen';

  @override
  String get advancedAccessWrong => 'Falscher Code';

  @override
  String get advancedHiddenHint =>
      'Für erweiterte Einstellungen gedrückt halten';

  @override
  String get favoritesAndDownloads => 'Favoriten & Downloads';

  @override
  String get activeAudio => 'Ton auf diesem Bildschirm';

  @override
  String get addChannel => 'Sender hinzufügen';

  @override
  String get noChannelSelected => 'Kein Sender ausgewählt';

  @override
  String get removeChannel => 'Sender entfernen';

  @override
  String get avatarCategoryAll => 'Alle';

  @override
  String get avatarCategoryCharacters => 'Figuren';

  @override
  String get avatarCategorySuperheroes => 'Superhelden';

  @override
  String get avatarCategoryAnimals => 'Tiere';

  @override
  String get avatarCategoryFlowers => 'Blumen';

  @override
  String get avatarCategoryNature => 'Natur';

  @override
  String get avatarCategoryYouth => 'Jugend';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Schwarz & Weiß';

  @override
  String get updateTitle => 'Updates';

  @override
  String get updateSettingsSubtitle =>
      'Neueste offizielle GitHub-Version prüfen';

  @override
  String get updateChecking => 'Suche nach Updates…';

  @override
  String get updateCurrent =>
      'Die neueste verfügbare Version ist bereits installiert.';

  @override
  String get updateAvailable => 'Eine neue Version ist verfügbar:';

  @override
  String get updateDownloading => 'APK wird heruntergeladen und geprüft…';

  @override
  String get updateReady => 'Android-Installationsprogramm wird geöffnet…';

  @override
  String get updatePermission =>
      'Erlaube Orbit in den Android-Einstellungen die Installation unbekannter Apps, kehre zurück und versuche es erneut.';

  @override
  String get updateNoRelease =>
      'Auf GitHub ist keine stabile Version verfügbar.';

  @override
  String get updateAssetError =>
      'Die Version enthält nicht die offizielle universelle APK oder ihre Prüfdaten.';

  @override
  String get updateInvalidApk =>
      'Die APK ist inkompatibel, anders signiert oder hat keine höhere Android-Version. Installation abgebrochen.';

  @override
  String get updateIntegrityError =>
      'Die Prüfung der heruntergeladenen Datei ist fehlgeschlagen. Installation abgebrochen.';

  @override
  String get updateGenericError =>
      'Das Update ist fehlgeschlagen. Prüfe die Verbindung und versuche es erneut.';

  @override
  String get updateLater => 'Später';

  @override
  String get updateInstall => 'Aktualisieren';

  @override
  String get updateRetryInstall => 'Installation erneut versuchen';

  @override
  String get updateRetry => 'Erneut versuchen';

  @override
  String get avatarCategoryPixels => 'Pixel';

  @override
  String get unassignedLegacyLibraryItems =>
      'Einige ältere Favoriten oder Downloads werden nicht angezeigt, weil ihr ursprüngliches Abonnement unbekannt ist. Sie bleiben gespeichert.';

  @override
  String get forceNoSubtitlesSubtitle =>
      'Untertitel beim Start eines Films oder einer Serie automatisch deaktivieren';

  @override
  String get backTooltip => 'Zurück';

  @override
  String get categoryFilters => 'Kategoriefilter';

  @override
  String get categoryFiltersSubtitle =>
      'Je nach Abonnement ausgeblendete Kategorien';

  @override
  String get memoryCacheTitle => 'Speicher- und Cache-Verwaltung';

  @override
  String get memoryCacheSubtitle =>
      'Geben Sie Speicherplatz frei und bereinigen Sie lokale Daten.';

  @override
  String get clearWatchHistoryTitle => 'Ansehverlauf leeren';

  @override
  String get clearWatchHistorySubtitle =>
      'Löscht die Liste der zuletzt angesehenen Inhalte und die Wiedergabepositionen.';

  @override
  String get clearWatchHistoryAction => 'Löschen';

  @override
  String get clearCoverCacheTitle => 'Cover-Cache leeren';

  @override
  String get clearCoverCacheSubtitle =>
      'Gibt den von lokal gespeicherten VOD-/EPG-Miniaturen belegten Speicherplatz frei.';

  @override
  String get clearCoverCacheAction => 'Leeren';

  @override
  String get enginesDescription =>
      'Wählen Sie die für jeden Inhaltstyp verwendete Engine sowie die Ausweich-Engine bei Wiedergabefehler.';

  @override
  String get sortAdvancedTitle => 'Erweiterte Sortierungsoptionen';

  @override
  String get sortAdvancedSubtitle =>
      'Wählen Sie mit der Fernbedienung einen Modus:';

  @override
  String get sortDescRecentlyAdded => 'Kürzlich zur Liste hinzugefügte Inhalte';

  @override
  String get sortDescResumePriority =>
      'Setzt begonnene, unvollendete Inhalte nach oben';

  @override
  String get sortDescByRating => 'Sortierung nach vergebenen Bewertungen';

  @override
  String get sortDescByYear => 'Chronologisch nach Produktionsjahr';

  @override
  String get sortDescByDuration => 'Sortierung nach Inhaltsdauer';

  @override
  String get sortOptionActive => 'Aktiv';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get noActiveSubscription => 'Kein aktives Abonnement';

  @override
  String get noVodCategories => 'Keine Filmkategorien auf diesem Panel.';

  @override
  String get noSeriesCategories => 'Keine Serienkategorien auf diesem Panel.';

  @override
  String get neverScanned => 'Nie analysiert';

  @override
  String get scannedToday => 'Heute analysiert';

  @override
  String get scannedYesterday => 'Gestern analysiert';

  @override
  String scannedDaysAgo(int days) {
    return 'Vor $days Tagen analysiert';
  }

  @override
  String subscriptionSettingsNote(String scanned) {
    return 'Einstellungen nur für dieses Abonnement — $scanned';
  }

  @override
  String get rescanCategories => 'Kategorien erneut analysieren';

  @override
  String get scanningCategories => 'Analyse…';
}
