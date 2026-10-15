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
  String currentProfileLabel(String name) {
    return 'Perfil actual: $name';
  }

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
  String get langArabic => 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©';

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
  String get moreResults => 'Ver más resultados';

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
  String get newAnd4K => 'Películas a la carta';

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
  String get noGroupAffinity => 'No se encontró afinidad común';

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
  String get noRecommendations => 'No hay recomendaciones disponibles';

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
  String get play => 'Reproducir';

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
  String profilesSelected(int count) {
    return '$count perfiles seleccionados';
  }

  @override
  String get profileVisible => 'Perfil visible';

  @override
  String get programGrid => 'Guía de programas';

  @override
  String get protectWithPin => 'Proteger con código PIN';

  @override
  String get rankingsUnavailable => 'Clasificaciones no disponibles';

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
  String get seasonsAndEpisodes => 'Series a la carta';

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
  String selectAtLeastOneProfile(int count) {
    return 'Selecciona al menos 1 perfil adicional ($count/4)';
  }

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
  String get sortAffinity => 'Por afinidad';

  @override
  String get sortAffinityDescription =>
      'Ordena según tus gustos declarados en el perfil (matchmaking)';

  @override
  String get sortAscending => 'Orden ascendente';

  @override
  String get sortByDuration => 'Por duración';

  @override
  String get sortByRating => 'Por puntuación';

  @override
  String get sortByYear => 'Por año';

  @override
  String get sortDescending => 'Orden descendente';

  @override
  String get sortLatestM3UXtream => 'Últimos añadidos M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nombre (A → Z)';

  @override
  String get sortNameZToA => 'Nombre (Z → A)';

  @override
  String get sortResumePriority => 'Retomar en prioridad';

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
  String get aiTopicsTitle => 'Temas recomendados por IA';

  @override
  String get updateThisCategory => 'Actualizar esta categoría';

  @override
  String get updating => 'Actualizando…';

  @override
  String get updatingMediaContent => 'Actualizando contenido multimedia…';

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

  @override
  String get subtitleSection => 'Subtítulos';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'Vídeo';

  @override
  String get autoQuality => 'Automático';

  @override
  String get noneOption => 'Ninguno';

  @override
  String get subtitleNotApplicable => 'No aplicable';

  @override
  String get subtitleNotApplicableInfo =>
      'Una emisión en directo no publica ninguna pista de subtítulos.';

  @override
  String get subtitleUnavailable => 'No disponible';

  @override
  String get subtitleNoTrack => 'Sin pista';

  @override
  String get subtitleNoTrackInfo =>
      'El proveedor no publica subtítulos para este contenido.';

  @override
  String get subtitleGuessed => 'Pistas deducidas';

  @override
  String get subtitleGuessedInfo =>
      'El proveedor no declara sus subtítulos: estas pistas se obtienen por convención de URL. La que no exista señalará un error al activarla.';

  @override
  String get subtitleUnavailableToast => 'Subtítulo no disponible';

  @override
  String get audioTrackFallback => 'Pista de audio';

  @override
  String get subtitleLoading => 'Cargando subtítulos…';

  @override
  String get videoQualityFallback => 'Calidad de vídeo';

  @override
  String get close => 'Cerrar';

  @override
  String get streamTracksError =>
      'No se pudieron leer las pistas de esta emisión.';

  @override
  String get subtitleProviderNoAnswer => 'El proveedor no respondió.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Subtítulo no disponible: $reason';
  }

  @override
  String get epgNoDataTitle => 'Sin datos de programación';

  @override
  String get epgLiveNow => 'En directo';

  @override
  String get epgSelectChannelHint => 'Seleccione un canal para ver su programa';

  @override
  String get epgNow => 'Ahora';

  @override
  String get epgZoomIn => 'Acercar';

  @override
  String get epgZoomOut => 'Alejar';

  @override
  String get epgNoCurrentProgram => 'Ningún programa en curso';

  @override
  String replayWindowBadge(Object days) {
    return 'Replay $days d';
  }

  @override
  String replayWindowBadgeHours(Object hours) {
    return 'Replay $hours h';
  }

  @override
  String get replayNoAvailable => 'No hay replay disponible';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'Ningún programa ya emitido dentro del archivo de $days días de esta cuenta para este canal.';
  }

  @override
  String get replayNonePublished =>
      'El proveedor no publica ningún programa ya emitido para este canal.';

  @override
  String get epgActionFavorite => 'Favorito';

  @override
  String get epgActionRecording => 'Grabar';

  @override
  String get epgActionReminder => 'Recordatorio';

  @override
  String get epgStartReplay => 'Iniciar replay';

  @override
  String get epgBack => 'Atrás';

  @override
  String epgWatchChannel(Object name) {
    return 'Ver $name';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'El proveedor no sirve subtítulos para este contenido.';

  @override
  String subtitleVerifying(Object count) {
    return 'Comprobando subtítulos… ($count)';
  }

  @override
  String get subtitleSearchOnline => 'Buscar en línea';

  @override
  String get subtitleSearchOnlineInfo =>
      'El proveedor no ofrece nada para este contenido. Una búsqueda en línea puede encontrar un subtítulo.';

  @override
  String get subtitleSearchOnlineRunning => 'Buscando…';

  @override
  String get subtitleOnlineResults => 'Subtítulos encontrados en línea';

  @override
  String get subtitleOnlineEmpty =>
      'No se encontró ningún subtítulo en línea para este contenido.';

  @override
  String subtitleOnlineDownloads(Object count) {
    return '$count descargas';
  }

  @override
  String get subtitleOnlineNoTmdb =>
      'No se pudo identificar este contenido en TMDB: la búsqueda en línea necesita su identificador.';

  @override
  String get opensubtitlesKeyLabel =>
      'Búsqueda de subtítulos en línea (OpenSubtitles)';

  @override
  String get opensubtitlesKeyHint => 'Clave API — opcional';

  @override
  String get opensubtitlesKeyActive =>
      'Clave guardada: mayor cuota de descarga.';

  @override
  String get opensubtitlesKeyAnonymous =>
      'Sin clave: la búsqueda funciona, 5 descargas por IP y 24 h.';

  @override
  String get opensubtitlesKeyDelete => 'Borrar la clave';

  @override
  String get opensubtitlesKeyCheck => 'Comprobar la clave';

  @override
  String get opensubtitlesKeyChecking => 'Comprobando…';

  @override
  String get opensubtitlesKeyValid => 'Clave válida: el servicio la acepta.';

  @override
  String get opensubtitlesKeyRejected =>
      'Clave rechazada por el servicio: comprueba que la pegaste completa.';

  @override
  String get opensubtitlesKeyUnreachable =>
      'Servicio inaccesible: comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get opensubtitlesLoginLabel => 'Conexión a la cuenta de OpenSubtitles';

  @override
  String get opensubtitlesLoginHintUsername => 'Usuario';

  @override
  String get opensubtitlesLoginHintPassword => 'Contraseña';

  @override
  String get opensubtitlesLoginActive =>
      'Cuenta guardada: las descargas podrán conectarse.';

  @override
  String get opensubtitlesLoginNone =>
      'Sin cuenta: la descarga sigue rechazada (503).';

  @override
  String get opensubtitlesLoginDelete => 'Borrar la cuenta';

  @override
  String get opensubtitlesLoginConnect => 'Iniciar sesión / comprobar';

  @override
  String get opensubtitlesLoginConnecting => 'Conectando…';

  @override
  String get opensubtitlesLoginValid =>
      'Cuenta aceptada: el servicio emitió un token.';

  @override
  String get opensubtitlesLoginRejected =>
      'Credenciales rechazadas: comprueba el usuario y la contraseña.';

  @override
  String get opensubtitlesLoginUnreachable =>
      'Servicio inaccesible: comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get subtitleOnlineNoApiKey =>
      'Falta la clave API de OpenSubtitles: introdúcela en Ajustes para activar la búsqueda en línea.';

  @override
  String get subtitleOnlineKeyRejected =>
      'Clave API de OpenSubtitles rechazada: está configurada, pero el servicio la rechaza. Compruébala en Ajustes.';

  @override
  String get subtitleOnlineQuota =>
      'Cuota de descarga de OpenSubtitles alcanzada hoy. Inténtalo mañana.';

  @override
  String get subtitleOnlineNeedsLogin =>
      'La descarga de OpenSubtitles requiere una cuenta conectada, no solo la clave API: la búsqueda funciona, pero la descarga se rechaza.';

  @override
  String get favorites => 'Favoritos';

  @override
  String get films => 'Películas';

  @override
  String get replay => 'Replay';

  @override
  String get myContent => 'Mi contenido';

  @override
  String get contentTypeSelector => 'Tipo de contenido';

  @override
  String get downloadStatusDownloading => 'Descargando';

  @override
  String get downloadStatusPreparing => 'Preparando';

  @override
  String get downloadStatusPaused => 'En pausa';

  @override
  String get downloadStatusCompleted => 'Completado';

  @override
  String get downloadStatusFailed => 'Fallido';

  @override
  String get downloadStatusCancelled => 'Cancelado';

  @override
  String get downloadStatusQueued => 'En cola';

  @override
  String get history => 'Historial';

  @override
  String get explore => 'Explorar';

  @override
  String get downloadsEmptyHint =>
      'Añade contenido desde la ficha de una película o serie.';

  @override
  String get downloadsLocation => 'Archivos';

  @override
  String get advancedSettingsTitle => 'Ajustes avanzados';

  @override
  String get advancedSettingsIntro =>
      'Credenciales de API y ajustes de red. Estos ajustes comprometen tu cuenta con servicios de terceros: una clave compartida consume su cuota y un ajuste de red erróneo puede impedir que la aplicación arranque.';

  @override
  String get advancedSubtitlesProvider => 'Proveedor de subtítulos';

  @override
  String get advancedStatus => 'Estado de las credenciales';

  @override
  String get advancedAccessTitle => 'Acceso restringido';

  @override
  String get advancedAccessHint => 'Código';

  @override
  String get advancedAccessConfirm => 'Abrir';

  @override
  String get advancedAccessWrong => 'Código incorrecto';

  @override
  String get advancedHiddenHint => 'Mantén pulsado para los ajustes avanzados';

  @override
  String get favoritesAndDownloads => 'Favoritos y Descargas';

  @override
  String get activeAudio => 'Audio en esta pantalla';

  @override
  String get addChannel => 'Añadir un canal';

  @override
  String get noChannelSelected => 'Ningún canal seleccionado';

  @override
  String get removeChannel => 'Quitacar canal';

  @override
  String get avatarCategoryAll => 'Todas';

  @override
  String get avatarCategoryCharacters => 'Personajes';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Negro y Blanco';

  @override
  String get avatarCategoryPixels => 'Pixels';
}
