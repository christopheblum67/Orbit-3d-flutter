// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get accountDeviceProfile => '┘à┘ä┘ü Ïº┘äÏ¼┘çÏºÏ▓ ┘êÏº┘äÏ¬Ï┤Ï«┘èÏÁ';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Ïº┘ä┘à┘ä┘ü $label ┬À Ï¬Ï┤Ï«┘èÏÁ Ïº┘ä┘àÏ┤Ï║┘æ┘ä';
  }

  @override
  String get accountNoSubscription => '┘äÏº ┘è┘êÏ¼Ï» ÏºÏ┤Ï¬Ï▒Ïº┘â ┘åÏ┤ÏÀ';

  @override
  String get accountPreferences => 'Ï¬┘üÏÂ┘è┘äÏºÏ¬ Ïº┘ä┘à┘ä┘ü Ïº┘äÏ┤Ï«ÏÁ┘è';

  @override
  String get accountPreferencesSubtitle =>
      'Ïº┘ä┘äÏ║Ï®Ïî Ïº┘ä┘àÏ©┘çÏ▒Ïî ┘é┘è┘êÏ» Ïº┘äÏ╣┘àÏ▒Ïî Ï▒┘àÏ▓ PIN';

  @override
  String get accountProfiles => '┘à┘ä┘üÏºÏ¬ Ïº┘ä┘àÏ│Ï¬Ï«Ï»┘à┘è┘å';

  @override
  String get accountProfilesSubtitle =>
      'ÏÑÏ»ÏºÏ▒Ï® Ïº┘ä┘à┘ä┘üÏºÏ¬ ┘êÏº┘ä┘à┘ä┘ü Ïº┘ä┘åÏ┤ÏÀ';

  @override
  String get accountSubscriptions => 'ÏºÏ┤Ï¬Ï▒Ïº┘âÏºÏ¬ Xtream/M3U';

  @override
  String activeCountOngoing(Object count) {
    return '$count ┘é┘èÏ» Ïº┘äÏ¬┘å┘ü┘èÏ░';
  }

  @override
  String get addSubscription => 'ÏÑÏÂÏº┘üÏ® ÏºÏ┤Ï¬Ï▒Ïº┘â';

  @override
  String addedToFavorites(Object title) {
    return 'Ï¬┘àÏ¬ ÏÑÏÂÏº┘üÏ® ┬½$title┬╗ ÏÑ┘ä┘ë Ïº┘ä┘à┘üÏÂ┘äÏ®';
  }

  @override
  String get age => 'Ïº┘äÏ╣┘àÏ▒';

  @override
  String get ageRange13to17 => '13 - 17 Ï│┘åÏ®';

  @override
  String get ageRange18to24 => '18 - 24 Ï│┘åÏ®';

  @override
  String get ageRange25to34 => '25 - 34 Ï│┘åÏ®';

  @override
  String get ageRange35to44 => '35 - 44 Ï│┘åÏ®';

  @override
  String get ageRange45to54 => '45 - 54 Ï│┘åÏ®';

  @override
  String get ageRange55plus => '55 Ï│┘åÏ® ┘üÏú┘âÏ½Ï▒';

  @override
  String get ageRangeUnder12 => 'Ïú┘é┘ä ┘à┘å 12 Ï│┘åÏ®';

  @override
  String get appTitle => 'Ïú┘êÏ▒Ï¿Ï¬ IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'Ïº┘äÏ©┘ç┘êÏ▒ ┘ü┘è Ï╣┘à┘ä┘èÏºÏ¬ Ïº┘äÏ¿Ï¡Ï½ ┘êÏº┘äÏ¬┘êÏÁ┘èÏºÏ¬';

  @override
  String get apply => 'Ï¬ÏÀÏ¿┘è┘é';

  @override
  String get audioAndNightFocus => 'Ïº┘äÏÁ┘êÏ¬ ┘ê┘êÏÂÏ╣ Ïº┘ä┘ä┘è┘ä';

  @override
  String get audioAndNightFocusSubtitle =>
      'Ï¬Ï¡Ï│┘è┘å ┘ä┘è┘ä┘èÏî Ï¬Ï╣Ï▓┘èÏ▓ Ïº┘äÏ¡┘êÏºÏ▒Ïî ┘àÏ▓Ïº┘à┘åÏ® Ïº┘äÏÁ┘êÏ¬/Ïº┘ä┘ü┘èÏ»┘è┘ê';

  @override
  String get audioShift => 'ÏÑÏ▓ÏºÏ¡Ï® ÏÁ┘êÏ¬┘èÏ® ┘éÏºÏ¿┘äÏ® ┘ä┘äÏÂÏ¿ÏÀ';

  @override
  String get audioShiftMinus50 => '-50 ┘à┘ä┘ä┘è Ï½Ïº┘å┘èÏ®';

  @override
  String get audioShiftPlus50 => '+50 ┘à┘ä┘ä┘è Ï½Ïº┘å┘èÏ®';

  @override
  String get audioShiftSubtitle =>
      'ÏÑÏ▓ÏºÏ¡Ï® ÏÁ┘êÏ¬/┘ü┘èÏ»┘è┘ê ┘èÏ»┘ê┘èÏ® (Ï¿Ïº┘ä┘à┘ä┘è Ï½Ïº┘å┘èÏ®)';

  @override
  String get autoQualityDescription =>
      '┘èÏ¬┘èÏ¡ ┘ä┘àÏ┤Ï║┘ä ÏºÏ«Ï¬┘èÏºÏ▒ Ïú┘üÏÂ┘ä Ï¼┘êÏ»Ï®';

  @override
  String get autoReconnectLive =>
      'ÏÑÏ╣ÏºÏ»Ï® ÏºÏ¬ÏÁÏº┘ä ┘àÏ¿ÏºÏ┤Ï▒Ï® Ï¬┘ä┘éÏºÏª┘èÏ®';

  @override
  String get autoReconnectLiveSubtitle =>
      '┘àÏ¡Ïº┘ê┘äÏ® ÏÑÏ╣ÏºÏ»Ï® Ïº┘äÏºÏ¬ÏÁÏº┘ä Ï¬┘ä┘éÏºÏª┘è┘ïÏº ÏÑÏ░Ïº Ïº┘å┘éÏÀÏ╣ Ïº┘äÏ¿Ï½';

  @override
  String get avSyncDialogHint =>
      'ÏÑ┘èÏ¼ÏºÏ¿┘è = Ïº┘äÏÁ┘êÏ¬ ┘àÏ¬┘éÏ»┘àÏî Ï│┘äÏ¿┘è = Ïº┘äÏÁ┘êÏ¬ ┘àÏ¬ÏúÏ«Ï▒';

  @override
  String get avSyncDialogLabel => 'Ïº┘äÏÑÏ▓ÏºÏ¡Ï® (Ï¿Ïº┘ä┘à┘ä┘è Ï½Ïº┘å┘èÏ®)';

  @override
  String get avSyncDialogTitle => '┘àÏ╣Ïº┘èÏ▒Ï® Ïº┘äÏÁ┘êÏ¬/Ïº┘ä┘ü┘èÏ»┘è┘ê';

  @override
  String get backupExport => 'Ï¬ÏÁÏ»┘èÏ▒ Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬';

  @override
  String get backupExportSubtitle =>
      '┘åÏ│Ï« Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ ┘âÏº┘à┘äÏ® ÏÑ┘ä┘ë Ïº┘äÏ¡Ïº┘üÏ©Ï®';

  @override
  String get backupImport => 'ÏºÏ│Ï¬┘èÏ▒ÏºÏ» Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬';

  @override
  String get backupImportSubtitle =>
      'Ïº┘äÏºÏ│Ï¬Ï╣ÏºÏ»Ï® ┘à┘å Ïº┘äÏ¡Ïº┘üÏ©Ï® (JSON)';

  @override
  String get bassKiller =>
      '┘éÏºÏÀÏ╣ Ïº┘äÏ¿ÏºÏÁ (┘éÏÀÏ╣ Ïú┘é┘ä ┘à┘å 120 ┘çÏ▒Ï¬Ï▓)';

  @override
  String get bassKillerSubtitle =>
      '┘è┘é┘ä┘ä Ïº┘äÏ¬Ï▒Ï»Ï»ÏºÏ¬ Ïº┘ä┘à┘åÏ«┘üÏÂÏ® ┘äÏ¬Ï¼┘åÏ¿ Ïº┘äÏº┘çÏ¬Ï▓ÏºÏ▓ÏºÏ¬';

  @override
  String get cancel => 'ÏÑ┘äÏ║ÏºÏí';

  @override
  String get castToChromecast => 'ÏÑÏ▒Ï│Ïº┘ä ÏÑ┘ä┘ë Chromecast';

  @override
  String get catchUpTv => '┘àÏ¬ÏºÏ¿Ï╣Ï® Ïº┘äÏ¿Ï▒Ïº┘àÏ¼';

  @override
  String get categories => 'Ïº┘ä┘üÏªÏºÏ¬';

  @override
  String get certPinning => 'Ï¬┘üÏ╣┘è┘ä Ï¬Ï½Ï¿┘èÏ¬ Ïº┘äÏ┤┘çÏºÏ»Ï®';

  @override
  String get certPinningAdd => 'ÏÑÏÂÏº┘üÏ® Ïº┘äÏ¿ÏÁ┘àÏºÏ¬ ÏúÏ╣┘äÏº┘ç';

  @override
  String get certPinningHint =>
      'Ïº┘äÏ¿ÏÁ┘àÏºÏ¬ Ïº┘ä┘àÏ│┘à┘êÏ¡ Ï¿┘çÏº (┘êÏºÏ¡Ï»Ï® ┘ä┘â┘ä Ï│ÏÀÏ▒Ïî Ï│Ï»ÏºÏ│┘èÏ® Ï╣Ï┤Ï▒┘èÏ® Ï¿ÏúÏ¡Ï▒┘ü ┘âÏ¿┘èÏ▒Ï®):';

  @override
  String get certPinningSubtitle =>
      '┘èÏ¬Ï¡┘é┘é ┘à┘å Ï¿ÏÁ┘àÏ® SHA-256 ┘äÏ┤┘çÏºÏ»Ï® SSL Ïº┘äÏ«ÏºÏÁÏ® Ï¿Ïº┘äÏ«ÏºÏ»┘à (┘àÏÂÏºÏ» ┘ä┘ä┘Ç MITM)';

  @override
  String get changePinCode => 'Ï¬Ï║┘è┘èÏ▒ Ï▒┘àÏ▓ PIN';

  @override
  String get channelsUnavailable => 'Ïº┘ä┘é┘å┘êÏºÏ¬ Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get chooseProfile => 'ÏºÏ«Ï¬Ï▒ ┘à┘ä┘üÏº┘ï Ï┤Ï«ÏÁ┘èÏº┘ï';

  @override
  String get clearCaches => '┘àÏ│Ï¡ ┘â┘ä Ïº┘ä┘âÏºÏ┤';

  @override
  String get clearCachesSubtitle =>
      'Ïº┘äÏÁ┘êÏ▒Ïî ┘ü┘çÏ▒Ï│ Ïº┘äÏ¿Ï¡Ï½Ïî Ï¿┘èÏº┘åÏºÏ¬ TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'Ïº┘ä┘àÏ▓Ïº┘à┘åÏ® ┘à┘üÏ╣┘æ┘äÏ®';

  @override
  String cloudSyncLastSync(String time) {
    return 'ÏóÏ«Ï▒ ┘àÏ▓Ïº┘à┘åÏ®: $time';
  }

  @override
  String get cloudSyncNow => 'Ï▓Ïº┘à┘å Ïº┘äÏó┘å';

  @override
  String get cloudSyncNowSubtitle =>
      'ÏÑÏ▒Ï│Ïº┘ä Ïº┘äÏ¬Ï║┘è┘èÏ▒ÏºÏ¬ Ïº┘ä┘àÏ¡┘ä┘èÏ® ÏÑ┘ä┘ë Ïº┘äÏ│Ï¡ÏºÏ¿Ï®';

  @override
  String get cloudSyncSubtitleOff =>
      '┘àÏ▓Ïº┘à┘åÏ® Ïº┘ä┘à┘üÏÂ┘äÏºÏ¬ ┘êÏº┘ä┘à┘ÅÏ┤Ïº┘ç┘ÄÏ» ┘êÏº┘äÏ¡Ï»┘èÏ½ ┘åÏ¡┘ê Ïº┘äÏ│Ï¡ÏºÏ¿Ï®';

  @override
  String get cloudflareReset => 'ÏÑÏ╣ÏºÏ»Ï® ÏÂÏ¿ÏÀ ÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      '┘àÏ│Ï¡ Ïº┘ä┘â┘ê┘â┘èÏ▓Ïî TLS Impersonation=OFFÏî ┘ê┘â┘è┘ä ExoPlayer Ïº┘äÏº┘üÏ¬Ï▒ÏºÏÂ┘è';

  @override
  String get comingSoon => '┘éÏ▒┘èÏ¿Ïº┘ï';

  @override
  String get confirmAndContinue => 'Ï¬Ïú┘â┘èÏ» ┘êÏº┘ä┘àÏ¬ÏºÏ¿Ï╣Ï®';

  @override
  String get coverCacheCleared =>
      'Ï¬┘à Ï¬┘üÏ▒┘èÏ║ Ï░Ïº┘âÏ▒Ï® Ïº┘äÏ¬Ï«Ï▓┘è┘å Ïº┘ä┘àÏñ┘éÏ¬ ┘ä┘äÏúÏ║┘ä┘üÏ®.';

  @override
  String get createKidProfile => 'ÏÑ┘åÏ┤ÏºÏí ┘à┘ä┘ü Ï┤Ï«ÏÁ┘è ┘ä┘äÏúÏÀ┘üÏº┘ä';

  @override
  String get createNewProfile => 'ÏÑ┘åÏ┤ÏºÏí ┘à┘ä┘ü Ï┤Ï«ÏÁ┘è Ï¼Ï»┘èÏ»';

  @override
  String get createProfile => 'ÏÑ┘åÏ┤ÏºÏí ┘à┘ä┘ü Ï┤Ï«ÏÁ┘è';

  @override
  String currentProfileLabel(String name) {
    return 'Ïº┘ä┘à┘ä┘ü Ïº┘äÏ┤Ï«ÏÁ┘è Ïº┘äÏ¡Ïº┘ä┘è: $name';
  }

  @override
  String get dataAlreadyFresh =>
      'Ïº┘äÏ¿┘èÏº┘åÏºÏ¬ ┘àÏ¡Ï»Ï½Ï® (Ïú┘é┘ä ┘à┘å 30 Ï»┘é┘è┘éÏ®)';

  @override
  String get dataAndPrivacy => 'Ïº┘äÏ¿┘èÏº┘åÏºÏ¬ ┘êÏº┘äÏ«ÏÁ┘êÏÁ┘èÏ®';

  @override
  String get deleteAll => 'Ï¡Ï░┘ü Ïº┘ä┘â┘ä';

  @override
  String get deleteAllConfirm => '┘ç┘ä Ï¬Ï▒┘èÏ» Ï¡Ï░┘ü Ïº┘ä┘â┘äÏƒ';

  @override
  String get deletePin => 'Ï¡Ï░┘ü Ï▒┘àÏ▓ PIN';

  @override
  String get deleteProfileConfirm =>
      '┘ç┘ä Ï¬Ï▒┘èÏ» Ï¡Ï░┘ü Ïº┘ä┘à┘ä┘ü Ïº┘äÏ┤Ï«ÏÁ┘èÏƒ';

  @override
  String get detailUnavailable => 'Ïº┘äÏ¬┘üÏºÏÁ┘è┘ä Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get diagnosticUnavailable => 'Ïº┘äÏ¬Ï┤Ï«┘èÏÁ Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡';

  @override
  String get dialogueBoost => 'Ï¬Ï╣Ï▓┘èÏ▓ Ïº┘äÏ¡┘êÏºÏ▒ (+4 Ï»┘èÏ│┘èÏ¿┘ä)';

  @override
  String get dialogueBoostSubtitle =>
      '┘èÏÂÏ«┘æ┘à Ïº┘äÏúÏÁ┘êÏºÏ¬ ┘à┘éÏºÏ▒┘åÏ® Ï¿Ïº┘ä┘àÏñÏ½Ï▒ÏºÏ¬/Ïº┘ä┘à┘êÏ│┘è┘é┘ë';

  @override
  String get disableSubtitles => 'Ï¬Ï╣ÏÀ┘è┘ä Ïº┘äÏ¬Ï▒Ï¼┘àÏ®';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => '┘àÏ▓┘êÏ» DNS (DoH)';

  @override
  String get dnsProviderSubtitle =>
      'Ïº┘äÏ«ÏºÏ»┘à Ïº┘ä┘àÏ│Ï¬Ï«Ï»┘à ┘äÏºÏ│Ï¬Ï╣┘äÏº┘àÏºÏ¬ DNS Ï╣Ï¿Ï▒ HTTPS';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Ï¬┘ä┘éÏºÏª┘è (Ïº┘ä┘åÏ©Ïº┘à)';

  @override
  String downloadFailed(Object error) {
    return '┘üÏ┤┘ä Ïº┘äÏ¬┘åÏ▓┘è┘ä: $error';
  }

  @override
  String get downloads => 'Ïº┘äÏ¬┘åÏ▓┘è┘äÏºÏ¬';

  @override
  String get dpadNavigation =>
      'Ï¬┘å┘é┘ä ┘àÏ¡Ï│┘æ┘å Ï¿┘ä┘êÏ¡Ï® Ïº┘äÏºÏ¬Ï¼Ïº┘çÏºÏ¬';

  @override
  String get dpadNavigationSubtitle =>
      'Ï¬Ï▒┘â┘èÏ▓ ┘àÏ▒Ïª┘èÏî ┘çÏº┘äÏ® ┘àÏÂ┘èÏªÏ®Ïî Ïº┘äÏ¬┘üÏº┘ü Ïº┘ä┘åÏÁ (┘êÏÂÏ╣ Ïº┘äÏ¬┘ä┘üÏºÏ▓)';

  @override
  String get enableParentalControl =>
      'Ï¬┘üÏ╣┘è┘ä Ïº┘äÏ▒┘éÏºÏ¿Ï® Ïº┘äÏúÏ¿┘ê┘èÏ®';

  @override
  String enginesSubtitle(String live, String vod) {
    return '┘àÏ¿ÏºÏ┤Ï▒: $live ┬À ┘ü┘èÏ»┘è┘ê Ï╣┘åÏ» Ïº┘äÏÀ┘äÏ¿: $vod';
  }

  @override
  String get enginesTile => '┘àÏ¡Ï▒┘âÏºÏ¬ Ïº┘äÏ¬Ï┤Ï║┘è┘ä';

  @override
  String get enterNew4DigitPin =>
      'ÏúÏ»Ï«┘ä Ï▒┘àÏ▓Ïº┘ï Ï¼Ï»┘èÏ»Ïº┘ï ┘à┘å 4 ÏúÏ▒┘éÏº┘à';

  @override
  String get epgGrille => 'EPG (Ïº┘äÏ¼Ï»┘ê┘ä)';

  @override
  String get epgGuideTv => 'Ï»┘ä┘è┘ä TV (EPG)';

  @override
  String get episode => 'Ïº┘äÏ¡┘ä┘éÏ®';

  @override
  String errorGeneric(Object error) {
    return 'Ï«ÏÀÏú: $error';
  }

  @override
  String errorLoading(Object error) {
    return 'Ï«ÏÀÏú ┘ü┘è Ïº┘äÏ¬Ï¡┘à┘è┘ä: $error';
  }

  @override
  String get errorSaving => 'Ï«ÏÀÏú ÏúÏ½┘åÏºÏí Ïº┘äÏ¡┘üÏ©';

  @override
  String get exitWithoutSaving => 'Ïº┘äÏ«Ï▒┘êÏ¼ Ï¿Ï»┘ê┘å Ï¡┘üÏ©Ïƒ';

  @override
  String get failedToLoadProfiles =>
      'Ï¬Ï╣Ï░Ï▒ Ï¬Ï¡┘à┘è┘ä Ïº┘ä┘à┘ä┘üÏºÏ¬ Ïº┘äÏ┤Ï«ÏÁ┘èÏ®';

  @override
  String get fallbackEngine => 'Ïº┘ä┘àÏ¡Ï▒┘â Ïº┘äÏºÏ¡Ï¬┘èÏºÏÀ┘è';

  @override
  String get favoriteGenres => 'Ïº┘äÏú┘å┘êÏºÏ╣ Ïº┘ä┘à┘üÏÂ┘äÏ®';

  @override
  String get filmsVod => 'Ïú┘ü┘äÏº┘à (VOD)';

  @override
  String get firstName => 'Ïº┘äÏºÏ│┘à Ïº┘äÏú┘ê┘ä';

  @override
  String get fontSize => 'Ï¡Ï¼┘à ┘åÏÁ Ïú┘âÏ¿Ï▒';

  @override
  String get fontSizeSubtitle =>
      '┘è┘âÏ¿┘æÏ▒ Ïº┘ä┘åÏÁ┘êÏÁ ┘ü┘è Ïº┘äÏ¬ÏÀÏ¿┘è┘é ┘â┘ä┘ç';

  @override
  String get forYou => '┘ä┘â';

  @override
  String get forYouAndDuo => '┘ä┘â ┘ê┘àÏ¿┘å┘è Ï╣┘ä┘ë Ï½┘åÏºÏª┘è';

  @override
  String get forYouMatchmaking => '┘ä┘â (Ïº┘ä┘àÏÀÏºÏ¿┘éÏ®)';

  @override
  String get forward10s => 'Ï¬┘éÏ»┘è┘à 10 Ï½┘êÏº┘å┘ì';

  @override
  String get forward30s => 'Ï¬┘éÏ»┘è┘à 30 Ï½Ïº┘å┘èÏ®';

  @override
  String get groupMode => '┘àÏ¼Ï¬┘àÏ╣┘è';

  @override
  String get highContrast => '┘êÏÂÏ╣ Ïº┘äÏ¬Ï¿Ïº┘è┘å Ïº┘äÏ╣Ïº┘ä┘è';

  @override
  String get highContrastSubtitle =>
      '┘èÏ¡Ï│┘å Ïº┘ä┘êÏÂ┘êÏ¡ ┘äÏÂÏ╣Ïº┘ü Ïº┘äÏ¿ÏÁÏ▒';

  @override
  String get historyUnavailable => 'Ïº┘äÏ│Ï¼┘ä Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡';

  @override
  String get instantZapping => 'Ï¬┘å┘é┘ä ┘ü┘êÏ▒┘è (Ï¬Ï¡┘à┘è┘ä ┘àÏ│Ï¿┘é)';

  @override
  String get instantZappingSubtitle =>
      'Ï¬Ï¡┘à┘è┘ä Ïº┘ä┘é┘å┘êÏºÏ¬ Ïº┘ä┘àÏ¼Ïº┘êÏ▒Ï® ┘àÏ│Ï¿┘é┘ïÏº ┘ü┘è Ïº┘äÏ░Ïº┘âÏ▒Ï®';

  @override
  String get langArabic => 'Ïº┘äÏ╣Ï▒Ï¿┘èÏ®';

  @override
  String get langFrench => 'Fran├ºais';

  @override
  String get langPortuguese => 'Portugu├¬s';

  @override
  String get langSpanish => 'Espa├▒ol';

  @override
  String get language => 'Ïº┘ä┘äÏ║Ï®';

  @override
  String get languageExample => 'العربية, English, etc.';

  @override
  String get noneOption => 'لا شيء';

  @override
  String get play => 'تشغيل';

  @override
  String get newAnd4K => 'أفلام عند الطلب';

  @override
  String get seasonsAndEpisodes => 'مسلسلات عند الطلب';

  @override
  String get languagePreference => '┘äÏ║Ï® Ïº┘äÏ¬ÏÀÏ¿┘è┘é';

  @override
  String get languageUndetermined => 'Ï║┘èÏ▒ ┘àÏ¡Ï»Ï»';

  @override
  String get later => '┘äÏºÏ¡┘éÏº┘ï';

  @override
  String get legalNotice => 'Ïº┘éÏ▒Ïú┘å┘è ┬À ÏÑÏ┤Ï╣ÏºÏ▒ ┘éÏº┘å┘ê┘å┘è';

  @override
  String get legalNoticeSubtitle =>
      'ÏºÏ│Ï¬Ï«Ï»Ïº┘à Ïº┘äÏ¬ÏÀÏ¿┘è┘éÏî ÏúÏÁÏ¡ÏºÏ¿ Ïº┘äÏ¡┘é┘ê┘é ┘êÏº┘äÏ«ÏÁ┘êÏÁ┘èÏ®';

  @override
  String get liveChannelsAndZapping =>
      'Ïº┘ä┘é┘å┘êÏºÏ¬ Ïº┘ä┘àÏ¿ÏºÏ┤Ï▒Ï® ┘êÏº┘äÏ¬Ï¿Ï»┘è┘ä';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'Ïº┘äÏ│Ï¼┘äÏºÏ¬ ┘êÏº┘äÏ¬Ï┤Ï«┘èÏÁ';

  @override
  String get logsDiagnosticSubtitle =>
      'Ï╣Ï▒ÏÂ Ïº┘äÏ│Ï¼┘äÏºÏ¬Ïî Ïº┘äÏ¬ÏÁÏ»┘èÏ▒Ïî ┘àÏ│Ï¡ Ïº┘ä┘âÏºÏ┤';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'Ï▒ÏºÏ¿ÏÀ ┘éÏºÏª┘àÏ® Ïº┘äÏ¬Ï┤Ï║┘è┘ä M3U';

  @override
  String get mainCast => 'ÏÀÏº┘é┘à Ïº┘äÏ¬┘àÏ½┘è┘ä Ïº┘äÏ▒Ïª┘èÏ│┘è';

  @override
  String get manualAvCalibration =>
      '┘àÏ╣Ïº┘èÏ▒Ï® ┘èÏ»┘ê┘èÏ® ┘ä┘äÏÁ┘êÏ¬/Ïº┘ä┘ü┘èÏ»┘è┘ê';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Ïº┘äÏÑÏ▓ÏºÏ¡Ï® Ïº┘äÏ¡Ïº┘ä┘èÏ®: $ms ┘à┘ä┘è Ï½Ïº┘å┘èÏ®';
  }

  @override
  String get matchmaking => '┘à┘å ÏúÏ¼┘ä┘â (Ïº┘ä┘àÏÀÏºÏ¿┘éÏ®)';

  @override
  String get matchmakingSubtitle =>
      'ÏÑÏ»ÏºÏ▒Ï® Ïº┘ä┘àÏÀÏºÏ¿┘éÏ® ┘êÏº┘äÏº┘éÏ¬Ï▒ÏºÏ¡ÏºÏ¬ Ïº┘ä┘àÏ«ÏÁÏÁÏ®';

  @override
  String maxProfilesReached(Object max) {
    return 'Ï¬┘à Ïº┘ä┘êÏÁ┘ê┘ä ÏÑ┘ä┘ë Ïº┘äÏ¡Ï» Ïº┘äÏú┘éÏÁ┘ë ┘äÏ╣Ï»Ï» Ïº┘ä┘à┘ä┘üÏºÏ¬ Ïº┘äÏ┤Ï«ÏÁ┘èÏ® ($max)';
  }

  @override
  String get memory => 'Ïº┘äÏ░Ïº┘âÏ▒Ï®';

  @override
  String get moreResults => 'Ï╣Ï▒ÏÂ Ïº┘ä┘àÏ▓┘èÏ» ┘à┘å Ïº┘ä┘åÏ¬ÏºÏªÏ¼';

  @override
  String get moviesUnavailable => 'Ïº┘äÏú┘ü┘äÏº┘à Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get multiScreen => 'Ï┤ÏºÏ┤ÏºÏ¬ ┘àÏ¬Ï╣Ï»Ï»Ï®';

  @override
  String get multiVideo => '┘ü┘èÏ»┘è┘ê ┘àÏ¬Ï╣Ï»Ï»';

  @override
  String get myProfile => '┘à┘ä┘ü┘è Ïº┘äÏ┤Ï«ÏÁ┘è';

  @override
  String get nameOptional => 'Ïº┘äÏºÏ│┘à (ÏºÏ«Ï¬┘èÏºÏ▒┘è)';

  @override
  String get nameOrNickname => 'Ïº┘äÏºÏ│┘à / Ïº┘ä┘â┘å┘èÏ®';

  @override
  String get navigateToOkToSelect => 'Ïº┘åÏ¬┘é┘ä ÏÑ┘ä┘ë OK ┘ä┘äÏ¬Ï¡Ï»┘èÏ»';

  @override
  String get networkDisconnected => 'Ïº┘å┘éÏÀÏ╣ Ïº┘äÏºÏ¬ÏÁÏº┘ä Ï¿Ïº┘äÏ┤Ï¿┘âÏ®';

  @override
  String get never => 'ÏúÏ¿Ï»┘ïÏº';

  @override
  String get newProfile => '┘à┘ä┘ü Ï┤Ï«ÏÁ┘è Ï¼Ï»┘èÏ»';

  @override
  String get nextChannel => 'Ïº┘ä┘é┘åÏºÏ® Ïº┘äÏ¬Ïº┘ä┘èÏ®';

  @override
  String get nightFocusEnable => 'Ï¬┘üÏ╣┘è┘ä ┘êÏÂÏ╣ Ïº┘ä┘ä┘è┘ä';

  @override
  String get nightFocusEnableSubtitle =>
      '┘àÏ╣Ïº┘äÏ¼Ï® ÏÁ┘êÏ¬┘èÏ® ┘ü┘êÏ▒┘èÏ®: Ï¬Ï╣Ï▓┘èÏ▓ Ïº┘äÏ¡┘êÏºÏ▒Ïî Ï«┘üÏÂ Ïº┘äÏ¿ÏºÏÁÏî Ïº┘ä┘àÏ▓Ïº┘à┘åÏ®';

  @override
  String get nightFocusTitle => '┘êÏÂÏ╣ Ïº┘ä┘ä┘è┘ä (┘êÏÂÏ╣ Ïº┘ä┘ä┘è┘ä)';

  @override
  String get noAudioTrackDetected =>
      '┘ä┘à ┘èÏ¬┘à Ïº┘âÏ¬Ï┤Ïº┘ü ┘àÏ│ÏºÏ▒ ÏÁ┘êÏ¬┘è';

  @override
  String get noChannelsAvailable => '┘äÏº Ï¬┘êÏ¼Ï» ┘é┘å┘êÏºÏ¬ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get noChromecastDeviceFound =>
      '┘ä┘à ┘èÏ¬┘à Ïº┘äÏ╣Ï½┘êÏ▒ Ï╣┘ä┘ë Ï¼┘çÏºÏ▓ Chromecast.';

  @override
  String get noDownloads => '┘äÏº Ï¬┘êÏ¼Ï» Ï¬┘åÏ▓┘è┘äÏºÏ¬';

  @override
  String get noEpisodes => '┘äÏº Ï¬┘êÏ¼Ï» Ï¡┘ä┘éÏºÏ¬';

  @override
  String get noFavoriteChannels => '┘äÏº Ï¬┘êÏ¼Ï» ┘é┘å┘êÏºÏ¬ ┘à┘üÏÂ┘äÏ®';

  @override
  String get noFavoriteMovies => '┘äÏº Ï¬┘êÏ¼Ï» Ïú┘ü┘äÏº┘à ┘à┘üÏÂ┘äÏ®';

  @override
  String get noFavoriteReplays =>
      '┘äÏº Ï¬┘êÏ¼Ï» ÏÑÏ╣ÏºÏ»Ï® ┘àÏ┤Ïº┘çÏ»Ï® ┘à┘üÏÂ┘äÏ®';

  @override
  String get noFavoriteSeries => '┘äÏº Ï¬┘êÏ¼Ï» Ï│┘äÏ│┘ä ┘à┘üÏÂ┘äÏ®';

  @override
  String get noGroupAffinity =>
      '┘ä┘à ┘èÏ¬┘à Ïº┘äÏ╣Ï½┘êÏ▒ Ï╣┘ä┘ë Ï¬┘éÏºÏ▒Ï¿ ┘àÏ┤Ï¬Ï▒┘â';

  @override
  String get noHistory => '┘äÏº ┘è┘êÏ¼Ï» Ï│Ï¼┘ä';

  @override
  String get noKidsChannels => '┘äÏº Ï¬┘êÏ¼Ï» ┘é┘å┘êÏºÏ¬ ÏúÏÀ┘üÏº┘ä';

  @override
  String get noKidsMovies => '┘äÏº Ï¬┘êÏ¼Ï» Ïú┘ü┘äam ÏúÏÀ┘üÏº┘ä';

  @override
  String get noKidsReplays =>
      '┘äÏº Ï¬┘êÏ¼Ï» ÏÑÏ╣ÏºÏ»Ï® ┘àÏ┤Ïº┘çÏ»Ï® ÏúÏÀ┘üÏº┘ä';

  @override
  String get noKidsSeries => '┘äÏº Ï¬┘êÏ¼Ï» Ï│┘äÏ│┘ä ÏúÏÀ┘üÏº┘ä';

  @override
  String get noMoviesAvailable => '┘äÏº Ï¬┘êÏ¼Ï» Ïú┘ü┘äÏº┘à ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get noProfileAvailable => '┘äÏº ┘è┘êÏ¼Ï» ┘à┘ä┘ü Ï┤Ï«ÏÁ┘è ┘àÏ¬ÏºÏ¡';

  @override
  String get noProfilesYet => '┘äÏº Ï¬┘êÏ¼Ï» ┘à┘ä┘üÏºÏ¬ Ï┤Ï«ÏÁ┘èÏ® Ï¿Ï╣Ï»';

  @override
  String get noProgramInfoAvailable =>
      '┘äÏº Ï¬Ï¬┘ê┘üÏ▒ ┘àÏ╣┘ä┘ê┘àÏºÏ¬ Ï╣┘å Ïº┘äÏ¿Ï▒┘åÏº┘àÏ¼';

  @override
  String get noRankings => '┘äÏº Ï¬┘êÏ¼Ï» Ï¬Ï▒Ï¬┘èÏ¿ÏºÏ¬';

  @override
  String get noRecommendations => '┘äÏº Ï¬┘êÏ¼Ï» Ï¬┘êÏÁ┘èÏºÏ¬ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get noReplaysInCategory =>
      '┘äÏº Ï¬┘êÏ¼Ï» ÏÑÏ╣ÏºÏ»Ï® ┘àÏ┤Ïº┘çÏ»Ï® ┘ü┘è ┘çÏ░┘ç Ïº┘ä┘üÏªÏ®';

  @override
  String noResultsFor(Object query) {
    return '┘äÏº Ï¬┘êÏ¼Ï» ┘åÏ¬ÏºÏªÏ¼ ┘ä┘Ç $query';
  }

  @override
  String get noSeriesAvailable => '┘äÏº Ï¬┘êÏ¼Ï» Ï│┘äÏ│┘ä ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get noStationsAvailable => '┘äÏº Ï¬┘êÏ¼Ï» ┘àÏ¡ÏÀÏºÏ¬ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get noVideoQualityDetected =>
      '┘ä┘à ┘èÏ¬┘à Ïº┘âÏ¬Ï┤Ïº┘ü Ï¼┘êÏ»Ï® ┘ü┘èÏ»┘è┘ê';

  @override
  String get notAvailableInCatalog => 'Ï║┘èÏ▒ ┘àÏ¬┘ê┘üÏ▒ ┘ü┘è Ïº┘ä┘âÏ¬Ïº┘ä┘êÏ¼';

  @override
  String get offline => 'Ï║┘èÏ▒ ┘àÏ¬ÏÁ┘ä';

  @override
  String get parentalControl => 'Ïº┘äÏ▒┘éÏºÏ¿Ï® Ïº┘äÏúÏ¿┘ê┘èÏ®';

  @override
  String get parentalControlSubtitle =>
      'ÏÑÏÂÏº┘üÏ® Ï▒┘àÏ▓ PIN ┘êÏ¬┘é┘è┘èÏ» Ïº┘ä┘àÏ¡Ï¬┘ê┘ë';

  @override
  String get pauseDownload => 'ÏÑ┘è┘éÏº┘ü ┘àÏñ┘éÏ¬';

  @override
  String get pinCode => 'Ï▒┘àÏ▓ PIN';

  @override
  String get pinDeleted => 'Ï¬┘à Ï¡Ï░┘ü Ï▒┘àÏ▓ PIN';

  @override
  String get pinMustBe4Digits =>
      '┘èÏ¼Ï¿ Ïú┘å ┘èÏ¡Ï¬┘ê┘è Ï▒┘àÏ▓ PIN Ï╣┘ä┘ë 4 ÏúÏ▒┘éÏº┘à Ï¿Ïº┘äÏÂÏ¿ÏÀ';

  @override
  String get pinSaved => 'Ï¬┘à Ï¡┘üÏ© Ï▒┘àÏ▓ PIN';

  @override
  String get pip => 'Ïº┘äÏ╣Ï▒ÏÂ Ïº┘äÏ╣ÏºÏª┘à (PiP)';

  @override
  String get pipUnavailable =>
      'Ïº┘äÏ╣Ï▒ÏÂ Ïº┘äÏ╣ÏºÏª┘à (PiP) Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡ Ï╣┘ä┘ë ┘çÏ░Ïº Ïº┘äÏ¼┘çÏºÏ▓';

  @override
  String get playHistoryCleared => 'Ï¬┘à ┘àÏ│Ï¡ Ï│Ï¼┘ä Ïº┘ä┘àÏ┤Ïº┘çÏ»Ï®.';

  @override
  String plusAgeYears(Object age) {
    return '+$age Ï│┘å┘êÏºÏ¬';
  }

  @override
  String get preferences => 'Ïº┘äÏ¬┘üÏÂ┘è┘äÏºÏ¬';

  @override
  String get previousChannel => 'Ïº┘ä┘é┘åÏºÏ® Ïº┘äÏ│ÏºÏ¿┘éÏ®';

  @override
  String get primaryEngine => 'Ïº┘ä┘àÏ¡Ï▒┘â Ïº┘äÏ▒Ïª┘èÏ│┘è';

  @override
  String profilesSelected(int count) {
    return 'Ï¬┘à Ï¬Ï¡Ï»┘èÏ» $count ┘à┘ä┘üÏºÏ¬ Ï¬Ï╣Ï▒┘è┘ü';
  }

  @override
  String get profileVisible => '┘à┘ä┘ü Ï┤Ï«ÏÁ┘è ┘àÏ▒Ïª┘è';

  @override
  String get programGrid => 'Ï¼Ï»┘ê┘ä Ïº┘äÏ¿Ï▒Ïº┘àÏ¼';

  @override
  String get protectWithPin => 'Ïº┘äÏ¡┘àÏº┘èÏ® Ï¿Ï▒┘àÏ▓ PIN';

  @override
  String get rankingsUnavailable => 'Ïº┘äÏ¬Ï▒Ï¬┘èÏ¿ Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡';

  @override
  String get recentSearch => 'Ï¿Ï¡Ï½ Ï¡Ï»┘èÏ½';

  @override
  String get recentSearches => 'Ïº┘äÏúÏ«┘èÏ▒Ï®';

  @override
  String get recentlyWatched => 'Ï┤┘ê┘çÏ» ┘àÏñÏ«Ï▒Ïº┘ï';

  @override
  String get removeAll => 'ÏÑÏ▓Ïº┘äÏ® Ïº┘ä┘â┘ä';

  @override
  String get removeFromWatchedConfirm =>
      'ÏÑÏ▓Ïº┘äÏ® Ïº┘ä┘â┘ä ┘à┘å Ïº┘ä┘àÏ┤Ïº┘çÏ»Ï®Ïƒ';

  @override
  String get replaysUnavailable =>
      'ÏÑÏ╣ÏºÏ»Ï® Ïº┘ä┘àÏ┤Ïº┘çÏ»Ï® Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get reset => 'ÏÑÏ╣ÏºÏ»Ï® Ï¬Ï╣┘è┘è┘å';

  @override
  String get resetApp => 'ÏÑÏ╣ÏºÏ»Ï® ÏÂÏ¿ÏÀ Ïº┘äÏ¬ÏÀÏ¿┘è┘é';

  @override
  String get resetAppDialogBody =>
      'Ï│┘èÏ¬┘à ┘àÏ│Ï¡ Ï¼┘à┘èÏ╣ Ïº┘äÏ¿┘èÏº┘åÏºÏ¬: Ïº┘ä┘à┘ä┘üÏºÏ¬Ïî Ïº┘ä┘à┘üÏÂ┘äÏºÏ¬Ïî Ïº┘äÏ│Ï¼┘äÏî Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬. ┘çÏ░Ïº Ïº┘äÏÑÏ¼Ï▒ÏºÏí ┘äÏº ┘è┘à┘â┘å Ïº┘äÏ¬Ï▒ÏºÏ¼Ï╣ Ï╣┘å┘ç.';

  @override
  String get resetAppDialogConfirm => '┘àÏ│Ï¡ ┘â┘ä Ï┤┘èÏí';

  @override
  String get resetAppDialogTitle => 'ÏÑÏ╣ÏºÏ»Ï® ÏÂÏ¿ÏÀ Ïº┘äÏ¬ÏÀÏ¿┘è┘éÏƒ';

  @override
  String get resetAppSubtitle =>
      '┘è┘àÏ│Ï¡ Ï¼┘à┘èÏ╣ Ï¿┘èÏº┘åÏºÏ¬ Ïº┘ä┘àÏ│Ï¬Ï«Ï»┘à (Ïº┘ä┘à┘ä┘üÏºÏ¬Ïî Ïº┘ä┘à┘üÏÂ┘äÏºÏ¬Ïî Ïº┘äÏ│Ï¼┘ä)';

  @override
  String get resetCompleted => 'Ï¬┘àÏ¬ ÏÑÏ╣ÏºÏ»Ï® Ïº┘äÏ¬Ï╣┘è┘è┘å';

  @override
  String get resumePlayback => '┘ç┘ä Ï¬Ï▒┘èÏ» ÏºÏ│Ï¬Ïª┘åÏº┘ü Ïº┘äÏ¬Ï┤Ï║┘è┘äÏƒ';

  @override
  String get retry => 'ÏÑÏ╣ÏºÏ»Ï® Ïº┘ä┘àÏ¡Ïº┘ê┘äÏ®';

  @override
  String get retrySearch => 'ÏÑÏ╣ÏºÏ»Ï® ┘àÏ¡Ïº┘ê┘äÏ® Ïº┘äÏ¿Ï¡Ï½';

  @override
  String get rewind10s => 'Ï¬Ï▒Ï¼┘èÏ╣ 10 Ï½┘êÏº┘å┘ì';

  @override
  String get rewind30s => 'Ï¬Ï▒Ï¼┘èÏ╣ 30 Ï½Ïº┘å┘èÏ®';

  @override
  String get rightsHolders => 'ÏúÏÁÏ¡ÏºÏ¿ Ïº┘äÏ¡┘é┘ê┘é';

  @override
  String get save => 'Ï¡┘üÏ©';

  @override
  String get sdkAndroid => 'SDK Android';

  @override
  String get searchChannel => 'Ïº┘äÏ¿Ï¡Ï½ Ï╣┘å ┘é┘åÏºÏ®';

  @override
  String get searchError => 'Ï«ÏÀÏú ┘ü┘è Ïº┘äÏ¿Ï¡Ï½';

  @override
  String get searchMovie => 'Ïº┘äÏ¿Ï¡Ï½ Ï╣┘å ┘ü┘è┘ä┘à';

  @override
  String get searchSeries => 'Ïº┘äÏ¿Ï¡Ï½ Ï╣┘å Ï│┘äÏ│┘ä';

  @override
  String seasonNumber(Object season) {
    return 'Ïº┘ä┘à┘êÏ│┘à $season';
  }

  @override
  String get sectionAccessibility => 'ÏÑ┘à┘âÏº┘å┘èÏ® Ïº┘ä┘êÏÁ┘ê┘ä';

  @override
  String get sectionAccountProfile => 'Ïº┘äÏ¡Ï│ÏºÏ¿ ┘êÏº┘ä┘à┘ä┘ü Ïº┘äÏ┤Ï«ÏÁ┘è';

  @override
  String get sectionAntiThrottle =>
      'Ï¡┘àÏº┘èÏ® ┘à┘å Ï¬Ï«┘ü┘è┘ü Ï│Ï▒Ï╣Ï® ┘àÏ▓┘êÏ» Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬';

  @override
  String get sectionAudioNight => 'Ïº┘äÏÁ┘êÏ¬ ┘ê┘êÏÂÏ╣ Ïº┘ä┘ä┘è┘ä';

  @override
  String get sectionAvSync => '┘àÏ▓Ïº┘à┘åÏ® Ïº┘äÏÁ┘êÏ¬/Ïº┘ä┘ü┘èÏ»┘è┘ê';

  @override
  String get sectionBackup =>
      'Ïº┘ä┘åÏ│Ï« Ïº┘äÏºÏ¡Ï¬┘èÏºÏÀ┘è / Ïº┘äÏºÏ│Ï¬Ï╣ÏºÏ»Ï®';

  @override
  String get sectionCertPinning => 'Ï¬Ï½Ï¿┘èÏ¬ Ïº┘äÏ┤┘çÏºÏ»Ï® (SHA-256)';

  @override
  String get sectionCloudSync =>
      'Ïº┘ä┘àÏ▓Ïº┘à┘åÏ® Ïº┘äÏ│Ï¡ÏºÏ¿┘èÏ® (Ï╣Ï»Ï® ÏúÏ¼┘çÏ▓Ï®)';

  @override
  String get sectionCloudflare => 'Ï¬Ï¡Ï│┘è┘å Cloudflare';

  @override
  String get sectionDiagnostics => 'Ïº┘äÏ¬Ï┤Ï«┘èÏÁ ┘êÏº┘äÏÁ┘èÏº┘åÏ®';

  @override
  String get sectionEngines => '┘àÏ¡Ï▒┘âÏºÏ¬ Ïº┘äÏ¬Ï┤Ï║┘è┘ä';

  @override
  String get sectionLegal => '┘àÏ╣┘ä┘ê┘àÏºÏ¬ ┘éÏº┘å┘ê┘å┘èÏ®';

  @override
  String get sectionMemory => 'Ïº┘äÏ░Ïº┘âÏ▒Ï® ┘êÏº┘ä┘âÏºÏ┤';

  @override
  String get sectionOutput => '┘àÏ«Ï▒Ï¼ Ïº┘äÏÁ┘êÏ¬';

  @override
  String get sectionParental => 'Ïº┘äÏ▒┘éÏºÏ¿Ï® Ïº┘äÏúÏ¿┘ê┘èÏ®';

  @override
  String get sectionRecommendations => 'Ïº┘äÏ¬┘êÏÁ┘èÏºÏ¬';

  @override
  String get sectionResilience => '┘àÏ▒┘ê┘åÏ® Ïº┘äÏ«Ï»┘àÏ®';

  @override
  String get sectionTmdb => 'Ï¬ÏÁ┘å┘è┘üÏºÏ¬ TMDB';

  @override
  String get sectionZapping => 'Ïº┘äÏ¬┘å┘é┘ä ┘êÏº┘äÏúÏ»ÏºÏí';

  @override
  String get select => 'ÏºÏ«Ï¬┘èÏºÏ▒';

  @override
  String selectAtLeastOneProfile(int count) {
    return 'ÏºÏ«Ï¬Ï▒ ┘à┘ä┘ü┘ïÏº ┘êÏºÏ¡Ï»┘ïÏº Ï╣┘ä┘ë Ïº┘äÏú┘é┘ä ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'ÏºÏ«Ï¬Ï▒ ┘à┘ä┘üÏº┘ï Ï┤Ï«ÏÁ┘èÏº┘ï ┘äÏ╣Ï▒ÏÂ Ï¬┘êÏÁ┘èÏºÏ¬┘ç';

  @override
  String get series => 'Ïº┘äÏ│┘äÏ│┘ä';

  @override
  String get seriesNotFound => 'Ïº┘äÏ│┘äÏ│┘ä Ï║┘èÏ▒ ┘à┘êÏ¼┘êÏ»Ï®';

  @override
  String get seriesUnavailable => 'Ïº┘äÏ│┘äÏ│┘ä Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get seriesUnavailableTemporarily =>
      'Ïº┘äÏ│┘äÏ│┘ä Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï® Ï¡Ïº┘ä┘èÏº┘ï.';

  @override
  String get serverProtectedAntiLeech =>
      'Ïº┘äÏ«ÏºÏ»┘à ┘àÏ¡┘à┘è (┘àÏÂÏºÏ» ┘ä┘äÏ¬┘åÏ▓┘è┘ä)';

  @override
  String get serverUrlPlaceholder =>
      'Ï▒ÏºÏ¿ÏÀ Ïº┘äÏ«ÏºÏ»┘à (┘àÏ½Ïº┘ä: https://provider.com)';

  @override
  String get serviceNature => 'ÏÀÏ¿┘èÏ╣Ï® Ïº┘äÏ«Ï»┘àÏ®';

  @override
  String get setAsDefaultServer => 'Ï¬Ï╣┘è┘è┘å ┘âÏ«ÏºÏ»┘à Ïº┘üÏ¬Ï▒ÏºÏÂ┘è';

  @override
  String get settings => 'Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬';

  @override
  String get settingsTitle => 'Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬';

  @override
  String get similarMovies => 'Ïú┘ü┘äÏº┘à ┘àÏ┤ÏºÏ¿┘çÏ®';

  @override
  String get snackBackupExported =>
      'Ï¬┘à Ï¬ÏÁÏ»┘èÏ▒ Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ ÏÑ┘ä┘ë Ïº┘äÏ¡Ïº┘üÏ©Ï®';

  @override
  String get snackCacheCleared => 'Ï¬┘à ┘àÏ│Ï¡ Ïº┘ä┘âÏºÏ┤';

  @override
  String get snackCloudflareReset =>
      'Ï¬┘àÏ¬ ÏÑÏ╣ÏºÏ»Ï® ÏÂÏ¿ÏÀ ÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ Cloudflare';

  @override
  String snackImportError(String message) {
    return 'Ï«ÏÀÏú: $message';
  }

  @override
  String get snackImportSuccess =>
      'Ï¬┘à ÏºÏ│Ï¬┘èÏ▒ÏºÏ» Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ Ï¿┘åÏ¼ÏºÏ¡';

  @override
  String get snackNoBackup =>
      '┘ä┘à ┘èÏ¬┘à Ïº┘äÏ╣Ï½┘êÏ▒ Ï╣┘ä┘ë ┘åÏ│Ï«Ï® ÏºÏ¡Ï¬┘èÏºÏÀ┘èÏ®';

  @override
  String get sortAffinity => 'Ï¡Ï│Ï¿ Ïº┘äÏ¬┘éÏºÏ▒Ï¿';

  @override
  String get sortAffinityDescription =>
      '┘èÏ▒Ï¬Ï¿ ┘ê┘ü┘é ÏúÏ░┘êÏº┘é┘â Ïº┘ä┘àÏ╣┘ä┘åÏ® ┘ü┘è Ïº┘ä┘à┘ä┘ü Ïº┘äÏ┤Ï«ÏÁ┘è (┘àÏÀÏºÏ¿┘éÏ®)';

  @override
  String get sortAscending => 'Ï¬Ï▒Ï¬┘èÏ¿ Ï¬ÏÁÏºÏ╣Ï»┘è';

  @override
  String get sortByDuration => 'Ï¡Ï│Ï¿ Ïº┘ä┘àÏ»Ï®';

  @override
  String get sortByRating => 'Ï¡Ï│Ï¿ Ïº┘äÏ¬┘é┘è┘è┘à';

  @override
  String get sortByYear => 'Ï¡Ï│Ï¿ Ïº┘äÏ│┘åÏ®';

  @override
  String get sortDescending => 'Ï¬Ï▒Ï¬┘èÏ¿ Ï¬┘åÏºÏ▓┘ä┘è';

  @override
  String get sortLatestM3UXtream => 'ÏóÏ«Ï▒ Ïº┘äÏÑÏÂÏº┘üÏºÏ¬ M3U/Xtream';

  @override
  String get sortNameAToZ => 'Ïº┘äÏºÏ│┘à (Ïú ÔåÆ ┘è)';

  @override
  String get sortNameZToA => 'Ïº┘äÏºÏ│┘à (┘è ÔåÆ Ïú)';

  @override
  String get sortResumePriority => 'Ïº┘ä┘àÏ¬ÏºÏ¿Ï╣Ï® Ïú┘ê┘äÏº┘ï';

  @override
  String specialGuestsSeason(Object season) {
    return 'ÏÂ┘è┘ê┘ü Ï«ÏºÏÁ┘è┘å - Ïº┘ä┘à┘êÏ│┘à $season';
  }

  @override
  String get srtVttUrl => 'Ï▒ÏºÏ¿ÏÀ .srt / .vtt';

  @override
  String get start => 'Ï¬Ï┤Ï║┘è┘ä';

  @override
  String get stationsUnavailable => 'Ïº┘ä┘àÏ¡ÏÀÏºÏ¬ Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get stopCasting => 'ÏÑ┘è┘éÏº┘ü Ïº┘äÏÑÏ▒Ï│Ïº┘ä';

  @override
  String get streamDetails => 'Ï¬┘üÏºÏÁ┘è┘ä Ïº┘äÏ¿Ï½';

  @override
  String subtitleLoadError(Object error) {
    return 'Ï«ÏÀÏú ┘ü┘è Ï¬Ï¡┘à┘è┘ä Ïº┘äÏ¬Ï▒Ï¼┘àÏ®: $error';
  }

  @override
  String get subtitlesUnavailable => 'Ïº┘äÏ¬Ï▒Ï¼┘àÏ®: Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get system => 'Ïº┘ä┘åÏ©Ïº┘à';

  @override
  String get tabAccount => 'Ïº┘äÏ¡Ï│ÏºÏ¿';

  @override
  String get tabAdvanced => '┘àÏ¬┘éÏ»┘à';

  @override
  String get tabAudio => 'Ïº┘äÏÁ┘êÏ¬';

  @override
  String get tabNetwork => 'Ïº┘äÏ┤Ï¿┘âÏ®';

  @override
  String get tabPlayer => 'Ïº┘ä┘àÏ┤Ï║┘æ┘ä';

  @override
  String get tabSecurity => 'Ïº┘äÏú┘àÏº┘å';

  @override
  String get theme => 'Ïº┘ä┘àÏ©┘çÏ▒';

  @override
  String get tlsImpersonation =>
      'Ïº┘åÏ¬Ï¡Ïº┘ä TLS (Ï«ÏºÏ»┘à ┘êÏ│┘èÏÀ ┘àÏ¡┘ä┘è)';

  @override
  String get tlsImpersonationSubtitle =>
      '┘èÏ¡Ïº┘â┘è Ï¿ÏÁ┘àÏ® ┘àÏ¬ÏÁ┘üÏ¡ Ï¡Ï»┘èÏ½ ┘äÏ¬Ï¼Ïº┘êÏ▓ Cloudflare';

  @override
  String get tmdbKeyActive =>
      'Ïº┘ä┘à┘üÏ¬ÏºÏ¡ Ïº┘äÏ┤Ï«ÏÁ┘è ┘åÏ┤ÏÀ ÔÇö ┘èÏ¬┘à Ï¬Ï¼Ïº┘ç┘ä Ïº┘ä┘à┘üÏ¬ÏºÏ¡ Ïº┘ä┘àÏ┤Ï¬Ï▒┘â';

  @override
  String get tmdbKeyColumn => '┘à┘üÏºÏ¬┘èÏ¡ TMDB';

  @override
  String get tmdbKeyDelete => 'Ï¡Ï░┘ü Ïº┘ä┘à┘üÏ¬ÏºÏ¡ Ïº┘äÏ┤Ï«ÏÁ┘è';

  @override
  String get tmdbKeyHint =>
      '┘è┘ÅÏ│Ï¬Ï«Ï»┘à Ïº┘ä┘à┘üÏ¬ÏºÏ¡ Ïº┘ä┘àÏ┤Ï¬Ï▒┘â Ïº┘ä┘àÏÂ┘à┘æ┘å Ïº┘üÏ¬Ï▒ÏºÏÂ┘è┘ïÏº';

  @override
  String get tmdbKeyLabel =>
      '┘à┘üÏ¬ÏºÏ¡ TMDB API Ïº┘äÏ┤Ï«ÏÁ┘è (ÏºÏ«Ï¬┘èÏºÏ▒┘è)';

  @override
  String get tmdbKeyShared =>
      'Ïº┘ä┘à┘üÏ¬ÏºÏ¡ Ïº┘ä┘àÏ┤Ï¬Ï▒┘â Ïº┘ä┘àÏÂ┘à┘æ┘å ┘é┘èÏ» Ïº┘äÏºÏ│Ï¬Ï«Ï»Ïº┘à (┘äÏº ┘è┘êÏ¼Ï» ┘à┘üÏ¬ÏºÏ¡ Ï┤Ï«ÏÁ┘è)';

  @override
  String get tvChannels => '┘é┘å┘êÏºÏ¬ TV';

  @override
  String get unableToBuildReplayUrl =>
      'Ï¬Ï╣Ï░Ï▒ Ï¿┘åÏºÏí Ï▒ÏºÏ¿ÏÀ ÏÑÏ╣ÏºÏ»Ï® Ïº┘ä┘àÏ┤Ïº┘çÏ»Ï®.';

  @override
  String get unlockCloudflare => '┘üÏ¬Ï¡ Ïº┘ä┘é┘ü┘ä (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'يلزم التحقق من مزود الخدمة';

  @override
  String get cloudflareChallengeHelp =>
      'يطلب مزود الخدمة إجراء تحقق من Cloudflare. افتح موقعه في المتصفح وأكمل أي تحقق يظهر لك بنفسك، ثم عُد إلى هنا وأعد المحاولة. قد لا تتم مشاركة جلسة المتصفح مع التطبيق.';

  @override
  String get openProviderWebsite => 'فتح موقع مزود الخدمة';

  @override
  String get providerWebsiteUnavailable =>
      'تعذر فتح موقع مزود الخدمة. تحقق من عنوان الاشتراك ثم أعد المحاولة.';

  @override
  String get unstableConnection => 'ÏºÏ¬ÏÁÏº┘ä Ï║┘èÏ▒ ┘àÏ│Ï¬┘éÏ▒';

  @override
  String get updateAllData => 'Ï¬Ï¡Ï»┘èÏ½ Ï¼┘à┘èÏ╣ Ïº┘äÏ¿┘èÏº┘åÏºÏ¬';

  @override
  String get aiTopicsTitle =>
      '┘à┘êÏÂ┘êÏ╣ÏºÏ¬ ┘à┘éÏ¬Ï▒Ï¡Ï® Ï¿Ïº┘äÏ░┘âÏºÏí Ïº┘äÏºÏÁÏÀ┘åÏºÏ╣┘è';

  @override
  String get updateThisCategory => 'Ï¬Ï¡Ï»┘èÏ½ ┘çÏ░┘ç Ïº┘ä┘üÏªÏ®';

  @override
  String get updating => 'Ï¼ÏºÏ▒┘ì Ïº┘äÏ¬Ï¡Ï»┘èÏ½ÔÇª';

  @override
  String get updatingMediaContent =>
      'Ï¼ÏºÏ▒┘ì Ï¬Ï¡Ï»┘èÏ½ Ïº┘ä┘àÏ¡Ï¬┘ê┘ë ┘àÏ¬Ï╣Ï»Ï» Ïº┘ä┘êÏ│ÏºÏªÏÀÔÇª';

  @override
  String get volumeNormalization => '┘àÏ╣ÏºÏ»┘äÏ® Ïº┘äÏÁ┘êÏ¬';

  @override
  String get volumeNormalizationSubtitle =>
      'Ï¬Ï¡Ï» ┘à┘å ┘é┘à┘à Ïº┘äÏÁ┘êÏ¬ Ï¿┘è┘å Ïº┘ä┘é┘å┘êÏºÏ¬/Ïº┘äÏ¿Ï▒Ïº┘àÏ¼ (AGC)';

  @override
  String get watchLive => 'Ïº┘ä┘àÏ┤Ïº┘çÏ»Ï® Ïº┘ä┘àÏ¿ÏºÏ┤Ï▒Ï®';

  @override
  String get whoIsWatching => '┘à┘å ┘èÏ┤Ïº┘çÏ»Ïƒ';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => '┘é┘å┘êÏºÏ¬┘â ┘ê┘àÏ¡Ï¬┘êÏº┘â';

  @override
  String get subtitleSection => 'Ïº┘äÏ¬Ï▒Ï¼┘àÏ®';

  @override
  String get audioSection => 'Ïº┘äÏÁ┘êÏ¬';

  @override
  String get videoSection => 'Ïº┘ä┘ü┘èÏ»┘è┘ê';

  @override
  String get autoQuality => 'Ï¬┘ä┘éÏºÏª┘è';

  @override
  String get subtitleNotApplicable => '┘äÏº ┘è┘åÏÀÏ¿┘é';

  @override
  String get subtitleNotApplicableInfo =>
      'Ïº┘äÏ¿Ï½ Ïº┘ä┘àÏ¿ÏºÏ┤Ï▒ ┘äÏº ┘è┘ê┘üÏ▒ ┘àÏ│ÏºÏ▒ Ï¬Ï▒Ï¼┘àÏ®.';

  @override
  String get subtitleUnavailable => 'Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡';

  @override
  String get subtitleNoTrack => '┘äÏº ┘è┘êÏ¼Ï» ┘àÏ│ÏºÏ▒';

  @override
  String get subtitleNoTrackInfo =>
      '┘äÏº ┘è┘ê┘ü┘æÏ▒ Ïº┘ä┘àÏ▓┘ê┘æÏ» Ï¬Ï▒Ï¼┘àÏºÏ¬ ┘ä┘çÏ░Ïº Ïº┘ä┘àÏ¡Ï¬┘ê┘ë.';

  @override
  String get subtitleGuessed => '┘àÏ│ÏºÏ▒ÏºÏ¬ ┘à┘ÅÏ│Ï¬┘åÏ¬Ï¼Ï®';

  @override
  String get subtitleGuessedInfo =>
      '┘äÏº ┘èÏ╣┘ä┘å Ïº┘ä┘àÏ▓┘ê┘æÏ» Ï¬Ï▒Ï¼┘àÏºÏ¬┘ç: Ï¬┘ÅÏ┤Ï¬┘é ┘çÏ░┘ç Ïº┘ä┘àÏ│ÏºÏ▒ÏºÏ¬ ┘à┘å ÏºÏÁÏÀ┘äÏºÏ¡ Ï╣┘å┘êÏº┘å URL. ┘êÏú┘è ┘àÏ│ÏºÏ▒ Ï║┘èÏ▒ ┘à┘êÏ¼┘êÏ» Ï│┘è┘ÅÏ¿┘ä┘æÏ║ Ï╣┘å Ï«ÏÀÏú Ï╣┘åÏ» Ïº┘äÏ¬┘üÏ╣┘è┘ä.';

  @override
  String get subtitleUnavailableToast => 'Ïº┘äÏ¬Ï▒Ï¼┘àÏ® Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String get audioTrackFallback => '┘àÏ│ÏºÏ▒ ÏÁ┘êÏ¬┘è';

  @override
  String get subtitleLoading => 'Ï¼ÏºÏ▒┘ì Ï¬Ï¡┘à┘è┘ä Ïº┘äÏ¬Ï▒Ï¼┘àÏ®ÔÇª';

  @override
  String get videoQualityFallback => 'Ï¼┘êÏ»Ï® Ïº┘ä┘ü┘èÏ»┘è┘ê';

  @override
  String get close => 'ÏÑÏ║┘äÏº┘é';

  @override
  String get streamTracksError =>
      'Ï¬Ï╣Ï░┘æÏ▒Ï¬ ┘éÏ▒ÏºÏíÏ® ┘àÏ│ÏºÏ▒ÏºÏ¬ ┘çÏ░Ïº Ïº┘äÏ¿Ï½.';

  @override
  String get subtitleProviderNoAnswer => '┘ä┘à ┘èÏ│Ï¬Ï¼Ï¿ Ïº┘ä┘àÏ▓┘ê┘æÏ».';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Ïº┘äÏ¬Ï▒Ï¼┘àÏ® Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®: $reason';
  }

  @override
  String get epgNoDataTitle => '┘äÏº Ï¬┘êÏ¼Ï» Ï¿┘èÏº┘åÏºÏ¬ Ï¿Ï▒Ïº┘àÏ¼';

  @override
  String get epgLiveNow => '┘àÏ¿ÏºÏ┤Ï▒';

  @override
  String get epgSelectChannelHint =>
      'ÏºÏ«Ï¬Ï▒ ┘é┘åÏºÏ® ┘äÏ╣Ï▒ÏÂ Ï¿Ï▒┘åÏº┘àÏ¼┘çÏº';

  @override
  String get epgNow => 'Ïº┘äÏó┘å';

  @override
  String get epgZoomIn => 'Ï¬┘âÏ¿┘èÏ▒';

  @override
  String get epgZoomOut => 'Ï¬ÏÁÏ║┘èÏ▒';

  @override
  String get epgNoCurrentProgram => '┘äÏº ┘è┘êÏ¼Ï» Ï¿Ï▒┘åÏº┘àÏ¼ Ï¼ÏºÏ▒┘ì';

  @override
  String replayWindowBadge(Object days) {
    return 'ÏÑÏ╣ÏºÏ»Ï® $days ┘è┘ê┘à';
  }

  @override
  String replayWindowBadgeHours(Object hours) {
    return 'ÏÑÏ╣ÏºÏ»Ï® $hours Ï│ÏºÏ╣Ï®';
  }

  @override
  String get replayNoAvailable => '┘äÏº Ï¬┘êÏ¼Ï» ÏÑÏ╣ÏºÏ»Ï® ┘àÏ¬ÏºÏ¡Ï®';

  @override
  String replayNoneInArchiveDays(Object days) {
    return '┘äÏº ┘è┘êÏ¼Ï» Ï¿Ï▒┘åÏº┘àÏ¼ Ï╣┘ÅÏ▒ÏÂ Ï│ÏºÏ¿┘é┘ïÏº ÏÂ┘à┘å ÏúÏ▒Ï┤┘è┘ü $days ┘è┘ê┘à┘ïÏº ┘ä┘çÏ░Ïº Ïº┘äÏ¡Ï│ÏºÏ¿ ┘ü┘è ┘çÏ░┘ç Ïº┘ä┘é┘åÏºÏ®.';
  }

  @override
  String get replayNonePublished =>
      '┘äÏº ┘è┘åÏ┤Ï▒ Ïº┘ä┘àÏ▓┘ê┘æÏ» Ïú┘è Ï¿Ï▒┘åÏº┘àÏ¼ Ï╣┘ÅÏ▒ÏÂ Ï│ÏºÏ¿┘é┘ïÏº ┘ä┘çÏ░┘ç Ïº┘ä┘é┘åÏºÏ®.';

  @override
  String get epgActionFavorite => '┘à┘üÏÂ┘æ┘ä';

  @override
  String get epgActionRecording => 'Ï¬Ï│Ï¼┘è┘ä';

  @override
  String get epgActionReminder => 'Ï¬Ï░┘â┘èÏ▒';

  @override
  String get epgStartReplay => 'Ï¿Ï»Ïí Ïº┘äÏÑÏ╣ÏºÏ»Ï®';

  @override
  String get epgBack => 'Ï▒Ï¼┘êÏ╣';

  @override
  String epgWatchChannel(Object name) {
    return 'Ï┤Ïº┘çÏ» $name';
  }

  @override
  String get subtitleNoneServedByPanel =>
      '┘äÏº ┘è┘ê┘ü┘æÏ▒ Ïº┘ä┘àÏ▓┘ê┘æÏ» Ï¬Ï▒Ï¼┘àÏºÏ¬ ┘ä┘çÏ░Ïº Ïº┘ä┘àÏ¡Ï¬┘ê┘ë.';

  @override
  String subtitleVerifying(Object count) {
    return 'Ï¼ÏºÏ▒┘ì Ïº┘äÏ¬Ï¡┘é┘é ┘à┘å Ïº┘äÏ¬Ï▒Ï¼┘àÏ®ÔÇª ($count)';
  }

  @override
  String get subtitleSearchOnline => 'ÏºÏ¿Ï¡Ï½ Ï╣Ï¿Ï▒ Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬';

  @override
  String get subtitleSearchOnlineInfo =>
      '┘äÏº ┘è┘ê┘ü┘æÏ▒ Ïº┘ä┘àÏ▓┘ê┘æÏ» Ï┤┘èÏª┘ïÏº ┘ä┘çÏ░Ïº Ïº┘ä┘àÏ¡Ï¬┘ê┘ë. ┘éÏ» ┘èÏ╣Ï½Ï▒ Ïº┘äÏ¿Ï¡Ï½ Ï╣Ï¿Ï▒ Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬ Ï╣┘ä┘ë Ï¬Ï▒Ï¼┘àÏ®.';

  @override
  String get subtitleSearchOnlineRunning => 'Ï¼ÏºÏ▒┘ì Ïº┘äÏ¿Ï¡Ï½ÔÇª';

  @override
  String get subtitleOnlineResults =>
      'Ï¬Ï▒Ï¼┘àÏºÏ¬ Ï╣┘ÅÏ½Ï▒ Ï╣┘ä┘è┘çÏº Ï╣Ï¿Ï▒ Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬';

  @override
  String get subtitleOnlineEmpty =>
      '┘ä┘à ┘è┘ÅÏ╣Ï½Ï▒ Ï╣┘ä┘ë Ï¬Ï▒Ï¼┘àÏ® Ï╣Ï¿Ï▒ Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬ ┘ä┘çÏ░Ïº Ïº┘ä┘àÏ¡Ï¬┘ê┘ë.';

  @override
  String subtitleOnlineDownloads(Object count) {
    return '$count Ï¬┘åÏ▓┘è┘ä';
  }

  @override
  String get subtitleOnlineNoTmdb =>
      'Ï¬Ï╣Ï░┘æÏ▒ Ï¬Ï¡Ï»┘èÏ» ┘çÏ░Ïº Ïº┘ä┘àÏ¡Ï¬┘ê┘ë Ï╣┘ä┘ë TMDB: ┘èÏ¡Ï¬ÏºÏ¼ Ïº┘äÏ¿Ï¡Ï½ Ï╣Ï¿Ï▒ Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬ ÏÑ┘ä┘ë ┘àÏ╣Ï▒┘æ┘ü┘ç.';

  @override
  String get opensubtitlesKeyLabel =>
      'Ïº┘äÏ¿Ï¡Ï½ Ï╣┘å Ï¬Ï▒Ï¼┘àÏ® Ï╣Ï¿Ï▒ Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬ (OpenSubtitles)';

  @override
  String get opensubtitlesKeyHint => '┘à┘üÏ¬ÏºÏ¡ API ÔÇö ÏºÏ«Ï¬┘èÏºÏ▒┘è';

  @override
  String get opensubtitlesKeyActive =>
      'Ïº┘ä┘à┘üÏ¬ÏºÏ¡ ┘àÏ¡┘ü┘êÏ©: Ï¡ÏÁÏ® Ï¬┘åÏ▓┘è┘ä ÏúÏ╣┘ä┘ë.';

  @override
  String get opensubtitlesKeyAnonymous =>
      'Ï¿Ï»┘ê┘å ┘à┘üÏ¬ÏºÏ¡: Ïº┘äÏ¿Ï¡Ï½ ┘àÏ¬ÏºÏ¡Ïî 5 Ï¬┘åÏ▓┘è┘äÏºÏ¬ ┘ä┘â┘ä Ï╣┘å┘êÏº┘å IP ┘â┘ä 24 Ï│ÏºÏ╣Ï®.';

  @override
  String get opensubtitlesKeyDelete => 'Ïº┘àÏ│Ï¡ Ïº┘ä┘à┘üÏ¬ÏºÏ¡';

  @override
  String get opensubtitlesKeyCheck => 'Ïº┘äÏ¬Ï¡┘é┘é ┘à┘å Ïº┘ä┘à┘üÏ¬ÏºÏ¡';

  @override
  String get opensubtitlesKeyChecking => 'Ï¼ÏºÏ▒┘ì Ïº┘äÏ¬Ï¡┘é┘éÔÇª';

  @override
  String get opensubtitlesKeyValid =>
      '┘à┘üÏ¬ÏºÏ¡ ÏÁÏº┘äÏ¡: Ïº┘äÏ«Ï»┘àÏ® Ï¬┘éÏ¿┘ä┘ç.';

  @override
  String get opensubtitlesKeyRejected =>
      'Ï¬┘à Ï▒┘üÏÂ Ïº┘ä┘à┘üÏ¬ÏºÏ¡ ┘à┘å Ïº┘äÏ«Ï»┘àÏ®: Ï¬Ï¡┘é┘é ┘à┘å Ïú┘å┘â ┘äÏÁ┘éÏ¬┘ç ┘âÏº┘à┘ä┘ïÏº.';

  @override
  String get opensubtitlesKeyUnreachable =>
      'Ïº┘äÏ«Ï»┘àÏ® Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®: Ï¬Ï¡┘é┘é ┘à┘å ÏºÏ¬ÏÁÏº┘ä┘â ┘êÏúÏ╣Ï» Ïº┘ä┘àÏ¡Ïº┘ê┘äÏ®.';

  @override
  String get opensubtitlesLoginLabel =>
      'Ï¬Ï│Ï¼┘è┘ä Ïº┘äÏ»Ï«┘ê┘ä ÏÑ┘ä┘ë Ï¡Ï│ÏºÏ¿ OpenSubtitles';

  @override
  String get opensubtitlesLoginHintUsername => 'ÏºÏ│┘à Ïº┘ä┘àÏ│Ï¬Ï«Ï»┘à';

  @override
  String get opensubtitlesLoginHintPassword => '┘â┘ä┘àÏ® Ïº┘ä┘àÏ▒┘êÏ▒';

  @override
  String get opensubtitlesLoginActive =>
      'Ï¬┘à Ï¡┘üÏ© Ïº┘äÏ¡Ï│ÏºÏ¿: Ï│Ï¬Ï¬┘à┘â┘å Ïº┘äÏ¬┘åÏ▓┘è┘äÏºÏ¬ ┘à┘å Ï¬Ï│Ï¼┘è┘ä Ïº┘äÏ»Ï«┘ê┘ä.';

  @override
  String get opensubtitlesLoginNone =>
      '┘äÏº ┘è┘êÏ¼Ï» Ï¡Ï│ÏºÏ¿: ┘èÏ¿┘é┘ë Ïº┘äÏ¬┘åÏ▓┘è┘ä ┘àÏ▒┘ü┘êÏÂ┘ïÏº (503).';

  @override
  String get opensubtitlesLoginDelete => 'Ïº┘àÏ│Ï¡ Ïº┘äÏ¡Ï│ÏºÏ¿';

  @override
  String get opensubtitlesLoginConnect =>
      'Ï¬Ï│Ï¼┘è┘ä Ïº┘äÏ»Ï«┘ê┘ä / Ïº┘äÏ¬Ï¡┘é┘é';

  @override
  String get opensubtitlesLoginConnecting =>
      'Ï¼ÏºÏ▒┘ì Ï¬Ï│Ï¼┘è┘ä Ïº┘äÏ»Ï«┘ê┘äÔÇª';

  @override
  String get opensubtitlesLoginValid =>
      'Ï¬┘à ┘éÏ¿┘ê┘ä Ïº┘äÏ¡Ï│ÏºÏ¿: ÏúÏÁÏ»Ï▒Ï¬ Ïº┘äÏ«Ï»┘àÏ® Ï▒┘àÏ▓┘ïÏº ┘à┘à┘èÏ▓┘ïÏº.';

  @override
  String get opensubtitlesLoginRejected =>
      'Ï¬┘à Ï▒┘üÏÂ Ï¿┘èÏº┘åÏºÏ¬ Ïº┘äÏ»Ï«┘ê┘ä: Ï¬Ï¡┘é┘é ┘à┘å ÏºÏ│┘à Ïº┘ä┘àÏ│Ï¬Ï«Ï»┘à ┘ê┘â┘ä┘àÏ® Ïº┘ä┘àÏ▒┘êÏ▒.';

  @override
  String get opensubtitlesLoginUnreachable =>
      'Ïº┘äÏ«Ï»┘àÏ® Ï║┘èÏ▒ ┘àÏ¬ÏºÏ¡Ï®: Ï¬Ï¡┘é┘é ┘à┘å ÏºÏ¬ÏÁÏº┘ä┘â ┘êÏúÏ╣Ï» Ïº┘ä┘àÏ¡Ïº┘ê┘äÏ®.';

  @override
  String get subtitleOnlineNoApiKey =>
      '┘à┘üÏ¬ÏºÏ¡ OpenSubtitles API ┘à┘ü┘é┘êÏ»: ÏúÏ»Ï«┘ä┘ç ┘ü┘è Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ ┘äÏ¬┘üÏ╣┘è┘ä Ïº┘äÏ¿Ï¡Ï½ Ï╣Ï¿Ï▒ Ïº┘äÏÑ┘åÏ¬Ï▒┘åÏ¬.';

  @override
  String get subtitleOnlineKeyRejected =>
      'Ï¬┘à Ï▒┘üÏÂ ┘à┘üÏ¬ÏºÏ¡ OpenSubtitles API: ÏÑ┘å┘ç ┘à┘êÏ¼┘êÏ»Ïî ┘ä┘â┘å Ïº┘äÏ«Ï»┘àÏ® Ï¬Ï▒┘üÏÂ┘ç. Ï¬Ï¡┘é┘é ┘à┘å┘ç ┘ü┘è Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬.';

  @override
  String get subtitleOnlineQuota =>
      'Ï¬┘à Ï¿┘ä┘êÏ║ Ï¡ÏÁÏ® Ï¬┘åÏ▓┘è┘ä OpenSubtitles Ïº┘ä┘è┘ê┘à. ÏúÏ╣Ï» Ïº┘ä┘àÏ¡Ïº┘ê┘äÏ® Ï║Ï»┘ïÏº.';

  @override
  String get subtitleOnlineNeedsLogin =>
      '┘èÏ¬ÏÀ┘äÏ¿ Ï¬┘åÏ▓┘è┘ä OpenSubtitles Ï¡Ï│ÏºÏ¿┘ïÏº ┘àÏ│Ï¼┘Ä┘æ┘ä Ïº┘äÏ»Ï«┘ê┘äÏî ┘ê┘ä┘èÏ│ ┘à┘üÏ¬ÏºÏ¡ API ┘ü┘éÏÀ: Ïº┘äÏ¿Ï¡Ï½ ┘èÏ╣┘à┘äÏî ┘ä┘â┘å ┘èÏ¬┘à Ï▒┘üÏÂ Ïº┘äÏ¬┘åÏ▓┘è┘ä.';

  @override
  String get favorites => 'Ïº┘ä┘à┘üÏÂ┘äÏ®';

  @override
  String get films => 'Ïú┘ü┘äÏº┘à';

  @override
  String get replay => 'ÏÑÏ╣ÏºÏ»Ï®';

  @override
  String get myContent => '┘àÏ¡Ï¬┘êÏº┘è';

  @override
  String get contentTypeSelector => '┘å┘êÏ╣ Ïº┘ä┘àÏ¡Ï¬┘ê┘ë';

  @override
  String get downloadStatusDownloading => 'Ï¼ÏºÏ▒┘ì Ïº┘äÏ¬┘åÏ▓┘è┘ä';

  @override
  String get downloadStatusPreparing => 'Ï¼ÏºÏ▒┘ì Ïº┘äÏ¬Ï¡ÏÂ┘èÏ▒';

  @override
  String get downloadStatusPaused => '┘àÏ¬┘ê┘é┘ü ┘àÏñ┘éÏ¬┘ïÏº';

  @override
  String get downloadStatusCompleted => '┘à┘âÏ¬┘à┘ä';

  @override
  String get downloadStatusFailed => '┘üÏ┤┘ä';

  @override
  String get downloadStatusCancelled => 'Ïú┘Å┘äÏ║┘è';

  @override
  String get downloadStatusQueued => '┘ü┘è Ïº┘äÏº┘åÏ¬Ï©ÏºÏ▒';

  @override
  String get history => 'Ïº┘äÏ│Ï¼┘ä';

  @override
  String get explore => 'ÏºÏ│Ï¬┘âÏ┤Ïº┘ü';

  @override
  String get downloadsEmptyHint =>
      'ÏúÏÂ┘ü ┘àÏ¡Ï¬┘ê┘ë ┘à┘å ÏÁ┘üÏ¡Ï® Ï¬┘üÏºÏÁ┘è┘ä ┘ü┘è┘ä┘à Ïú┘ê ┘àÏ│┘äÏ│┘ä.';

  @override
  String get downloadsLocation => 'Ïº┘ä┘à┘ä┘üÏºÏ¬';

  @override
  String get advancedSettingsTitle => 'ÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ ┘àÏ¬┘éÏ»┘àÏ®';

  @override
  String get advancedSettingsIntro =>
      'Ï¿┘èÏº┘åÏºÏ¬ API ┘êÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ Ïº┘äÏ┤Ï¿┘âÏ®. ┘çÏ░┘ç Ïº┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ Ï¬Ï▒Ï¿ÏÀ Ï¡Ï│ÏºÏ¿┘â Ï¿Ï«Ï»┘àÏºÏ¬ Ï«ÏºÏ▒Ï¼┘èÏ®: ┘à┘üÏ¬ÏºÏ¡ ┘àÏ┤Ï¬Ï▒┘â ┘èÏ│Ï¬┘ç┘ä┘â Ï¡ÏÁÏ¬┘çÏî ┘êÏÑÏ╣Ï»ÏºÏ» Ï┤Ï¿┘âÏ® Ï«ÏºÏÀÏª ┘éÏ» ┘è┘à┘åÏ╣ Ïº┘äÏ¬ÏÀÏ¿┘è┘é ┘à┘å Ïº┘äÏ¿Ï»Ïí.';

  @override
  String get advancedSubtitlesProvider => '┘àÏ▓┘ê┘æÏ» Ïº┘äÏ¬Ï▒Ï¼┘àÏ®';

  @override
  String get advancedStatus => 'Ï¡Ïº┘äÏ® Ï¿┘èÏº┘åÏºÏ¬ Ïº┘äÏºÏ╣Ï¬┘àÏºÏ»';

  @override
  String get advancedAccessTitle => '┘êÏÁ┘ê┘ä ┘àÏ¡Ï¼┘êÏ▓';

  @override
  String get advancedAccessHint => 'Ïº┘äÏ▒┘àÏ▓';

  @override
  String get advancedAccessConfirm => '┘üÏ¬Ï¡';

  @override
  String get advancedAccessWrong => 'Ï▒┘àÏ▓ Ï║┘èÏ▒ ÏÁÏ¡┘èÏ¡';

  @override
  String get advancedHiddenHint =>
      'ÏºÏÂÏ║ÏÀ ┘àÏÀ┘ê┘äÏº┘ï ┘ä┘äÏÑÏ╣Ï»ÏºÏ»ÏºÏ¬ Ïº┘ä┘àÏ¬┘éÏ»┘àÏ®';

  @override
  String get favoritesAndDownloads => 'Ïº┘ä┘à┘üÏÂ┘äÏ® ┘êÏº┘äÏ¬┘åÏ▓┘è┘äÏºÏ¬';

  @override
  String get activeAudio => 'Ïº┘äÏÁ┘êÏ¬ ┘èÏ╣┘à┘ä Ï╣┘ä┘ë ┘çÏ░┘ç Ïº┘äÏ┤ÏºÏ┤Ï®';

  @override
  String get addChannel => 'ÏÑÏÂÏº┘üÏ® ┘é┘åÏºÏ®';

  @override
  String get noChannelSelected => '┘ä┘à ┘èÏ¬┘à Ï¬Ï¡Ï»┘èÏ» Ïú┘è ┘é┘åÏºÏ®';

  @override
  String get removeChannel => 'ÏÑÏ▓Ïº┘äÏ® Ïº┘ä┘é┘åÏºÏ®';

  @override
  String get avatarCategoryAll => 'Ï¼┘à┘èÏ╣';

  @override
  String get avatarCategoryCharacters => 'Ï┤Ï«ÏÁ┘èÏºÏ¬';

  @override
  String get avatarCategorySmileys => '┘àÏ▓ÏºÏ¡';

  @override
  String get avatarCategoryBlackWhite => 'ÏúÏ¿┘èÏÂ ┘êÏúÏ│┘êÏ»';

  @override
  String get avatarCategoryPixels => 'Ï¿┘âÏ│┘äÏºÏ¬';
}
