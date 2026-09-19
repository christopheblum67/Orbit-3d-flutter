// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accountDeviceProfile => 'Perfil del dispositivo y diagnóstico';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Perfil $label · diagnóstico del reproductor';
  }

  @override
  String get accountNoSubscription => 'Sin suscripción activa';

  @override
  String get accountPreferences => 'Preferencias de perfil';

  @override
  String get accountPreferencesSubtitle =>
      'Idioma, tema, restricciones de edad, PIN';

  @override
  String get accountProfiles => 'Perfiles de usuario';

  @override
  String get accountProfilesSubtitle => 'Gestionar perfiles y el perfil activo';

  @override
  String get accountSubscriptions => 'Suscripciones Xtream/M3U';

  @override
  String activeCountOngoing(Object count) {
    return '$count en curso';
  }

  @override
  String get addSubscription => 'Añadir una suscripción';

  @override
  String addedToFavorites(Object title) {
    return '\"$title\" añadido a favoritos';
  }

  @override
  String get age => 'Edad';

  @override
  String get ageRange13to17 => '13 - 17 años';

  @override
  String get ageRange18to24 => '18 - 24 años';

  @override
  String get ageRange25to34 => '25 - 34 años';

  @override
  String get ageRange35to44 => '35 - 44 años';

  @override
  String get ageRange45to54 => '45 - 54 años';

  @override
  String get ageRange55plus => '55 años y más';

  @override
  String get ageRangeUnder12 => '- 12 años';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'Aparecer en búsquedas y recomendaciones';

  @override
  String get apply => 'Aplicar';

  @override
  String get audioAndNightFocus => 'Audio y Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Optimización nocturna, refuerzo de diálogos, sincronización A/V';

  @override
  String get audioShift => 'Desfase de audio configurable';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'Desfase audio/vídeo manual (ms)';

  @override
  String get autoQualityDescription =>
      'Permite al reproductor elegir la mejor calidad';

  @override
  String get autoReconnectLive => 'Reconexión automática en vivo';

  @override
  String get autoReconnectLiveSubtitle =>
      'Reconecta automáticamente si el flujo se corta';

  @override
  String get avSyncDialogHint =>
      'Positivo = audio adelantado, Negativo = audio retardado';

  @override
  String get avSyncDialogLabel => 'Desfase (ms)';

  @override
  String get avSyncDialogTitle => 'Calibración A/V';

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
  String get bassKiller => 'Bass Killer (corte < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Atenúa las bajas frecuencias para evitar vibraciones';

  @override
  String get cancel => 'Cancelar';

  @override
  String get castToChromecast => 'Emitir en Chromecast';

  @override
  String get catchUpTv => 'Catching-up';

  @override
  String get categories => 'Categorías';

  @override
  String get certPinning => 'Activar Certificate Pinning';

  @override
  String get certPinningAdd => 'Añadir las huellas de arriba';

  @override
  String get certPinningHint =>
      'Huellas permitidas (una por línea, hexadecimal en mayúsculas):';

  @override
  String get certPinningSubtitle =>
      'Verifica la huella SHA-256 del certificado SSL del servidor (anti-MITM)';

  @override
  String get changePinCode => 'Cambiar código PIN';

  @override
  String get channelsUnavailable => 'Canales no disponibles';

  @override
  String get chooseProfile => 'Elegir un perfil';

  @override
  String get clearCaches => 'Vaciar todas las cachés';

  @override
  String get clearCachesSubtitle =>
      'Imágenes, índice de búsqueda, metadatos TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'Sincronización activada';

  @override
  String cloudSyncLastSync(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get cloudSyncNow => 'Sincronizar ahora';

  @override
  String get cloudSyncNowSubtitle => 'Envía los cambios locales a la nube';

  @override
  String get cloudSyncSubtitleOff =>
      'Sincroniza favoritos, vistos y recientes en la nube';

  @override
  String get cloudflareReset => 'Restablecer configuración de Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Borra cookies, TLS Impersonation=OFF, UA ExoPlayer por defecto';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get confirmAndContinue => 'Confirmar y continuar';

  @override
  String get coverCacheCleared => 'Caché de carátulas purgado.';

  @override
  String get createKidProfile => 'Crear un perfil infantil';

  @override
  String get createNewProfile => 'Crear un nuevo perfil';

  @override
  String get createProfile => 'Crear un perfil';

  @override
  String get dataAlreadyFresh => 'Datos ya actualizados (menos de 30 min)';

  @override
  String get dataAndPrivacy => 'Datos y privacidad';

  @override
  String get deleteAll => 'Eliminar todo';

  @override
  String get deleteAllConfirm => '¿Eliminar todo?';

  @override
  String get deletePin => 'Eliminar el PIN';

  @override
  String get deleteProfileConfirm => '¿Eliminar el perfil?';

  @override
  String get detailUnavailable => 'Detalle no disponible';

  @override
  String get diagnosticUnavailable => 'Diagnóstico no disponible';

  @override
  String get dialogueBoost => 'Refuerzo de diálogos (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifica las voces frente a efectos/música';

  @override
  String get disableSubtitles => 'Desactivar subtítulos';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'Proveedor DNS (DoH)';

  @override
  String get dnsProviderSubtitle =>
      'Servidor usado para consultas DNS over HTTPS';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automático (Sistema)';

  @override
  String downloadFailed(Object error) {
    return 'Descarga fallida: $error';
  }

  @override
  String get downloads => 'Descargas';

  @override
  String get dpadNavigation => 'Navegación con D-pad reforzada';

  @override
  String get dpadNavigationSubtitle =>
      'Foco visible, halo luminoso, ajuste de texto (modo TV)';

  @override
  String get enableParentalControl => 'Activar el control parental';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'En vivo: $live · VOD: $vod';
  }

  @override
  String get enginesTile => 'Motores de reproducción';

  @override
  String get enterNew4DigitPin => 'Introduce un nuevo código de 4 dígitos';

  @override
  String get epgGrille => 'EPG (guía)';

  @override
  String get epgGuideTv => 'Guía TV (EPG)';

  @override
  String get episode => 'Episodio';

  @override
  String errorGeneric(Object error) {
    return 'Error: $error';
  }

  @override
  String errorLoading(Object error) {
    return 'Error de carga: $error';
  }

  @override
  String get errorSaving => 'Error al guardar';

  @override
  String get exitWithoutSaving => '¿Salir sin guardar?';

  @override
  String get failedToLoadProfiles => 'No se pudieron cargar los perfiles';

  @override
  String get fallbackEngine => 'Motor de Respaldo';

  @override
  String get favoriteGenres => 'Géneros favoritos';

  @override
  String get filmsVod => 'Películas (VOD)';

  @override
  String get firstName => 'Nombre';

  @override
  String get fontSize => 'Tamaño de texto aumentado';

  @override
  String get fontSizeSubtitle => 'Agranda los textos en toda la app';

  @override
  String get forYou => 'Para ti';

  @override
  String get forYouAndDuo => 'Para ti y En duo';

  @override
  String get forYouMatchmaking => 'Para ti (Matchmaking)';

  @override
  String get forward10s => 'Adelantar 10s';

  @override
  String get forward30s => 'Adelantar 30s';

  @override
  String get groupMode => 'En grupo';

  @override
  String get highContrast => 'Modo de alto contraste';

  @override
  String get highContrastSubtitle =>
      'Mejora la legibilidad para personas con discapacidad visual';

  @override
  String get historyUnavailable => 'Historial no disponible';

  @override
  String get instantZapping => 'Zapping instantáneo (precarga)';

  @override
  String get instantZappingSubtitle =>
      'Precarga los canales adyacentes en el búfer';

  @override
  String get kidsContent => 'Contenido infantil';

  @override
  String get kidsMode => 'Modo Infantil';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langSpanish => 'Español';

  @override
  String get language => 'Idioma';

  @override
  String get languageExample => 'Français, English, etc.';

  @override
  String get languagePreference => 'Idioma de la aplicación';

  @override
  String get languageUndetermined => 'Indeterminado';

  @override
  String get later => 'Más tarde';

  @override
  String get legalNotice => 'Leer · Aviso legal';

  @override
  String get legalNoticeSubtitle =>
      'Uso de la app, titulares de derechos y privacidad';

  @override
  String get liveChannelsAndZapping => 'Canales en directo y Zapping';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'Registros y diagnóstico';

  @override
  String get logsDiagnosticSubtitle => 'Ver registros, exportar, vaciar caché';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'URL de la playlist M3U';

  @override
  String get mainCast => 'Reparto principal';

  @override
  String get manualAvCalibration => 'Calibración A/V manual';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Desfase actual: $ms ms';
  }

  @override
  String get matchmaking => 'Para ti (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Gestionar emparejamiento y sugerencias personalizadas';

  @override
  String maxProfilesReached(Object max) {
    return 'Número máximo de perfiles alcanzado ($max)';
  }

  @override
  String get memory => 'Memoria';

  @override
  String get moviesUnavailable => 'Películas no disponibles';

  @override
  String get multiScreen => 'Multi-pantalla';

  @override
  String get multiVideo => 'Multi-vídeo';

  @override
  String get myProfile => 'Mi perfil';

  @override
  String get nameOptional => 'Nombre (opcional)';

  @override
  String get nameOrNickname => 'Nombre / Apodo';

  @override
  String get navigateToOkToSelect => 'Navega a OK para seleccionar';

  @override
  String get networkDisconnected => 'Red desconectada';

  @override
  String get never => 'nunca';

  @override
  String get newAnd4K => 'Novedades y 4K';

  @override
  String get newProfile => 'Nuevo perfil';

  @override
  String get nextChannel => 'Canal siguiente';

  @override
  String get nightFocusEnable => 'Activar Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Procesamiento de audio en tiempo real: refuerzo de diálogos, corte de graves, sincronización';

  @override
  String get nightFocusTitle => 'Night Focus (modo nocturno)';

  @override
  String get noAudioTrackDetected => 'No se detectó pista de audio';

  @override
  String get noChannelsAvailable => 'No hay canales disponibles';

  @override
  String get noChromecastDeviceFound =>
      'No se encontró ningún dispositivo Chromecast.';

  @override
  String get noDownloads => 'No hay descargas';

  @override
  String get noEpisodes => 'No hay episodios';

  @override
  String get noFavoriteChannels => 'No hay canales favoritos';

  @override
  String get noFavoriteMovies => 'No hay películas favoritas';

  @override
  String get noFavoriteReplays => 'No hay reemisiones favoritas';

  @override
  String get noFavoriteSeries => 'No hay series favoritas';

  @override
  String get noHistory => 'No hay historial';

  @override
  String get noKidsChannels => 'No hay canales infantiles';

  @override
  String get noKidsMovies => 'No hay películas infantiles';

  @override
  String get noKidsReplays => 'No hay reemisiones infantiles';

  @override
  String get noKidsSeries => 'No hay series infantiles';

  @override
  String get noMoviesAvailable => 'No hay películas disponibles';

  @override
  String get noProfileAvailable => 'No hay perfil disponible';

  @override
  String get noProfilesYet => 'No hay perfiles aún';

  @override
  String get noProgramInfoAvailable =>
      'No hay información de programa disponible';

  @override
  String get noRankings => 'No hay clasificaciones';

  @override
  String get noReplaysInCategory => 'No hay reemisiones en esta categoría';

  @override
  String noResultsFor(Object query) {
    return 'Sin resultados para $query';
  }

  @override
  String get noSeriesAvailable => 'No hay series disponibles';

  @override
  String get noStationsAvailable => 'No hay estaciones disponibles';

  @override
  String get noVideoQualityDetected => 'No se detectó calidad de vídeo';

  @override
  String get notAvailableInCatalog => 'No disponible en el catálogo';

  @override
  String get offline => 'Sin conexión';

  @override
  String get parentalControl => 'Control parental';

  @override
  String get parentalControlSubtitle =>
      'Añadir un código PIN y restringir contenido';

  @override
  String get pauseDownload => 'Pausar';

  @override
  String get pinCode => 'Código PIN';

  @override
  String get pinDeleted => 'PIN eliminado';

  @override
  String get pinMustBe4Digits => 'El PIN debe contener exactamente 4 dígitos';

  @override
  String get pinSaved => 'PIN guardado';

  @override
  String get pip => 'Ventana flotante (PiP)';

  @override
  String get pipUnavailable =>
      'Ventana flotante (PiP) no disponible en este dispositivo';

  @override
  String get playHistoryCleared => 'Historial de reproducción borrado.';

  @override
  String plusAgeYears(Object age) {
    return '+$age años';
  }

  @override
  String get preferences => 'Preferencias';

  @override
  String get previousChannel => 'Canal anterior';

  @override
  String get primaryEngine => 'Motor Principal';

  @override
  String get profileVisible => 'Perfil visible';

  @override
  String get programGrid => 'Guía de programas';

  @override
  String get protectWithPin => 'Proteger con código PIN';

  @override
  String get rankingsUnavailable => 'Clasificaciones no disponibles';

  @override
  String get receiveAlertsAndTips => 'Recibir alertas y consejos';

  @override
  String get recentSearch => 'Búsqueda reciente';

  @override
  String get recentSearches => 'Recientes';

  @override
  String get recentlyWatched => 'Visto recientemente';

  @override
  String get removeAll => 'Retirar todo';

  @override
  String get removeFromWatchedConfirm => '¿Retirar todo de vistos?';

  @override
  String get replaysUnavailable => 'Reemisiones no disponibles';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetApp => 'Restablecer aplicación';

  @override
  String get resetAppDialogBody =>
      'Se borrarán todos los datos: perfiles, favoritos, historial, ajustes. Esta acción es irreversible.';

  @override
  String get resetAppDialogConfirm => 'Borrar todo';

  @override
  String get resetAppDialogTitle => '¿Restablecer la aplicación?';

  @override
  String get resetAppSubtitle =>
      'Borra todos los datos de usuario (perfiles, favoritos, historial)';

  @override
  String get resetCompleted => 'Restablecimiento completado';

  @override
  String get resumePlayback => '¿Reanudar la reproducción?';

  @override
  String get retry => 'Reintentar';

  @override
  String get retrySearch => 'Reintentar búsqueda';

  @override
  String get rewind10s => 'Retroceder 10s';

  @override
  String get rewind30s => 'Retroceder 30s';

  @override
  String get rightsHolders => 'Titulares de derechos';

  @override
  String get save => 'Guardar';

  @override
  String get sdkAndroid => 'SDK Android';

  @override
  String get searchChannel => 'Buscar un canal';

  @override
  String get searchError => 'Error de búsqueda';

  @override
  String get searchMovie => 'Buscar una película';

  @override
  String get searchSeries => 'Buscar una serie';

  @override
  String seasonNumber(Object season) {
    return 'Temporada $season';
  }

  @override
  String get seasonsAndEpisodes => 'Temporadas y episodios';

  @override
  String get sectionAccessibility => 'Accesibilidad';

  @override
  String get sectionAccountProfile => 'Cuenta y perfil';

  @override
  String get sectionAntiThrottle => 'Protección anti-limitación del ISP';

  @override
  String get sectionAudioNight => 'Audio y Night Focus';

  @override
  String get sectionAvSync => 'Sincronización A/V';

  @override
  String get sectionBackup => 'Copia de seguridad / Restauración';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get sectionCloudSync => 'Sincronización en la nube (multidispositivo)';

  @override
  String get sectionCloudflare => 'Optimización Cloudflare';

  @override
  String get sectionDiagnostics => 'Diagnóstico y mantenimiento';

  @override
  String get sectionEngines => 'Motores de reproducción';

  @override
  String get sectionLegal => 'Información legal';

  @override
  String get sectionMemory => 'Memoria y caché';

  @override
  String get sectionNotifications => 'Notificaciones';

  @override
  String get sectionOutput => 'Salida de audio';

  @override
  String get sectionParental => 'Control parental';

  @override
  String get sectionRecommendations => 'Recomendaciones';

  @override
  String get sectionResilience => 'Resistencia del servicio';

  @override
  String get sectionTmdb => 'Clasificaciones TMDB';

  @override
  String get sectionZapping => 'Zapping y rendimiento';

  @override
  String get select => 'Seleccionar';

  @override
  String get selectProfileForRecommendations =>
      'Selecciona un perfil para ver sus recomendaciones';

  @override
  String get series => 'Series';

  @override
  String get seriesNotFound => 'Serie no encontrada';

  @override
  String get seriesUnavailable => 'Series no disponibles';

  @override
  String get seriesUnavailableTemporarily =>
      'Serie no disponible por el momento.';

  @override
  String get serverProtectedAntiLeech => 'Servidor protegido (anti-leech)';

  @override
  String get serverUrlPlaceholder =>
      'URL del servidor (ej: https://provider.com)';

  @override
  String get serviceNature => 'Naturaleza del servicio';

  @override
  String get setAsDefaultServer => 'Establecer como servidor predeterminado';

  @override
  String get settings => 'Ajustes';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get similarMovies => 'Películas similares';

  @override
  String get snackBackupExported => 'Configuración exportada al portapapeles';

  @override
  String get snackCacheCleared => 'Cachés vaciadas';

  @override
  String get snackCloudflareReset => 'Configuración de Cloudflare restablecida';

  @override
  String snackImportError(String message) {
    return 'Error: $message';
  }

  @override
  String get snackImportSuccess => 'Configuración importada correctamente';

  @override
  String get snackNoBackup => 'No se encontró ninguna copia';

  @override
  String get sortBestRated => 'Mejor valorados (XCIPTV)';

  @override
  String get sortLatestM3UXtream => 'Últimos añadidos M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nombre (A → Z)';

  @override
  String get sortNameZToA => 'Nombre (Z → A)';

  @override
  String get sortResumePriority => 'Retomar en prioridad';

  @override
  String get sortYearRecentToOld => 'Año de estreno (Reciente → Antiguo)';

  @override
  String specialGuestsSeason(Object season) {
    return 'Invitados especiales - Temporada $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'Iniciar';

  @override
  String get stationsUnavailable => 'Estaciones no disponibles';

  @override
  String get stopCasting => 'Detener la emisión';

  @override
  String get streamDetails => 'Detalles del stream';

  @override
  String subtitleLoadError(Object error) {
    return 'Error al cargar subtítulo: $error';
  }

  @override
  String get subtitlesUnavailable => 'Subtítulos: no disponibles';

  @override
  String get system => 'Sistema';

  @override
  String get tabAccount => 'Cuenta';

  @override
  String get tabAdvanced => 'Avanzado';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabNetwork => 'Red';

  @override
  String get tabPlayer => 'Reproductor';

  @override
  String get tabSecurity => 'Seguridad';

  @override
  String get testNotifications => 'Probar notificaciones';

  @override
  String get testNotificationsSubtitle =>
      'Envía una notificación local de prueba';

  @override
  String get theme => 'Tema';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Proxy local)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simula la huella de un navegador moderno para eludir Cloudflare';

  @override
  String get tmdbKeyActive => 'Clave personal activa: se ignora la compartida';

  @override
  String get tmdbKeyColumn => 'Claves TMDB';

  @override
  String get tmdbKeyDelete => 'Eliminar clave personal';

  @override
  String get tmdbKeyHint => 'Se usa la clave compartida integrada por defecto';

  @override
  String get tmdbKeyLabel => 'Clave API personal de TMDB (opcional)';

  @override
  String get tmdbKeyShared =>
      'Clave compartida integrada en uso (sin clave personal)';

  @override
  String get tvChannels => 'Canales TV';

  @override
  String get unableToBuildReplayUrl =>
      'No se pudo construir la URL del replay.';

  @override
  String get unlockCloudflare => 'Desbloquear (Cloudflare)';

  @override
  String get unstableConnection => 'Conexión inestable';

  @override
  String get updateAllData => 'Actualizar todos los datos';

  @override
  String get updateThisCategory => 'Actualizar esta categoría';

  @override
  String get updating => 'Actualizando…';

  @override
  String get volumeNormalization => 'Normalización del volumen';

  @override
  String get volumeNormalizationSubtitle =>
      'Limita los picos de volumen entre canales/programas (AGC)';

  @override
  String get watchLive => 'Ver en directo';

  @override
  String get whoIsWatching => '¿Quién ve?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Tus canales y contenidos';
}
