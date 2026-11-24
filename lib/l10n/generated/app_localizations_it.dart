// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get castSearching => 'Ricerca di dispositivi Cast…';

  @override
  String get castReceiverNotReady => 'Il ricevitore non è ancora pronto';

  @override
  String castConnectedTo(String name) {
    return 'Connesso a $name';
  }

  @override
  String castConnectionFailed(String name) {
    return 'Impossibile connettersi a $name.';
  }

  @override
  String get playerPause => 'Pausa';

  @override
  String get playerNightFocusOn => 'Night Focus (attivo)';

  @override
  String get playerNightFocusOff => 'Night Focus (disattivato)';

  @override
  String get playerLoadingProgram => 'Caricamento programma…';

  @override
  String get audioNightHelp =>
      'L’ottimizzazione audio si applica al motore nativo quando Night Focus è attivo. Le impostazioni vengono salvate per la riproduzione successiva.';

  @override
  String get audioNightTitle => 'Ottimizzazione notturna (Night Focus)';

  @override
  String get audioDialogueBoost => 'Potenziamento dialoghi';

  @override
  String get audioDialogueHelp =>
      'Aumenta la gamma di frequenze delle voci (1–4 kHz)';

  @override
  String get audioBassLimiter => 'Riduzione bassi e limitatore';

  @override
  String get audioBassHelp =>
      'Attenua i bassi profondi e comprime i picchi improvvisi';

  @override
  String get audioVocalGain => 'Amplificazione voci:';

  @override
  String get audioSyncTitle => 'Ritardo audio (sincronizzazione A/V)';

  @override
  String startupResumeQuestion(String title, String position) {
    return 'Riprendere «$title» da $position?';
  }

  @override
  String get startupLastSession => 'Ultima sessione';

  @override
  String get seriesExternalTracksHint =>
      'Con un lettore esterno, scegli audio e sottotitoli in quel lettore. Le preferenze seguenti si applicano al lettore interno.';

  @override
  String seriesResetWatchedBody(int count, String title) {
    return 'I $count episodi visti di «$title» saranno contrassegnati come non visti per questo profilo.';
  }

  @override
  String seriesResetWatchedDone(String title) {
    return '«$title» rimosso dagli elementi visti.';
  }

  @override
  String get recommendationAffinity => 'Affinità';

  @override
  String get recommendationLoadingCatalog => 'Caricamento del catalogo…';

  @override
  String get recommendationBuilding => 'Preparazione dei tuoi suggerimenti…';

  @override
  String get recommendationLoadingDuration => 'Può richiedere fino a 1 minuto.';

  @override
  String get memoryPanelTitle => 'Memoria e cache';

  @override
  String get memoryPanelHelp =>
      'Cancella la cronologia e la cache delle immagini in memoria.';

  @override
  String get memoryHistoryTitle => 'Cancella cronologia di visione';

  @override
  String get memoryHistoryHelp =>
      'Cancella la cronologia globale e i vecchi elementi recenti, oltre ai contenuti recenti e alle posizioni di ripresa del profilo corrente.';

  @override
  String get memoryClear => 'Cancella';

  @override
  String get memoryImagesTitle => 'Svuota la cache delle immagini in memoria';

  @override
  String get memoryImagesHelp =>
      'Libera le immagini nella memoria; i file nella cache su disco vengono conservati.';

  @override
  String get memoryPurge => 'Svuota';

  @override
  String get sortOptionsTitle => 'Opzioni di ordinamento avanzato';

  @override
  String get sortOptionsHelp => 'Seleziona una modalità con il telecomando:';

  @override
  String get sortRecentDescription => 'Contenuti importati di recente';

  @override
  String get sortResumeDescription =>
      'Mostra prima i contenuti iniziati e non completati';

  @override
  String get sortRatingDescription => 'Ordina in base alle valutazioni';

  @override
  String get sortYearDescription =>
      'Ordina cronologicamente per anno di produzione';

  @override
  String get sortDurationDescription => 'Ordina per durata';

  @override
  String get sortActive => 'Attivo';

  @override
  String get onboardingWelcome => 'Benvenuto su Orbit IPTV';

  @override
  String get onboardingSubtitle => 'Configurazione automatica del dispositivo';

  @override
  String get onboardingDeviceDetected => 'Dispositivo rilevato';

  @override
  String get onboardingDevice => 'Dispositivo';

  @override
  String get onboardingConnection => 'Connessione';

  @override
  String get onboardingMobileNetwork => 'Rete mobile';

  @override
  String get onboardingOtherNetwork => 'Altro';

  @override
  String get onboardingUnknownMemory => 'Sconosciuta';

  @override
  String onboardingMemoryMb(String value) {
    return '$value MB';
  }

  @override
  String onboardingMemoryGb(String value) {
    return '$value GB';
  }

  @override
  String get onboardingEco => 'Risparmio';

  @override
  String onboardingProfile(String name) {
    return 'Profilo $name';
  }

  @override
  String get onboardingEcoDescription =>
      'Avvio rapido (1,5 s) · max 1080p · 3D e multivista disattivati';

  @override
  String get onboardingStandardDescription =>
      'Avvio rapido (2 s) · 3D fluido · multivista x2';

  @override
  String get onboardingUltraDescription =>
      'Cambio rapido dei canali (3 s · 4K HDR possibile) · multivista x4';

  @override
  String get onboardingResetRecommendation => 'Ripristina suggerimento';

  @override
  String get onboardingAdjust => 'Regola manualmente';

  @override
  String get onboardingChooseProfile => 'Scegli un profilo';

  @override
  String get onboardingRecommendedProfile => 'Profilo consigliato';

  @override
  String get onboardingEcoHint => 'Effetti 3D e multivista disattivati.';

  @override
  String get duoTitle => 'Modalità Duo';

  @override
  String duoChooseOthers(int max) {
    return 'Scegli da 1 a $max profili aggiuntivi';
  }

  @override
  String duoChooseWith(String name, int max) {
    return 'Con «$name» — scegli da 1 a $max altri profili';
  }

  @override
  String get duoCreateProfile => 'Crea almeno un secondo profilo';

  @override
  String get duoNeedsProfiles =>
      'La modalità Duo richiede almeno 2 profili in totale.';

  @override
  String get duoFull => '4 profili — squadra Duo al completo';

  @override
  String duoReady(int count) {
    return '$count profili selezionati — pronto per Duo';
  }

  @override
  String duoSelectOne(int count) {
    return 'Seleziona almeno 1 profilo aggiuntivo ($count/4)';
  }

  @override
  String get duoStart => 'Avvia Duo';

  @override
  String get duoSelected => 'Selezionato';

  @override
  String get duoMaximum => 'Massimo raggiunto';

  @override
  String get legalIntroTitle => 'Orbit IPTV · Leggimi';

  @override
  String get legalIntro =>
      'Prima di iniziare, ecco alcune brevi informazioni sull’uso dell’app e sui diritti relativi ai contenuti visualizzati.';

  @override
  String get legalServicePlayer =>
      'Orbit IPTV è un lettore IPTV: visualizza flussi forniti da server di terze parti (abbonamento M3U / Xtream Codes) senza ospitare contenuti video, audio o sottotitoli.';

  @override
  String get legalServiceMetadata =>
      'Aggrega e mostra metadati (locandine, sinossi, EPG) ottenuti tramite API pubbliche. Funziona come un browser specializzato per flussi HLS/DASH.';

  @override
  String get legalRightsProvider =>
      'Il fornitore dell’abbonamento IPTV è l’unico responsabile delle licenze dei canali, dei diritti di trasmissione e del blocco geografico dei flussi forniti.';

  @override
  String get legalRightsMetadata =>
      'Locandine e sinossi provengono da TMDb con licenza API; l’attribuzione TMDb è riportata in fondo alla pagina delle classifiche.';

  @override
  String get legalRightsContent =>
      'Orbit IPTV non archivia, ridistribuisce né monetizza alcun contenuto trasmesso.';

  @override
  String get legalUsageTitle => 'Uso dell’applicazione';

  @override
  String get legalUsageRights =>
      'Utilizzare solo con un abbonamento per cui si possiedono i diritti di trasmissione.';

  @override
  String get legalUsageRestrictions =>
      'È vietato aggirare il blocco geografico o i DRM e condividere l’account fuori dal nucleo domestico.';

  @override
  String get legalUsageEditorial =>
      'L’app non effettua alcuna selezione editoriale dei contenuti trasmessi e non controlla i flussi dei server di terze parti.';

  @override
  String get legalPrivacyStorage =>
      'Profili, preferiti, cronologia e impostazioni sono archiviati localmente. Se attivi la condivisione cloud, i dati selezionati vengono sincronizzati anche in forma crittografata.';

  @override
  String get legalPrivacyConsent =>
      'Non viene effettuata alcuna raccolta di dati per impostazione predefinita; notifiche e accessi facoltativi richiedono un consenso esplicito.';

  @override
  String get legalWarningTitle => 'Avvertenza';

  @override
  String get legalWarningBody =>
      'Questo documento non costituisce consulenza legale. Le norme variano a seconda della giurisdizione: verifica che il tuo utilizzo sia consentito nel tuo paese (legge applicabile, età minima).';

  @override
  String get legalAccept => 'Ho letto e accetto · Continua';

  @override
  String get epgReplayAvailableOnChannel =>
      'Replay disponibile su questo canale';

  @override
  String actorBornOn(String date) {
    return 'Data di nascita: $date';
  }

  @override
  String get actorGenderMale => 'Uomo';

  @override
  String get actorGenderFemale => 'Donna';

  @override
  String get crewTitle => 'Troupe';

  @override
  String get crewDirecting => 'Regia';

  @override
  String get crewWriting => 'Sceneggiatura';

  @override
  String get crewProduction => 'Produzione';

  @override
  String get crewSound => 'Suono';

  @override
  String get crewCamera => 'Riprese';

  @override
  String get crewEditing => 'Montaggio';

  @override
  String get crewArt => 'Direzione artistica';

  @override
  String get crewCostume => 'Costumi e trucco';

  @override
  String get crewVisualEffects => 'Effetti visivi';

  @override
  String get crewLighting => 'Illuminazione';

  @override
  String get menuContinue => 'Continua';

  @override
  String get menuDiscover => 'Scopri';

  @override
  String get menuHome => 'Home';

  @override
  String get menuSearch => 'Cerca';

  @override
  String get menuProfile => 'Profilo';

  @override
  String get menuSubscriptions => 'Abbonamenti';

  @override
  String get menuSelect => 'Seleziona un sottomenu';

  @override
  String get menuContent => 'Contenuti';

  @override
  String get profileMustKeepOne =>
      'Almeno un profilo deve rimanere sul dispositivo';

  @override
  String profileDeleteBody(String name) {
    return '«$name» e le relative preferenze saranno eliminati definitivamente. L\'operazione non può essere annullata.';
  }

  @override
  String get profileChange => 'Cambia profilo';

  @override
  String get profileEdit => 'Modifica';

  @override
  String get profileDelete => 'Elimina';

  @override
  String get profileBack => 'Indietro';

  @override
  String get profileAdult => 'adulto';

  @override
  String get profileChild => 'bambino';

  @override
  String get profileExpert => 'esperto';

  @override
  String get categoryTitle => 'Categorie';

  @override
  String get categoryShowAll => 'Mostra tutte';

  @override
  String get categoryScanFailed =>
      'Analisi impossibile: il provider non risponde.';

  @override
  String get categoryEmptyLive =>
      'Nessuna categoria TV in diretta da questo provider.';

  @override
  String get categoryEmptyMovies =>
      'Nessuna categoria film da questo provider.';

  @override
  String get categoryEmptySeries =>
      'Nessuna categoria serie da questo provider.';

  @override
  String categoryHidden(String label, int count) {
    return '$label ($count nascoste)';
  }

  @override
  String get categoryNeverScanned => 'Mai analizzato';

  @override
  String get categoryScannedToday => 'Analizzato oggi';

  @override
  String get categoryScannedYesterday => 'Analizzato ieri';

  @override
  String categoryScannedDaysAgo(int days) {
    return 'Analizzato $days giorni fa';
  }

  @override
  String categorySubscriptionSettings(String status) {
    return 'Impostazioni per questo abbonamento — $status';
  }

  @override
  String get categoryScanning => 'Analisi…';

  @override
  String get categoryRescan => 'Analizza di nuovo le categorie';

  @override
  String categoryChannelsCount(int count) {
    return '$count canali';
  }

  @override
  String categoryTitlesCount(int count) {
    return '$count titoli';
  }

  @override
  String get liveWatchAction => 'Guarda';

  @override
  String get livePreviewDisabled =>
      'L\'anteprima video è disattivata. Premi Guarda per aprire il canale.';

  @override
  String get livePreviewFrozen => 'Anteprima bloccata';

  @override
  String get livePreviewRetry => 'Riprova';

  @override
  String get episodeMarkWatchedFailed =>
      'Impossibile contrassegnare questo episodio come visto.';

  @override
  String get episodeAlreadyWatched => 'Episodio già visto';

  @override
  String get episodeMarkWatched => 'Segna come visto';

  @override
  String episodeResumeAt(String position) {
    return 'Riprendi da $position';
  }

  @override
  String get episodeActionsHelp =>
      'Tieni premuto OK per segnare come visto o reimpostare.';

  @override
  String episodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodi',
      one: '1 episodio',
    );
    return '$_temp0';
  }

  @override
  String episodesInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodi in corso',
      one: '1 episodio in corso',
    );
    return '$_temp0';
  }

  @override
  String episodesWatchedCount(int seen, int total) {
    return '$seen/$total visti';
  }

  @override
  String get episodeWatched => 'Visto';

  @override
  String get homeRefreshFailed =>
      'Aggiornamento non riuscito: nessuna fonte ha risposto.';

  @override
  String get homeRefreshDone => 'Aggiornamento completato.';

  @override
  String get homeRefreshEmpty =>
      'Aggiornamento completato; nessun dato disponibile.';

  @override
  String get homeChangeSubscription => 'Cambia abbonamento';

  @override
  String get homeNoSubscription => 'Nessun abbonamento';

  @override
  String get homeAddOrChangeSubscription => 'Aggiungi o cambia abbonamento';

  @override
  String get homeMultiStream => 'Fino a 4 flussi contemporaneamente';

  @override
  String get homeRadioStations => 'Stazioni in diretta';

  @override
  String get homeRefreshUnknown => 'Ultimo aggiornamento sconosciuto';

  @override
  String homeRefreshMinutes(int minutes) {
    return 'Aggiornato $minutes min fa';
  }

  @override
  String get catalogAll => 'Tutti';

  @override
  String get catalogUngrouped => 'Senza gruppo';

  @override
  String get catalogSort => 'Ordina';

  @override
  String get browseLoading => 'Caricamento…';

  @override
  String get startupRadio => 'Radio';

  @override
  String get profileCreateFirstHint =>
      'Crea il tuo primo profilo per iniziare a guardare.';

  @override
  String downloadDirectoryMissing(String path) {
    return 'Cartella non trovata: $path';
  }

  @override
  String downloadFileMissing(String path, String names) {
    return 'File non trovato: $path. File presenti: $names';
  }

  @override
  String get widevineSelectSubscription => 'Seleziona un abbonamento attivo';

  @override
  String get widevineLoading => 'Caricamento della configurazione';

  @override
  String get widevineLoadFailed => 'Impossibile caricare la configurazione';

  @override
  String widevineNoLicense(String subscription) {
    return '$subscription: nessuna licenza configurata';
  }

  @override
  String get widevineSelectFirst => 'Seleziona prima un abbonamento attivo.';

  @override
  String get widevineUnavailable =>
      'La configurazione Widevine non è disponibile.';

  @override
  String widevineSaveFailed(String error) {
    return 'Impossibile salvare Widevine: $error';
  }

  @override
  String widevineClearFailed(String error) {
    return 'Impossibile cancellare Widevine: $error';
  }

  @override
  String get widevineLicenseUrl => 'URL del server di licenza';

  @override
  String get widevineInvalidUrl => 'Inserisci un URL HTTPS valido.';

  @override
  String get widevineHeaders => 'Intestazioni HTTP (JSON, facoltativo)';

  @override
  String get widevineInvalidHeaders =>
      'Le intestazioni devono essere un oggetto JSON di stringhe.';

  @override
  String get widevineCertificate => 'Certificato base64 (facoltativo)';

  @override
  String get widevineStorageHelp =>
      'La configurazione è memorizzata in modo sicuro e associata a questo abbonamento. Non rende compatibile un lettore che non supporta Widevine.';

  @override
  String get widevineCopyLegacy => 'Copia la precedente configurazione globale';

  @override
  String get widevineClear => 'Cancella';

  @override
  String get preferenceMultiTvFailed =>
      'Impossibile salvare l’impostazione Multi TV.';

  @override
  String get preferenceLight => 'Chiaro';

  @override
  String get preferenceDark => 'Scuro';

  @override
  String get preferenceDisabled => 'Disattivato';

  @override
  String preferenceParentalEnabled(String restriction) {
    return 'Attivato · Restrizione $restriction';
  }

  @override
  String get preferenceMultiTvHelp =>
      'Mostra e consenti la riproduzione multischermo per questo profilo.';

  @override
  String get preferenceAllowRecording => 'Consenti registrazione';

  @override
  String get preferenceRecordingHelp =>
      'Consenti la registrazione dei miei contenuti preferiti';

  @override
  String get preferenceLivePreview => 'Anteprima video in diretta';

  @override
  String get preferenceLivePreviewHelp =>
      'Mostra la diretta durante la navigazione dei canali. Impostazione comune al dispositivo.';

  @override
  String get preferenceProfileHelp =>
      'Le tue preferenze vengono applicate al tuo profilo.';

  @override
  String get parentalAgeLimit => 'Limite di età';

  @override
  String get parentalNone => 'Nessuno';

  @override
  String get parentalHideAdult => 'Nascondi contenuti per adulti';

  @override
  String get parentalHideAdultHelp =>
      'Film, serie e canali classificati 18+ o erotici';

  @override
  String get parentalHideViolence => 'Nascondi la violenza';

  @override
  String get parentalHideViolenceHelp =>
      'Contenuti gore / horror / thriller / omicidio';

  @override
  String get parentalCurrentPin => 'PIN attuale: ••••';

  @override
  String get parentalSetPin => 'Imposta un PIN';

  @override
  String get parentalNewPin => 'Nuovo PIN (4 cifre)';

  @override
  String get parentalPin => 'PIN (4 cifre)';

  @override
  String get parentalShowPin => 'Mostra PIN';

  @override
  String get parentalHidePin => 'Nascondi PIN';

  @override
  String get parentalUpdatePin => 'Aggiorna PIN';

  @override
  String get subtitleAvailableTracks => 'Tracce disponibili';

  @override
  String get subtitleAddUrl => 'Aggiungi sottotitoli (URL .srt/.vtt)';

  @override
  String get subtitleLoadAction => 'Carica';

  @override
  String subtitleTrackCues(String language, int count) {
    return '$language · $count segmenti';
  }

  @override
  String multiMaxStreams(int count) {
    return 'Massimo: $count flussi su questo dispositivo.';
  }

  @override
  String get multiDisabledProfile =>
      'Multi TV è disattivata per questo profilo. Attivala nelle preferenze del profilo.';

  @override
  String get multiAnalyzingDevice => 'Analisi del dispositivo…';

  @override
  String get multiDeviceAnalysisFailed =>
      'Impossibile analizzare il dispositivo';

  @override
  String get multiDisabledEconomy =>
      'La multivista è disattivata dal profilo Economico.\nCambia il profilo in Configura dispositivo.';

  @override
  String engineInternal(String name) {
    return '$name (Interno)';
  }

  @override
  String engineExternal(String name) {
    return '$name (Esterno)';
  }

  @override
  String get engineSelectionHelp =>
      'Scegli il lettore per ogni tipo di contenuto e quello di riserva in caso di errore di riproduzione.';

  @override
  String get engineVideoDecoding => 'Decodifica video';

  @override
  String get engineAutoRecommended => 'Auto (consigliato)';

  @override
  String get engineHardware => 'Hardware';

  @override
  String get engineSoftware => 'Software';

  @override
  String get engineAutoSoftware =>
      'Auto: software selezionato per questo dispositivo';

  @override
  String get engineSubtitleDefault => 'Predefinito';

  @override
  String get engineSubtitleDisabled => 'Senza sottotitoli';

  @override
  String get engineSubtitleForced => 'Sottotitoli forzati';

  @override
  String get engineVodSubtitles => 'Sottotitoli di film e serie';

  @override
  String get profilePinsNone => 'Nessun profilo ha un PIN.';

  @override
  String get profilePinsRemoveQuestion => 'Rimuovere i PIN dei profili?';

  @override
  String profilePinsRemoveConfirmation(int count) {
    return 'I PIN verranno rimossi da $count profilo/i. I profili e i loro dati rimarranno su questo dispositivo. Le modifiche potranno essere sincronizzate con i dispositivi condivisi nel cloud.';
  }

  @override
  String get profilePinsRemove => 'Rimuovi PIN';

  @override
  String get profilePinsNothingToRemove => 'Nessun PIN da rimuovere.';

  @override
  String profilePinsRemoved(int count) {
    return 'PIN rimossi da $count profilo/i.';
  }

  @override
  String get profilePinsRemoveFailed => 'Impossibile rimuovere i PIN. Riprova.';

  @override
  String get profilePinsLocked =>
      'Un profilo è temporaneamente bloccato dopo tre PIN errati. Attendi la fine del blocco prima di modificare o rimuovere il suo PIN.';

  @override
  String get profileProtection => 'Protezione dei profili';

  @override
  String get profilePinsRemoveHelp =>
      'Rimuovi i PIN di tutti i profili su questo dispositivo. I profili e i loro dati non verranno eliminati.';

  @override
  String get profilePinsRemoving => 'Rimozione dei PIN…';

  @override
  String get profilePinsRemoveAll => 'Rimuovi i PIN dei profili';

  @override
  String get radioEmptyHint => 'Aggiungi stazioni radio nelle impostazioni.';

  @override
  String get radioStations => 'Stazioni';

  @override
  String radioStationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stazioni',
      one: '1 stazione',
    );
    return '$_temp0';
  }

  @override
  String get radioStreamUnavailable =>
      'Flusso radio non disponibile per questa stazione';

  @override
  String get livePreviousCategory => 'Categoria precedente';

  @override
  String get liveNextCategory => 'Categoria successiva';

  @override
  String get liveGuideUnavailable => 'Guida non disponibile';

  @override
  String get liveNoPrograms => 'Nessun programma disponibile';

  @override
  String get liveNoUpcomingPrograms => 'Nessun programma in arrivo';

  @override
  String get liveNoDescription => 'Nessun riassunto disponibile.';

  @override
  String get recommendationSubscriptionChanged =>
      'L’abbonamento è cambiato. Ricomincia.';

  @override
  String get recommendationCannotFavorite =>
      'Questo contenuto non può essere aggiunto ai preferiti.';

  @override
  String get recommendationFavoriteFailed =>
      'Impossibile aggiungere questo contenuto ai preferiti.';

  @override
  String get recommendationMovieQuestion => 'Questo film ti appartiene?';

  @override
  String get recommendationSeriesQuestion => 'Questa serie ti appartiene?';

  @override
  String get recommendationMovieSeen => 'Film già visto';

  @override
  String get recommendationSeriesSeen => 'Serie già vista';

  @override
  String get recommendationRemovedFuture => 'Rimosso dai prossimi suggerimenti';

  @override
  String get recommendationNotInterested => 'Non mi interessa';

  @override
  String get recommendationExcluded =>
      'Escluso definitivamente dai suggerimenti';

  @override
  String get recommendationFavoriteProfile =>
      'Aggiunto ai preferiti del profilo attuale';

  @override
  String get startupParsingPlaylist => 'Analisi della playlist M3U in corso…';

  @override
  String get startupProviderSlow =>
      'Il fornitore risponde lentamente (potrebbe essere in corso una verifica di sicurezza). Attendi…';

  @override
  String get startupLoadingRemaining => 'Caricamento di radio e replay';

  @override
  String get startupLoadingInitial =>
      'Caricamento di canali live, film, serie e guida TV';

  @override
  String get startupCheckingSubscription => 'La verifica dell’abbonamento';

  @override
  String get startupRefresh => 'L’aggiornamento';

  @override
  String startupStalled(String step, int seconds) {
    return '$step: nessun progresso da $seconds secondi. Il server potrebbe essere lento o non disponibile.';
  }

  @override
  String startupRefreshStalled(String step, int seconds) {
    return '$step: nessun progresso da $seconds secondi. Il server potrebbe essere lento o non disponibile; puoi verificare l’abbonamento.';
  }

  @override
  String get startupMovies => 'Film e VOD';

  @override
  String get startupLive => 'Canali live';

  @override
  String get startupReady => 'Pronto!';

  @override
  String get startupBackHome => 'Torna alla home';

  @override
  String get startupCheckSubscription => 'Verifica abbonamento';

  @override
  String get browseRankings => 'Classifiche';

  @override
  String get browsePopularRankings => 'Classifiche popolari';

  @override
  String get browseRankingsUnavailableHint =>
      'Le tendenze TMDB non sono disponibili. Aggiungi una chiave API TMDB nelle Impostazioni (oppure TMDB_API_KEY in assets/config/runtime.env).';

  @override
  String get browseTmdbData => 'Dati © TMDB';

  @override
  String get browsePopular => 'Popolari';

  @override
  String get browseNowPlaying => 'Al cinema';

  @override
  String get browseTopRated => 'Più votati';

  @override
  String get browseUpcoming => 'In arrivo';

  @override
  String get browseTrendingWeek => 'Tendenze della settimana';

  @override
  String get browseOnTheAir => 'In onda';

  @override
  String get browseAiringToday => 'In onda oggi';

  @override
  String get browseSeriesType => 'Serie';

  @override
  String get browseSynopsis => 'Trama';

  @override
  String get browseExploreCategories => 'Esplora per categoria';

  @override
  String get browseFavoriteHint =>
      'Tieni premuto un elemento per ritrovarlo qui.';

  @override
  String get browseRecentHint => 'I contenuti guardati appariranno qui.';

  @override
  String get browseSearchEmpty => 'Nessun contenuto corrisponde alla ricerca.';

  @override
  String browseTitlesCount(int visible, int total) {
    return '$visible titoli (su $total)';
  }

  @override
  String get catalogSearchMovies => 'Cerca un film o un genere…';

  @override
  String get catalogSearchSeries => 'Cerca una serie o un genere…';

  @override
  String get catalogLoading =>
      'Caricamento del catalogo…\nAttendi qualche secondo.';

  @override
  String get catalogNoMovies => 'La libreria dei film è attualmente vuota.';

  @override
  String get catalogNoSeries => 'La libreria delle serie è attualmente vuota.';

  @override
  String get catalogNoRecentMovies => 'Nessun film recente';

  @override
  String get catalogNoRecentSeries => 'Nessuna serie recente';

  @override
  String get catalogNoResults => 'Nessun risultato';

  @override
  String get catalogNoMoviesInCategory => 'Nessun film in questa categoria';

  @override
  String get catalogMovieFavoriteHint =>
      'Seleziona il cuore di un film per trovarlo qui.';

  @override
  String get catalogSeriesFavoriteHint =>
      'Seleziona il cuore di una serie per trovarla qui.';

  @override
  String get catalogRecentMoviesHint => 'I film guardati appariranno qui.';

  @override
  String get catalogRecentSeriesHint => 'Le serie guardate appariranno qui.';

  @override
  String get catalogMovieSearchEmpty => 'Nessun film corrisponde alla ricerca.';

  @override
  String get catalogSeriesSearchEmpty =>
      'Nessuna serie corrisponde alla ricerca.';

  @override
  String get catalogMovieCategoryEmpty =>
      'Nessun film corrisponde alla categoria.';

  @override
  String removedFromFavorites(String title) {
    return '«$title» rimosso dai preferiti';
  }

  @override
  String get liveBackToChannels => 'Torna ai canali';

  @override
  String get liveAddSourceHint =>
      'Aggiungi una fonte di canali nelle impostazioni.';

  @override
  String get liveNoChannelFound => 'Nessun canale trovato';

  @override
  String get liveNoRecentChannel => 'Nessun canale recente';

  @override
  String get liveNoChannelInGroup => 'Nessun canale in questo gruppo';

  @override
  String get liveTryAnotherSearch => 'Prova un altro termine di ricerca.';

  @override
  String get liveFavoriteHint =>
      'Seleziona il cuore di un canale per trovarlo qui.';

  @override
  String get liveRecentHint => 'I canali guardati appariranno qui.';

  @override
  String get liveEmptyGroupHint => 'Questo gruppo non contiene canali.';

  @override
  String get liveLoadingHint =>
      'Caricamento dei canali…\nAttendi prima di avviare un flusso.';

  @override
  String get replayNoChannels =>
      'Nessun canale di questo abbonamento dichiara di supportare il replay.';

  @override
  String get replayEmptyGroup =>
      'Questo gruppo non contiene canali con replay.';

  @override
  String get epgLoadingBanner =>
      'Caricamento della guida TV… i programmi appariranno a breve.';

  @override
  String get epgNoChannelsInCategory => 'Nessun canale in questa categoria';

  @override
  String get epgLoadingChannels => 'Caricamento dei canali…';

  @override
  String get epgChannelsLoadFailed => 'Impossibile caricare i canali.';

  @override
  String get replayToday => 'Oggi';

  @override
  String get replayYesterday => 'Ieri';

  @override
  String searchWithinHint(String type) {
    return 'Cerca in $type…';
  }

  @override
  String get searchAllHint =>
      'Cerca TV in diretta, film, serie, replay e guida…';

  @override
  String get searchHint => 'Cerca…';

  @override
  String searchWithinTitle(String type) {
    return 'Cerca in $type';
  }

  @override
  String get searchUnifiedTitle => 'Ricerca unificata';

  @override
  String searchWithinHelp(String type) {
    return 'Scrivi per cercare solo in $type.';
  }

  @override
  String get searchUnifiedHelp =>
      'Cerca canali in diretta, film, serie, replay o programmi TV.';

  @override
  String get searchOffline => 'Modalità offline — solo risultati locali';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultsHelp =>
      'Prova altri termini o controlla l\'ortografia.';

  @override
  String get searchAllCategories => 'Tutte';

  @override
  String get searchClearHistory => 'Cancella cronologia';

  @override
  String get settingsPlaybackEngines => 'Motori di riproduzione';

  @override
  String get settingsCloudAccount => 'Account cloud';

  @override
  String get settingsCloudSignIn => 'Accesso con Google o email';

  @override
  String get settingsSyncUnavailable =>
      'Sincronizzazione completa non disponibile';

  @override
  String get settingsSyncUnavailableHelp =>
      'La vecchia sincronizzazione non cifrata è disattivata. I profili possono essere salvati manualmente da Account cloud; gli altri dati non vengono sincronizzati.';

  @override
  String get settingsSystemAutomatic => 'Automatico (sistema)';

  @override
  String get settingsSubtitleDefault => 'Sottotitoli predefiniti';

  @override
  String get settingsSubtitleForced => 'Sottotitoli forzati';

  @override
  String get settingsSubtitleOff => 'Sottotitoli disattivati';

  @override
  String get settingsSubtitles => 'Sottotitoli';

  @override
  String get settingsProtectedPlayback => 'Riproduzione protetta';

  @override
  String get settingsCategoryFilters => 'Filtri categorie';

  @override
  String get settingsCategoryFiltersHelp =>
      'Categorie nascoste per abbonamento';

  @override
  String get episodeSelectProfile =>
      'Seleziona un profilo per modificare questo episodio.';

  @override
  String get episodeProfileChanged => 'Il profilo è cambiato. Riprova.';

  @override
  String get episodeStatusFailed =>
      'Impossibile modificare lo stato di questo episodio.';

  @override
  String get episodeResetQuestion => 'Reimpostare l\'episodio?';

  @override
  String get episodeMarkWatchedQuestion => 'Segnare come visto?';

  @override
  String episodeResetProgressMessage(String title) {
    return '«$title» sarà segnato come non visto e il progresso di riproduzione sarà cancellato.';
  }

  @override
  String episodeMarkUnwatchedMessage(String title) {
    return '«$title» sarà segnato come non visto per questo profilo.';
  }

  @override
  String episodeMarkWatchedMessage(String title) {
    return '«$title» sarà segnato come visto per questo profilo.';
  }

  @override
  String get episodeMarkUnwatched => 'Segna come non visto';

  @override
  String get detailAiData => 'Dati generati dall\'IA';

  @override
  String detailSourceData(String source) {
    return 'Dati $source';
  }

  @override
  String get detailUnavailableValue => 'Non disponibile';

  @override
  String get detailKeywords => 'Parole chiave';

  @override
  String get detailGenres => 'Generi';

  @override
  String get detailCast => 'Cast';

  @override
  String get detailTrailerFailed => 'Impossibile aprire il trailer';

  @override
  String get detailShowCrew => 'Mostra la troupe';

  @override
  String get detailHideCrew => 'Nascondi la troupe';

  @override
  String seriesRuntimePerEpisode(int minutes) {
    return '$minutes min/episodio';
  }

  @override
  String seriesNetwork(String network) {
    return 'Rete: $network';
  }

  @override
  String seriesFirstAired(String date) {
    return 'Prima trasmissione: $date';
  }

  @override
  String seriesSeasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stagioni',
      one: '1 stagione',
    );
    return '$_temp0';
  }

  @override
  String get profileDiscardHelp =>
      'Le modifiche non salvate andranno perse. Uscire comunque?';

  @override
  String get profileLeave => 'Esci';

  @override
  String get profileEditTitle => 'Modifica profilo';

  @override
  String get profileAvatarTheme => 'Tema avatar';

  @override
  String get profileAvatarThemeHelp =>
      'Scegli uno stile e poi un avatar dalla griglia';

  @override
  String get profileAvatars => 'Avatar';

  @override
  String profileCurrentTheme(String theme) {
    return 'Tema attuale: $theme';
  }

  @override
  String get profileRequired => 'Obbligatorio';

  @override
  String get profileFavoriteMovieGenres => 'Generi cinematografici preferiti';

  @override
  String get profileGenresHelp => 'Scegli uno o più stili per i consigli';

  @override
  String get profilePinMismatch => 'I PIN non coincidono.';

  @override
  String get profilePinCreateFailed => 'Impossibile creare il PIN.';

  @override
  String get profilePinActive => 'Un PIN di 4 cifre è attivo';

  @override
  String get profilePinPending =>
      'PIN confermato. Salva il profilo per attivarlo.';

  @override
  String get profilePinRequest => 'Richiedi un PIN alla selezione del profilo';

  @override
  String get profilePinCreating => 'Creazione del PIN…';

  @override
  String get profileNotFound => 'Nessun profilo da modificare';

  @override
  String get profileSaveActivate => 'Salva e attiva la protezione';

  @override
  String get profileCreateActivate => 'Crea profilo e attiva la protezione';

  @override
  String get profileSaveAction => 'Salva';

  @override
  String get profileCreateAction => 'Crea profilo';

  @override
  String get genreAction => 'Azione';

  @override
  String get genreAdventure => 'Avventura';

  @override
  String get genreAnimation => 'Animazione';

  @override
  String get genreComedy => 'Commedia';

  @override
  String get genreRomanticComedy => 'Commedia romantica';

  @override
  String get genreDrama => 'Drammatico';

  @override
  String get genreHorror => 'Horror';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreDetective => 'Poliziesco';

  @override
  String get genreCrime => 'Crimine';

  @override
  String get genreWar => 'Guerra';

  @override
  String get genreHistorical => 'Storico';

  @override
  String get genreWestern => 'Western';

  @override
  String get genreSciFi => 'Fantascienza';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreSuperheroes => 'Supereroi';

  @override
  String get genreMystery => 'Mistero';

  @override
  String get genreRomance => 'Romantico';

  @override
  String get genreMusical => 'Musical';

  @override
  String get genreMusic => 'Musica';

  @override
  String get genreBiopic => 'Biografico';

  @override
  String get genreDocumentary => 'Documentario';

  @override
  String get genreTournament => 'Torneo';

  @override
  String get genreChildren => 'Bambini';

  @override
  String get genreFamily => 'Famiglia';

  @override
  String get genreSuspense => 'Suspense';

  @override
  String get genreBlackWhite => 'Bianco e nero';

  @override
  String get genreClassic => 'Classico';

  @override
  String get cloudConfirm => 'Conferma';

  @override
  String get cloudShareProfilesTitle => 'Condividere questi profili?';

  @override
  String cloudDuplicateProfileId(String id) {
    return 'Stesso nome — identificativo: $id';
  }

  @override
  String get cloudShareProfilesHelp =>
      'I profili mancanti saranno aggiunti senza sostituire quelli esistenti. Saranno condivisi i loro preferiti e le attività, insieme a preferenze e abbonamenti, incluse le credenziali IPTV. Questi dati sono crittografati.\n\nI profili con lo stesso nome rimangono separati. Se i dati differiscono, sceglierai quali conservare.';

  @override
  String get cloudChooseSourceTitle => 'Scegli la fonte in caso di conflitto';

  @override
  String get cloudChooseSourceHelp =>
      'Le aggiunte diverse saranno unite su entrambi i dispositivi. Se lo stesso dato è stato modificato su entrambi, sarà conservata la fonte scelta qui e inviata all’altro dispositivo. La scelta vale per tutti i conflitti iniziali.';

  @override
  String get cloudSourceLocal => 'Usa questo dispositivo come fonte';

  @override
  String get cloudSourceRemote => 'Usa il cloud come fonte';

  @override
  String get cloudResetTitle => 'Ricominciare da zero nel cloud?';

  @override
  String get cloudResetHelp =>
      'Tutti i profili e i loro dati condivisi saranno eliminati dal cloud. I profili locali saranno conservati. Sugli altri dispositivi sarà necessario inserire il nuovo codice. L’operazione è irreversibile.';

  @override
  String get cloudNewCode => 'Nuovo codice';

  @override
  String get cloudConfirmCode => 'Conferma codice';

  @override
  String get cloudResetCodeError =>
      'Inserisci un nuovo codice da 3 a 10 cifre e confermalo esattamente.';

  @override
  String get cloudRestoreTitle => 'Recuperare questo profilo?';

  @override
  String cloudRestoreHelp(String name) {
    return 'Il profilo di $name sarà aggiunto senza sostituire i profili locali. Preferiti, cronologia, abbonamenti e preferenze non saranno ripristinati.';
  }

  @override
  String cloudDeleteTitle(String name) {
    return 'Eliminare $name dal cloud?';
  }

  @override
  String get cloudDeleteHelp =>
      'Il profilo e i suoi dati sincronizzati saranno eliminati dal cloud. Il profilo locale su questo dispositivo non sarà eliminato. Gli altri dispositivi saranno messi in pausa e dovranno aggiornare l’elenco.';

  @override
  String get cloudSyncFinished => 'Sincronizzazione completata';

  @override
  String get cloudSyncFinishedHelp =>
      'I profili selezionati e i loro dati sono stati sincronizzati con il cloud.';

  @override
  String get cloudResolveTitle => 'Risolvere il conflitto?';

  @override
  String get cloudResolveLocalHelp =>
      'Per gli elementi in conflitto di questa categoria sarà conservata la versione di questo dispositivo. L’altra versione, inclusa un’eventuale eliminazione, sarà sovrascritta.';

  @override
  String get cloudResolveRemoteHelp =>
      'Per gli elementi in conflitto di questa categoria sarà conservata la versione cloud. L’altra versione, inclusa un’eventuale eliminazione, sarà sovrascritta.';

  @override
  String get cloudProfilesTitle => 'I miei profili sui miei dispositivi';

  @override
  String get cloudSignInToContinue =>
      'Accedi a un account cloud per continuare.';

  @override
  String get cloudFirebaseUnavailable =>
      'Firebase non è disponibile su questo dispositivo.';

  @override
  String get cloudGoogleCanceled =>
      'Accesso Google annullato o non riuscito. Se il problema persiste, controlla la configurazione Google di questa app.';

  @override
  String get cloudGoogleConfiguration =>
      'Configurazione Google errata: controlla il client OAuth e la firma di questa app.';

  @override
  String get cloudGoogleUnavailable =>
      'L’accesso Google non è disponibile su questo dispositivo.';

  @override
  String get cloudSignInUnavailable =>
      'Il servizio di accesso non è disponibile su questo dispositivo.';

  @override
  String get cloudSignInRetry => 'Accesso non riuscito. Riprova.';

  @override
  String get cloudInvalidEmail => 'Indirizzo e-mail non valido.';

  @override
  String get cloudWeakPassword => 'La password è troppo debole.';

  @override
  String get cloudEmailInUse => 'Questo indirizzo è già in uso.';

  @override
  String get cloudInvalidCredentials => 'Indirizzo e-mail o password errati.';

  @override
  String get cloudNetworkUnavailable => 'Connessione di rete non disponibile.';

  @override
  String get cloudTooManyAttempts => 'Troppi tentativi. Riprova più tardi.';

  @override
  String get cloudMethodDisabled => 'Questo metodo di accesso non è attivo.';

  @override
  String get cloudGoogleAlreadyLinked =>
      'Questo account è già collegato a Google.';

  @override
  String get cloudGoogleOtherAccount =>
      'Questo account Google è già associato a un altro account Firebase. Nessun account o dato è stato unito. Per usare l’altro account, esci e accedi con Google.';

  @override
  String get cloudFirebaseSignInFailed =>
      'Accesso non riuscito. Riprova o controlla la configurazione Firebase.';

  @override
  String get cloudAccountIntro =>
      'Accedi per ritrovare i tuoi profili e i relativi dati sui tuoi dispositivi. I dati sono crittografati.';

  @override
  String get cloudAccountLinkHelp =>
      'Se un account è già connesso, Google verrà collegato senza cambiarne l’identificativo. Gli account distinti non vengono uniti.';

  @override
  String get cloudAccountStateError =>
      'Impossibile leggere lo stato dell’account.';

  @override
  String get cloudAccountChecking => 'Verifica dell’account…';

  @override
  String get cloudAccountNone => 'Nessun account cloud connesso.';

  @override
  String get cloudPairingCleanupFailed =>
      'Account collegato, ma la pulizia della sessione temporanea non è riuscita.';

  @override
  String get cloudPairTv => 'Associa una TV tramite codice QR';

  @override
  String get pairSignOutFirst =>
      'Esci dall’account cloud prima dell’associazione.';

  @override
  String get pairScannerAccountChanged =>
      'L’account cloud è cambiato. Chiudi questa schermata e ricomincia.';

  @override
  String get pairScannerAccountCheckFailed =>
      'Impossibile verificare l’account cloud.';

  @override
  String get pairScannerCameraFailed => 'Impossibile usare la fotocamera.';

  @override
  String get pairScannerInvalidQr =>
      'Questo codice QR non corrisponde a una sessione Orbit 3D.';

  @override
  String get pairScannerAssociationFailed =>
      'Associazione non riuscita. Controlla la rete o crea un nuovo codice QR sulla TV.';

  @override
  String get pairScannerTitle => 'Associa una TV';

  @override
  String get pairScannerSent =>
      'Richiesta inviata. Conferma l’account mostrato sulla TV.';

  @override
  String get pairScannerCameraPermission =>
      'Fotocamera non disponibile. Consenti l’accesso nelle impostazioni.';

  @override
  String get pairScannerCompareCode =>
      'Confronta questo codice con quello mostrato sulla TV:';

  @override
  String get pairScannerVerifyWarning =>
      'Accetta solo se i codici coincidono e controlli la TV.';

  @override
  String pairScannerSelectedProfiles(String profiles) {
    return 'La TV selezionerà automaticamente: $profiles.';
  }

  @override
  String get pairScannerConfirm => 'Conferma e associa';

  @override
  String get pairScannerRescan => 'Scansiona di nuovo';

  @override
  String get pairTemporaryUnavailable =>
      'La sessione temporanea non è disponibile.';

  @override
  String get pairCleanupIncomplete =>
      'Pulizia incompleta: la sessione scadrà automaticamente.';

  @override
  String get pairCleanupFailed =>
      'Pulizia non riuscita: la sessione scadrà automaticamente.';

  @override
  String get pairUnavailable =>
      'Associazione non disponibile. Controlla la rete e la configurazione Firebase.';

  @override
  String get pairRestart => 'Riavvia l’associazione.';

  @override
  String get pairTvTitle => 'Collega questa TV';

  @override
  String get pairInstructions =>
      'Sul telefono connesso, apri la sincronizzazione crittografata e scansiona questo codice QR. Confronta i codici visualizzati prima di confermare.';

  @override
  String get pairCreateQr => 'Crea un codice QR';

  @override
  String pairVerificationCode(String code) {
    return 'Codice di verifica: $code';
  }

  @override
  String get pairExpires => 'Il codice QR scade dopo cinque minuti.';

  @override
  String pairAccount(String account) {
    return 'Account da collegare: $account';
  }

  @override
  String get pairConfirmAccount => 'Conferma questo account';

  @override
  String get pairWaiting => 'In attesa della conferma sul telefono…';

  @override
  String get cloudTemporaryAccount =>
      'Un account temporaneo è connesso su questo dispositivo.';

  @override
  String cloudAccountConnected(String account) {
    return 'Account connesso: $account';
  }

  @override
  String get cloudRecoverProfiles =>
      'Ritrova i miei profili sui miei dispositivi';

  @override
  String get cloudEmail => 'Indirizzo e-mail';

  @override
  String get cloudSignIn => 'Accedi';

  @override
  String get cloudCreateAccount => 'Crea un account';

  @override
  String get cloudResetEmailSent =>
      'Se l’account esiste, è possibile inviare un’e-mail di reimpostazione.';

  @override
  String get cloudForgotPassword => 'Password dimenticata';

  @override
  String get cloudGoogleLinked => 'Account Google già collegato';

  @override
  String get cloudSignInWithGoogle => 'Accedi con Google';

  @override
  String get cloudLinkGoogle => 'Collega un account Google';

  @override
  String get cloudSignOut => 'Esci';

  @override
  String get cloudPrepareCodeHelp =>
      'Un adulto prepara il codice. Poi scegli i profili da condividere.';

  @override
  String get cloudChooseProfilesHelp =>
      'Seleziona i profili che vuoi sui tuoi dispositivi, poi premi Condividi.';

  @override
  String get cloudFirstSyncHelp =>
      'Il primo aggiornamento può richiedere più di 10 minuti. Lascia Orbit aperto fino al termine.';

  @override
  String get cloudLegacyPhrase => 'Frase segreta (vecchio formato)';

  @override
  String get cloudAdultCode => 'Codice fornito da un adulto';

  @override
  String get cloudSamePhraseHelp =>
      'Inserisci la stessa frase su entrambi i dispositivi.';

  @override
  String get cloudSameCodeHelp =>
      'Inserisci lo stesso codice su entrambi i dispositivi.';

  @override
  String get cloudShowPhrase => 'Mostra frase segreta';

  @override
  String get cloudHidePhrase => 'Nascondi frase segreta';

  @override
  String get cloudShowCode => 'Mostra codice cloud';

  @override
  String get cloudHideCode => 'Nascondi codice cloud';

  @override
  String get cloudSeeProfiles => 'Mostra i miei profili';

  @override
  String get cloudRefreshList => 'Aggiorna elenco';

  @override
  String get cloudAdultOptions => 'Opzioni per adulti';

  @override
  String get cloudUseLegacyPhrase => 'Usa una vecchia frase segreta';

  @override
  String get cloudResetAction => 'Elimina tutto dal cloud e ricomincia';

  @override
  String get cloudShareBeforePairing =>
      'Condividi prima i profili selezionati per renderli disponibili sulla TV.';

  @override
  String get cloudConfirmYourCode => 'Conferma il codice';

  @override
  String get cloudBackupTitle => 'Salvare questo profilo?';

  @override
  String cloudConfirmProfilesHelp(String name) {
    return 'Conferma il codice per i profili $name. Conservalo al sicuro: senza di esso non potrai recuperare i dati.';
  }

  @override
  String cloudBackupHelp(String name) {
    return 'Sarà salvato solo il profilo di $name, in forma crittografata. Preferiti, cronologia, abbonamenti e preferenze non sono inclusi. Se perdi il segreto, il backup non sarà recuperabile.';
  }

  @override
  String get cloudConfirmPhrase => 'Conferma la frase segreta';

  @override
  String get cloudConfirmCloudCode => 'Conferma il codice cloud';

  @override
  String get cloudShowConfirmation => 'Mostra conferma';

  @override
  String get cloudHideConfirmation => 'Nascondi conferma';

  @override
  String get cloudSecretsMismatch => 'I segreti non coincidono.';

  @override
  String get cloudSyncProfileTitle => 'Sincronizzare questo profilo?';

  @override
  String get cloudSyncProfileHelp =>
      'Il profilo attivo, i preferiti video e radio, la cronologia recente, gli episodi visti e le posizioni di riproduzione, nonché preferenze e abbonamenti, saranno sincronizzati in forma crittografata durante questa sessione. Le credenziali IPTV sono incluse. L’abbonamento attivo rimane scelto su ogni dispositivo.';

  @override
  String get cloudUpdating => 'Aggiornamento in corso…';

  @override
  String get cloudAdultMustChoose =>
      'Un adulto deve scegliere quali dati conservare.';

  @override
  String get cloudSharingEnabled => 'La condivisione è attiva.';

  @override
  String get cloudKeepOpen =>
      'Potrebbero volerci più di 10 minuti. Lascia Orbit aperto.';

  @override
  String get cloudAutoSharing =>
      'Le modifiche vengono condivise automaticamente.';

  @override
  String get cloudConflictHelp =>
      'Questo dispositivo e l’altro non concordano. Chiedi a un adulto di scegliere la versione corretta.';

  @override
  String get cloudKeepLocal => 'Conserva i dati di questo dispositivo';

  @override
  String get cloudKeepRemote => 'Conserva i dati dell’altro dispositivo';

  @override
  String get cloudShareSettings => 'Impostazioni di condivisione (adulto)';

  @override
  String get cloudUpdateNow => 'Aggiorna ora';

  @override
  String get cloudPause => 'Metti in pausa';

  @override
  String get cloudSelectProfiles => 'Scegli i profili da condividere';

  @override
  String get cloudWhichProfiles => 'Quali profili vuoi sui tuoi dispositivi?';

  @override
  String get cloudLocalProfilesUnavailable => 'Profili locali non disponibili.';

  @override
  String get cloudUnselectAll => 'Deseleziona tutto';

  @override
  String get cloudSelectAll => 'Seleziona tutto';

  @override
  String get cloudShareSelected => 'Condividi i profili selezionati';

  @override
  String get cloudShareAll => 'Condividi tutti i profili';

  @override
  String get cloudProfilesToAdd => 'Profili da aggiungere';

  @override
  String get cloudOtherOptions => 'Altre opzioni (adulto)';

  @override
  String get cloudShareActiveOnly => 'Condividi solo il profilo attivo';

  @override
  String get cloudLocalProfileKept => 'Il profilo locale viene conservato.';

  @override
  String get cloudRecover => 'Recupera';

  @override
  String get cloudDeleteAction => 'Elimina dal cloud';

  @override
  String get cloudBackupAction => 'Salva';

  @override
  String get cloudScopeFavorites => 'preferiti';

  @override
  String get cloudScopeRadioFavorites => 'preferiti radio';

  @override
  String get cloudScopeRecents => 'cronologia recente';

  @override
  String get cloudScopeWatched => 'episodi visti';

  @override
  String get cloudScopePlayback => 'posizioni di riproduzione';

  @override
  String get cloudScopePreferences => 'preferenze generali';

  @override
  String get cloudScopeProfile => 'dati del profilo';

  @override
  String get cloudProfileFallback => 'profilo';

  @override
  String get cloudScopeSubscriptions => 'abbonamenti';

  @override
  String get cloudScopeData => 'dati';

  @override
  String cloudProgressPercent(int percent) {
    return 'Completato: $percent %';
  }

  @override
  String cloudProgressScope(String scope) {
    return 'In corso: $scope.';
  }

  @override
  String cloudProgressProfile(String scope, String profile) {
    return 'In corso: $scope — $profile.';
  }

  @override
  String cloudConflictProfile(String name, String id) {
    return 'Profilo in conflitto: $name ($id)';
  }

  @override
  String cloudConflictData(String scope) {
    return 'Dati: $scope';
  }

  @override
  String get cloudChangedElsewhere =>
      'Il cloud è cambiato altrove. Ricarica prima di riprovare.';

  @override
  String get cloudBadPhrase => 'Frase segreta errata o dati cloud danneggiati.';

  @override
  String get cloudBadCode => 'Codice cloud errato o dati cloud danneggiati.';

  @override
  String get cloudAccessFailed =>
      'Impossibile accedere al cloud. Controlla la rete e la configurazione Firebase.';

  @override
  String get cloudInvalidData =>
      'Dati cloud non validi o incompatibili; nessun ripristino effettuato.';

  @override
  String get cloudOperationFailed =>
      'Operazione impossibile. Controlla la rete e aggiorna il cloud.';

  @override
  String get cloudAskAdult => 'Chiedi il codice a un adulto.';

  @override
  String get cloudCodeLength => 'Il codice deve contenere da 3 a 10 cifre.';

  @override
  String get cloudAccountChanged =>
      'L’account o il segreto sono cambiati. Ricomincia.';

  @override
  String get cloudPhraseChanged =>
      'L’account o la frase sono cambiati. Ricomincia.';

  @override
  String get cloudBackupRefreshed => 'Profilo salvato. Catalogo aggiornato.';

  @override
  String get cloudAccessEmpty => 'Accesso confermato. Nessun profilo salvato.';

  @override
  String get cloudCodeUnverified =>
      'Nessun backup trovato: il codice non può ancora essere verificato.';

  @override
  String get cloudAccessChoose =>
      'Accesso confermato. Scegli i profili da condividere.';

  @override
  String get cloudBackupRefreshFailed =>
      'Profilo salvato, ma non è stato possibile aggiornare il catalogo.';

  @override
  String get cloudPhoneProfilesMissing =>
      'I profili scelti sul telefono non sono più disponibili. Aggiorna l’elenco e selezionali di nuovo.';

  @override
  String get cloudPhoneProfilesReceived =>
      'Profili ricevuti dal telefono. Avvio della condivisione…';

  @override
  String get cloudProfileRestored =>
      'Profilo recuperato. Selezionalo nell’app, poi torna qui per attivare la sincronizzazione.';

  @override
  String get cloudWaitDelete =>
      'Attendi la fine della sincronizzazione prima di eliminare.';

  @override
  String get cloudWaitReset =>
      'Attendi la fine della sincronizzazione prima di ripristinare.';

  @override
  String get cloudResetComplete =>
      'Cloud ripristinato. Il nuovo codice è attivo; i profili locali sono stati conservati.';

  @override
  String get cloudWaitSelection =>
      'È in corso una sincronizzazione. Attendi che termini prima di modificare la selezione.';

  @override
  String get cloudProfilesChanged =>
      'I profili sono cambiati. Controlla la selezione.';

  @override
  String get cloudRestoredProfileMissing =>
      'Un profilo recuperato non è stato trovato. Riprova.';

  @override
  String cloudRestoringProfiles(int current, int total) {
    return 'Recupero dei profili: $current / $total.';
  }

  @override
  String get cloudCheckingProfiles =>
      'Verifica e salvataggio dei profili cloud.';

  @override
  String get cloudPartialRestore =>
      'Alcuni profili potrebbero essere stati recuperati. Controlla l’elenco prima di riprovare.';

  @override
  String get cloudStartingSync => 'Avvio della sincronizzazione.';

  @override
  String get cloudProfilesBackedUp => 'I profili sono stati salvati.';

  @override
  String get subscriptionTitle => 'Abbonamenti';

  @override
  String get subscriptionRefreshSuccess =>
      'Aggiornamento completato: almeno una fonte è stata aggiornata.';

  @override
  String get subscriptionRefreshFailed =>
      'Aggiornamento non riuscito: nessun dato ricevuto.';

  @override
  String get subscriptionConnectionHelp =>
      'Connessione non riuscita o credenziali rifiutate. Controlla indirizzo del server, nome utente, password e connessione Internet.';

  @override
  String get subscriptionDuplicateHelp =>
      'Possibile duplicato: più abbonamenti hanno la stessa configurazione. Nessuno è stato eliminato; i preferiti potrebbero essere diversi.';

  @override
  String get subscriptionRefreshActive =>
      'Forza aggiornamento dell’abbonamento attivo';

  @override
  String get subscriptionActivationFailed =>
      'Impossibile attivare l’abbonamento.';

  @override
  String get subscriptionDeleteTitle => 'Eliminare l’abbonamento?';

  @override
  String subscriptionDeleteHelp(String name) {
    return 'Eliminare «$name»? L’operazione è irreversibile.';
  }

  @override
  String get subscriptionNoActive =>
      'Nessun abbonamento attivo. Selezionane uno o aggiungine uno nuovo.';

  @override
  String get subscriptionActivate => 'Attiva';

  @override
  String get subscriptionNone => 'Nessun abbonamento';

  @override
  String get subscriptionEmptyHelp =>
      'Aggiungi il tuo primo abbonamento Xtream Codes o M3U per iniziare.';

  @override
  String get subscriptionFilterHelp =>
      'Le categorie da nascondere si impostano in Impostazioni > Accessibilità > Filtri categorie.';

  @override
  String get subscriptionPossibleDuplicate => 'Possibile duplicato';

  @override
  String get subscriptionInactive => 'Inattivo';

  @override
  String get subscriptionTesting => 'Test in corso…';

  @override
  String get subscriptionUntested => 'Non testato';

  @override
  String get subscriptionTestOk => 'Test OK';

  @override
  String subscriptionTestLatency(int latency) {
    return 'Test OK • $latency ms';
  }

  @override
  String get subscriptionTestFailed => 'Fallito';

  @override
  String get subscriptionTestAction => 'Testa';

  @override
  String get subscriptionIncomplete => 'Configurazione incompleta';

  @override
  String get connectionInvalidConfiguration =>
      'Le impostazioni di questo abbonamento sono mancanti o non valide.';

  @override
  String get connectionCheckServerOrPlaylist =>
      'Controlla l’URL del server o della playlist.';

  @override
  String get connectionCheckCredentials =>
      'Controlla anche il nome utente e la password.';

  @override
  String get connectionCertificateExpired => 'Certificato SSL scaduto';

  @override
  String get connectionSslError => 'Errore SSL/TLS';

  @override
  String get connectionCertificateExpiredHelp =>
      'Il certificato di sicurezza del server è scaduto.';

  @override
  String get connectionSslHelp =>
      'Impossibile stabilire una connessione sicura al server.';

  @override
  String get connectionCheckDateTime =>
      'Controlla la data e l’ora del dispositivo.';

  @override
  String get connectionContactProvider =>
      'Contatta il tuo fornitore se il problema persiste.';

  @override
  String get connectionDnsFailure => 'Server non trovato (DNS)';

  @override
  String get connectionDnsFailureHelp =>
      'Impossibile trovare il server. Controlla il suo indirizzo e la connessione Internet.';

  @override
  String get connectionNetworkUnavailable => 'Rete non raggiungibile';

  @override
  String get connectionNetworkUnavailableHelp =>
      'Impossibile raggiungere la rete del server. Controlla la connessione Internet.';

  @override
  String get connectionServerError => 'Server temporaneamente non disponibile';

  @override
  String get connectionServerUnreachable => 'Server non raggiungibile';

  @override
  String get connectionServerUnreachableHelp =>
      'Impossibile raggiungere il server. Controlla l’indirizzo e la connessione Internet.';

  @override
  String get connectionCheckUrl =>
      'Controlla che l’URL sia scritto correttamente.';

  @override
  String get connectionTryAnotherNetwork => 'Prova da un’altra rete.';

  @override
  String get connectionContactUnreachableProvider =>
      'Contatta il tuo fornitore se il server resta irraggiungibile.';

  @override
  String get connectionTimeout => 'Tempo di risposta scaduto';

  @override
  String get connectionTimeoutHelp =>
      'Il server non ha risposto in tempo. Potrebbe essere lento o temporaneamente sovraccarico.';

  @override
  String get connectionTryLater => 'Riprova tra qualche minuto.';

  @override
  String get connectionCheckInternet => 'Controlla la connessione Internet.';

  @override
  String get connectionInvalidCredentials => 'Credenziali non valide';

  @override
  String get connectionAccessDenied => 'Accesso negato';

  @override
  String get connectionXtreamRejected =>
      'Il server ha rifiutato il nome utente o la password Xtream.';

  @override
  String get connectionM3uAuthorization =>
      'La playlist M3U richiede un’autorizzazione o un URL valido.';

  @override
  String get connectionCheckCredentialsCase =>
      'Controlla il nome utente e la password, comprese le maiuscole.';

  @override
  String get connectionConfirmCredentials =>
      'Chiedi al tuo fornitore di confermare i dati di accesso.';

  @override
  String get connectionAccountUnavailable =>
      'Abbonamento o account non disponibile';

  @override
  String get connectionAccountUnavailableHelp =>
      'L’account potrebbe essere scaduto, disattivato o aver raggiunto il limite di connessioni.';

  @override
  String get connectionCheckSubscription =>
      'Verifica lo stato dell’abbonamento con il tuo fornitore.';

  @override
  String get connectionCloseOtherDevices =>
      'Chiudi le connessioni sugli altri dispositivi e riprova.';

  @override
  String get connectionForbidden => 'Accesso vietato';

  @override
  String get connectionForbiddenHelp =>
      'Il server rifiuta la connessione. L’account o l’indirizzo IP potrebbero essere bloccati.';

  @override
  String get connectionCheckActiveSubscription =>
      'Verifica che l’abbonamento sia ancora attivo.';

  @override
  String get connectionCheckProviderAccess =>
      'Contatta il tuo fornitore per verificare l’accesso.';

  @override
  String get connectionNotFound => 'Indirizzo non trovato (404)';

  @override
  String get connectionInvalidRequest => 'Richiesta non valida';

  @override
  String get connectionInvalidAddress =>
      'L’indirizzo del server o il punto di accesso non sembrano corretti.';

  @override
  String get connectionCheckBaseUrl =>
      'Controlla l’URL di base del server o l’URL M3U.';

  @override
  String get connectionUseXtreamPanel =>
      'Usa l’indirizzo del pannello Xtream senza aggiungere player_api.php.';

  @override
  String connectionServerUnavailable(int status) {
    return 'Server temporaneamente non disponibile ($status)';
  }

  @override
  String get connectionServerProblem =>
      'Il server del fornitore ha riscontrato un problema.';

  @override
  String get connectionInvalidPlaylist => 'Playlist M3U non valida o vuota';

  @override
  String get connectionInvalidPlaylistHelp =>
      'La playlist non contiene dati leggibili nel formato previsto.';

  @override
  String get connectionCheckPlaylistUrl =>
      'Verifica che l’URL punti a una playlist M3U aggiornata.';

  @override
  String get connectionRequestNewUrl => 'Chiedi un nuovo URL al tuo fornitore.';

  @override
  String get connectionTestFailed => 'Test di connessione non riuscito';

  @override
  String get connectionUnexpectedError =>
      'Un errore imprevisto ha impedito la connessione a questo abbonamento.';

  @override
  String get connectionCheckSubscriptionAndInternet =>
      'Controlla i dati dell’abbonamento e la connessione Internet.';

  @override
  String get connectionRetryOrContact =>
      'Riprova o contatta il tuo fornitore se il problema persiste.';

  @override
  String get connectionThingsToCheck => 'Cosa verificare';

  @override
  String get connectionTechnicalDetails => 'Dettagli tecnici';

  @override
  String subscriptionSemantic(String name) {
    return 'Abbonamento $name';
  }

  @override
  String get subscriptionSemanticActive => 'attivo';

  @override
  String get subscriptionSemanticDuplicate => 'possibile duplicato';

  @override
  String get subscriptionAdded => 'Abbonamento aggiunto';

  @override
  String subscriptionAddedHelp(String name) {
    return '«$name» è stato salvato. Puoi testare la connessione e poi attivare l’abbonamento.';
  }

  @override
  String get subscriptionTestRunning => 'Test della connessione in corso…';

  @override
  String get subscriptionTestSuccess => 'Test della connessione riuscito.';

  @override
  String get subscriptionTestUnavailable =>
      'Il risultato del test non è disponibile.';

  @override
  String get subscriptionTestError =>
      'Impossibile completare il test della connessione.';

  @override
  String get subscriptionEditTitle => 'Modifica abbonamento';

  @override
  String get subscriptionNewTitle => 'Nuovo abbonamento';

  @override
  String get subscriptionName => 'Nome dell’abbonamento';

  @override
  String get subscriptionUsername => 'Nome utente';

  @override
  String get subscriptionPassword => 'Password';

  @override
  String get subscriptionShowPassword => 'Mostra password';

  @override
  String get subscriptionHidePassword => 'Nascondi password';

  @override
  String get subscriptionAdd => 'Aggiungi';

  @override
  String get playerExternalOpened =>
      'Riproduzione aperta in un lettore esterno';

  @override
  String get playerExternalTrackHelp =>
      'Scegli le tracce audio e i sottotitoli nel lettore esterno: le preferenze di Orbit non vengono trasferite.';

  @override
  String get playerProviderBlocked =>
      'Flusso temporaneamente bloccato dal fornitore';

  @override
  String get playerStreamNotStarting =>
      'Il flusso viene ricevuto ma la riproduzione non inizia. La traccia potrebbe essere troppo impegnativa per questo dispositivo.';

  @override
  String get playerStreamFrozen =>
      'Il flusso viene ricevuto ma la riproduzione è bloccata.';

  @override
  String get playerStreamRecovering =>
      'Il flusso non avanza più. Tentativo di recupero…';

  @override
  String playerCooldown(int seconds) {
    return 'Server protetto (anti-leech), nuovo tentativo tra ${seconds}s';
  }

  @override
  String get playerProviderBlockedHelp =>
      'La protezione anti-leech del server ha interrotto la riproduzione. Attendi da 3 a 5 minuti senza riprodurre, poi riavvia questo canale senza cambiare canale.';

  @override
  String get playerLiveUnavailable => 'Flusso non disponibile';

  @override
  String get playerLiveUnavailableHelp =>
      'Impossibile avviare questo canale. Controlla l’abbonamento o riprova.';

  @override
  String playerNextEpisode(String title) {
    return 'Prossimo episodio: $title';
  }

  @override
  String playerNextEpisodeCountdown(String title, int seconds) {
    return 'Prossimo episodio: $title ($seconds s)';
  }

  @override
  String get profileSelectToContinue => 'Seleziona un profilo per continuare';

  @override
  String get profileCreateToWatch =>
      'Crea il tuo primo profilo per iniziare a guardare.';

  @override
  String get profileNavigationHelp =>
      'Frecce + OK per navigare · Tocca una scheda per selezionarla';

  @override
  String get profileActive => 'Attivo';

  @override
  String get resumeAction => 'Riprendi';

  @override
  String get refreshRecommendations => 'Aggiorna i consigli';

  @override
  String get localVideoProxy => 'Proxy video locale sperimentale';

  @override
  String get localVideoProxySubtitle =>
      'Per film e serie nel lettore interno, con cache su disco limitata.';

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
  String get accountPreferencesSubtitle => 'Lingua, PIN';

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
  String get deleteDownload => 'Elimina';

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
    return 'Ultima sincronizzazione (questa installazione): $time';
  }

  @override
  String get cloudSyncNow => 'Sincronizza ora';

  @override
  String get cloudSyncNowSubtitle =>
      'Sincronizza preferiti, cronologia e progressi di riproduzione di questa installazione';

  @override
  String get cloudSyncSubtitleOff =>
      'Sincronizza preferiti, episodi visti, recenti e progressi di riproduzione di questa installazione';

  @override
  String get cloudflareReset => 'Reimposta sessione Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Rinnova la sessione Cloudflare attiva.';

  @override
  String get cloudflareNoActiveSession =>
      'Non ci sono sessioni Cloudflare attive da rinnovare.';

  @override
  String get comingSoon => 'Prossimamente';

  @override
  String get settingsContact => 'Contatto';

  @override
  String get settingsActivateApp => 'Attiva app';

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
  String currentProfileLabel(String name) {
    return 'Profilo attuale: $name';
  }

  @override
  String get dataAlreadyFresh => 'Dati già aggiornati (meno di 8 ore)';

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
  String downloadAdded(String title) {
    return '«$title» aggiunto ai download';
  }

  @override
  String get downloadCompleted => 'Scaricato';

  @override
  String get downloadInProgress => 'Download in corso';

  @override
  String get downloadOffline => 'Scarica per l’uso offline';

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
  String get noneOption => 'Nessuno';

  @override
  String get play => 'Riprodurre';

  @override
  String get newAnd4K => 'Film on Demand';

  @override
  String get seasonsAndEpisodes => 'Serie on Demand';

  @override
  String get languagePreference => 'Lingua dell\'applicazione';

  @override
  String get languageUndetermined => 'Indeterminato';

  @override
  String get later => 'Piú tardi';

  @override
  String get legalNotice => 'Informativa legale / Contatto';

  @override
  String get contactTeamTitle => 'Contatta il team';

  @override
  String get contactTeamIntro =>
      'Ascoltiamo le tue esperienze, le idee per migliorare e le segnalazioni di bug per far evolvere l’applicazione.';

  @override
  String get contactAddress => 'Indirizzo di contatto:';

  @override
  String get contactImportant => 'Importante:';

  @override
  String get contactTeamWarning =>
      'Non risponderemo ai messaggi che richiedono una proroga del periodo di prova o un mese gratuito.';

  @override
  String get contactCompose => 'Scrivi un’email';

  @override
  String get contactMailUnavailable =>
      'Nessuna applicazione email disponibile.';

  @override
  String get contactLegal => 'Informativa legale';

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
  String get moreResults => 'Mostra altri risultati';

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
  String get noGroupAffinity => 'Nessuna affinità comune trovata';

  @override
  String get noHistory => 'Nessuna cronologia';

  @override
  String get historyLoading => 'Caricamento della cronologia…';

  @override
  String get historyEmptyHint => 'Le tue riproduzioni recenti appariranno qui.';

  @override
  String get refreshAction => 'Aggiorna';

  @override
  String get favoritesAdd => 'Aggiungi ai preferiti';

  @override
  String get favoritesRemove => 'Rimuovi dai preferiti';

  @override
  String get favoritesNeedScope =>
      'Sono necessari un profilo e un abbonamento attivi.';

  @override
  String get favoritesReplayHint =>
      'Tocca il cuore di un replay per ritrovarlo qui.';

  @override
  String favoritesClearPrompt(int total) {
    return 'Rimuovere i $total preferiti salvati? L’elenco dei preferiti verrà svuotato.';
  }

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
  String get noRecommendations => 'Nessun consiglio disponibile';

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
  String get pinRequired => 'PIN richiesto';

  @override
  String get pinSet => 'Imposta un PIN';

  @override
  String get pinThisProfile => 'questo profilo';

  @override
  String pinEnterForProfile(String name) {
    return 'Inserisci il PIN di $name';
  }

  @override
  String get pinConfirmFourDigits => 'Conferma il codice a 4 cifre';

  @override
  String get pinChooseFourDigits => 'Scegli un codice a 4 cifre';

  @override
  String get pinVerifyFailed => 'Impossibile verificare il PIN.';

  @override
  String get pinConfirmInstruction => 'Dopo 4 cifre, premi ✓ per confermare.';

  @override
  String pinIncorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentativi rimanenti',
      one: '1 tentativo rimanente',
    );
    return 'Codice errato — $_temp0. Dopo 3 errori l\'accesso è bloccato per 2 ore.';
  }

  @override
  String pinTemporarilyLocked(int minutes) {
    return 'Troppi PIN errati. Riprova tra $minutes min.';
  }

  @override
  String get pinChecking => 'Verifica in corso…';

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
  String profilesSelected(int count) {
    return '$count profili selezionati';
  }

  @override
  String get profileVisible => 'Profilo visibile';

  @override
  String get programGrid => 'Guida programmi';

  @override
  String get protectWithPin => 'Proteggi con codice PIN';

  @override
  String get rankingsUnavailable => 'Classifica non disponibile';

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
      'Le cronologie locali di visione e ricerca saranno cancellate. Profili, abbonamenti, dati API, impostazioni TLS e dei flussi, Cloudflare e le altre impostazioni saranno conservati. Questa azione è irreversibile.';

  @override
  String get resetAppDialogConfirm => 'Reimposta';

  @override
  String get resetAppDialogTitle => 'Azzerare l\'applicazione?';

  @override
  String get resetAppSubtitle =>
      'Cancella la cronologia locale conservando profili e configurazione';

  @override
  String get resetFailed => 'Reimpostazione incompleta. Riprova.';

  @override
  String get resetCompleted => 'Reimpostazione completata';

  @override
  String get resumePlayback => 'Riprendere la riproduzione?';

  @override
  String get retry => 'Riprova';

  @override
  String get tmdbMovieRecommendations => 'Consigli TMDB';

  @override
  String get tmdbRecommendationsEmpty =>
      'Nessun consiglio TMDB per questo film.';

  @override
  String get tmdbRecommendationsError =>
      'Impossibile caricare i consigli TMDB.';

  @override
  String get tmdbRecommendationsUnavailable =>
      'Consigli TMDB non disponibili per questo film.';

  @override
  String get playbackDelayedTitle => 'La riproduzione richiede troppo tempo';

  @override
  String get playbackDelayedMessage =>
      'La riproduzione non inizia o non riprende. La causa potrebbe essere il flusso, la connessione o il formato video.';

  @override
  String get playbackContinueWaiting => 'Continua ad aspettare';

  @override
  String get playbackUnavailableTitle => 'Riproduzione non disponibile';

  @override
  String get playbackUnavailableMessage =>
      'Questo film o episodio non può essere riprodotto al momento. Riprova o controlla la connessione e il formato del file.';

  @override
  String get protectedPlaybackUnsupportedMessage =>
      'Il lettore integrato non può riprodurre in sicurezza questo flusso DASH o inoltrato con intestazioni protette.';

  @override
  String get greenScreenDetectedTitle => 'Rilevato un problema video';

  @override
  String get externalPlayerLimitationsTitle =>
      'Limitazioni dei lettori esterni';

  @override
  String get externalPlayerLimitationsDescription =>
      'Orbit non trasmette le preferenze audio e sottotitoli a VLC o MX Player: seleziona le tracce nel lettore esterno. Per le serie, l’episodio successivo si avvia automaticamente solo se MX Player conferma la fine; altrimenti avvialo manualmente tornando in Orbit. Vale anche per il lettore di riserva.';

  @override
  String get actorShowFilmography => 'Vedi filmografia';

  @override
  String get actorFilmographyUnavailable => 'Filmografia non disponibile.';

  @override
  String get actorCreditFilm => 'Film';

  @override
  String get actorCreditSeries => 'Serie';

  @override
  String actorCreditRole(String role) {
    return 'Ruolo: $role';
  }

  @override
  String get actorCreditTmdbUnavailable => 'Dettagli TMDB non disponibili.';

  @override
  String get actorCreditSynopsisUnavailable => 'Sinossi non disponibile.';

  @override
  String get actorCreditCatalogUnconfirmed =>
      'Nessuna corrispondenza confermata nel catalogo.';

  @override
  String get actorCreditOpenCatalog => 'Vedi nel catalogo';

  @override
  String get greenScreenDetectedMessage =>
      'È stato rilevato un problema video (schermo verde). Il lettore attuale potrebbe non decodificare correttamente questo flusso. Prova un altro lettore in Impostazioni > Lettore > Motori di riproduzione, quindi riavvia la riproduzione.';

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
  String selectAtLeastOneProfile(int count) {
    return 'Seleziona almeno 1 profilo aggiuntivo ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'Seleziona un profilo per vedere le sue raccomandazioni';

  @override
  String get series => 'Serie';

  @override
  String get seriesNotFound => 'Serie non trovata';

  @override
  String get seriesMissingId =>
      'ID della serie mancante (navigazione errata). Torna all’elenco e riprova.';

  @override
  String get seriesEnriching => 'Arricchimento dei metadati…';

  @override
  String get seriesLoading => 'Caricamento della serie…';

  @override
  String get seriesNoEpisodesHint => 'Questa serie non ha ancora episodi.';

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
  String get snackCacheCleared => 'Caches svuotate';

  @override
  String get snackCloudflareReset => 'Sessione Cloudflare rinnovata';

  @override
  String snackImportError(String message) {
    return 'Errore: $message';
  }

  @override
  String get snackImportSuccess => 'Configurazione importata correttamente';

  @override
  String get snackNoBackup => 'Nessun backup trovato';

  @override
  String get sortAffinity => 'Per affinità';

  @override
  String get sortAffinityDescription =>
      'Ordina in base ai tuoi gusti dichiarati nel profilo (matchmaking)';

  @override
  String get sortAscending => 'Ordine crescente';

  @override
  String get sortByDuration => 'Per durata';

  @override
  String get sortByRating => 'Per voto';

  @override
  String get sortByYear => 'Per anno';

  @override
  String get sortDescending => 'Ordine decrescente';

  @override
  String get sortLatestM3UXtream => 'Ultimi aggiunti M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nome (A → Z)';

  @override
  String get sortNameZToA => 'Nome (Z → A)';

  @override
  String get sortResumePriority => 'Da riprendere in prioritá';

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
  String get tmdbKeyValid => 'La chiave TMDB è valida';

  @override
  String get tmdbKeyValidationFailed =>
      'TMDB ha rifiutato la chiave o la rete non è disponibile: controlla la chiave';

  @override
  String get tvChannels => 'Canali TV';

  @override
  String get unableToBuildReplayUrl =>
      'Impossibile costruire l\'URL del replay.';

  @override
  String get unlockCloudflare => 'Sblocca (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'Verifica del provider richiesta';

  @override
  String get cloudflareChallengeHelp =>
      'Il provider richiede una verifica Cloudflare. Completala in questa finestra, chiudila e riprova. I cookie di questa pagina non vengono inviati al lettore, quindi la riproduzione potrebbe restare bloccata.';

  @override
  String get openProviderWebsite => 'Apri il sito del provider';

  @override
  String get providerWebsiteUnavailable =>
      'Impossibile aprire il sito del provider. Controlla l\'indirizzo dell\'abbonamento e riprova.';

  @override
  String get unstableConnection => 'Connessione instabile';

  @override
  String get updateAllData => 'Aggiorna tutti i dati';

  @override
  String get aiTopicsTitle => 'Argomenti consigliati dall IA';

  @override
  String get updateThisCategory => 'Aggiorna questa categoria';

  @override
  String get updating => 'Aggiornamento in corso…';

  @override
  String get updatingMediaContent =>
      'Aggiornamento dei contenuti multimediali…';

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

  @override
  String get subtitleSection => 'Sottotitoli';

  @override
  String get seriesDefaultAudioLanguage => 'Lingua audio predefinita';

  @override
  String get seriesDefaultSubtitleLanguage =>
      'Lingua predefinita dei sottotitoli';

  @override
  String get seriesSelectLanguage => 'Seleziona una lingua';

  @override
  String get seriesStreamDefault => '(Predefinita del flusso)';

  @override
  String get seriesChooseLanguageFirst => 'Scegli prima una lingua';

  @override
  String get seriesDefaultAllEpisodes =>
      'Usa la lingua predefinita del flusso per tutti gli episodi';

  @override
  String get seriesDefaultUnlessEpisodeChoice =>
      'Usa la lingua del flusso salvo scelta per episodio';

  @override
  String get seriesForceLanguageAllEpisodes =>
      'Forza questa lingua per tutti gli episodi';

  @override
  String get seriesApplyIfAvailable => 'Applica se disponibile';

  @override
  String get seriesSearchingAudio => 'Ricerca delle tracce audio…';

  @override
  String get seriesSubtitlesDisabled => '(Disattivati)';

  @override
  String get seriesDisableSubtitlesAll =>
      'Disattiva i sottotitoli per tutti gli episodi';

  @override
  String get seriesDisableSubtitlesDefault =>
      'Disattiva i sottotitoli per impostazione predefinita';

  @override
  String get seriesSearchingSubtitles =>
      'Ricerca delle tracce dei sottotitoli…';

  @override
  String get seriesNoSubtitleTracks =>
      'Nessuna traccia rilevata: scegli una lingua, verrà usata se disponibile.';

  @override
  String get seriesLanguageFrench => 'Francese';

  @override
  String get seriesLanguageEnglish => 'Inglese';

  @override
  String get seriesLanguageSpanish => 'Spagnolo';

  @override
  String get seriesLanguageGerman => 'Tedesco';

  @override
  String get seriesLanguageItalian => 'Italiano';

  @override
  String get seriesLanguageArabic => 'Arabo';

  @override
  String get subtitleEmbeddedSection => 'Sottotitoli incorporati';

  @override
  String get subtitleForcedLabel => 'Forzato';

  @override
  String get subtitleEmbeddedLabel => 'Incorporato';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'Video';

  @override
  String get autoQuality => 'Automatico';

  @override
  String get subtitleNotApplicable => 'Non applicabile';

  @override
  String get subtitleNotApplicableInfo =>
      'Uno stream live non pubblica tracce di sottotitoli.';

  @override
  String get subtitleUnavailable => 'Non disponibile';

  @override
  String get subtitleNoTrack => 'Nessuna traccia';

  @override
  String get subtitleNoTrackInfo =>
      'Il provider non pubblica sottotitoli per questo contenuto.';

  @override
  String get subtitleGuessed => 'Tracce dedotte';

  @override
  String get subtitleGuessedInfo =>
      'Il provider non dichiara i sottotitoli: queste tracce derivano da una convenzione URL. Quella inesistente segnalera un errore all\'attivazione.';

  @override
  String get subtitleUnavailableToast => 'Sottotitolo non disponibile';

  @override
  String get audioTrackFallback => 'Traccia audio';

  @override
  String get subtitleLoading => 'Caricamento sottotitoli…';

  @override
  String get videoQualityFallback => 'Qualità video';

  @override
  String get close => 'Chiudi';

  @override
  String get streamTracksError =>
      'Impossibile leggere le tracce di questo stream.';

  @override
  String get subtitleProviderNoAnswer => 'Il provider non ha risposto.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Sottotitolo non disponibile: $reason';
  }

  @override
  String get epgNoDataTitle => 'Nessun dato di programma';

  @override
  String get epgLiveNow => 'In diretta';

  @override
  String get epgSelectChannelHint =>
      'Seleziona un canale per vedere il programma';

  @override
  String get epgNow => 'Adesso';

  @override
  String get epgZoomIn => 'Ingrandisci';

  @override
  String get epgZoomOut => 'Riduci';

  @override
  String get epgNoCurrentProgram => 'Nessun programma in corso';

  @override
  String replayWindowBadge(Object days) {
    return 'Replay $days g';
  }

  @override
  String replayWindowBadgeHours(Object hours) {
    return 'Replay $hours h';
  }

  @override
  String get replayNoAvailable => 'Nessun replay disponibile';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'Nessun programma già andato in onda nell\'archivio di $days giorni di questo account per questo canale.';
  }

  @override
  String get replayNonePublished =>
      'Il provider non pubblica programmi già andati in onda per questo canale.';

  @override
  String get epgActionFavorite => 'Preferito';

  @override
  String get epgActionRecording => 'Registra';

  @override
  String get epgActionReminder => 'Promemoria';

  @override
  String get epgStartReplay => 'Avvia replay';

  @override
  String get epgBack => 'Indietro';

  @override
  String epgWatchChannel(Object name) {
    return 'Guarda $name';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'Il provider non serve sottotitoli per questo contenuto.';

  @override
  String subtitleVerifying(Object count) {
    return 'Verifica dei sottotitoli… ($count)';
  }

  @override
  String get favorites => 'Preferiti';

  @override
  String get films => 'Film';

  @override
  String get replay => 'Replay';

  @override
  String get myContent => 'I miei contenuti';

  @override
  String get contentTypeSelector => 'Tipo di contenuto';

  @override
  String get downloadStatusDownloading => 'Download in corso';

  @override
  String get downloadStatusPreparing => 'Preparazione';

  @override
  String get downloadStatusPaused => 'In pausa';

  @override
  String get downloadStatusCompleted => 'Completato';

  @override
  String get downloadStatusFailed => 'Non riuscito';

  @override
  String get downloadStatusCancelled => 'Annullato';

  @override
  String get downloadStatusQueued => 'In coda';

  @override
  String get history => 'Cronologia';

  @override
  String get explore => 'Esplora';

  @override
  String get downloadsEmptyHint =>
      'Aggiungi contenuti dalla scheda di un film o una serie.';

  @override
  String get downloadsLocation => 'File';

  @override
  String get advancedSettingsTitle => 'Impostazioni avanzate';

  @override
  String get freeMode => 'Modalità gratuita';

  @override
  String get freeModePending =>
      'Da configurare in seguito; per ora non ha alcun effetto.';

  @override
  String get advancedSettingsIntro =>
      'Credenziali API e impostazioni di rete. Queste impostazioni vincolano il tuo account a servizi di terze parti: una chiave condivisa consuma la sua quota e un\'impostazione di rete errata può impedire l\'avvio dell\'app.';

  @override
  String get advancedStatus => 'Stato delle credenziali';

  @override
  String get advancedAccessTitle => 'Accesso riservato';

  @override
  String get advancedAccessHint => 'Codice';

  @override
  String get advancedAccessConfirm => 'Apri';

  @override
  String get advancedAccessWrong => 'Codice errato';

  @override
  String get advancedHiddenHint => 'Tieni premuto per le impostazioni avanzate';

  @override
  String get favoritesAndDownloads => 'Preferiti e Download';

  @override
  String get activeAudio => 'Audio su questo schermo';

  @override
  String get addChannel => 'Aggiungi un canale';

  @override
  String get noChannelSelected => 'Nessun canale selezionato';

  @override
  String get removeChannel => 'Rimuovi canale';

  @override
  String get avatarCategoryAll => 'Tutte';

  @override
  String get avatarCategoryCharacters => 'Personaggi';

  @override
  String get avatarCategorySuperheroes => 'Supereroi';

  @override
  String get avatarCategoryAnimals => 'Animali';

  @override
  String get avatarCategoryFlowers => 'Fiori';

  @override
  String get avatarCategoryNature => 'Natura';

  @override
  String get avatarCategoryYouth => 'Giovani';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Nero e Bianco';

  @override
  String get updateTitle => 'Aggiornamenti';

  @override
  String get updateSettingsSubtitle =>
      'Controlla l’ultima versione ufficiale su GitHub';

  @override
  String get updateChecking => 'Ricerca aggiornamenti…';

  @override
  String get updateCurrent => 'È già installata l’ultima versione disponibile.';

  @override
  String get updateAvailable => 'È disponibile una nuova versione:';

  @override
  String get updateDownloading => 'Download e verifica dell’APK…';

  @override
  String get updateReady => 'Apertura del programma di installazione Android…';

  @override
  String get updatePermission =>
      'Consenti a Orbit di installare app sconosciute nelle impostazioni Android, poi torna qui e riprova.';

  @override
  String get updateNoRelease =>
      'Nessuna versione stabile disponibile su GitHub.';

  @override
  String get updateAssetError =>
      'La versione non contiene l’APK universale ufficiale o i dati di verifica.';

  @override
  String get updateInvalidApk =>
      'APK incompatibile, firmato con un’altra chiave o senza una versione Android superiore. Installazione annullata.';

  @override
  String get updateIntegrityError =>
      'La verifica del file scaricato è fallita. Installazione annullata.';

  @override
  String get updateGenericError =>
      'Aggiornamento non riuscito. Controlla la connessione e riprova.';

  @override
  String get updateLater => 'Più tardi';

  @override
  String get updateInstall => 'Aggiorna';

  @override
  String get updateRetryInstall => 'Riprova l’installazione';

  @override
  String get updateRetry => 'Riprova';

  @override
  String get avatarCategoryPixels => 'Pixel';

  @override
  String get unassignedLegacyLibraryItems =>
      'Alcuni vecchi preferiti o download non sono visibili perché l\'abbonamento originale è sconosciuto. Sono comunque conservati.';

  @override
  String get forceNoSubtitlesSubtitle =>
      'Disattiva automaticamente i sottotitoli all\'avvio di un film o una serie';

  @override
  String get backTooltip => 'Indietro';

  @override
  String get categoryFilters => 'Filtri delle categorie';

  @override
  String get categoryFiltersSubtitle => 'Categorie nascoste per abbonamento';

  @override
  String get memoryCacheTitle => 'Gestione della memoria e della cache';

  @override
  String get memoryCacheSubtitle => 'Libera spazio e pulisci i dati locali.';

  @override
  String get clearWatchHistoryTitle => 'Svuota la cronologia di visione';

  @override
  String get clearWatchHistorySubtitle =>
      'Cancella l\'elenco dei contenuti visti di recente e le posizioni di ripresa.';

  @override
  String get clearWatchHistoryAction => 'Svuota';

  @override
  String get clearCoverCacheTitle => 'Pulisci la cache delle copertine';

  @override
  String get clearCoverCacheSubtitle =>
      'Libera lo spazio su disco occupato dalle miniature VOD/EPG salvate localmente.';

  @override
  String get clearCoverCacheAction => 'Svuota';

  @override
  String get enginesDescription =>
      'Scegli il motore usato per ogni tipo di contenuto e il motore di ripiego in caso di errore di riproduzione.';

  @override
  String get sortAdvancedTitle => 'Opzioni di ordinamento avanzate';

  @override
  String get sortAdvancedSubtitle =>
      'Seleziona una modalità con il telecomando:';

  @override
  String get sortDescRecentlyAdded =>
      'Contenuti aggiunti di recente all\'elenco';

  @override
  String get sortDescResumePriority =>
      'Mette in cima i contenuti iniziati e non conclusi';

  @override
  String get sortDescByRating => 'Classifica in base ai voti assegnati';

  @override
  String get sortDescByYear => 'Ordine cronologico per anno di produzione';

  @override
  String get sortDescByDuration => 'Ordinamento per durata del contenuto';

  @override
  String get sortOptionActive => 'Attivo';

  @override
  String get showAll => 'Mostra tutto';

  @override
  String get noActiveSubscription => 'Nessun abbonamento attivo';

  @override
  String get noVodCategories => 'Nessuna categoria film su questo pannello.';

  @override
  String get noSeriesCategories =>
      'Nessuna categoria serie su questo pannello.';

  @override
  String get neverScanned => 'Mai analizzato';

  @override
  String get scannedToday => 'Analizzato oggi';

  @override
  String get scannedYesterday => 'Analizzato ieri';

  @override
  String scannedDaysAgo(int days) {
    return 'Analizzato $days giorni fa';
  }

  @override
  String subscriptionSettingsNote(String scanned) {
    return 'Impostazioni specifiche di questo abbonamento — $scanned';
  }

  @override
  String get rescanCategories => 'Rianalizza le categorie';

  @override
  String get scanningCategories => 'Analisi…';
}
