// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أوربت IPTV';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get tabAccount => 'الحساب';

  @override
  String get tabNetwork => 'الشبكة';

  @override
  String get tabPlayer => 'المشغّل';

  @override
  String get tabSecurity => 'الأمان';

  @override
  String get tabAudio => 'الصوت';

  @override
  String get tabAdvanced => 'متقدم';

  @override
  String get sectionAccountProfile => 'الحساب والملف الشخصي';

  @override
  String get accountProfiles => 'ملفات المستخدمين';

  @override
  String get accountProfilesSubtitle => 'إدارة الملفات والملف النشط';

  @override
  String get accountSubscriptions => 'اشتراكات Xtream/M3U';

  @override
  String get accountNoSubscription => 'لا يوجد اشتراك نشط';

  @override
  String get accountPreferences => 'تفضيلات الملف الشخصي';

  @override
  String get accountPreferencesSubtitle => 'اللغة، المظهر، قيود العمر، رمز PIN';

  @override
  String get accountDeviceProfile => 'ملف الجهاز والتشخيص';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'الملف $label · تشخيص المشغّل';
  }

  @override
  String get sectionCloudSync => 'المزامنة السحابية (عدة أجهزة)';

  @override
  String get cloudSyncEnabled => 'المزامنة مفعّلة';

  @override
  String cloudSyncLastSync(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get cloudSyncSubtitleOff =>
      'مزامنة المفضلات والمُشاهَد والحديث نحو السحابة';

  @override
  String get cloudSyncNow => 'زامن الآن';

  @override
  String get cloudSyncNowSubtitle => 'إرسال التغييرات المحلية إلى السحابة';

  @override
  String get never => 'أبدًا';

  @override
  String get sectionNotifications => 'الإشعارات';

  @override
  String get testNotifications => 'اختبار الإشعارات';

  @override
  String get testNotificationsSubtitle => 'إرسال إشعار محلي تجريبي';

  @override
  String get sectionBackup => 'النسخ الاحتياطي / الاستعادة';

  @override
  String get backupExport => 'تصدير الإعدادات';

  @override
  String get backupExportSubtitle => 'نسخ الإعدادات كاملة إلى الحافظة';

  @override
  String get backupImport => 'استيراد الإعدادات';

  @override
  String get backupImportSubtitle => 'الاستعادة من الحافظة (JSON)';

  @override
  String get snackBackupExported => 'تم تصدير الإعدادات إلى الحافظة';

  @override
  String get snackNoBackup => 'لم يتم العثور على نسخة احتياطية';

  @override
  String get snackImportSuccess => 'تم استيراد الإعدادات بنجاح';

  @override
  String snackImportError(String message) {
    return 'خطأ: $message';
  }

  @override
  String get sectionAntiThrottle => 'حماية من تخفيف سرعة مزود الإنترنت';

  @override
  String get tlsImpersonation => 'انتحال TLS (خادم وسيط محلي)';

  @override
  String get tlsImpersonationSubtitle =>
      'يحاكي بصمة متصفح حديث لتجاوز Cloudflare';

  @override
  String get dnsProvider => 'مزود DNS (DoH)';

  @override
  String get dnsProviderSubtitle => 'الخادم المستخدم لاستعلامات DNS عبر HTTPS';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'تلقائي (النظام)';

  @override
  String get sectionCloudflare => 'تحسين Cloudflare';

  @override
  String get cloudflareReset => 'إعادة ضبط إعدادات Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'مسح الكوكيز، TLS Impersonation=OFF، وكيل ExoPlayer الافتراضي';

  @override
  String get snackCloudflareReset => 'تمت إعادة ضبط إعدادات Cloudflare';

  @override
  String get sectionEngines => 'محركات التشغيل';

  @override
  String get enginesTile => 'محركات التشغيل';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'مباشر: $live · فيديو عند الطلب: $vod';
  }

  @override
  String get sectionAudioNight => 'الصوت ووضع الليل';

  @override
  String get audioAndNightFocus => 'الصوت ووضع الليل';

  @override
  String get audioAndNightFocusSubtitle =>
      'تحسين ليلي، تعزيز الحوار، مزامنة الصوت/الفيديو';

  @override
  String get sectionZapping => 'التنقل والأداء';

  @override
  String get instantZapping => 'تنقل فوري (تحميل مسبق)';

  @override
  String get instantZappingSubtitle =>
      'تحميل القنوات المجاورة مسبقًا في الذاكرة';

  @override
  String get sectionMemory => 'الذاكرة والكاش';

  @override
  String get sectionParental => 'الرقابة الأبوية';

  @override
  String get parentalControl => 'الرقابة الأبوية';

  @override
  String get parentalControlSubtitle => 'إضافة رمز PIN وتقييد المحتوى';

  @override
  String get sectionCertPinning => 'تثبيت الشهادة (SHA-256)';

  @override
  String get certPinning => 'تفعيل تثبيت الشهادة';

  @override
  String get certPinningSubtitle =>
      'يتحقق من بصمة SHA-256 لشهادة SSL الخاصة بالخادم (مضاد للـ MITM)';

  @override
  String get certPinningHint =>
      'البصمات المسموح بها (واحدة لكل سطر، سداسية عشرية بأحرف كبيرة):';

  @override
  String get certPinningAdd => 'إضافة البصمات أعلاه';

  @override
  String get sectionResilience => 'مرونة الخدمة';

  @override
  String get autoReconnectLive => 'إعادة اتصال مباشرة تلقائية';

  @override
  String get autoReconnectLiveSubtitle =>
      'محاولة إعادة الاتصال تلقائيًا إذا انقطع البث';

  @override
  String get sectionLegal => 'معلومات قانونية';

  @override
  String get legalNotice => 'اقرأني · إشعار قانوني';

  @override
  String get legalNoticeSubtitle => 'استخدام التطبيق، أصحاب الحقوق والخصوصية';

  @override
  String get nightFocusTitle => 'وضع الليل (وضع الليل)';

  @override
  String get nightFocusEnable => 'تفعيل وضع الليل';

  @override
  String get nightFocusEnableSubtitle =>
      'معالجة صوتية فورية: تعزيز الحوار، خفض الباص، المزامنة';

  @override
  String get dialogueBoost => 'تعزيز الحوار (+4 ديسيبل)';

  @override
  String get dialogueBoostSubtitle => 'يضخّم الأصوات مقارنة بالمؤثرات/الموسيقى';

  @override
  String get bassKiller => 'قاطع الباص (قطع أقل من 120 هرتز)';

  @override
  String get bassKillerSubtitle => 'يقلل الترددات المنخفضة لتجنب الاهتزازات';

  @override
  String get sectionAvSync => 'مزامنة الصوت/الفيديو';

  @override
  String get audioShift => 'إزاحة صوتية قابلة للضبط';

  @override
  String get audioShiftSubtitle => 'إزاحة صوت/فيديو يدوية (بالملي ثانية)';

  @override
  String get manualAvCalibration => 'معايرة يدوية للصوت/الفيديو';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'الإزاحة الحالية: $ms ملي ثانية';
  }

  @override
  String get sectionOutput => 'مخرج الصوت';

  @override
  String get volumeNormalization => 'معادلة الصوت';

  @override
  String get volumeNormalizationSubtitle =>
      'تحد من قمم الصوت بين القنوات/البرامج (AGC)';

  @override
  String get avSyncDialogTitle => 'معايرة الصوت/الفيديو';

  @override
  String get avSyncDialogLabel => 'الإزاحة (بالملي ثانية)';

  @override
  String get avSyncDialogHint => 'إيجابي = الصوت متقدم، سلبي = الصوت متأخر';

  @override
  String get apply => 'تطبيق';

  @override
  String get sectionAccessibility => 'إمكانية الوصول';

  @override
  String get highContrast => 'وضع التباين العالي';

  @override
  String get highContrastSubtitle => 'يحسن الوضوح لضعاف البصر';

  @override
  String get dpadNavigation => 'تنقل محسّن بلوحة الاتجاهات';

  @override
  String get dpadNavigationSubtitle =>
      'تركيز مرئي، هالة مضيئة، التفاف النص (وضع التلفاز)';

  @override
  String get fontSize => 'حجم نص أكبر';

  @override
  String get fontSizeSubtitle => 'يكبّر النصوص في التطبيق كله';

  @override
  String get sectionTmdb => 'تصنيفات TMDB';

  @override
  String get sectionRecommendations => 'التوصيات';

  @override
  String get matchmaking => 'من أجلك (المطابقة)';

  @override
  String get matchmakingSubtitle => 'إدارة المطابقة والاقتراحات المخصصة';

  @override
  String get sectionDiagnostics => 'التشخيص والصيانة';

  @override
  String get logsDiagnostic => 'السجلات والتشخيص';

  @override
  String get logsDiagnosticSubtitle => 'عرض السجلات، التصدير، مسح الكاش';

  @override
  String get clearCaches => 'مسح كل الكاش';

  @override
  String get clearCachesSubtitle => 'الصور، فهرس البحث، بيانات TMDB/TVmaze';

  @override
  String get resetApp => 'إعادة ضبط التطبيق';

  @override
  String get resetAppSubtitle =>
      'يمسح جميع بيانات المستخدم (الملفات، المفضلات، السجل)';

  @override
  String get snackCacheCleared => 'تم مسح الكاش (TODO)';

  @override
  String get resetAppDialogTitle => 'إعادة ضبط التطبيق؟';

  @override
  String get resetAppDialogBody =>
      'سيتم مسح جميع البيانات: الملفات، المفضلات، السجل، الإعدادات. هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get resetAppDialogConfirm => 'مسح كل شيء';

  @override
  String get tmdbKeyLabel => 'مفتاح TMDB API الشخصي (اختياري)';

  @override
  String get tmdbKeyHint => 'يُستخدم المفتاح المشترك المضمّن افتراضيًا';

  @override
  String get tmdbKeyActive => 'المفتاح الشخصي نشط — يتم تجاهل المفتاح المشترك';

  @override
  String get tmdbKeyShared =>
      'المفتاح المشترك المضمّن قيد الاستخدام (لا يوجد مفتاح شخصي)';

  @override
  String get tmdbKeyDelete => 'حذف المفتاح الشخصي';

  @override
  String get tmdbKeyColumn => 'مفاتيح TMDB';

  @override
  String get language => 'اللغة';

  @override
  String get languagePreference => 'لغة التطبيق';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';
}
