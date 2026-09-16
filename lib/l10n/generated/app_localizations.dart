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

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Orbit IPTV'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration'**
  String get settingsTitle;

  /// No description provided for @tabAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get tabAccount;

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

  /// No description provided for @tabAudio.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get tabAudio;

  /// No description provided for @tabAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get tabAdvanced;

  /// No description provided for @sectionAccountProfile.
  ///
  /// In fr, this message translates to:
  /// **'Compte & Profil'**
  String get sectionAccountProfile;

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

  /// No description provided for @sectionCloudSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation Cloud (multi-appareils)'**
  String get sectionCloudSync;

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

  /// No description provided for @cloudSyncSubtitleOff.
  ///
  /// In fr, this message translates to:
  /// **'Synchronise favoris, vus et récents vers le cloud'**
  String get cloudSyncSubtitleOff;

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

  /// No description provided for @never.
  ///
  /// In fr, this message translates to:
  /// **'jamais'**
  String get never;

  /// No description provided for @sectionNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

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

  /// No description provided for @sectionBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde / Restauration'**
  String get sectionBackup;

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

  /// No description provided for @snackBackupExported.
  ///
  /// In fr, this message translates to:
  /// **'Configuration exportée dans le presse-papiers'**
  String get snackBackupExported;

  /// No description provided for @snackNoBackup.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde trouvée'**
  String get snackNoBackup;

  /// No description provided for @snackImportSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Configuration importée avec succès'**
  String get snackImportSuccess;

  /// No description provided for @snackImportError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {message}'**
  String snackImportError(String message);

  /// No description provided for @sectionAntiThrottle.
  ///
  /// In fr, this message translates to:
  /// **'Protection anti-bridage FAI'**
  String get sectionAntiThrottle;

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

  /// No description provided for @sectionCloudflare.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation Cloudflare'**
  String get sectionCloudflare;

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

  /// No description provided for @snackCloudflareReset.
  ///
  /// In fr, this message translates to:
  /// **'Config Cloudflare réinitialisée'**
  String get snackCloudflareReset;

  /// No description provided for @sectionEngines.
  ///
  /// In fr, this message translates to:
  /// **'Moteurs de lecture'**
  String get sectionEngines;

  /// No description provided for @enginesTile.
  ///
  /// In fr, this message translates to:
  /// **'Moteurs de lecture'**
  String get enginesTile;

  /// No description provided for @enginesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Live : {live} · VOD : {vod}'**
  String enginesSubtitle(String live, String vod);

  /// No description provided for @sectionAudioNight.
  ///
  /// In fr, this message translates to:
  /// **'Audio & Night Focus'**
  String get sectionAudioNight;

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

  /// No description provided for @sectionZapping.
  ///
  /// In fr, this message translates to:
  /// **'Zapping & Performance'**
  String get sectionZapping;

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

  /// No description provided for @sectionMemory.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire & Cache'**
  String get sectionMemory;

  /// No description provided for @sectionParental.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle parental'**
  String get sectionParental;

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

  /// No description provided for @sectionCertPinning.
  ///
  /// In fr, this message translates to:
  /// **'Certificate Pinning (SHA-256)'**
  String get sectionCertPinning;

  /// No description provided for @certPinning.
  ///
  /// In fr, this message translates to:
  /// **'Activer Certificate Pinning'**
  String get certPinning;

  /// No description provided for @certPinningSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie l\'empreinte SHA-256 du certificat SSL du serveur (anti-MITM)'**
  String get certPinningSubtitle;

  /// No description provided for @certPinningHint.
  ///
  /// In fr, this message translates to:
  /// **'Empreintes autorisées (une par ligne, format hex uppercase) :'**
  String get certPinningHint;

  /// No description provided for @certPinningAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter les empreintes ci-dessus'**
  String get certPinningAdd;

  /// No description provided for @sectionResilience.
  ///
  /// In fr, this message translates to:
  /// **'Résilience du Service'**
  String get sectionResilience;

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

  /// No description provided for @sectionLegal.
  ///
  /// In fr, this message translates to:
  /// **'Informations légales'**
  String get sectionLegal;

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

  /// No description provided for @nightFocusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Night Focus (Mode Nuit)'**
  String get nightFocusTitle;

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

  /// No description provided for @sectionAvSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation A/V'**
  String get sectionAvSync;

  /// No description provided for @audioShift.
  ///
  /// In fr, this message translates to:
  /// **'Décalage audio configurable'**
  String get audioShift;

  /// No description provided for @audioShiftSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Décalage audio/vidéo manuel (ms)'**
  String get audioShiftSubtitle;

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

  /// No description provided for @sectionOutput.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Audio'**
  String get sectionOutput;

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

  /// No description provided for @avSyncDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calibrage A/V'**
  String get avSyncDialogTitle;

  /// No description provided for @avSyncDialogLabel.
  ///
  /// In fr, this message translates to:
  /// **'Décalage (ms)'**
  String get avSyncDialogLabel;

  /// No description provided for @avSyncDialogHint.
  ///
  /// In fr, this message translates to:
  /// **'Positif = audio en avance, Négatif = audio en retard'**
  String get avSyncDialogHint;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @sectionAccessibility.
  ///
  /// In fr, this message translates to:
  /// **'Accessibilité'**
  String get sectionAccessibility;

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

  /// No description provided for @sectionTmdb.
  ///
  /// In fr, this message translates to:
  /// **'Classements TMDB'**
  String get sectionTmdb;

  /// No description provided for @sectionRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get sectionRecommendations;

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

  /// No description provided for @sectionDiagnostics.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic & Maintenance'**
  String get sectionDiagnostics;

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

  /// No description provided for @resetApp.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'application'**
  String get resetApp;

  /// No description provided for @resetAppSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface toutes les données utilisateur (profils, favoris, historique)'**
  String get resetAppSubtitle;

  /// No description provided for @snackCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Caches vidés (TODO)'**
  String get snackCacheCleared;

  /// No description provided for @resetAppDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'application ?'**
  String get resetAppDialogTitle;

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

  /// No description provided for @tmdbKeyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Clé API TMDB personnelle (optionnel)'**
  String get tmdbKeyLabel;

  /// No description provided for @tmdbKeyHint.
  ///
  /// In fr, this message translates to:
  /// **'La clé partagée embarquée est utilisée par défaut'**
  String get tmdbKeyHint;

  /// No description provided for @tmdbKeyActive.
  ///
  /// In fr, this message translates to:
  /// **'Clé personnelle active — la clé partagée est ignorée'**
  String get tmdbKeyActive;

  /// No description provided for @tmdbKeyShared.
  ///
  /// In fr, this message translates to:
  /// **'Clé partagée embarquée utilisée (aucune clé personnelle)'**
  String get tmdbKeyShared;

  /// No description provided for @tmdbKeyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la clé personnelle'**
  String get tmdbKeyDelete;

  /// No description provided for @tmdbKeyColumn.
  ///
  /// In fr, this message translates to:
  /// **'Clés TMDB'**
  String get tmdbKeyColumn;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languagePreference.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get languagePreference;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Sauver'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;
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
