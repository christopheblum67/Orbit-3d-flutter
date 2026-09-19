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
    return 'Profil $label · diagnostic lecteur';
  }

  @override
  String get accountNoSubscription => 'Aucun abonnement actif';

  @override
  String get accountPreferences => 'Préférences profil';

  @override
  String get accountPreferencesSubtitle =>
      'Langue, thème, restrictions d\'âge, PIN';

  @override
  String get accountProfiles => 'Profils utilisateurs';

  @override
  String get accountProfilesSubtitle => 'Gérer les profils et le profil actif';

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
    return '« $title » ajouté aux favoris';
  }

  @override
  String get age => 'Âge';

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
      'Apparaître dans les recherches et recommandations';

  @override
  String get apply => 'Appliquer';

  @override
  String get audioAndNightFocus => 'Audio & Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Optimisation nocturne, dialogue boost, synchronisation A/V';

  @override
  String get audioShift => 'Décalage audio configurable';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'Décalage audio/vidéo manuel (ms)';

  @override
  String get autoQualityDescription =>
      'Laisse le lecteur choisir la meilleure qualité';

  @override
  String get autoReconnectLive => 'Auto-réconnexion Live';

  @override
  String get autoReconnectLiveSubtitle =>
      'Tente de reconnecter automatiquement si le flux coupe';

  @override
  String get avSyncDialogHint =>
      'Positif = audio en avance, Négatif = audio en retard';

  @override
  String get avSyncDialogLabel => 'Décalage (ms)';

  @override
  String get avSyncDialogTitle => 'Calibrage A/V';

  @override
  String get backupExport => 'Exporter la configuration';

  @override
  String get backupExportSubtitle =>
      'Copie la config complète dans le presse-papiers';

  @override
  String get backupImport => 'Importer la configuration';

  @override
  String get backupImportSubtitle => 'Restaure depuis le presse-papiers (JSON)';

  @override
  String get bassKiller => 'Bass Killer (coupe < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Atténue les basses fréquences pour éviter les vibrations';

  @override
  String get cancel => 'Annuler';

  @override
  String get castToChromecast => 'Diffuser sur Chromecast';

  @override
  String get catchUpTv => 'Rattrapage des chaînes';

  @override
  String get categories => 'Catégories';

  @override
  String get certPinning => 'Activer Certificate Pinning';

  @override
  String get certPinningAdd => 'Ajouter les empreintes ci-dessus';

  @override
  String get certPinningHint =>
      'Empreintes autorisées (une par ligne, format hex uppercase) :';

  @override
  String get certPinningSubtitle =>
      'Vérifie l\'empreinte SHA-256 du certificat SSL du serveur (anti-MITM)';

  @override
  String get changePinCode => 'Changer le code PIN';

  @override
  String get channelsUnavailable => 'Chaînes indisponibles';

  @override
  String get chooseProfile => 'Choisir un profil';

  @override
  String get clearCaches => 'Vider tous les caches';

  @override
  String get clearCachesSubtitle =>
      'Images, index recherche, métadonnées TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'Synchronisation activée';

  @override
  String cloudSyncLastSync(String time) {
    return 'Dernière sync : $time';
  }

  @override
  String get cloudSyncNow => 'Synchroniser maintenant';

  @override
  String get cloudSyncNowSubtitle =>
      'Pousse les modifications locales vers le cloud';

  @override
  String get cloudSyncSubtitleOff =>
      'Synchronise favoris, vus et récents vers le cloud';

  @override
  String get cloudflareReset => 'Réinitialiser config Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Efface cookies, remet TLS Impersonation=OFF, UA ExoPlayer par défaut';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get confirmAndContinue => 'Valider et continuer';

  @override
  String get coverCacheCleared => 'Cache des pochettes purgé.';

  @override
  String get createKidProfile => 'Créer un profil Enfant';

  @override
  String get createNewProfile => 'Créer un nouveau profil';

  @override
  String get createProfile => 'Créer un profil';

  @override
  String get dataAlreadyFresh => 'Données déjà fraîches (moins de 30 min)';

  @override
  String get dataAndPrivacy => 'Données & confidentialité';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get deleteAllConfirm => 'Tout supprimer ?';

  @override
  String get deletePin => 'Supprimer le PIN';

  @override
  String get deleteProfileConfirm => 'Supprimer le profil ?';

  @override
  String get detailUnavailable => 'Détail indisponible';

  @override
  String get diagnosticUnavailable => 'Diagnostic indisponible';

  @override
  String get dialogueBoost => 'Boost Dialogues (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifie les voix par rapport aux effets/musique';

  @override
  String get disableSubtitles => 'Désactiver les sous-titres';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'Fournisseur DNS (DoH)';

  @override
  String get dnsProviderSubtitle =>
      'Serveur utilisé pour les requêtes DNS over HTTPS';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatique (Système)';

  @override
  String downloadFailed(Object error) {
    return 'Téléchargement impossible : $error';
  }

  @override
  String get downloads => 'Téléchargements';

  @override
  String get dpadNavigation => 'Navigation D-pad renforcée';

  @override
  String get dpadNavigationSubtitle =>
      'Focus visible, halo lumineux, wrap texte (TV mode)';

  @override
  String get enableParentalControl => 'Activer le contrôle parental';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live : $live · VOD : $vod';
  }

  @override
  String get enginesTile => 'Moteurs de lecture';

  @override
  String get enterNew4DigitPin => 'Saisir un nouveau code à 4 chiffres';

  @override
  String get epgGrille => 'EPG (grille)';

  @override
  String get epgGuideTv => 'Guide TV (EPG)';

  @override
  String get episode => 'Épisode';

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
  String get firstName => 'Prénom';

  @override
  String get fontSize => 'Taille du texte augmentée';

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
  String get highContrast => 'Mode contraste élevé';

  @override
  String get highContrastSubtitle =>
      'Améliore la lisibilité pour les malvoyants';

  @override
  String get historyUnavailable => 'Historique indisponible';

  @override
  String get instantZapping => 'Zapping Instantané (Prefetching)';

  @override
  String get instantZappingSubtitle =>
      'Précharge les chaînes adjacentes en mémoire tampon';

  @override
  String get kidsContent => 'Contenus adaptés aux enfants';

  @override
  String get kidsMode => 'Mode Enfants';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langSpanish => 'Español';

  @override
  String get language => 'Langue';

  @override
  String get languageExample => 'Français, English, etc.';

  @override
  String get languagePreference => 'Langue de l\'application';

  @override
  String get languageUndetermined => 'Indéterminé';

  @override
  String get later => 'Plus tard';

  @override
  String get legalNotice => 'Lisez-moi · Mentions légales';

  @override
  String get legalNoticeSubtitle =>
      'Usage de l\'application, ayants droit et confidentialité';

  @override
  String get liveChannelsAndZapping => 'Chaînes en direct & Zapping';

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
    return 'Décalage actuel: $ms ms';
  }

  @override
  String get matchmaking => 'Pour vous (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Gérer l\'appariement et les suggestions personnalisées';

  @override
  String maxProfilesReached(Object max) {
    return 'Nombre maximal de profils atteint ($max)';
  }

  @override
  String get memory => 'Mémoire';

  @override
  String get moviesUnavailable => 'Films indisponibles';

  @override
  String get multiScreen => 'Multi-écrans';

  @override
  String get multiVideo => 'Multi-vidéo';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get nameOptional => 'Nom (optionnel)';

  @override
  String get nameOrNickname => 'Nom / Pseudo';

  @override
  String get navigateToOkToSelect => 'Naviguer à OK pour sélectionner';

  @override
  String get networkDisconnected => 'Réseau coupé';

  @override
  String get never => 'jamais';

  @override
  String get newAnd4K => 'Nouveautés & 4K';

  @override
  String get newProfile => 'Nouveau profil';

  @override
  String get nextChannel => 'Chaîne suivante';

  @override
  String get nightFocusEnable => 'Activer Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Traitement audio temps réel : boost dialogues, coupe basses, sync';

  @override
  String get nightFocusTitle => 'Night Focus (Mode Nuit)';

  @override
  String get noAudioTrackDetected => 'Aucune piste audio détectée';

  @override
  String get noChannelsAvailable => 'Aucune chaîne disponible';

  @override
  String get noChromecastDeviceFound => 'Aucun appareil Chromecast trouvé.';

  @override
  String get noDownloads => 'Aucun téléchargement';

  @override
  String get noEpisodes => 'Aucun épisode';

  @override
  String get noFavoriteChannels => 'Aucune chaîne favorite';

  @override
  String get noFavoriteMovies => 'Aucun film favori';

  @override
  String get noFavoriteReplays => 'Aucun replay favori';

  @override
  String get noFavoriteSeries => 'Aucune série favorite';

  @override
  String get noHistory => 'Aucun historique';

  @override
  String get noKidsChannels => 'Aucune chaîne pour enfants';

  @override
  String get noKidsMovies => 'Aucun film pour enfants';

  @override
  String get noKidsReplays => 'Aucun replay pour enfants';

  @override
  String get noKidsSeries => 'Aucune série pour enfants';

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
  String get noReplaysInCategory => 'Aucun replay dans cette catégorie';

  @override
  String noResultsFor(Object query) {
    return 'Aucun résultat pour $query';
  }

  @override
  String get noSeriesAvailable => 'Aucune série disponible';

  @override
  String get noStationsAvailable => 'Aucune station disponible';

  @override
  String get noVideoQualityDetected => 'Aucune qualité vidéo détectée';

  @override
  String get notAvailableInCatalog => 'Non disponible dans le catalogue';

  @override
  String get offline => 'Hors ligne';

  @override
  String get parentalControl => 'Contrôle parental';

  @override
  String get parentalControlSubtitle =>
      'Ajouter un code PIN et restreindre le contenu';

  @override
  String get pauseDownload => 'Mettre en pause';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get pinDeleted => 'PIN supprimé';

  @override
  String get pinMustBe4Digits => 'Le PIN doit contenir exactement 4 chiffres';

  @override
  String get pinSaved => 'PIN enregistré';

  @override
  String get pip => 'Vue flottante (PiP)';

  @override
  String get pipUnavailable =>
      'Vue flottante (PiP) non disponible sur cet appareil';

  @override
  String get playHistoryCleared => 'Historique de lecture effacé.';

  @override
  String plusAgeYears(Object age) {
    return '+$age ans';
  }

  @override
  String get preferences => 'Préférences';

  @override
  String get previousChannel => 'Chaîne précédente';

  @override
  String get primaryEngine => 'Moteur Principal';

  @override
  String get profileVisible => 'Profil visible';

  @override
  String get programGrid => 'Grille des programmes';

  @override
  String get protectWithPin => 'Protéger par code PIN';

  @override
  String get rankingsUnavailable => 'Classement indisponible';

  @override
  String get receiveAlertsAndTips => 'Recevoir les alertes et conseils';

  @override
  String get recentSearch => 'Recherche récente';

  @override
  String get recentSearches => 'Récents';

  @override
  String get recentlyWatched => 'Récemment';

  @override
  String get removeAll => 'Tout retirer';

  @override
  String get removeFromWatchedConfirm => 'Tout retirer des déjà vus ?';

  @override
  String get replaysUnavailable => 'Replays indisponibles';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resetApp => 'Réinitialiser l\'application';

  @override
  String get resetAppDialogBody =>
      'Toutes les données seront effacées : profils, favoris, historique, réglages. Cette action est irréversible.';

  @override
  String get resetAppDialogConfirm => 'Tout effacer';

  @override
  String get resetAppDialogTitle => 'Réinitialiser l\'application ?';

  @override
  String get resetAppSubtitle =>
      'Efface toutes les données utilisateur (profils, favoris, historique)';

  @override
  String get resetCompleted => 'Réinitialisation effectuée';

  @override
  String get resumePlayback => 'Reprendre la lecture ?';

  @override
  String get retry => 'Réessayer';

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
  String get searchChannel => 'Rechercher une chaîne';

  @override
  String get searchError => 'Erreur de recherche';

  @override
  String get searchMovie => 'Rechercher un film';

  @override
  String get searchSeries => 'Rechercher une série';

  @override
  String seasonNumber(Object season) {
    return 'Saison $season';
  }

  @override
  String get seasonsAndEpisodes => 'Saisons & Épisodes';

  @override
  String get sectionAccessibility => 'Accessibilité';

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
  String get sectionLegal => 'Informations légales';

  @override
  String get sectionMemory => 'Mémoire & Cache';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get sectionOutput => 'Sortie Audio';

  @override
  String get sectionParental => 'Contrôle parental';

  @override
  String get sectionRecommendations => 'Recommandations';

  @override
  String get sectionResilience => 'Résilience du Service';

  @override
  String get sectionTmdb => 'Classements TMDB';

  @override
  String get sectionZapping => 'Zapping & Performance';

  @override
  String get select => 'Sélectionner';

  @override
  String get selectProfileForRecommendations =>
      'Sélectionnez un profil pour voir ses recommandations';

  @override
  String get series => 'Séries';

  @override
  String get seriesNotFound => 'Série introuvable';

  @override
  String get seriesUnavailable => 'Séries indisponibles';

  @override
  String get seriesUnavailableTemporarily =>
      'Série indisponible pour le moment.';

  @override
  String get serverProtectedAntiLeech => 'Serveur protégé (anti-leech)';

  @override
  String get serverUrlPlaceholder =>
      'URL du serveur (ex: https://provider.com)';

  @override
  String get serviceNature => 'Nature du service';

  @override
  String get setAsDefaultServer => 'Définir comme serveur par défaut';

  @override
  String get settings => 'Réglages';

  @override
  String get settingsTitle => 'Configuration';

  @override
  String get similarMovies => 'Films similaires';

  @override
  String get snackBackupExported =>
      'Configuration exportée dans le presse-papiers';

  @override
  String get snackCacheCleared => 'Caches vidés';

  @override
  String get snackCloudflareReset => 'Config Cloudflare réinitialisée';

  @override
  String snackImportError(String message) {
    return 'Erreur: $message';
  }

  @override
  String get snackImportSuccess => 'Configuration importée avec succès';

  @override
  String get snackNoBackup => 'Aucune sauvegarde trouvée';

  @override
  String get sortBestRated => 'Les Mieux Notés (XCIPTV)';

  @override
  String get sortLatestM3UXtream => 'Derniers Ajouts M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nom (A → Z)';

  @override
  String get sortNameZToA => 'Nom (Z → A)';

  @override
  String get sortResumePriority => 'À reprendre en priorité';

  @override
  String get sortYearRecentToOld => 'Année de Sortie (Récent → Ancien)';

  @override
  String specialGuestsSeason(Object season) {
    return 'Invités spéciaux - Saison $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'Démarrer';

  @override
  String get stationsUnavailable => 'Stations indisponibles';

  @override
  String get stopCasting => 'Arrêter la diffusion';

  @override
  String get streamDetails => 'Détails du flux';

  @override
  String subtitleLoadError(Object error) {
    return 'Erreur chargement sous-titre: $error';
  }

  @override
  String get subtitlesUnavailable => 'Sous-titres : non disponibles';

  @override
  String get system => 'Système';

  @override
  String get tabAccount => 'Compte';

  @override
  String get tabAdvanced => 'Avancé';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabNetwork => 'Réseau';

  @override
  String get tabPlayer => 'Lecteur';

  @override
  String get tabSecurity => 'Sécurité';

  @override
  String get testNotifications => 'Tester les notifications';

  @override
  String get testNotificationsSubtitle =>
      'Envoie une notification locale de test';

  @override
  String get theme => 'Thème';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy Local)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simule l\'empreinte d\'un navigateur moderne pour contourner Cloudflare';

  @override
  String get tmdbKeyActive =>
      'Clé personnelle active — la clé partagée est ignorée';

  @override
  String get tmdbKeyColumn => 'Clés TMDB';

  @override
  String get tmdbKeyDelete => 'Supprimer la clé personnelle';

  @override
  String get tmdbKeyHint => 'La clé partagée embarquée est utilisée par défaut';

  @override
  String get tmdbKeyLabel => 'Clé API TMDB personnelle (optionnel)';

  @override
  String get tmdbKeyShared =>
      'Clé partagée embarquée utilisée (aucune clé personnelle)';

  @override
  String get tvChannels => 'Chaînes TV';

  @override
  String get unableToBuildReplayUrl =>
      'Impossible de construire l\'URL du replay.';

  @override
  String get unlockCloudflare => 'Débloquer (Cloudflare)';

  @override
  String get unstableConnection => 'Connexion instable';

  @override
  String get updateAllData => 'Mettre à jour toutes les données';

  @override
  String get updateThisCategory => 'Mettre à jour cette catégorie';

  @override
  String get updating => 'Mise à jour en cours…';

  @override
  String get volumeNormalization => 'Normalisation du volume';

  @override
  String get volumeNormalizationSubtitle =>
      'Limite les pics de volume entre chaînes/programmes (AGC)';

  @override
  String get watchLive => 'Regarder en direct';

  @override
  String get whoIsWatching => 'Qui regarde ?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Vos chaînes & contenus';
}
