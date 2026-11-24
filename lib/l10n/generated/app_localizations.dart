import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @castSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche d’appareils Cast…'**
  String get castSearching;

  /// No description provided for @castReceiverNotReady.
  ///
  /// In fr, this message translates to:
  /// **'Récepteur pas encore prêt'**
  String get castReceiverNotReady;

  /// No description provided for @castConnectedTo.
  ///
  /// In fr, this message translates to:
  /// **'Connecté à {name}'**
  String castConnectedTo(String name);

  /// No description provided for @castConnectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à {name} impossible.'**
  String castConnectionFailed(String name);

  /// No description provided for @playerPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerNightFocusOn.
  ///
  /// In fr, this message translates to:
  /// **'Night Focus (activé)'**
  String get playerNightFocusOn;

  /// No description provided for @playerNightFocusOff.
  ///
  /// In fr, this message translates to:
  /// **'Night Focus (désactivé)'**
  String get playerNightFocusOff;

  /// No description provided for @playerLoadingProgram.
  ///
  /// In fr, this message translates to:
  /// **'Programme en cours de chargement…'**
  String get playerLoadingProgram;

  /// No description provided for @audioNightHelp.
  ///
  /// In fr, this message translates to:
  /// **'L’optimisation sonore s’applique au moteur natif lorsque Night Focus est activé. Les réglages sont conservés pour la prochaine lecture.'**
  String get audioNightHelp;

  /// No description provided for @audioNightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation nocturne (Night Focus)'**
  String get audioNightTitle;

  /// No description provided for @audioDialogueBoost.
  ///
  /// In fr, this message translates to:
  /// **'Amplification des dialogues'**
  String get audioDialogueBoost;

  /// No description provided for @audioDialogueHelp.
  ///
  /// In fr, this message translates to:
  /// **'Rehausse la plage spectrale des voix (1–4 kHz)'**
  String get audioDialogueHelp;

  /// No description provided for @audioBassLimiter.
  ///
  /// In fr, this message translates to:
  /// **'Réduction des basses et limiteur'**
  String get audioBassLimiter;

  /// No description provided for @audioBassHelp.
  ///
  /// In fr, this message translates to:
  /// **'Atténue les basses profondes et compresse les surcharges soudaines'**
  String get audioBassHelp;

  /// No description provided for @audioVocalGain.
  ///
  /// In fr, this message translates to:
  /// **'Amplification des voix :'**
  String get audioVocalGain;

  /// No description provided for @audioSyncTitle.
  ///
  /// In fr, this message translates to:
  /// **'Décalage audio (synchronisation A/V)'**
  String get audioSyncTitle;

  /// No description provided for @startupResumeQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre « {title} » à {position} ?'**
  String startupResumeQuestion(String title, String position);

  /// No description provided for @startupLastSession.
  ///
  /// In fr, this message translates to:
  /// **'Dernière session'**
  String get startupLastSession;

  /// No description provided for @seriesExternalTracksHint.
  ///
  /// In fr, this message translates to:
  /// **'Avec un lecteur externe, choisissez les pistes audio et les sous-titres dans ce lecteur. Les préférences ci-dessous s’appliquent au lecteur interne.'**
  String get seriesExternalTracksHint;

  /// No description provided for @seriesResetWatchedBody.
  ///
  /// In fr, this message translates to:
  /// **'Les {count} épisodes vus de « {title} » seront marqués comme non vus pour ce profil.'**
  String seriesResetWatchedBody(int count, String title);

  /// No description provided for @seriesResetWatchedDone.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » retiré des déjà vus.'**
  String seriesResetWatchedDone(String title);

  /// No description provided for @recommendationAffinity.
  ///
  /// In fr, this message translates to:
  /// **'Affinité'**
  String get recommendationAffinity;

  /// No description provided for @recommendationLoadingCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du catalogue en cours…'**
  String get recommendationLoadingCatalog;

  /// No description provided for @recommendationBuilding.
  ///
  /// In fr, this message translates to:
  /// **'Construction de vos recommandations en cours…'**
  String get recommendationBuilding;

  /// No description provided for @recommendationLoadingDuration.
  ///
  /// In fr, this message translates to:
  /// **'Cela peut prendre jusqu\'à 1 minute.'**
  String get recommendationLoadingDuration;

  /// No description provided for @memoryPanelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire et cache'**
  String get memoryPanelTitle;

  /// No description provided for @memoryPanelHelp.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyez l’historique et le cache d’images en mémoire.'**
  String get memoryPanelHelp;

  /// No description provided for @memoryHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Effacer l’historique des vues'**
  String get memoryHistoryTitle;

  /// No description provided for @memoryHistoryHelp.
  ///
  /// In fr, this message translates to:
  /// **'Efface l’historique global et les anciens éléments récents, ainsi que les contenus récents et les positions de reprise du profil courant.'**
  String get memoryHistoryHelp;

  /// No description provided for @memoryClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get memoryClear;

  /// No description provided for @memoryImagesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider le cache d’images en mémoire'**
  String get memoryImagesTitle;

  /// No description provided for @memoryImagesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Libère les images mises en cache en mémoire ; les fichiers en cache sur disque sont conservés.'**
  String get memoryImagesHelp;

  /// No description provided for @memoryPurge.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get memoryPurge;

  /// No description provided for @sortOptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Options de tri avancé'**
  String get sortOptionsTitle;

  /// No description provided for @sortOptionsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un mode avec la télécommande :'**
  String get sortOptionsHelp;

  /// No description provided for @sortRecentDescription.
  ///
  /// In fr, this message translates to:
  /// **'Contenus importés récemment dans la liste'**
  String get sortRecentDescription;

  /// No description provided for @sortResumeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Place les contenus commencés non terminés en haut'**
  String get sortResumeDescription;

  /// No description provided for @sortRatingDescription.
  ///
  /// In fr, this message translates to:
  /// **'Classement selon les notes attribuées'**
  String get sortRatingDescription;

  /// No description provided for @sortYearDescription.
  ///
  /// In fr, this message translates to:
  /// **'Tri chronologique par année de production'**
  String get sortYearDescription;

  /// No description provided for @sortDurationDescription.
  ///
  /// In fr, this message translates to:
  /// **'Tri par durée du contenu'**
  String get sortDurationDescription;

  /// No description provided for @sortActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get sortActive;

  /// No description provided for @onboardingWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Orbit IPTV'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration automatique de votre appareil'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingDeviceDetected.
  ///
  /// In fr, this message translates to:
  /// **'Appareil détecté'**
  String get onboardingDeviceDetected;

  /// No description provided for @onboardingDevice.
  ///
  /// In fr, this message translates to:
  /// **'Appareil'**
  String get onboardingDevice;

  /// No description provided for @onboardingConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get onboardingConnection;

  /// No description provided for @onboardingMobileNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Réseau mobile'**
  String get onboardingMobileNetwork;

  /// No description provided for @onboardingOtherNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get onboardingOtherNetwork;

  /// No description provided for @onboardingUnknownMemory.
  ///
  /// In fr, this message translates to:
  /// **'Inconnue'**
  String get onboardingUnknownMemory;

  /// No description provided for @onboardingMemoryMb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Mo'**
  String onboardingMemoryMb(String value);

  /// No description provided for @onboardingMemoryGb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Go'**
  String onboardingMemoryGb(String value);

  /// No description provided for @onboardingEco.
  ///
  /// In fr, this message translates to:
  /// **'Économique'**
  String get onboardingEco;

  /// No description provided for @onboardingProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil {name}'**
  String onboardingProfile(String name);

  /// No description provided for @onboardingEcoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage rapide (1,5 s) · max 1080p · 3D désactivée · multi-vue désactivée'**
  String get onboardingEcoDescription;

  /// No description provided for @onboardingStandardDescription.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage rapide (2 s) · rendu 3D fluide · multi-vue x2'**
  String get onboardingStandardDescription;

  /// No description provided for @onboardingUltraDescription.
  ///
  /// In fr, this message translates to:
  /// **'Zapping rapide (3 s · 4K HDR possible) · multi-vue x4'**
  String get onboardingUltraDescription;

  /// No description provided for @onboardingResetRecommendation.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la recommandation'**
  String get onboardingResetRecommendation;

  /// No description provided for @onboardingAdjust.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster manuellement'**
  String get onboardingAdjust;

  /// No description provided for @onboardingChooseProfile.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un profil'**
  String get onboardingChooseProfile;

  /// No description provided for @onboardingRecommendedProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil recommandé'**
  String get onboardingRecommendedProfile;

  /// No description provided for @onboardingEcoHint.
  ///
  /// In fr, this message translates to:
  /// **'Effets 3D et multi-vue désactivés.'**
  String get onboardingEcoHint;

  /// No description provided for @duoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode Duo'**
  String get duoTitle;

  /// No description provided for @duoChooseOthers.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez 1 à {max} profil(s) supplémentaire(s)'**
  String duoChooseOthers(int max);

  /// No description provided for @duoChooseWith.
  ///
  /// In fr, this message translates to:
  /// **'Avec « {name} » — choisissez 1 à {max} autre(s) profil(s)'**
  String duoChooseWith(String name, int max);

  /// No description provided for @duoCreateProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créez au moins un 2e profil'**
  String get duoCreateProfile;

  /// No description provided for @duoNeedsProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Le mode Duo nécessite au moins 2 profils au total.'**
  String get duoNeedsProfiles;

  /// No description provided for @duoFull.
  ///
  /// In fr, this message translates to:
  /// **'4 profils — équipe complète pour le Duo'**
  String get duoFull;

  /// No description provided for @duoReady.
  ///
  /// In fr, this message translates to:
  /// **'{count} profils sélectionnés — prêt pour le Duo'**
  String duoReady(int count);

  /// No description provided for @duoSelectOne.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au moins 1 profil supplémentaire ({count}/4)'**
  String duoSelectOne(int count);

  /// No description provided for @duoStart.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le Duo'**
  String get duoStart;

  /// No description provided for @duoSelected.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionné'**
  String get duoSelected;

  /// No description provided for @duoMaximum.
  ///
  /// In fr, this message translates to:
  /// **'Max atteint'**
  String get duoMaximum;

  /// No description provided for @legalIntroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Orbit IPTV · Lisez-moi'**
  String get legalIntroTitle;

  /// No description provided for @legalIntro.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour ! Avant de commencer, quelques informations courtes sur l’usage de cette application et les droits associés aux contenus affichés.'**
  String get legalIntro;

  /// No description provided for @legalServicePlayer.
  ///
  /// In fr, this message translates to:
  /// **'Orbit IPTV est un lecteur IPTV : il affiche des flux fournis par des serveurs tiers (abonnement M3U / Xtream Codes) sans héberger aucun contenu vidéo, audio ou sous-titre.'**
  String get legalServicePlayer;

  /// No description provided for @legalServiceMetadata.
  ///
  /// In fr, this message translates to:
  /// **'Il agrège et présente des métadonnées (affiches, synopsis, EPG) récupérées via des API publiques. Il fonctionne comme un navigateur spécialisé pour les flux HLS/DASH.'**
  String get legalServiceMetadata;

  /// No description provided for @legalRightsProvider.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur d’abonnement IPTV est seul responsable des licences des chaînes, des droits de diffusion et du géoblocage des flux qu’il fournit.'**
  String get legalRightsProvider;

  /// No description provided for @legalRightsMetadata.
  ///
  /// In fr, this message translates to:
  /// **'Les affiches et synopsis proviennent de TMDb sous licence API ; l’attribution TMDb est affichée en bas de page des classements.'**
  String get legalRightsMetadata;

  /// No description provided for @legalRightsContent.
  ///
  /// In fr, this message translates to:
  /// **'Orbit IPTV ne stocke, ne redistribue et ne monétise aucun contenu diffusé.'**
  String get legalRightsContent;

  /// No description provided for @legalUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Usage de l’application'**
  String get legalUsageTitle;

  /// No description provided for @legalUsageRights.
  ///
  /// In fr, this message translates to:
  /// **'À utiliser uniquement avec un abonnement dont vous détenez les droits de diffusion.'**
  String get legalUsageRights;

  /// No description provided for @legalUsageRestrictions.
  ///
  /// In fr, this message translates to:
  /// **'Interdiction de contourner le géoblocage ou les DRM, et de partager son compte hors du foyer.'**
  String get legalUsageRestrictions;

  /// No description provided for @legalUsageEditorial.
  ///
  /// In fr, this message translates to:
  /// **'L’application ne fait aucune sélection éditoriale du contenu diffusé : aucun contrôle sur les flux des serveurs tiers.'**
  String get legalUsageEditorial;

  /// No description provided for @legalPrivacyStorage.
  ///
  /// In fr, this message translates to:
  /// **'Profils, favoris, historique et réglages sont stockés localement. Si vous activez le partage cloud, les données sélectionnées sont également synchronisées de façon chiffrée.'**
  String get legalPrivacyStorage;

  /// No description provided for @legalPrivacyConsent.
  ///
  /// In fr, this message translates to:
  /// **'Aucune collecte par défaut : notifications et accès optionnels font l’objet d’un consentement explicite.'**
  String get legalPrivacyConsent;

  /// No description provided for @legalWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get legalWarningTitle;

  /// No description provided for @legalWarningBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce document ne constitue pas un conseil juridique. Les règles varient selon les juridictions : vérifiez que votre usage est autorisé dans votre pays (loi applicable, âge minimum).'**
  String get legalWarningBody;

  /// No description provided for @legalAccept.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai lu et j\'accepte · Continuer'**
  String get legalAccept;

  /// No description provided for @epgReplayAvailableOnChannel.
  ///
  /// In fr, this message translates to:
  /// **'Replay disponible sur cette chaîne'**
  String get epgReplayAvailableOnChannel;

  /// No description provided for @actorBornOn.
  ///
  /// In fr, this message translates to:
  /// **'Né(e) le {date}'**
  String actorBornOn(String date);

  /// No description provided for @actorGenderMale.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get actorGenderMale;

  /// No description provided for @actorGenderFemale.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get actorGenderFemale;

  /// No description provided for @crewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équipe technique'**
  String get crewTitle;

  /// No description provided for @crewDirecting.
  ///
  /// In fr, this message translates to:
  /// **'Réalisation'**
  String get crewDirecting;

  /// No description provided for @crewWriting.
  ///
  /// In fr, this message translates to:
  /// **'Scénario'**
  String get crewWriting;

  /// No description provided for @crewProduction.
  ///
  /// In fr, this message translates to:
  /// **'Production'**
  String get crewProduction;

  /// No description provided for @crewSound.
  ///
  /// In fr, this message translates to:
  /// **'Son'**
  String get crewSound;

  /// No description provided for @crewCamera.
  ///
  /// In fr, this message translates to:
  /// **'Image'**
  String get crewCamera;

  /// No description provided for @crewEditing.
  ///
  /// In fr, this message translates to:
  /// **'Montage'**
  String get crewEditing;

  /// No description provided for @crewArt.
  ///
  /// In fr, this message translates to:
  /// **'Direction artistique'**
  String get crewArt;

  /// No description provided for @crewCostume.
  ///
  /// In fr, this message translates to:
  /// **'Costumes et maquillage'**
  String get crewCostume;

  /// No description provided for @crewVisualEffects.
  ///
  /// In fr, this message translates to:
  /// **'Effets visuels'**
  String get crewVisualEffects;

  /// No description provided for @crewLighting.
  ///
  /// In fr, this message translates to:
  /// **'Éclairage'**
  String get crewLighting;

  /// No description provided for @menuContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get menuContinue;

  /// No description provided for @menuDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get menuDiscover;

  /// No description provided for @menuHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get menuHome;

  /// No description provided for @menuSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get menuSearch;

  /// No description provided for @menuProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get menuProfile;

  /// No description provided for @menuSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get menuSubscriptions;

  /// No description provided for @menuSelect.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un sous-menu'**
  String get menuSelect;

  /// No description provided for @menuContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenus'**
  String get menuContent;

  /// No description provided for @profileMustKeepOne.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un profil doit rester sur l\'appareil'**
  String get profileMustKeepOne;

  /// No description provided for @profileDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » et ses préférences seront supprimés définitivement. Cette action est irréversible.'**
  String profileDeleteBody(String name);

  /// No description provided for @profileChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer de profil'**
  String get profileChange;

  /// No description provided for @profileEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get profileEdit;

  /// No description provided for @profileDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get profileDelete;

  /// No description provided for @profileBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get profileBack;

  /// No description provided for @profileAdult.
  ///
  /// In fr, this message translates to:
  /// **'adulte'**
  String get profileAdult;

  /// No description provided for @profileChild.
  ///
  /// In fr, this message translates to:
  /// **'enfant'**
  String get profileChild;

  /// No description provided for @profileExpert.
  ///
  /// In fr, this message translates to:
  /// **'expert'**
  String get profileExpert;

  /// No description provided for @categoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categoryTitle;

  /// No description provided for @categoryShowAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout afficher'**
  String get categoryShowAll;

  /// No description provided for @categoryScanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Analyse impossible : le panel ne répond pas.'**
  String get categoryScanFailed;

  /// No description provided for @categoryEmptyLive.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie Live TV sur ce panel.'**
  String get categoryEmptyLive;

  /// No description provided for @categoryEmptyMovies.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie Films sur ce panel.'**
  String get categoryEmptyMovies;

  /// No description provided for @categoryEmptySeries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie Séries sur ce panel.'**
  String get categoryEmptySeries;

  /// No description provided for @categoryHidden.
  ///
  /// In fr, this message translates to:
  /// **'{label} ({count} masquées)'**
  String categoryHidden(String label, int count);

  /// No description provided for @categoryNeverScanned.
  ///
  /// In fr, this message translates to:
  /// **'Jamais analysé'**
  String get categoryNeverScanned;

  /// No description provided for @categoryScannedToday.
  ///
  /// In fr, this message translates to:
  /// **'Analysé aujourd\'hui'**
  String get categoryScannedToday;

  /// No description provided for @categoryScannedYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Analysé hier'**
  String get categoryScannedYesterday;

  /// No description provided for @categoryScannedDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Analysé il y a {days} jours'**
  String categoryScannedDaysAgo(int days);

  /// No description provided for @categorySubscriptionSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages propres à cet abonnement — {status}'**
  String categorySubscriptionSettings(String status);

  /// No description provided for @categoryScanning.
  ///
  /// In fr, this message translates to:
  /// **'Analyse…'**
  String get categoryScanning;

  /// No description provided for @categoryRescan.
  ///
  /// In fr, this message translates to:
  /// **'Réanalyser les catégories'**
  String get categoryRescan;

  /// No description provided for @categoryChannelsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} chaînes'**
  String categoryChannelsCount(int count);

  /// No description provided for @categoryTitlesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} titres'**
  String categoryTitlesCount(int count);

  /// No description provided for @liveWatchAction.
  ///
  /// In fr, this message translates to:
  /// **'Regarder'**
  String get liveWatchAction;

  /// No description provided for @livePreviewDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu vidéo désactivé. Appuie sur « regarder » pour ouvrir la chaîne.'**
  String get livePreviewDisabled;

  /// No description provided for @livePreviewFrozen.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu figé'**
  String get livePreviewFrozen;

  /// No description provided for @livePreviewRetry.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get livePreviewRetry;

  /// No description provided for @episodeMarkWatchedFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de marquer cet épisode comme vu.'**
  String get episodeMarkWatchedFailed;

  /// No description provided for @episodeAlreadyWatched.
  ///
  /// In fr, this message translates to:
  /// **'Épisode déjà vu'**
  String get episodeAlreadyWatched;

  /// No description provided for @episodeMarkWatched.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme vu'**
  String get episodeMarkWatched;

  /// No description provided for @episodeResumeAt.
  ///
  /// In fr, this message translates to:
  /// **'Repris à {position}'**
  String episodeResumeAt(String position);

  /// No description provided for @episodeActionsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez OK pour marquer comme vu ou réinitialiser.'**
  String get episodeActionsHelp;

  /// No description provided for @episodesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 épisode} other{{count} épisodes}}'**
  String episodesCount(int count);

  /// No description provided for @episodesInProgress.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 épisode en cours} other{{count} épisodes en cours}}'**
  String episodesInProgress(int count);

  /// No description provided for @episodesWatchedCount.
  ///
  /// In fr, this message translates to:
  /// **'{seen}/{total} vus'**
  String episodesWatchedCount(int seen, int total);

  /// No description provided for @episodeWatched.
  ///
  /// In fr, this message translates to:
  /// **'Vu'**
  String get episodeWatched;

  /// No description provided for @homeRefreshFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la mise à jour : aucune source n\'a répondu.'**
  String get homeRefreshFailed;

  /// No description provided for @homeRefreshDone.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour terminée.'**
  String get homeRefreshDone;

  /// No description provided for @homeRefreshEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour terminée, aucune donnée disponible.'**
  String get homeRefreshEmpty;

  /// No description provided for @homeChangeSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Changer d’abonnement'**
  String get homeChangeSubscription;

  /// No description provided for @homeNoSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abo'**
  String get homeNoSubscription;

  /// No description provided for @homeAddOrChangeSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ou changer d’abonnement'**
  String get homeAddOrChangeSubscription;

  /// No description provided for @homeMultiStream.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 4 flux à la fois'**
  String get homeMultiStream;

  /// No description provided for @homeRadioStations.
  ///
  /// In fr, this message translates to:
  /// **'Stations en direct'**
  String get homeRadioStations;

  /// No description provided for @homeRefreshUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour inconnue'**
  String get homeRefreshUnknown;

  /// No description provided for @homeRefreshMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour il y a {minutes} min'**
  String homeRefreshMinutes(int minutes);

  /// No description provided for @catalogAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get catalogAll;

  /// No description provided for @catalogUngrouped.
  ///
  /// In fr, this message translates to:
  /// **'Non groupé'**
  String get catalogUngrouped;

  /// No description provided for @catalogSort.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get catalogSort;

  /// No description provided for @browseLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get browseLoading;

  /// No description provided for @startupRadio.
  ///
  /// In fr, this message translates to:
  /// **'Radios'**
  String get startupRadio;

  /// No description provided for @profileCreateFirstHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton premier profil pour commencer à regarder.'**
  String get profileCreateFirstHint;

  /// No description provided for @downloadDirectoryMissing.
  ///
  /// In fr, this message translates to:
  /// **'Répertoire introuvable : {path}'**
  String downloadDirectoryMissing(String path);

  /// No description provided for @downloadFileMissing.
  ///
  /// In fr, this message translates to:
  /// **'Fichier introuvable : {path}. Fichiers présents : {names}'**
  String downloadFileMissing(String path, String names);

  /// No description provided for @widevineSelectSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un abonnement actif'**
  String get widevineSelectSubscription;

  /// No description provided for @widevineLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la configuration'**
  String get widevineLoading;

  /// No description provided for @widevineLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la configuration'**
  String get widevineLoadFailed;

  /// No description provided for @widevineNoLicense.
  ///
  /// In fr, this message translates to:
  /// **'{subscription} : aucune licence configurée'**
  String widevineNoLicense(String subscription);

  /// No description provided for @widevineSelectFirst.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez d’abord un abonnement actif.'**
  String get widevineSelectFirst;

  /// No description provided for @widevineUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La configuration Widevine n’est pas disponible.'**
  String get widevineUnavailable;

  /// No description provided for @widevineSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer Widevine : {error}'**
  String widevineSaveFailed(String error);

  /// No description provided for @widevineClearFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’effacer Widevine : {error}'**
  String widevineClearFailed(String error);

  /// No description provided for @widevineLicenseUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL du serveur de licence'**
  String get widevineLicenseUrl;

  /// No description provided for @widevineInvalidUrl.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une URL HTTPS valide.'**
  String get widevineInvalidUrl;

  /// No description provided for @widevineHeaders.
  ///
  /// In fr, this message translates to:
  /// **'En-têtes HTTP (JSON, facultatif)'**
  String get widevineHeaders;

  /// No description provided for @widevineInvalidHeaders.
  ///
  /// In fr, this message translates to:
  /// **'Les en-têtes doivent être un objet JSON de chaînes.'**
  String get widevineInvalidHeaders;

  /// No description provided for @widevineCertificate.
  ///
  /// In fr, this message translates to:
  /// **'Certificat base64 (facultatif)'**
  String get widevineCertificate;

  /// No description provided for @widevineStorageHelp.
  ///
  /// In fr, this message translates to:
  /// **'La configuration est stockée dans le coffre sécurisé. Elle est liée à cet abonnement. Elle ne rend pas compatible un moteur de lecture qui ne prend pas en charge Widevine.'**
  String get widevineStorageHelp;

  /// No description provided for @widevineCopyLegacy.
  ///
  /// In fr, this message translates to:
  /// **'Copier l’ancienne configuration globale'**
  String get widevineCopyLegacy;

  /// No description provided for @widevineClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get widevineClear;

  /// No description provided for @preferenceMultiTvFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer le réglage Multi TV.'**
  String get preferenceMultiTvFailed;

  /// No description provided for @preferenceLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get preferenceLight;

  /// No description provided for @preferenceDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get preferenceDark;

  /// No description provided for @preferenceDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get preferenceDisabled;

  /// No description provided for @preferenceParentalEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Activé · Restriction {restriction}'**
  String preferenceParentalEnabled(String restriction);

  /// No description provided for @preferenceMultiTvHelp.
  ///
  /// In fr, this message translates to:
  /// **'Afficher et autoriser la lecture multi-écran pour ce profil.'**
  String get preferenceMultiTvHelp;

  /// No description provided for @preferenceAllowRecording.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser l’enregistrement'**
  String get preferenceAllowRecording;

  /// No description provided for @preferenceRecordingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Permettre l’enregistrement de mes contenus favoris'**
  String get preferenceRecordingHelp;

  /// No description provided for @preferenceLivePreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu vidéo en direct'**
  String get preferenceLivePreview;

  /// No description provided for @preferenceLivePreviewHelp.
  ///
  /// In fr, this message translates to:
  /// **'Affiche le direct dans la navigation Live. Réglage commun à cet appareil.'**
  String get preferenceLivePreviewHelp;

  /// No description provided for @preferenceProfileHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vos préférences sont appliquées à votre profil.'**
  String get preferenceProfileHelp;

  /// No description provided for @parentalAgeLimit.
  ///
  /// In fr, this message translates to:
  /// **'Restriction d’âge'**
  String get parentalAgeLimit;

  /// No description provided for @parentalNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get parentalNone;

  /// No description provided for @parentalHideAdult.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le contenu adulte'**
  String get parentalHideAdult;

  /// No description provided for @parentalHideAdultHelp.
  ///
  /// In fr, this message translates to:
  /// **'Films/Séries/Chaînes classés 18+ ou érotique'**
  String get parentalHideAdultHelp;

  /// No description provided for @parentalHideViolence.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la violence'**
  String get parentalHideViolence;

  /// No description provided for @parentalHideViolenceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Contenus Gore / Horreur / Thriller / Meurtre'**
  String get parentalHideViolenceHelp;

  /// No description provided for @parentalCurrentPin.
  ///
  /// In fr, this message translates to:
  /// **'PIN actuel : ••••'**
  String get parentalCurrentPin;

  /// No description provided for @parentalSetPin.
  ///
  /// In fr, this message translates to:
  /// **'Définir un code PIN'**
  String get parentalSetPin;

  /// No description provided for @parentalNewPin.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau PIN (4 chiffres)'**
  String get parentalNewPin;

  /// No description provided for @parentalPin.
  ///
  /// In fr, this message translates to:
  /// **'PIN (4 chiffres)'**
  String get parentalPin;

  /// No description provided for @parentalShowPin.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le PIN'**
  String get parentalShowPin;

  /// No description provided for @parentalHidePin.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le PIN'**
  String get parentalHidePin;

  /// No description provided for @parentalUpdatePin.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le PIN'**
  String get parentalUpdatePin;

  /// No description provided for @subtitleAvailableTracks.
  ///
  /// In fr, this message translates to:
  /// **'Pistes disponibles'**
  String get subtitleAvailableTracks;

  /// No description provided for @subtitleAddUrl.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un sous-titre (URL .srt/.vtt)'**
  String get subtitleAddUrl;

  /// No description provided for @subtitleLoadAction.
  ///
  /// In fr, this message translates to:
  /// **'Charger'**
  String get subtitleLoadAction;

  /// No description provided for @subtitleTrackCues.
  ///
  /// In fr, this message translates to:
  /// **'{language} · {count} segments'**
  String subtitleTrackCues(String language, int count);

  /// No description provided for @multiMaxStreams.
  ///
  /// In fr, this message translates to:
  /// **'Maximum : {count} flux sur cet appareil.'**
  String multiMaxStreams(int count);

  /// No description provided for @multiDisabledProfile.
  ///
  /// In fr, this message translates to:
  /// **'Multi TV est désactivée pour ce profil. Activez-la dans les préférences du profil.'**
  String get multiDisabledProfile;

  /// No description provided for @multiAnalyzingDevice.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de l’appareil…'**
  String get multiAnalyzingDevice;

  /// No description provided for @multiDeviceAnalysisFailed.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de l’appareil impossible'**
  String get multiDeviceAnalysisFailed;

  /// No description provided for @multiDisabledEconomy.
  ///
  /// In fr, this message translates to:
  /// **'Multi-vue désactivée par le profil Économique.\nRéglez le profil dans Configurer l’appareil.'**
  String get multiDisabledEconomy;

  /// No description provided for @engineInternal.
  ///
  /// In fr, this message translates to:
  /// **'{name} (Interne)'**
  String engineInternal(String name);

  /// No description provided for @engineExternal.
  ///
  /// In fr, this message translates to:
  /// **'{name} (Externe)'**
  String engineExternal(String name);

  /// No description provided for @engineSelectionHelp.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le moteur utilisé pour chaque type de contenu, ainsi que le moteur de secours en cas d’échec de lecture.'**
  String get engineSelectionHelp;

  /// No description provided for @engineVideoDecoding.
  ///
  /// In fr, this message translates to:
  /// **'Décodage vidéo'**
  String get engineVideoDecoding;

  /// No description provided for @engineAutoRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Auto (recommandé)'**
  String get engineAutoRecommended;

  /// No description provided for @engineHardware.
  ///
  /// In fr, this message translates to:
  /// **'Matériel'**
  String get engineHardware;

  /// No description provided for @engineSoftware.
  ///
  /// In fr, this message translates to:
  /// **'Logiciel'**
  String get engineSoftware;

  /// No description provided for @engineAutoSoftware.
  ///
  /// In fr, this message translates to:
  /// **'Auto : logiciel retenu pour cet appareil'**
  String get engineAutoSoftware;

  /// No description provided for @engineSubtitleDefault.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut'**
  String get engineSubtitleDefault;

  /// No description provided for @engineSubtitleDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Sans sous-titres'**
  String get engineSubtitleDisabled;

  /// No description provided for @engineSubtitleForced.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres forcés'**
  String get engineSubtitleForced;

  /// No description provided for @engineVodSubtitles.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres des films et séries'**
  String get engineVodSubtitles;

  /// No description provided for @profilePinsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil ne possède de code PIN.'**
  String get profilePinsNone;

  /// No description provided for @profilePinsRemoveQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les codes PIN des profils ?'**
  String get profilePinsRemoveQuestion;

  /// No description provided for @profilePinsRemoveConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Les codes PIN seront retirés de {count} profil(s). Les profils et leurs données resteront sur cet appareil. Les changements pourront être synchronisés avec les appareils partagés dans le Cloud.'**
  String profilePinsRemoveConfirmation(int count);

  /// No description provided for @profilePinsRemove.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les PIN'**
  String get profilePinsRemove;

  /// No description provided for @profilePinsNothingToRemove.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code PIN à supprimer.'**
  String get profilePinsNothingToRemove;

  /// No description provided for @profilePinsRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Codes PIN supprimés de {count} profil(s).'**
  String profilePinsRemoved(int count);

  /// No description provided for @profilePinsRemoveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer les codes PIN. Réessayez.'**
  String get profilePinsRemoveFailed;

  /// No description provided for @profilePinsLocked.
  ///
  /// In fr, this message translates to:
  /// **'Un profil est temporairement bloqué après trois codes PIN incorrects. Attendez la fin du blocage avant de modifier ou supprimer son PIN.'**
  String get profilePinsLocked;

  /// No description provided for @profileProtection.
  ///
  /// In fr, this message translates to:
  /// **'Protection des profils'**
  String get profileProtection;

  /// No description provided for @profilePinsRemoveHelp.
  ///
  /// In fr, this message translates to:
  /// **'Retirez les codes PIN de tous les profils de cet appareil. Les profils et leurs données ne seront pas supprimés.'**
  String get profilePinsRemoveHelp;

  /// No description provided for @profilePinsRemoving.
  ///
  /// In fr, this message translates to:
  /// **'Suppression des PIN…'**
  String get profilePinsRemoving;

  /// No description provided for @profilePinsRemoveAll.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les codes PIN des profils'**
  String get profilePinsRemoveAll;

  /// No description provided for @radioEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute des stations de radio dans les réglages.'**
  String get radioEmptyHint;

  /// No description provided for @radioStations.
  ///
  /// In fr, this message translates to:
  /// **'Stations'**
  String get radioStations;

  /// No description provided for @radioStationsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 station} other{{count} stations}}'**
  String radioStationsCount(int count);

  /// No description provided for @radioStreamUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Flux radio indisponible sur cette station'**
  String get radioStreamUnavailable;

  /// No description provided for @livePreviousCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie précédente'**
  String get livePreviousCategory;

  /// No description provided for @liveNextCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie suivante'**
  String get liveNextCategory;

  /// No description provided for @liveGuideUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Guide indisponible'**
  String get liveGuideUnavailable;

  /// No description provided for @liveNoPrograms.
  ///
  /// In fr, this message translates to:
  /// **'Aucun programme disponible'**
  String get liveNoPrograms;

  /// No description provided for @liveNoUpcomingPrograms.
  ///
  /// In fr, this message translates to:
  /// **'Aucun programme à venir'**
  String get liveNoUpcomingPrograms;

  /// No description provided for @liveNoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résumé disponible.'**
  String get liveNoDescription;

  /// No description provided for @recommendationSubscriptionChanged.
  ///
  /// In fr, this message translates to:
  /// **'L’abonnement a changé. Recommencez.'**
  String get recommendationSubscriptionChanged;

  /// No description provided for @recommendationCannotFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu ne peut pas être ajouté aux favoris.'**
  String get recommendationCannotFavorite;

  /// No description provided for @recommendationFavoriteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ajouter ce contenu aux favoris.'**
  String get recommendationFavoriteFailed;

  /// No description provided for @recommendationMovieQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Ce film vous appartient ?'**
  String get recommendationMovieQuestion;

  /// No description provided for @recommendationSeriesQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Cette série vous appartient ?'**
  String get recommendationSeriesQuestion;

  /// No description provided for @recommendationMovieSeen.
  ///
  /// In fr, this message translates to:
  /// **'Film déjà vu'**
  String get recommendationMovieSeen;

  /// No description provided for @recommendationSeriesSeen.
  ///
  /// In fr, this message translates to:
  /// **'Série déjà vue'**
  String get recommendationSeriesSeen;

  /// No description provided for @recommendationRemovedFuture.
  ///
  /// In fr, this message translates to:
  /// **'Retiré des prochaines suggestions'**
  String get recommendationRemovedFuture;

  /// No description provided for @recommendationNotInterested.
  ///
  /// In fr, this message translates to:
  /// **'Pas intéressé'**
  String get recommendationNotInterested;

  /// No description provided for @recommendationExcluded.
  ///
  /// In fr, this message translates to:
  /// **'Écarté définitivement des suggestions'**
  String get recommendationExcluded;

  /// No description provided for @recommendationFavoriteProfile.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté aux favoris du profil actuel'**
  String get recommendationFavoriteProfile;

  /// No description provided for @startupParsingPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de la playlist M3U en cours…'**
  String get startupParsingPlaylist;

  /// No description provided for @startupProviderSlow.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur répond lentement (vérification de sécurité possible). Merci de patienter…'**
  String get startupProviderSlow;

  /// No description provided for @startupLoadingRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des radios et replays'**
  String get startupLoadingRemaining;

  /// No description provided for @startupLoadingInitial.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du direct, des films, séries et du guide TV'**
  String get startupLoadingInitial;

  /// No description provided for @startupCheckingSubscription.
  ///
  /// In fr, this message translates to:
  /// **'La vérification de l’abonnement'**
  String get startupCheckingSubscription;

  /// No description provided for @startupRefresh.
  ///
  /// In fr, this message translates to:
  /// **'La mise à jour'**
  String get startupRefresh;

  /// No description provided for @startupStalled.
  ///
  /// In fr, this message translates to:
  /// **'{step} ne signale aucune progression depuis {seconds} secondes. Le serveur peut être lent ou indisponible.'**
  String startupStalled(String step, int seconds);

  /// No description provided for @startupRefreshStalled.
  ///
  /// In fr, this message translates to:
  /// **'{step} ne signale aucune progression depuis {seconds} secondes. Le serveur peut être lent ou indisponible ; vous pouvez vérifier l’abonnement.'**
  String startupRefreshStalled(String step, int seconds);

  /// No description provided for @startupMovies.
  ///
  /// In fr, this message translates to:
  /// **'Films & VOD'**
  String get startupMovies;

  /// No description provided for @startupLive.
  ///
  /// In fr, this message translates to:
  /// **'Chaînes live'**
  String get startupLive;

  /// No description provided for @startupReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt !'**
  String get startupReady;

  /// No description provided for @startupBackHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l’accueil'**
  String get startupBackHome;

  /// No description provided for @startupCheckSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier l’abonnement'**
  String get startupCheckSubscription;

  /// No description provided for @browseRankings.
  ///
  /// In fr, this message translates to:
  /// **'Classements'**
  String get browseRankings;

  /// No description provided for @browsePopularRankings.
  ///
  /// In fr, this message translates to:
  /// **'Classements populaires'**
  String get browsePopularRankings;

  /// No description provided for @browseRankingsUnavailableHint.
  ///
  /// In fr, this message translates to:
  /// **'Les tendances TMDB ne sont pas disponibles. Ajoutez une clé API TMDB dans Réglages (ou TMDB_API_KEY dans assets/config/runtime.env).'**
  String get browseRankingsUnavailableHint;

  /// No description provided for @browseTmdbData.
  ///
  /// In fr, this message translates to:
  /// **'Données © TMDB'**
  String get browseTmdbData;

  /// No description provided for @browsePopular.
  ///
  /// In fr, this message translates to:
  /// **'Populaire'**
  String get browsePopular;

  /// No description provided for @browseNowPlaying.
  ///
  /// In fr, this message translates to:
  /// **'En salle'**
  String get browseNowPlaying;

  /// No description provided for @browseTopRated.
  ///
  /// In fr, this message translates to:
  /// **'Mieux notés'**
  String get browseTopRated;

  /// No description provided for @browseUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get browseUpcoming;

  /// No description provided for @browseTrendingWeek.
  ///
  /// In fr, this message translates to:
  /// **'Tendance de la semaine'**
  String get browseTrendingWeek;

  /// No description provided for @browseOnTheAir.
  ///
  /// In fr, this message translates to:
  /// **'En diffusion'**
  String get browseOnTheAir;

  /// No description provided for @browseAiringToday.
  ///
  /// In fr, this message translates to:
  /// **'Diffusion aujourd’hui'**
  String get browseAiringToday;

  /// No description provided for @browseSeriesType.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get browseSeriesType;

  /// No description provided for @browseSynopsis.
  ///
  /// In fr, this message translates to:
  /// **'Synopsis'**
  String get browseSynopsis;

  /// No description provided for @browseExploreCategories.
  ///
  /// In fr, this message translates to:
  /// **'Explorer par catégorie'**
  String get browseExploreCategories;

  /// No description provided for @browseFavoriteHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie longuement sur un élément pour le retrouver ici.'**
  String get browseFavoriteHint;

  /// No description provided for @browseRecentHint.
  ///
  /// In fr, this message translates to:
  /// **'Les contenus regardés s’afficheront ici.'**
  String get browseRecentHint;

  /// No description provided for @browseSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu ne correspond à cette recherche.'**
  String get browseSearchEmpty;

  /// No description provided for @browseTitlesCount.
  ///
  /// In fr, this message translates to:
  /// **'{visible} titres (sur {total})'**
  String browseTitlesCount(int visible, int total);

  /// No description provided for @catalogSearchMovies.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un film ou un genre…'**
  String get catalogSearchMovies;

  /// No description provided for @catalogSearchSeries.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une série ou un genre…'**
  String get catalogSearchSeries;

  /// No description provided for @catalogLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du catalogue en cours…\nMerci de patienter quelques secondes.'**
  String get catalogLoading;

  /// No description provided for @catalogNoMovies.
  ///
  /// In fr, this message translates to:
  /// **'La bibliothèque VOD est vide pour le moment.'**
  String get catalogNoMovies;

  /// No description provided for @catalogNoSeries.
  ///
  /// In fr, this message translates to:
  /// **'La bibliothèque de séries est vide pour le moment.'**
  String get catalogNoSeries;

  /// No description provided for @catalogNoRecentMovies.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film récent'**
  String get catalogNoRecentMovies;

  /// No description provided for @catalogNoRecentSeries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série récente'**
  String get catalogNoRecentSeries;

  /// No description provided for @catalogNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get catalogNoResults;

  /// No description provided for @catalogNoMoviesInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film dans cette catégorie'**
  String get catalogNoMoviesInCategory;

  /// No description provided for @catalogMovieFavoriteHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur le cœur d\'un film pour le retrouver ici.'**
  String get catalogMovieFavoriteHint;

  /// No description provided for @catalogSeriesFavoriteHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur le cœur d\'une série pour la retrouver ici.'**
  String get catalogSeriesFavoriteHint;

  /// No description provided for @catalogRecentMoviesHint.
  ///
  /// In fr, this message translates to:
  /// **'Les films regardés s\'afficheront ici.'**
  String get catalogRecentMoviesHint;

  /// No description provided for @catalogRecentSeriesHint.
  ///
  /// In fr, this message translates to:
  /// **'Les séries regardées s\'afficheront ici.'**
  String get catalogRecentSeriesHint;

  /// No description provided for @catalogMovieSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film ne correspond à cette recherche.'**
  String get catalogMovieSearchEmpty;

  /// No description provided for @catalogSeriesSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série ne correspond à cette recherche.'**
  String get catalogSeriesSearchEmpty;

  /// No description provided for @catalogMovieCategoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film ne correspond à cette catégorie.'**
  String get catalogMovieCategoryEmpty;

  /// No description provided for @removedFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » retiré des favoris'**
  String removedFromFavorites(String title);

  /// No description provided for @liveBackToChannels.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux chaînes'**
  String get liveBackToChannels;

  /// No description provided for @liveAddSourceHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une source de chaînes dans les réglages.'**
  String get liveAddSourceHint;

  /// No description provided for @liveNoChannelFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne trouvée'**
  String get liveNoChannelFound;

  /// No description provided for @liveNoRecentChannel.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne récente'**
  String get liveNoRecentChannel;

  /// No description provided for @liveNoChannelInGroup.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne dans ce groupe'**
  String get liveNoChannelInGroup;

  /// No description provided for @liveTryAnotherSearch.
  ///
  /// In fr, this message translates to:
  /// **'Essaie un autre terme de recherche.'**
  String get liveTryAnotherSearch;

  /// No description provided for @liveFavoriteHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur le cœur d\'une chaîne pour la retrouver ici.'**
  String get liveFavoriteHint;

  /// No description provided for @liveRecentHint.
  ///
  /// In fr, this message translates to:
  /// **'Les chaînes regardées s\'afficheront ici.'**
  String get liveRecentHint;

  /// No description provided for @liveEmptyGroupHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce groupe ne contient aucune chaîne.'**
  String get liveEmptyGroupHint;

  /// No description provided for @liveLoadingHint.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des chaînes en cours…\nMerci de patienter avant de lancer un flux.'**
  String get liveLoadingHint;

  /// No description provided for @replayNoChannels.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne de cet abonnement ne déclare de catch-up.'**
  String get replayNoChannels;

  /// No description provided for @replayEmptyGroup.
  ///
  /// In fr, this message translates to:
  /// **'Ce groupe ne contient aucune chaîne rejouable.'**
  String get replayEmptyGroup;

  /// No description provided for @epgLoadingBanner.
  ///
  /// In fr, this message translates to:
  /// **'Guide TV en cours de chargement… les programmes apparaîtront dans un instant.'**
  String get epgLoadingBanner;

  /// No description provided for @epgNoChannelsInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne dans cette catégorie'**
  String get epgNoChannelsInCategory;

  /// No description provided for @epgLoadingChannels.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des chaînes…'**
  String get epgLoadingChannels;

  /// No description provided for @epgChannelsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les chaînes.'**
  String get epgChannelsLoadFailed;

  /// No description provided for @replayToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get replayToday;

  /// No description provided for @replayYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get replayYesterday;

  /// No description provided for @searchWithinHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans {type}…'**
  String searchWithinHint(String type);

  /// No description provided for @searchAllHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher Live, Films, Séries, Replay, EPG…'**
  String get searchAllHint;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher…'**
  String get searchHint;

  /// No description provided for @searchWithinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche dans {type}'**
  String searchWithinTitle(String type);

  /// No description provided for @searchUnifiedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche unifiée'**
  String get searchUnifiedTitle;

  /// No description provided for @searchWithinHelp.
  ///
  /// In fr, this message translates to:
  /// **'Tapez pour rechercher uniquement dans {type}.'**
  String searchWithinHelp(String type);

  /// No description provided for @searchUnifiedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Tapez votre recherche pour trouver des chaînes Live, films, séries, replays ou programmes EPG.'**
  String get searchUnifiedHelp;

  /// No description provided for @searchOffline.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne — résultats locaux uniquement'**
  String get searchOffline;

  /// No description provided for @searchResultsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 résultat} other{{count} résultats}}'**
  String searchResultsCount(int count);

  /// No description provided for @searchNoResultsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Essayez avec d\'autres termes ou vérifiez l\'orthographe.'**
  String get searchNoResultsHelp;

  /// No description provided for @searchAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get searchAllCategories;

  /// No description provided for @searchClearHistory.
  ///
  /// In fr, this message translates to:
  /// **'Effacer l\'historique'**
  String get searchClearHistory;

  /// No description provided for @settingsPlaybackEngines.
  ///
  /// In fr, this message translates to:
  /// **'Moteurs de lecture'**
  String get settingsPlaybackEngines;

  /// No description provided for @settingsCloudAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte cloud'**
  String get settingsCloudAccount;

  /// No description provided for @settingsCloudSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google ou e-mail'**
  String get settingsCloudSignIn;

  /// No description provided for @settingsSyncUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation complète indisponible'**
  String get settingsSyncUnavailable;

  /// No description provided for @settingsSyncUnavailableHelp.
  ///
  /// In fr, this message translates to:
  /// **'L’ancienne synchronisation en clair est désactivée. Les fiches de profils peuvent être sauvegardées manuellement depuis Compte cloud ; les autres données ne sont pas synchronisées.'**
  String get settingsSyncUnavailableHelp;

  /// No description provided for @settingsSystemAutomatic.
  ///
  /// In fr, this message translates to:
  /// **'Automatique (Système)'**
  String get settingsSystemAutomatic;

  /// No description provided for @settingsSubtitleDefault.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titrage par défaut'**
  String get settingsSubtitleDefault;

  /// No description provided for @settingsSubtitleForced.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titrage forcé'**
  String get settingsSubtitleForced;

  /// No description provided for @settingsSubtitleOff.
  ///
  /// In fr, this message translates to:
  /// **'Sans sous-titrage'**
  String get settingsSubtitleOff;

  /// No description provided for @settingsSubtitles.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres'**
  String get settingsSubtitles;

  /// No description provided for @settingsProtectedPlayback.
  ///
  /// In fr, this message translates to:
  /// **'Lecture protégée'**
  String get settingsProtectedPlayback;

  /// No description provided for @settingsCategoryFilters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres de catégories'**
  String get settingsCategoryFilters;

  /// No description provided for @settingsCategoryFiltersHelp.
  ///
  /// In fr, this message translates to:
  /// **'Catégories masquées par abonnement'**
  String get settingsCategoryFiltersHelp;

  /// No description provided for @episodeSelectProfile.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un profil pour modifier cet épisode.'**
  String get episodeSelectProfile;

  /// No description provided for @episodeProfileChanged.
  ///
  /// In fr, this message translates to:
  /// **'Le profil a changé. Réessayez.'**
  String get episodeProfileChanged;

  /// No description provided for @episodeStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier le statut de cet épisode.'**
  String get episodeStatusFailed;

  /// No description provided for @episodeResetQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'épisode ?'**
  String get episodeResetQuestion;

  /// No description provided for @episodeMarkWatchedQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme vu ?'**
  String get episodeMarkWatchedQuestion;

  /// No description provided for @episodeResetProgressMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » sera marqué comme non vu et sa progression de lecture sera effacée.'**
  String episodeResetProgressMessage(String title);

  /// No description provided for @episodeMarkUnwatchedMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » sera marqué comme non vu pour ce profil.'**
  String episodeMarkUnwatchedMessage(String title);

  /// No description provided for @episodeMarkWatchedMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » sera marqué comme vu pour ce profil.'**
  String episodeMarkWatchedMessage(String title);

  /// No description provided for @episodeMarkUnwatched.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme non vu'**
  String get episodeMarkUnwatched;

  /// No description provided for @detailAiData.
  ///
  /// In fr, this message translates to:
  /// **'Données générées par IA'**
  String get detailAiData;

  /// No description provided for @detailSourceData.
  ///
  /// In fr, this message translates to:
  /// **'Données {source}'**
  String detailSourceData(String source);

  /// No description provided for @detailUnavailableValue.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible'**
  String get detailUnavailableValue;

  /// No description provided for @detailKeywords.
  ///
  /// In fr, this message translates to:
  /// **'Mots-clés'**
  String get detailKeywords;

  /// No description provided for @detailGenres.
  ///
  /// In fr, this message translates to:
  /// **'Genres'**
  String get detailGenres;

  /// No description provided for @detailCast.
  ///
  /// In fr, this message translates to:
  /// **'Distribution'**
  String get detailCast;

  /// No description provided for @detailTrailerFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la bande-annonce'**
  String get detailTrailerFailed;

  /// No description provided for @detailShowCrew.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'équipe technique'**
  String get detailShowCrew;

  /// No description provided for @detailHideCrew.
  ///
  /// In fr, this message translates to:
  /// **'Masquer l\'équipe technique'**
  String get detailHideCrew;

  /// No description provided for @seriesRuntimePerEpisode.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min/ép'**
  String seriesRuntimePerEpisode(int minutes);

  /// No description provided for @seriesNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Réseau : {network}'**
  String seriesNetwork(String network);

  /// No description provided for @seriesFirstAired.
  ///
  /// In fr, this message translates to:
  /// **'Première diffusion : {date}'**
  String seriesFirstAired(String date);

  /// No description provided for @seriesSeasonsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 saison} other{{count} saisons}}'**
  String seriesSeasonsCount(int count);

  /// No description provided for @profileDiscardHelp.
  ///
  /// In fr, this message translates to:
  /// **'Des modifications non sauvegardées seront perdues. Quitter quand même ?'**
  String get profileDiscardHelp;

  /// No description provided for @profileLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get profileLeave;

  /// No description provided for @profileEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileEditTitle;

  /// No description provided for @profileAvatarTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème d\'avatar'**
  String get profileAvatarTheme;

  /// No description provided for @profileAvatarThemeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un style, puis un avatar dans la grille'**
  String get profileAvatarThemeHelp;

  /// No description provided for @profileAvatars.
  ///
  /// In fr, this message translates to:
  /// **'Avatars'**
  String get profileAvatars;

  /// No description provided for @profileCurrentTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème actuel : {theme}'**
  String profileCurrentTheme(String theme);

  /// No description provided for @profileRequired.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get profileRequired;

  /// No description provided for @profileFavoriteMovieGenres.
  ///
  /// In fr, this message translates to:
  /// **'Genres de films favoris'**
  String get profileFavoriteMovieGenres;

  /// No description provided for @profileGenresHelp.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un ou plusieurs styles pour les recommandations'**
  String get profileGenresHelp;

  /// No description provided for @profilePinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les codes PIN ne correspondent pas.'**
  String get profilePinMismatch;

  /// No description provided for @profilePinCreateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le code PIN.'**
  String get profilePinCreateFailed;

  /// No description provided for @profilePinActive.
  ///
  /// In fr, this message translates to:
  /// **'Un code PIN de 4 chiffres est actif'**
  String get profilePinActive;

  /// No description provided for @profilePinPending.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN confirmé. Enregistrez le profil pour l’activer.'**
  String get profilePinPending;

  /// No description provided for @profilePinRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demander un code PIN à la sélection du profil'**
  String get profilePinRequest;

  /// No description provided for @profilePinCreating.
  ///
  /// In fr, this message translates to:
  /// **'Création du code PIN…'**
  String get profilePinCreating;

  /// No description provided for @profileNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil à modifier'**
  String get profileNotFound;

  /// No description provided for @profileSaveActivate.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer et activer la protection'**
  String get profileSaveActivate;

  /// No description provided for @profileCreateActivate.
  ///
  /// In fr, this message translates to:
  /// **'Créer le profil et activer la protection'**
  String get profileCreateActivate;

  /// No description provided for @profileSaveAction.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get profileSaveAction;

  /// No description provided for @profileCreateAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer le profil'**
  String get profileCreateAction;

  /// No description provided for @genreAction.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get genreAction;

  /// No description provided for @genreAdventure.
  ///
  /// In fr, this message translates to:
  /// **'Aventure'**
  String get genreAdventure;

  /// No description provided for @genreAnimation.
  ///
  /// In fr, this message translates to:
  /// **'Animation'**
  String get genreAnimation;

  /// No description provided for @genreComedy.
  ///
  /// In fr, this message translates to:
  /// **'Comédie'**
  String get genreComedy;

  /// No description provided for @genreRomanticComedy.
  ///
  /// In fr, this message translates to:
  /// **'Comédie romantique'**
  String get genreRomanticComedy;

  /// No description provided for @genreDrama.
  ///
  /// In fr, this message translates to:
  /// **'Drame'**
  String get genreDrama;

  /// No description provided for @genreHorror.
  ///
  /// In fr, this message translates to:
  /// **'Horreur'**
  String get genreHorror;

  /// No description provided for @genreThriller.
  ///
  /// In fr, this message translates to:
  /// **'Thriller'**
  String get genreThriller;

  /// No description provided for @genreDetective.
  ///
  /// In fr, this message translates to:
  /// **'Policier'**
  String get genreDetective;

  /// No description provided for @genreCrime.
  ///
  /// In fr, this message translates to:
  /// **'Crime'**
  String get genreCrime;

  /// No description provided for @genreWar.
  ///
  /// In fr, this message translates to:
  /// **'Guerre'**
  String get genreWar;

  /// No description provided for @genreHistorical.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get genreHistorical;

  /// No description provided for @genreWestern.
  ///
  /// In fr, this message translates to:
  /// **'Western'**
  String get genreWestern;

  /// No description provided for @genreSciFi.
  ///
  /// In fr, this message translates to:
  /// **'Sci-Fi'**
  String get genreSciFi;

  /// No description provided for @genreFantasy.
  ///
  /// In fr, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreSuperheroes.
  ///
  /// In fr, this message translates to:
  /// **'Super-héros'**
  String get genreSuperheroes;

  /// No description provided for @genreMystery.
  ///
  /// In fr, this message translates to:
  /// **'Mystère'**
  String get genreMystery;

  /// No description provided for @genreRomance.
  ///
  /// In fr, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreMusical.
  ///
  /// In fr, this message translates to:
  /// **'Musical'**
  String get genreMusical;

  /// No description provided for @genreMusic.
  ///
  /// In fr, this message translates to:
  /// **'Musique'**
  String get genreMusic;

  /// No description provided for @genreBiopic.
  ///
  /// In fr, this message translates to:
  /// **'Biopic'**
  String get genreBiopic;

  /// No description provided for @genreDocumentary.
  ///
  /// In fr, this message translates to:
  /// **'Documentaire'**
  String get genreDocumentary;

  /// No description provided for @genreTournament.
  ///
  /// In fr, this message translates to:
  /// **'Tournoi'**
  String get genreTournament;

  /// No description provided for @genreChildren.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get genreChildren;

  /// No description provided for @genreFamily.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get genreFamily;

  /// No description provided for @genreSuspense.
  ///
  /// In fr, this message translates to:
  /// **'Suspense'**
  String get genreSuspense;

  /// No description provided for @genreBlackWhite.
  ///
  /// In fr, this message translates to:
  /// **'Noir & Blanc'**
  String get genreBlackWhite;

  /// No description provided for @genreClassic.
  ///
  /// In fr, this message translates to:
  /// **'Classique'**
  String get genreClassic;

  /// No description provided for @cloudConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get cloudConfirm;

  /// No description provided for @cloudShareProfilesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager ces profils ?'**
  String get cloudShareProfilesTitle;

  /// No description provided for @cloudDuplicateProfileId.
  ///
  /// In fr, this message translates to:
  /// **'Même nom — identifiant : {id}'**
  String cloudDuplicateProfileId(String id);

  /// No description provided for @cloudShareProfilesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les profils manquants seront ajoutés sans remplacer ceux qui existent. Leurs favoris et leur activité seront partagés, ainsi que les préférences et abonnements, avec leurs identifiants IPTV. Ces données sont chiffrées.\n\nDeux profils de même nom restent séparés. Si des données sont différentes, vous choisirez lesquelles garder.'**
  String get cloudShareProfilesHelp;

  /// No description provided for @cloudChooseSourceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la source en cas de conflit'**
  String get cloudChooseSourceTitle;

  /// No description provided for @cloudChooseSourceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les ajouts différents seront réunis sur les deux appareils. Si une même donnée a été modifiée des deux côtés, la source choisie ici sera conservée et envoyée à l’autre appareil. Ce choix s’applique à tous les conflits du démarrage.'**
  String get cloudChooseSourceHelp;

  /// No description provided for @cloudSourceLocal.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil est la source'**
  String get cloudSourceLocal;

  /// No description provided for @cloudSourceRemote.
  ///
  /// In fr, this message translates to:
  /// **'Le Cloud est la source'**
  String get cloudSourceRemote;

  /// No description provided for @cloudResetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Repartir de zéro sur le Cloud ?'**
  String get cloudResetTitle;

  /// No description provided for @cloudResetHelp.
  ///
  /// In fr, this message translates to:
  /// **'Tous les profils et leurs données partagées seront supprimés du Cloud. Les profils locaux seront conservés. Les autres appareils devront saisir ce nouveau code. Cette action est irréversible.'**
  String get cloudResetHelp;

  /// No description provided for @cloudNewCode.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get cloudNewCode;

  /// No description provided for @cloudConfirmCode.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le code'**
  String get cloudConfirmCode;

  /// No description provided for @cloudResetCodeError.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nouveau code de 3 à 10 chiffres et confirmez-le à l’identique.'**
  String get cloudResetCodeError;

  /// No description provided for @cloudRestoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer ce profil ?'**
  String get cloudRestoreTitle;

  /// No description provided for @cloudRestoreHelp.
  ///
  /// In fr, this message translates to:
  /// **'La fiche de {name} sera ajoutée sans remplacer les profils locaux. Les favoris, historiques, abonnements et préférences ne seront pas restaurés.'**
  String cloudRestoreHelp(String name);

  /// No description provided for @cloudDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {name} du Cloud ?'**
  String cloudDeleteTitle(String name);

  /// No description provided for @cloudDeleteHelp.
  ///
  /// In fr, this message translates to:
  /// **'La fiche et les données synchronisées de ce profil seront supprimées du Cloud. Le profil local sur cet appareil ne sera pas supprimé. Les autres appareils seront mis en pause et devront actualiser leur liste.'**
  String get cloudDeleteHelp;

  /// No description provided for @cloudSyncFinished.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation terminée'**
  String get cloudSyncFinished;

  /// No description provided for @cloudSyncFinishedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les profils sélectionnés et leurs données ont bien été synchronisés avec le Cloud.'**
  String get cloudSyncFinishedHelp;

  /// No description provided for @cloudResolveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre le conflit ?'**
  String get cloudResolveTitle;

  /// No description provided for @cloudResolveLocalHelp.
  ///
  /// In fr, this message translates to:
  /// **'Pour les éléments en conflit de cette catégorie, la version de cet appareil sera conservée. L’autre version, y compris une éventuelle suppression, sera écrasée.'**
  String get cloudResolveLocalHelp;

  /// No description provided for @cloudResolveRemoteHelp.
  ///
  /// In fr, this message translates to:
  /// **'Pour les éléments en conflit de cette catégorie, la version cloud sera conservée. L’autre version, y compris une éventuelle suppression, sera écrasée.'**
  String get cloudResolveRemoteHelp;

  /// No description provided for @cloudProfilesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes profils sur mes appareils'**
  String get cloudProfilesTitle;

  /// No description provided for @cloudSignInToContinue.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à un compte cloud pour continuer.'**
  String get cloudSignInToContinue;

  /// No description provided for @cloudFirebaseUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Firebase n’est pas disponible sur cet appareil.'**
  String get cloudFirebaseUnavailable;

  /// No description provided for @cloudGoogleCanceled.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google annulée ou impossible. Si le problème persiste, vérifiez la configuration Google de cette application.'**
  String get cloudGoogleCanceled;

  /// No description provided for @cloudGoogleConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'Configuration Google incorrecte : vérifiez le client OAuth et la signature de cette application.'**
  String get cloudGoogleConfiguration;

  /// No description provided for @cloudGoogleUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google indisponible sur cet appareil.'**
  String get cloudGoogleUnavailable;

  /// No description provided for @cloudSignInUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Service de connexion indisponible sur cet appareil.'**
  String get cloudSignInUnavailable;

  /// No description provided for @cloudSignInRetry.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Réessayez.'**
  String get cloudSignInRetry;

  /// No description provided for @cloudInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get cloudInvalidEmail;

  /// No description provided for @cloudWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop faible.'**
  String get cloudWeakPassword;

  /// No description provided for @cloudEmailInUse.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse est déjà utilisée.'**
  String get cloudEmailInUse;

  /// No description provided for @cloudInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail ou mot de passe incorrect.'**
  String get cloudInvalidCredentials;

  /// No description provided for @cloudNetworkUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réseau indisponible.'**
  String get cloudNetworkUnavailable;

  /// No description provided for @cloudTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez plus tard.'**
  String get cloudTooManyAttempts;

  /// No description provided for @cloudMethodDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Cette méthode de connexion n’est pas activée.'**
  String get cloudMethodDisabled;

  /// No description provided for @cloudGoogleAlreadyLinked.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est déjà lié à Google.'**
  String get cloudGoogleAlreadyLinked;

  /// No description provided for @cloudGoogleOtherAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte Google est déjà associé à un autre compte Firebase. Aucun compte ni donnée n’a été fusionné. Pour utiliser cet autre compte, déconnectez-vous puis connectez-vous avec Google.'**
  String get cloudGoogleOtherAccount;

  /// No description provided for @cloudFirebaseSignInFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Réessayez ou vérifiez la configuration Firebase.'**
  String get cloudFirebaseSignInFailed;

  /// No description provided for @cloudAccountIntro.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour retrouver vos profils et leurs données sur vos appareils. Vos données sont chiffrées.'**
  String get cloudAccountIntro;

  /// No description provided for @cloudAccountLinkHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte est déjà connecté, Google lui sera lié sans changer son identifiant. Les comptes distincts ne sont pas fusionnés.'**
  String get cloudAccountLinkHelp;

  /// No description provided for @cloudAccountStateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire l’état du compte.'**
  String get cloudAccountStateError;

  /// No description provided for @cloudAccountChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du compte…'**
  String get cloudAccountChecking;

  /// No description provided for @cloudAccountNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte cloud connecté.'**
  String get cloudAccountNone;

  /// No description provided for @cloudPairingCleanupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Compte associé, mais le nettoyage de la session temporaire a échoué.'**
  String get cloudPairingCleanupFailed;

  /// No description provided for @cloudPairTv.
  ///
  /// In fr, this message translates to:
  /// **'Associer une TV par QR code'**
  String get cloudPairTv;

  /// No description provided for @pairSignOutFirst.
  ///
  /// In fr, this message translates to:
  /// **'Déconnectez le compte cloud avant le couplage.'**
  String get pairSignOutFirst;

  /// No description provided for @pairScannerAccountChanged.
  ///
  /// In fr, this message translates to:
  /// **'Le compte cloud a changé. Fermez cet écran et recommencez.'**
  String get pairScannerAccountChanged;

  /// No description provided for @pairScannerAccountCheckFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier le compte cloud.'**
  String get pairScannerAccountCheckFailed;

  /// No description provided for @pairScannerCameraFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’utiliser la caméra.'**
  String get pairScannerCameraFailed;

  /// No description provided for @pairScannerInvalidQr.
  ///
  /// In fr, this message translates to:
  /// **'Ce QR code ne correspond pas à une session Orbit 3D.'**
  String get pairScannerInvalidQr;

  /// No description provided for @pairScannerAssociationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Association impossible. Vérifiez le réseau ou recréez le QR code sur la TV.'**
  String get pairScannerAssociationFailed;

  /// No description provided for @pairScannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Associer une TV'**
  String get pairScannerTitle;

  /// No description provided for @pairScannerSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée. Confirmez le compte affiché sur la TV.'**
  String get pairScannerSent;

  /// No description provided for @pairScannerCameraPermission.
  ///
  /// In fr, this message translates to:
  /// **'Caméra indisponible. Autorisez son accès dans les réglages.'**
  String get pairScannerCameraPermission;

  /// No description provided for @pairScannerCompareCode.
  ///
  /// In fr, this message translates to:
  /// **'Comparez ce code avec celui affiché sur la TV :'**
  String get pairScannerCompareCode;

  /// No description provided for @pairScannerVerifyWarning.
  ///
  /// In fr, this message translates to:
  /// **'N’acceptez que si les deux codes sont identiques et que vous contrôlez la TV.'**
  String get pairScannerVerifyWarning;

  /// No description provided for @pairScannerSelectedProfiles.
  ///
  /// In fr, this message translates to:
  /// **'La TV sélectionnera automatiquement : {profiles}.'**
  String pairScannerSelectedProfiles(String profiles);

  /// No description provided for @pairScannerConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et associer'**
  String get pairScannerConfirm;

  /// No description provided for @pairScannerRescan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner à nouveau'**
  String get pairScannerRescan;

  /// No description provided for @pairTemporaryUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La session temporaire est indisponible.'**
  String get pairTemporaryUnavailable;

  /// No description provided for @pairCleanupIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage incomplet : la session expirera automatiquement.'**
  String get pairCleanupIncomplete;

  /// No description provided for @pairCleanupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage impossible : la session expirera automatiquement.'**
  String get pairCleanupFailed;

  /// No description provided for @pairUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Couplage indisponible. Vérifiez le réseau et la configuration Firebase.'**
  String get pairUnavailable;

  /// No description provided for @pairRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencez le couplage.'**
  String get pairRestart;

  /// No description provided for @pairTvTitle.
  ///
  /// In fr, this message translates to:
  /// **'Associer cette TV'**
  String get pairTvTitle;

  /// No description provided for @pairInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Sur le téléphone connecté, ouvrez la synchronisation chiffrée et scannez ce QR code. Comparez les codes affichés avant de confirmer.'**
  String get pairInstructions;

  /// No description provided for @pairCreateQr.
  ///
  /// In fr, this message translates to:
  /// **'Créer un QR code'**
  String get pairCreateQr;

  /// No description provided for @pairVerificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification : {code}'**
  String pairVerificationCode(String code);

  /// No description provided for @pairExpires.
  ///
  /// In fr, this message translates to:
  /// **'Le QR code expire après cinq minutes.'**
  String get pairExpires;

  /// No description provided for @pairAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte à associer : {account}'**
  String pairAccount(String account);

  /// No description provided for @pairConfirmAccount.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ce compte'**
  String get pairConfirmAccount;

  /// No description provided for @pairWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation sur le téléphone…'**
  String get pairWaiting;

  /// No description provided for @cloudTemporaryAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte temporaire connecté sur cet appareil.'**
  String get cloudTemporaryAccount;

  /// No description provided for @cloudAccountConnected.
  ///
  /// In fr, this message translates to:
  /// **'Compte connecté : {account}'**
  String cloudAccountConnected(String account);

  /// No description provided for @cloudRecoverProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Retrouver mes profils sur mes appareils'**
  String get cloudRecoverProfiles;

  /// No description provided for @cloudEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get cloudEmail;

  /// No description provided for @cloudSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get cloudSignIn;

  /// No description provided for @cloudCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get cloudCreateAccount;

  /// No description provided for @cloudResetEmailSent.
  ///
  /// In fr, this message translates to:
  /// **'Si le compte existe, un e-mail de réinitialisation peut être envoyé.'**
  String get cloudResetEmailSent;

  /// No description provided for @cloudForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get cloudForgotPassword;

  /// No description provided for @cloudGoogleLinked.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google déjà lié'**
  String get cloudGoogleLinked;

  /// No description provided for @cloudSignInWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Google'**
  String get cloudSignInWithGoogle;

  /// No description provided for @cloudLinkGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Lier un compte Google'**
  String get cloudLinkGoogle;

  /// No description provided for @cloudSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get cloudSignOut;

  /// No description provided for @cloudPrepareCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un adulte prépare le code. Ensuite, choisis les profils à partager.'**
  String get cloudPrepareCodeHelp;

  /// No description provided for @cloudChooseProfilesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Coche les profils que tu veux retrouver sur tes appareils, puis appuie sur Partager.'**
  String get cloudChooseProfilesHelp;

  /// No description provided for @cloudFirstSyncHelp.
  ///
  /// In fr, this message translates to:
  /// **'La première mise à jour peut prendre plus de 10 minutes. Garde Orbit ouvert jusqu’à la fin.'**
  String get cloudFirstSyncHelp;

  /// No description provided for @cloudLegacyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Phrase secrète (ancien format)'**
  String get cloudLegacyPhrase;

  /// No description provided for @cloudAdultCode.
  ///
  /// In fr, this message translates to:
  /// **'Code donné par l’adulte'**
  String get cloudAdultCode;

  /// No description provided for @cloudSamePhraseHelp.
  ///
  /// In fr, this message translates to:
  /// **'Saisir la même phrase sur les deux appareils.'**
  String get cloudSamePhraseHelp;

  /// No description provided for @cloudSameCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le même code sur les deux appareils.'**
  String get cloudSameCodeHelp;

  /// No description provided for @cloudShowPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la phrase secrète'**
  String get cloudShowPhrase;

  /// No description provided for @cloudHidePhrase.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la phrase secrète'**
  String get cloudHidePhrase;

  /// No description provided for @cloudShowCode.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le code cloud'**
  String get cloudShowCode;

  /// No description provided for @cloudHideCode.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le code cloud'**
  String get cloudHideCode;

  /// No description provided for @cloudSeeProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes profils'**
  String get cloudSeeProfiles;

  /// No description provided for @cloudRefreshList.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser la liste'**
  String get cloudRefreshList;

  /// No description provided for @cloudAdultOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options pour un adulte'**
  String get cloudAdultOptions;

  /// No description provided for @cloudUseLegacyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser une ancienne phrase secrète'**
  String get cloudUseLegacyPhrase;

  /// No description provided for @cloudResetAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer tout le Cloud et repartir de zéro'**
  String get cloudResetAction;

  /// No description provided for @cloudShareBeforePairing.
  ///
  /// In fr, this message translates to:
  /// **'Partagez d’abord les profils sélectionnés pour les rendre disponibles sur la TV.'**
  String get cloudShareBeforePairing;

  /// No description provided for @cloudConfirmYourCode.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer votre code'**
  String get cloudConfirmYourCode;

  /// No description provided for @cloudBackupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder cette fiche ?'**
  String get cloudBackupTitle;

  /// No description provided for @cloudConfirmProfilesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre code pour les profils {name}. Gardez-le en lieu sûr : sans lui, vous ne pourrez plus retrouver vos données.'**
  String cloudConfirmProfilesHelp(String name);

  /// No description provided for @cloudBackupHelp.
  ///
  /// In fr, this message translates to:
  /// **'Seule la fiche de {name} sera sauvegardée, chiffrée. Les favoris, historiques, abonnements et préférences ne sont pas inclus. La perte du secret rend la sauvegarde irrécupérable.'**
  String cloudBackupHelp(String name);

  /// No description provided for @cloudConfirmPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la phrase secrète'**
  String get cloudConfirmPhrase;

  /// No description provided for @cloudConfirmCloudCode.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le code cloud'**
  String get cloudConfirmCloudCode;

  /// No description provided for @cloudShowConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la confirmation'**
  String get cloudShowConfirmation;

  /// No description provided for @cloudHideConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la confirmation'**
  String get cloudHideConfirmation;

  /// No description provided for @cloudSecretsMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les secrets ne correspondent pas.'**
  String get cloudSecretsMismatch;

  /// No description provided for @cloudSyncProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser ce profil ?'**
  String get cloudSyncProfileTitle;

  /// No description provided for @cloudSyncProfileHelp.
  ///
  /// In fr, this message translates to:
  /// **'La fiche, les favoris vidéo et radio, historiques récents, épisodes vus et positions du profil actif, ainsi que les préférences et abonnements, seront synchronisés sous forme chiffrée pendant cette session. Les identifiants IPTV sont inclus. L’abonnement actif reste choisi sur chaque appareil.'**
  String get cloudSyncProfileHelp;

  /// No description provided for @cloudUpdating.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour en cours…'**
  String get cloudUpdating;

  /// No description provided for @cloudAdultMustChoose.
  ///
  /// In fr, this message translates to:
  /// **'Un adulte doit choisir les données à garder.'**
  String get cloudAdultMustChoose;

  /// No description provided for @cloudSharingEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Le partage est activé.'**
  String get cloudSharingEnabled;

  /// No description provided for @cloudKeepOpen.
  ///
  /// In fr, this message translates to:
  /// **'Cela peut prendre plus de 10 minutes. Garde Orbit ouvert.'**
  String get cloudKeepOpen;

  /// No description provided for @cloudAutoSharing.
  ///
  /// In fr, this message translates to:
  /// **'Les changements sont partagés automatiquement.'**
  String get cloudAutoSharing;

  /// No description provided for @cloudConflictHelp.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil et l’autre appareil ne sont pas d’accord. Demande à un adulte de choisir la bonne version.'**
  String get cloudConflictHelp;

  /// No description provided for @cloudKeepLocal.
  ///
  /// In fr, this message translates to:
  /// **'Garder les données d’ici'**
  String get cloudKeepLocal;

  /// No description provided for @cloudKeepRemote.
  ///
  /// In fr, this message translates to:
  /// **'Garder les données de l’autre appareil'**
  String get cloudKeepRemote;

  /// No description provided for @cloudShareSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages du partage (adulte)'**
  String get cloudShareSettings;

  /// No description provided for @cloudUpdateNow.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour maintenant'**
  String get cloudUpdateNow;

  /// No description provided for @cloudPause.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause'**
  String get cloudPause;

  /// No description provided for @cloudSelectProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Choisis les profils à partager'**
  String get cloudSelectProfiles;

  /// No description provided for @cloudWhichProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Quels profils veux-tu retrouver sur tes appareils ?'**
  String get cloudWhichProfiles;

  /// No description provided for @cloudLocalProfilesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Profils locaux indisponibles.'**
  String get cloudLocalProfilesUnavailable;

  /// No description provided for @cloudUnselectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout décocher'**
  String get cloudUnselectAll;

  /// No description provided for @cloudSelectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout cocher'**
  String get cloudSelectAll;

  /// No description provided for @cloudShareSelected.
  ///
  /// In fr, this message translates to:
  /// **'Partager les profils cochés'**
  String get cloudShareSelected;

  /// No description provided for @cloudShareAll.
  ///
  /// In fr, this message translates to:
  /// **'Partager tous les profils'**
  String get cloudShareAll;

  /// No description provided for @cloudProfilesToAdd.
  ///
  /// In fr, this message translates to:
  /// **'Profils à ajouter'**
  String get cloudProfilesToAdd;

  /// No description provided for @cloudOtherOptions.
  ///
  /// In fr, this message translates to:
  /// **'Autres options (adulte)'**
  String get cloudOtherOptions;

  /// No description provided for @cloudShareActiveOnly.
  ///
  /// In fr, this message translates to:
  /// **'Partager seulement le profil utilisé'**
  String get cloudShareActiveOnly;

  /// No description provided for @cloudLocalProfileKept.
  ///
  /// In fr, this message translates to:
  /// **'Le profil local est conservé.'**
  String get cloudLocalProfileKept;

  /// No description provided for @cloudRecover.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer'**
  String get cloudRecover;

  /// No description provided for @cloudDeleteAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer du Cloud'**
  String get cloudDeleteAction;

  /// No description provided for @cloudBackupAction.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get cloudBackupAction;

  /// No description provided for @cloudScopeFavorites.
  ///
  /// In fr, this message translates to:
  /// **'favoris'**
  String get cloudScopeFavorites;

  /// No description provided for @cloudScopeRadioFavorites.
  ///
  /// In fr, this message translates to:
  /// **'favoris radio'**
  String get cloudScopeRadioFavorites;

  /// No description provided for @cloudScopeRecents.
  ///
  /// In fr, this message translates to:
  /// **'historique récent'**
  String get cloudScopeRecents;

  /// No description provided for @cloudScopeWatched.
  ///
  /// In fr, this message translates to:
  /// **'épisodes vus'**
  String get cloudScopeWatched;

  /// No description provided for @cloudScopePlayback.
  ///
  /// In fr, this message translates to:
  /// **'positions de lecture'**
  String get cloudScopePlayback;

  /// No description provided for @cloudScopePreferences.
  ///
  /// In fr, this message translates to:
  /// **'préférences générales'**
  String get cloudScopePreferences;

  /// No description provided for @cloudScopeProfile.
  ///
  /// In fr, this message translates to:
  /// **'fiche du profil'**
  String get cloudScopeProfile;

  /// No description provided for @cloudProfileFallback.
  ///
  /// In fr, this message translates to:
  /// **'profil'**
  String get cloudProfileFallback;

  /// No description provided for @cloudScopeSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'abonnements'**
  String get cloudScopeSubscriptions;

  /// No description provided for @cloudScopeData.
  ///
  /// In fr, this message translates to:
  /// **'données'**
  String get cloudScopeData;

  /// No description provided for @cloudProgressPercent.
  ///
  /// In fr, this message translates to:
  /// **'Fait : {percent} %'**
  String cloudProgressPercent(int percent);

  /// No description provided for @cloudProgressScope.
  ///
  /// In fr, this message translates to:
  /// **'En ce moment : {scope}.'**
  String cloudProgressScope(String scope);

  /// No description provided for @cloudProgressProfile.
  ///
  /// In fr, this message translates to:
  /// **'En ce moment : {scope} — {profile}.'**
  String cloudProgressProfile(String scope, String profile);

  /// No description provided for @cloudConflictProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil en conflit : {name} ({id})'**
  String cloudConflictProfile(String name, String id);

  /// No description provided for @cloudConflictData.
  ///
  /// In fr, this message translates to:
  /// **'Données : {scope}'**
  String cloudConflictData(String scope);

  /// No description provided for @cloudChangedElsewhere.
  ///
  /// In fr, this message translates to:
  /// **'Le cloud a changé ailleurs. Rechargez avant de réessayer.'**
  String get cloudChangedElsewhere;

  /// No description provided for @cloudBadPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Phrase secrète incorrecte ou données cloud altérées.'**
  String get cloudBadPhrase;

  /// No description provided for @cloudBadCode.
  ///
  /// In fr, this message translates to:
  /// **'Code cloud incorrect ou données cloud altérées.'**
  String get cloudBadCode;

  /// No description provided for @cloudAccessFailed.
  ///
  /// In fr, this message translates to:
  /// **'Accès cloud impossible. Vérifiez le réseau et la configuration Firebase.'**
  String get cloudAccessFailed;

  /// No description provided for @cloudInvalidData.
  ///
  /// In fr, this message translates to:
  /// **'Données cloud invalides ou incompatibles ; aucune restauration effectuée.'**
  String get cloudInvalidData;

  /// No description provided for @cloudOperationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Opération impossible. Vérifiez le réseau puis actualisez le Cloud.'**
  String get cloudOperationFailed;

  /// No description provided for @cloudAskAdult.
  ///
  /// In fr, this message translates to:
  /// **'Demande le code à un adulte.'**
  String get cloudAskAdult;

  /// No description provided for @cloudCodeLength.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit contenir de 3 à 10 chiffres.'**
  String get cloudCodeLength;

  /// No description provided for @cloudAccountChanged.
  ///
  /// In fr, this message translates to:
  /// **'Le compte ou le secret a changé. Recommencez.'**
  String get cloudAccountChanged;

  /// No description provided for @cloudPhraseChanged.
  ///
  /// In fr, this message translates to:
  /// **'Le compte ou la phrase a changé. Recommencez.'**
  String get cloudPhraseChanged;

  /// No description provided for @cloudBackupRefreshed.
  ///
  /// In fr, this message translates to:
  /// **'Fiche sauvegardée. Catalogue actualisé.'**
  String get cloudBackupRefreshed;

  /// No description provided for @cloudAccessEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Accès confirmé. Aucun profil sauvegardé.'**
  String get cloudAccessEmpty;

  /// No description provided for @cloudCodeUnverified.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde trouvée : votre code ne peut pas encore être vérifié.'**
  String get cloudCodeUnverified;

  /// No description provided for @cloudAccessChoose.
  ///
  /// In fr, this message translates to:
  /// **'Accès confirmé. Choisissez les profils à partager.'**
  String get cloudAccessChoose;

  /// No description provided for @cloudBackupRefreshFailed.
  ///
  /// In fr, this message translates to:
  /// **'Fiche sauvegardée, mais le catalogue n’a pas pu être actualisé.'**
  String get cloudBackupRefreshFailed;

  /// No description provided for @cloudPhoneProfilesMissing.
  ///
  /// In fr, this message translates to:
  /// **'Les profils choisis sur le téléphone ne sont plus disponibles. Actualisez la liste et sélectionnez-les à nouveau.'**
  String get cloudPhoneProfilesMissing;

  /// No description provided for @cloudPhoneProfilesReceived.
  ///
  /// In fr, this message translates to:
  /// **'Profils reçus du téléphone. Démarrage du partage…'**
  String get cloudPhoneProfilesReceived;

  /// No description provided for @cloudProfileRestored.
  ///
  /// In fr, this message translates to:
  /// **'Fiche récupérée. Sélectionnez ce profil dans l’application, puis revenez ici pour activer sa synchronisation.'**
  String get cloudProfileRestored;

  /// No description provided for @cloudWaitDelete.
  ///
  /// In fr, this message translates to:
  /// **'Attendez la fin de la synchronisation avant la suppression.'**
  String get cloudWaitDelete;

  /// No description provided for @cloudWaitReset.
  ///
  /// In fr, this message translates to:
  /// **'Attendez la fin de la synchronisation avant la réinitialisation.'**
  String get cloudWaitReset;

  /// No description provided for @cloudResetComplete.
  ///
  /// In fr, this message translates to:
  /// **'Cloud réinitialisé. Le nouveau code est actif ; les profils locaux ont été conservés.'**
  String get cloudResetComplete;

  /// No description provided for @cloudWaitSelection.
  ///
  /// In fr, this message translates to:
  /// **'Une synchronisation est en cours. Attendez la fin avant de modifier la sélection.'**
  String get cloudWaitSelection;

  /// No description provided for @cloudProfilesChanged.
  ///
  /// In fr, this message translates to:
  /// **'Les profils ont changé. Vérifiez votre sélection.'**
  String get cloudProfilesChanged;

  /// No description provided for @cloudRestoredProfileMissing.
  ///
  /// In fr, this message translates to:
  /// **'Une fiche récupérée est introuvable. Réessayez.'**
  String get cloudRestoredProfileMissing;

  /// No description provided for @cloudRestoringProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Récupération des fiches : {current} / {total}.'**
  String cloudRestoringProfiles(int current, int total);

  /// No description provided for @cloudCheckingProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Vérification et sauvegarde des fiches cloud.'**
  String get cloudCheckingProfiles;

  /// No description provided for @cloudPartialRestore.
  ///
  /// In fr, this message translates to:
  /// **'Certaines fiches ont peut-être été récupérées. Vérifiez la liste avant de réessayer.'**
  String get cloudPartialRestore;

  /// No description provided for @cloudStartingSync.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage de la synchronisation.'**
  String get cloudStartingSync;

  /// No description provided for @cloudProfilesBackedUp.
  ///
  /// In fr, this message translates to:
  /// **'Les fiches ont été sauvegardées.'**
  String get cloudProfilesBackedUp;

  /// No description provided for @subscriptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionRefreshSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour terminée : au moins une source actualisée.'**
  String get subscriptionRefreshSuccess;

  /// No description provided for @subscriptionRefreshFailed.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour impossible : aucune donnée reçue.'**
  String get subscriptionRefreshFailed;

  /// No description provided for @subscriptionConnectionHelp.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible ou identifiants refusés. Vérifiez l’adresse du serveur, le nom d’utilisateur, le mot de passe et votre connexion Internet.'**
  String get subscriptionConnectionHelp;

  /// No description provided for @subscriptionDuplicateHelp.
  ///
  /// In fr, this message translates to:
  /// **'Doublon possible : plusieurs abonnements ont la même configuration. Aucun n’a été supprimé ; leurs favoris peuvent être différents.'**
  String get subscriptionDuplicateHelp;

  /// No description provided for @subscriptionRefreshActive.
  ///
  /// In fr, this message translates to:
  /// **'Forcer la mise à jour de l’abonnement actif'**
  String get subscriptionRefreshActive;

  /// No description provided for @subscriptionActivationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’activer l’abonnement.'**
  String get subscriptionActivationFailed;

  /// No description provided for @subscriptionDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’abonnement ?'**
  String get subscriptionDeleteTitle;

  /// No description provided for @subscriptionDeleteHelp.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer « {name} » ? Cette action est irréversible.'**
  String subscriptionDeleteHelp(String name);

  /// No description provided for @subscriptionNoActive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif. Sélectionnez-en un ou ajoutez-en un nouveau.'**
  String get subscriptionNoActive;

  /// No description provided for @subscriptionActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get subscriptionActivate;

  /// No description provided for @subscriptionNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement'**
  String get subscriptionNone;

  /// No description provided for @subscriptionEmptyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier abonnement Xtream Codes ou M3U pour commencer.'**
  String get subscriptionEmptyHelp;

  /// No description provided for @subscriptionFilterHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les catégories à masquer se règlent dans Configuration > Accessibilité > Filtres de catégories.'**
  String get subscriptionFilterHelp;

  /// No description provided for @subscriptionPossibleDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Doublon possible'**
  String get subscriptionPossibleDuplicate;

  /// No description provided for @subscriptionInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get subscriptionInactive;

  /// No description provided for @subscriptionTesting.
  ///
  /// In fr, this message translates to:
  /// **'Test…'**
  String get subscriptionTesting;

  /// No description provided for @subscriptionUntested.
  ///
  /// In fr, this message translates to:
  /// **'Non testé'**
  String get subscriptionUntested;

  /// No description provided for @subscriptionTestOk.
  ///
  /// In fr, this message translates to:
  /// **'Test OK'**
  String get subscriptionTestOk;

  /// No description provided for @subscriptionTestLatency.
  ///
  /// In fr, this message translates to:
  /// **'Test OK • {latency} ms'**
  String subscriptionTestLatency(int latency);

  /// No description provided for @subscriptionTestFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get subscriptionTestFailed;

  /// No description provided for @subscriptionTestAction.
  ///
  /// In fr, this message translates to:
  /// **'Tester'**
  String get subscriptionTestAction;

  /// No description provided for @subscriptionIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Configuration incomplète'**
  String get subscriptionIncomplete;

  /// No description provided for @connectionInvalidConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'Les paramètres de cet abonnement sont manquants ou invalides.'**
  String get connectionInvalidConfiguration;

  /// No description provided for @connectionCheckServerOrPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’URL du serveur ou de la playlist.'**
  String get connectionCheckServerOrPlaylist;

  /// No description provided for @connectionCheckCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez également l’identifiant et le mot de passe.'**
  String get connectionCheckCredentials;

  /// No description provided for @connectionCertificateExpired.
  ///
  /// In fr, this message translates to:
  /// **'Certificat SSL expiré'**
  String get connectionCertificateExpired;

  /// No description provided for @connectionSslError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur SSL/TLS'**
  String get connectionSslError;

  /// No description provided for @connectionCertificateExpiredHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le certificat de sécurité du serveur a expiré.'**
  String get connectionCertificateExpiredHelp;

  /// No description provided for @connectionSslHelp.
  ///
  /// In fr, this message translates to:
  /// **'La connexion sécurisée au serveur n’a pas pu être établie.'**
  String get connectionSslHelp;

  /// No description provided for @connectionCheckDateTime.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez la date et l’heure de votre appareil.'**
  String get connectionCheckDateTime;

  /// No description provided for @connectionContactProvider.
  ///
  /// In fr, this message translates to:
  /// **'Contactez votre fournisseur si le problème persiste.'**
  String get connectionContactProvider;

  /// No description provided for @connectionDnsFailure.
  ///
  /// In fr, this message translates to:
  /// **'Serveur introuvable (DNS)'**
  String get connectionDnsFailure;

  /// No description provided for @connectionDnsFailureHelp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de trouver le serveur. Vérifiez son adresse et votre connexion Internet.'**
  String get connectionDnsFailureHelp;

  /// No description provided for @connectionNetworkUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Réseau inaccessible'**
  String get connectionNetworkUnavailable;

  /// No description provided for @connectionNetworkUnavailableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’atteindre le réseau du serveur. Vérifiez votre connexion Internet.'**
  String get connectionNetworkUnavailableHelp;

  /// No description provided for @connectionServerError.
  ///
  /// In fr, this message translates to:
  /// **'Serveur temporairement indisponible'**
  String get connectionServerError;

  /// No description provided for @connectionServerUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Serveur inaccessible'**
  String get connectionServerUnreachable;

  /// No description provided for @connectionServerUnreachableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur. Vérifiez l’adresse et votre connexion Internet.'**
  String get connectionServerUnreachableHelp;

  /// No description provided for @connectionCheckUrl.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’orthographe de l’URL.'**
  String get connectionCheckUrl;

  /// No description provided for @connectionTryAnotherNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Essayez depuis un autre réseau.'**
  String get connectionTryAnotherNetwork;

  /// No description provided for @connectionContactUnreachableProvider.
  ///
  /// In fr, this message translates to:
  /// **'Contactez votre fournisseur si le serveur reste inaccessible.'**
  String get connectionContactUnreachableProvider;

  /// No description provided for @connectionTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai de réponse dépassé'**
  String get connectionTimeout;

  /// No description provided for @connectionTimeoutHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur n’a pas répondu à temps. Il peut être lent ou momentanément surchargé.'**
  String get connectionTimeoutHelp;

  /// No description provided for @connectionTryLater.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez dans quelques minutes.'**
  String get connectionTryLater;

  /// No description provided for @connectionCheckInternet.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion Internet.'**
  String get connectionCheckInternet;

  /// No description provided for @connectionInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants invalides'**
  String get connectionInvalidCredentials;

  /// No description provided for @connectionAccessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé'**
  String get connectionAccessDenied;

  /// No description provided for @connectionXtreamRejected.
  ///
  /// In fr, this message translates to:
  /// **'L’identifiant ou le mot de passe Xtream est refusé par le serveur.'**
  String get connectionXtreamRejected;

  /// No description provided for @connectionM3uAuthorization.
  ///
  /// In fr, this message translates to:
  /// **'La playlist M3U nécessite une autorisation ou une URL valide.'**
  String get connectionM3uAuthorization;

  /// No description provided for @connectionCheckCredentialsCase.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’identifiant et le mot de passe, en respectant les majuscules.'**
  String get connectionCheckCredentialsCase;

  /// No description provided for @connectionConfirmCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Demandez à votre fournisseur de confirmer les informations de connexion.'**
  String get connectionConfirmCredentials;

  /// No description provided for @connectionAccountUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement ou compte indisponible'**
  String get connectionAccountUnavailable;

  /// No description provided for @connectionAccountUnavailableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le compte peut être expiré, désactivé ou avoir atteint sa limite de connexions.'**
  String get connectionAccountUnavailableHelp;

  /// No description provided for @connectionCheckSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’état de l’abonnement auprès de votre fournisseur.'**
  String get connectionCheckSubscription;

  /// No description provided for @connectionCloseOtherDevices.
  ///
  /// In fr, this message translates to:
  /// **'Fermez les autres appareils connectés puis réessayez.'**
  String get connectionCloseOtherDevices;

  /// No description provided for @connectionForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Accès interdit'**
  String get connectionForbidden;

  /// No description provided for @connectionForbiddenHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur refuse la connexion. Le compte ou l’adresse IP peut être bloqué.'**
  String get connectionForbiddenHelp;

  /// No description provided for @connectionCheckActiveSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que l’abonnement est toujours actif.'**
  String get connectionCheckActiveSubscription;

  /// No description provided for @connectionCheckProviderAccess.
  ///
  /// In fr, this message translates to:
  /// **'Contactez votre fournisseur pour vérifier l’accès.'**
  String get connectionCheckProviderAccess;

  /// No description provided for @connectionNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Adresse introuvable (404)'**
  String get connectionNotFound;

  /// No description provided for @connectionInvalidRequest.
  ///
  /// In fr, this message translates to:
  /// **'Requête invalide'**
  String get connectionInvalidRequest;

  /// No description provided for @connectionInvalidAddress.
  ///
  /// In fr, this message translates to:
  /// **'L’adresse du serveur ou le point d’accès ne semble pas correct.'**
  String get connectionInvalidAddress;

  /// No description provided for @connectionCheckBaseUrl.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’URL de base du serveur ou l’URL M3U.'**
  String get connectionCheckBaseUrl;

  /// No description provided for @connectionUseXtreamPanel.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez l’adresse du panel Xtream, sans ajouter player_api.php.'**
  String get connectionUseXtreamPanel;

  /// No description provided for @connectionServerUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Serveur temporairement indisponible ({status})'**
  String connectionServerUnavailable(int status);

  /// No description provided for @connectionServerProblem.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur du fournisseur rencontre un problème.'**
  String get connectionServerProblem;

  /// No description provided for @connectionInvalidPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Playlist M3U invalide ou vide'**
  String get connectionInvalidPlaylist;

  /// No description provided for @connectionInvalidPlaylistHelp.
  ///
  /// In fr, this message translates to:
  /// **'La playlist ne contient pas de données lisibles au format attendu.'**
  String get connectionInvalidPlaylistHelp;

  /// No description provided for @connectionCheckPlaylistUrl.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que l’URL pointe vers une playlist M3U à jour.'**
  String get connectionCheckPlaylistUrl;

  /// No description provided for @connectionRequestNewUrl.
  ///
  /// In fr, this message translates to:
  /// **'Demandez une nouvelle URL à votre fournisseur.'**
  String get connectionRequestNewUrl;

  /// No description provided for @connectionTestFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du test de connexion'**
  String get connectionTestFailed;

  /// No description provided for @connectionUnexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue a empêché la connexion à cet abonnement.'**
  String get connectionUnexpectedError;

  /// No description provided for @connectionCheckSubscriptionAndInternet.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les informations de l’abonnement et votre connexion Internet.'**
  String get connectionCheckSubscriptionAndInternet;

  /// No description provided for @connectionRetryOrContact.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez ou contactez votre fournisseur si le problème persiste.'**
  String get connectionRetryOrContact;

  /// No description provided for @connectionThingsToCheck.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get connectionThingsToCheck;

  /// No description provided for @connectionTechnicalDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails techniques'**
  String get connectionTechnicalDetails;

  /// No description provided for @subscriptionSemantic.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement {name}'**
  String subscriptionSemantic(String name);

  /// No description provided for @subscriptionSemanticActive.
  ///
  /// In fr, this message translates to:
  /// **'actif'**
  String get subscriptionSemanticActive;

  /// No description provided for @subscriptionSemanticDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'doublon possible'**
  String get subscriptionSemanticDuplicate;

  /// No description provided for @subscriptionAdded.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement ajouté'**
  String get subscriptionAdded;

  /// No description provided for @subscriptionAddedHelp.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » est enregistré. Vous pouvez tester la connexion puis activer l’abonnement.'**
  String subscriptionAddedHelp(String name);

  /// No description provided for @subscriptionTestRunning.
  ///
  /// In fr, this message translates to:
  /// **'Test de connexion en cours…'**
  String get subscriptionTestRunning;

  /// No description provided for @subscriptionTestSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Test de connexion réussi.'**
  String get subscriptionTestSuccess;

  /// No description provided for @subscriptionTestUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le résultat du test est indisponible.'**
  String get subscriptionTestUnavailable;

  /// No description provided for @subscriptionTestError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de terminer le test de connexion.'**
  String get subscriptionTestError;

  /// No description provided for @subscriptionEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’abonnement'**
  String get subscriptionEditTitle;

  /// No description provided for @subscriptionNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel abonnement'**
  String get subscriptionNewTitle;

  /// No description provided for @subscriptionName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’abonnement'**
  String get subscriptionName;

  /// No description provided for @subscriptionUsername.
  ///
  /// In fr, this message translates to:
  /// **'Nom d’utilisateur'**
  String get subscriptionUsername;

  /// No description provided for @subscriptionPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get subscriptionPassword;

  /// No description provided for @subscriptionShowPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get subscriptionShowPassword;

  /// No description provided for @subscriptionHidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get subscriptionHidePassword;

  /// No description provided for @subscriptionAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get subscriptionAdd;

  /// No description provided for @playerExternalOpened.
  ///
  /// In fr, this message translates to:
  /// **'Lecture ouverte dans un lecteur externe'**
  String get playerExternalOpened;

  /// No description provided for @playerExternalTrackHelp.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez les pistes audio et les sous-titres dans le lecteur externe : les préférences d’Orbit ne lui sont pas transmises.'**
  String get playerExternalTrackHelp;

  /// No description provided for @playerProviderBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Flux temporairement bloqué par le fournisseur'**
  String get playerProviderBlocked;

  /// No description provided for @playerStreamNotStarting.
  ///
  /// In fr, this message translates to:
  /// **'Le flux est bien reçu mais la lecture ne démarre pas. La piste est peut-être trop lourde pour cet appareil.'**
  String get playerStreamNotStarting;

  /// No description provided for @playerStreamFrozen.
  ///
  /// In fr, this message translates to:
  /// **'Le flux est reçu mais la lecture est figée.'**
  String get playerStreamFrozen;

  /// No description provided for @playerStreamRecovering.
  ///
  /// In fr, this message translates to:
  /// **'Le flux ne progresse plus. Tentative de récupération…'**
  String get playerStreamRecovering;

  /// No description provided for @playerCooldown.
  ///
  /// In fr, this message translates to:
  /// **'Serveur protégé (anti-leech), nouvelle tentative dans {seconds}s'**
  String playerCooldown(int seconds);

  /// No description provided for @playerProviderBlockedHelp.
  ///
  /// In fr, this message translates to:
  /// **'La lecture a été coupée par la protection anti-leech du serveur. Patientez 3 à 5 minutes sans lecture, puis relancez cette chaîne (sans zapper).'**
  String get playerProviderBlockedHelp;

  /// No description provided for @playerLiveUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Flux indisponible'**
  String get playerLiveUnavailable;

  /// No description provided for @playerLiveUnavailableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer cette chaîne. Vérifiez votre abonnement ou réessayez.'**
  String get playerLiveUnavailableHelp;

  /// No description provided for @playerNextEpisode.
  ///
  /// In fr, this message translates to:
  /// **'Épisode suivant : {title}'**
  String playerNextEpisode(String title);

  /// No description provided for @playerNextEpisodeCountdown.
  ///
  /// In fr, this message translates to:
  /// **'Épisode suivant : {title} ({seconds} s)'**
  String playerNextEpisodeCountdown(String title, int seconds);

  /// No description provided for @profileSelectToContinue.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un profil pour continuer'**
  String get profileSelectToContinue;

  /// No description provided for @profileCreateToWatch.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre premier profil pour commencer à regarder.'**
  String get profileCreateToWatch;

  /// No description provided for @profileNavigationHelp.
  ///
  /// In fr, this message translates to:
  /// **'Flèches + OK pour naviguer · Touchez une carte pour sélectionner'**
  String get profileNavigationHelp;

  /// No description provided for @profileActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get profileActive;

  /// No description provided for @resumeAction.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resumeAction;

  /// No description provided for @refreshRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser les recommandations'**
  String get refreshRecommendations;

  /// No description provided for @localVideoProxy.
  ///
  /// In fr, this message translates to:
  /// **'Relais vidéo local expérimental'**
  String get localVideoProxy;

  /// No description provided for @localVideoProxySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour les films et séries du lecteur interne, avec cache disque limité.'**
  String get localVideoProxySubtitle;

  /// No description provided for @accountDeviceProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil appareil & Diagnostic'**
  String get accountDeviceProfile;

  /// No description provided for @accountDeviceProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil {label} · diagnostic lecteur'**
  String accountDeviceProfileSubtitle(String label);

  /// No description provided for @accountNoSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif'**
  String get accountNoSubscription;

  /// No description provided for @accountPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences profil'**
  String get accountPreferences;

  /// No description provided for @accountPreferencesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue, PIN'**
  String get accountPreferencesSubtitle;

  /// No description provided for @accountProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Profils utilisateurs'**
  String get accountProfiles;

  /// No description provided for @accountProfilesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les profils et le profil actif'**
  String get accountProfilesSubtitle;

  /// No description provided for @accountSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements Xtream/M3U'**
  String get accountSubscriptions;

  /// No description provided for @activeCountOngoing.
  ///
  /// In fr, this message translates to:
  /// **'{count} en cours'**
  String activeCountOngoing(Object count);

  /// No description provided for @addSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un abonnement'**
  String get addSubscription;

  /// No description provided for @addedToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » ajouté aux favoris'**
  String addedToFavorites(Object title);

  /// No description provided for @age.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get age;

  /// No description provided for @ageRange13to17.
  ///
  /// In fr, this message translates to:
  /// **'13 - 17 ans'**
  String get ageRange13to17;

  /// No description provided for @ageRange18to24.
  ///
  /// In fr, this message translates to:
  /// **'18 - 24 ans'**
  String get ageRange18to24;

  /// No description provided for @ageRange25to34.
  ///
  /// In fr, this message translates to:
  /// **'25 - 34 ans'**
  String get ageRange25to34;

  /// No description provided for @ageRange35to44.
  ///
  /// In fr, this message translates to:
  /// **'35 - 44 ans'**
  String get ageRange35to44;

  /// No description provided for @ageRange45to54.
  ///
  /// In fr, this message translates to:
  /// **'45 - 54 ans'**
  String get ageRange45to54;

  /// No description provided for @ageRange55plus.
  ///
  /// In fr, this message translates to:
  /// **'55 ans et plus'**
  String get ageRange55plus;

  /// No description provided for @ageRangeUnder12.
  ///
  /// In fr, this message translates to:
  /// **'- 12 ans'**
  String get ageRangeUnder12;

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Orbit IPTV'**
  String get appTitle;

  /// No description provided for @appearInSearchAndRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Apparaître dans les recherches et recommandations'**
  String get appearInSearchAndRecommendations;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @audioAndNightFocus.
  ///
  /// In fr, this message translates to:
  /// **'Audio & Night Focus'**
  String get audioAndNightFocus;

  /// No description provided for @audioAndNightFocusSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation nocturne, dialogue boost, synchronisation A/V'**
  String get audioAndNightFocusSubtitle;

  /// No description provided for @audioShift.
  ///
  /// In fr, this message translates to:
  /// **'Décalage audio configurable'**
  String get audioShift;

  /// No description provided for @audioShiftMinus50.
  ///
  /// In fr, this message translates to:
  /// **'-50 ms'**
  String get audioShiftMinus50;

  /// No description provided for @audioShiftPlus50.
  ///
  /// In fr, this message translates to:
  /// **'+50 ms'**
  String get audioShiftPlus50;

  /// No description provided for @audioShiftSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Décalage audio/vidéo manuel (ms)'**
  String get audioShiftSubtitle;

  /// No description provided for @autoQualityDescription.
  ///
  /// In fr, this message translates to:
  /// **'Laisse le lecteur choisir la meilleure qualité'**
  String get autoQualityDescription;

  /// No description provided for @autoReconnectLive.
  ///
  /// In fr, this message translates to:
  /// **'Auto-réconnexion Live'**
  String get autoReconnectLive;

  /// No description provided for @autoReconnectLiveSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tente de reconnecter automatiquement si le flux coupe'**
  String get autoReconnectLiveSubtitle;

  /// No description provided for @avSyncDialogHint.
  ///
  /// In fr, this message translates to:
  /// **'Positif = audio en avance, Négatif = audio en retard'**
  String get avSyncDialogHint;

  /// No description provided for @avSyncDialogLabel.
  ///
  /// In fr, this message translates to:
  /// **'Décalage (ms)'**
  String get avSyncDialogLabel;

  /// No description provided for @avSyncDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calibrage A/V'**
  String get avSyncDialogTitle;

  /// No description provided for @backupExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter la configuration'**
  String get backupExport;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Copie la config complète dans le presse-papiers'**
  String get backupExportSubtitle;

  /// No description provided for @backupImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer la configuration'**
  String get backupImport;

  /// No description provided for @backupImportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaure depuis le presse-papiers (JSON)'**
  String get backupImportSubtitle;

  /// No description provided for @bassKiller.
  ///
  /// In fr, this message translates to:
  /// **'Bass Killer (coupe < 120 Hz)'**
  String get bassKiller;

  /// No description provided for @bassKillerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Atténue les basses fréquences pour éviter les vibrations'**
  String get bassKillerSubtitle;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @deleteDownload.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteDownload;

  /// No description provided for @castToChromecast.
  ///
  /// In fr, this message translates to:
  /// **'Diffuser sur Chromecast'**
  String get castToChromecast;

  /// No description provided for @catchUpTv.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage des chaînes'**
  String get catchUpTv;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @certPinning.
  ///
  /// In fr, this message translates to:
  /// **'Activer Certificate Pinning'**
  String get certPinning;

  /// No description provided for @certPinningAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter les empreintes ci-dessus'**
  String get certPinningAdd;

  /// No description provided for @certPinningHint.
  ///
  /// In fr, this message translates to:
  /// **'Empreintes autorisées (une par ligne, format hex uppercase) :'**
  String get certPinningHint;

  /// No description provided for @certPinningSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie l\'empreinte SHA-256 du certificat SSL du serveur (anti-MITM)'**
  String get certPinningSubtitle;

  /// No description provided for @changePinCode.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code PIN'**
  String get changePinCode;

  /// No description provided for @channelsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Chaînes indisponibles'**
  String get channelsUnavailable;

  /// No description provided for @chooseProfile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un profil'**
  String get chooseProfile;

  /// No description provided for @clearCaches.
  ///
  /// In fr, this message translates to:
  /// **'Vider tous les caches'**
  String get clearCaches;

  /// No description provided for @clearCachesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Images, index recherche, métadonnées TMDB/TVmaze'**
  String get clearCachesSubtitle;

  /// No description provided for @cloudSyncEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation activée'**
  String get cloudSyncEnabled;

  /// No description provided for @cloudSyncLastSync.
  ///
  /// In fr, this message translates to:
  /// **'Dernière sync (cette installation) : {time}'**
  String cloudSyncLastSync(String time);

  /// No description provided for @cloudSyncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get cloudSyncNow;

  /// No description provided for @cloudSyncNowSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoie au cloud les favoris, historiques et reprises de lecture de cette installation'**
  String get cloudSyncNowSubtitle;

  /// No description provided for @cloudSyncSubtitleOff.
  ///
  /// In fr, this message translates to:
  /// **'Synchronise favoris, épisodes vus, récents et reprises de lecture pour cette installation'**
  String get cloudSyncSubtitleOff;

  /// No description provided for @cloudflareReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la session Cloudflare'**
  String get cloudflareReset;

  /// No description provided for @cloudflareResetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Renouvelle la session Cloudflare active.'**
  String get cloudflareResetSubtitle;

  /// No description provided for @cloudflareNoActiveSession.
  ///
  /// In fr, this message translates to:
  /// **'Aucune session Cloudflare active à renouveler.'**
  String get cloudflareNoActiveSession;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @settingsContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get settingsContact;

  /// No description provided for @settingsActivateApp.
  ///
  /// In fr, this message translates to:
  /// **'Activer l’application'**
  String get settingsActivateApp;

  /// No description provided for @confirmAndContinue.
  ///
  /// In fr, this message translates to:
  /// **'Valider et continuer'**
  String get confirmAndContinue;

  /// No description provided for @coverCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Cache des pochettes purgé.'**
  String get coverCacheCleared;

  /// No description provided for @createKidProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créer un profil Enfant'**
  String get createKidProfile;

  /// No description provided for @createNewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau profil'**
  String get createNewProfile;

  /// No description provided for @createProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créer un profil'**
  String get createProfile;

  /// No description provided for @currentProfileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Profil courant : {name}'**
  String currentProfileLabel(String name);

  /// No description provided for @dataAlreadyFresh.
  ///
  /// In fr, this message translates to:
  /// **'Données déjà fraîches (moins de 8 h)'**
  String get dataAlreadyFresh;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Données & confidentialité'**
  String get dataAndPrivacy;

  /// No description provided for @deleteAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout supprimer'**
  String get deleteAll;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tout supprimer ?'**
  String get deleteAllConfirm;

  /// No description provided for @deletePin.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le PIN'**
  String get deletePin;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le profil ?'**
  String get deleteProfileConfirm;

  /// No description provided for @detailUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Détail indisponible'**
  String get detailUnavailable;

  /// No description provided for @diagnosticUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic indisponible'**
  String get diagnosticUnavailable;

  /// No description provided for @dialogueBoost.
  ///
  /// In fr, this message translates to:
  /// **'Boost Dialogues (+4 dB)'**
  String get dialogueBoost;

  /// No description provided for @dialogueBoostSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Amplifie les voix par rapport aux effets/musique'**
  String get dialogueBoostSubtitle;

  /// No description provided for @disableSubtitles.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver les sous-titres'**
  String get disableSubtitles;

  /// No description provided for @dnsCloudflare.
  ///
  /// In fr, this message translates to:
  /// **'1.1.1.1 (Cloudflare DoH)'**
  String get dnsCloudflare;

  /// No description provided for @dnsGoogle.
  ///
  /// In fr, this message translates to:
  /// **'8.8.8.8 (Google DoH)'**
  String get dnsGoogle;

  /// No description provided for @dnsProvider.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur DNS (DoH)'**
  String get dnsProvider;

  /// No description provided for @dnsProviderSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Serveur utilisé pour les requêtes DNS over HTTPS'**
  String get dnsProviderSubtitle;

  /// No description provided for @dnsQuad9.
  ///
  /// In fr, this message translates to:
  /// **'9.9.9.9 (Quad9 DoH)'**
  String get dnsQuad9;

  /// No description provided for @dnsSystem.
  ///
  /// In fr, this message translates to:
  /// **'Automatique (Système)'**
  String get dnsSystem;

  /// No description provided for @downloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement impossible : {error}'**
  String downloadFailed(Object error);

  /// No description provided for @downloadAdded.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » ajouté aux téléchargements'**
  String downloadAdded(String title);

  /// No description provided for @downloadCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargé'**
  String get downloadCompleted;

  /// No description provided for @downloadInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement en cours'**
  String get downloadInProgress;

  /// No description provided for @downloadOffline.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger hors-ligne'**
  String get downloadOffline;

  /// No description provided for @downloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get downloads;

  /// No description provided for @dpadNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Navigation D-pad renforcée'**
  String get dpadNavigation;

  /// No description provided for @dpadNavigationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Focus visible, halo lumineux, wrap texte (TV mode)'**
  String get dpadNavigationSubtitle;

  /// No description provided for @enableParentalControl.
  ///
  /// In fr, this message translates to:
  /// **'Activer le contrôle parental'**
  String get enableParentalControl;

  /// No description provided for @enginesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Live : {live} · VOD : {vod}'**
  String enginesSubtitle(String live, String vod);

  /// No description provided for @enginesTile.
  ///
  /// In fr, this message translates to:
  /// **'Moteurs de lecture'**
  String get enginesTile;

  /// No description provided for @enterNew4DigitPin.
  ///
  /// In fr, this message translates to:
  /// **'Saisir un nouveau code à 4 chiffres'**
  String get enterNew4DigitPin;

  /// No description provided for @epgGrille.
  ///
  /// In fr, this message translates to:
  /// **'EPG (grille)'**
  String get epgGrille;

  /// No description provided for @epgGuideTv.
  ///
  /// In fr, this message translates to:
  /// **'Guide TV (EPG)'**
  String get epgGuideTv;

  /// No description provided for @episode.
  ///
  /// In fr, this message translates to:
  /// **'Épisode'**
  String get episode;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String errorGeneric(Object error);

  /// No description provided for @errorLoading.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement: {error}'**
  String errorLoading(Object error);

  /// No description provided for @errorSaving.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde'**
  String get errorSaving;

  /// No description provided for @exitWithoutSaving.
  ///
  /// In fr, this message translates to:
  /// **'Quitter sans sauvegarder ?'**
  String get exitWithoutSaving;

  /// No description provided for @failedToLoadProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les profils'**
  String get failedToLoadProfiles;

  /// No description provided for @fallbackEngine.
  ///
  /// In fr, this message translates to:
  /// **'Moteur de Secours'**
  String get fallbackEngine;

  /// No description provided for @favoriteGenres.
  ///
  /// In fr, this message translates to:
  /// **'Genres favoris'**
  String get favoriteGenres;

  /// No description provided for @filmsVod.
  ///
  /// In fr, this message translates to:
  /// **'Films (VOD)'**
  String get filmsVod;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @fontSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte augmentée'**
  String get fontSize;

  /// No description provided for @fontSizeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Agrandit les textes dans toute l\'app'**
  String get fontSizeSubtitle;

  /// No description provided for @forYou.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous'**
  String get forYou;

  /// No description provided for @forYouAndDuo.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous & En duo'**
  String get forYouAndDuo;

  /// No description provided for @forYouMatchmaking.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous (matchmaking)'**
  String get forYouMatchmaking;

  /// No description provided for @forward10s.
  ///
  /// In fr, this message translates to:
  /// **'Avancer 10s'**
  String get forward10s;

  /// No description provided for @forward30s.
  ///
  /// In fr, this message translates to:
  /// **'Avancer 30s'**
  String get forward30s;

  /// No description provided for @groupMode.
  ///
  /// In fr, this message translates to:
  /// **'En groupe'**
  String get groupMode;

  /// No description provided for @highContrast.
  ///
  /// In fr, this message translates to:
  /// **'Mode contraste élevé'**
  String get highContrast;

  /// No description provided for @highContrastSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Améliore la lisibilité pour les malvoyants'**
  String get highContrastSubtitle;

  /// No description provided for @historyUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Historique indisponible'**
  String get historyUnavailable;

  /// No description provided for @instantZapping.
  ///
  /// In fr, this message translates to:
  /// **'Zapping Instantané (Prefetching)'**
  String get instantZapping;

  /// No description provided for @instantZappingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Précharge les chaînes adjacentes en mémoire tampon'**
  String get instantZappingSubtitle;

  /// No description provided for @langArabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @langFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langPortuguese.
  ///
  /// In fr, this message translates to:
  /// **'Português'**
  String get langPortuguese;

  /// No description provided for @langSpanish.
  ///
  /// In fr, this message translates to:
  /// **'Español'**
  String get langSpanish;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageExample.
  ///
  /// In fr, this message translates to:
  /// **'Français, English, etc.'**
  String get languageExample;

  /// Option for disabling a track
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get noneOption;

  /// Play button for downloaded content
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get play;

  /// No description provided for @newAnd4K.
  ///
  /// In fr, this message translates to:
  /// **'Films à la demande'**
  String get newAnd4K;

  /// No description provided for @seasonsAndEpisodes.
  ///
  /// In fr, this message translates to:
  /// **'Séries à la demande'**
  String get seasonsAndEpisodes;

  /// No description provided for @languagePreference.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get languagePreference;

  /// No description provided for @languageUndetermined.
  ///
  /// In fr, this message translates to:
  /// **'Indéterminé'**
  String get languageUndetermined;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @legalNotice.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales / Contact'**
  String get legalNotice;

  /// No description provided for @contactTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contacter l’équipe'**
  String get contactTeamTitle;

  /// No description provided for @contactTeamIntro.
  ///
  /// In fr, this message translates to:
  /// **'Nous restons à votre écoute pour vos retours d’expérience, idées d’amélioration et signalements de bugs afin de faire évoluer l’application.'**
  String get contactTeamIntro;

  /// No description provided for @contactAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de contact :'**
  String get contactAddress;

  /// No description provided for @contactImportant.
  ///
  /// In fr, this message translates to:
  /// **'Important :'**
  String get contactImportant;

  /// No description provided for @contactTeamWarning.
  ///
  /// In fr, this message translates to:
  /// **'Les messages demandant une prolongation de période d’essai ou un mois gratuit ne recevront pas de réponse.'**
  String get contactTeamWarning;

  /// No description provided for @contactCompose.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un e-mail'**
  String get contactCompose;

  /// No description provided for @contactMailUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application de messagerie disponible.'**
  String get contactMailUnavailable;

  /// No description provided for @contactLegal.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get contactLegal;

  /// No description provided for @legalNoticeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Usage de l\'application, ayants droit et confidentialité'**
  String get legalNoticeSubtitle;

  /// No description provided for @liveChannelsAndZapping.
  ///
  /// In fr, this message translates to:
  /// **'Chaînes en direct & Zapping'**
  String get liveChannelsAndZapping;

  /// No description provided for @liveTv.
  ///
  /// In fr, this message translates to:
  /// **'Live TV'**
  String get liveTv;

  /// No description provided for @logsDiagnostic.
  ///
  /// In fr, this message translates to:
  /// **'Logs & Diagnostic'**
  String get logsDiagnostic;

  /// No description provided for @logsDiagnosticSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir les logs, exporter, vider le cache'**
  String get logsDiagnosticSubtitle;

  /// No description provided for @m3uPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'M3U Playlist'**
  String get m3uPlaylist;

  /// No description provided for @m3uPlaylistUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de la playlist M3U'**
  String get m3uPlaylistUrl;

  /// No description provided for @mainCast.
  ///
  /// In fr, this message translates to:
  /// **'Distribution principale'**
  String get mainCast;

  /// No description provided for @manualAvCalibration.
  ///
  /// In fr, this message translates to:
  /// **'Calibrage manuel A/V'**
  String get manualAvCalibration;

  /// No description provided for @manualAvCalibrationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Décalage actuel: {ms} ms'**
  String manualAvCalibrationSubtitle(int ms);

  /// No description provided for @matchmaking.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous (Matchmaking)'**
  String get matchmaking;

  /// No description provided for @matchmakingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer l\'appariement et les suggestions personnalisées'**
  String get matchmakingSubtitle;

  /// No description provided for @maxProfilesReached.
  ///
  /// In fr, this message translates to:
  /// **'Nombre maximal de profils atteint ({max})'**
  String maxProfilesReached(Object max);

  /// No description provided for @memory.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire'**
  String get memory;

  /// No description provided for @moreResults.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus de résultats'**
  String get moreResults;

  /// No description provided for @moviesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Films indisponibles'**
  String get moviesUnavailable;

  /// No description provided for @multiScreen.
  ///
  /// In fr, this message translates to:
  /// **'Multi-écrans'**
  String get multiScreen;

  /// No description provided for @multiVideo.
  ///
  /// In fr, this message translates to:
  /// **'Multi-vidéo'**
  String get multiVideo;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get myProfile;

  /// No description provided for @nameOptional.
  ///
  /// In fr, this message translates to:
  /// **'Nom (optionnel)'**
  String get nameOptional;

  /// No description provided for @nameOrNickname.
  ///
  /// In fr, this message translates to:
  /// **'Nom / Pseudo'**
  String get nameOrNickname;

  /// No description provided for @navigateToOkToSelect.
  ///
  /// In fr, this message translates to:
  /// **'Naviguer à OK pour sélectionner'**
  String get navigateToOkToSelect;

  /// No description provided for @networkDisconnected.
  ///
  /// In fr, this message translates to:
  /// **'Réseau coupé'**
  String get networkDisconnected;

  /// No description provided for @never.
  ///
  /// In fr, this message translates to:
  /// **'jamais'**
  String get never;

  /// No description provided for @newProfile.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau profil'**
  String get newProfile;

  /// No description provided for @nextChannel.
  ///
  /// In fr, this message translates to:
  /// **'Chaîne suivante'**
  String get nextChannel;

  /// No description provided for @nightFocusEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer Night Focus'**
  String get nightFocusEnable;

  /// No description provided for @nightFocusEnableSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Traitement audio temps réel : boost dialogues, coupe basses, sync'**
  String get nightFocusEnableSubtitle;

  /// No description provided for @nightFocusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Night Focus (Mode Nuit)'**
  String get nightFocusTitle;

  /// No description provided for @noAudioTrackDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune piste audio détectée'**
  String get noAudioTrackDetected;

  /// No description provided for @noChannelsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne disponible'**
  String get noChannelsAvailable;

  /// No description provided for @noChromecastDeviceFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appareil Chromecast trouvé.'**
  String get noChromecastDeviceFound;

  /// No description provided for @noDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement'**
  String get noDownloads;

  /// No description provided for @noEpisodes.
  ///
  /// In fr, this message translates to:
  /// **'Aucun épisode'**
  String get noEpisodes;

  /// No description provided for @noFavoriteChannels.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne favorite'**
  String get noFavoriteChannels;

  /// No description provided for @noFavoriteMovies.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film favori'**
  String get noFavoriteMovies;

  /// No description provided for @noFavoriteReplays.
  ///
  /// In fr, this message translates to:
  /// **'Aucun replay favori'**
  String get noFavoriteReplays;

  /// No description provided for @noFavoriteSeries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série favorite'**
  String get noFavoriteSeries;

  /// No description provided for @noGroupAffinity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune affinité commune trouvée'**
  String get noGroupAffinity;

  /// No description provided for @noHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique'**
  String get noHistory;

  /// No description provided for @historyLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de l’historique…'**
  String get historyLoading;

  /// No description provided for @historyEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Tes lectures récentes apparaîtront ici.'**
  String get historyEmptyHint;

  /// No description provided for @refreshAction.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refreshAction;

  /// No description provided for @favoritesAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get favoritesAdd;

  /// No description provided for @favoritesRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get favoritesRemove;

  /// No description provided for @favoritesNeedScope.
  ///
  /// In fr, this message translates to:
  /// **'Un profil et un abonnement actifs sont nécessaires.'**
  String get favoritesNeedScope;

  /// No description provided for @favoritesReplayHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur le cœur d’un replay pour le retrouver ici.'**
  String get favoritesReplayHint;

  /// No description provided for @favoritesClearPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Retirer les {total} favoris enregistrés ? La liste des favoris sera vidée.'**
  String favoritesClearPrompt(int total);

  /// No description provided for @noKidsChannels.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne pour enfants'**
  String get noKidsChannels;

  /// No description provided for @noKidsMovies.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film pour enfants'**
  String get noKidsMovies;

  /// No description provided for @noKidsReplays.
  ///
  /// In fr, this message translates to:
  /// **'Aucun replay pour enfants'**
  String get noKidsReplays;

  /// No description provided for @noKidsSeries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série pour enfants'**
  String get noKidsSeries;

  /// No description provided for @noMoviesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film disponible'**
  String get noMoviesAvailable;

  /// No description provided for @noProfileAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil disponible'**
  String get noProfileAvailable;

  /// No description provided for @noProfilesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil pour le moment'**
  String get noProfilesYet;

  /// No description provided for @noProgramInfoAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune information de programme disponible'**
  String get noProgramInfoAvailable;

  /// No description provided for @noRankings.
  ///
  /// In fr, this message translates to:
  /// **'Aucun classement'**
  String get noRankings;

  /// No description provided for @noRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recommandation disponible'**
  String get noRecommendations;

  /// No description provided for @noReplaysInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun replay dans cette catégorie'**
  String get noReplaysInCategory;

  /// No description provided for @noResultsFor.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour {query}'**
  String noResultsFor(Object query);

  /// No description provided for @noSeriesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série disponible'**
  String get noSeriesAvailable;

  /// No description provided for @noStationsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune station disponible'**
  String get noStationsAvailable;

  /// No description provided for @noVideoQualityDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune qualité vidéo détectée'**
  String get noVideoQualityDetected;

  /// No description provided for @notAvailableInCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible dans le catalogue'**
  String get notAvailableInCatalog;

  /// No description provided for @offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offline;

  /// No description provided for @parentalControl.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle parental'**
  String get parentalControl;

  /// No description provided for @parentalControlSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un code PIN et restreindre le contenu'**
  String get parentalControlSubtitle;

  /// No description provided for @pauseDownload.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause'**
  String get pauseDownload;

  /// No description provided for @pinCode.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get pinCode;

  /// No description provided for @pinRequired.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN requis'**
  String get pinRequired;

  /// No description provided for @pinSet.
  ///
  /// In fr, this message translates to:
  /// **'Définir un code PIN'**
  String get pinSet;

  /// No description provided for @pinThisProfile.
  ///
  /// In fr, this message translates to:
  /// **'ce profil'**
  String get pinThisProfile;

  /// No description provided for @pinEnterForProfile.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code PIN de {name}'**
  String pinEnterForProfile(String name);

  /// No description provided for @pinConfirmFourDigits.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre code à 4 chiffres'**
  String get pinConfirmFourDigits;

  /// No description provided for @pinChooseFourDigits.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un code à 4 chiffres'**
  String get pinChooseFourDigits;

  /// No description provided for @pinVerifyFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier le code PIN.'**
  String get pinVerifyFailed;

  /// No description provided for @pinConfirmInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Après 4 chiffres, appuyez sur ✓ pour valider.'**
  String get pinConfirmInstruction;

  /// No description provided for @pinIncorrectAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect — {count, plural, one{1 essai restant} other{{count} essais restants}}. Après 3 erreurs, blocage pendant 2 heures.'**
  String pinIncorrectAttempts(int count);

  /// No description provided for @pinTemporarilyLocked.
  ///
  /// In fr, this message translates to:
  /// **'Trop de codes incorrects. Réessayez dans {minutes} min.'**
  String pinTemporarilyLocked(int minutes);

  /// No description provided for @pinChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours…'**
  String get pinChecking;

  /// No description provided for @pinDeleted.
  ///
  /// In fr, this message translates to:
  /// **'PIN supprimé'**
  String get pinDeleted;

  /// No description provided for @pinMustBe4Digits.
  ///
  /// In fr, this message translates to:
  /// **'Le PIN doit contenir exactement 4 chiffres'**
  String get pinMustBe4Digits;

  /// No description provided for @pinSaved.
  ///
  /// In fr, this message translates to:
  /// **'PIN enregistré'**
  String get pinSaved;

  /// No description provided for @pip.
  ///
  /// In fr, this message translates to:
  /// **'Vue flottante (PiP)'**
  String get pip;

  /// No description provided for @pipUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Vue flottante (PiP) non disponible sur cet appareil'**
  String get pipUnavailable;

  /// No description provided for @playHistoryCleared.
  ///
  /// In fr, this message translates to:
  /// **'Historique de lecture effacé.'**
  String get playHistoryCleared;

  /// No description provided for @plusAgeYears.
  ///
  /// In fr, this message translates to:
  /// **'+{age} ans'**
  String plusAgeYears(Object age);

  /// No description provided for @preferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get preferences;

  /// No description provided for @previousChannel.
  ///
  /// In fr, this message translates to:
  /// **'Chaîne précédente'**
  String get previousChannel;

  /// No description provided for @primaryEngine.
  ///
  /// In fr, this message translates to:
  /// **'Moteur Principal'**
  String get primaryEngine;

  /// No description provided for @profilesSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count} profils sélectionnés'**
  String profilesSelected(int count);

  /// No description provided for @profileVisible.
  ///
  /// In fr, this message translates to:
  /// **'Profil visible'**
  String get profileVisible;

  /// No description provided for @programGrid.
  ///
  /// In fr, this message translates to:
  /// **'Grille des programmes'**
  String get programGrid;

  /// No description provided for @protectWithPin.
  ///
  /// In fr, this message translates to:
  /// **'Protéger par code PIN'**
  String get protectWithPin;

  /// No description provided for @rankingsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Classement indisponible'**
  String get rankingsUnavailable;

  /// No description provided for @recentSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche récente'**
  String get recentSearch;

  /// No description provided for @recentSearches.
  ///
  /// In fr, this message translates to:
  /// **'Récents'**
  String get recentSearches;

  /// No description provided for @recentlyWatched.
  ///
  /// In fr, this message translates to:
  /// **'Récemment'**
  String get recentlyWatched;

  /// No description provided for @removeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout retirer'**
  String get removeAll;

  /// No description provided for @removeFromWatchedConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tout retirer des déjà vus ?'**
  String get removeFromWatchedConfirm;

  /// No description provided for @replaysUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Replays indisponibles'**
  String get replaysUnavailable;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @resetApp.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'application'**
  String get resetApp;

  /// No description provided for @resetAppDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Les historiques locaux de lecture et de recherche seront effacés. Les profils, abonnements, données API, réglages TLS et de flux, ainsi que Cloudflare et les autres réglages seront conservés. Cette action est irréversible.'**
  String get resetAppDialogBody;

  /// No description provided for @resetAppDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetAppDialogConfirm;

  /// No description provided for @resetAppDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'application ?'**
  String get resetAppDialogTitle;

  /// No description provided for @resetAppSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface les historiques locaux en conservant les configurations et les profils'**
  String get resetAppSubtitle;

  /// No description provided for @resetFailed.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisation incomplète. Réessayez.'**
  String get resetFailed;

  /// No description provided for @resetCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisation effectuée'**
  String get resetCompleted;

  /// No description provided for @resumePlayback.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la lecture ?'**
  String get resumePlayback;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @tmdbMovieRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations TMDB'**
  String get tmdbMovieRecommendations;

  /// No description provided for @tmdbRecommendationsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recommandation TMDB pour ce film.'**
  String get tmdbRecommendationsEmpty;

  /// No description provided for @tmdbRecommendationsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les recommandations TMDB.'**
  String get tmdbRecommendationsError;

  /// No description provided for @tmdbRecommendationsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations TMDB indisponibles pour ce film.'**
  String get tmdbRecommendationsUnavailable;

  /// No description provided for @playbackDelayedTitle.
  ///
  /// In fr, this message translates to:
  /// **'La lecture prend du temps'**
  String get playbackDelayedTitle;

  /// No description provided for @playbackDelayedMessage.
  ///
  /// In fr, this message translates to:
  /// **'La lecture ne démarre pas ou ne reprend pas pour le moment. Le flux, la connexion ou le format vidéo peuvent être en cause.'**
  String get playbackDelayedMessage;

  /// No description provided for @playbackContinueWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Continuer à attendre'**
  String get playbackContinueWaiting;

  /// No description provided for @playbackUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lecture indisponible'**
  String get playbackUnavailableTitle;

  /// No description provided for @playbackUnavailableMessage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer ce film ou cet épisode pour le moment. Réessaie ou vérifie la connexion et le format du fichier.'**
  String get playbackUnavailableMessage;

  /// No description provided for @protectedPlaybackUnsupportedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le lecteur intégré ne peut pas lire en toute sécurité ce flux DASH ou relayé avec des en-têtes protégés.'**
  String get protectedPlaybackUnsupportedMessage;

  /// No description provided for @greenScreenDetectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Problème d’image détecté'**
  String get greenScreenDetectedTitle;

  /// No description provided for @externalPlayerLimitationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Limites des lecteurs externes'**
  String get externalPlayerLimitationsTitle;

  /// No description provided for @externalPlayerLimitationsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Avec VLC ou MX Player, les préférences audio et sous-titres d’Orbit ne sont pas transmises : choisissez les pistes dans le lecteur externe. Pour les séries, l’épisode suivant démarre automatiquement uniquement si MX Player confirme la fin ; sinon, lancez-le manuellement au retour dans Orbit. Cela concerne aussi le lecteur de secours.'**
  String get externalPlayerLimitationsDescription;

  /// No description provided for @actorShowFilmography.
  ///
  /// In fr, this message translates to:
  /// **'Voir la filmographie'**
  String get actorShowFilmography;

  /// No description provided for @actorFilmographyUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Filmographie indisponible.'**
  String get actorFilmographyUnavailable;

  /// No description provided for @actorCreditFilm.
  ///
  /// In fr, this message translates to:
  /// **'Film'**
  String get actorCreditFilm;

  /// No description provided for @actorCreditSeries.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get actorCreditSeries;

  /// No description provided for @actorCreditRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle : {role}'**
  String actorCreditRole(String role);

  /// No description provided for @actorCreditTmdbUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Détails TMDB indisponibles.'**
  String get actorCreditTmdbUnavailable;

  /// No description provided for @actorCreditSynopsisUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Synopsis indisponible.'**
  String get actorCreditSynopsisUnavailable;

  /// No description provided for @actorCreditCatalogUnconfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Correspondance non confirmée dans le catalogue.'**
  String get actorCreditCatalogUnconfirmed;

  /// No description provided for @actorCreditOpenCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Voir dans le catalogue'**
  String get actorCreditOpenCatalog;

  /// No description provided for @greenScreenDetectedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Une anomalie d’image (écran vert) a été détectée. Le moteur actuel ne semble pas décoder correctement ce flux. Essayez un autre moteur dans Réglages > Lecteur > Moteurs de lecture, puis relancez la lecture.'**
  String get greenScreenDetectedMessage;

  /// No description provided for @retrySearch.
  ///
  /// In fr, this message translates to:
  /// **'Relancer la recherche'**
  String get retrySearch;

  /// No description provided for @rewind10s.
  ///
  /// In fr, this message translates to:
  /// **'Reculer 10s'**
  String get rewind10s;

  /// No description provided for @rewind30s.
  ///
  /// In fr, this message translates to:
  /// **'Reculer 30s'**
  String get rewind30s;

  /// No description provided for @rightsHolders.
  ///
  /// In fr, this message translates to:
  /// **'Ayants droit'**
  String get rightsHolders;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Sauver'**
  String get save;

  /// No description provided for @sdkAndroid.
  ///
  /// In fr, this message translates to:
  /// **'SDK Android'**
  String get sdkAndroid;

  /// No description provided for @searchChannel.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une chaîne'**
  String get searchChannel;

  /// No description provided for @searchError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de recherche'**
  String get searchError;

  /// No description provided for @searchMovie.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un film'**
  String get searchMovie;

  /// No description provided for @searchSeries.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une série'**
  String get searchSeries;

  /// No description provided for @seasonNumber.
  ///
  /// In fr, this message translates to:
  /// **'Saison {season}'**
  String seasonNumber(Object season);

  /// No description provided for @sectionAccessibility.
  ///
  /// In fr, this message translates to:
  /// **'Accessibilité'**
  String get sectionAccessibility;

  /// No description provided for @sectionAccountProfile.
  ///
  /// In fr, this message translates to:
  /// **'Compte & Profil'**
  String get sectionAccountProfile;

  /// No description provided for @sectionAntiThrottle.
  ///
  /// In fr, this message translates to:
  /// **'Protection anti-bridage FAI'**
  String get sectionAntiThrottle;

  /// No description provided for @sectionAudioNight.
  ///
  /// In fr, this message translates to:
  /// **'Audio & Night Focus'**
  String get sectionAudioNight;

  /// No description provided for @sectionAvSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation A/V'**
  String get sectionAvSync;

  /// No description provided for @sectionBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde / Restauration'**
  String get sectionBackup;

  /// No description provided for @sectionCertPinning.
  ///
  /// In fr, this message translates to:
  /// **'Certificate Pinning (SHA-256)'**
  String get sectionCertPinning;

  /// No description provided for @sectionCloudSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation Cloud (multi-appareils)'**
  String get sectionCloudSync;

  /// No description provided for @sectionCloudflare.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation Cloudflare'**
  String get sectionCloudflare;

  /// No description provided for @sectionDiagnostics.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic & Maintenance'**
  String get sectionDiagnostics;

  /// No description provided for @sectionEngines.
  ///
  /// In fr, this message translates to:
  /// **'Moteurs de lecture'**
  String get sectionEngines;

  /// No description provided for @sectionLegal.
  ///
  /// In fr, this message translates to:
  /// **'Informations légales'**
  String get sectionLegal;

  /// No description provided for @sectionMemory.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire & Cache'**
  String get sectionMemory;

  /// No description provided for @sectionOutput.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Audio'**
  String get sectionOutput;

  /// No description provided for @sectionParental.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle parental'**
  String get sectionParental;

  /// No description provided for @sectionRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get sectionRecommendations;

  /// No description provided for @sectionResilience.
  ///
  /// In fr, this message translates to:
  /// **'Résilience du Service'**
  String get sectionResilience;

  /// No description provided for @sectionTmdb.
  ///
  /// In fr, this message translates to:
  /// **'Classements TMDB'**
  String get sectionTmdb;

  /// No description provided for @sectionZapping.
  ///
  /// In fr, this message translates to:
  /// **'Zapping & Performance'**
  String get sectionZapping;

  /// No description provided for @select.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get select;

  /// No description provided for @selectAtLeastOneProfile.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au moins 1 profil supplémentaire ({count}/4)'**
  String selectAtLeastOneProfile(int count);

  /// No description provided for @selectProfileForRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un profil pour voir ses recommandations'**
  String get selectProfileForRecommendations;

  /// No description provided for @series.
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get series;

  /// No description provided for @seriesNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Série introuvable'**
  String get seriesNotFound;

  /// No description provided for @seriesMissingId.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant de série manquant (navigation incorrecte). Retournez à la liste et réessayez.'**
  String get seriesMissingId;

  /// No description provided for @seriesEnriching.
  ///
  /// In fr, this message translates to:
  /// **'Enrichissement des métadonnées…'**
  String get seriesEnriching;

  /// No description provided for @seriesLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la série…'**
  String get seriesLoading;

  /// No description provided for @seriesNoEpisodesHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette série ne propose pas encore d’épisodes.'**
  String get seriesNoEpisodesHint;

  /// No description provided for @seriesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Séries indisponibles'**
  String get seriesUnavailable;

  /// No description provided for @seriesUnavailableTemporarily.
  ///
  /// In fr, this message translates to:
  /// **'Série indisponible pour le moment.'**
  String get seriesUnavailableTemporarily;

  /// No description provided for @serverProtectedAntiLeech.
  ///
  /// In fr, this message translates to:
  /// **'Serveur protégé (anti-leech)'**
  String get serverProtectedAntiLeech;

  /// No description provided for @serverUrlPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'URL du serveur (ex: https://provider.com)'**
  String get serverUrlPlaceholder;

  /// No description provided for @serviceNature.
  ///
  /// In fr, this message translates to:
  /// **'Nature du service'**
  String get serviceNature;

  /// No description provided for @setAsDefaultServer.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme serveur par défaut'**
  String get setAsDefaultServer;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration'**
  String get settingsTitle;

  /// No description provided for @similarMovies.
  ///
  /// In fr, this message translates to:
  /// **'Films similaires'**
  String get similarMovies;

  /// No description provided for @snackBackupExported.
  ///
  /// In fr, this message translates to:
  /// **'Configuration exportée dans le presse-papiers'**
  String get snackBackupExported;

  /// No description provided for @snackCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Caches vidés'**
  String get snackCacheCleared;

  /// No description provided for @snackCloudflareReset.
  ///
  /// In fr, this message translates to:
  /// **'Session Cloudflare renouvelée'**
  String get snackCloudflareReset;

  /// No description provided for @snackImportError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {message}'**
  String snackImportError(String message);

  /// No description provided for @snackImportSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Configuration importée avec succès'**
  String get snackImportSuccess;

  /// No description provided for @snackNoBackup.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde trouvée'**
  String get snackNoBackup;

  /// No description provided for @sortAffinity.
  ///
  /// In fr, this message translates to:
  /// **'Par affinité'**
  String get sortAffinity;

  /// No description provided for @sortAffinityDescription.
  ///
  /// In fr, this message translates to:
  /// **'Classe selon vos goûts déclarés dans le profil (matchmaking)'**
  String get sortAffinityDescription;

  /// No description provided for @sortAscending.
  ///
  /// In fr, this message translates to:
  /// **'Tri croissant'**
  String get sortAscending;

  /// No description provided for @sortByDuration.
  ///
  /// In fr, this message translates to:
  /// **'Par durée'**
  String get sortByDuration;

  /// No description provided for @sortByRating.
  ///
  /// In fr, this message translates to:
  /// **'Par note'**
  String get sortByRating;

  /// No description provided for @sortByYear.
  ///
  /// In fr, this message translates to:
  /// **'Par année'**
  String get sortByYear;

  /// No description provided for @sortDescending.
  ///
  /// In fr, this message translates to:
  /// **'Tri décroissant'**
  String get sortDescending;

  /// No description provided for @sortLatestM3UXtream.
  ///
  /// In fr, this message translates to:
  /// **'Derniers Ajouts M3U/Xtream'**
  String get sortLatestM3UXtream;

  /// No description provided for @sortNameAToZ.
  ///
  /// In fr, this message translates to:
  /// **'Nom (A → Z)'**
  String get sortNameAToZ;

  /// No description provided for @sortNameZToA.
  ///
  /// In fr, this message translates to:
  /// **'Nom (Z → A)'**
  String get sortNameZToA;

  /// No description provided for @sortResumePriority.
  ///
  /// In fr, this message translates to:
  /// **'À reprendre en priorité'**
  String get sortResumePriority;

  /// No description provided for @specialGuestsSeason.
  ///
  /// In fr, this message translates to:
  /// **'Invités spéciaux - Saison {season}'**
  String specialGuestsSeason(Object season);

  /// No description provided for @srtVttUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL .srt / .vtt'**
  String get srtVttUrl;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get start;

  /// No description provided for @stationsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Stations indisponibles'**
  String get stationsUnavailable;

  /// No description provided for @stopCasting.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la diffusion'**
  String get stopCasting;

  /// No description provided for @streamDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du flux'**
  String get streamDetails;

  /// No description provided for @subtitleLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement sous-titre: {error}'**
  String subtitleLoadError(Object error);

  /// No description provided for @subtitlesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres : non disponibles'**
  String get subtitlesUnavailable;

  /// No description provided for @system.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get system;

  /// No description provided for @tabAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get tabAccount;

  /// No description provided for @tabAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get tabAdvanced;

  /// No description provided for @tabAudio.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get tabAudio;

  /// No description provided for @tabNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Réseau'**
  String get tabNetwork;

  /// No description provided for @tabPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur'**
  String get tabPlayer;

  /// No description provided for @tabSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get tabSecurity;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @tlsImpersonation.
  ///
  /// In fr, this message translates to:
  /// **'TLS Impersonation (Proxy Local)'**
  String get tlsImpersonation;

  /// No description provided for @tlsImpersonationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Simule l\'empreinte d\'un navigateur moderne pour contourner Cloudflare'**
  String get tlsImpersonationSubtitle;

  /// No description provided for @tmdbKeyActive.
  ///
  /// In fr, this message translates to:
  /// **'Clé personnelle active — la clé partagée est ignorée'**
  String get tmdbKeyActive;

  /// No description provided for @tmdbKeyColumn.
  ///
  /// In fr, this message translates to:
  /// **'Clés TMDB'**
  String get tmdbKeyColumn;

  /// No description provided for @tmdbKeyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la clé personnelle'**
  String get tmdbKeyDelete;

  /// No description provided for @tmdbKeyHint.
  ///
  /// In fr, this message translates to:
  /// **'La clé partagée embarquée est utilisée par défaut'**
  String get tmdbKeyHint;

  /// No description provided for @tmdbKeyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Clé API TMDB personnelle (optionnel)'**
  String get tmdbKeyLabel;

  /// No description provided for @tmdbKeyShared.
  ///
  /// In fr, this message translates to:
  /// **'Clé partagée embarquée utilisée (aucune clé personnelle)'**
  String get tmdbKeyShared;

  /// No description provided for @tmdbKeyValid.
  ///
  /// In fr, this message translates to:
  /// **'Clé TMDB valide'**
  String get tmdbKeyValid;

  /// No description provided for @tmdbKeyValidationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Clé refusée par TMDB ou réseau indisponible : vérifiez la clé'**
  String get tmdbKeyValidationFailed;

  /// No description provided for @tvChannels.
  ///
  /// In fr, this message translates to:
  /// **'Chaînes TV'**
  String get tvChannels;

  /// No description provided for @unableToBuildReplayUrl.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de construire l\'URL du replay.'**
  String get unableToBuildReplayUrl;

  /// No description provided for @unlockCloudflare.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer (Cloudflare)'**
  String get unlockCloudflare;

  /// No description provided for @cloudflareCheckRequired.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du fournisseur requise'**
  String get cloudflareCheckRequired;

  /// No description provided for @cloudflareChallengeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur demande une vérification Cloudflare. Effectuez-la dans cette fenêtre, fermez-la puis réessayez. Les cookies de cette page ne sont pas transmis au lecteur : la lecture peut rester bloquée.'**
  String get cloudflareChallengeHelp;

  /// No description provided for @openProviderWebsite.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le site du fournisseur'**
  String get openProviderWebsite;

  /// No description provided for @providerWebsiteUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le site du fournisseur. Vérifiez l\'adresse de l\'abonnement et réessayez.'**
  String get providerWebsiteUnavailable;

  /// No description provided for @unstableConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion instable'**
  String get unstableConnection;

  /// No description provided for @updateAllData.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour toutes les données'**
  String get updateAllData;

  /// No description provided for @aiTopicsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sujets recommandés par IA'**
  String get aiTopicsTitle;

  /// No description provided for @updateThisCategory.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour cette catégorie'**
  String get updateThisCategory;

  /// No description provided for @updating.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour en cours…'**
  String get updating;

  /// No description provided for @updatingMediaContent.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour du contenu multimédia en cours…'**
  String get updatingMediaContent;

  /// No description provided for @volumeNormalization.
  ///
  /// In fr, this message translates to:
  /// **'Normalisation du volume'**
  String get volumeNormalization;

  /// No description provided for @volumeNormalizationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Limite les pics de volume entre chaînes/programmes (AGC)'**
  String get volumeNormalizationSubtitle;

  /// No description provided for @watchLive.
  ///
  /// In fr, this message translates to:
  /// **'Regarder en direct'**
  String get watchLive;

  /// No description provided for @whoIsWatching.
  ///
  /// In fr, this message translates to:
  /// **'Qui regarde ?'**
  String get whoIsWatching;

  /// No description provided for @xtreamCodes.
  ///
  /// In fr, this message translates to:
  /// **'Xtream Codes'**
  String get xtreamCodes;

  /// No description provided for @yourChannelsAndContent.
  ///
  /// In fr, this message translates to:
  /// **'Vos chaînes & contenus'**
  String get yourChannelsAndContent;

  /// No description provided for @subtitleSection.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres'**
  String get subtitleSection;

  /// No description provided for @seriesDefaultAudioLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue audio par défaut'**
  String get seriesDefaultAudioLanguage;

  /// No description provided for @seriesDefaultSubtitleLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue des sous-titres par défaut'**
  String get seriesDefaultSubtitleLanguage;

  /// No description provided for @seriesSelectLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une langue'**
  String get seriesSelectLanguage;

  /// No description provided for @seriesStreamDefault.
  ///
  /// In fr, this message translates to:
  /// **'(Défaut du flux)'**
  String get seriesStreamDefault;

  /// No description provided for @seriesChooseLanguageFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d’abord une langue'**
  String get seriesChooseLanguageFirst;

  /// No description provided for @seriesDefaultAllEpisodes.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le défaut du flux pour tous les épisodes'**
  String get seriesDefaultAllEpisodes;

  /// No description provided for @seriesDefaultUnlessEpisodeChoice.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le défaut du flux sauf choix par épisode'**
  String get seriesDefaultUnlessEpisodeChoice;

  /// No description provided for @seriesForceLanguageAllEpisodes.
  ///
  /// In fr, this message translates to:
  /// **'Forcer cette langue pour tous les épisodes'**
  String get seriesForceLanguageAllEpisodes;

  /// No description provided for @seriesApplyIfAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer si disponible'**
  String get seriesApplyIfAvailable;

  /// No description provided for @seriesSearchingAudio.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des pistes audio…'**
  String get seriesSearchingAudio;

  /// No description provided for @seriesSubtitlesDisabled.
  ///
  /// In fr, this message translates to:
  /// **'(Désactivés)'**
  String get seriesSubtitlesDisabled;

  /// No description provided for @seriesDisableSubtitlesAll.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver les sous-titres pour tous les épisodes'**
  String get seriesDisableSubtitlesAll;

  /// No description provided for @seriesDisableSubtitlesDefault.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver les sous-titres par défaut'**
  String get seriesDisableSubtitlesDefault;

  /// No description provided for @seriesSearchingSubtitles.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des pistes de sous-titres…'**
  String get seriesSearchingSubtitles;

  /// No description provided for @seriesNoSubtitleTracks.
  ///
  /// In fr, this message translates to:
  /// **'Aucune piste détectée : choisissez une langue, elle sera utilisée si disponible.'**
  String get seriesNoSubtitleTracks;

  /// No description provided for @seriesLanguageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get seriesLanguageFrench;

  /// No description provided for @seriesLanguageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get seriesLanguageEnglish;

  /// No description provided for @seriesLanguageSpanish.
  ///
  /// In fr, this message translates to:
  /// **'Espagnol'**
  String get seriesLanguageSpanish;

  /// No description provided for @seriesLanguageGerman.
  ///
  /// In fr, this message translates to:
  /// **'Allemand'**
  String get seriesLanguageGerman;

  /// No description provided for @seriesLanguageItalian.
  ///
  /// In fr, this message translates to:
  /// **'Italien'**
  String get seriesLanguageItalian;

  /// No description provided for @seriesLanguageArabic.
  ///
  /// In fr, this message translates to:
  /// **'Arabe'**
  String get seriesLanguageArabic;

  /// No description provided for @subtitleEmbeddedSection.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres intégrés'**
  String get subtitleEmbeddedSection;

  /// No description provided for @subtitleForcedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Forcé'**
  String get subtitleForcedLabel;

  /// No description provided for @subtitleEmbeddedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Intégré'**
  String get subtitleEmbeddedLabel;

  /// No description provided for @audioSection.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get audioSection;

  /// No description provided for @videoSection.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get videoSection;

  /// No description provided for @autoQuality.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get autoQuality;

  /// No description provided for @subtitleNotApplicable.
  ///
  /// In fr, this message translates to:
  /// **'Non applicable'**
  String get subtitleNotApplicable;

  /// No description provided for @subtitleNotApplicableInfo.
  ///
  /// In fr, this message translates to:
  /// **'Un flux direct ne publie pas de piste de sous-titre.'**
  String get subtitleNotApplicableInfo;

  /// No description provided for @subtitleUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get subtitleUnavailable;

  /// No description provided for @subtitleNoTrack.
  ///
  /// In fr, this message translates to:
  /// **'Aucune piste'**
  String get subtitleNoTrack;

  /// No description provided for @subtitleNoTrackInfo.
  ///
  /// In fr, this message translates to:
  /// **'Le panel ne publie de sous-titre pour ce contenu.'**
  String get subtitleNoTrackInfo;

  /// No description provided for @subtitleGuessed.
  ///
  /// In fr, this message translates to:
  /// **'Pistes déduites'**
  String get subtitleGuessed;

  /// No description provided for @subtitleGuessedInfo.
  ///
  /// In fr, this message translates to:
  /// **'Le panel ne déclare pas ses sous-titres : ces pistes sont obtenues par convention d\'URL. Celle qui n\'existe pas signale une erreur à l\'activation.'**
  String get subtitleGuessedInfo;

  /// No description provided for @subtitleUnavailableToast.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titre indisponible'**
  String get subtitleUnavailableToast;

  /// No description provided for @audioTrackFallback.
  ///
  /// In fr, this message translates to:
  /// **'Piste audio'**
  String get audioTrackFallback;

  /// No description provided for @subtitleLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des sous-titres…'**
  String get subtitleLoading;

  /// No description provided for @videoQualityFallback.
  ///
  /// In fr, this message translates to:
  /// **'Qualité vidéo'**
  String get videoQualityFallback;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @streamTracksError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire les pistes de ce flux.'**
  String get streamTracksError;

  /// No description provided for @subtitleProviderNoAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Le panel n\'a pas répondu.'**
  String get subtitleProviderNoAnswer;

  /// No description provided for @subtitleUnavailableDetail.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titre indisponible : {reason}'**
  String subtitleUnavailableDetail(Object reason);

  /// No description provided for @epgNoDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de programme'**
  String get epgNoDataTitle;

  /// No description provided for @epgLiveNow.
  ///
  /// In fr, this message translates to:
  /// **'En Direct'**
  String get epgLiveNow;

  /// No description provided for @epgSelectChannelHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une chaîne pour voir son programme'**
  String get epgSelectChannelHint;

  /// No description provided for @epgNow.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant'**
  String get epgNow;

  /// No description provided for @epgZoomIn.
  ///
  /// In fr, this message translates to:
  /// **'Zoomer'**
  String get epgZoomIn;

  /// No description provided for @epgZoomOut.
  ///
  /// In fr, this message translates to:
  /// **'Dézoomer'**
  String get epgZoomOut;

  /// No description provided for @epgNoCurrentProgram.
  ///
  /// In fr, this message translates to:
  /// **'Aucun programme en cours'**
  String get epgNoCurrentProgram;

  /// No description provided for @replayWindowBadge.
  ///
  /// In fr, this message translates to:
  /// **'Replay {days} j'**
  String replayWindowBadge(Object days);

  /// No description provided for @replayWindowBadgeHours.
  ///
  /// In fr, this message translates to:
  /// **'Replay {hours} h'**
  String replayWindowBadgeHours(Object hours);

  /// No description provided for @replayNoAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun replay disponible'**
  String get replayNoAvailable;

  /// No description provided for @replayNoneInArchiveDays.
  ///
  /// In fr, this message translates to:
  /// **'Aucun programme déjà diffusé dans les {days} jours d\'archives de ce compte pour cette chaîne.'**
  String replayNoneInArchiveDays(Object days);

  /// No description provided for @replayNonePublished.
  ///
  /// In fr, this message translates to:
  /// **'Le panel ne publie aucun programme déjà diffusé pour cette chaîne.'**
  String get replayNonePublished;

  /// No description provided for @epgActionFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Favori'**
  String get epgActionFavorite;

  /// No description provided for @epgActionRecording.
  ///
  /// In fr, this message translates to:
  /// **'Enreg.'**
  String get epgActionRecording;

  /// No description provided for @epgActionReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get epgActionReminder;

  /// No description provided for @epgStartReplay.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le replay'**
  String get epgStartReplay;

  /// No description provided for @epgBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get epgBack;

  /// No description provided for @epgWatchChannel.
  ///
  /// In fr, this message translates to:
  /// **'Regarder {name}'**
  String epgWatchChannel(Object name);

  /// No description provided for @subtitleNoneServedByPanel.
  ///
  /// In fr, this message translates to:
  /// **'Le panel ne sert aucun sous-titre pour ce contenu.'**
  String get subtitleNoneServedByPanel;

  /// No description provided for @subtitleVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification des sous-titres… ({count})'**
  String subtitleVerifying(Object count);

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @films.
  ///
  /// In fr, this message translates to:
  /// **'Films'**
  String get films;

  /// No description provided for @replay.
  ///
  /// In fr, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @myContent.
  ///
  /// In fr, this message translates to:
  /// **'Mes contenus'**
  String get myContent;

  /// No description provided for @contentTypeSelector.
  ///
  /// In fr, this message translates to:
  /// **'Type de contenu'**
  String get contentTypeSelector;

  /// No description provided for @downloadStatusDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement'**
  String get downloadStatusDownloading;

  /// No description provided for @downloadStatusPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get downloadStatusPreparing;

  /// No description provided for @downloadStatusPaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get downloadStatusPaused;

  /// No description provided for @downloadStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get downloadStatusCompleted;

  /// No description provided for @downloadStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get downloadStatusFailed;

  /// No description provided for @downloadStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get downloadStatusCancelled;

  /// No description provided for @downloadStatusQueued.
  ///
  /// In fr, this message translates to:
  /// **'En file'**
  String get downloadStatusQueued;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @explore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get explore;

  /// No description provided for @downloadsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des contenus depuis les détails d\'un film ou d\'une série.'**
  String get downloadsEmptyHint;

  /// No description provided for @downloadsLocation.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers'**
  String get downloadsLocation;

  /// No description provided for @advancedSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages avancés'**
  String get advancedSettingsTitle;

  /// No description provided for @freeMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode gratuit'**
  String get freeMode;

  /// No description provided for @freeModePending.
  ///
  /// In fr, this message translates to:
  /// **'Option à configurer ultérieurement, sans effet pour le moment.'**
  String get freeModePending;

  /// No description provided for @advancedSettingsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants d\'API et paramètres réseau. Ces réglages engagent votre compte auprès de services tiers : une clé partagée consomme son quota, et une mauvaise manipulation du réseau peut empêcher l\'application de démarrer.'**
  String get advancedSettingsIntro;

  /// No description provided for @advancedStatus.
  ///
  /// In fr, this message translates to:
  /// **'État des identifiants'**
  String get advancedStatus;

  /// No description provided for @advancedAccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé'**
  String get advancedAccessTitle;

  /// No description provided for @advancedAccessHint.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get advancedAccessHint;

  /// No description provided for @advancedAccessConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get advancedAccessConfirm;

  /// No description provided for @advancedAccessWrong.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect'**
  String get advancedAccessWrong;

  /// No description provided for @advancedHiddenHint.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir appuyé pour les réglages avancés'**
  String get advancedHiddenHint;

  /// No description provided for @favoritesAndDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Favoris et Téléchargements'**
  String get favoritesAndDownloads;

  /// No description provided for @activeAudio.
  ///
  /// In fr, this message translates to:
  /// **'Son actif sur cet écran'**
  String get activeAudio;

  /// No description provided for @addChannel.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une chaîne'**
  String get addChannel;

  /// No description provided for @noChannelSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaîne sélectionnée'**
  String get noChannelSelected;

  /// No description provided for @removeChannel.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la chaîne'**
  String get removeChannel;

  /// No description provided for @avatarCategoryAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get avatarCategoryAll;

  /// No description provided for @avatarCategoryCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Personnages'**
  String get avatarCategoryCharacters;

  /// No description provided for @avatarCategorySuperheroes.
  ///
  /// In fr, this message translates to:
  /// **'Super-héros'**
  String get avatarCategorySuperheroes;

  /// No description provided for @avatarCategoryAnimals.
  ///
  /// In fr, this message translates to:
  /// **'Animaux'**
  String get avatarCategoryAnimals;

  /// No description provided for @avatarCategoryFlowers.
  ///
  /// In fr, this message translates to:
  /// **'Fleurs'**
  String get avatarCategoryFlowers;

  /// No description provided for @avatarCategoryNature.
  ///
  /// In fr, this message translates to:
  /// **'Nature'**
  String get avatarCategoryNature;

  /// No description provided for @avatarCategoryYouth.
  ///
  /// In fr, this message translates to:
  /// **'Jeunesse'**
  String get avatarCategoryYouth;

  /// No description provided for @avatarCategorySmileys.
  ///
  /// In fr, this message translates to:
  /// **'Smileys'**
  String get avatarCategorySmileys;

  /// No description provided for @avatarCategoryBlackWhite.
  ///
  /// In fr, this message translates to:
  /// **'Noir & Blanc'**
  String get avatarCategoryBlackWhite;

  /// No description provided for @updateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mises à jour'**
  String get updateTitle;

  /// No description provided for @updateSettingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier la dernière version officielle sur GitHub'**
  String get updateSettingsSubtitle;

  /// No description provided for @updateChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours…'**
  String get updateChecking;

  /// No description provided for @updateCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Vous utilisez déjà la dernière version disponible.'**
  String get updateCurrent;

  /// No description provided for @updateAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle version est disponible :'**
  String get updateAvailable;

  /// No description provided for @updateDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement et vérification de l’APK…'**
  String get updateDownloading;

  /// No description provided for @updateReady.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture de l’installateur Android…'**
  String get updateReady;

  /// No description provided for @updatePermission.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez Orbit à installer des applications inconnues dans les réglages Android, puis revenez ici et réessayez.'**
  String get updatePermission;

  /// No description provided for @updateNoRelease.
  ///
  /// In fr, this message translates to:
  /// **'Aucune release stable n’est disponible sur GitHub.'**
  String get updateNoRelease;

  /// No description provided for @updateAssetError.
  ///
  /// In fr, this message translates to:
  /// **'La release ne contient pas l’APK universel officiel ou ses informations de vérification.'**
  String get updateAssetError;

  /// No description provided for @updateInvalidApk.
  ///
  /// In fr, this message translates to:
  /// **'APK incompatible, signé avec une autre clé ou version Android non supérieure. Installation annulée.'**
  String get updateInvalidApk;

  /// No description provided for @updateIntegrityError.
  ///
  /// In fr, this message translates to:
  /// **'La vérification du fichier téléchargé a échoué. Installation annulée.'**
  String get updateIntegrityError;

  /// No description provided for @updateGenericError.
  ///
  /// In fr, this message translates to:
  /// **'La mise à jour a échoué. Vérifiez la connexion et réessayez.'**
  String get updateGenericError;

  /// No description provided for @updateLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get updateLater;

  /// No description provided for @updateInstall.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateInstall;

  /// No description provided for @updateRetryInstall.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer l’installation'**
  String get updateRetryInstall;

  /// No description provided for @updateRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get updateRetry;

  /// No description provided for @avatarCategoryPixels.
  ///
  /// In fr, this message translates to:
  /// **'Pixels'**
  String get avatarCategoryPixels;

  /// No description provided for @unassignedLegacyLibraryItems.
  ///
  /// In fr, this message translates to:
  /// **'Certains anciens favoris ou téléchargements ne sont pas affichés : leur abonnement d’origine est inconnu. Ils restent conservés.'**
  String get unassignedLegacyLibraryItems;

  /// No description provided for @forceNoSubtitlesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactive automatiquement les sous-titres au lancement d\'un film ou d\'une série'**
  String get forceNoSubtitlesSubtitle;

  /// No description provided for @backTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get backTooltip;

  /// No description provided for @categoryFilters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres de catégories'**
  String get categoryFilters;

  /// No description provided for @categoryFiltersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories masquées par abonnement'**
  String get categoryFiltersSubtitle;

  /// No description provided for @memoryCacheTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de la Mémoire & Cache'**
  String get memoryCacheTitle;

  /// No description provided for @memoryCacheSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Libérez de l\'espace et nettoyez les données locales.'**
  String get memoryCacheSubtitle;

  /// No description provided for @clearWatchHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider l\'historique des vues'**
  String get clearWatchHistoryTitle;

  /// No description provided for @clearWatchHistorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface la liste des récemment regardés et les positions de reprise.'**
  String get clearWatchHistorySubtitle;

  /// No description provided for @clearWatchHistoryAction.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearWatchHistoryAction;

  /// No description provided for @clearCoverCacheTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyer le cache des pochettes'**
  String get clearCoverCacheTitle;

  /// No description provided for @clearCoverCacheSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Libère l\'espace disque occupé par les vignettes VOD/EPG stockées localement.'**
  String get clearCoverCacheSubtitle;

  /// No description provided for @clearCoverCacheAction.
  ///
  /// In fr, this message translates to:
  /// **'Purger'**
  String get clearCoverCacheAction;

  /// No description provided for @enginesDescription.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le moteur utilisé pour chaque type de contenu, ainsi que le moteur de secours en cas d\'échec de lecture.'**
  String get enginesDescription;

  /// No description provided for @sortAdvancedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Options de Tri Avancé'**
  String get sortAdvancedTitle;

  /// No description provided for @sortAdvancedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un mode avec la télécommande :'**
  String get sortAdvancedSubtitle;

  /// No description provided for @sortDescRecentlyAdded.
  ///
  /// In fr, this message translates to:
  /// **'Contenus importés récemment dans la liste'**
  String get sortDescRecentlyAdded;

  /// No description provided for @sortDescResumePriority.
  ///
  /// In fr, this message translates to:
  /// **'Place les contenus commencés non terminés en haut'**
  String get sortDescResumePriority;

  /// No description provided for @sortDescByRating.
  ///
  /// In fr, this message translates to:
  /// **'Classement selon les notes attribuées'**
  String get sortDescByRating;

  /// No description provided for @sortDescByYear.
  ///
  /// In fr, this message translates to:
  /// **'Tri chronologique par année de production'**
  String get sortDescByYear;

  /// No description provided for @sortDescByDuration.
  ///
  /// In fr, this message translates to:
  /// **'Tri par durée du contenu'**
  String get sortDescByDuration;

  /// No description provided for @sortOptionActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get sortOptionActive;

  /// No description provided for @showAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout afficher'**
  String get showAll;

  /// No description provided for @noActiveSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif'**
  String get noActiveSubscription;

  /// No description provided for @noVodCategories.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie Films sur ce panel.'**
  String get noVodCategories;

  /// No description provided for @noSeriesCategories.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie Séries sur ce panel.'**
  String get noSeriesCategories;

  /// No description provided for @neverScanned.
  ///
  /// In fr, this message translates to:
  /// **'Jamais analysé'**
  String get neverScanned;

  /// No description provided for @scannedToday.
  ///
  /// In fr, this message translates to:
  /// **'Analysé aujourd\'hui'**
  String get scannedToday;

  /// No description provided for @scannedYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Analysé hier'**
  String get scannedYesterday;

  /// No description provided for @scannedDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Analysé il y a {days} jours'**
  String scannedDaysAgo(int days);

  /// No description provided for @subscriptionSettingsNote.
  ///
  /// In fr, this message translates to:
  /// **'Réglages propres à cet abonnement — {scanned}'**
  String subscriptionSettingsNote(String scanned);

  /// No description provided for @rescanCategories.
  ///
  /// In fr, this message translates to:
  /// **'Réanalyser les catégories'**
  String get rescanCategories;

  /// No description provided for @scanningCategories.
  ///
  /// In fr, this message translates to:
  /// **'Analyse…'**
  String get scanningCategories;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'it'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
