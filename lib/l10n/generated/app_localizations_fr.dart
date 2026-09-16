// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get settingsTitle => 'Configuration';

  @override
  String get tabAccount => 'Compte';

  @override
  String get tabNetwork => 'Réseau';

  @override
  String get tabPlayer => 'Lecteur';

  @override
  String get tabSecurity => 'Sécurité';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabAdvanced => 'Avancé';

  @override
  String get sectionAccountProfile => 'Compte & Profil';

  @override
  String get accountProfiles => 'Profils utilisateurs';

  @override
  String get accountProfilesSubtitle => 'Gérer les profils et le profil actif';

  @override
  String get accountSubscriptions => 'Abonnements Xtream/M3U';

  @override
  String get accountNoSubscription => 'Aucun abonnement actif';

  @override
  String get accountPreferences => 'Préférences profil';

  @override
  String get accountPreferencesSubtitle =>
      'Langue, thème, restrictions d\'âge, PIN';

  @override
  String get accountDeviceProfile => 'Profil appareil & Diagnostic';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profil $label · diagnostic lecteur';
  }

  @override
  String get sectionCloudSync => 'Synchronisation Cloud (multi-appareils)';

  @override
  String get cloudSyncEnabled => 'Synchronisation activée';

  @override
  String cloudSyncLastSync(String time) {
    return 'Dernière sync : $time';
  }

  @override
  String get cloudSyncSubtitleOff =>
      'Synchronise favoris, vus et récents vers le cloud';

  @override
  String get cloudSyncNow => 'Synchroniser maintenant';

  @override
  String get cloudSyncNowSubtitle =>
      'Pousse les modifications locales vers le cloud';

  @override
  String get never => 'jamais';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get testNotifications => 'Tester les notifications';

  @override
  String get testNotificationsSubtitle =>
      'Envoie une notification locale de test';

  @override
  String get sectionBackup => 'Sauvegarde / Restauration';

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
  String get snackBackupExported =>
      'Configuration exportée dans le presse-papiers';

  @override
  String get snackNoBackup => 'Aucune sauvegarde trouvée';

  @override
  String get snackImportSuccess => 'Configuration importée avec succès';

  @override
  String snackImportError(String message) {
    return 'Erreur: $message';
  }

  @override
  String get sectionAntiThrottle => 'Protection anti-bridage FAI';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy Local)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simule l\'empreinte d\'un navigateur moderne pour contourner Cloudflare';

  @override
  String get dnsProvider => 'Fournisseur DNS (DoH)';

  @override
  String get dnsProviderSubtitle =>
      'Serveur utilisé pour les requêtes DNS over HTTPS';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatique (Système)';

  @override
  String get sectionCloudflare => 'Optimisation Cloudflare';

  @override
  String get cloudflareReset => 'Réinitialiser config Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Efface cookies, remet TLS Impersonation=OFF, UA ExoPlayer par défaut';

  @override
  String get snackCloudflareReset => 'Config Cloudflare réinitialisée';

  @override
  String get sectionEngines => 'Moteurs de lecture';

  @override
  String get enginesTile => 'Moteurs de lecture';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live : $live · VOD : $vod';
  }

  @override
  String get sectionAudioNight => 'Audio & Night Focus';

  @override
  String get audioAndNightFocus => 'Audio & Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Optimisation nocturne, dialogue boost, synchronisation A/V';

  @override
  String get sectionZapping => 'Zapping & Performance';

  @override
  String get instantZapping => 'Zapping Instantané (Prefetching)';

  @override
  String get instantZappingSubtitle =>
      'Précharge les chaînes adjacentes en mémoire tampon';

  @override
  String get sectionMemory => 'Mémoire & Cache';

  @override
  String get sectionParental => 'Contrôle parental';

  @override
  String get parentalControl => 'Contrôle parental';

  @override
  String get parentalControlSubtitle =>
      'Ajouter un code PIN et restreindre le contenu';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get certPinning => 'Activer Certificate Pinning';

  @override
  String get certPinningSubtitle =>
      'Vérifie l\'empreinte SHA-256 du certificat SSL du serveur (anti-MITM)';

  @override
  String get certPinningHint =>
      'Empreintes autorisées (une par ligne, format hex uppercase) :';

  @override
  String get certPinningAdd => 'Ajouter les empreintes ci-dessus';

  @override
  String get sectionResilience => 'Résilience du Service';

  @override
  String get autoReconnectLive => 'Auto-réconnexion Live';

  @override
  String get autoReconnectLiveSubtitle =>
      'Tente de reconnecter automatiquement si le flux coupe';

  @override
  String get sectionLegal => 'Informations légales';

  @override
  String get legalNotice => 'Lisez-moi · Mentions légales';

  @override
  String get legalNoticeSubtitle =>
      'Usage de l\'application, ayants droit et confidentialité';

  @override
  String get nightFocusTitle => 'Night Focus (Mode Nuit)';

  @override
  String get nightFocusEnable => 'Activer Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Traitement audio temps réel : boost dialogues, coupe basses, sync';

  @override
  String get dialogueBoost => 'Boost Dialogues (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifie les voix par rapport aux effets/musique';

  @override
  String get bassKiller => 'Bass Killer (coupe < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Atténue les basses fréquences pour éviter les vibrations';

  @override
  String get sectionAvSync => 'Synchronisation A/V';

  @override
  String get audioShift => 'Décalage audio configurable';

  @override
  String get audioShiftSubtitle => 'Décalage audio/vidéo manuel (ms)';

  @override
  String get manualAvCalibration => 'Calibrage manuel A/V';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Décalage actuel: $ms ms';
  }

  @override
  String get sectionOutput => 'Sortie Audio';

  @override
  String get volumeNormalization => 'Normalisation du volume';

  @override
  String get volumeNormalizationSubtitle =>
      'Limite les pics de volume entre chaînes/programmes (AGC)';

  @override
  String get avSyncDialogTitle => 'Calibrage A/V';

  @override
  String get avSyncDialogLabel => 'Décalage (ms)';

  @override
  String get avSyncDialogHint =>
      'Positif = audio en avance, Négatif = audio en retard';

  @override
  String get apply => 'Appliquer';

  @override
  String get sectionAccessibility => 'Accessibilité';

  @override
  String get highContrast => 'Mode contraste élevé';

  @override
  String get highContrastSubtitle =>
      'Améliore la lisibilité pour les malvoyants';

  @override
  String get dpadNavigation => 'Navigation D-pad renforcée';

  @override
  String get dpadNavigationSubtitle =>
      'Focus visible, halo lumineux, wrap texte (TV mode)';

  @override
  String get fontSize => 'Taille du texte augmentée';

  @override
  String get fontSizeSubtitle => 'Agrandit les textes dans toute l\'app';

  @override
  String get sectionTmdb => 'Classements TMDB';

  @override
  String get sectionRecommendations => 'Recommandations';

  @override
  String get matchmaking => 'Pour vous (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Gérer l\'appariement et les suggestions personnalisées';

  @override
  String get sectionDiagnostics => 'Diagnostic & Maintenance';

  @override
  String get logsDiagnostic => 'Logs & Diagnostic';

  @override
  String get logsDiagnosticSubtitle =>
      'Voir les logs, exporter, vider le cache';

  @override
  String get clearCaches => 'Vider tous les caches';

  @override
  String get clearCachesSubtitle =>
      'Images, index recherche, métadonnées TMDB/TVmaze';

  @override
  String get resetApp => 'Réinitialiser l\'application';

  @override
  String get resetAppSubtitle =>
      'Efface toutes les données utilisateur (profils, favoris, historique)';

  @override
  String get snackCacheCleared => 'Caches vidés (TODO)';

  @override
  String get resetAppDialogTitle => 'Réinitialiser l\'application ?';

  @override
  String get resetAppDialogBody =>
      'Toutes les données seront effacées : profils, favoris, historique, réglages. Cette action est irréversible.';

  @override
  String get resetAppDialogConfirm => 'Tout effacer';

  @override
  String get tmdbKeyLabel => 'Clé API TMDB personnelle (optionnel)';

  @override
  String get tmdbKeyHint => 'La clé partagée embarquée est utilisée par défaut';

  @override
  String get tmdbKeyActive =>
      'Clé personnelle active — la clé partagée est ignorée';

  @override
  String get tmdbKeyShared =>
      'Clé partagée embarquée utilisée (aucune clé personnelle)';

  @override
  String get tmdbKeyDelete => 'Supprimer la clé personnelle';

  @override
  String get tmdbKeyColumn => 'Clés TMDB';

  @override
  String get language => 'Langue';

  @override
  String get languagePreference => 'Langue de l\'application';

  @override
  String get save => 'Sauver';

  @override
  String get cancel => 'Annuler';
}
