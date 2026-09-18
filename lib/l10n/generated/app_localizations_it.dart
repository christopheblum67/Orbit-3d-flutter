// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get accountDeviceProfile => 'Profilo dispositivo e diagnostica';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profilo $label · diagnostica lettore';
  }

  @override
  String get accountNoSubscription => 'Nessun abbonamento attivo';

  @override
  String get accountPreferences => 'Preferenze profilo';

  @override
  String get accountPreferencesSubtitle => 'Lingua, tema, limiti di età, PIN';

  @override
  String get accountProfiles => 'Profili utente';

  @override
  String get accountProfilesSubtitle =>
      'Gestisci i profili e il profilo attivo';

  @override
  String get accountSubscriptions => 'Abbonamenti Xtream/M3U';

  @override
  String activeCountOngoing(Object count) {
    return '$count in corso';
  }

  @override
  String get addSubscription => 'Aggiungi un abbonamento';

  @override
  String addedToFavorites(Object title) {
    return '\"$title\" aggiunto ai preferiti';
  }

  @override
  String get age => 'Età';

  @override
  String get ageRange13to17 => '13 - 17 anni';

  @override
  String get ageRange18to24 => '18 - 24 anni';

  @override
  String get ageRange25to34 => '25 - 34 anni';

  @override
  String get ageRange35to44 => '35 - 44 anni';

  @override
  String get ageRange45to54 => '45 - 54 anni';

  @override
  String get ageRange55plus => '55 anni e più';

  @override
  String get ageRangeUnder12 => '- 12 anni';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'Apparire nelle ricerche e raccomandazioni';

  @override
  String get apply => 'Applica';

  @override
  String get audioAndNightFocus => 'Audio e Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Ottimizzazione notturna, boost dialoghi, sincronizzazione A/V';

  @override
  String get audioShift => 'Compensazione audio configurabile';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'Compensazione audio/video manuale (ms)';

  @override
  String get autoQualityDescription =>
      'Lascia al lettore la scelta della qualità migliore';

  @override
  String get autoReconnectLive => 'Riconnessione automatica live';

  @override
  String get autoReconnectLiveSubtitle =>
      'Riconnette automaticamente se il flusso si interrompe';

  @override
  String get avSyncDialogHint =>
      'Positivo = audio in anticipo, Negativo = audio in ritardo';

  @override
  String get avSyncDialogLabel => 'Compensazione (ms)';

  @override
  String get avSyncDialogTitle => 'Calibrazione A/V';

  @override
  String get backupExport => 'Esporta configurazione';

  @override
  String get backupExportSubtitle =>
      'Copia l\'intera configurazione negli appunti';

  @override
  String get backupImport => 'Importa configurazione';

  @override
  String get backupImportSubtitle => 'Ripristina dagli appunti (JSON)';

  @override
  String get bassKiller => 'Bass Killer (taglio < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Atenua le basse frequenze per evitare vibrazioni';

  @override
  String get cancel => 'Annulla';

  @override
  String get castToChromecast => 'Trasmetti su Chromecast';

  @override
  String get catchUpTv => 'Replica dei canali';

  @override
  String get categories => 'Categorie';

  @override
  String get certPinning => 'Attiva Certificate Pinning';

  @override
  String get certPinningAdd => 'Aggiungi le impronte sopra';

  @override
  String get certPinningHint =>
      'Impronte consentite (una per riga, esadecimali maiuscole):';

  @override
  String get certPinningSubtitle =>
      'Verifica l\'impronta SHA-256 del certificato SSL del server (anti-MITM)';

  @override
  String get changePinCode => 'Cambia codice PIN';

  @override
  String get channelsUnavailable => 'Canali non disponibili';

  @override
  String get chooseProfile => 'Scegli un profilo';

  @override
  String get clearCaches => 'Svuota tutte le cache';

  @override
  String get clearCachesSubtitle =>
      'Immagini, indice di ricerca, metadati TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'Sincronizzazione attivata';

  @override
  String cloudSyncLastSync(String time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String get cloudSyncNow => 'Sincronizza ora';

  @override
  String get cloudSyncNowSubtitle => 'Invia le modifiche locali al cloud';

  @override
  String get cloudSyncSubtitleOff =>
      'Sincronizza preferiti, visti e recenti sul cloud';

  @override
  String get cloudflareReset => 'Azzera configurazione Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Cancella cookie, TLS Impersonation=OFF, UA ExoPlayer predefinito';

  @override
  String get comingSoon => 'Prossimamente';

  @override
  String get confirmAndContinue => 'Conferma e continua';

  @override
  String get coverCacheCleared => 'Cache delle copertine svuotata.';

  @override
  String get createKidProfile => 'Crea un profilo bambino';

  @override
  String get createNewProfile => 'Crea un nuovo profilo';

  @override
  String get createProfile => 'Crea un profilo';

  @override
  String get dataAlreadyFresh => 'Dati già aggiornati (meno di 30 min)';

  @override
  String get dataAndPrivacy => 'Dati e privacy';

  @override
  String get deleteAll => 'Elimina tutto';

  @override
  String get deleteAllConfirm => 'Eliminare tutto?';

  @override
  String get deletePin => 'Elimina il PIN';

  @override
  String get deleteProfileConfirm => 'Eliminare il profilo?';

  @override
  String get detailUnavailable => 'Dettaglio non disponibile';

  @override
  String get diagnosticUnavailable => 'Diagnostica non disponibile';

  @override
  String get dialogueBoost => 'Boost dialoghi (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifica le voci rispetto a effetti/musica';

  @override
  String get disableSubtitles => 'Disattiva i sottotitoli';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'Provider DNS (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server usato per le query DNS over HTTPS';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatico (Sistema)';

  @override
  String downloadFailed(Object error) {
    return 'Download fallito: $error';
  }

  @override
  String get downloads => 'Download';

  @override
  String get dpadNavigation => 'Navigazione D-pad potenziata';

  @override
  String get dpadNavigationSubtitle =>
      'Focus visibile, alone luminoso, ritorno a capo (modalità TV)';

  @override
  String get enableParentalControl => 'Attiva il controllo parentale';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live: $live · VOD: $vod';
  }

  @override
  String get enginesTile => 'Motori di riproduzione';

  @override
  String get enterNew4DigitPin => 'Inserisci un nuovo codice a 4 cifre';

  @override
  String get epgGrille => 'EPG (guida)';

  @override
  String get epgGuideTv => 'Guida TV (EPG)';

  @override
  String get episode => 'Episodio';

  @override
  String errorGeneric(Object error) {
    return 'Errore: $error';
  }

  @override
  String errorLoading(Object error) {
    return 'Errore di caricamento: $error';
  }

  @override
  String get errorSaving => 'Errore durante il salvataggio';

  @override
  String get exitWithoutSaving => 'Uscire senza salvare?';

  @override
  String get failedToLoadProfiles => 'Impossibile caricare i profili';

  @override
  String get fallbackEngine => 'Motore di Riserva';

  @override
  String get favoriteGenres => 'Generi preferiti';

  @override
  String get filmsVod => 'Film (VOD)';

  @override
  String get firstName => 'Nome';

  @override
  String get fontSize => 'Dimensione testo aumentata';

  @override
  String get fontSizeSubtitle => 'Ingrandisce i testi in tutta l\'app';

  @override
  String get forYou => 'Per te';

  @override
  String get forYouAndDuo => 'Per te e In coppia';

  @override
  String get forYouMatchmaking => 'Per te (Matchmaking)';

  @override
  String get forward10s => 'Avanti 10s';

  @override
  String get forward30s => 'Avanti 30s';

  @override
  String get groupMode => 'In gruppo';

  @override
  String get highContrast => 'Modalità ad alto contrasto';

  @override
  String get highContrastSubtitle =>
      'Migliora la leggibilità per gli ipovedenti';

  @override
  String get historyUnavailable => 'Cronologia non disponibile';

  @override
  String get instantZapping => 'Zapping istantaneo (precaricamento)';

  @override
  String get instantZappingSubtitle =>
      'Precarica i canali adiacenti nel buffer';

  @override
  String get kidsContent => 'Contenuti per bambini';

  @override
  String get kidsMode => 'Modalità Bambini';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langSpanish => 'Español';

  @override
  String get language => 'Lingua';

  @override
  String get languageExample => 'Français, English, ecc.';

  @override
  String get languagePreference => 'Lingua dell\'applicazione';

  @override
  String get languageUndetermined => 'Indeterminato';

  @override
  String get later => 'Piú tardi';

  @override
  String get legalNotice => 'Leggimi · Informativa legale';

  @override
  String get legalNoticeSubtitle =>
      'Uso dell\'app, titolari dei diritti e privacy';

  @override
  String get liveChannelsAndZapping => 'Canali in diretta e Zapping';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'Log e diagnostica';

  @override
  String get logsDiagnosticSubtitle => 'Visualizza log, esporta, svuota cache';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'URL della playlist M3U';

  @override
  String get mainCast => 'Cast principale';

  @override
  String get manualAvCalibration => 'Calibrazione A/V manuale';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Compensazione attuale: $ms ms';
  }

  @override
  String get matchmaking => 'Per te (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Gestisci abbinamento e suggerimenti personalizzati';

  @override
  String maxProfilesReached(Object max) {
    return 'Numero massimo di profili raggiunto ($max)';
  }

  @override
  String get memory => 'Memoria';

  @override
  String get moviesUnavailable => 'Film non disponibili';

  @override
  String get multiScreen => 'Multi-schermo';

  @override
  String get multiVideo => 'Multi-video';

  @override
  String get myProfile => 'Il mio profilo';

  @override
  String get nameOptional => 'Nome (opzionale)';

  @override
  String get nameOrNickname => 'Nome / Soprannome';

  @override
  String get navigateToOkToSelect => 'Naviga su OK per selezionare';

  @override
  String get networkDisconnected => 'Rete disconnessa';

  @override
  String get never => 'mai';

  @override
  String get newAnd4K => 'Novità e 4K';

  @override
  String get newProfile => 'Nuovo profilo';

  @override
  String get nextChannel => 'Canale successivo';

  @override
  String get nightFocusEnable => 'Attiva Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Elaborazione audio in tempo reale: boost dialoghi, taglio bassi, sincronizzazione';

  @override
  String get nightFocusTitle => 'Night Focus (modalità notte)';

  @override
  String get noAudioTrackDetected => 'Nessuna traccia audio rilevata';

  @override
  String get noChannelsAvailable => 'Nessun canale disponibile';

  @override
  String get noChromecastDeviceFound =>
      'Nessun dispositivo Chromecast trovato.';

  @override
  String get noDownloads => 'Nessun download';

  @override
  String get noEpisodes => 'Nessun episodio';

  @override
  String get noFavoriteChannels => 'Nessun canale preferito';

  @override
  String get noFavoriteMovies => 'Nessun film preferito';

  @override
  String get noFavoriteReplays => 'Nessun replay preferito';

  @override
  String get noFavoriteSeries => 'Nessuna serie preferita';

  @override
  String get noHistory => 'Nessuna cronologia';

  @override
  String get noKidsChannels => 'Nessun canale per bambini';

  @override
  String get noKidsMovies => 'Nessun film per bambini';

  @override
  String get noKidsReplays => 'Nessuna replica per bambini';

  @override
  String get noKidsSeries => 'Nessuna serie per bambini';

  @override
  String get noMoviesAvailable => 'Nessun film disponibile';

  @override
  String get noProfileAvailable => 'Nessun profilo disponibile';

  @override
  String get noProfilesYet => 'Nessun profilo ancora';

  @override
  String get noProgramInfoAvailable =>
      'Nessuna informazione sul programma disponibile';

  @override
  String get noRankings => 'Nessuna classifica';

  @override
  String get noReplaysInCategory => 'Nessuna replica in questa categoria';

  @override
  String noResultsFor(Object query) {
    return 'Nessun risultato per $query';
  }

  @override
  String get noSeriesAvailable => 'Nessuna serie disponibile';

  @override
  String get noStationsAvailable => 'Nessuna stazione disponibile';

  @override
  String get noVideoQualityDetected => 'Nessuna qualità video rilevata';

  @override
  String get notAvailableInCatalog => 'Non disponibile nel catalogo';

  @override
  String get offline => 'Offline';

  @override
  String get parentalControl => 'Controllo genitori';

  @override
  String get parentalControlSubtitle =>
      'Aggiungi un codice PIN e limita i contenuti';

  @override
  String get pauseDownload => 'Metti in pausa';

  @override
  String get pinCode => 'Codice PIN';

  @override
  String get pinDeleted => 'PIN eliminato';

  @override
  String get pinMustBe4Digits => 'Il PIN deve contenere esattamente 4 cifre';

  @override
  String get pinSaved => 'PIN salvato';

  @override
  String get pip => 'Picture-in-Picture (PiP)';

  @override
  String get pipUnavailable =>
      'Picture-in-Picture (PiP) non disponibile su questo dispositivo';

  @override
  String get playHistoryCleared => 'Cronologia di riproduzione cancellata.';

  @override
  String plusAgeYears(Object age) {
    return '+$age anni';
  }

  @override
  String get preferences => 'Preferenze';

  @override
  String get previousChannel => 'Canale precedente';

  @override
  String get primaryEngine => 'Motore Principale';

  @override
  String get profileVisible => 'Profilo visibile';

  @override
  String get programGrid => 'Guida programmi';

  @override
  String get protectWithPin => 'Proteggi con codice PIN';

  @override
  String get rankingsUnavailable => 'Classifica non disponibile';

  @override
  String get receiveAlertsAndTips => 'Ricevi avvisi e suggerimenti';

  @override
  String get recentSearch => 'Ricerca recente';

  @override
  String get recentSearches => 'Recenti';

  @override
  String get recentlyWatched => 'Visti di recente';

  @override
  String get removeAll => 'Rimuovi tutto';

  @override
  String get removeFromWatchedConfirm => 'Rimuovere tutto dai visti?';

  @override
  String get replaysUnavailable => 'Replica non disponibili';

  @override
  String get reset => 'Reimposta';

  @override
  String get resetApp => 'Azzera applicazione';

  @override
  String get resetAppDialogBody =>
      'Tutti i dati verranno cancellati: profili, preferiti, cronologia, impostazioni. Questa azione è irreversibile.';

  @override
  String get resetAppDialogConfirm => 'Cancella tutto';

  @override
  String get resetAppDialogTitle => 'Azzerare l\'applicazione?';

  @override
  String get resetAppSubtitle =>
      'Cancella tutti i dati utente (profili, preferiti, cronologia)';

  @override
  String get resetCompleted => 'Reimpostazione completata';

  @override
  String get resumePlayback => 'Riprendere la riproduzione?';

  @override
  String get retry => 'Riprova';

  @override
  String get retrySearch => 'Riprova la ricerca';

  @override
  String get rewind10s => 'Indietro 10s';

  @override
  String get rewind30s => 'Indietro 30s';

  @override
  String get rightsHolders => 'Titolari dei diritti';

  @override
  String get save => 'Salva';

  @override
  String get sdkAndroid => 'SDK Android';

  @override
  String get searchChannel => 'Cerca un canale';

  @override
  String get searchError => 'Errore di ricerca';

  @override
  String get searchMovie => 'Cerca un film';

  @override
  String get searchSeries => 'Cerca una serie';

  @override
  String seasonNumber(Object season) {
    return 'Stagione $season';
  }

  @override
  String get seasonsAndEpisodes => 'Stagioni e episodi';

  @override
  String get sectionAccessibility => 'Accessibilità';

  @override
  String get sectionAccountProfile => 'Account e profilo';

  @override
  String get sectionAntiThrottle => 'Protezione anti-throttling ISP';

  @override
  String get sectionAudioNight => 'Audio e Night Focus';

  @override
  String get sectionAvSync => 'Sincronizzazione A/V';

  @override
  String get sectionBackup => 'Backup / Ripristino';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get sectionCloudSync => 'Sincronizzazione cloud (più dispositivi)';

  @override
  String get sectionCloudflare => 'Ottimizzazione Cloudflare';

  @override
  String get sectionDiagnostics => 'Diagnostica e manutenzione';

  @override
  String get sectionEngines => 'Motori di riproduzione';

  @override
  String get sectionLegal => 'Informazioni legali';

  @override
  String get sectionMemory => 'Memoria e cache';

  @override
  String get sectionNotifications => 'Notifiche';

  @override
  String get sectionOutput => 'Uscita audio';

  @override
  String get sectionParental => 'Controllo genitori';

  @override
  String get sectionRecommendations => 'Consigli';

  @override
  String get sectionResilience => 'Resilienza del servizio';

  @override
  String get sectionTmdb => 'Classifiche TMDB';

  @override
  String get sectionZapping => 'Zapping e prestazioni';

  @override
  String get select => 'Seleziona';

  @override
  String get selectProfileForRecommendations =>
      'Seleziona un profilo per vedere le sue raccomandazioni';

  @override
  String get series => 'Serie';

  @override
  String get seriesNotFound => 'Serie non trovata';

  @override
  String get seriesUnavailable => 'Serie non disponibili';

  @override
  String get seriesUnavailableTemporarily =>
      'Serie non disponibile al momento.';

  @override
  String get serverProtectedAntiLeech => 'Server protetto (anti-leech)';

  @override
  String get serverUrlPlaceholder =>
      'URL del server (es: https://provider.com)';

  @override
  String get serviceNature => 'Natura del servizio';

  @override
  String get setAsDefaultServer => 'Imposta come server predefinito';

  @override
  String get settings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get similarMovies => 'Film simili';

  @override
  String get snackBackupExported => 'Configurazione esportata negli appunti';

  @override
  String get snackCacheCleared => 'Cache svuotate (TODO)';

  @override
  String get snackCloudflareReset => 'Configurazione Cloudflare azzerata';

  @override
  String snackImportError(String message) {
    return 'Errore: $message';
  }

  @override
  String get snackImportSuccess => 'Configurazione importata correttamente';

  @override
  String get snackNoBackup => 'Nessun backup trovato';

  @override
  String get sortBestRated => 'Piú votati (XCIPTV)';

  @override
  String get sortLatestM3UXtream => 'Ultimi aggiunti M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nome (A → Z)';

  @override
  String get sortNameZToA => 'Nome (Z → A)';

  @override
  String get sortResumePriority => 'Da riprendere in prioritá';

  @override
  String get sortYearRecentToOld => 'Anno di uscita (Recente → Vecchio)';

  @override
  String specialGuestsSeason(Object season) {
    return 'Ospiti speciali - Stagione $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'Avvia';

  @override
  String get stationsUnavailable => 'Stazioni non disponibili';

  @override
  String get stopCasting => 'Intermetti la trasmissione';

  @override
  String get streamDetails => 'Dettagli dello stream';

  @override
  String subtitleLoadError(Object error) {
    return 'Errore caricamento sottotitolo: $error';
  }

  @override
  String get subtitlesUnavailable => 'Sottotitoli: non disponibili';

  @override
  String get system => 'Sistema';

  @override
  String get tabAccount => 'Account';

  @override
  String get tabAdvanced => 'Avanzate';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabNetwork => 'Rete';

  @override
  String get tabPlayer => 'Lettore';

  @override
  String get tabSecurity => 'Sicurezza';

  @override
  String get testNotifications => 'Prova notifiche';

  @override
  String get testNotificationsSubtitle => 'Invia una notifica locale di prova';

  @override
  String get theme => 'Tema';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy locale)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simula l\'impronta di un browser moderno per aggirare Cloudflare';

  @override
  String get tmdbKeyActive =>
      'Chiave personale attiva: quella condivisa viene ignorata';

  @override
  String get tmdbKeyColumn => 'Chiavi TMDB';

  @override
  String get tmdbKeyDelete => 'Elimina chiave personale';

  @override
  String get tmdbKeyHint =>
      'Per impostazione predefinita viene usata la chiave condivisa incorporata';

  @override
  String get tmdbKeyLabel => 'Chiave API TMDB personale (opzionale)';

  @override
  String get tmdbKeyShared =>
      'Chiave condivisa incorporata in uso (nessuna chiave personale)';

  @override
  String get tvChannels => 'Canali TV';

  @override
  String get unableToBuildReplayUrl =>
      'Impossibile costruire l\'URL del replay.';

  @override
  String get unlockCloudflare => 'Sblocca (Cloudflare)';

  @override
  String get unstableConnection => 'Connessione instabile';

  @override
  String get updateAllData => 'Aggiorna tutti i dati';

  @override
  String get updateThisCategory => 'Aggiorna questa categoria';

  @override
  String get updating => 'Aggiornamento in corso…';

  @override
  String get volumeNormalization => 'Normalizzazione del volume';

  @override
  String get volumeNormalizationSubtitle =>
      'Limita i picchi di volume tra canali/programmi (AGC)';

  @override
  String get watchLive => 'Guarda in diretta';

  @override
  String get whoIsWatching => 'Chi guarda?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'I tuoi canali e contenuti';
}
