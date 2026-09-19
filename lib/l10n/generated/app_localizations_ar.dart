// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get accountDeviceProfile => 'ملف الجهاز والتشخيص';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'الملف $label · تشخيص المشغّل';
  }

  @override
  String get accountNoSubscription => 'لا يوجد اشتراك نشط';

  @override
  String get accountPreferences => 'تفضيلات الملف الشخصي';

  @override
  String get accountPreferencesSubtitle => 'اللغة، المظهر، قيود العمر، رمز PIN';

  @override
  String get accountProfiles => 'ملفات المستخدمين';

  @override
  String get accountProfilesSubtitle => 'إدارة الملفات والملف النشط';

  @override
  String get accountSubscriptions => 'اشتراكات Xtream/M3U';

  @override
  String activeCountOngoing(Object count) {
    return '$count قيد التنفيذ';
  }

  @override
  String get addSubscription => 'إضافة اشتراك';

  @override
  String addedToFavorites(Object title) {
    return 'تمت إضافة «$title» إلى المفضلة';
  }

  @override
  String get age => 'العمر';

  @override
  String get ageRange13to17 => '13 - 17 سنة';

  @override
  String get ageRange18to24 => '18 - 24 سنة';

  @override
  String get ageRange25to34 => '25 - 34 سنة';

  @override
  String get ageRange35to44 => '35 - 44 سنة';

  @override
  String get ageRange45to54 => '45 - 54 سنة';

  @override
  String get ageRange55plus => '55 سنة فأكثر';

  @override
  String get ageRangeUnder12 => 'أقل من 12 سنة';

  @override
  String get appTitle => 'أوربت IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'الظهور في عمليات البحث والتوصيات';

  @override
  String get apply => 'تطبيق';

  @override
  String get audioAndNightFocus => 'الصوت ووضع الليل';

  @override
  String get audioAndNightFocusSubtitle =>
      'تحسين ليلي، تعزيز الحوار، مزامنة الصوت/الفيديو';

  @override
  String get audioShift => 'إزاحة صوتية قابلة للضبط';

  @override
  String get audioShiftMinus50 => '-50 مللي ثانية';

  @override
  String get audioShiftPlus50 => '+50 مللي ثانية';

  @override
  String get audioShiftSubtitle => 'إزاحة صوت/فيديو يدوية (بالملي ثانية)';

  @override
  String get autoQualityDescription => 'يتيح لمشغل اختيار أفضل جودة';

  @override
  String get autoReconnectLive => 'إعادة اتصال مباشرة تلقائية';

  @override
  String get autoReconnectLiveSubtitle =>
      'محاولة إعادة الاتصال تلقائيًا إذا انقطع البث';

  @override
  String get avSyncDialogHint => 'إيجابي = الصوت متقدم، سلبي = الصوت متأخر';

  @override
  String get avSyncDialogLabel => 'الإزاحة (بالملي ثانية)';

  @override
  String get avSyncDialogTitle => 'معايرة الصوت/الفيديو';

  @override
  String get backupExport => 'تصدير الإعدادات';

  @override
  String get backupExportSubtitle => 'نسخ الإعدادات كاملة إلى الحافظة';

  @override
  String get backupImport => 'استيراد الإعدادات';

  @override
  String get backupImportSubtitle => 'الاستعادة من الحافظة (JSON)';

  @override
  String get bassKiller => 'قاطع الباص (قطع أقل من 120 هرتز)';

  @override
  String get bassKillerSubtitle => 'يقلل الترددات المنخفضة لتجنب الاهتزازات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get castToChromecast => 'إرسال إلى Chromecast';

  @override
  String get catchUpTv => 'متابعة البرامج';

  @override
  String get categories => 'الفئات';

  @override
  String get certPinning => 'تفعيل تثبيت الشهادة';

  @override
  String get certPinningAdd => 'إضافة البصمات أعلاه';

  @override
  String get certPinningHint =>
      'البصمات المسموح بها (واحدة لكل سطر، سداسية عشرية بأحرف كبيرة):';

  @override
  String get certPinningSubtitle =>
      'يتحقق من بصمة SHA-256 لشهادة SSL الخاصة بالخادم (مضاد للـ MITM)';

  @override
  String get changePinCode => 'تغيير رمز PIN';

  @override
  String get channelsUnavailable => 'القنوات غير متاحة';

  @override
  String get chooseProfile => 'اختر ملفاً شخصياً';

  @override
  String get clearCaches => 'مسح كل الكاش';

  @override
  String get clearCachesSubtitle => 'الصور، فهرس البحث، بيانات TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'المزامنة مفعّلة';

  @override
  String cloudSyncLastSync(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get cloudSyncNow => 'زامن الآن';

  @override
  String get cloudSyncNowSubtitle => 'إرسال التغييرات المحلية إلى السحابة';

  @override
  String get cloudSyncSubtitleOff =>
      'مزامنة المفضلات والمُشاهَد والحديث نحو السحابة';

  @override
  String get cloudflareReset => 'إعادة ضبط إعدادات Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'مسح الكوكيز، TLS Impersonation=OFF، وكيل ExoPlayer الافتراضي';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get confirmAndContinue => 'تأكيد والمتابعة';

  @override
  String get coverCacheCleared => 'تم تفريغ ذاكرة التخزين المؤقت للأغلفة.';

  @override
  String get createKidProfile => 'إنشاء ملف شخصي للأطفال';

  @override
  String get createNewProfile => 'إنشاء ملف شخصي جديد';

  @override
  String get createProfile => 'إنشاء ملف شخصي';

  @override
  String get dataAlreadyFresh => 'البيانات محدثة (أقل من 30 دقيقة)';

  @override
  String get dataAndPrivacy => 'البيانات والخصوصية';

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String get deleteAllConfirm => 'هل تريد حذف الكل؟';

  @override
  String get deletePin => 'حذف رمز PIN';

  @override
  String get deleteProfileConfirm => 'هل تريد حذف الملف الشخصي؟';

  @override
  String get detailUnavailable => 'التفاصيل غير متاحة';

  @override
  String get diagnosticUnavailable => 'التشخيص غير متاح';

  @override
  String get dialogueBoost => 'تعزيز الحوار (+4 ديسيبل)';

  @override
  String get dialogueBoostSubtitle => 'يضخّم الأصوات مقارنة بالمؤثرات/الموسيقى';

  @override
  String get disableSubtitles => 'تعطيل الترجمة';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'مزود DNS (DoH)';

  @override
  String get dnsProviderSubtitle => 'الخادم المستخدم لاستعلامات DNS عبر HTTPS';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'تلقائي (النظام)';

  @override
  String downloadFailed(Object error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String get downloads => 'التنزيلات';

  @override
  String get dpadNavigation => 'تنقل محسّن بلوحة الاتجاهات';

  @override
  String get dpadNavigationSubtitle =>
      'تركيز مرئي، هالة مضيئة، التفاف النص (وضع التلفاز)';

  @override
  String get enableParentalControl => 'تفعيل الرقابة الأبوية';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'مباشر: $live · فيديو عند الطلب: $vod';
  }

  @override
  String get enginesTile => 'محركات التشغيل';

  @override
  String get enterNew4DigitPin => 'أدخل رمزاً جديداً من 4 أرقام';

  @override
  String get epgGrille => 'EPG (الجدول)';

  @override
  String get epgGuideTv => 'دليل TV (EPG)';

  @override
  String get episode => 'الحلقة';

  @override
  String errorGeneric(Object error) {
    return 'خطأ: $error';
  }

  @override
  String errorLoading(Object error) {
    return 'خطأ في التحميل: $error';
  }

  @override
  String get errorSaving => 'خطأ أثناء الحفظ';

  @override
  String get exitWithoutSaving => 'الخروج بدون حفظ؟';

  @override
  String get failedToLoadProfiles => 'تعذر تحميل الملفات الشخصية';

  @override
  String get fallbackEngine => 'المحرك الاحتياطي';

  @override
  String get favoriteGenres => 'الأنواع المفضلة';

  @override
  String get filmsVod => 'أفلام (VOD)';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get fontSize => 'حجم نص أكبر';

  @override
  String get fontSizeSubtitle => 'يكبّر النصوص في التطبيق كله';

  @override
  String get forYou => 'لك';

  @override
  String get forYouAndDuo => 'لك ومبني على ثنائي';

  @override
  String get forYouMatchmaking => 'لك (المطابقة)';

  @override
  String get forward10s => 'تقديم 10 ثوانٍ';

  @override
  String get forward30s => 'تقديم 30 ثانية';

  @override
  String get groupMode => 'مجتمعي';

  @override
  String get highContrast => 'وضع التباين العالي';

  @override
  String get highContrastSubtitle => 'يحسن الوضوح لضعاف البصر';

  @override
  String get historyUnavailable => 'السجل غير متاح';

  @override
  String get instantZapping => 'تنقل فوري (تحميل مسبق)';

  @override
  String get instantZappingSubtitle =>
      'تحميل القنوات المجاورة مسبقًا في الذاكرة';

  @override
  String get kidsContent => 'محتوى مناسب للأطفال';

  @override
  String get kidsMode => 'وضع الأطفال';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langSpanish => 'Español';

  @override
  String get language => 'اللغة';

  @override
  String get languageExample => 'Français, English, إلخ';

  @override
  String get languagePreference => 'لغة التطبيق';

  @override
  String get languageUndetermined => 'غير محدد';

  @override
  String get later => 'لاحقاً';

  @override
  String get legalNotice => 'اقرأني · إشعار قانوني';

  @override
  String get legalNoticeSubtitle => 'استخدام التطبيق، أصحاب الحقوق والخصوصية';

  @override
  String get liveChannelsAndZapping => 'القنوات المباشرة والتبديل';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'السجلات والتشخيص';

  @override
  String get logsDiagnosticSubtitle => 'عرض السجلات، التصدير، مسح الكاش';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'رابط قائمة التشغيل M3U';

  @override
  String get mainCast => 'طاقم التمثيل الرئيسي';

  @override
  String get manualAvCalibration => 'معايرة يدوية للصوت/الفيديو';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'الإزاحة الحالية: $ms ملي ثانية';
  }

  @override
  String get matchmaking => 'من أجلك (المطابقة)';

  @override
  String get matchmakingSubtitle => 'إدارة المطابقة والاقتراحات المخصصة';

  @override
  String maxProfilesReached(Object max) {
    return 'تم الوصول إلى الحد الأقصى لعدد الملفات الشخصية ($max)';
  }

  @override
  String get memory => 'الذاكرة';

  @override
  String get moviesUnavailable => 'الأفلام غير متاحة';

  @override
  String get multiScreen => 'شاشات متعددة';

  @override
  String get multiVideo => 'فيديو متعدد';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get nameOptional => 'الاسم (اختياري)';

  @override
  String get nameOrNickname => 'الاسم / الكنية';

  @override
  String get navigateToOkToSelect => 'انتقل إلى OK للتحديد';

  @override
  String get networkDisconnected => 'انقطع الاتصال بالشبكة';

  @override
  String get never => 'أبدًا';

  @override
  String get newAnd4K => 'جديد و4K';

  @override
  String get newProfile => 'ملف شخصي جديد';

  @override
  String get nextChannel => 'القناة التالية';

  @override
  String get nightFocusEnable => 'تفعيل وضع الليل';

  @override
  String get nightFocusEnableSubtitle =>
      'معالجة صوتية فورية: تعزيز الحوار، خفض الباص، المزامنة';

  @override
  String get nightFocusTitle => 'وضع الليل (وضع الليل)';

  @override
  String get noAudioTrackDetected => 'لم يتم اكتشاف مسار صوتي';

  @override
  String get noChannelsAvailable => 'لا توجد قنوات متاحة';

  @override
  String get noChromecastDeviceFound => 'لم يتم العثور على جهاز Chromecast.';

  @override
  String get noDownloads => 'لا توجد تنزيلات';

  @override
  String get noEpisodes => 'لا توجد حلقات';

  @override
  String get noFavoriteChannels => 'لا توجد قنوات مفضلة';

  @override
  String get noFavoriteMovies => 'لا توجد أفلام مفضلة';

  @override
  String get noFavoriteReplays => 'لا توجد إعادة مشاهدة مفضلة';

  @override
  String get noFavoriteSeries => 'لا توجد سلسل مفضلة';

  @override
  String get noHistory => 'لا يوجد سجل';

  @override
  String get noKidsChannels => 'لا توجد قنوات أطفال';

  @override
  String get noKidsMovies => 'لا توجد أفلam أطفال';

  @override
  String get noKidsReplays => 'لا توجد إعادة مشاهدة أطفال';

  @override
  String get noKidsSeries => 'لا توجد سلسل أطفال';

  @override
  String get noMoviesAvailable => 'لا توجد أفلام متاحة';

  @override
  String get noProfileAvailable => 'لا يوجد ملف شخصي متاح';

  @override
  String get noProfilesYet => 'لا توجد ملفات شخصية بعد';

  @override
  String get noProgramInfoAvailable => 'لا تتوفر معلومات عن البرنامج';

  @override
  String get noRankings => 'لا توجد ترتيبات';

  @override
  String get noReplaysInCategory => 'لا توجد إعادة مشاهدة في هذه الفئة';

  @override
  String noResultsFor(Object query) {
    return 'لا توجد نتائج لـ $query';
  }

  @override
  String get noSeriesAvailable => 'لا توجد سلسل متاحة';

  @override
  String get noStationsAvailable => 'لا توجد محطات متاحة';

  @override
  String get noVideoQualityDetected => 'لم يتم اكتشاف جودة فيديو';

  @override
  String get notAvailableInCatalog => 'غير متوفر في الكتالوج';

  @override
  String get offline => 'غير متصل';

  @override
  String get parentalControl => 'الرقابة الأبوية';

  @override
  String get parentalControlSubtitle => 'إضافة رمز PIN وتقييد المحتوى';

  @override
  String get pauseDownload => 'إيقاف مؤقت';

  @override
  String get pinCode => 'رمز PIN';

  @override
  String get pinDeleted => 'تم حذف رمز PIN';

  @override
  String get pinMustBe4Digits => 'يجب أن يحتوي رمز PIN على 4 أرقام بالضبط';

  @override
  String get pinSaved => 'تم حفظ رمز PIN';

  @override
  String get pip => 'العرض العائم (PiP)';

  @override
  String get pipUnavailable => 'العرض العائم (PiP) غير متاح على هذا الجهاز';

  @override
  String get playHistoryCleared => 'تم مسح سجل المشاهدة.';

  @override
  String plusAgeYears(Object age) {
    return '+$age سنوات';
  }

  @override
  String get preferences => 'التفضيلات';

  @override
  String get previousChannel => 'القناة السابقة';

  @override
  String get primaryEngine => 'المحرك الرئيسي';

  @override
  String get profileVisible => 'ملف شخصي مرئي';

  @override
  String get programGrid => 'جدول البرامج';

  @override
  String get protectWithPin => 'الحماية برمز PIN';

  @override
  String get rankingsUnavailable => 'الترتيب غير متاح';

  @override
  String get receiveAlertsAndTips => 'استقبال التنبيهات والنصائح';

  @override
  String get recentSearch => 'بحث حديث';

  @override
  String get recentSearches => 'الأخيرة';

  @override
  String get recentlyWatched => 'شوهد مؤخراً';

  @override
  String get removeAll => 'إزالة الكل';

  @override
  String get removeFromWatchedConfirm => 'إزالة الكل من المشاهدة؟';

  @override
  String get replaysUnavailable => 'إعادة المشاهدة غير متاحة';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get resetApp => 'إعادة ضبط التطبيق';

  @override
  String get resetAppDialogBody =>
      'سيتم مسح جميع البيانات: الملفات، المفضلات، السجل، الإعدادات. هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get resetAppDialogConfirm => 'مسح كل شيء';

  @override
  String get resetAppDialogTitle => 'إعادة ضبط التطبيق؟';

  @override
  String get resetAppSubtitle =>
      'يمسح جميع بيانات المستخدم (الملفات، المفضلات، السجل)';

  @override
  String get resetCompleted => 'تمت إعادة التعيين';

  @override
  String get resumePlayback => 'هل تريد استئناف التشغيل؟';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get retrySearch => 'إعادة محاولة البحث';

  @override
  String get rewind10s => 'ترجيع 10 ثوانٍ';

  @override
  String get rewind30s => 'ترجيع 30 ثانية';

  @override
  String get rightsHolders => 'أصحاب الحقوق';

  @override
  String get save => 'حفظ';

  @override
  String get sdkAndroid => 'SDK Android';

  @override
  String get searchChannel => 'البحث عن قناة';

  @override
  String get searchError => 'خطأ في البحث';

  @override
  String get searchMovie => 'البحث عن فيلم';

  @override
  String get searchSeries => 'البحث عن سلسل';

  @override
  String seasonNumber(Object season) {
    return 'الموسم $season';
  }

  @override
  String get seasonsAndEpisodes => 'المواسم والحلقات';

  @override
  String get sectionAccessibility => 'إمكانية الوصول';

  @override
  String get sectionAccountProfile => 'الحساب والملف الشخصي';

  @override
  String get sectionAntiThrottle => 'حماية من تخفيف سرعة مزود الإنترنت';

  @override
  String get sectionAudioNight => 'الصوت ووضع الليل';

  @override
  String get sectionAvSync => 'مزامنة الصوت/الفيديو';

  @override
  String get sectionBackup => 'النسخ الاحتياطي / الاستعادة';

  @override
  String get sectionCertPinning => 'تثبيت الشهادة (SHA-256)';

  @override
  String get sectionCloudSync => 'المزامنة السحابية (عدة أجهزة)';

  @override
  String get sectionCloudflare => 'تحسين Cloudflare';

  @override
  String get sectionDiagnostics => 'التشخيص والصيانة';

  @override
  String get sectionEngines => 'محركات التشغيل';

  @override
  String get sectionLegal => 'معلومات قانونية';

  @override
  String get sectionMemory => 'الذاكرة والكاش';

  @override
  String get sectionNotifications => 'الإشعارات';

  @override
  String get sectionOutput => 'مخرج الصوت';

  @override
  String get sectionParental => 'الرقابة الأبوية';

  @override
  String get sectionRecommendations => 'التوصيات';

  @override
  String get sectionResilience => 'مرونة الخدمة';

  @override
  String get sectionTmdb => 'تصنيفات TMDB';

  @override
  String get sectionZapping => 'التنقل والأداء';

  @override
  String get select => 'اختيار';

  @override
  String get selectProfileForRecommendations =>
      'اختر ملفاً شخصياً لعرض توصياته';

  @override
  String get series => 'السلسل';

  @override
  String get seriesNotFound => 'السلسل غير موجودة';

  @override
  String get seriesUnavailable => 'السلسل غير متاحة';

  @override
  String get seriesUnavailableTemporarily => 'السلسل غير متاحة حالياً.';

  @override
  String get serverProtectedAntiLeech => 'الخادم محمي (مضاد للتنزيل)';

  @override
  String get serverUrlPlaceholder => 'رابط الخادم (مثال: https://provider.com)';

  @override
  String get serviceNature => 'طبيعة الخدمة';

  @override
  String get setAsDefaultServer => 'تعيين كخادم افتراضي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get similarMovies => 'أفلام مشابهة';

  @override
  String get snackBackupExported => 'تم تصدير الإعدادات إلى الحافظة';

  @override
  String get snackCacheCleared => 'تم مسح الكاش';

  @override
  String get snackCloudflareReset => 'تمت إعادة ضبط إعدادات Cloudflare';

  @override
  String snackImportError(String message) {
    return 'خطأ: $message';
  }

  @override
  String get snackImportSuccess => 'تم استيراد الإعدادات بنجاح';

  @override
  String get snackNoBackup => 'لم يتم العثور على نسخة احتياطية';

  @override
  String get sortBestRated => 'الأعلى تقييماً (XCIPTV)';

  @override
  String get sortLatestM3UXtream => 'آخر الإضافات M3U/Xtream';

  @override
  String get sortNameAToZ => 'الاسم (أ → ي)';

  @override
  String get sortNameZToA => 'الاسم (ي → أ)';

  @override
  String get sortResumePriority => 'المتابعة أولاً';

  @override
  String get sortYearRecentToOld => 'سنة الإصدار (الأحدث → الأقدم)';

  @override
  String specialGuestsSeason(Object season) {
    return 'ضيوف خاصين - الموسم $season';
  }

  @override
  String get srtVttUrl => 'رابط .srt / .vtt';

  @override
  String get start => 'تشغيل';

  @override
  String get stationsUnavailable => 'المحطات غير متاحة';

  @override
  String get stopCasting => 'إيقاف الإرسال';

  @override
  String get streamDetails => 'تفاصيل البث';

  @override
  String subtitleLoadError(Object error) {
    return 'خطأ في تحميل الترجمة: $error';
  }

  @override
  String get subtitlesUnavailable => 'الترجمة: غير متاحة';

  @override
  String get system => 'النظام';

  @override
  String get tabAccount => 'الحساب';

  @override
  String get tabAdvanced => 'متقدم';

  @override
  String get tabAudio => 'الصوت';

  @override
  String get tabNetwork => 'الشبكة';

  @override
  String get tabPlayer => 'المشغّل';

  @override
  String get tabSecurity => 'الأمان';

  @override
  String get testNotifications => 'اختبار الإشعارات';

  @override
  String get testNotificationsSubtitle => 'إرسال إشعار محلي تجريبي';

  @override
  String get theme => 'المظهر';

  @override
  String get tlsImpersonation => 'انتحال TLS (خادم وسيط محلي)';

  @override
  String get tlsImpersonationSubtitle =>
      'يحاكي بصمة متصفح حديث لتجاوز Cloudflare';

  @override
  String get tmdbKeyActive => 'المفتاح الشخصي نشط — يتم تجاهل المفتاح المشترك';

  @override
  String get tmdbKeyColumn => 'مفاتيح TMDB';

  @override
  String get tmdbKeyDelete => 'حذف المفتاح الشخصي';

  @override
  String get tmdbKeyHint => 'يُستخدم المفتاح المشترك المضمّن افتراضيًا';

  @override
  String get tmdbKeyLabel => 'مفتاح TMDB API الشخصي (اختياري)';

  @override
  String get tmdbKeyShared =>
      'المفتاح المشترك المضمّن قيد الاستخدام (لا يوجد مفتاح شخصي)';

  @override
  String get tvChannels => 'قنوات TV';

  @override
  String get unableToBuildReplayUrl => 'تعذر بناء رابط إعادة المشاهدة.';

  @override
  String get unlockCloudflare => 'فتح القفل (Cloudflare)';

  @override
  String get unstableConnection => 'اتصال غير مستقر';

  @override
  String get updateAllData => 'تحديث جميع البيانات';

  @override
  String get updateThisCategory => 'تحديث هذه الفئة';

  @override
  String get updating => 'جارٍ التحديث…';

  @override
  String get volumeNormalization => 'معادلة الصوت';

  @override
  String get volumeNormalizationSubtitle =>
      'تحد من قمم الصوت بين القنوات/البرامج (AGC)';

  @override
  String get watchLive => 'المشاهدة المباشرة';

  @override
  String get whoIsWatching => 'من يشاهد؟';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'قنواتك ومحتواك';
}
