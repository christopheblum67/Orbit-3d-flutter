// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get accountDeviceProfile => 'Profil appareil & Diagnostic';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profil $label Â· diagnostic lecteur';
  }

  @override
  String get accountNoSubscription => 'Aucun abonnement actif';

  @override
  String get accountPreferences => 'PrÃ©fÃ©rences profil';

  @override
  String get accountPreferencesSubtitle =>
      'Langue, thÃ¨me, restrictions d\'Ã¢ge, PIN';

  @override
  String get accountProfiles => 'Profils utilisateurs';

  @override
  String get accountProfilesSubtitle => 'GÃ©rer les profils et le profil actif';

  @override
  String get accountSubscriptions => 'Abonnements Xtream/M3U';

  @override
  String activeCountOngoing(Object count) {
    return '$count en cours';
  }

  @override
  String get addSubscription => 'Ajouter un abonnement';

  @override
  String addedToFavorites(Object title) {
    return 'Â« $title Â» ajoutÃ© aux favoris';
  }

  @override
  String get age => 'Ã‚ge';

  @override
  String get ageRange13to17 => '13 - 17 ans';

  @override
  String get ageRange18to24 => '18 - 24 ans';

  @override
  String get ageRange25to34 => '25 - 34 ans';

  @override
  String get ageRange35to44 => '35 - 44 ans';

  @override
  String get ageRange45to54 => '45 - 54 ans';

  @override
  String get ageRange55plus => '55 ans et plus';

  @override
  String get ageRangeUnder12 => '- 12 ans';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'ApparaÃ®tre dans les recherches et recommandations';

  @override
  String get apply => 'Appliquer';

  @override
  String get audioAndNightFocus => 'Audio & Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Optimisation nocturne, dialogue boost, synchronisation A/V';

  @override
  String get audioShift => 'DÃ©calage audio configurable';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'DÃ©calage audio/vidÃ©o manuel (ms)';

  @override
  String get autoQualityDescription =>
      'Laisse le lecteur choisir la meilleure qualitÃ©';

  @override
  String get autoReconnectLive => 'Auto-rÃ©connexion Live';

  @override
  String get autoReconnectLiveSubtitle =>
      'Tente de reconnecter automatiquement si le flux coupe';

  @override
  String get avSyncDialogHint =>
      'Positif = audio en avance, NÃ©gatif = audio en retard';

  @override
  String get avSyncDialogLabel => 'DÃ©calage (ms)';

  @override
  String get avSyncDialogTitle => 'Calibrage A/V';

  @override
  String get backupExport => 'Exporter la configuration';

  @override
  String get backupExportSubtitle =>
      'Copie la config complÃ¨te dans le presse-papiers';

  @override
  String get backupImport => 'Importer la configuration';

  @override
  String get backupImportSubtitle => 'Restaure depuis le presse-papiers (JSON)';

  @override
  String get bassKiller => 'Bass Killer (coupe < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'AttÃ©nue les basses frÃ©quences pour Ã©viter les vibrations';

  @override
  String get cancel => 'Annuler';

  @override
  String get castToChromecast => 'Diffuser sur Chromecast';

  @override
  String get catchUpTv => 'Rattrapage des chaÃ®nes';

  @override
  String get categories => 'CatÃ©gories';

  @override
  String get certPinning => 'Activer Certificate Pinning';

  @override
  String get certPinningAdd => 'Ajouter les empreintes ci-dessus';

  @override
  String get certPinningHint =>
      'Empreintes autorisÃ©es (une par ligne, format hex uppercase) :';

  @override
  String get certPinningSubtitle =>
      'VÃ©rifie l\'empreinte SHA-256 du certificat SSL du serveur (anti-MITM)';

  @override
  String get changePinCode => 'Changer le code PIN';

  @override
  String get channelsUnavailable => 'ChaÃ®nes indisponibles';

  @override
  String get chooseProfile => 'Choisir un profil';

  @override
  String get clearCaches => 'Vider tous les caches';

  @override
  String get clearCachesSubtitle =>
      'Images, index recherche, mÃ©tadonnÃ©es TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'Synchronisation activÃ©e';

  @override
  String cloudSyncLastSync(String time) {
    return 'DerniÃ¨re sync : $time';
  }

  @override
  String get cloudSyncNow => 'Synchroniser maintenant';

  @override
  String get cloudSyncNowSubtitle =>
      'Pousse les modifications locales vers le cloud';

  @override
  String get cloudSyncSubtitleOff =>
      'Synchronise favoris, vus et rÃ©cents vers le cloud';

  @override
  String get cloudflareReset => 'RÃ©initialiser config Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Efface cookies, remet TLS Impersonation=OFF, UA ExoPlayer par dÃ©faut';

  @override
  String get comingSoon => 'BientÃ´t disponible';

  @override
  String get confirmAndContinue => 'Valider et continuer';

  @override
  String get coverCacheCleared => 'Cache des pochettes purgÃ©.';

  @override
  String get createKidProfile => 'CrÃ©er un profil Enfant';

  @override
  String get createNewProfile => 'CrÃ©er un nouveau profil';

  @override
  String get createProfile => 'CrÃ©er un profil';

  @override
  String currentProfileLabel(String name) {
    return 'Profil courant : $name';
  }

  @override
  String get dataAlreadyFresh => 'DonnÃ©es dÃ©jÃ  fraÃ®ches (moins de 30 min)';

  @override
  String get dataAndPrivacy => 'DonnÃ©es & confidentialitÃ©';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get deleteAllConfirm => 'Tout supprimer ?';

  @override
  String get deletePin => 'Supprimer le PIN';

  @override
  String get deleteProfileConfirm => 'Supprimer le profil ?';

  @override
  String get detailUnavailable => 'DÃ©tail indisponible';

  @override
  String get diagnosticUnavailable => 'Diagnostic indisponible';

  @override
  String get dialogueBoost => 'Boost Dialogues (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifie les voix par rapport aux effets/musique';

  @override
  String get disableSubtitles => 'DÃ©sactiver les sous-titres';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'Fournisseur DNS (DoH)';

  @override
  String get dnsProviderSubtitle =>
      'Serveur utilisÃ© pour les requÃªtes DNS over HTTPS';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatique (SystÃ¨me)';

  @override
  String downloadFailed(Object error) {
    return 'TÃ©lÃ©chargement impossible : $error';
  }

  @override
  String get downloads => 'TÃ©lÃ©chargements';

  @override
  String get dpadNavigation => 'Navigation D-pad renforcÃ©e';

  @override
  String get dpadNavigationSubtitle =>
      'Focus visible, halo lumineux, wrap texte (TV mode)';

  @override
  String get enableParentalControl => 'Activer le contrÃ´le parental';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live : $live Â· VOD : $vod';
  }

  @override
  String get enginesTile => 'Moteurs de lecture';

  @override
  String get enterNew4DigitPin => 'Saisir un nouveau code Ã  4 chiffres';

  @override
  String get epgGrille => 'EPG (grille)';

  @override
  String get epgGuideTv => 'Guide TV (EPG)';

  @override
  String get episode => 'Ã‰pisode';

  @override
  String errorGeneric(Object error) {
    return 'Erreur: $error';
  }

  @override
  String errorLoading(Object error) {
    return 'Erreur de chargement: $error';
  }

  @override
  String get errorSaving => 'Erreur lors de la sauvegarde';

  @override
  String get exitWithoutSaving => 'Quitter sans sauvegarder ?';

  @override
  String get failedToLoadProfiles => 'Impossible de charger les profils';

  @override
  String get fallbackEngine => 'Moteur de Secours';

  @override
  String get favoriteGenres => 'Genres favoris';

  @override
  String get filmsVod => 'Films (VOD)';

  @override
  String get firstName => 'PrÃ©nom';

  @override
  String get fontSize => 'Taille du texte augmentÃ©e';

  @override
  String get fontSizeSubtitle => 'Agrandit les textes dans toute l\'app';

  @override
  String get forYou => 'Pour vous';

  @override
  String get forYouAndDuo => 'Pour vous & En duo';

  @override
  String get forYouMatchmaking => 'Pour vous (matchmaking)';

  @override
  String get forward10s => 'Avancer 10s';

  @override
  String get forward30s => 'Avancer 30s';

  @override
  String get groupMode => 'En groupe';

  @override
  String get highContrast => 'Mode contraste Ã©levÃ©';

  @override
  String get highContrastSubtitle =>
      'AmÃ©liore la lisibilitÃ© pour les malvoyants';

  @override
  String get historyUnavailable => 'Historique indisponible';

  @override
  String get instantZapping => 'Zapping InstantanÃ© (Prefetching)';

  @override
  String get instantZappingSubtitle =>
      'PrÃ©charge les chaÃ®nes adjacentes en mÃ©moire tampon';

  @override
  String get langArabic => 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©';

  @override
  String get langFrench => 'FranÃ§ais';

  @override
  String get langPortuguese => 'PortuguÃªs';

  @override
  String get langSpanish => 'EspaÃ±ol';

  @override
  String get language => 'Langue';

  @override
  String get languageExample => 'FranÃ§ais, English, etc.';

  @override
  String get languagePreference => 'Langue de l\'application';

  @override
  String get languageUndetermined => 'IndÃ©terminÃ©';

  @override
  String get later => 'Plus tard';

  @override
  String get legalNotice => 'Lisez-moi Â· Mentions lÃ©gales';

  @override
  String get legalNoticeSubtitle =>
      'Usage de l\'application, ayants droit et confidentialitÃ©';

  @override
  String get liveChannelsAndZapping => 'ChaÃ®nes en direct & Zapping';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'Logs & Diagnostic';

  @override
  String get logsDiagnosticSubtitle =>
      'Voir les logs, exporter, vider le cache';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'URL de la playlist M3U';

  @override
  String get mainCast => 'Distribution principale';

  @override
  String get manualAvCalibration => 'Calibrage manuel A/V';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'DÃ©calage actuel: $ms ms';
  }

  @override
  String get matchmaking => 'Pour vous (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'GÃ©rer l\'appariement et les suggestions personnalisÃ©es';

  @override
  String maxProfilesReached(Object max) {
    return 'Nombre maximal de profils atteint ($max)';
  }

  @override
  String get memory => 'MÃ©moire';

  @override
  String get moreResults => 'Voir plus de rÃ©sultats';

  @override
  String get moviesUnavailable => 'Films indisponibles';

  @override
  String get multiScreen => 'Multi-Ã©crans';

  @override
  String get multiVideo => 'Multi-vidÃ©o';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get nameOptional => 'Nom (optionnel)';

  @override
  String get nameOrNickname => 'Nom / Pseudo';

  @override
  String get navigateToOkToSelect => 'Naviguer Ã  OK pour sÃ©lectionner';

  @override
  String get networkDisconnected => 'RÃ©seau coupÃ©';

  @override
  String get never => 'jamais';

  @override
  String get newAnd4K => 'Films Ã  la demande';

  @override
  String get newProfile => 'Nouveau profil';

  @override
  String get nextChannel => 'ChaÃ®ne suivante';

  @override
  String get nightFocusEnable => 'Activer Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Traitement audio temps rÃ©el : boost dialogues, coupe basses, sync';

  @override
  String get nightFocusTitle => 'Night Focus (Mode Nuit)';

  @override
  String get noAudioTrackDetected => 'Aucune piste audio dÃ©tectÃ©e';

  @override
  String get noChannelsAvailable => 'Aucune chaÃ®ne disponible';

  @override
  String get noChromecastDeviceFound => 'Aucun appareil Chromecast trouvÃ©.';

  @override
  String get noDownloads => 'Aucun tÃ©lÃ©chargement';

  @override
  String get noEpisodes => 'Aucun Ã©pisode';

  @override
  String get noFavoriteChannels => 'Aucune chaÃ®ne favorite';

  @override
  String get noFavoriteMovies => 'Aucun film favori';

  @override
  String get noFavoriteReplays => 'Aucun replay favori';

  @override
  String get noFavoriteSeries => 'Aucune sÃ©rie favorite';

  @override
  String get noGroupAffinity => 'Aucune affinitÃ© commune trouvÃ©e';

  @override
  String get noHistory => 'Aucun historique';

  @override
  String get noKidsChannels => 'Aucune chaÃ®ne pour enfants';

  @override
  String get noKidsMovies => 'Aucun film pour enfants';

  @override
  String get noKidsReplays => 'Aucun replay pour enfants';

  @override
  String get noKidsSeries => 'Aucune sÃ©rie pour enfants';

  @override
  String get noMoviesAvailable => 'Aucun film disponible';

  @override
  String get noProfileAvailable => 'Aucun profil disponible';

  @override
  String get noProfilesYet => 'Aucun profil pour le moment';

  @override
  String get noProgramInfoAvailable =>
      'Aucune information de programme disponible';

  @override
  String get noRankings => 'Aucun classement';

  @override
  String get noRecommendations => 'Aucune recommandation disponible';

  @override
  String get noReplaysInCategory => 'Aucun replay dans cette catÃ©gorie';

  @override
  String noResultsFor(Object query) {
    return 'Aucun rÃ©sultat pour $query';
  }

  @override
  String get noSeriesAvailable => 'Aucune sÃ©rie disponible';

  @override
  String get noStationsAvailable => 'Aucune station disponible';

  @override
  String get noVideoQualityDetected => 'Aucune qualitÃ© vidÃ©o dÃ©tectÃ©e';

  @override
  String get notAvailableInCatalog => 'Non disponible dans le catalogue';

  @override
  String get offline => 'Hors ligne';

  @override
  String get parentalControl => 'ContrÃ´le parental';

  @override
  String get parentalControlSubtitle =>
      'Ajouter un code PIN et restreindre le contenu';

  @override
  String get pauseDownload => 'Mettre en pause';

  @override
  String get play => 'Lire';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get pinDeleted => 'PIN supprimÃ©';

  @override
  String get pinMustBe4Digits => 'Le PIN doit contenir exactement 4 chiffres';

  @override
  String get pinSaved => 'PIN enregistrÃ©';

  @override
  String get pip => 'Vue flottante (PiP)';

  @override
  String get pipUnavailable =>
      'Vue flottante (PiP) non disponible sur cet appareil';

  @override
  String get playHistoryCleared => 'Historique de lecture effacÃ©.';

  @override
  String plusAgeYears(Object age) {
    return '+$age ans';
  }

  @override
  String get preferences => 'PrÃ©fÃ©rences';

  @override
  String get previousChannel => 'ChaÃ®ne prÃ©cÃ©dente';

  @override
  String get primaryEngine => 'Moteur Principal';

  @override
  String profilesSelected(int count) {
    return '$count profils sÃ©lectionnÃ©s';
  }

  @override
  String get profileVisible => 'Profil visible';

  @override
  String get programGrid => 'Grille des programmes';

  @override
  String get protectWithPin => 'ProtÃ©ger par code PIN';

  @override
  String get rankingsUnavailable => 'Classement indisponible';

  @override
  String get recentSearch => 'Recherche rÃ©cente';

  @override
  String get recentSearches => 'RÃ©cents';

  @override
  String get recentlyWatched => 'RÃ©cemment';

  @override
  String get removeAll => 'Tout retirer';

  @override
  String get removeFromWatchedConfirm => 'Tout retirer des dÃ©jÃ  vus ?';

  @override
  String get replaysUnavailable => 'Replays indisponibles';

  @override
  String get reset => 'RÃ©initialiser';

  @override
  String get resetApp => 'RÃ©initialiser l\'application';

  @override
  String get resetAppDialogBody =>
      'Toutes les donnÃ©es seront effacÃ©es : profils, favoris, historique, rÃ©glages. Cette action est irrÃ©versible.';

  @override
  String get resetAppDialogConfirm => 'Tout effacer';

  @override
  String get resetAppDialogTitle => 'RÃ©initialiser l\'application ?';

  @override
  String get resetAppSubtitle =>
      'Efface toutes les donnÃ©es utilisateur (profils, favoris, historique)';

  @override
  String get resetCompleted => 'RÃ©initialisation effectuÃ©e';

  @override
  String get resumePlayback => 'Reprendre la lecture ?';

  @override
  String get retry => 'RÃ©essayer';

  @override
  String get retrySearch => 'Relancer la recherche';

  @override
  String get rewind10s => 'Reculer 10s';

  @override
  String get rewind30s => 'Reculer 30s';

  @override
  String get rightsHolders => 'Ayants droit';

  @override
  String get save => 'Sauver';

  @override
  String get sdkAndroid => 'SDK Android';

  @override
  String get searchChannel => 'Rechercher une chaÃ®ne';

  @override
  String get searchError => 'Erreur de recherche';

  @override
  String get searchMovie => 'Rechercher un film';

  @override
  String get searchSeries => 'Rechercher une sÃ©rie';

  @override
  String seasonNumber(Object season) {
    return 'Saison $season';
  }

  @override
  String get seasonsAndEpisodes => 'SÃ©ries Ã  la demande';

  @override
  String get sectionAccessibility => 'AccessibilitÃ©';

  @override
  String get sectionAccountProfile => 'Compte & Profil';

  @override
  String get sectionAntiThrottle => 'Protection anti-bridage FAI';

  @override
  String get sectionAudioNight => 'Audio & Night Focus';

  @override
  String get sectionAvSync => 'Synchronisation A/V';

  @override
  String get sectionBackup => 'Sauvegarde / Restauration';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get sectionCloudSync => 'Synchronisation Cloud (multi-appareils)';

  @override
  String get sectionCloudflare => 'Optimisation Cloudflare';

  @override
  String get sectionDiagnostics => 'Diagnostic & Maintenance';

  @override
  String get sectionEngines => 'Moteurs de lecture';

  @override
  String get sectionLegal => 'Informations lÃ©gales';

  @override
  String get sectionMemory => 'MÃ©moire & Cache';

  @override
  String get sectionOutput => 'Sortie Audio';

  @override
  String get sectionParental => 'ContrÃ´le parental';

  @override
  String get sectionRecommendations => 'Recommandations';

  @override
  String get sectionResilience => 'RÃ©silience du Service';

  @override
  String get sectionTmdb => 'Classements TMDB';

  @override
  String get sectionZapping => 'Zapping & Performance';

  @override
  String get select => 'SÃ©lectionner';

  @override
  String selectAtLeastOneProfile(int count) {
    return 'SÃ©lectionnez au moins 1 profil supplÃ©mentaire ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'SÃ©lectionnez un profil pour voir ses recommandations';

  @override
  String get series => 'SÃ©ries';

  @override
  String get seriesNotFound => 'SÃ©rie introuvable';

  @override
  String get seriesUnavailable => 'SÃ©ries indisponibles';

  @override
  String get seriesUnavailableTemporarily =>
      'SÃ©rie indisponible pour le moment.';

  @override
  String get serverProtectedAntiLeech => 'Serveur protÃ©gÃ© (anti-leech)';

  @override
  String get serverUrlPlaceholder =>
      'URL du serveur (ex: https://provider.com)';

  @override
  String get serviceNature => 'Nature du service';

  @override
  String get setAsDefaultServer => 'DÃ©finir comme serveur par dÃ©faut';

  @override
  String get settings => 'RÃ©glages';

  @override
  String get settingsTitle => 'Configuration';

  @override
  String get similarMovies => 'Films similaires';

  @override
  String get snackBackupExported =>
      'Configuration exportÃ©e dans le presse-papiers';

  @override
  String get snackCacheCleared => 'Caches vidÃ©s';

  @override
  String get snackCloudflareReset => 'Config Cloudflare rÃ©initialisÃ©e';

  @override
  String snackImportError(String message) {
    return 'Erreur: $message';
  }

  @override
  String get snackImportSuccess => 'Configuration importÃ©e avec succÃ¨s';

  @override
  String get snackNoBackup => 'Aucune sauvegarde trouvÃ©e';

  @override
  String get sortAffinity => 'Par affinitÃ©';

  @override
  String get sortAffinityDescription =>
      'Classe selon vos goÃ»ts dÃ©clarÃ©s dans le profil (matchmaking)';

  @override
  String get sortAscending => 'Tri croissant';

  @override
  String get sortByDuration => 'Par durÃ©e';

  @override
  String get sortByRating => 'Par note';

  @override
  String get sortByYear => 'Par annÃ©e';

  @override
  String get sortDescending => 'Tri dÃ©croissant';

  @override
  String get sortLatestM3UXtream => 'Derniers Ajouts M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nom (A â†’ Z)';

  @override
  String get sortNameZToA => 'Nom (Z â†’ A)';

  @override
  String get sortResumePriority => 'Ã€ reprendre en prioritÃ©';

  @override
  String specialGuestsSeason(Object season) {
    return 'InvitÃ©s spÃ©ciaux - Saison $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'DÃ©marrer';

  @override
  String get stationsUnavailable => 'Stations indisponibles';

  @override
  String get stopCasting => 'ArrÃªter la diffusion';

  @override
  String get streamDetails => 'DÃ©tails du flux';

  @override
  String subtitleLoadError(Object error) {
    return 'Erreur chargement sous-titre: $error';
  }

  @override
  String get subtitlesUnavailable => 'Sous-titres : non disponibles';

  @override
  String get system => 'SystÃ¨me';

  @override
  String get tabAccount => 'Compte';

  @override
  String get tabAdvanced => 'AvancÃ©';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabNetwork => 'RÃ©seau';

  @override
  String get tabPlayer => 'Lecteur';

  @override
  String get tabSecurity => 'SÃ©curitÃ©';

  @override
  String get theme => 'ThÃ¨me';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy Local)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simule l\'empreinte d\'un navigateur moderne pour contourner Cloudflare';

  @override
  String get tmdbKeyActive =>
      'ClÃ© personnelle active â€” la clÃ© partagÃ©e est ignorÃ©e';

  @override
  String get tmdbKeyColumn => 'ClÃ©s TMDB';

  @override
  String get tmdbKeyDelete => 'Supprimer la clÃ© personnelle';

  @override
  String get tmdbKeyHint =>
      'La clÃ© partagÃ©e embarquÃ©e est utilisÃ©e par dÃ©faut';

  @override
  String get tmdbKeyLabel => 'ClÃ© API TMDB personnelle (optionnel)';

  @override
  String get tmdbKeyShared =>
      'ClÃ© partagÃ©e embarquÃ©e utilisÃ©e (aucune clÃ© personnelle)';

  @override
  String get tvChannels => 'ChaÃ®nes TV';

  @override
  String get unableToBuildReplayUrl =>
      'Impossible de construire l\'URL du replay.';

  @override
  String get unlockCloudflare => 'DÃ©bloquer (Cloudflare)';

  @override
  String get unstableConnection => 'Connexion instable';

  @override
  String get updateAllData => 'Mettre Ã  jour toutes les donnÃ©es';

  @override
  String get aiTopicsTitle => 'Sujets recommandÃ©s par IA';

  @override
  String get updateThisCategory => 'Mettre Ã  jour cette catÃ©gorie';

  @override
  String get updating => 'Mise Ã  jour en coursâ€¦';

  @override
  String get updatingMediaContent =>
      'Mise Ã  jour du contenu multimÃ©dia en coursâ€¦';

  @override
  String get volumeNormalization => 'Normalisation du volume';

  @override
  String get volumeNormalizationSubtitle =>
      'Limite les pics de volume entre chaÃ®nes/programmes (AGC)';

  @override
  String get watchLive => 'Regarder en direct';

  @override
  String get whoIsWatching => 'Qui regarde ?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Vos chaÃ®nes & contenus';

  @override
  String get subtitleSection => 'Sous-titres';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'VidÃ©o';

  @override
  String get autoQuality => 'Automatique';

  @override
  String get noneOption => 'Aucun';

  @override
  String get subtitleNotApplicable => 'Non applicable';

  @override
  String get subtitleNotApplicableInfo =>
      'Un flux direct ne publie pas de piste de sous-titre.';

  @override
  String get subtitleUnavailable => 'Indisponible';

  @override
  String get subtitleNoTrack => 'Aucune piste';

  @override
  String get subtitleNoTrackInfo =>
      'Le panel ne publie de sous-titre pour ce contenu.';

  @override
  String get subtitleGuessed => 'Pistes dÃ©duites';

  @override
  String get subtitleGuessedInfo =>
      'Le panel ne dÃ©clare pas ses sous-titres : ces pistes sont obtenues par convention d\'URL. Celle qui n\'existe pas signale une erreur Ã  l\'activation.';

  @override
  String get subtitleUnavailableToast => 'Sous-titre indisponible';

  @override
  String get audioTrackFallback => 'Piste audio';

  @override
  String get subtitleLoading => 'Chargement des sous-titresâ€¦';

  @override
  String get videoQualityFallback => 'QualitÃ© vidÃ©o';

  @override
  String get close => 'Fermer';

  @override
  String get streamTracksError => 'Impossible de lire les pistes de ce flux.';

  @override
  String get subtitleProviderNoAnswer => 'Le panel n\'a pas rÃ©pondu.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Sous-titre indisponible : $reason';
  }

  @override
  String get epgNoDataTitle => 'Aucune donnÃ©e de programme';

  @override
  String get epgLiveNow => 'En Direct';

  @override
  String get epgSelectChannelHint =>
      'SÃ©lectionnez une chaÃ®ne pour voir son programme';

  @override
  String get epgNow => 'Maintenant';

  @override
  String get epgZoomIn => 'Zoomer';

  @override
  String get epgZoomOut => 'DÃ©zoomer';

  @override
  String get epgNoCurrentProgram => 'Aucun programme en cours';

  @override
  String replayWindowBadge(Object days) {
    return 'Replay $days j';
  }

  @override
  String replayWindowBadgeHours(Object hours) {
    return 'Replay $hours h';
  }

  @override
  String get replayNoAvailable => 'Aucun replay disponible';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'Aucun programme dÃ©jÃ  diffusÃ© dans les $days jours d\'archives de ce compte pour cette chaÃ®ne.';
  }

  @override
  String get replayNonePublished =>
      'Le panel ne publie aucun programme dÃ©jÃ  diffusÃ© pour cette chaÃ®ne.';

  @override
  String get epgActionFavorite => 'Favori';

  @override
  String get epgActionRecording => 'Enreg.';

  @override
  String get epgActionReminder => 'Rappel';

  @override
  String get epgStartReplay => 'Lancer le replay';

  @override
  String get epgBack => 'Retour';

  @override
  String epgWatchChannel(Object name) {
    return 'Regarder $name';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'Le panel ne sert aucun sous-titre pour ce contenu.';

  @override
  String subtitleVerifying(Object count) {
    return 'VÃ©rification des sous-titresâ€¦ ($count)';
  }

  @override
  String get subtitleSearchOnline => 'Rechercher en ligne';

  @override
  String get subtitleSearchOnlineInfo =>
      'Le panel ne propose rien pour ce contenu. Une recherche en ligne peut trouver un sous-titre.';

  @override
  String get subtitleSearchOnlineRunning => 'Recherche en coursâ€¦';

  @override
  String get subtitleOnlineResults => 'Sous-titres trouvÃ©s en ligne';

  @override
  String get subtitleOnlineEmpty =>
      'Aucun sous-titre trouvÃ© en ligne pour ce contenu.';

  @override
  String subtitleOnlineDownloads(Object count) {
    return '$count tÃ©lÃ©chargements';
  }

  @override
  String get subtitleOnlineNoTmdb =>
      'Impossible d\'identifier ce contenu sur TMDB : la recherche en ligne a besoin de son identifiant.';

  @override
  String get opensubtitlesKeyLabel =>
      'Recherche de sous-titres en ligne (OpenSubtitles)';

  @override
  String get opensubtitlesKeyHint => 'ClÃ© API â€” facultative';

  @override
  String get opensubtitlesKeyActive =>
      'ClÃ© enregistrÃ©e : quota de tÃ©lÃ©chargement relevÃ©.';

  @override
  String get opensubtitlesKeyAnonymous =>
      'Aucune clÃ© : recherche possible, 5 tÃ©lÃ©chargements par IP et par 24 h.';

  @override
  String get opensubtitlesKeyDelete => 'Effacer la clÃ©';

  @override
  String get opensubtitlesKeyCheck => 'VÃ©rifier la clÃ©';

  @override
  String get opensubtitlesKeyChecking => 'VÃ©rification en coursâ€¦';

  @override
  String get opensubtitlesKeyValid => 'ClÃ© valide : le service l\'accepte.';

  @override
  String get opensubtitlesKeyRejected =>
      'ClÃ© refusÃ©e par le service : vÃ©rifiez que vous l\'avez copiÃ©e en entier.';

  @override
  String get opensubtitlesKeyUnreachable =>
      'Service injoignable : vÃ©rifiez votre connexion et rÃ©essayez.';

  @override
  String get opensubtitlesLoginLabel => 'Connexion au compte OpenSubtitles';

  @override
  String get opensubtitlesLoginHintUsername => 'Identifiant';

  @override
  String get opensubtitlesLoginHintPassword => 'Mot de passe';

  @override
  String get opensubtitlesLoginActive =>
      'Compte enregistrÃ© : les tÃ©lÃ©chargements pourront se connecter.';

  @override
  String get opensubtitlesLoginNone =>
      'Aucun compte : le tÃ©lÃ©chargement reste refusÃ© (503).';

  @override
  String get opensubtitlesLoginDelete => 'Effacer le compte';

  @override
  String get opensubtitlesLoginConnect => 'Se connecter / vÃ©rifier';

  @override
  String get opensubtitlesLoginConnecting => 'Connexion en coursâ€¦';

  @override
  String get opensubtitlesLoginValid =>
      'Compte acceptÃ© : le service dÃ©livre un jeton.';

  @override
  String get opensubtitlesLoginRejected =>
      'Identifiants refusÃ©s : vÃ©rifiez l\'identifiant et le mot de passe.';

  @override
  String get opensubtitlesLoginUnreachable =>
      'Service injoignable : vÃ©rifiez votre connexion et rÃ©essayez.';

  @override
  String get subtitleOnlineNoApiKey =>
      'ClÃ© API OpenSubtitles absente : saisissez-la dans RÃ©glages pour activer la recherche en ligne.';

  @override
  String get subtitleOnlineKeyRejected =>
      'ClÃ© API OpenSubtitles refusÃ©e : elle est prÃ©sente mais le service la rejette. VÃ©rifiez sa validitÃ© dans RÃ©glages.';

  @override
  String get subtitleOnlineQuota =>
      'Quota de tÃ©lÃ©chargement OpenSubtitles atteint pour aujourd\'hui. RÃ©essayez demain.';

  @override
  String get subtitleOnlineNeedsLogin =>
      'Le tÃ©lÃ©chargement OpenSubtitles exige un compte connectÃ©, pas seulement la clÃ© API : la recherche fonctionne, mais le tÃ©lÃ©chargement est refusÃ©.';

  @override
  String get favorites => 'Favoris';

  @override
  String get films => 'Films';

  @override
  String get replay => 'Replay';

  @override
  String get myContent => 'Mes contenus';

  @override
  String get contentTypeSelector => 'Type de contenu';

  @override
  String get downloadStatusDownloading => 'TÃ©lÃ©chargement';

  @override
  String get downloadStatusPreparing => 'PrÃ©paration';

  @override
  String get downloadStatusPaused => 'En pause';

  @override
  String get downloadStatusCompleted => 'TerminÃ©';

  @override
  String get downloadStatusFailed => 'Ã‰chec';

  @override
  String get downloadStatusCancelled => 'AnnulÃ©';

  @override
  String get downloadStatusQueued => 'En file';

  @override
  String get history => 'Historique';

  @override
  String get explore => 'Explorer';

  @override
  String get downloadsEmptyHint =>
      'Ajoutez des contenus depuis les dÃ©tails d\'un film ou d\'une sÃ©rie.';

  @override
  String get downloadsLocation => 'Fichiers';

  @override
  String get advancedSettingsTitle => 'RÃ©glages avancÃ©s';

  @override
  String get advancedSettingsIntro =>
      'Identifiants d\'API et paramÃ¨tres rÃ©seau. Ces rÃ©glages engagent votre compte auprÃ¨s de services tiers : une clÃ© partagÃ©e consomme son quota, et une mauvaise manipulation du rÃ©seau peut empÃªcher l\'application de dÃ©marrer.';

  @override
  String get advancedSubtitlesProvider => 'Fournisseur de sous-titres';

  @override
  String get advancedStatus => 'Ã‰tat des identifiants';

  @override
  String get advancedAccessTitle => 'AccÃ¨s rÃ©servÃ©';

  @override
  String get advancedAccessHint => 'Code';

  @override
  String get advancedAccessConfirm => 'Ouvrir';

  @override
  String get advancedAccessWrong => 'Code incorrect';

  @override
  String get advancedHiddenHint =>
      'Maintenir appuyÃ© pour les rÃ©glages avancÃ©s';

  @override
  String get favoritesAndDownloads => 'Favoris et TÃ©lÃ©chargements';

  @override
  String get activeAudio => 'Son actif sur cet Ã©cran';

  @override
  String get addChannel => 'Ajouter une chaÃ®ne';

  @override
  String get noChannelSelected => 'Aucune chaÃ®ne sÃ©lectionnÃ©e';

  @override
  String get removeChannel => 'Retirer la chaÃ®ne';

  @override
  String get avatarCategoryAll => 'Toutes';

  @override
  String get avatarCategoryCharacters => 'Personnages';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Noir & Blanc';

  @override
  String get avatarCategoryPixels => 'Pixels';
}
