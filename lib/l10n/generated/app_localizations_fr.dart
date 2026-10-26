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
    return 'Profil $label ┬À diagnostic lecteur';
  }

  @override
  String get accountNoSubscription => 'Aucun abonnement actif';

  @override
  String get accountPreferences => 'Pr├®f├®rences profil';

  @override
  String get accountPreferencesSubtitle =>
      'Langue, th├¿me, restrictions d\'├óge, PIN';

  @override
  String get accountProfiles => 'Profils utilisateurs';

  @override
  String get accountProfilesSubtitle => 'G├®rer les profils et le profil actif';

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
    return '┬½ $title ┬╗ ajout├® aux favoris';
  }

  @override
  String get age => '├ége';

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
      'Appara├«tre dans les recherches et recommandations';

  @override
  String get apply => 'Appliquer';

  @override
  String get audioAndNightFocus => 'Audio & Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Optimisation nocturne, dialogue boost, synchronisation A/V';

  @override
  String get audioShift => 'D├®calage audio configurable';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'D├®calage audio/vid├®o manuel (ms)';

  @override
  String get autoQualityDescription =>
      'Laisse le lecteur choisir la meilleure qualit├®';

  @override
  String get autoReconnectLive => 'Auto-r├®connexion Live';

  @override
  String get autoReconnectLiveSubtitle =>
      'Tente de reconnecter automatiquement si le flux coupe';

  @override
  String get avSyncDialogHint =>
      'Positif = audio en avance, N├®gatif = audio en retard';

  @override
  String get avSyncDialogLabel => 'D├®calage (ms)';

  @override
  String get avSyncDialogTitle => 'Calibrage A/V';

  @override
  String get backupExport => 'Exporter la configuration';

  @override
  String get backupExportSubtitle =>
      'Copie la config compl├¿te dans le presse-papiers';

  @override
  String get backupImport => 'Importer la configuration';

  @override
  String get backupImportSubtitle => 'Restaure depuis le presse-papiers (JSON)';

  @override
  String get bassKiller => 'Bass Killer (coupe < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Att├®nue les basses fr├®quences pour ├®viter les vibrations';

  @override
  String get cancel => 'Annuler';

  @override
  String get castToChromecast => 'Diffuser sur Chromecast';

  @override
  String get catchUpTv => 'Rattrapage des cha├«nes';

  @override
  String get categories => 'Cat├®gories';

  @override
  String get certPinning => 'Activer Certificate Pinning';

  @override
  String get certPinningAdd => 'Ajouter les empreintes ci-dessus';

  @override
  String get certPinningHint =>
      'Empreintes autoris├®es (une par ligne, format hex uppercase) :';

  @override
  String get certPinningSubtitle =>
      'V├®rifie l\'empreinte SHA-256 du certificat SSL du serveur (anti-MITM)';

  @override
  String get changePinCode => 'Changer le code PIN';

  @override
  String get channelsUnavailable => 'Cha├«nes indisponibles';

  @override
  String get chooseProfile => 'Choisir un profil';

  @override
  String get clearCaches => 'Vider tous les caches';

  @override
  String get clearCachesSubtitle =>
      'Images, index recherche, m├®tadonn├®es TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'Synchronisation activ├®e';

  @override
  String cloudSyncLastSync(String time) {
    return 'Derni├¿re sync : $time';
  }

  @override
  String get cloudSyncNow => 'Synchroniser maintenant';

  @override
  String get cloudSyncNowSubtitle =>
      'Pousse les modifications locales vers le cloud';

  @override
  String get cloudSyncSubtitleOff =>
      'Synchronise favoris, vus et r├®cents vers le cloud';

  @override
  String get cloudflareReset => 'R├®initialiser config Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Efface cookies, remet TLS Impersonation=OFF, UA ExoPlayer par d├®faut';

  @override
  String get comingSoon => 'Bient├┤t disponible';

  @override
  String get confirmAndContinue => 'Valider et continuer';

  @override
  String get coverCacheCleared => 'Cache des pochettes purg├®.';

  @override
  String get createKidProfile => 'Cr├®er un profil Enfant';

  @override
  String get createNewProfile => 'Cr├®er un nouveau profil';

  @override
  String get createProfile => 'Cr├®er un profil';

  @override
  String currentProfileLabel(String name) {
    return 'Profil courant : $name';
  }

  @override
  String get dataAlreadyFresh => 'Donn├®es d├®j├á fra├«ches (moins de 30 min)';

  @override
  String get dataAndPrivacy => 'Donn├®es & confidentialit├®';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get deleteAllConfirm => 'Tout supprimer ?';

  @override
  String get deletePin => 'Supprimer le PIN';

  @override
  String get deleteProfileConfirm => 'Supprimer le profil ?';

  @override
  String get detailUnavailable => 'D├®tail indisponible';

  @override
  String get diagnosticUnavailable => 'Diagnostic indisponible';

  @override
  String get dialogueBoost => 'Boost Dialogues (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifie les voix par rapport aux effets/musique';

  @override
  String get disableSubtitles => 'D├®sactiver les sous-titres';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'Fournisseur DNS (DoH)';

  @override
  String get dnsProviderSubtitle =>
      'Serveur utilis├® pour les requ├¬tes DNS over HTTPS';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatique (Syst├¿me)';

  @override
  String downloadFailed(Object error) {
    return 'T├®l├®chargement impossible : $error';
  }

  @override
  String get downloads => 'T├®l├®chargements';

  @override
  String get dpadNavigation => 'Navigation D-pad renforc├®e';

  @override
  String get dpadNavigationSubtitle =>
      'Focus visible, halo lumineux, wrap texte (TV mode)';

  @override
  String get enableParentalControl => 'Activer le contr├┤le parental';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live : $live ┬À VOD : $vod';
  }

  @override
  String get enginesTile => 'Moteurs de lecture';

  @override
  String get enterNew4DigitPin => 'Saisir un nouveau code ├á 4 chiffres';

  @override
  String get epgGrille => 'EPG (grille)';

  @override
  String get epgGuideTv => 'Guide TV (EPG)';

  @override
  String get episode => '├ëpisode';

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
  String get firstName => 'Pr├®nom';

  @override
  String get fontSize => 'Taille du texte augment├®e';

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
  String get highContrast => 'Mode contraste ├®lev├®';

  @override
  String get highContrastSubtitle =>
      'Am├®liore la lisibilit├® pour les malvoyants';

  @override
  String get historyUnavailable => 'Historique indisponible';

  @override
  String get instantZapping => 'Zapping Instantan├® (Prefetching)';

  @override
  String get instantZappingSubtitle =>
      'Pr├®charge les cha├«nes adjacentes en m├®moire tampon';

  @override
  String get langArabic => 'Ïº┘äÏ╣Ï▒Ï¿┘èÏ®';

  @override
  String get langFrench => 'Fran├ºais';

  @override
  String get langPortuguese => 'Portugu├¬s';

  @override
  String get langSpanish => 'Espa├▒ol';

  @override
  String get language => 'Langue';

  @override
  String get languageExample => 'Français, English, etc.';

  @override
  String get noneOption => 'Aucun';

  @override
  String get play => 'Lire';

  @override
  String get newAnd4K => 'Films à la demande';

  @override
  String get seasonsAndEpisodes => 'Séries à la demande';

  @override
  String get languagePreference => 'Langue de l\'application';

  @override
  String get languageUndetermined => 'Ind├®termin├®';

  @override
  String get later => 'Plus tard';

  @override
  String get legalNotice => 'Lisez-moi ┬À Mentions l├®gales';

  @override
  String get legalNoticeSubtitle =>
      'Usage de l\'application, ayants droit et confidentialit├®';

  @override
  String get liveChannelsAndZapping => 'Cha├«nes en direct & Zapping';

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
    return 'D├®calage actuel: $ms ms';
  }

  @override
  String get matchmaking => 'Pour vous (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'G├®rer l\'appariement et les suggestions personnalis├®es';

  @override
  String maxProfilesReached(Object max) {
    return 'Nombre maximal de profils atteint ($max)';
  }

  @override
  String get memory => 'M├®moire';

  @override
  String get moreResults => 'Voir plus de r├®sultats';

  @override
  String get moviesUnavailable => 'Films indisponibles';

  @override
  String get multiScreen => 'Multi-├®crans';

  @override
  String get multiVideo => 'Multi-vid├®o';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get nameOptional => 'Nom (optionnel)';

  @override
  String get nameOrNickname => 'Nom / Pseudo';

  @override
  String get navigateToOkToSelect => 'Naviguer ├á OK pour s├®lectionner';

  @override
  String get networkDisconnected => 'R├®seau coup├®';

  @override
  String get never => 'jamais';

  @override
  String get newProfile => 'Nouveau profil';

  @override
  String get nextChannel => 'Cha├«ne suivante';

  @override
  String get nightFocusEnable => 'Activer Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Traitement audio temps r├®el : boost dialogues, coupe basses, sync';

  @override
  String get nightFocusTitle => 'Night Focus (Mode Nuit)';

  @override
  String get noAudioTrackDetected => 'Aucune piste audio d├®tect├®e';

  @override
  String get noChannelsAvailable => 'Aucune cha├«ne disponible';

  @override
  String get noChromecastDeviceFound => 'Aucun appareil Chromecast trouv├®.';

  @override
  String get noDownloads => 'Aucun t├®l├®chargement';

  @override
  String get noEpisodes => 'Aucun ├®pisode';

  @override
  String get noFavoriteChannels => 'Aucune cha├«ne favorite';

  @override
  String get noFavoriteMovies => 'Aucun film favori';

  @override
  String get noFavoriteReplays => 'Aucun replay favori';

  @override
  String get noFavoriteSeries => 'Aucune s├®rie favorite';

  @override
  String get noGroupAffinity => 'Aucune affinit├® commune trouv├®e';

  @override
  String get noHistory => 'Aucun historique';

  @override
  String get noKidsChannels => 'Aucune cha├«ne pour enfants';

  @override
  String get noKidsMovies => 'Aucun film pour enfants';

  @override
  String get noKidsReplays => 'Aucun replay pour enfants';

  @override
  String get noKidsSeries => 'Aucune s├®rie pour enfants';

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
  String get noReplaysInCategory => 'Aucun replay dans cette cat├®gorie';

  @override
  String noResultsFor(Object query) {
    return 'Aucun r├®sultat pour $query';
  }

  @override
  String get noSeriesAvailable => 'Aucune s├®rie disponible';

  @override
  String get noStationsAvailable => 'Aucune station disponible';

  @override
  String get noVideoQualityDetected => 'Aucune qualit├® vid├®o d├®tect├®e';

  @override
  String get notAvailableInCatalog => 'Non disponible dans le catalogue';

  @override
  String get offline => 'Hors ligne';

  @override
  String get parentalControl => 'Contr├┤le parental';

  @override
  String get parentalControlSubtitle =>
      'Ajouter un code PIN et restreindre le contenu';

  @override
  String get pauseDownload => 'Mettre en pause';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get pinDeleted => 'PIN supprim├®';

  @override
  String get pinMustBe4Digits => 'Le PIN doit contenir exactement 4 chiffres';

  @override
  String get pinSaved => 'PIN enregistr├®';

  @override
  String get pip => 'Vue flottante (PiP)';

  @override
  String get pipUnavailable =>
      'Vue flottante (PiP) non disponible sur cet appareil';

  @override
  String get playHistoryCleared => 'Historique de lecture effac├®.';

  @override
  String plusAgeYears(Object age) {
    return '+$age ans';
  }

  @override
  String get preferences => 'Pr├®f├®rences';

  @override
  String get previousChannel => 'Cha├«ne pr├®c├®dente';

  @override
  String get primaryEngine => 'Moteur Principal';

  @override
  String profilesSelected(int count) {
    return '$count profils s├®lectionn├®s';
  }

  @override
  String get profileVisible => 'Profil visible';

  @override
  String get programGrid => 'Grille des programmes';

  @override
  String get protectWithPin => 'Prot├®ger par code PIN';

  @override
  String get rankingsUnavailable => 'Classement indisponible';

  @override
  String get recentSearch => 'Recherche r├®cente';

  @override
  String get recentSearches => 'R├®cents';

  @override
  String get recentlyWatched => 'R├®cemment';

  @override
  String get removeAll => 'Tout retirer';

  @override
  String get removeFromWatchedConfirm => 'Tout retirer des d├®j├á vus ?';

  @override
  String get replaysUnavailable => 'Replays indisponibles';

  @override
  String get reset => 'R├®initialiser';

  @override
  String get resetApp => 'R├®initialiser l\'application';

  @override
  String get resetAppDialogBody =>
      'Toutes les donn├®es seront effac├®es : profils, favoris, historique, r├®glages. Cette action est irr├®versible.';

  @override
  String get resetAppDialogConfirm => 'Tout effacer';

  @override
  String get resetAppDialogTitle => 'R├®initialiser l\'application ?';

  @override
  String get resetAppSubtitle =>
      'Efface toutes les donn├®es utilisateur (profils, favoris, historique)';

  @override
  String get resetCompleted => 'R├®initialisation effectu├®e';

  @override
  String get resumePlayback => 'Reprendre la lecture ?';

  @override
  String get retry => 'R├®essayer';

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
  String get searchChannel => 'Rechercher une cha├«ne';

  @override
  String get searchError => 'Erreur de recherche';

  @override
  String get searchMovie => 'Rechercher un film';

  @override
  String get searchSeries => 'Rechercher une s├®rie';

  @override
  String seasonNumber(Object season) {
    return 'Saison $season';
  }

  @override
  String get sectionAccessibility => 'Accessibilit├®';

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
  String get sectionLegal => 'Informations l├®gales';

  @override
  String get sectionMemory => 'M├®moire & Cache';

  @override
  String get sectionOutput => 'Sortie Audio';

  @override
  String get sectionParental => 'Contr├┤le parental';

  @override
  String get sectionRecommendations => 'Recommandations';

  @override
  String get sectionResilience => 'R├®silience du Service';

  @override
  String get sectionTmdb => 'Classements TMDB';

  @override
  String get sectionZapping => 'Zapping & Performance';

  @override
  String get select => 'S├®lectionner';

  @override
  String selectAtLeastOneProfile(int count) {
    return 'S├®lectionnez au moins 1 profil suppl├®mentaire ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'S├®lectionnez un profil pour voir ses recommandations';

  @override
  String get series => 'S├®ries';

  @override
  String get seriesNotFound => 'S├®rie introuvable';

  @override
  String get seriesUnavailable => 'S├®ries indisponibles';

  @override
  String get seriesUnavailableTemporarily =>
      'S├®rie indisponible pour le moment.';

  @override
  String get serverProtectedAntiLeech => 'Serveur prot├®g├® (anti-leech)';

  @override
  String get serverUrlPlaceholder =>
      'URL du serveur (ex: https://provider.com)';

  @override
  String get serviceNature => 'Nature du service';

  @override
  String get setAsDefaultServer => 'D├®finir comme serveur par d├®faut';

  @override
  String get settings => 'R├®glages';

  @override
  String get settingsTitle => 'Configuration';

  @override
  String get similarMovies => 'Films similaires';

  @override
  String get snackBackupExported =>
      'Configuration export├®e dans le presse-papiers';

  @override
  String get snackCacheCleared => 'Caches vid├®s';

  @override
  String get snackCloudflareReset => 'Config Cloudflare r├®initialis├®e';

  @override
  String snackImportError(String message) {
    return 'Erreur: $message';
  }

  @override
  String get snackImportSuccess => 'Configuration import├®e avec succ├¿s';

  @override
  String get snackNoBackup => 'Aucune sauvegarde trouv├®e';

  @override
  String get sortAffinity => 'Par affinit├®';

  @override
  String get sortAffinityDescription =>
      'Classe selon vos go├╗ts d├®clar├®s dans le profil (matchmaking)';

  @override
  String get sortAscending => 'Tri croissant';

  @override
  String get sortByDuration => 'Par dur├®e';

  @override
  String get sortByRating => 'Par note';

  @override
  String get sortByYear => 'Par ann├®e';

  @override
  String get sortDescending => 'Tri d├®croissant';

  @override
  String get sortLatestM3UXtream => 'Derniers Ajouts M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nom (A ÔåÆ Z)';

  @override
  String get sortNameZToA => 'Nom (Z ÔåÆ A)';

  @override
  String get sortResumePriority => '├Ç reprendre en priorit├®';

  @override
  String specialGuestsSeason(Object season) {
    return 'Invit├®s sp├®ciaux - Saison $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'D├®marrer';

  @override
  String get stationsUnavailable => 'Stations indisponibles';

  @override
  String get stopCasting => 'Arr├¬ter la diffusion';

  @override
  String get streamDetails => 'D├®tails du flux';

  @override
  String subtitleLoadError(Object error) {
    return 'Erreur chargement sous-titre: $error';
  }

  @override
  String get subtitlesUnavailable => 'Sous-titres : non disponibles';

  @override
  String get system => 'Syst├¿me';

  @override
  String get tabAccount => 'Compte';

  @override
  String get tabAdvanced => 'Avanc├®';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabNetwork => 'R├®seau';

  @override
  String get tabPlayer => 'Lecteur';

  @override
  String get tabSecurity => 'S├®curit├®';

  @override
  String get theme => 'Th├¿me';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy Local)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simule l\'empreinte d\'un navigateur moderne pour contourner Cloudflare';

  @override
  String get tmdbKeyActive =>
      'Cl├® personnelle active ÔÇö la cl├® partag├®e est ignor├®e';

  @override
  String get tmdbKeyColumn => 'Cl├®s TMDB';

  @override
  String get tmdbKeyDelete => 'Supprimer la cl├® personnelle';

  @override
  String get tmdbKeyHint =>
      'La cl├® partag├®e embarqu├®e est utilis├®e par d├®faut';

  @override
  String get tmdbKeyLabel => 'Cl├® API TMDB personnelle (optionnel)';

  @override
  String get tmdbKeyShared =>
      'Cl├® partag├®e embarqu├®e utilis├®e (aucune cl├® personnelle)';

  @override
  String get tvChannels => 'Cha├«nes TV';

  @override
  String get unableToBuildReplayUrl =>
      'Impossible de construire l\'URL du replay.';

  @override
  String get unlockCloudflare => 'D├®bloquer (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'Vérification du fournisseur requise';

  @override
  String get cloudflareChallengeHelp =>
      'Le fournisseur demande une vérification Cloudflare. Ouvrez son site dans votre navigateur, effectuez vous-même la vérification si elle est proposée, puis revenez ici et réessayez. La session du navigateur peut ne pas être partagée avec l\'application.';

  @override
  String get openProviderWebsite => 'Ouvrir le site du fournisseur';

  @override
  String get providerWebsiteUnavailable =>
      'Impossible d\'ouvrir le site du fournisseur. Vérifiez l\'adresse de l\'abonnement et réessayez.';

  @override
  String get unstableConnection => 'Connexion instable';

  @override
  String get updateAllData => 'Mettre ├á jour toutes les donn├®es';

  @override
  String get aiTopicsTitle => 'Sujets recommand├®s par IA';

  @override
  String get updateThisCategory => 'Mettre ├á jour cette cat├®gorie';

  @override
  String get updating => 'Mise ├á jour en coursÔÇª';

  @override
  String get updatingMediaContent =>
      'Mise ├á jour du contenu multim├®dia en coursÔÇª';

  @override
  String get volumeNormalization => 'Normalisation du volume';

  @override
  String get volumeNormalizationSubtitle =>
      'Limite les pics de volume entre cha├«nes/programmes (AGC)';

  @override
  String get watchLive => 'Regarder en direct';

  @override
  String get whoIsWatching => 'Qui regarde ?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Vos cha├«nes & contenus';

  @override
  String get subtitleSection => 'Sous-titres';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'Vid├®o';

  @override
  String get autoQuality => 'Automatique';

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
  String get subtitleGuessed => 'Pistes d├®duites';

  @override
  String get subtitleGuessedInfo =>
      'Le panel ne d├®clare pas ses sous-titres : ces pistes sont obtenues par convention d\'URL. Celle qui n\'existe pas signale une erreur ├á l\'activation.';

  @override
  String get subtitleUnavailableToast => 'Sous-titre indisponible';

  @override
  String get audioTrackFallback => 'Piste audio';

  @override
  String get subtitleLoading => 'Chargement des sous-titresÔÇª';

  @override
  String get videoQualityFallback => 'Qualit├® vid├®o';

  @override
  String get close => 'Fermer';

  @override
  String get streamTracksError => 'Impossible de lire les pistes de ce flux.';

  @override
  String get subtitleProviderNoAnswer => 'Le panel n\'a pas r├®pondu.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Sous-titre indisponible : $reason';
  }

  @override
  String get epgNoDataTitle => 'Aucune donn├®e de programme';

  @override
  String get epgLiveNow => 'En Direct';

  @override
  String get epgSelectChannelHint =>
      'S├®lectionnez une cha├«ne pour voir son programme';

  @override
  String get epgNow => 'Maintenant';

  @override
  String get epgZoomIn => 'Zoomer';

  @override
  String get epgZoomOut => 'D├®zoomer';

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
    return 'Aucun programme d├®j├á diffus├® dans les $days jours d\'archives de ce compte pour cette cha├«ne.';
  }

  @override
  String get replayNonePublished =>
      'Le panel ne publie aucun programme d├®j├á diffus├® pour cette cha├«ne.';

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
    return 'V├®rification des sous-titresÔÇª ($count)';
  }

  @override
  String get subtitleSearchOnline => 'Rechercher en ligne';

  @override
  String get subtitleSearchOnlineInfo =>
      'Le panel ne propose rien pour ce contenu. Une recherche en ligne peut trouver un sous-titre.';

  @override
  String get subtitleSearchOnlineRunning => 'Recherche en coursÔÇª';

  @override
  String get subtitleOnlineResults => 'Sous-titres trouv├®s en ligne';

  @override
  String get subtitleOnlineEmpty =>
      'Aucun sous-titre trouv├® en ligne pour ce contenu.';

  @override
  String subtitleOnlineDownloads(Object count) {
    return '$count t├®l├®chargements';
  }

  @override
  String get subtitleOnlineNoTmdb =>
      'Impossible d\'identifier ce contenu sur TMDB : la recherche en ligne a besoin de son identifiant.';

  @override
  String get opensubtitlesKeyLabel =>
      'Recherche de sous-titres en ligne (OpenSubtitles)';

  @override
  String get opensubtitlesKeyHint => 'Cl├® API ÔÇö facultative';

  @override
  String get opensubtitlesKeyActive =>
      'Cl├® enregistr├®e : quota de t├®l├®chargement relev├®.';

  @override
  String get opensubtitlesKeyAnonymous =>
      'Aucune cl├® : recherche possible, 5 t├®l├®chargements par IP et par 24 h.';

  @override
  String get opensubtitlesKeyDelete => 'Effacer la cl├®';

  @override
  String get opensubtitlesKeyCheck => 'V├®rifier la cl├®';

  @override
  String get opensubtitlesKeyChecking => 'V├®rification en coursÔÇª';

  @override
  String get opensubtitlesKeyValid => 'Cl├® valide : le service l\'accepte.';

  @override
  String get opensubtitlesKeyRejected =>
      'Cl├® refus├®e par le service : v├®rifiez que vous l\'avez copi├®e en entier.';

  @override
  String get opensubtitlesKeyUnreachable =>
      'Service injoignable : v├®rifiez votre connexion et r├®essayez.';

  @override
  String get opensubtitlesLoginLabel => 'Connexion au compte OpenSubtitles';

  @override
  String get opensubtitlesLoginHintUsername => 'Identifiant';

  @override
  String get opensubtitlesLoginHintPassword => 'Mot de passe';

  @override
  String get opensubtitlesLoginActive =>
      'Compte enregistr├® : les t├®l├®chargements pourront se connecter.';

  @override
  String get opensubtitlesLoginNone =>
      'Aucun compte : le t├®l├®chargement reste refus├® (503).';

  @override
  String get opensubtitlesLoginDelete => 'Effacer le compte';

  @override
  String get opensubtitlesLoginConnect => 'Se connecter / v├®rifier';

  @override
  String get opensubtitlesLoginConnecting => 'Connexion en coursÔÇª';

  @override
  String get opensubtitlesLoginValid =>
      'Compte accept├® : le service d├®livre un jeton.';

  @override
  String get opensubtitlesLoginRejected =>
      'Identifiants refus├®s : v├®rifiez l\'identifiant et le mot de passe.';

  @override
  String get opensubtitlesLoginUnreachable =>
      'Service injoignable : v├®rifiez votre connexion et r├®essayez.';

  @override
  String get subtitleOnlineNoApiKey =>
      'Cl├® API OpenSubtitles absente : saisissez-la dans R├®glages pour activer la recherche en ligne.';

  @override
  String get subtitleOnlineKeyRejected =>
      'Cl├® API OpenSubtitles refus├®e : elle est pr├®sente mais le service la rejette. V├®rifiez sa validit├® dans R├®glages.';

  @override
  String get subtitleOnlineQuota =>
      'Quota de t├®l├®chargement OpenSubtitles atteint pour aujourd\'hui. R├®essayez demain.';

  @override
  String get subtitleOnlineNeedsLogin =>
      'Le t├®l├®chargement OpenSubtitles exige un compte connect├®, pas seulement la cl├® API : la recherche fonctionne, mais le t├®l├®chargement est refus├®.';

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
  String get downloadStatusDownloading => 'T├®l├®chargement';

  @override
  String get downloadStatusPreparing => 'Pr├®paration';

  @override
  String get downloadStatusPaused => 'En pause';

  @override
  String get downloadStatusCompleted => 'Termin├®';

  @override
  String get downloadStatusFailed => '├ëchec';

  @override
  String get downloadStatusCancelled => 'Annul├®';

  @override
  String get downloadStatusQueued => 'En file';

  @override
  String get history => 'Historique';

  @override
  String get explore => 'Explorer';

  @override
  String get downloadsEmptyHint =>
      'Ajoutez des contenus depuis les d├®tails d\'un film ou d\'une s├®rie.';

  @override
  String get downloadsLocation => 'Fichiers';

  @override
  String get advancedSettingsTitle => 'R├®glages avanc├®s';

  @override
  String get advancedSettingsIntro =>
      'Identifiants d\'API et param├¿tres r├®seau. Ces r├®glages engagent votre compte aupr├¿s de services tiers : une cl├® partag├®e consomme son quota, et une mauvaise manipulation du r├®seau peut emp├¬cher l\'application de d├®marrer.';

  @override
  String get advancedSubtitlesProvider => 'Fournisseur de sous-titres';

  @override
  String get advancedStatus => '├ëtat des identifiants';

  @override
  String get advancedAccessTitle => 'Acc├¿s r├®serv├®';

  @override
  String get advancedAccessHint => 'Code';

  @override
  String get advancedAccessConfirm => 'Ouvrir';

  @override
  String get advancedAccessWrong => 'Code incorrect';

  @override
  String get advancedHiddenHint =>
      'Maintenir appuy├® pour les r├®glages avanc├®s';

  @override
  String get favoritesAndDownloads => 'Favoris et T├®l├®chargements';

  @override
  String get activeAudio => 'Son actif sur cet ├®cran';

  @override
  String get addChannel => 'Ajouter une cha├«ne';

  @override
  String get noChannelSelected => 'Aucune cha├«ne s├®lectionn├®e';

  @override
  String get removeChannel => 'Retirer la cha├«ne';

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
