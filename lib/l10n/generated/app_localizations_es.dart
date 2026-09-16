// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get tabAccount => 'Cuenta';

  @override
  String get tabNetwork => 'Red';

  @override
  String get tabPlayer => 'Reproductor';

  @override
  String get tabSecurity => 'Seguridad';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabAdvanced => 'Avanzado';

  @override
  String get sectionAccountProfile => 'Cuenta y perfil';

  @override
  String get accountProfiles => 'Perfiles de usuario';

  @override
  String get accountProfilesSubtitle => 'Gestionar perfiles y el perfil activo';

  @override
  String get accountSubscriptions => 'Suscripciones Xtream/M3U';

  @override
  String get accountNoSubscription => 'Sin suscripción activa';

  @override
  String get accountPreferences => 'Preferencias de perfil';

  @override
  String get accountPreferencesSubtitle =>
      'Idioma, tema, restricciones de edad, PIN';

  @override
  String get accountDeviceProfile => 'Perfil del dispositivo y diagnóstico';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Perfil $label · diagnóstico del reproductor';
  }

  @override
  String get sectionCloudSync => 'Sincronización en la nube (multidispositivo)';

  @override
  String get cloudSyncEnabled => 'Sincronización activada';

  @override
  String cloudSyncLastSync(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get cloudSyncSubtitleOff =>
      'Sincroniza favoritos, vistos y recientes en la nube';

  @override
  String get cloudSyncNow => 'Sincronizar ahora';

  @override
  String get cloudSyncNowSubtitle => 'Envía los cambios locales a la nube';

  @override
  String get never => 'nunca';

  @override
  String get sectionNotifications => 'Notificaciones';

  @override
  String get testNotifications => 'Probar notificaciones';

  @override
  String get testNotificationsSubtitle =>
      'Envía una notificación local de prueba';

  @override
  String get sectionBackup => 'Copia de seguridad / Restauración';

  @override
  String get backupExport => 'Exportar configuración';

  @override
  String get backupExportSubtitle =>
      'Copia la configuración completa al portapapeles';

  @override
  String get backupImport => 'Importar configuración';

  @override
  String get backupImportSubtitle => 'Restaurar desde el portapapeles (JSON)';

  @override
  String get snackBackupExported => 'Configuración exportada al portapapeles';

  @override
  String get snackNoBackup => 'No se encontró ninguna copia';

  @override
  String get snackImportSuccess => 'Configuración importada correctamente';

  @override
  String snackImportError(String message) {
    return 'Error: $message';
  }

  @override
  String get sectionAntiThrottle => 'Protección anti-limitación del ISP';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy local)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simula la huella de un navegador moderno para eludir Cloudflare';

  @override
  String get dnsProvider => 'Proveedor DNS (DoH)';

  @override
  String get dnsProviderSubtitle =>
      'Servidor usado para consultas DNS over HTTPS';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automático (Sistema)';

  @override
  String get sectionCloudflare => 'Optimización Cloudflare';

  @override
  String get cloudflareReset => 'Restablecer configuración de Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Borra cookies, TLS Impersonation=OFF, UA ExoPlayer por defecto';

  @override
  String get snackCloudflareReset => 'Configuración de Cloudflare restablecida';

  @override
  String get sectionEngines => 'Motores de reproducción';

  @override
  String get enginesTile => 'Motores de reproducción';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'En vivo: $live · VOD: $vod';
  }

  @override
  String get sectionAudioNight => 'Audio y Night Focus';

  @override
  String get audioAndNightFocus => 'Audio y Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Optimización nocturna, refuerzo de diálogos, sincronización A/V';

  @override
  String get sectionZapping => 'Zapping y rendimiento';

  @override
  String get instantZapping => 'Zapping instantáneo (precarga)';

  @override
  String get instantZappingSubtitle =>
      'Precarga los canales adyacentes en el búfer';

  @override
  String get sectionMemory => 'Memoria y caché';

  @override
  String get sectionParental => 'Control parental';

  @override
  String get parentalControl => 'Control parental';

  @override
  String get parentalControlSubtitle =>
      'Añadir un código PIN y restringir contenido';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get certPinning => 'Activar Certificate Pinning';

  @override
  String get certPinningSubtitle =>
      'Verifica la huella SHA-256 del certificado SSL del servidor (anti-MITM)';

  @override
  String get certPinningHint =>
      'Huellas permitidas (una por línea, hexadecimal en mayúsculas):';

  @override
  String get certPinningAdd => 'Añadir las huellas de arriba';

  @override
  String get sectionResilience => 'Resistencia del servicio';

  @override
  String get autoReconnectLive => 'Reconexión automática en vivo';

  @override
  String get autoReconnectLiveSubtitle =>
      'Reconecta automáticamente si el flujo se corta';

  @override
  String get sectionLegal => 'Información legal';

  @override
  String get legalNotice => 'Leer · Aviso legal';

  @override
  String get legalNoticeSubtitle =>
      'Uso de la app, titulares de derechos y privacidad';

  @override
  String get nightFocusTitle => 'Night Focus (modo nocturno)';

  @override
  String get nightFocusEnable => 'Activar Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Procesamiento de audio en tiempo real: refuerzo de diálogos, corte de graves, sincronización';

  @override
  String get dialogueBoost => 'Refuerzo de diálogos (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifica las voces frente a efectos/música';

  @override
  String get bassKiller => 'Bass Killer (corte < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Atenúa las bajas frecuencias para evitar vibraciones';

  @override
  String get sectionAvSync => 'Sincronización A/V';

  @override
  String get audioShift => 'Desfase de audio configurable';

  @override
  String get audioShiftSubtitle => 'Desfase audio/vídeo manual (ms)';

  @override
  String get manualAvCalibration => 'Calibración A/V manual';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Desfase actual: $ms ms';
  }

  @override
  String get sectionOutput => 'Salida de audio';

  @override
  String get volumeNormalization => 'Normalización del volumen';

  @override
  String get volumeNormalizationSubtitle =>
      'Limita los picos de volumen entre canales/programas (AGC)';

  @override
  String get avSyncDialogTitle => 'Calibración A/V';

  @override
  String get avSyncDialogLabel => 'Desfase (ms)';

  @override
  String get avSyncDialogHint =>
      'Positivo = audio adelantado, Negativo = audio retardado';

  @override
  String get apply => 'Aplicar';

  @override
  String get sectionAccessibility => 'Accesibilidad';

  @override
  String get highContrast => 'Modo de alto contraste';

  @override
  String get highContrastSubtitle =>
      'Mejora la legibilidad para personas con discapacidad visual';

  @override
  String get dpadNavigation => 'Navegación con D-pad reforzada';

  @override
  String get dpadNavigationSubtitle =>
      'Foco visible, halo luminoso, ajuste de texto (modo TV)';

  @override
  String get fontSize => 'Tamaño de texto aumentado';

  @override
  String get fontSizeSubtitle => 'Agranda los textos en toda la app';

  @override
  String get sectionTmdb => 'Clasificaciones TMDB';

  @override
  String get sectionRecommendations => 'Recomendaciones';

  @override
  String get matchmaking => 'Para ti (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Gestionar emparejamiento y sugerencias personalizadas';

  @override
  String get sectionDiagnostics => 'Diagnóstico y mantenimiento';

  @override
  String get logsDiagnostic => 'Registros y diagnóstico';

  @override
  String get logsDiagnosticSubtitle => 'Ver registros, exportar, vaciar caché';

  @override
  String get clearCaches => 'Vaciar todas las cachés';

  @override
  String get clearCachesSubtitle =>
      'Imágenes, índice de búsqueda, metadatos TMDB/TVmaze';

  @override
  String get resetApp => 'Restablecer aplicación';

  @override
  String get resetAppSubtitle =>
      'Borra todos los datos de usuario (perfiles, favoritos, historial)';

  @override
  String get snackCacheCleared => 'Cachés vaciadas (TODO)';

  @override
  String get resetAppDialogTitle => '¿Restablecer la aplicación?';

  @override
  String get resetAppDialogBody =>
      'Se borrarán todos los datos: perfiles, favoritos, historial, ajustes. Esta acción es irreversible.';

  @override
  String get resetAppDialogConfirm => 'Borrar todo';

  @override
  String get tmdbKeyLabel => 'Clave API personal de TMDB (opcional)';

  @override
  String get tmdbKeyHint => 'Se usa la clave compartida integrada por defecto';

  @override
  String get tmdbKeyActive => 'Clave personal activa: se ignora la compartida';

  @override
  String get tmdbKeyShared =>
      'Clave compartida integrada en uso (sin clave personal)';

  @override
  String get tmdbKeyDelete => 'Eliminar clave personal';

  @override
  String get tmdbKeyColumn => 'Claves TMDB';

  @override
  String get language => 'Idioma';

  @override
  String get languagePreference => 'Idioma de la aplicación';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';
}
