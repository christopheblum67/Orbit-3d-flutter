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
  /// **'Profil {label} Â· diagnostic lecteur'**
  String accountDeviceProfileSubtitle(String label);

  /// No description provided for @accountNoSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif'**
  String get accountNoSubscription;

  /// No description provided for @accountPreferences.
  ///
  /// In fr, this message translates to:
  /// **'PrÃ©fÃ©rences profil'**
  String get accountPreferences;

  /// No description provided for @accountPreferencesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue, thÃ¨me, restrictions d\'Ã¢ge, PIN'**
  String get accountPreferencesSubtitle;

  /// No description provided for @accountProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Profils utilisateurs'**
  String get accountProfiles;

  /// No description provided for @accountProfilesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'GÃ©rer les profils et le profil actif'**
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
  /// **'Â« {title} Â» ajoutÃ© aux favoris'**
  String addedToFavorites(Object title);

  /// No description provided for @age.
  ///
  /// In fr, this message translates to:
  /// **'Ã‚ge'**
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
  /// **'ApparaÃ®tre dans les recherches et recommandations'**
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
  /// **'DÃ©calage audio configurable'**
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
  /// **'DÃ©calage audio/vidÃ©o manuel (ms)'**
  String get audioShiftSubtitle;

  /// No description provided for @autoQualityDescription.
  ///
  /// In fr, this message translates to:
  /// **'Laisse le lecteur choisir la meilleure qualitÃ©'**
  String get autoQualityDescription;

  /// No description provided for @autoReconnectLive.
  ///
  /// In fr, this message translates to:
  /// **'Auto-rÃ©connexion Live'**
  String get autoReconnectLive;

  /// No description provided for @autoReconnectLiveSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tente de reconnecter automatiquement si le flux coupe'**
  String get autoReconnectLiveSubtitle;

  /// No description provided for @avSyncDialogHint.
  ///
  /// In fr, this message translates to:
  /// **'Positif = audio en avance, NÃ©gatif = audio en retard'**
  String get avSyncDialogHint;

  /// No description provided for @avSyncDialogLabel.
  ///
  /// In fr, this message translates to:
  /// **'DÃ©calage (ms)'**
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
  /// **'Copie la config complÃ¨te dans le presse-papiers'**
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
  /// **'AttÃ©nue les basses frÃ©quences pour Ã©viter les vibrations'**
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
  /// **'Rattrapage des chaÃ®nes'**
  String get catchUpTv;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'CatÃ©gories'**
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
  /// **'Empreintes autorisÃ©es (une par ligne, format hex uppercase) :'**
  String get certPinningHint;

  /// No description provided for @certPinningSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'VÃ©rifie l\'empreinte SHA-256 du certificat SSL du serveur (anti-MITM)'**
  String get certPinningSubtitle;

  /// No description provided for @changePinCode.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code PIN'**
  String get changePinCode;

  /// No description provided for @channelsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'ChaÃ®nes indisponibles'**
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
  /// **'Images, index recherche, mÃ©tadonnÃ©es TMDB/TVmaze'**
  String get clearCachesSubtitle;

  /// No description provided for @cloudSyncEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation activÃ©e'**
  String get cloudSyncEnabled;

  /// No description provided for @cloudSyncLastSync.
  ///
  /// In fr, this message translates to:
  /// **'DerniÃ¨re sync : {time}'**
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
  /// **'Synchronise favoris, vus et rÃ©cents vers le cloud'**
  String get cloudSyncSubtitleOff;

  /// No description provided for @cloudflareReset.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©initialiser config Cloudflare'**
  String get cloudflareReset;

  /// No description provided for @cloudflareResetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface cookies, remet TLS Impersonation=OFF, UA ExoPlayer par dÃ©faut'**
  String get cloudflareResetSubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'BientÃ´t disponible'**
  String get comingSoon;

  /// No description provided for @confirmAndContinue.
  ///
  /// In fr, this message translates to:
  /// **'Valider et continuer'**
  String get confirmAndContinue;

  /// No description provided for @coverCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Cache des pochettes purgÃ©.'**
  String get coverCacheCleared;

  /// No description provided for @createKidProfile.
  ///
  /// In fr, this message translates to:
  /// **'CrÃ©er un profil Enfant'**
  String get createKidProfile;

  /// No description provided for @createNewProfile.
  ///
  /// In fr, this message translates to:
  /// **'CrÃ©er un nouveau profil'**
  String get createNewProfile;

  /// No description provided for @createProfile.
  ///
  /// In fr, this message translates to:
  /// **'CrÃ©er un profil'**
  String get createProfile;

  /// No description provided for @currentProfileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Profil courant : {name}'**
  String currentProfileLabel(String name);

  /// No description provided for @dataAlreadyFresh.
  ///
  /// In fr, this message translates to:
  /// **'DonnÃ©es dÃ©jÃ  fraÃ®ches (moins de 30 min)'**
  String get dataAlreadyFresh;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'DonnÃ©es & confidentialitÃ©'**
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
  /// **'DÃ©tail indisponible'**
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
  /// **'DÃ©sactiver les sous-titres'**
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
  /// **'Serveur utilisÃ© pour les requÃªtes DNS over HTTPS'**
  String get dnsProviderSubtitle;

  /// No description provided for @dnsQuad9.
  ///
  /// In fr, this message translates to:
  /// **'9.9.9.9 (Quad9 DoH)'**
  String get dnsQuad9;

  /// No description provided for @dnsSystem.
  ///
  /// In fr, this message translates to:
  /// **'Automatique (SystÃ¨me)'**
  String get dnsSystem;

  /// No description provided for @downloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'TÃ©lÃ©chargement impossible : {error}'**
  String downloadFailed(Object error);

  /// No description provided for @downloads.
  ///
  /// In fr, this message translates to:
  /// **'TÃ©lÃ©chargements'**
  String get downloads;

  /// No description provided for @dpadNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Navigation D-pad renforcÃ©e'**
  String get dpadNavigation;

  /// No description provided for @dpadNavigationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Focus visible, halo lumineux, wrap texte (TV mode)'**
  String get dpadNavigationSubtitle;

  /// No description provided for @enableParentalControl.
  ///
  /// In fr, this message translates to:
  /// **'Activer le contrÃ´le parental'**
  String get enableParentalControl;

  /// No description provided for @enginesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Live : {live} Â· VOD : {vod}'**
  String enginesSubtitle(String live, String vod);

  /// No description provided for @enginesTile.
  ///
  /// In fr, this message translates to:
  /// **'Moteurs de lecture'**
  String get enginesTile;

  /// No description provided for @enterNew4DigitPin.
  ///
  /// In fr, this message translates to:
  /// **'Saisir un nouveau code Ã  4 chiffres'**
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
  /// **'Ã‰pisode'**
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
  /// **'PrÃ©nom'**
  String get firstName;

  /// No description provided for @fontSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte augmentÃ©e'**
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
  /// **'Mode contraste Ã©levÃ©'**
  String get highContrast;

  /// No description provided for @highContrastSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'AmÃ©liore la lisibilitÃ© pour les malvoyants'**
  String get highContrastSubtitle;

  /// No description provided for @historyUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Historique indisponible'**
  String get historyUnavailable;

  /// No description provided for @instantZapping.
  ///
  /// In fr, this message translates to:
  /// **'Zapping InstantanÃ© (Prefetching)'**
  String get instantZapping;

  /// No description provided for @instantZappingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'PrÃ©charge les chaÃ®nes adjacentes en mÃ©moire tampon'**
  String get instantZappingSubtitle;

  /// No description provided for @langArabic.
  ///
  /// In fr, this message translates to:
  /// **'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©'**
  String get langArabic;

  /// No description provided for @langFrench.
  ///
  /// In fr, this message translates to:
  /// **'FranÃ§ais'**
  String get langFrench;

  /// No description provided for @langPortuguese.
  ///
  /// In fr, this message translates to:
  /// **'PortuguÃªs'**
  String get langPortuguese;

  /// No description provided for @langSpanish.
  ///
  /// In fr, this message translates to:
  /// **'EspaÃ±ol'**
  String get langSpanish;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageExample.
  ///
  /// In fr, this message translates to:
  /// **'FranÃ§ais, English, etc.'**
  String get languageExample;

  /// No description provided for @languagePreference.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get languagePreference;

  /// No description provided for @languageUndetermined.
  ///
  /// In fr, this message translates to:
  /// **'IndÃ©terminÃ©'**
  String get languageUndetermined;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @legalNotice.
  ///
  /// In fr, this message translates to:
  /// **'Lisez-moi Â· Mentions lÃ©gales'**
  String get legalNotice;

  /// No description provided for @legalNoticeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Usage de l\'application, ayants droit et confidentialitÃ©'**
  String get legalNoticeSubtitle;

  /// No description provided for @liveChannelsAndZapping.
  ///
  /// In fr, this message translates to:
  /// **'ChaÃ®nes en direct & Zapping'**
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
  /// **'DÃ©calage actuel: {ms} ms'**
  String manualAvCalibrationSubtitle(int ms);

  /// No description provided for @matchmaking.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous (Matchmaking)'**
  String get matchmaking;

  /// No description provided for @matchmakingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'GÃ©rer l\'appariement et les suggestions personnalisÃ©es'**
  String get matchmakingSubtitle;

  /// No description provided for @maxProfilesReached.
  ///
  /// In fr, this message translates to:
  /// **'Nombre maximal de profils atteint ({max})'**
  String maxProfilesReached(Object max);

  /// No description provided for @memory.
  ///
  /// In fr, this message translates to:
  /// **'MÃ©moire'**
  String get memory;

  /// No description provided for @moreResults.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus de rÃ©sultats'**
  String get moreResults;

  /// No description provided for @moviesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Films indisponibles'**
  String get moviesUnavailable;

  /// No description provided for @multiScreen.
  ///
  /// In fr, this message translates to:
  /// **'Multi-Ã©crans'**
  String get multiScreen;

  /// No description provided for @multiVideo.
  ///
  /// In fr, this message translates to:
  /// **'Multi-vidÃ©o'**
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
  /// **'Naviguer Ã  OK pour sÃ©lectionner'**
  String get navigateToOkToSelect;

  /// No description provided for @networkDisconnected.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©seau coupÃ©'**
  String get networkDisconnected;

  /// No description provided for @never.
  ///
  /// In fr, this message translates to:
  /// **'jamais'**
  String get never;

  /// No description provided for @newAnd4K.
  ///
  /// In fr, this message translates to:
  /// **'Films Ã  la demande'**
  String get newAnd4K;

  /// No description provided for @newProfile.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau profil'**
  String get newProfile;

  /// No description provided for @nextChannel.
  ///
  /// In fr, this message translates to:
  /// **'ChaÃ®ne suivante'**
  String get nextChannel;

  /// No description provided for @nightFocusEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer Night Focus'**
  String get nightFocusEnable;

  /// No description provided for @nightFocusEnableSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Traitement audio temps rÃ©el : boost dialogues, coupe basses, sync'**
  String get nightFocusEnableSubtitle;

  /// No description provided for @nightFocusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Night Focus (Mode Nuit)'**
  String get nightFocusTitle;

  /// No description provided for @noAudioTrackDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune piste audio dÃ©tectÃ©e'**
  String get noAudioTrackDetected;

  /// No description provided for @noChannelsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaÃ®ne disponible'**
  String get noChannelsAvailable;

  /// No description provided for @noChromecastDeviceFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appareil Chromecast trouvÃ©.'**
  String get noChromecastDeviceFound;

  /// No description provided for @noDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tÃ©lÃ©chargement'**
  String get noDownloads;

  /// No description provided for @noEpisodes.
  ///
  /// In fr, this message translates to:
  /// **'Aucun Ã©pisode'**
  String get noEpisodes;

  /// No description provided for @noFavoriteChannels.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaÃ®ne favorite'**
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
  /// **'Aucune sÃ©rie favorite'**
  String get noFavoriteSeries;

  /// No description provided for @noGroupAffinity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune affinitÃ© commune trouvÃ©e'**
  String get noGroupAffinity;

  /// No description provided for @noHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique'**
  String get noHistory;

  /// No description provided for @noKidsChannels.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaÃ®ne pour enfants'**
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
  /// **'Aucune sÃ©rie pour enfants'**
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
  /// **'Aucun replay dans cette catÃ©gorie'**
  String get noReplaysInCategory;

  /// No description provided for @noResultsFor.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rÃ©sultat pour {query}'**
  String noResultsFor(Object query);

  /// No description provided for @noSeriesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sÃ©rie disponible'**
  String get noSeriesAvailable;

  /// No description provided for @noStationsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune station disponible'**
  String get noStationsAvailable;

  /// No description provided for @noVideoQualityDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune qualitÃ© vidÃ©o dÃ©tectÃ©e'**
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
  /// **'ContrÃ´le parental'**
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

  /// No description provided for @play.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get play;

  /// No description provided for @pinCode.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get pinCode;

  /// No description provided for @pinDeleted.
  ///
  /// In fr, this message translates to:
  /// **'PIN supprimÃ©'**
  String get pinDeleted;

  /// No description provided for @pinMustBe4Digits.
  ///
  /// In fr, this message translates to:
  /// **'Le PIN doit contenir exactement 4 chiffres'**
  String get pinMustBe4Digits;

  /// No description provided for @pinSaved.
  ///
  /// In fr, this message translates to:
  /// **'PIN enregistrÃ©'**
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
  /// **'Historique de lecture effacÃ©.'**
  String get playHistoryCleared;

  /// No description provided for @plusAgeYears.
  ///
  /// In fr, this message translates to:
  /// **'+{age} ans'**
  String plusAgeYears(Object age);

  /// No description provided for @preferences.
  ///
  /// In fr, this message translates to:
  /// **'PrÃ©fÃ©rences'**
  String get preferences;

  /// No description provided for @previousChannel.
  ///
  /// In fr, this message translates to:
  /// **'ChaÃ®ne prÃ©cÃ©dente'**
  String get previousChannel;

  /// No description provided for @primaryEngine.
  ///
  /// In fr, this message translates to:
  /// **'Moteur Principal'**
  String get primaryEngine;

  /// No description provided for @profilesSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count} profils sÃ©lectionnÃ©s'**
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
  /// **'ProtÃ©ger par code PIN'**
  String get protectWithPin;

  /// No description provided for @rankingsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Classement indisponible'**
  String get rankingsUnavailable;

  /// No description provided for @recentSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche rÃ©cente'**
  String get recentSearch;

  /// No description provided for @recentSearches.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©cents'**
  String get recentSearches;

  /// No description provided for @recentlyWatched.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©cemment'**
  String get recentlyWatched;

  /// No description provided for @removeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout retirer'**
  String get removeAll;

  /// No description provided for @removeFromWatchedConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tout retirer des dÃ©jÃ  vus ?'**
  String get removeFromWatchedConfirm;

  /// No description provided for @replaysUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Replays indisponibles'**
  String get replaysUnavailable;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©initialiser'**
  String get reset;

  /// No description provided for @resetApp.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©initialiser l\'application'**
  String get resetApp;

  /// No description provided for @resetAppDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les donnÃ©es seront effacÃ©es : profils, favoris, historique, rÃ©glages. Cette action est irrÃ©versible.'**
  String get resetAppDialogBody;

  /// No description provided for @resetAppDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get resetAppDialogConfirm;

  /// No description provided for @resetAppDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©initialiser l\'application ?'**
  String get resetAppDialogTitle;

  /// No description provided for @resetAppSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface toutes les donnÃ©es utilisateur (profils, favoris, historique)'**
  String get resetAppSubtitle;

  /// No description provided for @resetCompleted.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©initialisation effectuÃ©e'**
  String get resetCompleted;

  /// No description provided for @resumePlayback.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la lecture ?'**
  String get resumePlayback;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©essayer'**
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
  /// **'Rechercher une chaÃ®ne'**
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
  /// **'Rechercher une sÃ©rie'**
  String get searchSeries;

  /// No description provided for @seasonNumber.
  ///
  /// In fr, this message translates to:
  /// **'Saison {season}'**
  String seasonNumber(Object season);

  /// No description provided for @seasonsAndEpisodes.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©ries Ã  la demande'**
  String get seasonsAndEpisodes;

  /// No description provided for @sectionAccessibility.
  ///
  /// In fr, this message translates to:
  /// **'AccessibilitÃ©'**
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
  /// **'Informations lÃ©gales'**
  String get sectionLegal;

  /// No description provided for @sectionMemory.
  ///
  /// In fr, this message translates to:
  /// **'MÃ©moire & Cache'**
  String get sectionMemory;

  /// No description provided for @sectionOutput.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Audio'**
  String get sectionOutput;

  /// No description provided for @sectionParental.
  ///
  /// In fr, this message translates to:
  /// **'ContrÃ´le parental'**
  String get sectionParental;

  /// No description provided for @sectionRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get sectionRecommendations;

  /// No description provided for @sectionResilience.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©silience du Service'**
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
  /// **'SÃ©lectionner'**
  String get select;

  /// No description provided for @selectAtLeastOneProfile.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©lectionnez au moins 1 profil supplÃ©mentaire ({count}/4)'**
  String selectAtLeastOneProfile(int count);

  /// No description provided for @selectProfileForRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©lectionnez un profil pour voir ses recommandations'**
  String get selectProfileForRecommendations;

  /// No description provided for @series.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©ries'**
  String get series;

  /// No description provided for @seriesNotFound.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©rie introuvable'**
  String get seriesNotFound;

  /// No description provided for @seriesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©ries indisponibles'**
  String get seriesUnavailable;

  /// No description provided for @seriesUnavailableTemporarily.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©rie indisponible pour le moment.'**
  String get seriesUnavailableTemporarily;

  /// No description provided for @serverProtectedAntiLeech.
  ///
  /// In fr, this message translates to:
  /// **'Serveur protÃ©gÃ© (anti-leech)'**
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
  /// **'DÃ©finir comme serveur par dÃ©faut'**
  String get setAsDefaultServer;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©glages'**
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
  /// **'Configuration exportÃ©e dans le presse-papiers'**
  String get snackBackupExported;

  /// No description provided for @snackCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Caches vidÃ©s'**
  String get snackCacheCleared;

  /// No description provided for @snackCloudflareReset.
  ///
  /// In fr, this message translates to:
  /// **'Config Cloudflare rÃ©initialisÃ©e'**
  String get snackCloudflareReset;

  /// No description provided for @snackImportError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {message}'**
  String snackImportError(String message);

  /// No description provided for @snackImportSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Configuration importÃ©e avec succÃ¨s'**
  String get snackImportSuccess;

  /// No description provided for @snackNoBackup.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde trouvÃ©e'**
  String get snackNoBackup;

  /// No description provided for @sortAffinity.
  ///
  /// In fr, this message translates to:
  /// **'Par affinitÃ©'**
  String get sortAffinity;

  /// No description provided for @sortAffinityDescription.
  ///
  /// In fr, this message translates to:
  /// **'Classe selon vos goÃ»ts dÃ©clarÃ©s dans le profil (matchmaking)'**
  String get sortAffinityDescription;

  /// No description provided for @sortAscending.
  ///
  /// In fr, this message translates to:
  /// **'Tri croissant'**
  String get sortAscending;

  /// No description provided for @sortByDuration.
  ///
  /// In fr, this message translates to:
  /// **'Par durÃ©e'**
  String get sortByDuration;

  /// No description provided for @sortByRating.
  ///
  /// In fr, this message translates to:
  /// **'Par note'**
  String get sortByRating;

  /// No description provided for @sortByYear.
  ///
  /// In fr, this message translates to:
  /// **'Par annÃ©e'**
  String get sortByYear;

  /// No description provided for @sortDescending.
  ///
  /// In fr, this message translates to:
  /// **'Tri dÃ©croissant'**
  String get sortDescending;

  /// No description provided for @sortLatestM3UXtream.
  ///
  /// In fr, this message translates to:
  /// **'Derniers Ajouts M3U/Xtream'**
  String get sortLatestM3UXtream;

  /// No description provided for @sortNameAToZ.
  ///
  /// In fr, this message translates to:
  /// **'Nom (A â†’ Z)'**
  String get sortNameAToZ;

  /// No description provided for @sortNameZToA.
  ///
  /// In fr, this message translates to:
  /// **'Nom (Z â†’ A)'**
  String get sortNameZToA;

  /// No description provided for @sortResumePriority.
  ///
  /// In fr, this message translates to:
  /// **'Ã€ reprendre en prioritÃ©'**
  String get sortResumePriority;

  /// No description provided for @specialGuestsSeason.
  ///
  /// In fr, this message translates to:
  /// **'InvitÃ©s spÃ©ciaux - Saison {season}'**
  String specialGuestsSeason(Object season);

  /// No description provided for @srtVttUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL .srt / .vtt'**
  String get srtVttUrl;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'DÃ©marrer'**
  String get start;

  /// No description provided for @stationsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Stations indisponibles'**
  String get stationsUnavailable;

  /// No description provided for @stopCasting.
  ///
  /// In fr, this message translates to:
  /// **'ArrÃªter la diffusion'**
  String get stopCasting;

  /// No description provided for @streamDetails.
  ///
  /// In fr, this message translates to:
  /// **'DÃ©tails du flux'**
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
  /// **'SystÃ¨me'**
  String get system;

  /// No description provided for @tabAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get tabAccount;

  /// No description provided for @tabAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'AvancÃ©'**
  String get tabAdvanced;

  /// No description provided for @tabAudio.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get tabAudio;

  /// No description provided for @tabNetwork.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©seau'**
  String get tabNetwork;

  /// No description provided for @tabPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur'**
  String get tabPlayer;

  /// No description provided for @tabSecurity.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©curitÃ©'**
  String get tabSecurity;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'ThÃ¨me'**
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
  /// **'ClÃ© personnelle active â€” la clÃ© partagÃ©e est ignorÃ©e'**
  String get tmdbKeyActive;

  /// No description provided for @tmdbKeyColumn.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ©s TMDB'**
  String get tmdbKeyColumn;

  /// No description provided for @tmdbKeyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la clÃ© personnelle'**
  String get tmdbKeyDelete;

  /// No description provided for @tmdbKeyHint.
  ///
  /// In fr, this message translates to:
  /// **'La clÃ© partagÃ©e embarquÃ©e est utilisÃ©e par dÃ©faut'**
  String get tmdbKeyHint;

  /// No description provided for @tmdbKeyLabel.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© API TMDB personnelle (optionnel)'**
  String get tmdbKeyLabel;

  /// No description provided for @tmdbKeyShared.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© partagÃ©e embarquÃ©e utilisÃ©e (aucune clÃ© personnelle)'**
  String get tmdbKeyShared;

  /// No description provided for @tvChannels.
  ///
  /// In fr, this message translates to:
  /// **'ChaÃ®nes TV'**
  String get tvChannels;

  /// No description provided for @unableToBuildReplayUrl.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de construire l\'URL du replay.'**
  String get unableToBuildReplayUrl;

  /// No description provided for @unlockCloudflare.
  ///
  /// In fr, this message translates to:
  /// **'DÃ©bloquer (Cloudflare)'**
  String get unlockCloudflare;

  /// No description provided for @unstableConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion instable'**
  String get unstableConnection;

  /// No description provided for @updateAllData.
  ///
  /// In fr, this message translates to:
  /// **'Mettre Ã  jour toutes les donnÃ©es'**
  String get updateAllData;

  /// No description provided for @aiTopicsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sujets recommandÃ©s par IA'**
  String get aiTopicsTitle;

  /// No description provided for @updateThisCategory.
  ///
  /// In fr, this message translates to:
  /// **'Mettre Ã  jour cette catÃ©gorie'**
  String get updateThisCategory;

  /// No description provided for @updating.
  ///
  /// In fr, this message translates to:
  /// **'Mise Ã  jour en coursâ€¦'**
  String get updating;

  /// No description provided for @updatingMediaContent.
  ///
  /// In fr, this message translates to:
  /// **'Mise Ã  jour du contenu multimÃ©dia en coursâ€¦'**
  String get updatingMediaContent;

  /// No description provided for @volumeNormalization.
  ///
  /// In fr, this message translates to:
  /// **'Normalisation du volume'**
  String get volumeNormalization;

  /// No description provided for @volumeNormalizationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Limite les pics de volume entre chaÃ®nes/programmes (AGC)'**
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
  /// **'Vos chaÃ®nes & contenus'**
  String get yourChannelsAndContent;

  /// No description provided for @subtitleSection.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres'**
  String get subtitleSection;

  /// No description provided for @audioSection.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get audioSection;

  /// No description provided for @videoSection.
  ///
  /// In fr, this message translates to:
  /// **'VidÃ©o'**
  String get videoSection;

  /// No description provided for @autoQuality.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get autoQuality;

  /// No description provided for @noneOption.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get noneOption;

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
  /// **'Pistes dÃ©duites'**
  String get subtitleGuessed;

  /// No description provided for @subtitleGuessedInfo.
  ///
  /// In fr, this message translates to:
  /// **'Le panel ne dÃ©clare pas ses sous-titres : ces pistes sont obtenues par convention d\'URL. Celle qui n\'existe pas signale une erreur Ã  l\'activation.'**
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
  /// **'Chargement des sous-titresâ€¦'**
  String get subtitleLoading;

  /// No description provided for @videoQualityFallback.
  ///
  /// In fr, this message translates to:
  /// **'QualitÃ© vidÃ©o'**
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
  /// **'Le panel n\'a pas rÃ©pondu.'**
  String get subtitleProviderNoAnswer;

  /// No description provided for @subtitleUnavailableDetail.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titre indisponible : {reason}'**
  String subtitleUnavailableDetail(Object reason);

  /// No description provided for @epgNoDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnÃ©e de programme'**
  String get epgNoDataTitle;

  /// No description provided for @epgLiveNow.
  ///
  /// In fr, this message translates to:
  /// **'En Direct'**
  String get epgLiveNow;

  /// No description provided for @epgSelectChannelHint.
  ///
  /// In fr, this message translates to:
  /// **'SÃ©lectionnez une chaÃ®ne pour voir son programme'**
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
  /// **'DÃ©zoomer'**
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
  /// **'Aucun programme dÃ©jÃ  diffusÃ© dans les {days} jours d\'archives de ce compte pour cette chaÃ®ne.'**
  String replayNoneInArchiveDays(Object days);

  /// No description provided for @replayNonePublished.
  ///
  /// In fr, this message translates to:
  /// **'Le panel ne publie aucun programme dÃ©jÃ  diffusÃ© pour cette chaÃ®ne.'**
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
  /// **'VÃ©rification des sous-titresâ€¦ ({count})'**
  String subtitleVerifying(Object count);

  /// No description provided for @subtitleSearchOnline.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher en ligne'**
  String get subtitleSearchOnline;

  /// No description provided for @subtitleSearchOnlineInfo.
  ///
  /// In fr, this message translates to:
  /// **'Le panel ne propose rien pour ce contenu. Une recherche en ligne peut trouver un sous-titre.'**
  String get subtitleSearchOnlineInfo;

  /// No description provided for @subtitleSearchOnlineRunning.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en coursâ€¦'**
  String get subtitleSearchOnlineRunning;

  /// No description provided for @subtitleOnlineResults.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres trouvÃ©s en ligne'**
  String get subtitleOnlineResults;

  /// No description provided for @subtitleOnlineEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sous-titre trouvÃ© en ligne pour ce contenu.'**
  String get subtitleOnlineEmpty;

  /// No description provided for @subtitleOnlineDownloads.
  ///
  /// In fr, this message translates to:
  /// **'{count} tÃ©lÃ©chargements'**
  String subtitleOnlineDownloads(Object count);

  /// No description provided for @subtitleOnlineNoTmdb.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'identifier ce contenu sur TMDB : la recherche en ligne a besoin de son identifiant.'**
  String get subtitleOnlineNoTmdb;

  /// No description provided for @opensubtitlesKeyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de sous-titres en ligne (OpenSubtitles)'**
  String get opensubtitlesKeyLabel;

  /// No description provided for @opensubtitlesKeyHint.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© API â€” facultative'**
  String get opensubtitlesKeyHint;

  /// No description provided for @opensubtitlesKeyActive.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© enregistrÃ©e : quota de tÃ©lÃ©chargement relevÃ©.'**
  String get opensubtitlesKeyActive;

  /// No description provided for @opensubtitlesKeyAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Aucune clÃ© : recherche possible, 5 tÃ©lÃ©chargements par IP et par 24 h.'**
  String get opensubtitlesKeyAnonymous;

  /// No description provided for @opensubtitlesKeyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la clÃ©'**
  String get opensubtitlesKeyDelete;

  /// No description provided for @opensubtitlesKeyCheck.
  ///
  /// In fr, this message translates to:
  /// **'VÃ©rifier la clÃ©'**
  String get opensubtitlesKeyCheck;

  /// No description provided for @opensubtitlesKeyChecking.
  ///
  /// In fr, this message translates to:
  /// **'VÃ©rification en coursâ€¦'**
  String get opensubtitlesKeyChecking;

  /// No description provided for @opensubtitlesKeyValid.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© valide : le service l\'accepte.'**
  String get opensubtitlesKeyValid;

  /// No description provided for @opensubtitlesKeyRejected.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© refusÃ©e par le service : vÃ©rifiez que vous l\'avez copiÃ©e en entier.'**
  String get opensubtitlesKeyRejected;

  /// No description provided for @opensubtitlesKeyUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Service injoignable : vÃ©rifiez votre connexion et rÃ©essayez.'**
  String get opensubtitlesKeyUnreachable;

  /// No description provided for @opensubtitlesLoginLabel.
  ///
  /// In fr, this message translates to:
  /// **'Connexion au compte OpenSubtitles'**
  String get opensubtitlesLoginLabel;

  /// No description provided for @opensubtitlesLoginHintUsername.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get opensubtitlesLoginHintUsername;

  /// No description provided for @opensubtitlesLoginHintPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get opensubtitlesLoginHintPassword;

  /// No description provided for @opensubtitlesLoginActive.
  ///
  /// In fr, this message translates to:
  /// **'Compte enregistrÃ© : les tÃ©lÃ©chargements pourront se connecter.'**
  String get opensubtitlesLoginActive;

  /// No description provided for @opensubtitlesLoginNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte : le tÃ©lÃ©chargement reste refusÃ© (503).'**
  String get opensubtitlesLoginNone;

  /// No description provided for @opensubtitlesLoginDelete.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le compte'**
  String get opensubtitlesLoginDelete;

  /// No description provided for @opensubtitlesLoginConnect.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter / vÃ©rifier'**
  String get opensubtitlesLoginConnect;

  /// No description provided for @opensubtitlesLoginConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en coursâ€¦'**
  String get opensubtitlesLoginConnecting;

  /// No description provided for @opensubtitlesLoginValid.
  ///
  /// In fr, this message translates to:
  /// **'Compte acceptÃ© : le service dÃ©livre un jeton.'**
  String get opensubtitlesLoginValid;

  /// No description provided for @opensubtitlesLoginRejected.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants refusÃ©s : vÃ©rifiez l\'identifiant et le mot de passe.'**
  String get opensubtitlesLoginRejected;

  /// No description provided for @opensubtitlesLoginUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Service injoignable : vÃ©rifiez votre connexion et rÃ©essayez.'**
  String get opensubtitlesLoginUnreachable;

  /// No description provided for @subtitleOnlineNoApiKey.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© API OpenSubtitles absente : saisissez-la dans RÃ©glages pour activer la recherche en ligne.'**
  String get subtitleOnlineNoApiKey;

  /// No description provided for @subtitleOnlineKeyRejected.
  ///
  /// In fr, this message translates to:
  /// **'ClÃ© API OpenSubtitles refusÃ©e : elle est prÃ©sente mais le service la rejette. VÃ©rifiez sa validitÃ© dans RÃ©glages.'**
  String get subtitleOnlineKeyRejected;

  /// No description provided for @subtitleOnlineQuota.
  ///
  /// In fr, this message translates to:
  /// **'Quota de tÃ©lÃ©chargement OpenSubtitles atteint pour aujourd\'hui. RÃ©essayez demain.'**
  String get subtitleOnlineQuota;

  /// No description provided for @subtitleOnlineNeedsLogin.
  ///
  /// In fr, this message translates to:
  /// **'Le tÃ©lÃ©chargement OpenSubtitles exige un compte connectÃ©, pas seulement la clÃ© API : la recherche fonctionne, mais le tÃ©lÃ©chargement est refusÃ©.'**
  String get subtitleOnlineNeedsLogin;

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
  /// **'TÃ©lÃ©chargement'**
  String get downloadStatusDownloading;

  /// No description provided for @downloadStatusPreparing.
  ///
  /// In fr, this message translates to:
  /// **'PrÃ©paration'**
  String get downloadStatusPreparing;

  /// No description provided for @downloadStatusPaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get downloadStatusPaused;

  /// No description provided for @downloadStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'TerminÃ©'**
  String get downloadStatusCompleted;

  /// No description provided for @downloadStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Ã‰chec'**
  String get downloadStatusFailed;

  /// No description provided for @downloadStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'AnnulÃ©'**
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
  /// **'Ajoutez des contenus depuis les dÃ©tails d\'un film ou d\'une sÃ©rie.'**
  String get downloadsEmptyHint;

  /// No description provided for @downloadsLocation.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers'**
  String get downloadsLocation;

  /// No description provided for @advancedSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'RÃ©glages avancÃ©s'**
  String get advancedSettingsTitle;

  /// No description provided for @advancedSettingsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants d\'API et paramÃ¨tres rÃ©seau. Ces rÃ©glages engagent votre compte auprÃ¨s de services tiers : une clÃ© partagÃ©e consomme son quota, et une mauvaise manipulation du rÃ©seau peut empÃªcher l\'application de dÃ©marrer.'**
  String get advancedSettingsIntro;

  /// No description provided for @advancedSubtitlesProvider.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur de sous-titres'**
  String get advancedSubtitlesProvider;

  /// No description provided for @advancedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Ã‰tat des identifiants'**
  String get advancedStatus;

  /// No description provided for @advancedAccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'AccÃ¨s rÃ©servÃ©'**
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
  /// **'Maintenir appuyÃ© pour les rÃ©glages avancÃ©s'**
  String get advancedHiddenHint;

  /// No description provided for @favoritesAndDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Favoris et TÃ©lÃ©chargements'**
  String get favoritesAndDownloads;

  /// No description provided for @activeAudio.
  ///
  /// In fr, this message translates to:
  /// **'Son actif sur cet Ã©cran'**
  String get activeAudio;

  /// No description provided for @addChannel.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une chaÃ®ne'**
  String get addChannel;

  /// No description provided for @noChannelSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chaÃ®ne sÃ©lectionnÃ©e'**
  String get noChannelSelected;

  /// No description provided for @removeChannel.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la chaÃ®ne'**
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

  /// No description provided for @avatarCategoryPixels.
  ///
  /// In fr, this message translates to:
  /// **'Pixels'**
  String get avatarCategoryPixels;
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
