// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get tabAccount => 'Account';

  @override
  String get tabNetwork => 'Rete';

  @override
  String get tabPlayer => 'Lettore';

  @override
  String get tabSecurity => 'Sicurezza';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabAdvanced => 'Avanzate';

  @override
  String get sectionAccountProfile => 'Account e profilo';

  @override
  String get accountProfiles => 'Profili utente';

  @override
  String get accountProfilesSubtitle =>
      'Gestisci i profili e il profilo attivo';

  @override
  String get accountSubscriptions => 'Abbonamenti Xtream/M3U';

  @override
  String get accountNoSubscription => 'Nessun abbonamento attivo';

  @override
  String get accountPreferences => 'Preferenze profilo';

  @override
  String get accountPreferencesSubtitle => 'Lingua, tema, limiti di età, PIN';

  @override
  String get accountDeviceProfile => 'Profilo dispositivo e diagnostica';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profilo $label · diagnostica lettore';
  }

  @override
  String get sectionCloudSync => 'Sincronizzazione cloud (più dispositivi)';

  @override
  String get cloudSyncEnabled => 'Sincronizzazione attivata';

  @override
  String cloudSyncLastSync(String time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String get cloudSyncSubtitleOff =>
      'Sincronizza preferiti, visti e recenti sul cloud';

  @override
  String get cloudSyncNow => 'Sincronizza ora';

  @override
  String get cloudSyncNowSubtitle => 'Invia le modifiche locali al cloud';

  @override
  String get never => 'mai';

  @override
  String get sectionNotifications => 'Notifiche';

  @override
  String get testNotifications => 'Prova notifiche';

  @override
  String get testNotificationsSubtitle => 'Invia una notifica locale di prova';

  @override
  String get sectionBackup => 'Backup / Ripristino';

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
  String get snackBackupExported => 'Configurazione esportata negli appunti';

  @override
  String get snackNoBackup => 'Nessun backup trovato';

  @override
  String get snackImportSuccess => 'Configurazione importata correttamente';

  @override
  String snackImportError(String message) {
    return 'Errore: $message';
  }

  @override
  String get sectionAntiThrottle => 'Protezione anti-throttling ISP';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy locale)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simula l\'impronta di un browser moderno per aggirare Cloudflare';

  @override
  String get dnsProvider => 'Provider DNS (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server usato per le query DNS over HTTPS';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatico (Sistema)';

  @override
  String get sectionCloudflare => 'Ottimizzazione Cloudflare';

  @override
  String get cloudflareReset => 'Azzera configurazione Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Cancella cookie, TLS Impersonation=OFF, UA ExoPlayer predefinito';

  @override
  String get snackCloudflareReset => 'Configurazione Cloudflare azzerata';

  @override
  String get sectionEngines => 'Motori di riproduzione';

  @override
  String get enginesTile => 'Motori di riproduzione';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live: $live · VOD: $vod';
  }

  @override
  String get sectionAudioNight => 'Audio e Night Focus';

  @override
  String get audioAndNightFocus => 'Audio e Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Ottimizzazione notturna, boost dialoghi, sincronizzazione A/V';

  @override
  String get sectionZapping => 'Zapping e prestazioni';

  @override
  String get instantZapping => 'Zapping istantaneo (precaricamento)';

  @override
  String get instantZappingSubtitle =>
      'Precarica i canali adiacenti nel buffer';

  @override
  String get sectionMemory => 'Memoria e cache';

  @override
  String get sectionParental => 'Controllo genitori';

  @override
  String get parentalControl => 'Controllo genitori';

  @override
  String get parentalControlSubtitle =>
      'Aggiungi un codice PIN e limita i contenuti';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get certPinning => 'Attiva Certificate Pinning';

  @override
  String get certPinningSubtitle =>
      'Verifica l\'impronta SHA-256 del certificato SSL del server (anti-MITM)';

  @override
  String get certPinningHint =>
      'Impronte consentite (una per riga, esadecimali maiuscole):';

  @override
  String get certPinningAdd => 'Aggiungi le impronte sopra';

  @override
  String get sectionResilience => 'Resilienza del servizio';

  @override
  String get autoReconnectLive => 'Riconnessione automatica live';

  @override
  String get autoReconnectLiveSubtitle =>
      'Riconnette automaticamente se il flusso si interrompe';

  @override
  String get sectionLegal => 'Informazioni legali';

  @override
  String get legalNotice => 'Leggimi · Informativa legale';

  @override
  String get legalNoticeSubtitle =>
      'Uso dell\'app, titolari dei diritti e privacy';

  @override
  String get nightFocusTitle => 'Night Focus (modalità notte)';

  @override
  String get nightFocusEnable => 'Attiva Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Elaborazione audio in tempo reale: boost dialoghi, taglio bassi, sincronizzazione';

  @override
  String get dialogueBoost => 'Boost dialoghi (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifica le voci rispetto a effetti/musica';

  @override
  String get bassKiller => 'Bass Killer (taglio < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Atenua le basse frequenze per evitare vibrazioni';

  @override
  String get sectionAvSync => 'Sincronizzazione A/V';

  @override
  String get audioShift => 'Compensazione audio configurabile';

  @override
  String get audioShiftSubtitle => 'Compensazione audio/video manuale (ms)';

  @override
  String get manualAvCalibration => 'Calibrazione A/V manuale';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Compensazione attuale: $ms ms';
  }

  @override
  String get sectionOutput => 'Uscita audio';

  @override
  String get volumeNormalization => 'Normalizzazione del volume';

  @override
  String get volumeNormalizationSubtitle =>
      'Limita i picchi di volume tra canali/programmi (AGC)';

  @override
  String get avSyncDialogTitle => 'Calibrazione A/V';

  @override
  String get avSyncDialogLabel => 'Compensazione (ms)';

  @override
  String get avSyncDialogHint =>
      'Positivo = audio in anticipo, Negativo = audio in ritardo';

  @override
  String get apply => 'Applica';

  @override
  String get sectionAccessibility => 'Accessibilità';

  @override
  String get highContrast => 'Modalità ad alto contrasto';

  @override
  String get highContrastSubtitle =>
      'Migliora la leggibilità per gli ipovedenti';

  @override
  String get dpadNavigation => 'Navigazione D-pad potenziata';

  @override
  String get dpadNavigationSubtitle =>
      'Focus visibile, alone luminoso, ritorno a capo (modalità TV)';

  @override
  String get fontSize => 'Dimensione testo aumentata';

  @override
  String get fontSizeSubtitle => 'Ingrandisce i testi in tutta l\'app';

  @override
  String get sectionTmdb => 'Classifiche TMDB';

  @override
  String get sectionRecommendations => 'Consigli';

  @override
  String get matchmaking => 'Per te (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Gestisci abbinamento e suggerimenti personalizzati';

  @override
  String get sectionDiagnostics => 'Diagnostica e manutenzione';

  @override
  String get logsDiagnostic => 'Log e diagnostica';

  @override
  String get logsDiagnosticSubtitle => 'Visualizza log, esporta, svuota cache';

  @override
  String get clearCaches => 'Svuota tutte le cache';

  @override
  String get clearCachesSubtitle =>
      'Immagini, indice di ricerca, metadati TMDB/TVmaze';

  @override
  String get resetApp => 'Azzera applicazione';

  @override
  String get resetAppSubtitle =>
      'Cancella tutti i dati utente (profili, preferiti, cronologia)';

  @override
  String get snackCacheCleared => 'Cache svuotate (TODO)';

  @override
  String get resetAppDialogTitle => 'Azzerare l\'applicazione?';

  @override
  String get resetAppDialogBody =>
      'Tutti i dati verranno cancellati: profili, preferiti, cronologia, impostazioni. Questa azione è irreversibile.';

  @override
  String get resetAppDialogConfirm => 'Cancella tutto';

  @override
  String get tmdbKeyLabel => 'Chiave API TMDB personale (opzionale)';

  @override
  String get tmdbKeyHint =>
      'Per impostazione predefinita viene usata la chiave condivisa incorporata';

  @override
  String get tmdbKeyActive =>
      'Chiave personale attiva: quella condivisa viene ignorata';

  @override
  String get tmdbKeyShared =>
      'Chiave condivisa incorporata in uso (nessuna chiave personale)';

  @override
  String get tmdbKeyDelete => 'Elimina chiave personale';

  @override
  String get tmdbKeyColumn => 'Chiavi TMDB';

  @override
  String get language => 'Lingua';

  @override
  String get languagePreference => 'Lingua dell\'applicazione';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';
}
