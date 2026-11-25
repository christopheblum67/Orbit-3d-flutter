// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get castSearching => 'جارٍ البحث عن أجهزة Cast…';

  @override
  String get castReceiverNotReady => 'جهاز الاستقبال غير جاهز بعد';

  @override
  String castConnectedTo(String name) {
    return 'متصل بـ $name';
  }

  @override
  String castConnectionFailed(String name) {
    return 'تعذر الاتصال بـ $name.';
  }

  @override
  String get playerPause => 'إيقاف مؤقت';

  @override
  String get playerNightFocusOn => 'Night Focus (مفعّل)';

  @override
  String get playerNightFocusOff => 'Night Focus (غير مفعّل)';

  @override
  String get playerLoadingProgram => 'جارٍ تحميل البرنامج…';

  @override
  String get audioNightHelp =>
      'يُطبق تحسين الصوت على المحرك الأصلي عند تفعيل Night Focus، وتُحفظ الإعدادات للتشغيل التالي.';

  @override
  String get audioNightTitle => 'التحسين الليلي (Night Focus)';

  @override
  String get audioDialogueBoost => 'تعزيز الحوار';

  @override
  String get audioDialogueHelp => 'يعزز نطاق تردد الأصوات (1–4 كيلوهرتز)';

  @override
  String get audioBassLimiter => 'خفض الجهير ومحدد الصوت';

  @override
  String get audioBassHelp => 'يخفض الجهير العميق ويضغط الارتفاعات المفاجئة';

  @override
  String get audioVocalGain => 'تعزيز الأصوات:';

  @override
  String get audioSyncTitle => 'تأخير الصوت (مزامنة الصوت والصورة)';

  @override
  String get audioSyncLimitations =>
      'يعمل فقط مع المشغل الداخلي وصوت PCM ‏16 بت وتفعيل Night Focus. لا تُطبّق القيم السالبة.';

  @override
  String startupResumeQuestion(String title, String position) {
    return 'استئناف «$title» عند $position؟';
  }

  @override
  String get startupLastSession => 'الجلسة الأخيرة';

  @override
  String get seriesExternalTracksHint =>
      'عند استخدام مشغل خارجي، اختر مسارات الصوت والترجمة فيه. تنطبق التفضيلات أدناه على المشغل الداخلي.';

  @override
  String seriesResetWatchedBody(int count, String title) {
    return 'سيتم تحديد الحلقات المشاهدة وعددها $count من «$title» كغير مشاهدة لهذا الملف.';
  }

  @override
  String seriesResetWatchedDone(String title) {
    return 'تمت إزالة «$title» من العناصر المشاهدة.';
  }

  @override
  String get recommendationAffinity => 'التوافق';

  @override
  String get recommendationLoadingCatalog => 'جارٍ تحميل الكتالوج…';

  @override
  String get recommendationBuilding => 'جارٍ إعداد توصياتك…';

  @override
  String get recommendationLoadingDuration =>
      'قد يستغرق ذلك ما يصل إلى دقيقة واحدة.';

  @override
  String get memoryPanelTitle => 'الذاكرة والتخزين المؤقت';

  @override
  String get memoryPanelHelp => 'امسح السجل وذاكرة الصور المؤقتة.';

  @override
  String get memoryHistoryTitle => 'مسح سجل المشاهدة';

  @override
  String get memoryHistoryHelp =>
      'يمسح السجل العام والعناصر الحديثة القديمة، إضافة إلى المحتوى الحديث ومواضع استئناف التشغيل للملف الحالي.';

  @override
  String get memoryClear => 'مسح';

  @override
  String get memoryImagesTitle => 'إفراغ ذاكرة الصور المؤقتة';

  @override
  String get memoryImagesHelp =>
      'يحرر الصور المخزنة في الذاكرة؛ وتبقى الملفات المؤقتة على القرص.';

  @override
  String get memoryPurge => 'إفراغ';

  @override
  String get sortOptionsTitle => 'خيارات الترتيب المتقدمة';

  @override
  String get sortOptionsHelp => 'اختر طريقة الترتيب باستخدام جهاز التحكم:';

  @override
  String get sortRecentDescription => 'المحتوى المستورد مؤخراً';

  @override
  String get sortResumeDescription =>
      'إظهار المحتوى الذي بدأته ولم تكمله أولاً';

  @override
  String get sortRatingDescription => 'الترتيب حسب التقييمات';

  @override
  String get sortYearDescription => 'الترتيب الزمني حسب سنة الإنتاج';

  @override
  String get sortDurationDescription => 'الترتيب حسب مدة المحتوى';

  @override
  String get sortActive => 'نشط';

  @override
  String get onboardingWelcome => 'مرحباً بك في Orbit IPTV';

  @override
  String get onboardingSubtitle => 'الإعداد التلقائي للجهاز';

  @override
  String get onboardingDeviceDetected => 'تم اكتشاف الجهاز';

  @override
  String get onboardingDevice => 'الجهاز';

  @override
  String get onboardingConnection => 'الاتصال';

  @override
  String get onboardingMobileNetwork => 'شبكة الهاتف المحمول';

  @override
  String get onboardingOtherNetwork => 'أخرى';

  @override
  String get onboardingUnknownMemory => 'غير معروفة';

  @override
  String onboardingMemoryMb(String value) {
    return '$value ميغابايت';
  }

  @override
  String onboardingMemoryGb(String value) {
    return '$value غيغابايت';
  }

  @override
  String get onboardingEco => 'اقتصادي';

  @override
  String onboardingProfile(String name) {
    return 'ملف $name';
  }

  @override
  String get onboardingEcoDescription =>
      'بدء سريع (1.5 ث) · حتى 1080p · تعطيل 3D والعرض المتعدد';

  @override
  String get onboardingStandardDescription =>
      'بدء سريع (2 ث) · عرض 3D سلس · عرض متعدد x2';

  @override
  String get onboardingUltraDescription =>
      'تبديل سريع للقنوات (3 ث · إمكانية 4K HDR) · عرض متعدد x4';

  @override
  String get onboardingResetRecommendation => 'إعادة تعيين التوصية';

  @override
  String get onboardingAdjust => 'تعديل يدوياً';

  @override
  String get onboardingChooseProfile => 'اختر ملفاً';

  @override
  String get onboardingRecommendedProfile => 'الملف الموصى به';

  @override
  String get onboardingEcoHint => 'تم تعطيل مؤثرات 3D والعرض المتعدد.';

  @override
  String get duoTitle => 'وضع Duo';

  @override
  String duoChooseOthers(int max) {
    return 'اختر من ملف شخصي واحد إلى $max ملفات إضافية';
  }

  @override
  String duoChooseWith(String name, int max) {
    return 'مع «$name» — اختر من ملف شخصي واحد إلى $max ملفات أخرى';
  }

  @override
  String get duoCreateProfile => 'أنشئ ملفاً شخصياً ثانياً على الأقل';

  @override
  String get duoNeedsProfiles => 'يتطلب وضع Duo ملفين شخصيين على الأقل.';

  @override
  String get duoFull => '4 ملفات شخصية — اكتمل فريق Duo';

  @override
  String duoReady(int count) {
    return 'تم اختيار $count ملفات شخصية — Duo جاهز';
  }

  @override
  String duoSelectOne(int count) {
    return 'اختر ملفاً شخصياً إضافياً واحداً على الأقل ($count/4)';
  }

  @override
  String get duoStart => 'بدء Duo';

  @override
  String get duoSelected => 'محدد';

  @override
  String get duoMaximum => 'بلغت الحد الأقصى';

  @override
  String get legalIntroTitle => 'Orbit IPTV · يرجى القراءة';

  @override
  String get legalIntro =>
      'قبل البدء، إليك معلومات موجزة عن استخدام التطبيق والحقوق المتعلقة بالمحتوى المعروض.';

  @override
  String get legalServicePlayer =>
      'Orbit IPTV هو مشغل IPTV يعرض بثاً توفره خوادم خارجية (اشتراك M3U أو Xtream Codes) دون استضافة أي محتوى فيديو أو صوت أو ترجمات.';

  @override
  String get legalServiceMetadata =>
      'يجمع التطبيق البيانات الوصفية ويعرضها، مثل الملصقات والملخصات ودليل البرامج، من خلال واجهات عامة. ويعمل كمتصفح متخصص لبث HLS/DASH.';

  @override
  String get legalRightsProvider =>
      'يتحمل مزود اشتراك IPTV وحده مسؤولية تراخيص القنوات وحقوق البث والحجب الجغرافي للبث الذي يوفره.';

  @override
  String get legalRightsMetadata =>
      'تأتي الملصقات والملخصات من TMDb بموجب ترخيص واجهة API؛ ويظهر إسناد TMDb أسفل صفحة التصنيفات.';

  @override
  String get legalRightsContent =>
      'لا يخزن Orbit IPTV أي محتوى مبثوث ولا يعيد توزيعه أو يحقق دخلاً منه.';

  @override
  String get legalUsageTitle => 'استخدام التطبيق';

  @override
  String get legalUsageRights =>
      'استخدم التطبيق فقط مع اشتراك تملك حقوق بث محتواه.';

  @override
  String get legalUsageRestrictions =>
      'يُحظر تجاوز الحجب الجغرافي أو أنظمة DRM ومشاركة الحساب خارج المنزل.';

  @override
  String get legalUsageEditorial =>
      'لا يختار التطبيق المحتوى المبثوث تحريرياً ولا يتحكم في بث الخوادم الخارجية.';

  @override
  String get legalPrivacyStorage =>
      'تُحفظ الملفات الشخصية والمفضلة والسجل والإعدادات محلياً. عند تفعيل المشاركة السحابية، تتم أيضاً مزامنة البيانات المحددة بشكل مشفر.';

  @override
  String get legalPrivacyConsent =>
      'لا تُجمع البيانات افتراضياً؛ تتطلب الإشعارات وأذونات الوصول الاختيارية موافقة صريحة.';

  @override
  String get legalWarningTitle => 'تنبيه';

  @override
  String get legalWarningBody =>
      'لا تشكل هذه الوثيقة استشارة قانونية. تختلف القواعد حسب الولاية القضائية؛ تحقق من أن استخدامك مسموح في بلدك وفق القانون والحد الأدنى للسن.';

  @override
  String get legalAccept => 'قرأت وأوافق · متابعة';

  @override
  String get epgReplayAvailableOnChannel => 'الإعادة متاحة على هذه القناة';

  @override
  String actorBornOn(String date) {
    return 'تاريخ الميلاد: $date';
  }

  @override
  String get actorGenderMale => 'ذكر';

  @override
  String get actorGenderFemale => 'أنثى';

  @override
  String get crewTitle => 'الطاقم الفني';

  @override
  String get crewDirecting => 'الإخراج';

  @override
  String get crewWriting => 'السيناريو';

  @override
  String get crewProduction => 'الإنتاج';

  @override
  String get crewSound => 'الصوت';

  @override
  String get crewCamera => 'التصوير';

  @override
  String get crewEditing => 'المونتاج';

  @override
  String get crewArt => 'الإدارة الفنية';

  @override
  String get crewCostume => 'الأزياء والمكياج';

  @override
  String get crewVisualEffects => 'المؤثرات البصرية';

  @override
  String get crewLighting => 'الإضاءة';

  @override
  String get menuContinue => 'متابعة';

  @override
  String get menuDiscover => 'اكتشف';

  @override
  String get menuHome => 'الرئيسية';

  @override
  String get menuSearch => 'بحث';

  @override
  String get menuProfile => 'الملف الشخصي';

  @override
  String get menuSubscriptions => 'الاشتراكات';

  @override
  String get menuSelect => 'اختر قائمة فرعية';

  @override
  String get menuContent => 'المحتوى';

  @override
  String get profileMustKeepOne =>
      'يجب أن يبقى ملف شخصي واحد على الأقل على الجهاز';

  @override
  String profileDeleteBody(String name) {
    return 'سيُحذف «$name» وتفضيلاته نهائيًا. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get profileChange => 'تغيير الملف الشخصي';

  @override
  String get profileEdit => 'تعديل';

  @override
  String get profileDelete => 'حذف';

  @override
  String get profileBack => 'رجوع';

  @override
  String get profileAdult => 'بالغ';

  @override
  String get profileChild => 'طفل';

  @override
  String get profileExpert => 'خبير';

  @override
  String get categoryTitle => 'الفئات';

  @override
  String get categoryShowAll => 'إظهار الكل';

  @override
  String get categoryScanFailed => 'تعذر الفحص: لا يستجيب المزود.';

  @override
  String get categoryEmptyLive => 'لا توجد فئات للبث المباشر لدى هذا المزود.';

  @override
  String get categoryEmptyMovies => 'لا توجد فئات أفلام لدى هذا المزود.';

  @override
  String get categoryEmptySeries => 'لا توجد فئات مسلسلات لدى هذا المزود.';

  @override
  String categoryHidden(String label, int count) {
    return '$label ($count مخفية)';
  }

  @override
  String get categoryNeverScanned => 'لم يُفحص مطلقًا';

  @override
  String get categoryScannedToday => 'فُحص اليوم';

  @override
  String get categoryScannedYesterday => 'فُحص أمس';

  @override
  String categoryScannedDaysAgo(int days) {
    return 'فُحص منذ $days أيام';
  }

  @override
  String categorySubscriptionSettings(String status) {
    return 'إعدادات هذا الاشتراك — $status';
  }

  @override
  String get categoryScanning => 'جارٍ الفحص…';

  @override
  String get categoryRescan => 'إعادة فحص الفئات';

  @override
  String categoryChannelsCount(int count) {
    return '$count قنوات';
  }

  @override
  String categoryTitlesCount(int count) {
    return '$count عنوانًا';
  }

  @override
  String get liveWatchAction => 'مشاهدة';

  @override
  String get livePreviewDisabled =>
      'معاينة الفيديو معطلة. اضغط على مشاهدة لفتح القناة.';

  @override
  String get livePreviewFrozen => 'المعاينة متوقفة';

  @override
  String get livePreviewRetry => 'إعادة المحاولة';

  @override
  String get episodeMarkWatchedFailed =>
      'تعذر وضع علامة مشاهدة على هذه الحلقة.';

  @override
  String get episodeAlreadyWatched => 'الحلقة تمت مشاهدتها';

  @override
  String get episodeMarkWatched => 'وضع علامة مشاهدة';

  @override
  String episodeResumeAt(String position) {
    return 'المتابعة من $position';
  }

  @override
  String get episodeActionsHelp =>
      'اضغط مطولًا على OK لوضع علامة مشاهدة أو إعادة التعيين.';

  @override
  String episodesCount(int count) {
    return '$count حلقة';
  }

  @override
  String episodesInProgress(int count) {
    return '$count حلقة قيد المشاهدة';
  }

  @override
  String episodesWatchedCount(int seen, int total) {
    return 'تمت مشاهدة $seen من $total';
  }

  @override
  String get episodeWatched => 'تمت المشاهدة';

  @override
  String get homeRefreshFailed => 'فشل التحديث: لم يستجب أي مصدر.';

  @override
  String get homeRefreshDone => 'اكتمل التحديث.';

  @override
  String get homeRefreshEmpty => 'اكتمل التحديث، لا توجد بيانات متاحة.';

  @override
  String get homeChangeSubscription => 'تغيير الاشتراك';

  @override
  String get homeNoSubscription => 'لا يوجد اشتراك';

  @override
  String get homeAddOrChangeSubscription => 'إضافة اشتراك أو تغييره';

  @override
  String get homeMultiStream => 'حتى 4 تدفقات في الوقت نفسه';

  @override
  String get homeRadioStations => 'محطات مباشرة';

  @override
  String get homeRefreshUnknown => 'آخر تحديث غير معروف';

  @override
  String homeRefreshMinutes(int minutes) {
    return 'تم التحديث منذ $minutes دقيقة';
  }

  @override
  String get catalogAll => 'الكل';

  @override
  String get catalogUngrouped => 'غير مجمّع';

  @override
  String get catalogSort => 'ترتيب';

  @override
  String get browseLoading => 'جارٍ التحميل…';

  @override
  String get startupRadio => 'الراديو';

  @override
  String get profileCreateFirstHint => 'أنشئ ملفك الشخصي الأول لبدء المشاهدة.';

  @override
  String downloadDirectoryMissing(String path) {
    return 'المجلد غير موجود: $path';
  }

  @override
  String downloadFileMissing(String path, String names) {
    return 'الملف غير موجود: $path. الملفات الموجودة: $names';
  }

  @override
  String get widevineSelectSubscription => 'اختر اشتراكًا نشطًا';

  @override
  String get widevineLoading => 'جارٍ تحميل الإعدادات';

  @override
  String get widevineLoadFailed => 'تعذر تحميل الإعدادات';

  @override
  String widevineNoLicense(String subscription) {
    return '$subscription: لم تُضبط أي رخصة';
  }

  @override
  String get widevineSelectFirst => 'اختر اشتراكًا نشطًا أولًا.';

  @override
  String get widevineUnavailable => 'إعدادات Widevine غير متاحة.';

  @override
  String widevineSaveFailed(String error) {
    return 'تعذر حفظ إعدادات Widevine: $error';
  }

  @override
  String widevineClearFailed(String error) {
    return 'تعذر مسح إعدادات Widevine: $error';
  }

  @override
  String get widevineLicenseUrl => 'رابط خادم الترخيص';

  @override
  String get widevineInvalidUrl => 'أدخل رابط HTTPS صالحًا.';

  @override
  String get widevineHeaders => 'ترويسات HTTP (JSON، اختياري)';

  @override
  String get widevineInvalidHeaders =>
      'يجب أن تكون الترويسات كائن JSON من سلاسل نصية.';

  @override
  String get widevineCertificate => 'شهادة base64 (اختياري)';

  @override
  String get widevineStorageHelp =>
      'تُحفظ الإعدادات في مخزن آمن وترتبط بهذا الاشتراك. وهي لا تجعل المشغل الذي لا يدعم Widevine متوافقًا معه.';

  @override
  String get widevineCopyLegacy => 'نسخ الإعدادات العامة السابقة';

  @override
  String get widevineClear => 'مسح';

  @override
  String get preferenceMultiTvFailed => 'تعذر حفظ إعداد Multi TV.';

  @override
  String get preferenceLight => 'فاتح';

  @override
  String get preferenceDark => 'داكن';

  @override
  String get preferenceDisabled => 'معطّل';

  @override
  String preferenceParentalEnabled(String restriction) {
    return 'مفعّل · الحد العمري $restriction';
  }

  @override
  String get preferenceMultiTvHelp =>
      'إظهار التشغيل متعدد الشاشات والسماح به لهذا الملف الشخصي.';

  @override
  String get preferenceAllowRecording => 'السماح بالتسجيل';

  @override
  String get preferenceRecordingHelp => 'السماح بتسجيل المحتوى المفضل لدي';

  @override
  String get preferenceLivePreview => 'معاينة الفيديو المباشر';

  @override
  String get preferenceLivePreviewHelp =>
      'يعرض البث المباشر أثناء تصفح القنوات. ينطبق هذا الإعداد على الجهاز.';

  @override
  String get preferenceProfileHelp => 'تُطبّق تفضيلاتك على ملفك الشخصي.';

  @override
  String get parentalAgeLimit => 'الحد العمري';

  @override
  String get parentalNone => 'بلا';

  @override
  String get parentalHideAdult => 'إخفاء محتوى البالغين';

  @override
  String get parentalHideAdultHelp =>
      'الأفلام والمسلسلات والقنوات المصنفة 18+ أو ذات المحتوى الجنسي';

  @override
  String get parentalHideViolence => 'إخفاء العنف';

  @override
  String get parentalHideViolenceHelp => 'محتوى دموي / رعب / إثارة / قتل';

  @override
  String get parentalCurrentPin => 'رمز PIN الحالي: ••••';

  @override
  String get parentalSetPin => 'تعيين رمز PIN';

  @override
  String get parentalNewPin => 'رمز PIN جديد (4 أرقام)';

  @override
  String get parentalPin => 'رمز PIN (4 أرقام)';

  @override
  String get parentalShowPin => 'إظهار رمز PIN';

  @override
  String get parentalHidePin => 'إخفاء رمز PIN';

  @override
  String get parentalUpdatePin => 'تحديث رمز PIN';

  @override
  String get subtitleAvailableTracks => 'المسارات المتاحة';

  @override
  String get subtitleAddUrl => 'إضافة ترجمة (رابط .srt/.vtt)';

  @override
  String get subtitleLoadAction => 'تحميل';

  @override
  String subtitleTrackCues(String language, int count) {
    return '$language · $count مقطع';
  }

  @override
  String multiMaxStreams(int count) {
    return 'الحد الأقصى: $count من البثوث على هذا الجهاز.';
  }

  @override
  String get multiDisabledProfile =>
      'ميزة Multi TV معطلة لهذا الملف الشخصي. فعّلها في تفضيلات الملف الشخصي.';

  @override
  String get multiAnalyzingDevice => 'جارٍ تحليل الجهاز…';

  @override
  String get multiDeviceAnalysisFailed => 'تعذر تحليل الجهاز';

  @override
  String get multiDisabledEconomy =>
      'العرض المتعدد معطل بسبب الملف الاقتصادي.\nغيّر الملف من إعداد الجهاز.';

  @override
  String engineInternal(String name) {
    return '$name (داخلي)';
  }

  @override
  String engineExternal(String name) {
    return '$name (خارجي)';
  }

  @override
  String get engineSelectionHelp =>
      'اختر المشغل لكل نوع من المحتوى والمشغل الاحتياطي عند فشل التشغيل.';

  @override
  String get engineVideoDecoding => 'فك ترميز الفيديو';

  @override
  String get engineAutoRecommended => 'تلقائي (موصى به)';

  @override
  String get engineHardware => 'العتاد';

  @override
  String get engineSoftware => 'البرمجيات';

  @override
  String get engineAutoSoftware =>
      'تلقائي: اختير فك الترميز البرمجي لهذا الجهاز';

  @override
  String get engineSubtitleDefault => 'الافتراضي';

  @override
  String get engineSubtitleDisabled => 'بدون ترجمة';

  @override
  String get engineSubtitleForced => 'ترجمة إجبارية';

  @override
  String get engineVodSubtitles => 'ترجمة الأفلام والمسلسلات';

  @override
  String get profilePinsNone => 'لا يحتوي أي ملف شخصي على رمز PIN.';

  @override
  String get profilePinsRemoveQuestion => 'إزالة رموز PIN للملفات الشخصية؟';

  @override
  String profilePinsRemoveConfirmation(int count) {
    return 'ستُزال رموز PIN من $count من الملفات الشخصية. ستبقى الملفات الشخصية وبياناتها على هذا الجهاز. وقد تُزامن التغييرات مع الأجهزة المشتركة عبر السحابة.';
  }

  @override
  String get profilePinsRemove => 'إزالة رموز PIN';

  @override
  String get profilePinsNothingToRemove => 'لا توجد رموز PIN لإزالتها.';

  @override
  String profilePinsRemoved(int count) {
    return 'أُزيلت رموز PIN من $count من الملفات الشخصية.';
  }

  @override
  String get profilePinsRemoveFailed => 'تعذرت إزالة رموز PIN. حاول مجددًا.';

  @override
  String get profilePinsLocked =>
      'تم قفل ملف شخصي مؤقتًا بعد إدخال رمز PIN خاطئ ثلاث مرات. انتظر انتهاء القفل قبل تغيير رمز PIN أو إزالته.';

  @override
  String get profileProtection => 'حماية الملفات الشخصية';

  @override
  String get profilePinsRemoveHelp =>
      'أزل رموز PIN لجميع الملفات الشخصية على هذا الجهاز. لن تُحذف الملفات الشخصية أو بياناتها.';

  @override
  String get profilePinsRemoving => 'جارٍ إزالة رموز PIN…';

  @override
  String get profilePinsRemoveAll => 'إزالة رموز PIN للملفات الشخصية';

  @override
  String get radioEmptyHint => 'أضف محطات الراديو في الإعدادات.';

  @override
  String get radioStations => 'المحطات';

  @override
  String radioStationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محطة',
      many: '$count محطة',
      few: '$count محطات',
      two: 'محطتان',
      one: 'محطة واحدة',
      zero: 'لا محطات',
    );
    return '$_temp0';
  }

  @override
  String get radioStreamUnavailable => 'بث الراديو غير متاح لهذه المحطة';

  @override
  String get livePreviousCategory => 'الفئة السابقة';

  @override
  String get liveNextCategory => 'الفئة التالية';

  @override
  String get liveGuideUnavailable => 'الدليل غير متاح';

  @override
  String get liveNoPrograms => 'لا توجد برامج متاحة';

  @override
  String get liveNoUpcomingPrograms => 'لا توجد برامج قادمة';

  @override
  String get liveNoDescription => 'لا يتوفر ملخص.';

  @override
  String get recommendationSubscriptionChanged =>
      'تغيّر الاشتراك. ابدأ مجددًا.';

  @override
  String get recommendationCannotFavorite =>
      'لا يمكن إضافة هذا المحتوى إلى المفضلة.';

  @override
  String get recommendationFavoriteFailed =>
      'تعذرت إضافة هذا المحتوى إلى المفضلة.';

  @override
  String get recommendationMovieQuestion => 'هل تملك هذا الفيلم؟';

  @override
  String get recommendationSeriesQuestion => 'هل تملك هذا المسلسل؟';

  @override
  String get recommendationMovieSeen => 'فيلم تمت مشاهدته';

  @override
  String get recommendationSeriesSeen => 'مسلسل تمت مشاهدته';

  @override
  String get recommendationRemovedFuture => 'يُزال من الاقتراحات القادمة';

  @override
  String get recommendationNotInterested => 'غير مهتم';

  @override
  String get recommendationExcluded => 'يُستبعد نهائيًا من الاقتراحات';

  @override
  String get recommendationFavoriteProfile =>
      'يُضاف إلى مفضلة الملف الشخصي الحالي';

  @override
  String get startupParsingPlaylist => 'جارٍ تحليل قائمة M3U…';

  @override
  String get startupProviderSlow =>
      'يستجيب المزود ببطء (قد يكون فحص الأمان جاريًا). يرجى الانتظار…';

  @override
  String get startupLoadingRemaining => 'جارٍ تحميل الراديو والإعادة';

  @override
  String get startupLoadingInitial =>
      'جارٍ تحميل البث المباشر والأفلام والمسلسلات ودليل التلفاز';

  @override
  String get startupCheckingSubscription => 'التحقق من الاشتراك';

  @override
  String get startupRefresh => 'التحديث';

  @override
  String startupStalled(String step, int seconds) {
    return 'لم يُسجّل تقدم في $step منذ $seconds ثانية. قد يكون الخادم بطيئًا أو غير متاح.';
  }

  @override
  String startupRefreshStalled(String step, int seconds) {
    return 'لم يُسجّل تقدم في $step منذ $seconds ثانية. قد يكون الخادم بطيئًا أو غير متاح؛ يمكنك التحقق من الاشتراك.';
  }

  @override
  String get startupMovies => 'الأفلام والفيديو حسب الطلب';

  @override
  String get startupLive => 'القنوات المباشرة';

  @override
  String get startupReady => 'جاهز!';

  @override
  String get startupBackHome => 'العودة إلى الرئيسية';

  @override
  String get startupCheckSubscription => 'التحقق من الاشتراك';

  @override
  String get browseRankings => 'التصنيفات';

  @override
  String get browsePopularRankings => 'التصنيفات الشائعة';

  @override
  String get browseRankingsUnavailableHint =>
      'اتجاهات TMDB غير متاحة. أضف مفتاح TMDB API في الإعدادات (أو TMDB_API_KEY في assets/config/runtime.env).';

  @override
  String get browseTmdbData => 'البيانات © TMDB';

  @override
  String get browsePopular => 'شائع';

  @override
  String get browseNowPlaying => 'يُعرض الآن';

  @override
  String get browseTopRated => 'الأعلى تقييمًا';

  @override
  String get browseUpcoming => 'قريبًا';

  @override
  String get browseTrendingWeek => 'اتجاهات الأسبوع';

  @override
  String get browseOnTheAir => 'قيد العرض';

  @override
  String get browseAiringToday => 'يُعرض اليوم';

  @override
  String get browseSeriesType => 'مسلسل';

  @override
  String get browseSynopsis => 'الملخص';

  @override
  String get browseExploreCategories => 'استكشف حسب الفئة';

  @override
  String get browseFavoriteHint => 'اضغط مطولًا على عنصر للعثور عليه هنا.';

  @override
  String get browseRecentHint => 'ستظهر المحتويات التي شاهدتها هنا.';

  @override
  String get browseSearchEmpty => 'لا يوجد محتوى يطابق هذا البحث.';

  @override
  String browseTitlesCount(int visible, int total) {
    return '$visible عنوانًا (من $total)';
  }

  @override
  String get catalogSearchMovies => 'البحث عن فيلم أو نوع…';

  @override
  String get catalogSearchSeries => 'البحث عن مسلسل أو نوع…';

  @override
  String get catalogLoading => 'جارٍ تحميل القائمة…\nيرجى الانتظار بضع ثوانٍ.';

  @override
  String get catalogNoMovies => 'مكتبة الأفلام فارغة حاليًا.';

  @override
  String get catalogNoSeries => 'مكتبة المسلسلات فارغة حاليًا.';

  @override
  String get catalogNoRecentMovies => 'لا توجد أفلام حديثة';

  @override
  String get catalogNoRecentSeries => 'لا توجد مسلسلات حديثة';

  @override
  String get catalogNoResults => 'لا توجد نتائج';

  @override
  String get catalogNoMoviesInCategory => 'لا توجد أفلام في هذه الفئة';

  @override
  String get catalogMovieFavoriteHint => 'اختر قلب الفيلم للعثور عليه هنا.';

  @override
  String get catalogSeriesFavoriteHint => 'اختر قلب المسلسل للعثور عليه هنا.';

  @override
  String get catalogRecentMoviesHint => 'ستظهر الأفلام التي شاهدتها هنا.';

  @override
  String get catalogRecentSeriesHint => 'ستظهر المسلسلات التي شاهدتها هنا.';

  @override
  String get catalogMovieSearchEmpty => 'لا توجد أفلام تطابق البحث.';

  @override
  String get catalogSeriesSearchEmpty => 'لا توجد مسلسلات تطابق البحث.';

  @override
  String get catalogMovieCategoryEmpty => 'لا توجد أفلام تطابق هذه الفئة.';

  @override
  String removedFromFavorites(String title) {
    return 'أزيل «$title» من المفضلة';
  }

  @override
  String get liveBackToChannels => 'العودة إلى القنوات';

  @override
  String get liveAddSourceHint => 'أضف مصدر قنوات في الإعدادات.';

  @override
  String get liveNoChannelFound => 'لم يُعثر على قنوات';

  @override
  String get liveNoRecentChannel => 'لا توجد قنوات حديثة';

  @override
  String get liveNoChannelInGroup => 'لا توجد قنوات في هذه المجموعة';

  @override
  String get liveTryAnotherSearch => 'جرّب كلمة بحث أخرى.';

  @override
  String get liveFavoriteHint => 'اختر قلب القناة للعثور عليها هنا.';

  @override
  String get liveRecentHint => 'ستظهر القنوات التي شاهدتها هنا.';

  @override
  String get liveEmptyGroupHint => 'لا تحتوي هذه المجموعة على قنوات.';

  @override
  String get liveLoadingHint =>
      'جارٍ تحميل القنوات…\nيرجى الانتظار قبل تشغيل البث.';

  @override
  String get replayNoChannels =>
      'لا تعلن أي قناة في هذا الاشتراك عن دعم إعادة المشاهدة.';

  @override
  String get replayEmptyGroup =>
      'لا تحتوي هذه المجموعة على قنوات تدعم إعادة المشاهدة.';

  @override
  String get epgLoadingBanner =>
      'جارٍ تحميل دليل التلفاز… ستظهر البرامج قريبًا.';

  @override
  String get epgNoChannelsInCategory => 'لا توجد قنوات في هذه الفئة';

  @override
  String get epgLoadingChannels => 'جارٍ تحميل القنوات…';

  @override
  String get epgChannelsLoadFailed => 'تعذر تحميل القنوات.';

  @override
  String get replayToday => 'اليوم';

  @override
  String get replayYesterday => 'أمس';

  @override
  String searchWithinHint(String type) {
    return 'البحث في $type…';
  }

  @override
  String get searchAllHint =>
      'البحث في البث المباشر والأفلام والمسلسلات والإعادة والدليل…';

  @override
  String get searchHint => 'بحث…';

  @override
  String searchWithinTitle(String type) {
    return 'البحث في $type';
  }

  @override
  String get searchUnifiedTitle => 'البحث الموحد';

  @override
  String searchWithinHelp(String type) {
    return 'اكتب للبحث في $type فقط.';
  }

  @override
  String get searchUnifiedHelp =>
      'ابحث عن قنوات مباشرة أو أفلام أو مسلسلات أو إعادات أو برامج تلفزيونية.';

  @override
  String get searchOffline => 'وضع عدم الاتصال — النتائج المحلية فقط';

  @override
  String searchResultsCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get searchNoResultsHelp => 'جرّب كلمات أخرى أو تحقق من الإملاء.';

  @override
  String get searchAllCategories => 'الكل';

  @override
  String get searchClearHistory => 'مسح السجل';

  @override
  String get settingsPlaybackEngines => 'محركات التشغيل';

  @override
  String get settingsCloudAccount => 'الحساب السحابي';

  @override
  String get settingsCloudSignIn =>
      'تسجيل الدخول باستخدام Google أو البريد الإلكتروني';

  @override
  String get settingsSyncUnavailable => 'المزامنة الكاملة غير متاحة';

  @override
  String get settingsSyncUnavailableHelp =>
      'المزامنة القديمة غير المشفرة معطلة. يمكن حفظ بيانات الملفات الشخصية يدويًا من الحساب السحابي؛ أما البيانات الأخرى فلا تتم مزامنتها.';

  @override
  String get settingsSystemAutomatic => 'تلقائي (النظام)';

  @override
  String get settingsSubtitleDefault => 'الترجمة الافتراضية';

  @override
  String get settingsSubtitleForced => 'الترجمة المفروضة';

  @override
  String get settingsSubtitleOff => 'بدون ترجمة';

  @override
  String get settingsSubtitles => 'الترجمة';

  @override
  String get settingsProtectedPlayback => 'التشغيل المحمي';

  @override
  String get settingsCategoryFilters => 'مرشحات الفئات';

  @override
  String get settingsCategoryFiltersHelp => 'الفئات المخفية لكل اشتراك';

  @override
  String get episodeSelectProfile => 'اختر ملفًا شخصيًا لتعديل هذه الحلقة.';

  @override
  String get episodeProfileChanged =>
      'تغير الملف الشخصي. يرجى المحاولة مجددًا.';

  @override
  String get episodeStatusFailed => 'تعذر تغيير حالة هذه الحلقة.';

  @override
  String get episodeResetQuestion => 'إعادة تعيين الحلقة؟';

  @override
  String get episodeMarkWatchedQuestion => 'وضع علامة مشاهدة؟';

  @override
  String episodeResetProgressMessage(String title) {
    return 'ستُعلّم «$title» كغير مشاهدة وسيُمسح تقدم تشغيلها.';
  }

  @override
  String episodeMarkUnwatchedMessage(String title) {
    return 'ستُعلّم «$title» كغير مشاهدة لهذا الملف الشخصي.';
  }

  @override
  String episodeMarkWatchedMessage(String title) {
    return 'ستُعلّم «$title» كمشاهدة لهذا الملف الشخصي.';
  }

  @override
  String get episodeMarkUnwatched => 'وضع علامة غير مشاهدة';

  @override
  String get detailAiData => 'بيانات مولّدة بالذكاء الاصطناعي';

  @override
  String detailSourceData(String source) {
    return 'بيانات $source';
  }

  @override
  String get detailUnavailableValue => 'غير متاح';

  @override
  String get detailKeywords => 'الكلمات المفتاحية';

  @override
  String get detailGenres => 'الأنواع';

  @override
  String get detailCast => 'طاقم التمثيل';

  @override
  String get detailTrailerFailed => 'تعذر فتح الإعلان';

  @override
  String get detailShowCrew => 'إظهار فريق العمل';

  @override
  String get detailHideCrew => 'إخفاء فريق العمل';

  @override
  String seriesRuntimePerEpisode(int minutes) {
    return '$minutes دقيقة/حلقة';
  }

  @override
  String seriesNetwork(String network) {
    return 'الشبكة: $network';
  }

  @override
  String seriesFirstAired(String date) {
    return 'أول عرض: $date';
  }

  @override
  String seriesSeasonsCount(int count) {
    return '$count موسم';
  }

  @override
  String get profileDiscardHelp =>
      'ستضيع التغييرات غير المحفوظة. هل تريد المغادرة؟';

  @override
  String get profileLeave => 'مغادرة';

  @override
  String get profileEditTitle => 'تعديل الملف الشخصي';

  @override
  String get profileAvatarTheme => 'نمط الصورة الرمزية';

  @override
  String get profileAvatarThemeHelp => 'اختر نمطًا ثم صورة رمزية من الشبكة';

  @override
  String get profileAvatars => 'الصور الرمزية';

  @override
  String profileCurrentTheme(String theme) {
    return 'النمط الحالي: $theme';
  }

  @override
  String get profileRequired => 'مطلوب';

  @override
  String get profileFavoriteMovieGenres => 'أنواع الأفلام المفضلة';

  @override
  String get profileGenresHelp => 'اختر نمطًا أو أكثر للتوصيات';

  @override
  String get profilePinMismatch => 'رمزا PIN غير متطابقين.';

  @override
  String get profilePinCreateFailed => 'تعذر إنشاء رمز PIN.';

  @override
  String get profilePinActive => 'رمز PIN المكون من 4 أرقام نشط';

  @override
  String get profilePinPending =>
      'تم تأكيد رمز PIN. احفظ الملف الشخصي لتفعيله.';

  @override
  String get profilePinRequest => 'طلب رمز PIN عند اختيار الملف الشخصي';

  @override
  String get profilePinCreating => 'جارٍ إنشاء رمز PIN…';

  @override
  String get profileNotFound => 'لا يوجد ملف شخصي لتعديله';

  @override
  String get profileSaveActivate => 'حفظ وتفعيل الحماية';

  @override
  String get profileCreateActivate => 'إنشاء الملف وتفعيل الحماية';

  @override
  String get profileSaveAction => 'حفظ';

  @override
  String get profileCreateAction => 'إنشاء الملف الشخصي';

  @override
  String get genreAction => 'أكشن';

  @override
  String get genreAdventure => 'مغامرة';

  @override
  String get genreAnimation => 'رسوم متحركة';

  @override
  String get genreComedy => 'كوميديا';

  @override
  String get genreRomanticComedy => 'كوميديا رومانسية';

  @override
  String get genreDrama => 'دراما';

  @override
  String get genreHorror => 'رعب';

  @override
  String get genreThriller => 'إثارة';

  @override
  String get genreDetective => 'تحقيق';

  @override
  String get genreCrime => 'جريمة';

  @override
  String get genreWar => 'حرب';

  @override
  String get genreHistorical => 'تاريخي';

  @override
  String get genreWestern => 'ويسترن';

  @override
  String get genreSciFi => 'خيال علمي';

  @override
  String get genreFantasy => 'فانتازيا';

  @override
  String get genreSuperheroes => 'أبطال خارقون';

  @override
  String get genreMystery => 'غموض';

  @override
  String get genreRomance => 'رومانسية';

  @override
  String get genreMusical => 'استعراضي';

  @override
  String get genreMusic => 'موسيقى';

  @override
  String get genreBiopic => 'سيرة ذاتية';

  @override
  String get genreDocumentary => 'وثائقي';

  @override
  String get genreTournament => 'بطولة';

  @override
  String get genreChildren => 'أطفال';

  @override
  String get genreFamily => 'عائلي';

  @override
  String get genreSuspense => 'تشويق';

  @override
  String get genreBlackWhite => 'أبيض وأسود';

  @override
  String get genreClassic => 'كلاسيكي';

  @override
  String get cloudConfirm => 'تأكيد';

  @override
  String get cloudShareProfilesTitle => 'مشاركة هذه الملفات الشخصية؟';

  @override
  String cloudDuplicateProfileId(String id) {
    return 'الاسم نفسه — المعرّف: $id';
  }

  @override
  String get cloudShareProfilesHelp =>
      'ستُضاف الملفات الشخصية المفقودة دون استبدال الملفات الموجودة. ستُشارك مفضلاتها ونشاطها، بالإضافة إلى التفضيلات والاشتراكات، بما فيها بيانات دخول IPTV. هذه البيانات مشفرة.\n\nتبقى الملفات التي تحمل الاسم نفسه منفصلة. إذا اختلفت البيانات، فستختار ما تريد الاحتفاظ به.';

  @override
  String get cloudChooseSourceTitle => 'اختيار المصدر عند التعارض';

  @override
  String get cloudChooseSourceHelp =>
      'ستُجمع الإضافات المختلفة على الجهازين. إذا عُدّلت البيانات نفسها على الجانبين، فسيُحتفظ بالمصدر المختار هنا ويُرسل إلى الجهاز الآخر. ينطبق هذا الاختيار على جميع تعارضات البداية.';

  @override
  String get cloudSourceLocal => 'استخدام هذا الجهاز كمصدر';

  @override
  String get cloudSourceRemote => 'استخدام السحابة كمصدر';

  @override
  String get cloudResetTitle => 'البدء من جديد في السحابة؟';

  @override
  String get cloudResetHelp =>
      'ستُحذف جميع الملفات الشخصية وبياناتها المشتركة من السحابة. ستبقى الملفات المحلية محفوظة. يجب إدخال الرمز الجديد على الأجهزة الأخرى. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cloudNewCode => 'رمز جديد';

  @override
  String get cloudConfirmCode => 'تأكيد الرمز';

  @override
  String get cloudResetCodeError =>
      'أدخل رمزًا جديدًا من 3 إلى 10 أرقام وأكد إدخاله مطابقًا.';

  @override
  String get cloudRestoreTitle => 'استعادة هذا الملف الشخصي؟';

  @override
  String cloudRestoreHelp(String name) {
    return 'سيُضاف ملف $name دون استبدال الملفات المحلية. لن تُستعاد المفضلات أو السجل أو الاشتراكات أو التفضيلات.';
  }

  @override
  String cloudDeleteTitle(String name) {
    return 'حذف $name من السحابة؟';
  }

  @override
  String get cloudDeleteHelp =>
      'سيُحذف الملف الشخصي وبياناته المتزامنة من السحابة. لن يُحذف الملف المحلي على هذا الجهاز. ستُوقف الأجهزة الأخرى مؤقتًا وعليها تحديث قائمتها.';

  @override
  String get cloudSyncFinished => 'اكتملت المزامنة';

  @override
  String get cloudSyncFinishedHelp =>
      'تمت مزامنة الملفات الشخصية المحددة وبياناتها مع السحابة.';

  @override
  String get cloudResolveTitle => 'حل التعارض؟';

  @override
  String get cloudResolveLocalHelp =>
      'بالنسبة إلى العناصر المتعارضة في هذه الفئة، سيُحتفظ بنسخة هذا الجهاز. ستُستبدل النسخة الأخرى، بما في ذلك أي حذف.';

  @override
  String get cloudResolveRemoteHelp =>
      'بالنسبة إلى العناصر المتعارضة في هذه الفئة، سيُحتفظ بنسخة السحابة. ستُستبدل النسخة الأخرى، بما في ذلك أي حذف.';

  @override
  String get cloudProfilesTitle => 'ملفاتي الشخصية على أجهزتي';

  @override
  String get cloudSignInToContinue => 'سجّل الدخول إلى حساب سحابي للمتابعة.';

  @override
  String get cloudFirebaseUnavailable => 'Firebase غير متاح على هذا الجهاز.';

  @override
  String get cloudGoogleCanceled =>
      'أُلغي تسجيل الدخول باستخدام Google أو تعذر إكماله. إذا استمرت المشكلة، تحقق من إعدادات Google لهذا التطبيق.';

  @override
  String get cloudGoogleConfiguration =>
      'إعدادات Google غير صحيحة: تحقق من عميل OAuth وتوقيع هذا التطبيق.';

  @override
  String get cloudGoogleUnavailable =>
      'تسجيل الدخول باستخدام Google غير متاح على هذا الجهاز.';

  @override
  String get cloudSignInUnavailable =>
      'خدمة تسجيل الدخول غير متاحة على هذا الجهاز.';

  @override
  String get cloudSignInRetry => 'تعذر تسجيل الدخول. حاول مجدداً.';

  @override
  String get cloudInvalidEmail => 'عنوان البريد الإلكتروني غير صالح.';

  @override
  String get cloudWeakPassword => 'كلمة المرور ضعيفة جداً.';

  @override
  String get cloudEmailInUse => 'عنوان البريد مستخدم بالفعل.';

  @override
  String get cloudInvalidCredentials =>
      'عنوان البريد أو كلمة المرور غير صحيحة.';

  @override
  String get cloudNetworkUnavailable => 'اتصال الشبكة غير متاح.';

  @override
  String get cloudTooManyAttempts => 'محاولات كثيرة جداً. حاول لاحقاً.';

  @override
  String get cloudMethodDisabled => 'طريقة تسجيل الدخول هذه غير مفعلة.';

  @override
  String get cloudGoogleAlreadyLinked => 'هذا الحساب مرتبط بالفعل بـ Google.';

  @override
  String get cloudGoogleOtherAccount =>
      'حساب Google هذا مرتبط بالفعل بحساب Firebase آخر. لم يتم دمج أي حسابات أو بيانات. لاستخدام الحساب الآخر، سجّل الخروج ثم سجّل الدخول باستخدام Google.';

  @override
  String get cloudFirebaseSignInFailed =>
      'تعذر تسجيل الدخول. حاول مجدداً أو تحقق من إعدادات Firebase.';

  @override
  String get cloudAccountIntro =>
      'سجّل الدخول للوصول إلى ملفاتك الشخصية وبياناتها على أجهزتك. بياناتك مشفرة.';

  @override
  String get cloudAccountLinkHelp =>
      'إذا كان هناك حساب مسجل الدخول بالفعل، فسيتم ربط Google به دون تغيير معرّفه. لا يتم دمج الحسابات المختلفة.';

  @override
  String get cloudAccountStateError => 'تعذر قراءة حالة الحساب.';

  @override
  String get cloudAccountChecking => 'جارٍ التحقق من الحساب…';

  @override
  String get cloudAccountNone => 'لا يوجد حساب سحابي مسجل الدخول.';

  @override
  String get cloudPairingCleanupFailed =>
      'تم ربط الحساب، لكن تعذر تنظيف الجلسة المؤقتة.';

  @override
  String get cloudPairTv => 'ربط تلفاز باستخدام رمز QR';

  @override
  String get pairSignOutFirst => 'سجّل الخروج من الحساب السحابي قبل الاقتران.';

  @override
  String get pairScannerAccountChanged =>
      'تغيّر الحساب السحابي. أغلق هذه الشاشة وابدأ مجددًا.';

  @override
  String get pairScannerAccountCheckFailed => 'تعذر التحقق من الحساب السحابي.';

  @override
  String get pairScannerCameraFailed => 'تعذر استخدام الكاميرا.';

  @override
  String get pairScannerInvalidQr => 'رمز QR هذا لا يطابق جلسة Orbit 3D.';

  @override
  String get pairScannerAssociationFailed =>
      'تعذر الربط. تحقق من الشبكة أو أنشئ رمز QR جديدًا على التلفاز.';

  @override
  String get pairScannerTitle => 'ربط تلفاز';

  @override
  String get pairScannerSent => 'أُرسل الطلب. أكّد الحساب المعروض على التلفاز.';

  @override
  String get pairScannerCameraPermission =>
      'الكاميرا غير متاحة. اسمح بالوصول إليها في الإعدادات.';

  @override
  String get pairScannerCompareCode =>
      'قارن هذا الرمز بالرمز المعروض على التلفاز:';

  @override
  String get pairScannerVerifyWarning =>
      'لا توافق إلا إذا تطابق الرمزان وكنت تتحكم في التلفاز.';

  @override
  String pairScannerSelectedProfiles(String profiles) {
    return 'سيختار التلفاز تلقائيًا: $profiles.';
  }

  @override
  String get pairScannerConfirm => 'تأكيد وربط';

  @override
  String get pairScannerRescan => 'المسح مجددًا';

  @override
  String get pairTemporaryUnavailable => 'الجلسة المؤقتة غير متاحة.';

  @override
  String get pairCleanupIncomplete =>
      'التنظيف غير مكتمل: ستنتهي الجلسة تلقائياً.';

  @override
  String get pairCleanupFailed => 'تعذر التنظيف: ستنتهي الجلسة تلقائياً.';

  @override
  String get pairUnavailable =>
      'الاقتران غير متاح. تحقق من الشبكة وإعدادات Firebase.';

  @override
  String get pairRestart => 'ابدأ الاقتران من جديد.';

  @override
  String get pairTvTitle => 'ربط هذا التلفاز';

  @override
  String get pairInstructions =>
      'على الهاتف المسجل الدخول، افتح المزامنة المشفرة وامسح رمز QR هذا. قارن الرموز المعروضة قبل التأكيد.';

  @override
  String get pairCreateQr => 'إنشاء رمز QR';

  @override
  String pairVerificationCode(String code) {
    return 'رمز التحقق: $code';
  }

  @override
  String get pairExpires => 'تنتهي صلاحية رمز QR بعد خمس دقائق.';

  @override
  String pairAccount(String account) {
    return 'الحساب المراد ربطه: $account';
  }

  @override
  String get pairConfirmAccount => 'تأكيد هذا الحساب';

  @override
  String get pairWaiting => 'في انتظار التأكيد على الهاتف…';

  @override
  String get cloudTemporaryAccount =>
      'يوجد حساب مؤقت مسجل الدخول على هذا الجهاز.';

  @override
  String cloudAccountConnected(String account) {
    return 'الحساب المسجل: $account';
  }

  @override
  String get cloudRecoverProfiles => 'العثور على ملفاتي الشخصية على أجهزتي';

  @override
  String get cloudEmail => 'البريد الإلكتروني';

  @override
  String get cloudSignIn => 'تسجيل الدخول';

  @override
  String get cloudCreateAccount => 'إنشاء حساب';

  @override
  String get cloudResetEmailSent =>
      'إذا كان الحساب موجوداً، يمكن إرسال رسالة لإعادة تعيين كلمة المرور.';

  @override
  String get cloudForgotPassword => 'نسيت كلمة المرور';

  @override
  String get cloudGoogleLinked => 'حساب Google مرتبط بالفعل';

  @override
  String get cloudSignInWithGoogle => 'تسجيل الدخول باستخدام Google';

  @override
  String get cloudLinkGoogle => 'ربط حساب Google';

  @override
  String get cloudSignOut => 'تسجيل الخروج';

  @override
  String get cloudPrepareCodeHelp =>
      'يُعدّ شخص بالغ الرمز. ثم اختر الملفات الشخصية لمشاركتها.';

  @override
  String get cloudChooseProfilesHelp =>
      'حدد الملفات التي تريدها على أجهزتك، ثم اضغط مشاركة.';

  @override
  String get cloudFirstSyncHelp =>
      'قد يستغرق التحديث الأول أكثر من 10 دقائق. أبقِ Orbit مفتوحًا حتى ينتهي.';

  @override
  String get cloudLegacyPhrase => 'العبارة السرية (التنسيق القديم)';

  @override
  String get cloudAdultCode => 'الرمز الذي يقدمه شخص بالغ';

  @override
  String get cloudSamePhraseHelp => 'أدخل العبارة نفسها على الجهازين.';

  @override
  String get cloudSameCodeHelp => 'أدخل الرمز نفسه على الجهازين.';

  @override
  String get cloudShowPhrase => 'إظهار العبارة السرية';

  @override
  String get cloudHidePhrase => 'إخفاء العبارة السرية';

  @override
  String get cloudShowCode => 'إظهار رمز السحابة';

  @override
  String get cloudHideCode => 'إخفاء رمز السحابة';

  @override
  String get cloudSeeProfiles => 'عرض ملفاتي الشخصية';

  @override
  String get cloudRefreshList => 'تحديث القائمة';

  @override
  String get cloudAdultOptions => 'خيارات للبالغين';

  @override
  String get cloudUseLegacyPhrase => 'استخدام عبارة سرية قديمة';

  @override
  String get cloudResetAction => 'حذف كل بيانات السحابة والبدء من جديد';

  @override
  String get cloudShareBeforePairing =>
      'شارك الملفات المحددة أولًا لإتاحتها على التلفاز.';

  @override
  String get cloudConfirmYourCode => 'تأكيد الرمز';

  @override
  String get cloudBackupTitle => 'حفظ هذا الملف الشخصي؟';

  @override
  String cloudConfirmProfilesHelp(String name) {
    return 'أكد رمزك للملفات الشخصية $name. احتفظ به في مكان آمن: بدونه لن تتمكن من استعادة بياناتك.';
  }

  @override
  String cloudBackupHelp(String name) {
    return 'سيُحفظ ملف $name فقط بصورة مشفرة. لا تشمل النسخة المفضلات أو السجل أو الاشتراكات أو التفضيلات. فقدان السر يجعل استعادة النسخة مستحيلة.';
  }

  @override
  String get cloudConfirmPhrase => 'تأكيد العبارة السرية';

  @override
  String get cloudConfirmCloudCode => 'تأكيد رمز السحابة';

  @override
  String get cloudShowConfirmation => 'إظهار التأكيد';

  @override
  String get cloudHideConfirmation => 'إخفاء التأكيد';

  @override
  String get cloudSecretsMismatch => 'السرّان غير متطابقين.';

  @override
  String get cloudSyncProfileTitle => 'مزامنة هذا الملف الشخصي؟';

  @override
  String get cloudSyncProfileHelp =>
      'ستُزامن بيانات الملف النشط، ومفضلات الفيديو والراديو، والسجل الحديث، والحلقات المشاهدة ومواضع التشغيل، بالإضافة إلى التفضيلات والاشتراكات، بصورة مشفرة خلال هذه الجلسة. تشمل البيانات بيانات دخول IPTV. يظل الاشتراك النشط محددًا على كل جهاز.';

  @override
  String get cloudUpdating => 'جارٍ التحديث…';

  @override
  String get cloudAdultMustChoose =>
      'يجب أن يختار شخص بالغ البيانات التي ستُحفظ.';

  @override
  String get cloudSharingEnabled => 'المشاركة مفعّلة.';

  @override
  String get cloudKeepOpen =>
      'قد يستغرق هذا أكثر من 10 دقائق. أبقِ Orbit مفتوحًا.';

  @override
  String get cloudAutoSharing => 'تُشارك التغييرات تلقائيًا.';

  @override
  String get cloudConflictHelp =>
      'هذا الجهاز والجهاز الآخر غير متطابقين. اطلب من شخص بالغ اختيار النسخة الصحيحة.';

  @override
  String get cloudKeepLocal => 'الاحتفاظ ببيانات هذا الجهاز';

  @override
  String get cloudKeepRemote => 'الاحتفاظ ببيانات الجهاز الآخر';

  @override
  String get cloudShareSettings => 'إعدادات المشاركة (للبالغين)';

  @override
  String get cloudUpdateNow => 'التحديث الآن';

  @override
  String get cloudPause => 'إيقاف مؤقت';

  @override
  String get cloudSelectProfiles => 'اختر الملفات الشخصية للمشاركة';

  @override
  String get cloudWhichProfiles => 'ما الملفات التي تريدها على أجهزتك؟';

  @override
  String get cloudLocalProfilesUnavailable => 'الملفات المحلية غير متاحة.';

  @override
  String get cloudUnselectAll => 'إلغاء تحديد الكل';

  @override
  String get cloudSelectAll => 'تحديد الكل';

  @override
  String get cloudShareSelected => 'مشاركة الملفات المحددة';

  @override
  String get cloudShareAll => 'مشاركة جميع الملفات';

  @override
  String get cloudProfilesToAdd => 'ملفات لإضافتها';

  @override
  String get cloudOtherOptions => 'خيارات أخرى (للبالغين)';

  @override
  String get cloudShareActiveOnly => 'مشاركة الملف النشط فقط';

  @override
  String get cloudLocalProfileKept => 'سيُحتفظ بالملف المحلي.';

  @override
  String get cloudRecover => 'استعادة';

  @override
  String get cloudDeleteAction => 'حذف من السحابة';

  @override
  String get cloudBackupAction => 'حفظ';

  @override
  String get cloudScopeFavorites => 'المفضلات';

  @override
  String get cloudScopeRadioFavorites => 'مفضلات الراديو';

  @override
  String get cloudScopeRecents => 'السجل الحديث';

  @override
  String get cloudScopeWatched => 'الحلقات المشاهدة';

  @override
  String get cloudScopePlayback => 'مواضع التشغيل';

  @override
  String get cloudScopePreferences => 'التفضيلات العامة';

  @override
  String get cloudScopeProfile => 'بيانات الملف الشخصي';

  @override
  String get cloudProfileFallback => 'ملف شخصي';

  @override
  String get cloudScopeSubscriptions => 'الاشتراكات';

  @override
  String get cloudScopeData => 'البيانات';

  @override
  String cloudProgressPercent(int percent) {
    return 'اكتمل: $percent٪';
  }

  @override
  String cloudProgressScope(String scope) {
    return 'حاليًا: $scope.';
  }

  @override
  String cloudProgressProfile(String scope, String profile) {
    return 'حاليًا: $scope — $profile.';
  }

  @override
  String cloudConflictProfile(String name, String id) {
    return 'الملف المتعارض: $name ($id)';
  }

  @override
  String cloudConflictData(String scope) {
    return 'البيانات: $scope';
  }

  @override
  String get cloudChangedElsewhere =>
      'تغيرت السحابة في مكان آخر. أعد التحميل قبل المحاولة مجددًا.';

  @override
  String get cloudBadPhrase =>
      'العبارة السرية غير صحيحة أو بيانات السحابة تالفة.';

  @override
  String get cloudBadCode => 'رمز السحابة غير صحيح أو بيانات السحابة تالفة.';

  @override
  String get cloudAccessFailed =>
      'تعذر الوصول إلى السحابة. تحقق من الشبكة وإعدادات Firebase.';

  @override
  String get cloudInvalidData =>
      'بيانات السحابة غير صالحة أو غير متوافقة؛ لم تُستعد أي بيانات.';

  @override
  String get cloudOperationFailed =>
      'تعذرت العملية. تحقق من الشبكة ثم حدّث السحابة.';

  @override
  String get cloudAskAdult => 'اطلب الرمز من شخص بالغ.';

  @override
  String get cloudCodeLength => 'يجب أن يتكون الرمز من 3 إلى 10 أرقام.';

  @override
  String get cloudAccountChanged => 'تغير الحساب أو السر. ابدأ من جديد.';

  @override
  String get cloudPhraseChanged => 'تغير الحساب أو العبارة. ابدأ من جديد.';

  @override
  String get cloudBackupRefreshed => 'حُفظ الملف الشخصي وحُدّث الدليل.';

  @override
  String get cloudAccessEmpty => 'تم تأكيد الوصول. لا توجد ملفات محفوظة.';

  @override
  String get cloudCodeUnverified =>
      'لم يُعثر على نسخة احتياطية؛ لا يمكن التحقق من الرمز بعد.';

  @override
  String get cloudAccessChoose =>
      'تم تأكيد الوصول. اختر الملفات الشخصية للمشاركة.';

  @override
  String get cloudBackupRefreshFailed =>
      'حُفظ الملف الشخصي، لكن تعذر تحديث الدليل.';

  @override
  String get cloudPhoneProfilesMissing =>
      'لم تعد الملفات المختارة على الهاتف متاحة. حدّث القائمة واخترها مجددًا.';

  @override
  String get cloudPhoneProfilesReceived =>
      'تم استلام الملفات من الهاتف. جارٍ بدء المشاركة…';

  @override
  String get cloudProfileRestored =>
      'استُعيد الملف الشخصي. حدده في التطبيق ثم عد إلى هنا لتفعيل مزامنته.';

  @override
  String get cloudWaitDelete => 'انتظر انتهاء المزامنة قبل الحذف.';

  @override
  String get cloudWaitReset => 'انتظر انتهاء المزامنة قبل إعادة الضبط.';

  @override
  String get cloudResetComplete =>
      'أُعيد ضبط السحابة. الرمز الجديد نشط والملفات المحلية محفوظة.';

  @override
  String get cloudWaitSelection =>
      'المزامنة قيد التنفيذ. انتظر انتهاءها قبل تغيير التحديد.';

  @override
  String get cloudProfilesChanged => 'تغيرت الملفات الشخصية. تحقق من اختيارك.';

  @override
  String get cloudRestoredProfileMissing =>
      'تعذر العثور على ملف مستعاد. حاول مجددًا.';

  @override
  String cloudRestoringProfiles(int current, int total) {
    return 'جارٍ استعادة الملفات: $current / $total.';
  }

  @override
  String get cloudCheckingProfiles => 'جارٍ التحقق من الملفات السحابية وحفظها.';

  @override
  String get cloudPartialRestore =>
      'ربما استُعيدت بعض الملفات. تحقق من القائمة قبل المحاولة مجددًا.';

  @override
  String get cloudStartingSync => 'جارٍ بدء المزامنة.';

  @override
  String get cloudProfilesBackedUp => 'تم حفظ الملفات الشخصية.';

  @override
  String get subscriptionTitle => 'الاشتراكات';

  @override
  String get subscriptionRefreshSuccess =>
      'اكتمل التحديث: تم تحديث مصدر واحد على الأقل.';

  @override
  String get subscriptionRefreshFailed => 'تعذر التحديث: لم تُستلم أي بيانات.';

  @override
  String get subscriptionConnectionHelp =>
      'تعذر الاتصال أو رُفضت بيانات الدخول. تحقق من عنوان الخادم واسم المستخدم وكلمة المرور واتصال الإنترنت.';

  @override
  String get subscriptionDuplicateHelp =>
      'تكرار محتمل: عدة اشتراكات لها الإعدادات نفسها. لم يُحذف أي منها؛ قد تختلف مفضلاتها.';

  @override
  String get subscriptionRefreshActive => 'فرض تحديث الاشتراك النشط';

  @override
  String get subscriptionActivationFailed => 'تعذر تفعيل الاشتراك.';

  @override
  String get subscriptionDeleteTitle => 'حذف الاشتراك؟';

  @override
  String subscriptionDeleteHelp(String name) {
    return 'هل تريد حذف «$name»؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get subscriptionNoActive =>
      'لا يوجد اشتراك نشط. اختر اشتراكًا أو أضف آخر.';

  @override
  String get subscriptionActivate => 'تفعيل';

  @override
  String get subscriptionNone => 'لا توجد اشتراكات';

  @override
  String get subscriptionEmptyHelp =>
      'أضف أول اشتراك Xtream Codes أو M3U للبدء.';

  @override
  String get subscriptionFilterHelp =>
      'تُضبط الفئات المراد إخفاؤها في الإعدادات > إمكانية الوصول > مرشحات الفئات.';

  @override
  String get subscriptionPossibleDuplicate => 'تكرار محتمل';

  @override
  String get subscriptionInactive => 'غير نشط';

  @override
  String get subscriptionTesting => 'جارٍ الاختبار…';

  @override
  String get subscriptionUntested => 'لم يُختبر';

  @override
  String get subscriptionTestOk => 'نجح الاختبار';

  @override
  String subscriptionTestLatency(int latency) {
    return 'نجح الاختبار • $latency مللي ثانية';
  }

  @override
  String get subscriptionTestFailed => 'فشل';

  @override
  String get subscriptionTestAction => 'اختبار';

  @override
  String get subscriptionIncomplete => 'الإعدادات غير مكتملة';

  @override
  String get connectionInvalidConfiguration =>
      'إعدادات هذا الاشتراك مفقودة أو غير صالحة.';

  @override
  String get connectionCheckServerOrPlaylist =>
      'تحقق من عنوان الخادم أو قائمة التشغيل.';

  @override
  String get connectionCheckCredentials =>
      'تحقق أيضاً من اسم المستخدم وكلمة المرور.';

  @override
  String get connectionCertificateExpired => 'انتهت صلاحية شهادة SSL';

  @override
  String get connectionSslError => 'خطأ SSL/TLS';

  @override
  String get connectionCertificateExpiredHelp =>
      'انتهت صلاحية شهادة أمان الخادم.';

  @override
  String get connectionSslHelp => 'تعذر إنشاء اتصال آمن بالخادم.';

  @override
  String get connectionCheckDateTime => 'تحقق من تاريخ جهازك ووقته.';

  @override
  String get connectionContactProvider =>
      'اتصل بمزود الخدمة إذا استمرت المشكلة.';

  @override
  String get connectionDnsFailure => 'تعذر العثور على الخادم (DNS)';

  @override
  String get connectionDnsFailureHelp =>
      'تعذر العثور على الخادم. تحقق من عنوانه واتصال الإنترنت.';

  @override
  String get connectionNetworkUnavailable => 'تعذر الوصول إلى الشبكة';

  @override
  String get connectionNetworkUnavailableHelp =>
      'تعذر الوصول إلى شبكة الخادم. تحقق من اتصال الإنترنت.';

  @override
  String get connectionServerError => 'الخادم غير متاح مؤقتًا';

  @override
  String get connectionServerUnreachable => 'تعذر الوصول إلى الخادم';

  @override
  String get connectionServerUnreachableHelp =>
      'تعذر الوصول إلى الخادم. تحقق من العنوان واتصال الإنترنت.';

  @override
  String get connectionCheckUrl => 'تحقق من كتابة العنوان بشكل صحيح.';

  @override
  String get connectionTryAnotherNetwork => 'جرّب شبكة أخرى.';

  @override
  String get connectionContactUnreachableProvider =>
      'اتصل بمزود الخدمة إذا استمر تعذر الوصول إلى الخادم.';

  @override
  String get connectionTimeout => 'انتهت مهلة الاتصال';

  @override
  String get connectionTimeoutHelp =>
      'لم يستجب الخادم في الوقت المحدد. قد يكون بطيئاً أو مثقلاً مؤقتاً.';

  @override
  String get connectionTryLater => 'حاول مرة أخرى بعد بضع دقائق.';

  @override
  String get connectionCheckInternet => 'تحقق من اتصال الإنترنت.';

  @override
  String get connectionInvalidCredentials => 'بيانات الدخول غير صالحة';

  @override
  String get connectionAccessDenied => 'تم رفض الوصول';

  @override
  String get connectionXtreamRejected =>
      'رفض الخادم اسم مستخدم Xtream أو كلمة المرور.';

  @override
  String get connectionM3uAuthorization =>
      'تتطلب قائمة M3U إذناً أو عنواناً صالحاً.';

  @override
  String get connectionCheckCredentialsCase =>
      'تحقق من اسم المستخدم وكلمة المرور مع مراعاة الأحرف الكبيرة والصغيرة.';

  @override
  String get connectionConfirmCredentials =>
      'اطلب من مزود الخدمة تأكيد بيانات الدخول.';

  @override
  String get connectionAccountUnavailable => 'الاشتراك أو الحساب غير متاح';

  @override
  String get connectionAccountUnavailableHelp =>
      'قد يكون الحساب منتهي الصلاحية أو معطلاً أو بلغ حد الاتصالات.';

  @override
  String get connectionCheckSubscription =>
      'تحقق من حالة الاشتراك لدى مزود الخدمة.';

  @override
  String get connectionCloseOtherDevices =>
      'أغلق الاتصالات على الأجهزة الأخرى ثم حاول مجدداً.';

  @override
  String get connectionForbidden => 'الوصول محظور';

  @override
  String get connectionForbiddenHelp =>
      'رفض الخادم الاتصال. قد يكون الحساب أو عنوان IP محظوراً.';

  @override
  String get connectionCheckActiveSubscription =>
      'تحقق من أن الاشتراك لا يزال نشطاً.';

  @override
  String get connectionCheckProviderAccess =>
      'اتصل بمزود الخدمة للتحقق من الوصول.';

  @override
  String get connectionNotFound => 'العنوان غير موجود (404)';

  @override
  String get connectionInvalidRequest => 'طلب غير صالح';

  @override
  String get connectionInvalidAddress =>
      'يبدو أن عنوان الخادم أو نقطة الوصول غير صحيح.';

  @override
  String get connectionCheckBaseUrl =>
      'تحقق من عنوان الخادم الأساسي أو عنوان M3U.';

  @override
  String get connectionUseXtreamPanel =>
      'استخدم عنوان لوحة Xtream دون إضافة player_api.php.';

  @override
  String connectionServerUnavailable(int status) {
    return 'الخادم غير متاح مؤقتاً ($status)';
  }

  @override
  String get connectionServerProblem => 'يواجه خادم مزود الخدمة مشكلة.';

  @override
  String get connectionInvalidPlaylist => 'قائمة M3U غير صالحة أو فارغة';

  @override
  String get connectionInvalidPlaylistHelp =>
      'لا تحتوي القائمة على بيانات قابلة للقراءة بالتنسيق المتوقع.';

  @override
  String get connectionCheckPlaylistUrl =>
      'تحقق من أن العنوان يشير إلى قائمة M3U محدثة.';

  @override
  String get connectionRequestNewUrl => 'اطلب عنواناً جديداً من مزود الخدمة.';

  @override
  String get connectionTestFailed => 'فشل اختبار الاتصال';

  @override
  String get connectionUnexpectedError =>
      'منع خطأ غير متوقع الاتصال بهذا الاشتراك.';

  @override
  String get connectionCheckSubscriptionAndInternet =>
      'تحقق من بيانات الاشتراك واتصال الإنترنت.';

  @override
  String get connectionRetryOrContact =>
      'حاول مجدداً أو اتصل بمزود الخدمة إذا استمرت المشكلة.';

  @override
  String get connectionThingsToCheck => 'ما يجب التحقق منه';

  @override
  String get connectionTechnicalDetails => 'التفاصيل التقنية';

  @override
  String subscriptionSemantic(String name) {
    return 'الاشتراك $name';
  }

  @override
  String get subscriptionSemanticActive => 'نشط';

  @override
  String get subscriptionSemanticDuplicate => 'تكرار محتمل';

  @override
  String get subscriptionAdded => 'تمت إضافة الاشتراك';

  @override
  String subscriptionAddedHelp(String name) {
    return 'تم حفظ «$name». يمكنك اختبار الاتصال ثم تفعيل الاشتراك.';
  }

  @override
  String get subscriptionTestRunning => 'جارٍ اختبار الاتصال…';

  @override
  String get subscriptionTestSuccess => 'نجح اختبار الاتصال.';

  @override
  String get subscriptionTestUnavailable => 'نتيجة الاختبار غير متاحة.';

  @override
  String get subscriptionTestError => 'تعذر إكمال اختبار الاتصال.';

  @override
  String get subscriptionEditTitle => 'تعديل الاشتراك';

  @override
  String get subscriptionNewTitle => 'اشتراك جديد';

  @override
  String get subscriptionName => 'اسم الاشتراك';

  @override
  String get subscriptionUsername => 'اسم المستخدم';

  @override
  String get subscriptionPassword => 'كلمة المرور';

  @override
  String get subscriptionShowPassword => 'إظهار كلمة المرور';

  @override
  String get subscriptionHidePassword => 'إخفاء كلمة المرور';

  @override
  String get subscriptionAdd => 'إضافة';

  @override
  String get playerExternalOpened => 'فُتحت المشاهدة في مشغّل خارجي';

  @override
  String get playerExternalTrackHelp =>
      'اختر المسارات الصوتية والترجمات في المشغّل الخارجي؛ لا تُنقل إليه تفضيلات Orbit.';

  @override
  String get playerProviderBlocked => 'حظر المزوّد البث مؤقتًا';

  @override
  String get playerStreamNotStarting =>
      'يتم استقبال البث لكن التشغيل لا يبدأ. قد يكون المسار متطلباً أكثر مما يتحمله هذا الجهاز.';

  @override
  String get playerStreamFrozen => 'يتم استقبال البث لكن التشغيل متجمد.';

  @override
  String get playerStreamRecovering => 'توقف تقدم البث. جارٍ محاولة الاستعادة…';

  @override
  String playerCooldown(int seconds) {
    return 'الخادم محمي (anti-leech)، إعادة المحاولة خلال $seconds ثانية';
  }

  @override
  String get playerProviderBlockedHelp =>
      'أوقفت حماية الخادم من الاستهلاك غير المصرح به التشغيل. انتظر من 3 إلى 5 دقائق دون تشغيل، ثم أعد تشغيل هذه القناة دون تغييرها.';

  @override
  String get playerLiveUnavailable => 'البث غير متاح';

  @override
  String get playerLiveUnavailableHelp =>
      'تعذّر تشغيل هذه القناة. تحقّق من اشتراكك أو حاول مجددًا.';

  @override
  String playerNextEpisode(String title) {
    return 'الحلقة التالية: $title';
  }

  @override
  String playerNextEpisodeCountdown(String title, int seconds) {
    return 'الحلقة التالية: $title ($seconds ث)';
  }

  @override
  String get profileSelectToContinue => 'اختر ملفًا شخصيًا للمتابعة';

  @override
  String get profileCreateToWatch => 'أنشئ ملفك الشخصي الأول لبدء المشاهدة.';

  @override
  String get profileNavigationHelp =>
      'الأسهم + موافق للتنقل · المس بطاقة للاختيار';

  @override
  String get profileActive => 'نشط';

  @override
  String get resumeAction => 'استئناف';

  @override
  String get refreshRecommendations => 'تحديث التوصيات';

  @override
  String get localVideoProxy => 'وكيل فيديو محلي تجريبي';

  @override
  String get localVideoProxySubtitle =>
      'للأفلام والمسلسلات في المشغل الداخلي، مع تخزين مؤقت محدود على القرص.';

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
  String get accountPreferencesSubtitle => 'اللغة، رمز PIN';

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
  String get deleteDownload => 'حذف';

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
    return 'آخر مزامنة (هذا التثبيت): $time';
  }

  @override
  String get cloudSyncNow => 'زامن الآن';

  @override
  String get cloudSyncNowSubtitle =>
      'مزامنة المفضلات والسجل وتقدّم المشاهدة لهذا التثبيت';

  @override
  String get cloudSyncSubtitleOff =>
      'مزامنة المفضلات والحلقات المشاهدة والأخيرة وتقدّم المشاهدة لهذا التثبيت';

  @override
  String get cloudflareReset => 'إعادة ضبط جلسة Cloudflare';

  @override
  String get cloudflareResetSubtitle => 'تجديد جلسة Cloudflare النشطة.';

  @override
  String get cloudflareNoActiveSession =>
      'لا توجد جلسة Cloudflare نشطة لتجديدها.';

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
  String currentProfileLabel(String name) {
    return 'الملف الشخصي الحالي: $name';
  }

  @override
  String get dataAlreadyFresh => 'البيانات محدثة (أقل من 8 ساعات)';

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
  String downloadAdded(String title) {
    return 'أُضيف «$title» إلى التنزيلات';
  }

  @override
  String get downloadCompleted => 'تم التنزيل';

  @override
  String get downloadInProgress => 'التنزيل جارٍ';

  @override
  String get downloadOffline => 'تنزيل للاستخدام دون اتصال';

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
  String get languageExample => 'Français، English، إلخ.';

  @override
  String get noneOption => 'لا شيء';

  @override
  String get play => 'تشغيل';

  @override
  String get newAnd4K => 'أفلام عند الطلب';

  @override
  String get seasonsAndEpisodes => 'مسلسلات عند الطلب';

  @override
  String get languagePreference => 'لغة التطبيق';

  @override
  String get languageUndetermined => 'غير محدد';

  @override
  String get later => 'لاحقاً';

  @override
  String get legalNotice => 'الإشعار القانوني / التواصل';

  @override
  String get contactTeamTitle => 'تواصل مع الفريق';

  @override
  String get contactTeamIntro =>
      'نرحب بتجاربكم وأفكاركم للتحسين وبلاغات الأخطاء للمساعدة في تطوير التطبيق.';

  @override
  String get contactAddress => 'عنوان التواصل:';

  @override
  String get contactImportant => 'مهم:';

  @override
  String get contactTeamWarning =>
      'لن يتم الرد على الرسائل التي تطلب تمديد الفترة التجريبية أو شهرًا مجانيًا.';

  @override
  String get contactCompose => 'كتابة بريد إلكتروني';

  @override
  String get contactMailUnavailable => 'لا يتوفر تطبيق للبريد الإلكتروني.';

  @override
  String get contactLegal => 'الإشعار القانوني';

  @override
  String get legalNoticeSubtitle => 'استخدام التطبيق، أصحاب الحقوق والخصوصية';

  @override
  String get liveChannelsAndZapping => 'القنوات المباشرة والتبديل';

  @override
  String get liveTv => 'البث التلفزيوني المباشر';

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
  String get moreResults => 'عرض المزيد من النتائج';

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
  String get noGroupAffinity => 'لم يتم العثور على تقارب مشترك';

  @override
  String get noHistory => 'لا يوجد سجل';

  @override
  String get historyLoading => 'جارٍ تحميل السجل…';

  @override
  String get historyEmptyHint => 'ستظهر مشاهداتك الأخيرة هنا.';

  @override
  String get refreshAction => 'تحديث';

  @override
  String get favoritesAdd => 'إضافة إلى المفضلة';

  @override
  String get recentRemove => 'إزالة من المشاهدة';

  @override
  String get favoritesRemove => 'إزالة من المفضلة';

  @override
  String get favoritesNeedScope => 'يلزم وجود ملف شخصي واشتراك نشطين.';

  @override
  String get favoritesReplayHint => 'اضغط على قلب الإعادة للعثور عليها هنا.';

  @override
  String favoritesClearPrompt(int total) {
    return 'إزالة العناصر المفضلة المحفوظة وعددها $total؟ ستُفرغ قائمة المفضلة.';
  }

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
  String get noRecommendations => 'لا توجد توصيات متاحة';

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
  String get pinRequired => 'رمز PIN مطلوب';

  @override
  String get pinSet => 'تعيين رمز PIN';

  @override
  String get pinThisProfile => 'هذا الملف الشخصي';

  @override
  String pinEnterForProfile(String name) {
    return 'أدخل رمز PIN لـ $name';
  }

  @override
  String get pinConfirmFourDigits => 'أكد الرمز المكون من 4 أرقام';

  @override
  String get pinChooseFourDigits => 'اختر رمزاً مكوناً من 4 أرقام';

  @override
  String get pinVerifyFailed => 'تعذر التحقق من رمز PIN.';

  @override
  String get pinConfirmInstruction => 'بعد إدخال 4 أرقام، اضغط ✓ للتأكيد.';

  @override
  String pinIncorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'المحاولات المتبقية: $count',
      two: 'تبقت محاولتان',
      one: 'تبقت محاولة واحدة',
    );
    return 'الرمز غير صحيح — $_temp0. بعد 3 أخطاء يُقفل الوصول لمدة ساعتين.';
  }

  @override
  String pinTemporarilyLocked(int minutes) {
    return 'عدد رموز PIN غير الصحيحة كبير. حاول مجددًا بعد $minutes دقيقة.';
  }

  @override
  String get pinChecking => 'جارٍ التحقق…';

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
  String profilesSelected(int count) {
    return 'تم تحديد $count ملفات تعريف';
  }

  @override
  String get profileVisible => 'ملف شخصي مرئي';

  @override
  String get programGrid => 'جدول البرامج';

  @override
  String get protectWithPin => 'الحماية برمز PIN';

  @override
  String get rankingsUnavailable => 'الترتيب غير متاح';

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
      'سيتم مسح سجل المشاهدة والبحث المحلي. ستبقى الملفات الشخصية والاشتراكات وبيانات API وإعدادات TLS والبث وCloudflare والإعدادات الأخرى محفوظة. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get resetAppDialogConfirm => 'إعادة الضبط';

  @override
  String get resetAppDialogTitle => 'إعادة ضبط التطبيق؟';

  @override
  String get resetAppSubtitle =>
      'يمسح السجل المحلي مع الاحتفاظ بالملفات الشخصية والإعدادات';

  @override
  String get resetFailed => 'لم تكتمل إعادة الضبط. حاول مجددًا.';

  @override
  String get resetCompleted => 'تمت إعادة التعيين';

  @override
  String get resumePlayback => 'هل تريد استئناف التشغيل؟';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get tmdbMovieRecommendations => 'توصيات TMDB';

  @override
  String get tmdbRecommendationsEmpty => 'لا توجد توصيات TMDB لهذا الفيلم.';

  @override
  String get tmdbRecommendationsError => 'تعذر تحميل توصيات TMDB.';

  @override
  String get tmdbRecommendationsUnavailable =>
      'توصيات TMDB غير متاحة لهذا الفيلم.';

  @override
  String get playbackDelayedTitle => 'يستغرق بدء التشغيل وقتًا طويلًا';

  @override
  String get playbackDelayedMessage =>
      'لم يبدأ التشغيل أو يستأنف بعد. قد يكون السبب البث أو الاتصال أو تنسيق الفيديو.';

  @override
  String get playbackContinueWaiting => 'متابعة الانتظار';

  @override
  String get playbackUnavailableTitle => 'التشغيل غير متاح';

  @override
  String get playbackUnavailableMessage =>
      'لا يمكن تشغيل هذا الفيلم أو هذه الحلقة حاليًا. أعد المحاولة أو تحقق من الاتصال وتنسيق الملف.';

  @override
  String get protectedPlaybackUnsupportedMessage =>
      'لا يستطيع المشغّل المدمج تشغيل بث DASH أو البث المُرحّل ذي الترويسات المحمية بأمان.';

  @override
  String get greenScreenDetectedTitle => 'تم اكتشاف مشكلة في عرض الفيديو';

  @override
  String get externalPlayerLimitationsTitle => 'قيود المشغلات الخارجية';

  @override
  String get externalPlayerLimitationsDescription =>
      'لا ينقل Orbit تفضيلات الصوت والترجمة إلى VLC أو MX Player؛ اختر المسارات في المشغل الخارجي. في المسلسلات، تبدأ الحلقة التالية تلقائيًا فقط إذا أكد MX Player انتهاء التشغيل؛ وإلا فابدأها يدويًا بعد العودة إلى Orbit. ينطبق هذا أيضًا على المشغل الاحتياطي.';

  @override
  String get actorShowFilmography => 'عرض الأعمال';

  @override
  String get actorFilmographyUnavailable => 'قائمة الأعمال غير متاحة.';

  @override
  String get actorCreditFilm => 'فيلم';

  @override
  String get actorCreditSeries => 'مسلسل';

  @override
  String actorCreditRole(String role) {
    return 'الدور: $role';
  }

  @override
  String get actorCreditTmdbUnavailable => 'تفاصيل TMDB غير متاحة.';

  @override
  String get actorCreditSynopsisUnavailable => 'الملخص غير متاح.';

  @override
  String get actorCreditCatalogUnconfirmed => 'لا يوجد تطابق مؤكد في الكتالوج.';

  @override
  String get actorCreditOpenCatalog => 'عرض في الكتالوج';

  @override
  String get greenScreenDetectedMessage =>
      'تم اكتشاف مشكلة في الصورة (شاشة خضراء). قد لا يتمكن المشغل الحالي من فك ترميز هذا البث بشكل صحيح. جرّب مشغلًا آخر من الإعدادات > المشغل > محركات التشغيل، ثم أعد تشغيل الفيديو.';

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
  String selectAtLeastOneProfile(int count) {
    return 'اختر ملفًا شخصيًا إضافيًا واحدًا على الأقل ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'اختر ملفاً شخصياً لعرض توصياته';

  @override
  String get series => 'المسلسلات';

  @override
  String get seriesNotFound => 'السلسل غير موجودة';

  @override
  String get seriesMissingId =>
      'معرّف المسلسل مفقود (تنقل غير صحيح). عد إلى القائمة وحاول مجددًا.';

  @override
  String get seriesEnriching => 'جارٍ إثراء البيانات الوصفية…';

  @override
  String get seriesLoading => 'جارٍ تحميل المسلسل…';

  @override
  String get seriesNoEpisodesHint => 'لا توجد حلقات لهذا المسلسل بعد.';

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
  String get snackCloudflareReset => 'تم تجديد جلسة Cloudflare';

  @override
  String snackImportError(String message) {
    return 'خطأ: $message';
  }

  @override
  String get snackImportSuccess => 'تم استيراد الإعدادات بنجاح';

  @override
  String get snackNoBackup => 'لم يتم العثور على نسخة احتياطية';

  @override
  String get sortAffinity => 'حسب التقارب';

  @override
  String get sortAffinityDescription =>
      'يرتب وفق أذواقك المعلنة في الملف الشخصي (مطابقة)';

  @override
  String get sortAscending => 'ترتيب تصاعدي';

  @override
  String get sortByDuration => 'حسب المدة';

  @override
  String get sortByRating => 'حسب التقييم';

  @override
  String get sortByYear => 'حسب السنة';

  @override
  String get sortDescending => 'ترتيب تنازلي';

  @override
  String get sortLatestM3UXtream => 'آخر الإضافات M3U/Xtream';

  @override
  String get sortNameAToZ => 'الاسم (أ → ي)';

  @override
  String get sortNameZToA => 'الاسم (ي → أ)';

  @override
  String get sortResumePriority => 'المتابعة أولاً';

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
  String get tmdbKeyValid => 'مفتاح TMDB صالح';

  @override
  String get tmdbKeyValidationFailed =>
      'رفض TMDB المفتاح أو الشبكة غير متاحة: تحقق من المفتاح';

  @override
  String get tvChannels => 'قنوات TV';

  @override
  String get unableToBuildReplayUrl => 'تعذر بناء رابط إعادة المشاهدة.';

  @override
  String get unlockCloudflare => 'فتح القفل (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'يلزم التحقق من مزود الخدمة';

  @override
  String get cloudflareChallengeHelp =>
      'يطلب مزود الخدمة إجراء تحقق من Cloudflare. أكمل التحقق في هذه النافذة، ثم أغلقها وأعد المحاولة. لا تُرسل ملفات تعريف الارتباط لهذه الصفحة إلى المشغل، لذا قد يستمر حظر التشغيل.';

  @override
  String get openProviderWebsite => 'فتح موقع مزود الخدمة';

  @override
  String get providerWebsiteUnavailable =>
      'تعذر فتح موقع مزود الخدمة. تحقق من عنوان الاشتراك ثم أعد المحاولة.';

  @override
  String get unstableConnection => 'اتصال غير مستقر';

  @override
  String get updateAllData => 'تحديث جميع البيانات';

  @override
  String get aiTopicsTitle => 'موضوعات مقترحة بالذكاء الاصطناعي';

  @override
  String get updateThisCategory => 'تحديث هذه الفئة';

  @override
  String get updating => 'جارٍ التحديث…';

  @override
  String get updatingMediaContent => 'جارٍ تحديث المحتوى متعدد الوسائط…';

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

  @override
  String get subtitleSection => 'الترجمة';

  @override
  String get seriesDefaultAudioLanguage => 'لغة الصوت الافتراضية';

  @override
  String get seriesDefaultSubtitleLanguage => 'لغة الترجمة الافتراضية';

  @override
  String get seriesSelectLanguage => 'اختر لغة';

  @override
  String get seriesStreamDefault => '(اللغة الافتراضية للبث)';

  @override
  String get seriesChooseLanguageFirst => 'اختر لغة أولاً';

  @override
  String get seriesDefaultAllEpisodes =>
      'استخدم اللغة الافتراضية للبث لكل الحلقات';

  @override
  String get seriesDefaultUnlessEpisodeChoice =>
      'استخدم اللغة الافتراضية للبث ما لم تُختر لغة للحلقة';

  @override
  String get seriesForceLanguageAllEpisodes => 'فرض هذه اللغة لكل الحلقات';

  @override
  String get seriesApplyIfAvailable => 'تطبيقها إن توفرت';

  @override
  String get seriesSearchingAudio => 'جارٍ البحث عن المسارات الصوتية…';

  @override
  String get seriesSubtitlesDisabled => '(معطلة)';

  @override
  String get seriesDisableSubtitlesAll => 'تعطيل الترجمة لكل الحلقات';

  @override
  String get seriesDisableSubtitlesDefault => 'تعطيل الترجمة افتراضياً';

  @override
  String get seriesSearchingSubtitles => 'جارٍ البحث عن مسارات الترجمة…';

  @override
  String get seriesNoSubtitleTracks =>
      'لم يُعثر على مسارات: اختر لغة وستُستخدم إن توفرت.';

  @override
  String get seriesLanguageFrench => 'الفرنسية';

  @override
  String get seriesLanguageEnglish => 'الإنجليزية';

  @override
  String get seriesLanguageSpanish => 'الإسبانية';

  @override
  String get seriesLanguageGerman => 'الألمانية';

  @override
  String get seriesLanguageItalian => 'الإيطالية';

  @override
  String get seriesLanguageArabic => 'العربية';

  @override
  String get subtitleEmbeddedSection => 'الترجمات المضمنة';

  @override
  String get subtitleForcedLabel => 'إجباري';

  @override
  String get subtitleEmbeddedLabel => 'مضمن';

  @override
  String get audioSection => 'الصوت';

  @override
  String get videoSection => 'الفيديو';

  @override
  String get autoQuality => 'تلقائي';

  @override
  String get subtitleNotApplicable => 'لا ينطبق';

  @override
  String get subtitleNotApplicableInfo => 'البث المباشر لا يوفر مسار ترجمة.';

  @override
  String get subtitleUnavailable => 'غير متاح';

  @override
  String get subtitleNoTrack => 'لا يوجد مسار';

  @override
  String get subtitleNoTrackInfo => 'لا يوفّر المزوّد ترجمات لهذا المحتوى.';

  @override
  String get subtitleGuessed => 'مسارات مُستنتجة';

  @override
  String get subtitleGuessedInfo =>
      'لا يعلن المزوّد ترجماته: تُشتق هذه المسارات من اصطلاح عنوان URL. وأي مسار غير موجود سيُبلّغ عن خطأ عند التفعيل.';

  @override
  String get subtitleUnavailableToast => 'الترجمة غير متاحة';

  @override
  String get audioTrackFallback => 'مسار صوتي';

  @override
  String get subtitleLoading => 'جارٍ تحميل الترجمة…';

  @override
  String get videoQualityFallback => 'جودة الفيديو';

  @override
  String get close => 'إغلاق';

  @override
  String get streamTracksError => 'تعذّرت قراءة مسارات هذا البث.';

  @override
  String get subtitleProviderNoAnswer => 'لم يستجب المزوّد.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'الترجمة غير متاحة: $reason';
  }

  @override
  String get epgNoDataTitle => 'لا توجد بيانات برامج';

  @override
  String get epgLiveNow => 'مباشر';

  @override
  String get epgSelectChannelHint => 'اختر قناة لعرض برنامجها';

  @override
  String get epgNow => 'الآن';

  @override
  String get epgZoomIn => 'تكبير';

  @override
  String get epgZoomOut => 'تصغير';

  @override
  String get epgNoCurrentProgram => 'لا يوجد برنامج جارٍ';

  @override
  String replayWindowBadge(Object days) {
    return 'إعادة $days يوم';
  }

  @override
  String replayWindowBadgeHours(Object hours) {
    return 'إعادة $hours ساعة';
  }

  @override
  String get replayNoAvailable => 'لا توجد إعادة متاحة';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'لا يوجد برنامج عُرض سابقًا ضمن أرشيف $days يومًا لهذا الحساب في هذه القناة.';
  }

  @override
  String get replayNonePublished =>
      'لا ينشر المزوّد أي برنامج عُرض سابقًا لهذه القناة.';

  @override
  String get epgActionFavorite => 'مفضّل';

  @override
  String get epgActionRecording => 'تسجيل';

  @override
  String get epgActionReminder => 'تذكير';

  @override
  String get epgStartReplay => 'بدء الإعادة';

  @override
  String get epgBack => 'رجوع';

  @override
  String epgWatchChannel(Object name) {
    return 'شاهد $name';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'لا يوفّر المزوّد ترجمات لهذا المحتوى.';

  @override
  String subtitleVerifying(Object count) {
    return 'جارٍ التحقق من الترجمة… ($count)';
  }

  @override
  String get favorites => 'المفضلة';

  @override
  String get films => 'أفلام';

  @override
  String get replay => 'إعادة';

  @override
  String get myContent => 'محتواي';

  @override
  String get contentTypeSelector => 'نوع المحتوى';

  @override
  String get downloadStatusDownloading => 'جارٍ التنزيل';

  @override
  String get downloadStatusPreparing => 'جارٍ التحضير';

  @override
  String get downloadStatusPaused => 'متوقف مؤقتًا';

  @override
  String get downloadStatusCompleted => 'مكتمل';

  @override
  String get downloadStatusFailed => 'فشل';

  @override
  String get downloadStatusCancelled => 'أُلغي';

  @override
  String get downloadStatusQueued => 'في الانتظار';

  @override
  String get history => 'السجل';

  @override
  String get explore => 'استكشاف';

  @override
  String get downloadsEmptyHint => 'أضف محتوى من صفحة تفاصيل فيلم أو مسلسل.';

  @override
  String get downloadsLocation => 'الملفات';

  @override
  String get advancedSettingsTitle => 'إعدادات متقدمة';

  @override
  String get freeMode => 'الوضع المجاني';

  @override
  String get freeModePending =>
      'سيتم ضبط هذا الخيار لاحقًا، وليس له تأثير حاليًا.';

  @override
  String get advancedSettingsIntro =>
      'بيانات API وإعدادات الشبكة. هذه الإعدادات تربط حسابك بخدمات خارجية: مفتاح مشترك يستهلك حصته، وإعداد شبكة خاطئ قد يمنع التطبيق من البدء.';

  @override
  String get advancedStatus => 'حالة بيانات الاعتماد';

  @override
  String get advancedAccessTitle => 'وصول محجوز';

  @override
  String get advancedAccessHint => 'الرمز';

  @override
  String get advancedAccessConfirm => 'فتح';

  @override
  String get advancedAccessWrong => 'رمز غير صحيح';

  @override
  String get advancedHiddenHint => 'اضغط مطولاً للإعدادات المتقدمة';

  @override
  String get favoritesAndDownloads => 'المفضلة والتنزيلات';

  @override
  String get activeAudio => 'الصوت يعمل على هذه الشاشة';

  @override
  String get addChannel => 'إضافة قناة';

  @override
  String get noChannelSelected => 'لم يتم تحديد أي قناة';

  @override
  String get removeChannel => 'إزالة القناة';

  @override
  String get avatarCategoryAll => 'جميع';

  @override
  String get avatarCategoryCharacters => 'شخصيات';

  @override
  String get avatarCategorySuperheroes => 'أبطال خارقون';

  @override
  String get avatarCategoryAnimals => 'حيوانات';

  @override
  String get avatarCategoryFlowers => 'زهور';

  @override
  String get avatarCategoryNature => 'الطبيعة';

  @override
  String get avatarCategoryYouth => 'الناشئة';

  @override
  String get avatarCategorySmileys => 'الوجوه التعبيرية';

  @override
  String get avatarCategoryBlackWhite => 'أبيض وأسود';

  @override
  String get updateTitle => 'التحديثات';

  @override
  String get updateSettingsSubtitle => 'التحقق من أحدث إصدار رسمي على GitHub';

  @override
  String get updateChecking => 'جارٍ البحث عن تحديثات…';

  @override
  String get updateCurrent => 'أحدث إصدار متاح مثبت بالفعل.';

  @override
  String get updateAvailable => 'يتوفر إصدار جديد:';

  @override
  String get updateDownloading => 'جارٍ تنزيل ملف APK والتحقق منه…';

  @override
  String get updateReady => 'جارٍ فتح مثبت Android…';

  @override
  String get updatePermission =>
      'اسمح لـ Orbit بتثبيت التطبيقات غير المعروفة في إعدادات Android، ثم عد إلى هنا وأعد المحاولة.';

  @override
  String get updateNoRelease => 'لا يوجد إصدار مستقر متاح على GitHub.';

  @override
  String get updateAssetError =>
      'الإصدار لا يحتوي على ملف APK الرسمي الشامل أو معلومات التحقق منه.';

  @override
  String get updateInvalidApk =>
      'ملف APK غير متوافق أو موقّع بمفتاح آخر أو ليس بإصدار Android أحدث. أُلغي التثبيت.';

  @override
  String get updateIntegrityError =>
      'فشل التحقق من الملف الذي تم تنزيله. أُلغي التثبيت.';

  @override
  String get updateGenericError =>
      'فشل التحديث. تحقق من الاتصال وأعد المحاولة.';

  @override
  String get updateLater => 'لاحقاً';

  @override
  String get updateInstall => 'تحديث';

  @override
  String get updateRetryInstall => 'إعادة محاولة التثبيت';

  @override
  String get updateRetry => 'إعادة المحاولة';

  @override
  String get avatarCategoryPixels => 'بكسلات';

  @override
  String get unassignedLegacyLibraryItems =>
      'بعض المفضلات أو التنزيلات القديمة مخفية لأن اشتراكها الأصلي غير معروف. لا تزال محفوظة.';

  @override
  String get forceNoSubtitlesSubtitle =>
      'تعطيل الترجمة تلقائيًا عند بدء فيلم أو مسلسل';

  @override
  String get backTooltip => 'رجوع';

  @override
  String get categoryFilters => 'مرشحات الفئات';

  @override
  String get categoryFiltersSubtitle => 'فئات مخفية حسب الاشتراك';

  @override
  String get memoryCacheTitle => 'إدارة الذاكرة والكاش';

  @override
  String get memoryCacheSubtitle => 'حرّر المساحة ونظّف البيانات المحلية.';

  @override
  String get clearWatchHistoryTitle => 'مسح سجل المشاهدة';

  @override
  String get clearWatchHistorySubtitle =>
      'يمسح قائمة المشاهدات الأخيرة ومواضع استئناف التشغيل.';

  @override
  String get clearWatchHistoryAction => 'مسح';

  @override
  String get clearCoverCacheTitle => 'مسح ذاكرة أغلفة الصور المؤقتة';

  @override
  String get clearCoverCacheSubtitle =>
      'يحرّر مساحة القرص التي تشغلها مصغّرات VOD/EPG المخزنة محليًا.';

  @override
  String get clearCoverCacheAction => 'تفريغ';

  @override
  String get enginesDescription =>
      'اختر المحرك المستخدم لكل نوع من المحتوى، ومحرك الاحتياط في حال فشل التشغيل.';

  @override
  String get sortAdvancedTitle => 'خيارات فرز متقدمة';

  @override
  String get sortAdvancedSubtitle => 'اختر وضعًا باستخدام جهاز التحكم:';

  @override
  String get sortDescRecentlyAdded => 'محتويات أُضيفت مؤخرًا إلى القائمة';

  @override
  String get sortDescResumePriority =>
      'يضع في الأعلى المحتويات المبدأة غير المنتهية';

  @override
  String get sortDescByRating => 'ترتيب حسب التقييمات الممنوحة';

  @override
  String get sortDescByYear => 'ترتيب زمني حسب سنة الإنتاج';

  @override
  String get sortDescByDuration => 'فرز حسب مدة المحتوى';

  @override
  String get sortOptionActive => 'مفعّل';

  @override
  String get showAll => 'إظهار الكل';

  @override
  String get noActiveSubscription => 'لا يوجد اشتراك نشط';

  @override
  String get noVodCategories => 'لا توجد فئات أفلام على هذه اللوحة.';

  @override
  String get noSeriesCategories => 'لا توجد فئات مسلسلات على هذه اللوحة.';

  @override
  String get neverScanned => 'لم يُحلَّل من قبل';

  @override
  String get scannedToday => 'حُلِّل اليوم';

  @override
  String get scannedYesterday => 'حُلِّل أمس';

  @override
  String scannedDaysAgo(int days) {
    return 'حُلِّل قبل $days يومًا';
  }

  @override
  String subscriptionSettingsNote(String scanned) {
    return 'إعدادات خاصة بهذا الاشتراك — $scanned';
  }

  @override
  String get rescanCategories => 'إعادة تحليل الفئات';

  @override
  String get scanningCategories => 'جارٍ التحليل…';
}
