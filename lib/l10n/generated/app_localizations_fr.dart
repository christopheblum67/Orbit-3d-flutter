// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get castSearching => 'Recherche d’appareils Cast…';

  @override
  String get castReceiverNotReady => 'Récepteur pas encore prêt';

  @override
  String castConnectedTo(String name) {
    return 'Connecté à $name';
  }

  @override
  String castConnectionFailed(String name) {
    return 'Connexion à $name impossible.';
  }

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNightFocusOn => 'Night Focus (activé)';

  @override
  String get playerNightFocusOff => 'Night Focus (désactivé)';

  @override
  String get playerLoadingProgram => 'Programme en cours de chargement…';

  @override
  String get audioNightHelp =>
      'L’optimisation sonore s’applique au moteur natif lorsque Night Focus est activé. Les réglages sont conservés pour la prochaine lecture.';

  @override
  String get audioNightTitle => 'Optimisation nocturne (Night Focus)';

  @override
  String get audioDialogueBoost => 'Amplification des dialogues';

  @override
  String get audioDialogueHelp =>
      'Rehausse la plage spectrale des voix (1–4 kHz)';

  @override
  String get audioBassLimiter => 'Réduction des basses et limiteur';

  @override
  String get audioBassHelp =>
      'Atténue les basses profondes et compresse les surcharges soudaines';

  @override
  String get audioVocalGain => 'Amplification des voix :';

  @override
  String get audioSyncTitle => 'Décalage audio (synchronisation A/V)';

  @override
  String startupResumeQuestion(String title, String position) {
    return 'Reprendre « $title » à $position ?';
  }

  @override
  String get startupLastSession => 'Dernière session';

  @override
  String get seriesExternalTracksHint =>
      'Avec un lecteur externe, choisissez les pistes audio et les sous-titres dans ce lecteur. Les préférences ci-dessous s’appliquent au lecteur interne.';

  @override
  String seriesResetWatchedBody(int count, String title) {
    return 'Les $count épisodes vus de « $title » seront marqués comme non vus pour ce profil.';
  }

  @override
  String seriesResetWatchedDone(String title) {
    return '« $title » retiré des déjà vus.';
  }

  @override
  String get recommendationAffinity => 'Affinité';

  @override
  String get recommendationLoadingCatalog =>
      'Chargement du catalogue en cours…';

  @override
  String get recommendationBuilding =>
      'Construction de vos recommandations en cours…';

  @override
  String get recommendationLoadingDuration =>
      'Cela peut prendre jusqu\'à 1 minute.';

  @override
  String get memoryPanelTitle => 'Mémoire et cache';

  @override
  String get memoryPanelHelp =>
      'Nettoyez l’historique et le cache d’images en mémoire.';

  @override
  String get memoryHistoryTitle => 'Effacer l’historique des vues';

  @override
  String get memoryHistoryHelp =>
      'Efface l’historique global et les anciens éléments récents, ainsi que les contenus récents et les positions de reprise du profil courant.';

  @override
  String get memoryClear => 'Effacer';

  @override
  String get memoryImagesTitle => 'Vider le cache d’images en mémoire';

  @override
  String get memoryImagesHelp =>
      'Libère les images mises en cache en mémoire ; les fichiers en cache sur disque sont conservés.';

  @override
  String get memoryPurge => 'Vider';

  @override
  String get sortOptionsTitle => 'Options de tri avancé';

  @override
  String get sortOptionsHelp => 'Sélectionnez un mode avec la télécommande :';

  @override
  String get sortRecentDescription =>
      'Contenus importés récemment dans la liste';

  @override
  String get sortResumeDescription =>
      'Place les contenus commencés non terminés en haut';

  @override
  String get sortRatingDescription => 'Classement selon les notes attribuées';

  @override
  String get sortYearDescription => 'Tri chronologique par année de production';

  @override
  String get sortDurationDescription => 'Tri par durée du contenu';

  @override
  String get sortActive => 'Actif';

  @override
  String get onboardingWelcome => 'Bienvenue sur Orbit IPTV';

  @override
  String get onboardingSubtitle =>
      'Configuration automatique de votre appareil';

  @override
  String get onboardingDeviceDetected => 'Appareil détecté';

  @override
  String get onboardingDevice => 'Appareil';

  @override
  String get onboardingConnection => 'Connexion';

  @override
  String get onboardingMobileNetwork => 'Réseau mobile';

  @override
  String get onboardingOtherNetwork => 'Autre';

  @override
  String get onboardingUnknownMemory => 'Inconnue';

  @override
  String onboardingMemoryMb(String value) {
    return '$value Mo';
  }

  @override
  String onboardingMemoryGb(String value) {
    return '$value Go';
  }

  @override
  String get onboardingEco => 'Économique';

  @override
  String onboardingProfile(String name) {
    return 'Profil $name';
  }

  @override
  String get onboardingEcoDescription =>
      'Démarrage rapide (1,5 s) · max 1080p · 3D désactivée · multi-vue désactivée';

  @override
  String get onboardingStandardDescription =>
      'Démarrage rapide (2 s) · rendu 3D fluide · multi-vue x2';

  @override
  String get onboardingUltraDescription =>
      'Zapping rapide (3 s · 4K HDR possible) · multi-vue x4';

  @override
  String get onboardingResetRecommendation => 'Réinitialiser la recommandation';

  @override
  String get onboardingAdjust => 'Ajuster manuellement';

  @override
  String get onboardingChooseProfile => 'Choisissez un profil';

  @override
  String get onboardingRecommendedProfile => 'Profil recommandé';

  @override
  String get onboardingEcoHint => 'Effets 3D et multi-vue désactivés.';

  @override
  String get duoTitle => 'Mode Duo';

  @override
  String duoChooseOthers(int max) {
    return 'Choisissez 1 à $max profil(s) supplémentaire(s)';
  }

  @override
  String duoChooseWith(String name, int max) {
    return 'Avec « $name » — choisissez 1 à $max autre(s) profil(s)';
  }

  @override
  String get duoCreateProfile => 'Créez au moins un 2e profil';

  @override
  String get duoNeedsProfiles =>
      'Le mode Duo nécessite au moins 2 profils au total.';

  @override
  String get duoFull => '4 profils — équipe complète pour le Duo';

  @override
  String duoReady(int count) {
    return '$count profils sélectionnés — prêt pour le Duo';
  }

  @override
  String duoSelectOne(int count) {
    return 'Sélectionnez au moins 1 profil supplémentaire ($count/4)';
  }

  @override
  String get duoStart => 'Lancer le Duo';

  @override
  String get duoSelected => 'Sélectionné';

  @override
  String get duoMaximum => 'Max atteint';

  @override
  String get legalIntroTitle => 'Orbit IPTV · Lisez-moi';

  @override
  String get legalIntro =>
      'Bonjour ! Avant de commencer, quelques informations courtes sur l’usage de cette application et les droits associés aux contenus affichés.';

  @override
  String get legalServicePlayer =>
      'Orbit IPTV est un lecteur IPTV : il affiche des flux fournis par des serveurs tiers (abonnement M3U / Xtream Codes) sans héberger aucun contenu vidéo, audio ou sous-titre.';

  @override
  String get legalServiceMetadata =>
      'Il agrège et présente des métadonnées (affiches, synopsis, EPG) récupérées via des API publiques. Il fonctionne comme un navigateur spécialisé pour les flux HLS/DASH.';

  @override
  String get legalRightsProvider =>
      'Le fournisseur d’abonnement IPTV est seul responsable des licences des chaînes, des droits de diffusion et du géoblocage des flux qu’il fournit.';

  @override
  String get legalRightsMetadata =>
      'Les affiches et synopsis proviennent de TMDb sous licence API ; l’attribution TMDb est affichée en bas de page des classements.';

  @override
  String get legalRightsContent =>
      'Orbit IPTV ne stocke, ne redistribue et ne monétise aucun contenu diffusé.';

  @override
  String get legalUsageTitle => 'Usage de l’application';

  @override
  String get legalUsageRights =>
      'À utiliser uniquement avec un abonnement dont vous détenez les droits de diffusion.';

  @override
  String get legalUsageRestrictions =>
      'Interdiction de contourner le géoblocage ou les DRM, et de partager son compte hors du foyer.';

  @override
  String get legalUsageEditorial =>
      'L’application ne fait aucune sélection éditoriale du contenu diffusé : aucun contrôle sur les flux des serveurs tiers.';

  @override
  String get legalPrivacyStorage =>
      'Profils, favoris, historique et réglages sont stockés localement. Si vous activez le partage cloud, les données sélectionnées sont également synchronisées de façon chiffrée.';

  @override
  String get legalPrivacyConsent =>
      'Aucune collecte par défaut : notifications et accès optionnels font l’objet d’un consentement explicite.';

  @override
  String get legalWarningTitle => 'Avertissement';

  @override
  String get legalWarningBody =>
      'Ce document ne constitue pas un conseil juridique. Les règles varient selon les juridictions : vérifiez que votre usage est autorisé dans votre pays (loi applicable, âge minimum).';

  @override
  String get legalAccept => 'J\'ai lu et j\'accepte · Continuer';

  @override
  String get epgReplayAvailableOnChannel =>
      'Replay disponible sur cette chaîne';

  @override
  String actorBornOn(String date) {
    return 'Né(e) le $date';
  }

  @override
  String get actorGenderMale => 'Homme';

  @override
  String get actorGenderFemale => 'Femme';

  @override
  String get crewTitle => 'Équipe technique';

  @override
  String get crewDirecting => 'Réalisation';

  @override
  String get crewWriting => 'Scénario';

  @override
  String get crewProduction => 'Production';

  @override
  String get crewSound => 'Son';

  @override
  String get crewCamera => 'Image';

  @override
  String get crewEditing => 'Montage';

  @override
  String get crewArt => 'Direction artistique';

  @override
  String get crewCostume => 'Costumes et maquillage';

  @override
  String get crewVisualEffects => 'Effets visuels';

  @override
  String get crewLighting => 'Éclairage';

  @override
  String get menuContinue => 'Continuer';

  @override
  String get menuDiscover => 'Découvrir';

  @override
  String get menuHome => 'Accueil';

  @override
  String get menuSearch => 'Recherche';

  @override
  String get menuProfile => 'Profil';

  @override
  String get menuSubscriptions => 'Abonnements';

  @override
  String get menuSelect => 'Sélectionnez un sous-menu';

  @override
  String get menuContent => 'Contenus';

  @override
  String get profileMustKeepOne =>
      'Au moins un profil doit rester sur l\'appareil';

  @override
  String profileDeleteBody(String name) {
    return '« $name » et ses préférences seront supprimés définitivement. Cette action est irréversible.';
  }

  @override
  String get profileChange => 'Changer de profil';

  @override
  String get profileEdit => 'Modifier';

  @override
  String get profileDelete => 'Supprimer';

  @override
  String get profileBack => 'Retour';

  @override
  String get profileAdult => 'adulte';

  @override
  String get profileChild => 'enfant';

  @override
  String get profileExpert => 'expert';

  @override
  String get categoryTitle => 'Catégories';

  @override
  String get categoryShowAll => 'Tout afficher';

  @override
  String get categoryScanFailed =>
      'Analyse impossible : le panel ne répond pas.';

  @override
  String get categoryEmptyLive => 'Aucune catégorie Live TV sur ce panel.';

  @override
  String get categoryEmptyMovies => 'Aucune catégorie Films sur ce panel.';

  @override
  String get categoryEmptySeries => 'Aucune catégorie Séries sur ce panel.';

  @override
  String categoryHidden(String label, int count) {
    return '$label ($count masquées)';
  }

  @override
  String get categoryNeverScanned => 'Jamais analysé';

  @override
  String get categoryScannedToday => 'Analysé aujourd\'hui';

  @override
  String get categoryScannedYesterday => 'Analysé hier';

  @override
  String categoryScannedDaysAgo(int days) {
    return 'Analysé il y a $days jours';
  }

  @override
  String categorySubscriptionSettings(String status) {
    return 'Réglages propres à cet abonnement — $status';
  }

  @override
  String get categoryScanning => 'Analyse…';

  @override
  String get categoryRescan => 'Réanalyser les catégories';

  @override
  String categoryChannelsCount(int count) {
    return '$count chaînes';
  }

  @override
  String categoryTitlesCount(int count) {
    return '$count titres';
  }

  @override
  String get liveWatchAction => 'Regarder';

  @override
  String get livePreviewDisabled =>
      'Aperçu vidéo désactivé. Appuie sur « regarder » pour ouvrir la chaîne.';

  @override
  String get livePreviewFrozen => 'Aperçu figé';

  @override
  String get livePreviewRetry => 'Relancer';

  @override
  String get episodeMarkWatchedFailed =>
      'Impossible de marquer cet épisode comme vu.';

  @override
  String get episodeAlreadyWatched => 'Épisode déjà vu';

  @override
  String get episodeMarkWatched => 'Marquer comme vu';

  @override
  String episodeResumeAt(String position) {
    return 'Repris à $position';
  }

  @override
  String get episodeActionsHelp =>
      'Maintenez OK pour marquer comme vu ou réinitialiser.';

  @override
  String episodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
    );
    return '$_temp0';
  }

  @override
  String episodesInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes en cours',
      one: '1 épisode en cours',
    );
    return '$_temp0';
  }

  @override
  String episodesWatchedCount(int seen, int total) {
    return '$seen/$total vus';
  }

  @override
  String get episodeWatched => 'Vu';

  @override
  String get homeRefreshFailed =>
      'Échec de la mise à jour : aucune source n\'a répondu.';

  @override
  String get homeRefreshDone => 'Mise à jour terminée.';

  @override
  String get homeRefreshEmpty =>
      'Mise à jour terminée, aucune donnée disponible.';

  @override
  String get homeChangeSubscription => 'Changer d’abonnement';

  @override
  String get homeManageSubscription => 'Gestion Abonnement';

  @override
  String get homeNoSubscription => 'Aucun abo';

  @override
  String get homeAddOrChangeSubscription => 'Ajouter ou changer d’abonnement';

  @override
  String get homeMultiStream => 'Jusqu\'à 4 flux à la fois';

  @override
  String get homeRadioStations => 'Stations en direct';

  @override
  String get homeRefreshUnknown => 'Dernière mise à jour inconnue';

  @override
  String homeRefreshMinutes(int minutes) {
    return 'Mis à jour il y a $minutes min';
  }

  @override
  String get catalogAll => 'Tous';

  @override
  String get catalogUngrouped => 'Non groupé';

  @override
  String get catalogSort => 'Trier';

  @override
  String get browseLoading => 'Chargement…';

  @override
  String get startupRadio => 'Radios';

  @override
  String get profileCreateFirstHint =>
      'Crée ton premier profil pour commencer à regarder.';

  @override
  String downloadDirectoryMissing(String path) {
    return 'Répertoire introuvable : $path';
  }

  @override
  String downloadFileMissing(String path, String names) {
    return 'Fichier introuvable : $path. Fichiers présents : $names';
  }

  @override
  String get widevineSelectSubscription => 'Sélectionnez un abonnement actif';

  @override
  String get widevineLoading => 'Chargement de la configuration';

  @override
  String get widevineLoadFailed => 'Impossible de charger la configuration';

  @override
  String widevineNoLicense(String subscription) {
    return '$subscription : aucune licence configurée';
  }

  @override
  String get widevineSelectFirst => 'Sélectionnez d’abord un abonnement actif.';

  @override
  String get widevineUnavailable =>
      'La configuration Widevine n’est pas disponible.';

  @override
  String widevineSaveFailed(String error) {
    return 'Impossible d’enregistrer Widevine : $error';
  }

  @override
  String widevineClearFailed(String error) {
    return 'Impossible d’effacer Widevine : $error';
  }

  @override
  String get widevineLicenseUrl => 'URL du serveur de licence';

  @override
  String get widevineInvalidUrl => 'Saisissez une URL HTTPS valide.';

  @override
  String get widevineHeaders => 'En-têtes HTTP (JSON, facultatif)';

  @override
  String get widevineInvalidHeaders =>
      'Les en-têtes doivent être un objet JSON de chaînes.';

  @override
  String get widevineCertificate => 'Certificat base64 (facultatif)';

  @override
  String get widevineStorageHelp =>
      'La configuration est stockée dans le coffre sécurisé. Elle est liée à cet abonnement. Elle ne rend pas compatible un moteur de lecture qui ne prend pas en charge Widevine.';

  @override
  String get widevineCopyLegacy => 'Copier l’ancienne configuration globale';

  @override
  String get widevineClear => 'Effacer';

  @override
  String get preferenceMultiTvFailed =>
      'Impossible d’enregistrer le réglage Multi TV.';

  @override
  String get preferenceLight => 'Clair';

  @override
  String get preferenceDark => 'Sombre';

  @override
  String get preferenceDisabled => 'Désactivé';

  @override
  String preferenceParentalEnabled(String restriction) {
    return 'Activé · Restriction $restriction';
  }

  @override
  String get preferenceMultiTvHelp =>
      'Afficher et autoriser la lecture multi-écran pour ce profil.';

  @override
  String get preferenceAllowRecording => 'Autoriser l’enregistrement';

  @override
  String get preferenceRecordingHelp =>
      'Permettre l’enregistrement de mes contenus favoris';

  @override
  String get preferenceLivePreview => 'Aperçu vidéo en direct';

  @override
  String get preferenceLivePreviewHelp =>
      'Affiche le direct dans la navigation Live. Réglage commun à cet appareil.';

  @override
  String get preferenceProfileHelp =>
      'Vos préférences sont appliquées à votre profil.';

  @override
  String get parentalAgeLimit => 'Restriction d’âge';

  @override
  String get parentalNone => 'Aucune';

  @override
  String get parentalHideAdult => 'Masquer le contenu adulte';

  @override
  String get parentalHideAdultHelp =>
      'Films/Séries/Chaînes classés 18+ ou érotique';

  @override
  String get parentalHideViolence => 'Masquer la violence';

  @override
  String get parentalHideViolenceHelp =>
      'Contenus Gore / Horreur / Thriller / Meurtre';

  @override
  String get parentalCurrentPin => 'PIN actuel : ••••';

  @override
  String get parentalSetPin => 'Définir un code PIN';

  @override
  String get parentalNewPin => 'Nouveau PIN (4 chiffres)';

  @override
  String get parentalPin => 'PIN (4 chiffres)';

  @override
  String get parentalShowPin => 'Afficher le PIN';

  @override
  String get parentalHidePin => 'Masquer le PIN';

  @override
  String get parentalUpdatePin => 'Mettre à jour le PIN';

  @override
  String get subtitleAvailableTracks => 'Pistes disponibles';

  @override
  String get subtitleAddUrl => 'Ajouter un sous-titre (URL .srt/.vtt)';

  @override
  String get subtitleLoadAction => 'Charger';

  @override
  String subtitleTrackCues(String language, int count) {
    return '$language · $count segments';
  }

  @override
  String multiMaxStreams(int count) {
    return 'Maximum : $count flux sur cet appareil.';
  }

  @override
  String get multiDisabledProfile =>
      'Multi TV est désactivée pour ce profil. Activez-la dans les préférences du profil.';

  @override
  String get multiAnalyzingDevice => 'Analyse de l’appareil…';

  @override
  String get multiDeviceAnalysisFailed => 'Analyse de l’appareil impossible';

  @override
  String get multiDisabledEconomy =>
      'Multi-vue désactivée par le profil Économique.\nRéglez le profil dans Configurer l’appareil.';

  @override
  String engineInternal(String name) {
    return '$name (Interne)';
  }

  @override
  String engineExternal(String name) {
    return '$name (Externe)';
  }

  @override
  String get engineSelectionHelp =>
      'Choisissez le moteur utilisé pour chaque type de contenu, ainsi que le moteur de secours en cas d’échec de lecture.';

  @override
  String get engineVideoDecoding => 'Décodage vidéo';

  @override
  String get engineAutoRecommended => 'Auto (recommandé)';

  @override
  String get engineHardware => 'Matériel';

  @override
  String get engineSoftware => 'Logiciel';

  @override
  String get engineAutoSoftware => 'Auto : logiciel retenu pour cet appareil';

  @override
  String get engineSubtitleDefault => 'Par défaut';

  @override
  String get engineSubtitleDisabled => 'Sans sous-titres';

  @override
  String get engineSubtitleForced => 'Sous-titres forcés';

  @override
  String get engineVodSubtitles => 'Sous-titres VOD';

  @override
  String get profilePinsNone => 'Aucun profil ne possède de code PIN.';

  @override
  String get profilePinsRemoveQuestion =>
      'Supprimer les codes PIN des profils ?';

  @override
  String profilePinsRemoveConfirmation(int count) {
    return 'Les codes PIN seront retirés de $count profil(s). Les profils et leurs données resteront sur cet appareil. Les changements pourront être synchronisés avec les appareils partagés dans le Cloud.';
  }

  @override
  String get profilePinsRemove => 'Supprimer les PIN';

  @override
  String get profilePinsNothingToRemove => 'Aucun code PIN à supprimer.';

  @override
  String profilePinsRemoved(int count) {
    return 'Codes PIN supprimés de $count profil(s).';
  }

  @override
  String get profilePinsRemoveFailed =>
      'Impossible de supprimer les codes PIN. Réessayez.';

  @override
  String get profileProtection => 'Protection des profils';

  @override
  String get profilePinsRemoveHelp =>
      'Retirez les codes PIN de tous les profils de cet appareil. Les profils et leurs données ne seront pas supprimés.';

  @override
  String get profilePinsRemoving => 'Suppression des PIN…';

  @override
  String get profilePinsRemoveAll => 'Supprimer les codes PIN des profils';

  @override
  String get radioEmptyHint =>
      'Ajoute des stations de radio dans les réglages.';

  @override
  String get radioStations => 'Stations';

  @override
  String radioStationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String get radioStreamUnavailable =>
      'Flux radio indisponible sur cette station';

  @override
  String get livePreviousCategory => 'Catégorie précédente';

  @override
  String get liveNextCategory => 'Catégorie suivante';

  @override
  String get liveGuideUnavailable => 'Guide indisponible';

  @override
  String get liveNoPrograms => 'Aucun programme disponible';

  @override
  String get liveNoUpcomingPrograms => 'Aucun programme à venir';

  @override
  String get liveNoDescription => 'Aucun résumé disponible.';

  @override
  String get recommendationSubscriptionChanged =>
      'L’abonnement a changé. Recommencez.';

  @override
  String get recommendationCannotFavorite =>
      'Ce contenu ne peut pas être ajouté aux favoris.';

  @override
  String get recommendationFavoriteFailed =>
      'Impossible d’ajouter ce contenu aux favoris.';

  @override
  String get recommendationMovieQuestion => 'Ce film vous appartient ?';

  @override
  String get recommendationSeriesQuestion => 'Cette série vous appartient ?';

  @override
  String get recommendationMovieSeen => 'Film déjà vu';

  @override
  String get recommendationSeriesSeen => 'Série déjà vue';

  @override
  String get recommendationRemovedFuture => 'Retiré des prochaines suggestions';

  @override
  String get recommendationNotInterested => 'Pas intéressé';

  @override
  String get recommendationExcluded => 'Écarté définitivement des suggestions';

  @override
  String get recommendationFavoriteProfile =>
      'Ajouté aux favoris du profil actuel';

  @override
  String get startupParsingPlaylist => 'Analyse de la playlist M3U en cours…';

  @override
  String get startupProviderSlow =>
      'Le fournisseur répond lentement (vérification de sécurité possible). Merci de patienter…';

  @override
  String get startupLoadingRemaining => 'Chargement des radios et replays';

  @override
  String get startupLoadingInitial =>
      'Chargement du direct, des films, séries et du guide TV';

  @override
  String get startupCheckingSubscription => 'La vérification de l’abonnement';

  @override
  String get startupRefresh => 'La mise à jour';

  @override
  String startupStalled(String step, int seconds) {
    return '$step ne signale aucune progression depuis $seconds secondes. Le serveur peut être lent ou indisponible.';
  }

  @override
  String startupRefreshStalled(String step, int seconds) {
    return '$step ne signale aucune progression depuis $seconds secondes. Le serveur peut être lent ou indisponible ; vous pouvez vérifier l’abonnement.';
  }

  @override
  String get startupMovies => 'Films & VOD';

  @override
  String get startupLive => 'Chaînes live';

  @override
  String get startupReady => 'Prêt !';

  @override
  String get startupBackHome => 'Retour à l’accueil';

  @override
  String get startupCheckSubscription => 'Vérifier l’abonnement';

  @override
  String get browseRankings => 'Classements';

  @override
  String get browsePopularRankings => 'Classements populaires';

  @override
  String get browseRankingsUnavailableHint =>
      'Les tendances TMDB ne sont pas disponibles. Ajoutez une clé API TMDB dans Réglages (ou TMDB_API_KEY dans assets/config/runtime.env).';

  @override
  String get browseTmdbData => 'Données © TMDB';

  @override
  String get browsePopular => 'Populaire';

  @override
  String get browseNowPlaying => 'En salle';

  @override
  String get browseTopRated => 'Mieux notés';

  @override
  String get browseUpcoming => 'À venir';

  @override
  String get browseTrendingWeek => 'Tendance de la semaine';

  @override
  String get browseOnTheAir => 'En diffusion';

  @override
  String get browseAiringToday => 'Diffusion aujourd’hui';

  @override
  String get browseSeriesType => 'Série';

  @override
  String get browseSynopsis => 'Synopsis';

  @override
  String get browseNotInSubscription =>
      'Cette œuvre n’est pas présente dans votre abonnement actif. Découvrez-la sur l’une des plateformes référencées par TMDB.';

  @override
  String get browseExploreCategories => 'Explorer par catégorie';

  @override
  String get browseFavoriteHint =>
      'Appuie longuement sur un élément pour le retrouver ici.';

  @override
  String get browseRecentHint => 'Les contenus regardés s’afficheront ici.';

  @override
  String get browseSearchEmpty =>
      'Aucun contenu ne correspond à cette recherche.';

  @override
  String browseTitlesCount(int visible, int total) {
    return '$visible titres (sur $total)';
  }

  @override
  String get catalogSearchMovies => 'Rechercher un film ou un genre…';

  @override
  String get catalogSearchSeries => 'Rechercher une série ou un genre…';

  @override
  String get catalogLoading =>
      'Chargement du catalogue en cours…\nMerci de patienter quelques secondes.';

  @override
  String get catalogNoMovies => 'La bibliothèque VOD est vide pour le moment.';

  @override
  String get catalogNoSeries =>
      'La bibliothèque de séries est vide pour le moment.';

  @override
  String get catalogNoRecentMovies => 'Aucun film récent';

  @override
  String get catalogNoRecentSeries => 'Aucune série récente';

  @override
  String get catalogNoResults => 'Aucun résultat';

  @override
  String get catalogNoMoviesInCategory => 'Aucun film dans cette catégorie';

  @override
  String get catalogMovieFavoriteHint =>
      'Appuie sur le cœur d\'un film pour le retrouver ici.';

  @override
  String get catalogSeriesFavoriteHint =>
      'Appuie sur le cœur d\'une série pour la retrouver ici.';

  @override
  String get catalogRecentMoviesHint =>
      'Les films regardés s\'afficheront ici.';

  @override
  String get catalogRecentSeriesHint =>
      'Les séries regardées s\'afficheront ici.';

  @override
  String get catalogMovieSearchEmpty =>
      'Aucun film ne correspond à cette recherche.';

  @override
  String get catalogSeriesSearchEmpty =>
      'Aucune série ne correspond à cette recherche.';

  @override
  String get catalogMovieCategoryEmpty =>
      'Aucun film ne correspond à cette catégorie.';

  @override
  String removedFromFavorites(String title) {
    return '« $title » retiré des favoris';
  }

  @override
  String get liveBackToChannels => 'Retour aux chaînes';

  @override
  String get liveAddSourceHint =>
      'Ajoute une source de chaînes dans les réglages.';

  @override
  String get liveNoChannelFound => 'Aucune chaîne trouvée';

  @override
  String get liveNoRecentChannel => 'Aucune chaîne récente';

  @override
  String get liveNoChannelInGroup => 'Aucune chaîne dans ce groupe';

  @override
  String get liveTryAnotherSearch => 'Essaie un autre terme de recherche.';

  @override
  String get liveFavoriteHint =>
      'Appuie sur le cœur d\'une chaîne pour la retrouver ici.';

  @override
  String get liveRecentHint => 'Les chaînes regardées s\'afficheront ici.';

  @override
  String get liveEmptyGroupHint => 'Ce groupe ne contient aucune chaîne.';

  @override
  String get liveLoadingHint =>
      'Chargement des chaînes en cours…\nMerci de patienter avant de lancer un flux.';

  @override
  String get replayNoChannels =>
      'Aucune chaîne de cet abonnement ne déclare de catch-up.';

  @override
  String get replayEmptyGroup =>
      'Ce groupe ne contient aucune chaîne rejouable.';

  @override
  String get epgLoadingBanner =>
      'Guide TV en cours de chargement… les programmes apparaîtront dans un instant.';

  @override
  String get epgNoChannelsInCategory => 'Aucune chaîne dans cette catégorie';

  @override
  String get epgLoadingChannels => 'Chargement des chaînes…';

  @override
  String get epgChannelsLoadFailed => 'Impossible de charger les chaînes.';

  @override
  String get replayToday => 'Aujourd\'hui';

  @override
  String get replayYesterday => 'Hier';

  @override
  String searchWithinHint(String type) {
    return 'Rechercher dans $type…';
  }

  @override
  String get searchAllHint => 'Rechercher Live, Films, Séries, Replay, EPG…';

  @override
  String get searchHint => 'Rechercher…';

  @override
  String searchWithinTitle(String type) {
    return 'Recherche dans $type';
  }

  @override
  String get searchUnifiedTitle => 'Recherche unifiée';

  @override
  String searchWithinHelp(String type) {
    return 'Tapez pour rechercher uniquement dans $type.';
  }

  @override
  String get searchUnifiedHelp =>
      'Tapez votre recherche pour trouver des chaînes Live, films, séries, replays ou programmes EPG.';

  @override
  String get searchOffline => 'Mode hors ligne — résultats locaux uniquement';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultsHelp =>
      'Essayez avec d\'autres termes ou vérifiez l\'orthographe.';

  @override
  String get searchAllCategories => 'Toutes';

  @override
  String get searchClearHistory => 'Effacer l\'historique';

  @override
  String get settingsPlaybackEngines => 'Moteurs de lecture';

  @override
  String get settingsCloudAccount => 'Compte cloud';

  @override
  String get settingsCloudSignIn => 'Connexion Google ou e-mail';

  @override
  String get settingsSyncUnavailable => 'Synchronisation complète indisponible';

  @override
  String get settingsSyncUnavailableHelp =>
      'L’ancienne synchronisation en clair est désactivée. Les fiches de profils peuvent être sauvegardées manuellement depuis Compte cloud ; les autres données ne sont pas synchronisées.';

  @override
  String get settingsSystemAutomatic => 'Automatique (Système)';

  @override
  String get settingsSubtitleDefault => 'Sous-titrage par défaut';

  @override
  String get settingsSubtitleForced => 'Sous-titrage forcé';

  @override
  String get settingsSubtitleOff => 'Sans sous-titrage';

  @override
  String get settingsSubtitleMoviesSeries => 'Sous-titres des films et séries';

  @override
  String get settingsSubtitles => 'Sous-titres';

  @override
  String get settingsProtectedPlayback => 'Lecture protégée';

  @override
  String get settingsCategoryFilters => 'Filtres de catégories';

  @override
  String get settingsCategoryFiltersHelp =>
      'Catégories masquées par abonnement';

  @override
  String get episodeSelectProfile =>
      'Sélectionnez un profil pour modifier cet épisode.';

  @override
  String get episodeProfileChanged => 'Le profil a changé. Réessayez.';

  @override
  String get episodeStatusFailed =>
      'Impossible de modifier le statut de cet épisode.';

  @override
  String get episodeResetQuestion => 'Réinitialiser l\'épisode ?';

  @override
  String get episodeMarkWatchedQuestion => 'Marquer comme vu ?';

  @override
  String episodeResetProgressMessage(String title) {
    return '« $title » sera marqué comme non vu et sa progression de lecture sera effacée.';
  }

  @override
  String episodeMarkUnwatchedMessage(String title) {
    return '« $title » sera marqué comme non vu pour ce profil.';
  }

  @override
  String episodeMarkWatchedMessage(String title) {
    return '« $title » sera marqué comme vu pour ce profil.';
  }

  @override
  String get episodeMarkUnwatched => 'Marquer comme non vu';

  @override
  String get detailAiData => 'Données générées par IA';

  @override
  String detailSourceData(String source) {
    return 'Données $source';
  }

  @override
  String get detailUnavailableValue => 'Non disponible';

  @override
  String get detailKeywords => 'Mots-clés';

  @override
  String get detailGenres => 'Genres';

  @override
  String get detailCast => 'Distribution';

  @override
  String get detailTrailerFailed => 'Impossible d\'ouvrir la bande-annonce';

  @override
  String get detailShowCrew => 'Voir l\'équipe technique';

  @override
  String get detailHideCrew => 'Masquer l\'équipe technique';

  @override
  String seriesRuntimePerEpisode(int minutes) {
    return '$minutes min/ép';
  }

  @override
  String seriesNetwork(String network) {
    return 'Réseau : $network';
  }

  @override
  String seriesFirstAired(String date) {
    return 'Première diffusion : $date';
  }

  @override
  String seriesSeasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saisons',
      one: '1 saison',
    );
    return '$_temp0';
  }

  @override
  String get profileDiscardHelp =>
      'Des modifications non sauvegardées seront perdues. Quitter quand même ?';

  @override
  String get profileLeave => 'Quitter';

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profileAvatarTheme => 'Thème d\'avatar';

  @override
  String get profileAvatarThemeHelp =>
      'Choisissez un style, puis un avatar dans la grille';

  @override
  String get profileAvatars => 'Avatars';

  @override
  String profileCurrentTheme(String theme) {
    return 'Thème actuel : $theme';
  }

  @override
  String get profileRequired => 'Obligatoire';

  @override
  String get profileFavoriteMovieGenres => 'Genres de films favoris';

  @override
  String get profileGenresHelp =>
      'Choisissez un ou plusieurs styles pour les recommandations';

  @override
  String get profilePinMismatch => 'Les codes PIN ne correspondent pas.';

  @override
  String get profilePinCreateFailed => 'Impossible de créer le code PIN.';

  @override
  String get profilePinActive => 'Un code PIN de 4 chiffres est actif';

  @override
  String get profilePinPending =>
      'Code PIN confirmé. Enregistrez le profil pour l’activer.';

  @override
  String get profilePinRequest =>
      'Demander un code PIN à la sélection du profil';

  @override
  String get profilePinCreating => 'Création du code PIN…';

  @override
  String get profileNotFound => 'Aucun profil à modifier';

  @override
  String get profileSaveActivate => 'Enregistrer et activer la protection';

  @override
  String get profileCreateActivate =>
      'Créer le profil et activer la protection';

  @override
  String get profileSaveAction => 'Enregistrer';

  @override
  String get profileCreateAction => 'Créer le profil';

  @override
  String get genreAction => 'Action';

  @override
  String get genreAdventure => 'Aventure';

  @override
  String get genreAnimation => 'Animation';

  @override
  String get genreComedy => 'Comédie';

  @override
  String get genreRomanticComedy => 'Comédie romantique';

  @override
  String get genreDrama => 'Drame';

  @override
  String get genreHorror => 'Horreur';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreDetective => 'Policier';

  @override
  String get genreCrime => 'Crime';

  @override
  String get genreWar => 'Guerre';

  @override
  String get genreHistorical => 'Historique';

  @override
  String get genreWestern => 'Western';

  @override
  String get genreSciFi => 'Sci-Fi';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreSuperheroes => 'Super-héros';

  @override
  String get genreMystery => 'Mystère';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreMusical => 'Musical';

  @override
  String get genreMusic => 'Musique';

  @override
  String get genreBiopic => 'Biopic';

  @override
  String get genreDocumentary => 'Documentaire';

  @override
  String get genreTournament => 'Tournoi';

  @override
  String get genreChildren => 'Enfants';

  @override
  String get genreFamily => 'Famille';

  @override
  String get genreSuspense => 'Suspense';

  @override
  String get genreBlackWhite => 'Noir & Blanc';

  @override
  String get genreClassic => 'Classique';

  @override
  String get cloudConfirm => 'Confirmer';

  @override
  String get cloudShareProfilesTitle => 'Partager ces profils ?';

  @override
  String cloudDuplicateProfileId(String id) {
    return 'Même nom — identifiant : $id';
  }

  @override
  String get cloudShareProfilesHelp =>
      'Les profils manquants seront ajoutés sans remplacer ceux qui existent. Leurs favoris et leur activité seront partagés, ainsi que les préférences et abonnements, avec leurs identifiants IPTV. Ces données sont chiffrées.\n\nDeux profils de même nom restent séparés. Si des données sont différentes, vous choisirez lesquelles garder.';

  @override
  String get cloudChooseSourceTitle => 'Choisir la source en cas de conflit';

  @override
  String get cloudChooseSourceHelp =>
      'Les ajouts différents seront réunis sur les deux appareils. Si une même donnée a été modifiée des deux côtés, la source choisie ici sera conservée et envoyée à l’autre appareil. Ce choix s’applique à tous les conflits du démarrage.';

  @override
  String get cloudSourceLocal => 'Cet appareil est la source';

  @override
  String get cloudSourceRemote => 'Le Cloud est la source';

  @override
  String get cloudResetTitle => 'Repartir de zéro sur le Cloud ?';

  @override
  String get cloudResetHelp =>
      'Tous les profils et leurs données partagées seront supprimés du Cloud. Les profils locaux seront conservés. Les autres appareils devront saisir ce nouveau code. Cette action est irréversible.';

  @override
  String get cloudNewCode => 'Nouveau code';

  @override
  String get cloudConfirmCode => 'Confirmer le code';

  @override
  String get cloudResetCodeError =>
      'Saisissez un nouveau code de 3 à 10 chiffres et confirmez-le à l’identique.';

  @override
  String get cloudRestoreTitle => 'Récupérer ce profil ?';

  @override
  String cloudRestoreHelp(String name) {
    return 'La fiche de $name sera ajoutée sans remplacer les profils locaux. Les favoris, historiques, abonnements et préférences ne seront pas restaurés.';
  }

  @override
  String cloudDeleteTitle(String name) {
    return 'Supprimer $name du Cloud ?';
  }

  @override
  String get cloudDeleteHelp =>
      'La fiche et les données synchronisées de ce profil seront supprimées du Cloud. Le profil local sur cet appareil ne sera pas supprimé. Les autres appareils seront mis en pause et devront actualiser leur liste.';

  @override
  String get cloudSyncFinished => 'Synchronisation terminée';

  @override
  String get cloudSyncFinishedHelp =>
      'Les profils sélectionnés et leurs données ont bien été synchronisés avec le Cloud.';

  @override
  String get cloudResolveTitle => 'Résoudre le conflit ?';

  @override
  String get cloudResolveLocalHelp =>
      'Pour les éléments en conflit de cette catégorie, la version de cet appareil sera conservée. L’autre version, y compris une éventuelle suppression, sera écrasée.';

  @override
  String get cloudResolveRemoteHelp =>
      'Pour les éléments en conflit de cette catégorie, la version cloud sera conservée. L’autre version, y compris une éventuelle suppression, sera écrasée.';

  @override
  String get cloudProfilesTitle => 'Mes profils sur mes appareils';

  @override
  String get cloudSignInToContinue =>
      'Connectez-vous à un compte cloud pour continuer.';

  @override
  String get cloudFirebaseUnavailable =>
      'Firebase n’est pas disponible sur cet appareil.';

  @override
  String get cloudGoogleCanceled =>
      'Connexion Google annulée ou impossible. Si le problème persiste, vérifiez la configuration Google de cette application.';

  @override
  String get cloudGoogleConfiguration =>
      'Configuration Google incorrecte : vérifiez le client OAuth et la signature de cette application.';

  @override
  String get cloudGoogleUnavailable =>
      'Connexion Google indisponible sur cet appareil.';

  @override
  String get cloudSignInUnavailable =>
      'Service de connexion indisponible sur cet appareil.';

  @override
  String get cloudSignInRetry => 'Connexion impossible. Réessayez.';

  @override
  String get cloudInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get cloudWeakPassword => 'Le mot de passe est trop faible.';

  @override
  String get cloudEmailInUse => 'Cette adresse est déjà utilisée.';

  @override
  String get cloudInvalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get cloudNetworkUnavailable => 'Connexion réseau indisponible.';

  @override
  String get cloudTooManyAttempts => 'Trop de tentatives. Réessayez plus tard.';

  @override
  String get cloudMethodDisabled =>
      'Cette méthode de connexion n’est pas activée.';

  @override
  String get cloudGoogleAlreadyLinked => 'Ce compte est déjà lié à Google.';

  @override
  String get cloudGoogleOtherAccount =>
      'Ce compte Google est déjà associé à un autre compte Firebase. Aucun compte ni donnée n’a été fusionné. Pour utiliser cet autre compte, déconnectez-vous puis connectez-vous avec Google.';

  @override
  String get cloudFirebaseSignInFailed =>
      'Connexion impossible. Réessayez ou vérifiez la configuration Firebase.';

  @override
  String get cloudAccountIntro =>
      'Connectez-vous pour retrouver vos profils et leurs données sur vos appareils. Vos données sont chiffrées.';

  @override
  String get cloudAccountLinkHelp =>
      'Si un compte est déjà connecté, Google lui sera lié sans changer son identifiant. Les comptes distincts ne sont pas fusionnés.';

  @override
  String get cloudAccountStateError => 'Impossible de lire l’état du compte.';

  @override
  String get cloudAccountChecking => 'Vérification du compte…';

  @override
  String get cloudAccountNone => 'Aucun compte cloud connecté.';

  @override
  String get cloudPairingCleanupFailed =>
      'Compte associé, mais le nettoyage de la session temporaire a échoué.';

  @override
  String get cloudPairTv => 'Associer une TV par QR code';

  @override
  String get pairSignOutFirst =>
      'Déconnectez le compte cloud avant le couplage.';

  @override
  String get pairScannerAccountChanged =>
      'Le compte cloud a changé. Fermez cet écran et recommencez.';

  @override
  String get pairScannerAccountCheckFailed =>
      'Impossible de vérifier le compte cloud.';

  @override
  String get pairScannerCameraFailed => 'Impossible d’utiliser la caméra.';

  @override
  String get pairScannerInvalidQr =>
      'Ce QR code ne correspond pas à une session Orbit 3D.';

  @override
  String get pairScannerAssociationFailed =>
      'Association impossible. Vérifiez le réseau ou recréez le QR code sur la TV.';

  @override
  String get pairScannerTitle => 'Associer une TV';

  @override
  String get pairScannerSent =>
      'Demande envoyée. Confirmez le compte affiché sur la TV.';

  @override
  String get pairScannerCameraPermission =>
      'Caméra indisponible. Autorisez son accès dans les réglages.';

  @override
  String get pairScannerCompareCode =>
      'Comparez ce code avec celui affiché sur la TV :';

  @override
  String get pairScannerVerifyWarning =>
      'N’acceptez que si les deux codes sont identiques et que vous contrôlez la TV.';

  @override
  String pairScannerSelectedProfiles(String profiles) {
    return 'La TV sélectionnera automatiquement : $profiles.';
  }

  @override
  String get pairScannerConfirm => 'Confirmer et associer';

  @override
  String get pairScannerRescan => 'Scanner à nouveau';

  @override
  String get pairTemporaryUnavailable =>
      'La session temporaire est indisponible.';

  @override
  String get pairCleanupIncomplete =>
      'Nettoyage incomplet : la session expirera automatiquement.';

  @override
  String get pairCleanupFailed =>
      'Nettoyage impossible : la session expirera automatiquement.';

  @override
  String get pairUnavailable =>
      'Couplage indisponible. Vérifiez le réseau et la configuration Firebase.';

  @override
  String get pairRestart => 'Recommencez le couplage.';

  @override
  String get pairTvTitle => 'Associer cette TV';

  @override
  String get pairInstructions =>
      'Sur le téléphone connecté, ouvrez la synchronisation chiffrée et scannez ce QR code. Comparez les codes affichés avant de confirmer.';

  @override
  String get pairCreateQr => 'Créer un QR code';

  @override
  String pairVerificationCode(String code) {
    return 'Code de vérification : $code';
  }

  @override
  String get pairExpires => 'Le QR code expire après cinq minutes.';

  @override
  String pairAccount(String account) {
    return 'Compte à associer : $account';
  }

  @override
  String get pairConfirmAccount => 'Confirmer ce compte';

  @override
  String get pairWaiting => 'En attente de confirmation sur le téléphone…';

  @override
  String get cloudTemporaryAccount =>
      'Compte temporaire connecté sur cet appareil.';

  @override
  String cloudAccountConnected(String account) {
    return 'Compte connecté : $account';
  }

  @override
  String get cloudRecoverProfiles => 'Retrouver mes profils sur mes appareils';

  @override
  String get cloudEmail => 'Adresse e-mail';

  @override
  String get cloudSignIn => 'Se connecter';

  @override
  String get cloudCreateAccount => 'Créer un compte';

  @override
  String get cloudResetEmailSent =>
      'Si le compte existe, un e-mail de réinitialisation peut être envoyé.';

  @override
  String get cloudForgotPassword => 'Mot de passe oublié';

  @override
  String get cloudGoogleLinked => 'Compte Google déjà lié';

  @override
  String get cloudSignInWithGoogle => 'Se connecter avec Google';

  @override
  String get cloudLinkGoogle => 'Lier un compte Google';

  @override
  String get cloudSignOut => 'Se déconnecter';

  @override
  String get cloudPrepareCodeHelp =>
      'Un adulte prépare le code. Ensuite, choisis les profils à partager.';

  @override
  String get cloudChooseProfilesHelp =>
      'Coche les profils que tu veux retrouver sur tes appareils, puis appuie sur Partager.';

  @override
  String get cloudFirstSyncHelp =>
      'La première mise à jour peut prendre plus de 10 minutes. Garde Orbit ouvert jusqu’à la fin.';

  @override
  String get cloudLegacyPhrase => 'Phrase secrète (ancien format)';

  @override
  String get cloudAdultCode => 'Code donné par l’adulte';

  @override
  String get cloudSamePhraseHelp =>
      'Saisir la même phrase sur les deux appareils.';

  @override
  String get cloudSameCodeHelp => 'Saisir le même code sur les deux appareils.';

  @override
  String get cloudShowPhrase => 'Afficher la phrase secrète';

  @override
  String get cloudHidePhrase => 'Masquer la phrase secrète';

  @override
  String get cloudShowCode => 'Afficher le code cloud';

  @override
  String get cloudHideCode => 'Masquer le code cloud';

  @override
  String get cloudSeeProfiles => 'Voir mes profils';

  @override
  String get cloudRefreshList => 'Actualiser la liste';

  @override
  String get cloudAdultOptions => 'Options pour un adulte';

  @override
  String get cloudUseLegacyPhrase => 'Utiliser une ancienne phrase secrète';

  @override
  String get cloudResetAction => 'Supprimer tout le Cloud et repartir de zéro';

  @override
  String get cloudShareBeforePairing =>
      'Partagez d’abord les profils sélectionnés pour les rendre disponibles sur la TV.';

  @override
  String get cloudConfirmYourCode => 'Confirmer votre code';

  @override
  String get cloudBackupTitle => 'Sauvegarder cette fiche ?';

  @override
  String cloudConfirmProfilesHelp(String name) {
    return 'Confirmez votre code pour les profils $name. Gardez-le en lieu sûr : sans lui, vous ne pourrez plus retrouver vos données.';
  }

  @override
  String cloudBackupHelp(String name) {
    return 'Seule la fiche de $name sera sauvegardée, chiffrée. Les favoris, historiques, abonnements et préférences ne sont pas inclus. La perte du secret rend la sauvegarde irrécupérable.';
  }

  @override
  String get cloudConfirmPhrase => 'Confirmer la phrase secrète';

  @override
  String get cloudConfirmCloudCode => 'Confirmer le code cloud';

  @override
  String get cloudShowConfirmation => 'Afficher la confirmation';

  @override
  String get cloudHideConfirmation => 'Masquer la confirmation';

  @override
  String get cloudSecretsMismatch => 'Les secrets ne correspondent pas.';

  @override
  String get cloudSyncProfileTitle => 'Synchroniser ce profil ?';

  @override
  String get cloudSyncProfileHelp =>
      'La fiche, les favoris vidéo et radio, historiques récents, épisodes vus et positions du profil actif, ainsi que les préférences et abonnements, seront synchronisés sous forme chiffrée pendant cette session. Les identifiants IPTV sont inclus. L’abonnement actif reste choisi sur chaque appareil.';

  @override
  String get cloudUpdating => 'Mise à jour en cours…';

  @override
  String get cloudAdultMustChoose =>
      'Un adulte doit choisir les données à garder.';

  @override
  String get cloudSharingEnabled => 'Le partage est activé.';

  @override
  String get cloudKeepOpen =>
      'Cela peut prendre plus de 10 minutes. Garde Orbit ouvert.';

  @override
  String get cloudAutoSharing =>
      'Les changements sont partagés automatiquement.';

  @override
  String get cloudConflictHelp =>
      'Cet appareil et l’autre appareil ne sont pas d’accord. Demande à un adulte de choisir la bonne version.';

  @override
  String get cloudKeepLocal => 'Garder les données d’ici';

  @override
  String get cloudKeepRemote => 'Garder les données de l’autre appareil';

  @override
  String get cloudShareSettings => 'Réglages du partage (adulte)';

  @override
  String get cloudUpdateNow => 'Mettre à jour maintenant';

  @override
  String get cloudPause => 'Mettre en pause';

  @override
  String get cloudSelectProfiles => 'Choisis les profils à partager';

  @override
  String get cloudWhichProfiles =>
      'Quels profils veux-tu retrouver sur tes appareils ?';

  @override
  String get cloudLocalProfilesUnavailable => 'Profils locaux indisponibles.';

  @override
  String get cloudUnselectAll => 'Tout décocher';

  @override
  String get cloudSelectAll => 'Tout cocher';

  @override
  String get cloudShareSelected => 'Partager les profils cochés';

  @override
  String get cloudShareAll => 'Partager tous les profils';

  @override
  String get cloudProfilesToAdd => 'Profils à ajouter';

  @override
  String get cloudOtherOptions => 'Autres options (adulte)';

  @override
  String get cloudShareActiveOnly => 'Partager seulement le profil utilisé';

  @override
  String get cloudLocalProfileKept => 'Le profil local est conservé.';

  @override
  String get cloudRecover => 'Récupérer';

  @override
  String get cloudDeleteAction => 'Supprimer du Cloud';

  @override
  String get cloudBackupAction => 'Sauvegarder';

  @override
  String get cloudScopeFavorites => 'favoris';

  @override
  String get cloudScopeRadioFavorites => 'favoris radio';

  @override
  String get cloudScopeRecents => 'historique récent';

  @override
  String get cloudScopeWatched => 'épisodes vus';

  @override
  String get cloudScopePlayback => 'positions de lecture';

  @override
  String get cloudScopePreferences => 'préférences générales';

  @override
  String get cloudScopeProfile => 'fiche du profil';

  @override
  String get cloudProfileFallback => 'profil';

  @override
  String get cloudScopeSubscriptions => 'abonnements';

  @override
  String get cloudScopeData => 'données';

  @override
  String cloudProgressPercent(int percent) {
    return 'Fait : $percent %';
  }

  @override
  String cloudProgressScope(String scope) {
    return 'En ce moment : $scope.';
  }

  @override
  String cloudProgressProfile(String scope, String profile) {
    return 'En ce moment : $scope — $profile.';
  }

  @override
  String cloudConflictProfile(String name, String id) {
    return 'Profil en conflit : $name ($id)';
  }

  @override
  String cloudConflictData(String scope) {
    return 'Données : $scope';
  }

  @override
  String get cloudChangedElsewhere =>
      'Le cloud a changé ailleurs. Rechargez avant de réessayer.';

  @override
  String get cloudBadPhrase =>
      'Phrase secrète incorrecte ou données cloud altérées.';

  @override
  String get cloudBadCode => 'Code cloud incorrect ou données cloud altérées.';

  @override
  String get cloudAccessFailed =>
      'Accès cloud impossible. Vérifiez le réseau et la configuration Firebase.';

  @override
  String get cloudInvalidData =>
      'Données cloud invalides ou incompatibles ; aucune restauration effectuée.';

  @override
  String get cloudOperationFailed =>
      'Opération impossible. Vérifiez le réseau puis actualisez le Cloud.';

  @override
  String get cloudAskAdult => 'Demande le code à un adulte.';

  @override
  String get cloudCodeLength => 'Le code doit contenir de 3 à 10 chiffres.';

  @override
  String get cloudAccountChanged =>
      'Le compte ou le secret a changé. Recommencez.';

  @override
  String get cloudPhraseChanged =>
      'Le compte ou la phrase a changé. Recommencez.';

  @override
  String get cloudBackupRefreshed => 'Fiche sauvegardée. Catalogue actualisé.';

  @override
  String get cloudAccessEmpty => 'Accès confirmé. Aucun profil sauvegardé.';

  @override
  String get cloudCodeUnverified =>
      'Aucune sauvegarde trouvée : votre code ne peut pas encore être vérifié.';

  @override
  String get cloudAccessChoose =>
      'Accès confirmé. Choisissez les profils à partager.';

  @override
  String get cloudBackupRefreshFailed =>
      'Fiche sauvegardée, mais le catalogue n’a pas pu être actualisé.';

  @override
  String get cloudPhoneProfilesMissing =>
      'Les profils choisis sur le téléphone ne sont plus disponibles. Actualisez la liste et sélectionnez-les à nouveau.';

  @override
  String get cloudPhoneProfilesReceived =>
      'Profils reçus du téléphone. Démarrage du partage…';

  @override
  String get cloudProfileRestored =>
      'Fiche récupérée. Sélectionnez ce profil dans l’application, puis revenez ici pour activer sa synchronisation.';

  @override
  String get cloudWaitDelete =>
      'Attendez la fin de la synchronisation avant la suppression.';

  @override
  String get cloudWaitReset =>
      'Attendez la fin de la synchronisation avant la réinitialisation.';

  @override
  String get cloudResetComplete =>
      'Cloud réinitialisé. Le nouveau code est actif ; les profils locaux ont été conservés.';

  @override
  String get cloudWaitSelection =>
      'Une synchronisation est en cours. Attendez la fin avant de modifier la sélection.';

  @override
  String get cloudProfilesChanged =>
      'Les profils ont changé. Vérifiez votre sélection.';

  @override
  String get cloudRestoredProfileMissing =>
      'Une fiche récupérée est introuvable. Réessayez.';

  @override
  String cloudRestoringProfiles(int current, int total) {
    return 'Récupération des fiches : $current / $total.';
  }

  @override
  String get cloudCheckingProfiles =>
      'Vérification et sauvegarde des fiches cloud.';

  @override
  String get cloudPartialRestore =>
      'Certaines fiches ont peut-être été récupérées. Vérifiez la liste avant de réessayer.';

  @override
  String get cloudStartingSync => 'Démarrage de la synchronisation.';

  @override
  String get cloudProfilesBackedUp => 'Les fiches ont été sauvegardées.';

  @override
  String get subscriptionTitle => 'Abonnements';

  @override
  String get subscriptionRefreshSuccess =>
      'Mise à jour terminée : au moins une source actualisée.';

  @override
  String get subscriptionRefreshFailed =>
      'Mise à jour impossible : aucune donnée reçue.';

  @override
  String get subscriptionConnectionHelp =>
      'Connexion impossible ou identifiants refusés. Vérifiez l’adresse du serveur, le nom d’utilisateur, le mot de passe et votre connexion Internet.';

  @override
  String get subscriptionDuplicateHelp =>
      'Doublon possible : plusieurs abonnements ont la même configuration. Aucun n’a été supprimé ; leurs favoris peuvent être différents.';

  @override
  String get subscriptionRefreshActive =>
      'Forcer la mise à jour de l’abonnement actif';

  @override
  String get subscriptionActivationFailed =>
      'Impossible d’activer l’abonnement.';

  @override
  String get subscriptionDeleteTitle => 'Supprimer l’abonnement ?';

  @override
  String subscriptionDeleteHelp(String name) {
    return 'Voulez-vous supprimer « $name » ? Cette action est irréversible.';
  }

  @override
  String get subscriptionNoActive =>
      'Aucun abonnement actif. Sélectionnez-en un ou ajoutez-en un nouveau.';

  @override
  String get subscriptionActivate => 'Activer';

  @override
  String get subscriptionNone => 'Aucun abonnement';

  @override
  String get subscriptionEmptyHelp =>
      'Ajoutez votre premier abonnement Xtream Codes ou M3U pour commencer.';

  @override
  String get subscriptionFilterHelp =>
      'Les catégories à masquer se règlent dans Configuration > Réglages avancés > Filtres de catégories.';

  @override
  String get subscriptionPossibleDuplicate => 'Doublon possible';

  @override
  String get subscriptionInactive => 'Inactif';

  @override
  String get subscriptionTesting => 'Test…';

  @override
  String get subscriptionUntested => 'Non testé';

  @override
  String get subscriptionTestOk => 'Test OK';

  @override
  String subscriptionTestLatency(int latency) {
    return 'Test OK • $latency ms';
  }

  @override
  String get subscriptionTestFailed => 'Échec';

  @override
  String get subscriptionTestAction => 'Tester';

  @override
  String get subscriptionIncomplete => 'Configuration incomplète';

  @override
  String get connectionInvalidConfiguration =>
      'Les paramètres de cet abonnement sont manquants ou invalides.';

  @override
  String get connectionCheckServerOrPlaylist =>
      'Vérifiez l’URL du serveur ou de la playlist.';

  @override
  String get connectionCheckCredentials =>
      'Vérifiez également l’identifiant et le mot de passe.';

  @override
  String get connectionCertificateExpired => 'Certificat SSL expiré';

  @override
  String get connectionSslError => 'Erreur SSL/TLS';

  @override
  String get connectionCertificateExpiredHelp =>
      'Le certificat de sécurité du serveur a expiré.';

  @override
  String get connectionSslHelp =>
      'La connexion sécurisée au serveur n’a pas pu être établie.';

  @override
  String get connectionCheckDateTime =>
      'Vérifiez la date et l’heure de votre appareil.';

  @override
  String get connectionContactProvider =>
      'Contactez votre fournisseur si le problème persiste.';

  @override
  String get connectionDnsFailure => 'Serveur introuvable (DNS)';

  @override
  String get connectionDnsFailureHelp =>
      'Impossible de trouver le serveur. Vérifiez son adresse et votre connexion Internet.';

  @override
  String get connectionNetworkUnavailable => 'Réseau inaccessible';

  @override
  String get connectionNetworkUnavailableHelp =>
      'Impossible d’atteindre le réseau du serveur. Vérifiez votre connexion Internet.';

  @override
  String get connectionServerError => 'Serveur temporairement indisponible';

  @override
  String get connectionServerUnreachable => 'Serveur inaccessible';

  @override
  String get connectionServerUnreachableHelp =>
      'Impossible de joindre le serveur. Vérifiez l’adresse et votre connexion Internet.';

  @override
  String get connectionCheckUrl => 'Vérifiez l’orthographe de l’URL.';

  @override
  String get connectionTryAnotherNetwork => 'Essayez depuis un autre réseau.';

  @override
  String get connectionContactUnreachableProvider =>
      'Contactez votre fournisseur si le serveur reste inaccessible.';

  @override
  String get connectionTimeout => 'Délai de réponse dépassé';

  @override
  String get connectionTimeoutHelp =>
      'Le serveur n’a pas répondu à temps. Il peut être lent ou momentanément surchargé.';

  @override
  String get connectionTryLater => 'Réessayez dans quelques minutes.';

  @override
  String get connectionCheckInternet => 'Vérifiez votre connexion Internet.';

  @override
  String get connectionInvalidCredentials => 'Identifiants invalides';

  @override
  String get connectionAccessDenied => 'Accès refusé';

  @override
  String get connectionXtreamRejected =>
      'L’identifiant ou le mot de passe Xtream est refusé par le serveur.';

  @override
  String get connectionM3uAuthorization =>
      'La playlist M3U nécessite une autorisation ou une URL valide.';

  @override
  String get connectionCheckCredentialsCase =>
      'Vérifiez l’identifiant et le mot de passe, en respectant les majuscules.';

  @override
  String get connectionConfirmCredentials =>
      'Demandez à votre fournisseur de confirmer les informations de connexion.';

  @override
  String get connectionAccountUnavailable =>
      'Abonnement ou compte indisponible';

  @override
  String get connectionAccountUnavailableHelp =>
      'Le compte peut être expiré, désactivé ou avoir atteint sa limite de connexions.';

  @override
  String get connectionCheckSubscription =>
      'Vérifiez l’état de l’abonnement auprès de votre fournisseur.';

  @override
  String get connectionCloseOtherDevices =>
      'Fermez les autres appareils connectés puis réessayez.';

  @override
  String get connectionForbidden => 'Accès interdit';

  @override
  String get connectionForbiddenHelp =>
      'Le serveur refuse la connexion. Le compte ou l’adresse IP peut être bloqué.';

  @override
  String get connectionCheckActiveSubscription =>
      'Vérifiez que l’abonnement est toujours actif.';

  @override
  String get connectionCheckProviderAccess =>
      'Contactez votre fournisseur pour vérifier l’accès.';

  @override
  String get connectionNotFound => 'Adresse introuvable (404)';

  @override
  String get connectionInvalidRequest => 'Requête invalide';

  @override
  String get connectionInvalidAddress =>
      'L’adresse du serveur ou le point d’accès ne semble pas correct.';

  @override
  String get connectionCheckBaseUrl =>
      'Vérifiez l’URL de base du serveur ou l’URL M3U.';

  @override
  String get connectionUseXtreamPanel =>
      'Utilisez l’adresse du panel Xtream, sans ajouter player_api.php.';

  @override
  String connectionServerUnavailable(int status) {
    return 'Serveur temporairement indisponible ($status)';
  }

  @override
  String get connectionServerProblem =>
      'Le serveur du fournisseur rencontre un problème.';

  @override
  String get connectionInvalidPlaylist => 'Playlist M3U invalide ou vide';

  @override
  String get connectionInvalidPlaylistHelp =>
      'La playlist ne contient pas de données lisibles au format attendu.';

  @override
  String get connectionCheckPlaylistUrl =>
      'Vérifiez que l’URL pointe vers une playlist M3U à jour.';

  @override
  String get connectionRequestNewUrl =>
      'Demandez une nouvelle URL à votre fournisseur.';

  @override
  String get connectionTestFailed => 'Échec du test de connexion';

  @override
  String get connectionUnexpectedError =>
      'Une erreur inattendue a empêché la connexion à cet abonnement.';

  @override
  String get connectionCheckSubscriptionAndInternet =>
      'Vérifiez les informations de l’abonnement et votre connexion Internet.';

  @override
  String get connectionRetryOrContact =>
      'Réessayez ou contactez votre fournisseur si le problème persiste.';

  @override
  String get connectionThingsToCheck => 'À vérifier';

  @override
  String get connectionTechnicalDetails => 'Détails techniques';

  @override
  String subscriptionSemantic(String name) {
    return 'Abonnement $name';
  }

  @override
  String get subscriptionSemanticActive => 'actif';

  @override
  String get subscriptionSemanticDuplicate => 'doublon possible';

  @override
  String get subscriptionAdded => 'Abonnement ajouté';

  @override
  String subscriptionAddedHelp(String name) {
    return '« $name » est enregistré. Vous pouvez tester la connexion puis activer l’abonnement.';
  }

  @override
  String get subscriptionTestRunning => 'Test de connexion en cours…';

  @override
  String get subscriptionTestSuccess => 'Test de connexion réussi.';

  @override
  String get subscriptionTestUnavailable =>
      'Le résultat du test est indisponible.';

  @override
  String get subscriptionTestError =>
      'Impossible de terminer le test de connexion.';

  @override
  String get subscriptionEditTitle => 'Modifier l’abonnement';

  @override
  String get subscriptionNewTitle => 'Nouvel abonnement';

  @override
  String get subscriptionName => 'Nom de l’abonnement';

  @override
  String get subscriptionUsername => 'Nom d’utilisateur';

  @override
  String get subscriptionPassword => 'Mot de passe';

  @override
  String get subscriptionShowPassword => 'Afficher le mot de passe';

  @override
  String get subscriptionHidePassword => 'Masquer le mot de passe';

  @override
  String get subscriptionAdd => 'Ajouter';

  @override
  String get playerExternalOpened => 'Lecture ouverte dans un lecteur externe';

  @override
  String get playerExternalTrackHelp =>
      'Choisissez les pistes audio et les sous-titres dans le lecteur externe : les préférences d’Orbit ne lui sont pas transmises.';

  @override
  String get playerProviderBlocked =>
      'Flux temporairement bloqué par le fournisseur';

  @override
  String get playerStreamNotStarting =>
      'Le flux est bien reçu mais la lecture ne démarre pas. La piste est peut-être trop lourde pour cet appareil.';

  @override
  String get playerStreamFrozen =>
      'Le flux est reçu mais la lecture est figée.';

  @override
  String get playerStreamRecovering =>
      'Le flux ne progresse plus. Tentative de récupération…';

  @override
  String playerCooldown(int seconds) {
    return 'Serveur protégé (anti-leech), nouvelle tentative dans ${seconds}s';
  }

  @override
  String get playerProviderBlockedHelp =>
      'La lecture a été coupée par la protection anti-leech du serveur. Patientez 3 à 5 minutes sans lecture, puis relancez cette chaîne (sans zapper).';

  @override
  String get playerLiveUnavailable => 'Flux indisponible';

  @override
  String get playerLiveUnavailableHelp =>
      'Impossible de lancer cette chaîne. Vérifiez votre abonnement ou réessayez.';

  @override
  String playerNextEpisode(String title) {
    return 'Épisode suivant : $title';
  }

  @override
  String playerNextEpisodeCountdown(String title, int seconds) {
    return 'Épisode suivant : $title ($seconds s)';
  }

  @override
  String get profileSelectToContinue => 'Sélectionnez un profil pour continuer';

  @override
  String get profileCreateToWatch =>
      'Créez votre premier profil pour commencer à regarder.';

  @override
  String get profileNavigationHelp =>
      'Flèches + OK pour naviguer · Touchez une carte pour sélectionner';

  @override
  String get profileActive => 'Actif';

  @override
  String get resumeAction => 'Reprendre';

  @override
  String get refreshRecommendations => 'Actualiser les recommandations';

  @override
  String get localVideoProxy => 'Relais vidéo local expérimental';

  @override
  String get localVideoProxySubtitle =>
      'Pour les films et séries du lecteur interne, avec cache disque limité.';

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
  String get deleteDownload => 'Supprimer';

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
    return 'Dernière sync (cette installation) : $time';
  }

  @override
  String get cloudSyncNow => 'Synchroniser maintenant';

  @override
  String get cloudSyncNowSubtitle =>
      'Envoie au cloud les favoris, historiques et reprises de lecture de cette installation';

  @override
  String get cloudSyncSubtitleOff =>
      'Synchronise favoris, épisodes vus, récents et reprises de lecture pour cette installation';

  @override
  String get cloudflareReset => 'Réinitialiser config Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Désactive l\'impersonation TLS et rétablit l\'User-Agent standard du lecteur';

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
  String currentProfileLabel(String name) {
    return 'Profil courant : $name';
  }

  @override
  String get dataAlreadyFresh => 'Données déjà fraîches (moins de 8 h)';

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
  String downloadAdded(String title) {
    return '« $title » ajouté aux téléchargements';
  }

  @override
  String get downloadCompleted => 'Téléchargé';

  @override
  String get downloadInProgress => 'Téléchargement en cours';

  @override
  String get downloadOffline => 'Télécharger hors-ligne';

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
  String get moreResults => 'Voir plus de résultats';

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
  String get noGroupAffinity => 'Aucune affinité commune trouvée';

  @override
  String get noHistory => 'Aucun historique';

  @override
  String get historyLoading => 'Chargement de l’historique…';

  @override
  String get historyEmptyHint => 'Tes lectures récentes apparaîtront ici.';

  @override
  String get refreshAction => 'Actualiser';

  @override
  String get favoritesAdd => 'Ajouter aux favoris';

  @override
  String get favoritesRemove => 'Retirer des favoris';

  @override
  String get favoritesNeedScope =>
      'Un profil et un abonnement actifs sont nécessaires.';

  @override
  String get favoritesReplayHint =>
      'Appuie sur le cœur d’un replay pour le retrouver ici.';

  @override
  String favoritesClearPrompt(int total) {
    return 'Retirer les $total favoris enregistrés ? La liste des favoris sera vidée.';
  }

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
  String get noRecommendations => 'Aucune recommandation disponible';

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
  String get pinRequired => 'Code PIN requis';

  @override
  String get pinSet => 'Définir un code PIN';

  @override
  String get pinThisProfile => 'ce profil';

  @override
  String pinEnterForProfile(String name) {
    return 'Entrez le code PIN de $name';
  }

  @override
  String get pinConfirmFourDigits => 'Confirmez votre code à 4 chiffres';

  @override
  String get pinChooseFourDigits => 'Choisissez un code à 4 chiffres';

  @override
  String get pinVerifyFailed => 'Impossible de vérifier le code PIN.';

  @override
  String get pinConfirmInstruction =>
      'Après 4 chiffres, appuyez sur ✓ pour valider.';

  @override
  String pinIncorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count essais restants',
      one: '1 essai restant',
    );
    return 'Code incorrect — $_temp0';
  }

  @override
  String get pinChecking => 'Vérification en cours…';

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
  String profilesSelected(int count) {
    return '$count profils sélectionnés';
  }

  @override
  String get profileVisible => 'Profil visible';

  @override
  String get programGrid => 'Grille des programmes';

  @override
  String get protectWithPin => 'Protéger par code PIN';

  @override
  String get rankingsUnavailable => 'Classement indisponible';

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
  String get tmdbMovieRecommendations => 'Recommandations TMDB';

  @override
  String get tmdbRecommendationsEmpty =>
      'Aucune recommandation TMDB pour ce film.';

  @override
  String get tmdbRecommendationsError =>
      'Impossible de charger les recommandations TMDB.';

  @override
  String get tmdbRecommendationsUnavailable =>
      'Recommandations TMDB indisponibles pour ce film.';

  @override
  String get playbackDelayedTitle => 'La lecture prend du temps';

  @override
  String get playbackDelayedMessage =>
      'La lecture ne démarre pas ou ne reprend pas pour le moment. Le flux, la connexion ou le format vidéo peuvent être en cause.';

  @override
  String get playbackContinueWaiting => 'Continuer à attendre';

  @override
  String get playbackUnavailableTitle => 'Lecture indisponible';

  @override
  String get playbackUnavailableMessage =>
      'Impossible de lancer ce film ou cet épisode pour le moment. Réessaie ou vérifie la connexion et le format du fichier.';

  @override
  String get protectedPlaybackUnsupportedMessage =>
      'Le lecteur intégré ne peut pas lire en toute sécurité ce flux DASH ou relayé avec des en-têtes protégés.';

  @override
  String get greenScreenDetectedTitle => 'Problème d’image détecté';

  @override
  String get externalPlayerLimitationsTitle => 'Limites des lecteurs externes';

  @override
  String get externalPlayerLimitationsDescription =>
      'Avec VLC ou MX Player, les préférences audio et sous-titres d’Orbit ne sont pas transmises : choisissez les pistes dans le lecteur externe. Pour les séries, l’épisode suivant démarre automatiquement uniquement si MX Player confirme la fin ; sinon, lancez-le manuellement au retour dans Orbit. Cela concerne aussi le lecteur de secours.';

  @override
  String get actorShowFilmography => 'Voir la filmographie';

  @override
  String get actorFilmographyUnavailable => 'Filmographie indisponible.';

  @override
  String get actorCreditFilm => 'Film';

  @override
  String get actorCreditSeries => 'Série';

  @override
  String actorCreditRole(String role) {
    return 'Rôle : $role';
  }

  @override
  String get actorCreditTmdbUnavailable => 'Détails TMDB indisponibles.';

  @override
  String get actorCreditSynopsisUnavailable => 'Synopsis indisponible.';

  @override
  String get actorCreditCatalogUnconfirmed =>
      'Correspondance non confirmée dans le catalogue.';

  @override
  String get actorCreditOpenCatalog => 'Voir dans le catalogue';

  @override
  String get greenScreenDetectedMessage =>
      'Une anomalie d’image (écran vert) a été détectée. Le moteur actuel ne semble pas décoder correctement ce flux. Essayez un autre moteur dans Réglages > Lecteur > Moteurs de lecture, puis relancez la lecture.';

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
  String selectAtLeastOneProfile(int count) {
    return 'Sélectionnez au moins 1 profil supplémentaire ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'Sélectionnez un profil pour voir ses recommandations';

  @override
  String get series => 'Séries';

  @override
  String get seriesNotFound => 'Série introuvable';

  @override
  String get seriesMissingId =>
      'Identifiant de série manquant (navigation incorrecte). Retournez à la liste et réessayez.';

  @override
  String get seriesEnriching => 'Enrichissement des métadonnées…';

  @override
  String get seriesLoading => 'Chargement de la série…';

  @override
  String get seriesNoEpisodesHint =>
      'Cette série ne propose pas encore d’épisodes.';

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
  String get sortAffinity => 'Par affinité';

  @override
  String get sortAffinityDescription =>
      'Classe selon vos goûts déclarés dans le profil (matchmaking)';

  @override
  String get sortAscending => 'Tri croissant';

  @override
  String get sortByDuration => 'Par durée';

  @override
  String get sortByRating => 'Par note';

  @override
  String get sortByYear => 'Par année';

  @override
  String get sortDescending => 'Tri décroissant';

  @override
  String get sortLatestM3UXtream => 'Derniers Ajouts M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nom (A → Z)';

  @override
  String get sortNameZToA => 'Nom (Z → A)';

  @override
  String get sortResumePriority => 'À reprendre en priorité';

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
  String get tmdbKeyValid => 'Clé TMDB valide';

  @override
  String get tmdbKeyValidationFailed =>
      'Clé refusée par TMDB ou réseau indisponible : vérifiez la clé';

  @override
  String get tvChannels => 'Chaînes TV';

  @override
  String get unableToBuildReplayUrl =>
      'Impossible de construire l\'URL du replay.';

  @override
  String get unlockCloudflare => 'Débloquer (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'Vérification du fournisseur requise';

  @override
  String get cloudflareChallengeHelp =>
      'Le fournisseur demande une vérification Cloudflare. Effectuez-la dans cette fenêtre, fermez-la puis réessayez. Les cookies de cette page ne sont pas transmis au lecteur : la lecture peut rester bloquée.';

  @override
  String get openProviderWebsite => 'Ouvrir le site du fournisseur';

  @override
  String get providerWebsiteUnavailable =>
      'Impossible d\'ouvrir le site du fournisseur. Vérifiez l\'adresse de l\'abonnement et réessayez.';

  @override
  String get unstableConnection => 'Connexion instable';

  @override
  String get updateAllData => 'Mettre à jour toutes les données';

  @override
  String get aiTopicsTitle => 'Sujets recommandés par IA';

  @override
  String get updateThisCategory => 'Mettre à jour cette catégorie';

  @override
  String get updating => 'Mise à jour en cours…';

  @override
  String get updatingMediaContent =>
      'Mise à jour du contenu multimédia en cours…';

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

  @override
  String get subtitleSection => 'Sous-titres';

  @override
  String get seriesDefaultAudioLanguage => 'Langue audio par défaut';

  @override
  String get seriesDefaultSubtitleLanguage =>
      'Langue des sous-titres par défaut';

  @override
  String get seriesSelectLanguage => 'Sélectionner une langue';

  @override
  String get seriesStreamDefault => '(Défaut du flux)';

  @override
  String get seriesChooseLanguageFirst => 'Choisissez d’abord une langue';

  @override
  String get seriesDefaultAllEpisodes =>
      'Utiliser le défaut du flux pour tous les épisodes';

  @override
  String get seriesDefaultUnlessEpisodeChoice =>
      'Utiliser le défaut du flux sauf choix par épisode';

  @override
  String get seriesForceLanguageAllEpisodes =>
      'Forcer cette langue pour tous les épisodes';

  @override
  String get seriesApplyIfAvailable => 'Appliquer si disponible';

  @override
  String get seriesSearchingAudio => 'Recherche des pistes audio…';

  @override
  String get seriesSubtitlesDisabled => '(Désactivés)';

  @override
  String get seriesDisableSubtitlesAll =>
      'Désactiver les sous-titres pour tous les épisodes';

  @override
  String get seriesDisableSubtitlesDefault =>
      'Désactiver les sous-titres par défaut';

  @override
  String get seriesSearchingSubtitles => 'Recherche des pistes de sous-titres…';

  @override
  String get seriesNoSubtitleTracks =>
      'Aucune piste détectée : choisissez une langue, elle sera utilisée si disponible.';

  @override
  String get seriesLanguageFrench => 'Français';

  @override
  String get seriesLanguageEnglish => 'Anglais';

  @override
  String get seriesLanguageSpanish => 'Espagnol';

  @override
  String get seriesLanguageGerman => 'Allemand';

  @override
  String get seriesLanguageItalian => 'Italien';

  @override
  String get seriesLanguageArabic => 'Arabe';

  @override
  String get subtitleEmbeddedSection => 'Sous-titres intégrés';

  @override
  String get subtitleForcedLabel => 'Forcé';

  @override
  String get subtitleEmbeddedLabel => 'Intégré';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'Vidéo';

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
  String get subtitleGuessed => 'Pistes déduites';

  @override
  String get subtitleGuessedInfo =>
      'Le panel ne déclare pas ses sous-titres : ces pistes sont obtenues par convention d\'URL. Celle qui n\'existe pas signale une erreur à l\'activation.';

  @override
  String get subtitleUnavailableToast => 'Sous-titre indisponible';

  @override
  String get audioTrackFallback => 'Piste audio';

  @override
  String get subtitleLoading => 'Chargement des sous-titres…';

  @override
  String get videoQualityFallback => 'Qualité vidéo';

  @override
  String get close => 'Fermer';

  @override
  String get streamTracksError => 'Impossible de lire les pistes de ce flux.';

  @override
  String get subtitleProviderNoAnswer => 'Le panel n\'a pas répondu.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Sous-titre indisponible : $reason';
  }

  @override
  String get epgNoDataTitle => 'Aucune donnée de programme';

  @override
  String get epgLiveNow => 'En Direct';

  @override
  String get epgSelectChannelHint =>
      'Sélectionnez une chaîne pour voir son programme';

  @override
  String get epgNow => 'Maintenant';

  @override
  String get epgZoomIn => 'Zoomer';

  @override
  String get epgZoomOut => 'Dézoomer';

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
    return 'Aucun programme déjà diffusé dans les $days jours d\'archives de ce compte pour cette chaîne.';
  }

  @override
  String get replayNonePublished =>
      'Le panel ne publie aucun programme déjà diffusé pour cette chaîne.';

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
    return 'Vérification des sous-titres… ($count)';
  }

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
  String get downloadStatusDownloading => 'Téléchargement';

  @override
  String get downloadStatusPreparing => 'Préparation';

  @override
  String get downloadStatusPaused => 'En pause';

  @override
  String get downloadStatusCompleted => 'Terminé';

  @override
  String get downloadStatusFailed => 'Échec';

  @override
  String get downloadStatusCancelled => 'Annulé';

  @override
  String get downloadStatusQueued => 'En file';

  @override
  String get history => 'Historique';

  @override
  String get explore => 'Explorer';

  @override
  String get downloadsEmptyHint =>
      'Ajoutez des contenus depuis les détails d\'un film ou d\'une série.';

  @override
  String get downloadsLocation => 'Fichiers';

  @override
  String get advancedSettingsTitle => 'Réglages avancés';

  @override
  String get advancedSettingsIntro =>
      'Identifiants d\'API et paramètres réseau. Ces réglages engagent votre compte auprès de services tiers : une clé partagée consomme son quota, et une mauvaise manipulation du réseau peut empêcher l\'application de démarrer.';

  @override
  String get advancedStatus => 'État des identifiants';

  @override
  String get advancedAccessTitle => 'Accès réservé';

  @override
  String get advancedAccessHint => 'Code';

  @override
  String get advancedAccessConfirm => 'Ouvrir';

  @override
  String get advancedAccessWrong => 'Code incorrect';

  @override
  String get advancedHiddenHint => 'Maintenir appuyé pour les réglages avancés';

  @override
  String get favoritesAndDownloads => 'Favoris et Téléchargements';

  @override
  String get activeAudio => 'Son actif sur cet écran';

  @override
  String get addChannel => 'Ajouter une chaîne';

  @override
  String get noChannelSelected => 'Aucune chaîne sélectionnée';

  @override
  String get removeChannel => 'Retirer la chaîne';

  @override
  String get avatarCategoryAll => 'Toutes';

  @override
  String get avatarCategoryCharacters => 'Personnages';

  @override
  String get avatarCategorySuperheroes => 'Super-héros';

  @override
  String get avatarCategoryAnimals => 'Animaux';

  @override
  String get avatarCategoryFlowers => 'Fleurs';

  @override
  String get avatarCategoryNature => 'Nature';

  @override
  String get avatarCategoryYouth => 'Jeunesse';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Noir & Blanc';

  @override
  String get updateTitle => 'Mises à jour';

  @override
  String get updateSettingsSubtitle =>
      'Vérifier la dernière version officielle sur GitHub';

  @override
  String get updateChecking => 'Vérification en cours…';

  @override
  String get updateCurrent =>
      'Vous utilisez déjà la dernière version disponible.';

  @override
  String get updateAvailable => 'Une nouvelle version est disponible :';

  @override
  String get updateDownloading => 'Téléchargement et vérification de l’APK…';

  @override
  String get updateReady => 'Ouverture de l’installateur Android…';

  @override
  String get updatePermission =>
      'Autorisez Orbit à installer des applications inconnues dans les réglages Android, puis revenez ici et réessayez.';

  @override
  String get updateNoRelease =>
      'Aucune release stable n’est disponible sur GitHub.';

  @override
  String get updateAssetError =>
      'La release ne contient pas l’APK universel officiel ou ses informations de vérification.';

  @override
  String get updateInvalidApk =>
      'APK incompatible, signé avec une autre clé ou version Android non supérieure. Installation annulée.';

  @override
  String get updateIntegrityError =>
      'La vérification du fichier téléchargé a échoué. Installation annulée.';

  @override
  String get updateGenericError =>
      'La mise à jour a échoué. Vérifiez la connexion et réessayez.';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateInstall => 'Mettre à jour';

  @override
  String get updateRetryInstall => 'Réessayer l’installation';

  @override
  String get updateRetry => 'Réessayer';

  @override
  String get avatarCategoryPixels => 'Pixels';

  @override
  String get unassignedLegacyLibraryItems =>
      'Certains anciens favoris ou téléchargements ne sont pas affichés : leur abonnement d’origine est inconnu. Ils restent conservés.';

  @override
  String get forceNoSubtitles => 'Forcer aucun sous-titre';

  @override
  String get forceNoSubtitlesSubtitle =>
      'Désactive automatiquement les sous-titres au lancement d\'un film ou d\'une série';

  @override
  String get backTooltip => 'Retour';

  @override
  String get categoryFilters => 'Filtres de catégories';

  @override
  String get categoryFiltersSubtitle => 'Catégories masquées par abonnement';

  @override
  String get memoryCacheTitle => 'Gestion de la Mémoire & Cache';

  @override
  String get memoryCacheSubtitle =>
      'Libérez de l\'espace et nettoyez les données locales.';

  @override
  String get clearWatchHistoryTitle => 'Vider l\'historique des vues';

  @override
  String get clearWatchHistorySubtitle =>
      'Efface la liste des récemment regardés et les positions de reprise.';

  @override
  String get clearWatchHistoryAction => 'Effacer';

  @override
  String get clearCoverCacheTitle => 'Nettoyer le cache des pochettes';

  @override
  String get clearCoverCacheSubtitle =>
      'Libère l\'espace disque occupé par les vignettes VOD/EPG stockées localement.';

  @override
  String get clearCoverCacheAction => 'Purger';

  @override
  String get enginesDescription =>
      'Choisissez le moteur utilisé pour chaque type de contenu, ainsi que le moteur de secours en cas d\'échec de lecture.';

  @override
  String get sortAdvancedTitle => 'Options de Tri Avancé';

  @override
  String get sortAdvancedSubtitle =>
      'Sélectionnez un mode avec la télécommande :';

  @override
  String get sortDescRecentlyAdded =>
      'Contenus importés récemment dans la liste';

  @override
  String get sortDescResumePriority =>
      'Place les contenus commencés non terminés en haut';

  @override
  String get sortDescByRating => 'Classement selon les notes attribuées';

  @override
  String get sortDescByYear => 'Tri chronologique par année de production';

  @override
  String get sortDescByDuration => 'Tri par durée du contenu';

  @override
  String get sortOptionActive => 'Actif';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get noActiveSubscription => 'Aucun abonnement actif';

  @override
  String get noVodCategories => 'Aucune catégorie Films sur ce panel.';

  @override
  String get noSeriesCategories => 'Aucune catégorie Séries sur ce panel.';

  @override
  String get neverScanned => 'Jamais analysé';

  @override
  String get scannedToday => 'Analysé aujourd\'hui';

  @override
  String get scannedYesterday => 'Analysé hier';

  @override
  String scannedDaysAgo(int days) {
    return 'Analysé il y a $days jours';
  }

  @override
  String subscriptionSettingsNote(String scanned) {
    return 'Réglages propres à cet abonnement — $scanned';
  }

  @override
  String get rescanCategories => 'Réanalyser les catégories';

  @override
  String get scanningCategories => 'Analyse…';
}
