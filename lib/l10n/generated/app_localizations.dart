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
  /// **'Langue, thème, restrictions d\'âge, PIN'**
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
  /// **'Dernière sync : {time}'**
  String cloudSyncLastSync(String time);

  /// No description provided for @cloudSyncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get cloudSyncNow;

  /// No description provided for @cloudSyncNowSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pousse les modifications locales vers le cloud'**
  String get cloudSyncNowSubtitle;

  /// No description provided for @cloudSyncSubtitleOff.
  ///
  /// In fr, this message translates to:
  /// **'Synchronise favoris, vus et récents vers le cloud'**
  String get cloudSyncSubtitleOff;

  /// No description provided for @cloudflareReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser config Cloudflare'**
  String get cloudflareReset;

  /// No description provided for @cloudflareResetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface cookies, remet TLS Impersonation=OFF, UA ExoPlayer par défaut'**
  String get cloudflareResetSubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

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

  /// No description provided for @dataAlreadyFresh.
  ///
  /// In fr, this message translates to:
  /// **'Données déjà fraîches (moins de 30 min)'**
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

  /// No description provided for @kidsContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenus adaptés aux enfants'**
  String get kidsContent;

  /// No description provided for @kidsMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode Enfants'**
  String get kidsMode;

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
  /// **'Lisez-moi · Mentions légales'**
  String get legalNotice;

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

  /// No description provided for @newAnd4K.
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés & 4K'**
  String get newAnd4K;

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

  /// No description provided for @noHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique'**
  String get noHistory;

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

  /// No description provided for @receiveAlertsAndTips.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir les alertes et conseils'**
  String get receiveAlertsAndTips;

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
  /// **'Toutes les données seront effacées : profils, favoris, historique, réglages. Cette action est irréversible.'**
  String get resetAppDialogBody;

  /// No description provided for @resetAppDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get resetAppDialogConfirm;

  /// No description provided for @resetAppDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'application ?'**
  String get resetAppDialogTitle;

  /// No description provided for @resetAppSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface toutes les données utilisateur (profils, favoris, historique)'**
  String get resetAppSubtitle;

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

  /// No description provided for @seasonsAndEpisodes.
  ///
  /// In fr, this message translates to:
  /// **'Saisons & Épisodes'**
  String get seasonsAndEpisodes;

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

  /// No description provided for @sectionNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

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
  /// **'Caches vidés (TODO)'**
  String get snackCacheCleared;

  /// No description provided for @snackCloudflareReset.
  ///
  /// In fr, this message translates to:
  /// **'Config Cloudflare réinitialisée'**
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

  /// No description provided for @sortBestRated.
  ///
  /// In fr, this message translates to:
  /// **'Les Mieux Notés (XCIPTV)'**
  String get sortBestRated;

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

  /// No description provided for @sortYearRecentToOld.
  ///
  /// In fr, this message translates to:
  /// **'Année de Sortie (Récent → Ancien)'**
  String get sortYearRecentToOld;

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

  /// No description provided for @testNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Tester les notifications'**
  String get testNotifications;

  /// No description provided for @testNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoie une notification locale de test'**
  String get testNotificationsSubtitle;

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
