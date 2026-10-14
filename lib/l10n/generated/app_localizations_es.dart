// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accountDeviceProfile => 'Perfil del dispositivo y diagnÃ³stico';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Perfil $label Â· diagnÃ³stico del reproductor';
  }

  @override
  String get accountNoSubscription => 'Sin suscripciÃ³n activa';

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
  String get addSubscription => 'AÃ±adir una suscripciÃ³n';

  @override
  String addedToFavorites(Object title) {
    return '\"$title\" aÃ±adido a favoritos';
  }

  @override
  String get age => 'Edad';

  @override
  String get ageRange13to17 => '13 - 17 aÃ±os';

  @override
  String get ageRange18to24 => '18 - 24 aÃ±os';

  @override
  String get ageRange25to34 => '25 - 34 aÃ±os';

  @override
  String get ageRange35to44 => '35 - 44 aÃ±os';

  @override
  String get ageRange45to54 => '45 - 54 aÃ±os';

  @override
  String get ageRange55plus => '55 aÃ±os y mÃ¡s';

  @override
  String get ageRangeUnder12 => '- 12 aÃ±os';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'Aparecer en bÃºsquedas y recomendaciones';

  @override
  String get apply => 'Aplicar';

  @override
  String get audioAndNightFocus => 'Audio y Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'OptimizaciÃ³n nocturna, refuerzo de diÃ¡logos, sincronizaciÃ³n A/V';

  @override
  String get audioShift => 'Desfase de audio configurable';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'Desfase audio/vÃ­deo manual (ms)';

  @override
  String get autoQualityDescription =>
      'Permite al reproductor elegir la mejor calidad';

  @override
  String get autoReconnectLive => 'ReconexiÃ³n automÃ¡tica en vivo';

  @override
  String get autoReconnectLiveSubtitle =>
      'Reconecta automÃ¡ticamente si el flujo se corta';

  @override
  String get avSyncDialogHint =>
      'Positivo = audio adelantado, Negativo = audio retardado';

  @override
  String get avSyncDialogLabel => 'Desfase (ms)';

  @override
  String get avSyncDialogTitle => 'CalibraciÃ³n A/V';

  @override
  String get backupExport => 'Exportar configuraciÃ³n';

  @override
  String get backupExportSubtitle =>
      'Copia la configuraciÃ³n completa al portapapeles';

  @override
  String get backupImport => 'Importar configuraciÃ³n';

  @override
  String get backupImportSubtitle => 'Restaurar desde el portapapeles (JSON)';

  @override
  String get bassKiller => 'Bass Killer (corte < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'AtenÃºa las bajas frecuencias para evitar vibraciones';

  @override
  String get cancel => 'Cancelar';

  @override
  String get castToChromecast => 'Emitir en Chromecast';

  @override
  String get catchUpTv => 'Catching-up';

  @override
  String get categories => 'CategorÃ­as';

  @override
  String get certPinning => 'Activar Certificate Pinning';

  @override
  String get certPinningAdd => 'AÃ±adir las huellas de arriba';

  @override
  String get certPinningHint =>
      'Huellas permitidas (una por lÃ­nea, hexadecimal en mayÃºsculas):';

  @override
  String get certPinningSubtitle =>
      'Verifica la huella SHA-256 del certificado SSL del servidor (anti-MITM)';

  @override
  String get changePinCode => 'Cambiar cÃ³digo PIN';

  @override
  String get channelsUnavailable => 'Canales no disponibles';

  @override
  String get chooseProfile => 'Elegir un perfil';

  @override
  String get clearCaches => 'Vaciar todas las cachÃ©s';

  @override
  String get clearCachesSubtitle =>
      'ImÃ¡genes, Ã­ndice de bÃºsqueda, metadatos TMDB/TVmaze';

  @override
  String get cloudSyncEnabled => 'SincronizaciÃ³n activada';

  @override
  String cloudSyncLastSync(String time) {
    return 'Ãšltima sincronizaciÃ³n: $time';
  }

  @override
  String get cloudSyncNow => 'Sincronizar ahora';

  @override
  String get cloudSyncNowSubtitle => 'EnvÃ­a los cambios locales a la nube';

  @override
  String get cloudSyncSubtitleOff =>
      'Sincroniza favoritos, vistos y recientes en la nube';

  @override
  String get cloudflareReset => 'Restablecer configuraciÃ³n de Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Borra cookies, TLS Impersonation=OFF, UA ExoPlayer por defecto';

  @override
  String get comingSoon => 'PrÃ³ximamente';

  @override
  String get confirmAndContinue => 'Confirmar y continuar';

  @override
  String get coverCacheCleared => 'CachÃ© de carÃ¡tulas purgado.';

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
  String get deleteAllConfirm => 'Â¿Eliminar todo?';

  @override
  String get deletePin => 'Eliminar el PIN';

  @override
  String get deleteProfileConfirm => 'Â¿Eliminar el perfil?';

  @override
  String get detailUnavailable => 'Detalle no disponible';

  @override
  String get diagnosticUnavailable => 'DiagnÃ³stico no disponible';

  @override
  String get dialogueBoost => 'Refuerzo de diÃ¡logos (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifica las voces frente a efectos/mÃºsica';

  @override
  String get disableSubtitles => 'Desactivar subtÃ­tulos';

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
  String get dnsSystem => 'AutomÃ¡tico (Sistema)';

  @override
  String downloadFailed(Object error) {
    return 'Descarga fallida: $error';
  }

  @override
  String get downloads => 'Descargas';

  @override
  String get dpadNavigation => 'NavegaciÃ³n con D-pad reforzada';

  @override
  String get dpadNavigationSubtitle =>
      'Foco visible, halo luminoso, ajuste de texto (modo TV)';

  @override
  String get enableParentalControl => 'Activar el control parental';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'En vivo: $live Â· VOD: $vod';
  }

  @override
  String get enginesTile => 'Motores de reproducciÃ³n';

  @override
  String get enterNew4DigitPin => 'Introduce un nuevo cÃ³digo de 4 dÃ­gitos';

  @override
  String get epgGrille => 'EPG (guÃ­a)';

  @override
  String get epgGuideTv => 'GuÃ­a TV (EPG)';

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
  String get exitWithoutSaving => 'Â¿Salir sin guardar?';

  @override
  String get failedToLoadProfiles => 'No se pudieron cargar los perfiles';

  @override
  String get fallbackEngine => 'Motor de Respaldo';

  @override
  String get favoriteGenres => 'GÃ©neros favoritos';

  @override
  String get filmsVod => 'PelÃ­culas (VOD)';

  @override
  String get firstName => 'Nombre';

  @override
  String get fontSize => 'TamaÃ±o de texto aumentado';

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
  String get instantZapping => 'Zapping instantÃ¡neo (precarga)';

  @override
  String get instantZappingSubtitle =>
      'Precarga los canales adyacentes en el bÃºfer';

  @override
  String get langArabic => 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©';

  @override
  String get langFrench => 'FranÃ§ais';

  @override
  String get langPortuguese => 'PortuguÃªs';

  @override
  String get langSpanish => 'EspaÃ±ol';

  @override
  String get language => 'Idioma';

  @override
  String get languageExample => 'FranÃ§ais, English, etc.';

  @override
  String get languagePreference => 'Idioma de la aplicaciÃ³n';

  @override
  String get languageUndetermined => 'Indeterminado';

  @override
  String get later => 'MÃ¡s tarde';

  @override
  String get legalNotice => 'Leer Â· Aviso legal';

  @override
  String get legalNoticeSubtitle =>
      'Uso de la app, titulares de derechos y privacidad';

  @override
  String get liveChannelsAndZapping => 'Canales en directo y Zapping';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'Registros y diagnÃ³stico';

  @override
  String get logsDiagnosticSubtitle => 'Ver registros, exportar, vaciar cachÃ©';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'URL de la playlist M3U';

  @override
  String get mainCast => 'Reparto principal';

  @override
  String get manualAvCalibration => 'CalibraciÃ³n A/V manual';

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
    return 'NÃºmero mÃ¡ximo de perfiles alcanzado ($max)';
  }

  @override
  String get memory => 'Memoria';

  @override
  String get moreResults => 'Ver mÃ¡s resultados';

  @override
  String get moviesUnavailable => 'PelÃ­culas no disponibles';

  @override
  String get multiScreen => 'Multi-pantalla';

  @override
  String get multiVideo => 'Multi-vÃ­deo';

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
  String get newAnd4K => 'PelÃ­culas a la carta';

  @override
  String get newProfile => 'Nuevo perfil';

  @override
  String get nextChannel => 'Canal siguiente';

  @override
  String get nightFocusEnable => 'Activar Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Procesamiento de audio en tiempo real: refuerzo de diÃ¡logos, corte de graves, sincronizaciÃ³n';

  @override
  String get nightFocusTitle => 'Night Focus (modo nocturno)';

  @override
  String get noAudioTrackDetected => 'No se detectÃ³ pista de audio';

  @override
  String get noChannelsAvailable => 'No hay canales disponibles';

  @override
  String get noChromecastDeviceFound =>
      'No se encontrÃ³ ningÃºn dispositivo Chromecast.';

  @override
  String get noDownloads => 'No hay descargas';

  @override
  String get noEpisodes => 'No hay episodios';

  @override
  String get noFavoriteChannels => 'No hay canales favoritos';

  @override
  String get noFavoriteMovies => 'No hay pelÃ­culas favoritas';

  @override
  String get noFavoriteReplays => 'No hay reemisiones favoritas';

  @override
  String get noFavoriteSeries => 'No hay series favoritas';

  @override
  String get noGroupAffinity => 'No se encontrÃ³ afinidad comÃºn';

  @override
  String get noHistory => 'No hay historial';

  @override
  String get noKidsChannels => 'No hay canales infantiles';

  @override
  String get noKidsMovies => 'No hay pelÃ­culas infantiles';

  @override
  String get noKidsReplays => 'No hay reemisiones infantiles';

  @override
  String get noKidsSeries => 'No hay series infantiles';

  @override
  String get noMoviesAvailable => 'No hay pelÃ­culas disponibles';

  @override
  String get noProfileAvailable => 'No hay perfil disponible';

  @override
  String get noProfilesYet => 'No hay perfiles aÃºn';

  @override
  String get noProgramInfoAvailable =>
      'No hay informaciÃ³n de programa disponible';

  @override
  String get noRankings => 'No hay clasificaciones';

  @override
  String get noRecommendations => 'No hay recomendaciones disponibles';

  @override
  String get noReplaysInCategory => 'No hay reemisiones en esta categorÃ­a';

  @override
  String noResultsFor(Object query) {
    return 'Sin resultados para $query';
  }

  @override
  String get noSeriesAvailable => 'No hay series disponibles';

  @override
  String get noStationsAvailable => 'No hay estaciones disponibles';

  @override
  String get noVideoQualityDetected => 'No se detectÃ³ calidad de vÃ­deo';

  @override
  String get notAvailableInCatalog => 'No disponible en el catÃ¡logo';

  @override
  String get offline => 'Sin conexiÃ³n';

  @override
  String get parentalControl => 'Control parental';

  @override
  String get parentalControlSubtitle =>
      'AÃ±adir un cÃ³digo PIN y restringir contenido';

  @override
  String get pauseDownload => 'Pausar';

  @override
  String get play => 'Reproducir';

  @override
  String get pinCode => 'CÃ³digo PIN';

  @override
  String get pinDeleted => 'PIN eliminado';

  @override
  String get pinMustBe4Digits => 'El PIN debe contener exactamente 4 dÃ­gitos';

  @override
  String get pinSaved => 'PIN guardado';

  @override
  String get pip => 'Ventana flotante (PiP)';

  @override
  String get pipUnavailable =>
      'Ventana flotante (PiP) no disponible en este dispositivo';

  @override
  String get playHistoryCleared => 'Historial de reproducciÃ³n borrado.';

  @override
  String plusAgeYears(Object age) {
    return '+$age aÃ±os';
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
  String get programGrid => 'GuÃ­a de programas';

  @override
  String get protectWithPin => 'Proteger con cÃ³digo PIN';

  @override
  String get rankingsUnavailable => 'Clasificaciones no disponibles';

  @override
  String get recentSearch => 'BÃºsqueda reciente';

  @override
  String get recentSearches => 'Recientes';

  @override
  String get recentlyWatched => 'Visto recientemente';

  @override
  String get removeAll => 'Retirar todo';

  @override
  String get removeFromWatchedConfirm => 'Â¿Retirar todo de vistos?';

  @override
  String get replaysUnavailable => 'Reemisiones no disponibles';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetApp => 'Restablecer aplicaciÃ³n';

  @override
  String get resetAppDialogBody =>
      'Se borrarÃ¡n todos los datos: perfiles, favoritos, historial, ajustes. Esta acciÃ³n es irreversible.';

  @override
  String get resetAppDialogConfirm => 'Borrar todo';

  @override
  String get resetAppDialogTitle => 'Â¿Restablecer la aplicaciÃ³n?';

  @override
  String get resetAppSubtitle =>
      'Borra todos los datos de usuario (perfiles, favoritos, historial)';

  @override
  String get resetCompleted => 'Restablecimiento completado';

  @override
  String get resumePlayback => 'Â¿Reanudar la reproducciÃ³n?';

  @override
  String get retry => 'Reintentar';

  @override
  String get retrySearch => 'Reintentar bÃºsqueda';

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
  String get searchError => 'Error de bÃºsqueda';

  @override
  String get searchMovie => 'Buscar una pelÃ­cula';

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
  String get sectionAntiThrottle => 'ProtecciÃ³n anti-limitaciÃ³n del ISP';

  @override
  String get sectionAudioNight => 'Audio y Night Focus';

  @override
  String get sectionAvSync => 'SincronizaciÃ³n A/V';

  @override
  String get sectionBackup => 'Copia de seguridad / RestauraciÃ³n';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get sectionCloudSync =>
      'SincronizaciÃ³n en la nube (multidispositivo)';

  @override
  String get sectionCloudflare => 'OptimizaciÃ³n Cloudflare';

  @override
  String get sectionDiagnostics => 'DiagnÃ³stico y mantenimiento';

  @override
  String get sectionEngines => 'Motores de reproducciÃ³n';

  @override
  String get sectionLegal => 'InformaciÃ³n legal';

  @override
  String get sectionMemory => 'Memoria y cachÃ©';

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
  String get settingsTitle => 'ConfiguraciÃ³n';

  @override
  String get similarMovies => 'PelÃ­culas similares';

  @override
  String get snackBackupExported => 'ConfiguraciÃ³n exportada al portapapeles';

  @override
  String get snackCacheCleared => 'CachÃ©s vaciadas';

  @override
  String get snackCloudflareReset =>
      'ConfiguraciÃ³n de Cloudflare restablecida';

  @override
  String snackImportError(String message) {
    return 'Error: $message';
  }

  @override
  String get snackImportSuccess => 'ConfiguraciÃ³n importada correctamente';

  @override
  String get snackNoBackup => 'No se encontrÃ³ ninguna copia';

  @override
  String get sortAffinity => 'Por afinidad';

  @override
  String get sortAffinityDescription =>
      'Ordena segÃºn tus gustos declarados en el perfil (matchmaking)';

  @override
  String get sortAscending => 'Orden ascendente';

  @override
  String get sortByDuration => 'Por duraciÃ³n';

  @override
  String get sortByRating => 'Por puntuaciÃ³n';

  @override
  String get sortByYear => 'Por aÃ±o';

  @override
  String get sortDescending => 'Orden descendente';

  @override
  String get sortLatestM3UXtream => 'Ãšltimos aÃ±adidos M3U/Xtream';

  @override
  String get sortNameAToZ => 'Nombre (A â†’ Z)';

  @override
  String get sortNameZToA => 'Nombre (Z â†’ A)';

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
  String get stopCasting => 'Detener la emisiÃ³n';

  @override
  String get streamDetails => 'Detalles del stream';

  @override
  String subtitleLoadError(Object error) {
    return 'Error al cargar subtÃ­tulo: $error';
  }

  @override
  String get subtitlesUnavailable => 'SubtÃ­tulos: no disponibles';

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
  String get unstableConnection => 'ConexiÃ³n inestable';

  @override
  String get updateAllData => 'Actualizar todos los datos';

  @override
  String get aiTopicsTitle => 'Temas recomendados por IA';

  @override
  String get updateThisCategory => 'Actualizar esta categorÃ­a';

  @override
  String get updating => 'Actualizandoâ€¦';

  @override
  String get updatingMediaContent => 'Actualizando contenido multimediaâ€¦';

  @override
  String get volumeNormalization => 'NormalizaciÃ³n del volumen';

  @override
  String get volumeNormalizationSubtitle =>
      'Limita los picos de volumen entre canales/programas (AGC)';

  @override
  String get watchLive => 'Ver en directo';

  @override
  String get whoIsWatching => 'Â¿QuiÃ©n ve?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Tus canales y contenidos';

  @override
  String get subtitleSection => 'SubtÃ­tulos';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'VÃ­deo';

  @override
  String get autoQuality => 'AutomÃ¡tico';

  @override
  String get noneOption => 'Ninguno';

  @override
  String get subtitleNotApplicable => 'No aplicable';

  @override
  String get subtitleNotApplicableInfo =>
      'Una emisiÃ³n en directo no publica ninguna pista de subtÃ­tulos.';

  @override
  String get subtitleUnavailable => 'No disponible';

  @override
  String get subtitleNoTrack => 'Sin pista';

  @override
  String get subtitleNoTrackInfo =>
      'El proveedor no publica subtÃ­tulos para este contenido.';

  @override
  String get subtitleGuessed => 'Pistas deducidas';

  @override
  String get subtitleGuessedInfo =>
      'El proveedor no declara sus subtÃ­tulos: estas pistas se obtienen por convenciÃ³n de URL. La que no exista seÃ±alarÃ¡ un error al activarla.';

  @override
  String get subtitleUnavailableToast => 'SubtÃ­tulo no disponible';

  @override
  String get audioTrackFallback => 'Pista de audio';

  @override
  String get subtitleLoading => 'Cargando subtÃ­tulosâ€¦';

  @override
  String get videoQualityFallback => 'Calidad de vÃ­deo';

  @override
  String get close => 'Cerrar';

  @override
  String get streamTracksError =>
      'No se pudieron leer las pistas de esta emisiÃ³n.';

  @override
  String get subtitleProviderNoAnswer => 'El proveedor no respondiÃ³.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'SubtÃ­tulo no disponible: $reason';
  }

  @override
  String get epgNoDataTitle => 'Sin datos de programaciÃ³n';

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
  String get epgNoCurrentProgram => 'NingÃºn programa en curso';

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
    return 'NingÃºn programa ya emitido dentro del archivo de $days dÃ­as de esta cuenta para este canal.';
  }

  @override
  String get replayNonePublished =>
      'El proveedor no publica ningÃºn programa ya emitido para este canal.';

  @override
  String get epgActionFavorite => 'Favorito';

  @override
  String get epgActionRecording => 'Grabar';

  @override
  String get epgActionReminder => 'Recordatorio';

  @override
  String get epgStartReplay => 'Iniciar replay';

  @override
  String get epgBack => 'AtrÃ¡s';

  @override
  String epgWatchChannel(Object name) {
    return 'Ver $name';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'El proveedor no sirve subtÃ­tulos para este contenido.';

  @override
  String subtitleVerifying(Object count) {
    return 'Comprobando subtÃ­tulosâ€¦ ($count)';
  }

  @override
  String get subtitleSearchOnline => 'Buscar en lÃ­nea';

  @override
  String get subtitleSearchOnlineInfo =>
      'El proveedor no ofrece nada para este contenido. Una bÃºsqueda en lÃ­nea puede encontrar un subtÃ­tulo.';

  @override
  String get subtitleSearchOnlineRunning => 'Buscandoâ€¦';

  @override
  String get subtitleOnlineResults => 'SubtÃ­tulos encontrados en lÃ­nea';

  @override
  String get subtitleOnlineEmpty =>
      'No se encontrÃ³ ningÃºn subtÃ­tulo en lÃ­nea para este contenido.';

  @override
  String subtitleOnlineDownloads(Object count) {
    return '$count descargas';
  }

  @override
  String get subtitleOnlineNoTmdb =>
      'No se pudo identificar este contenido en TMDB: la bÃºsqueda en lÃ­nea necesita su identificador.';

  @override
  String get opensubtitlesKeyLabel =>
      'BÃºsqueda de subtÃ­tulos en lÃ­nea (OpenSubtitles)';

  @override
  String get opensubtitlesKeyHint => 'Clave API â€” opcional';

  @override
  String get opensubtitlesKeyActive =>
      'Clave guardada: mayor cuota de descarga.';

  @override
  String get opensubtitlesKeyAnonymous =>
      'Sin clave: la bÃºsqueda funciona, 5 descargas por IP y 24 h.';

  @override
  String get opensubtitlesKeyDelete => 'Borrar la clave';

  @override
  String get opensubtitlesKeyCheck => 'Comprobar la clave';

  @override
  String get opensubtitlesKeyChecking => 'Comprobandoâ€¦';

  @override
  String get opensubtitlesKeyValid => 'Clave vÃ¡lida: el servicio la acepta.';

  @override
  String get opensubtitlesKeyRejected =>
      'Clave rechazada por el servicio: comprueba que la pegaste completa.';

  @override
  String get opensubtitlesKeyUnreachable =>
      'Servicio inaccesible: comprueba tu conexiÃ³n e intÃ©ntalo de nuevo.';

  @override
  String get opensubtitlesLoginLabel =>
      'ConexiÃ³n a la cuenta de OpenSubtitles';

  @override
  String get opensubtitlesLoginHintUsername => 'Usuario';

  @override
  String get opensubtitlesLoginHintPassword => 'ContraseÃ±a';

  @override
  String get opensubtitlesLoginActive =>
      'Cuenta guardada: las descargas podrÃ¡n conectarse.';

  @override
  String get opensubtitlesLoginNone =>
      'Sin cuenta: la descarga sigue rechazada (503).';

  @override
  String get opensubtitlesLoginDelete => 'Borrar la cuenta';

  @override
  String get opensubtitlesLoginConnect => 'Iniciar sesiÃ³n / comprobar';

  @override
  String get opensubtitlesLoginConnecting => 'Conectandoâ€¦';

  @override
  String get opensubtitlesLoginValid =>
      'Cuenta aceptada: el servicio emitiÃ³ un token.';

  @override
  String get opensubtitlesLoginRejected =>
      'Credenciales rechazadas: comprueba el usuario y la contraseÃ±a.';

  @override
  String get opensubtitlesLoginUnreachable =>
      'Servicio inaccesible: comprueba tu conexiÃ³n e intÃ©ntalo de nuevo.';

  @override
  String get subtitleOnlineNoApiKey =>
      'Falta la clave API de OpenSubtitles: introdÃºcela en Ajustes para activar la bÃºsqueda en lÃ­nea.';

  @override
  String get subtitleOnlineKeyRejected =>
      'Clave API de OpenSubtitles rechazada: estÃ¡ configurada, pero el servicio la rechaza. CompruÃ©bala en Ajustes.';

  @override
  String get subtitleOnlineQuota =>
      'Cuota de descarga de OpenSubtitles alcanzada hoy. IntÃ©ntalo maÃ±ana.';

  @override
  String get subtitleOnlineNeedsLogin =>
      'La descarga de OpenSubtitles requiere una cuenta conectada, no solo la clave API: la bÃºsqueda funciona, pero la descarga se rechaza.';

  @override
  String get favorites => 'Favoritos';

  @override
  String get films => 'PelÃ­culas';

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
      'AÃ±ade contenido desde la ficha de una pelÃ­cula o serie.';

  @override
  String get downloadsLocation => 'Archivos';

  @override
  String get advancedSettingsTitle => 'Ajustes avanzados';

  @override
  String get advancedSettingsIntro =>
      'Credenciales de API y ajustes de red. Estos ajustes comprometen tu cuenta con servicios de terceros: una clave compartida consume su cuota y un ajuste de red errÃ³neo puede impedir que la aplicaciÃ³n arranque.';

  @override
  String get advancedSubtitlesProvider => 'Proveedor de subtÃ­tulos';

  @override
  String get advancedStatus => 'Estado de las credenciales';

  @override
  String get advancedAccessTitle => 'Acceso restringido';

  @override
  String get advancedAccessHint => 'CÃ³digo';

  @override
  String get advancedAccessConfirm => 'Abrir';

  @override
  String get advancedAccessWrong => 'CÃ³digo incorrecto';

  @override
  String get advancedHiddenHint => 'MantÃ©n pulsado para los ajustes avanzados';

  @override
  String get favoritesAndDownloads => 'Favoritos y Descargas';

  @override
  String get activeAudio => 'Audio en esta pantalla';

  @override
  String get addChannel => 'AÃ±adir un canal';

  @override
  String get noChannelSelected => 'NingÃºn canal seleccionado';

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
