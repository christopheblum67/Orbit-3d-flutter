// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get castSearching => 'Buscando dispositivos Cast…';

  @override
  String get castReceiverNotReady => 'El receptor aún no está listo';

  @override
  String castConnectedTo(String name) {
    return 'Conectado a $name';
  }

  @override
  String castConnectionFailed(String name) {
    return 'No se pudo conectar a $name.';
  }

  @override
  String get playerPause => 'Pausa';

  @override
  String get playerNightFocusOn => 'Night Focus (activado)';

  @override
  String get playerNightFocusOff => 'Night Focus (desactivado)';

  @override
  String get playerLoadingProgram => 'Cargando programa…';

  @override
  String get audioNightHelp =>
      'La optimización de sonido se aplica al motor nativo cuando Night Focus está activado. Los ajustes se guardan para la próxima reproducción.';

  @override
  String get audioNightTitle => 'Optimización nocturna (Night Focus)';

  @override
  String get audioDialogueBoost => 'Realce de diálogos';

  @override
  String get audioDialogueHelp =>
      'Realza el rango de frecuencias de las voces (1–4 kHz)';

  @override
  String get audioBassLimiter => 'Reducción de graves y limitador';

  @override
  String get audioBassHelp =>
      'Atenúa los graves profundos y comprime los picos repentinos';

  @override
  String get audioVocalGain => 'Amplificación de voces:';

  @override
  String get audioSyncTitle => 'Desfase de audio (sincronización A/V)';

  @override
  String startupResumeQuestion(String title, String position) {
    return '¿Reanudar «$title» en $position?';
  }

  @override
  String get startupLastSession => 'Última sesión';

  @override
  String get seriesExternalTracksHint =>
      'Con un reproductor externo, elige el audio y los subtítulos en ese reproductor. Las preferencias siguientes se aplican al reproductor interno.';

  @override
  String seriesResetWatchedBody(int count, String title) {
    return 'Los $count episodios vistos de «$title» se marcarán como no vistos para este perfil.';
  }

  @override
  String seriesResetWatchedDone(String title) {
    return '«$title» se ha eliminado de los contenidos vistos.';
  }

  @override
  String get recommendationAffinity => 'Afinidad';

  @override
  String get recommendationLoadingCatalog => 'Cargando el catálogo…';

  @override
  String get recommendationBuilding => 'Preparando tus recomendaciones…';

  @override
  String get recommendationLoadingDuration =>
      'Esto puede tardar hasta 1 minuto.';

  @override
  String get memoryPanelTitle => 'Memoria y caché';

  @override
  String get memoryPanelHelp =>
      'Borra el historial y la caché de imágenes en memoria.';

  @override
  String get memoryHistoryTitle => 'Borrar historial de reproducción';

  @override
  String get memoryHistoryHelp =>
      'Borra el historial global y los elementos recientes antiguos, así como los contenidos recientes y las posiciones de reproducción del perfil actual.';

  @override
  String get memoryClear => 'Borrar';

  @override
  String get memoryImagesTitle => 'Vaciar caché de imágenes en memoria';

  @override
  String get memoryImagesHelp =>
      'Libera las imágenes guardadas en memoria; los archivos de caché en disco se conservan.';

  @override
  String get memoryPurge => 'Vaciar';

  @override
  String get sortOptionsTitle => 'Opciones de ordenación avanzada';

  @override
  String get sortOptionsHelp => 'Selecciona un modo con el mando:';

  @override
  String get sortRecentDescription => 'Contenidos importados recientemente';

  @override
  String get sortResumeDescription =>
      'Prioriza contenidos empezados sin terminar';

  @override
  String get sortRatingDescription => 'Ordenar según las valoraciones';

  @override
  String get sortYearDescription => 'Orden cronológico por año de producción';

  @override
  String get sortDurationDescription => 'Ordenar por duración';

  @override
  String get sortActive => 'Activo';

  @override
  String get onboardingWelcome => 'Te damos la bienvenida a Orbit IPTV';

  @override
  String get onboardingSubtitle => 'Configuración automática del dispositivo';

  @override
  String get onboardingDeviceDetected => 'Dispositivo detectado';

  @override
  String get onboardingDevice => 'Dispositivo';

  @override
  String get onboardingConnection => 'Conexión';

  @override
  String get onboardingMobileNetwork => 'Red móvil';

  @override
  String get onboardingOtherNetwork => 'Otra';

  @override
  String get onboardingUnknownMemory => 'Desconocida';

  @override
  String onboardingMemoryMb(String value) {
    return '$value MB';
  }

  @override
  String onboardingMemoryGb(String value) {
    return '$value GB';
  }

  @override
  String get onboardingEco => 'Ahorro';

  @override
  String onboardingProfile(String name) {
    return 'Perfil $name';
  }

  @override
  String get onboardingEcoDescription =>
      'Inicio rápido (1,5 s) · máx. 1080p · 3D y multivista desactivados';

  @override
  String get onboardingStandardDescription =>
      'Inicio rápido (2 s) · 3D fluido · multivista x2';

  @override
  String get onboardingUltraDescription =>
      'Cambio rápido de canal (3 s · 4K HDR posible) · multivista x4';

  @override
  String get onboardingResetRecommendation => 'Restablecer recomendación';

  @override
  String get onboardingAdjust => 'Ajustar manualmente';

  @override
  String get onboardingChooseProfile => 'Elige un perfil';

  @override
  String get onboardingRecommendedProfile => 'Perfil recomendado';

  @override
  String get onboardingEcoHint => 'Efectos 3D y multivista desactivados.';

  @override
  String get duoTitle => 'Modo Dúo';

  @override
  String duoChooseOthers(int max) {
    return 'Elige de 1 a $max perfiles adicionales';
  }

  @override
  String duoChooseWith(String name, int max) {
    return 'Con «$name»: elige de 1 a $max perfiles más';
  }

  @override
  String get duoCreateProfile => 'Crea al menos un segundo perfil';

  @override
  String get duoNeedsProfiles =>
      'El modo Dúo necesita al menos 2 perfiles en total.';

  @override
  String get duoFull => '4 perfiles: equipo completo para el Dúo';

  @override
  String duoReady(int count) {
    return '$count perfiles seleccionados: todo listo para el Dúo';
  }

  @override
  String duoSelectOne(int count) {
    return 'Selecciona al menos 1 perfil adicional ($count/4)';
  }

  @override
  String get duoStart => 'Iniciar Dúo';

  @override
  String get duoSelected => 'Seleccionado';

  @override
  String get duoMaximum => 'Máximo alcanzado';

  @override
  String get legalIntroTitle => 'Orbit IPTV · Léeme';

  @override
  String get legalIntro =>
      'Antes de empezar, aquí tienes información breve sobre el uso de esta aplicación y los derechos asociados a los contenidos mostrados.';

  @override
  String get legalServicePlayer =>
      'Orbit IPTV es un reproductor IPTV: muestra flujos proporcionados por servidores de terceros (suscripción M3U / Xtream Codes) sin alojar contenido de vídeo, audio ni subtítulos.';

  @override
  String get legalServiceMetadata =>
      'Agrupa y muestra metadatos (carteles, sinopsis, EPG) obtenidos mediante API públicas. Funciona como un navegador especializado en flujos HLS/DASH.';

  @override
  String get legalRightsProvider =>
      'El proveedor de la suscripción IPTV es el único responsable de las licencias de los canales, los derechos de emisión y el bloqueo geográfico de los flujos que proporciona.';

  @override
  String get legalRightsMetadata =>
      'Los carteles y las sinopsis proceden de TMDb bajo licencia de API; la atribución de TMDb aparece al pie de la página de clasificaciones.';

  @override
  String get legalRightsContent =>
      'Orbit IPTV no almacena, redistribuye ni monetiza contenido emitido.';

  @override
  String get legalUsageTitle => 'Uso de la aplicación';

  @override
  String get legalUsageRights =>
      'Utilízala solo con una suscripción para la que tengas derechos de emisión.';

  @override
  String get legalUsageRestrictions =>
      'Está prohibido eludir el bloqueo geográfico o los DRM y compartir la cuenta fuera del hogar.';

  @override
  String get legalUsageEditorial =>
      'La aplicación no realiza ninguna selección editorial del contenido emitido y no controla los flujos de servidores de terceros.';

  @override
  String get legalPrivacyStorage =>
      'Los perfiles, favoritos, el historial y los ajustes se almacenan localmente. Si activas el uso compartido en la nube, los datos seleccionados también se sincronizan de forma cifrada.';

  @override
  String get legalPrivacyConsent =>
      'No hay recopilación de datos por defecto; las notificaciones y los accesos opcionales requieren consentimiento explícito.';

  @override
  String get legalWarningTitle => 'Aviso';

  @override
  String get legalWarningBody =>
      'Este documento no constituye asesoramiento jurídico. Las normas varían según la jurisdicción: comprueba que tu uso está permitido en tu país (ley aplicable, edad mínima).';

  @override
  String get legalAccept => 'He leído y acepto · Continuar';

  @override
  String get epgReplayAvailableOnChannel => 'Replay disponible en este canal';

  @override
  String actorBornOn(String date) {
    return 'Nacimiento: $date';
  }

  @override
  String get actorGenderMale => 'Hombre';

  @override
  String get actorGenderFemale => 'Mujer';

  @override
  String get crewTitle => 'Equipo técnico';

  @override
  String get crewDirecting => 'Dirección';

  @override
  String get crewWriting => 'Guion';

  @override
  String get crewProduction => 'Producción';

  @override
  String get crewSound => 'Sonido';

  @override
  String get crewCamera => 'Cámara';

  @override
  String get crewEditing => 'Montaje';

  @override
  String get crewArt => 'Dirección artística';

  @override
  String get crewCostume => 'Vestuario y maquillaje';

  @override
  String get crewVisualEffects => 'Efectos visuales';

  @override
  String get crewLighting => 'Iluminación';

  @override
  String get menuContinue => 'Continuar';

  @override
  String get menuDiscover => 'Descubrir';

  @override
  String get menuHome => 'Inicio';

  @override
  String get menuSearch => 'Buscar';

  @override
  String get menuProfile => 'Perfil';

  @override
  String get menuSubscriptions => 'Suscripciones';

  @override
  String get menuSelect => 'Selecciona un submenú';

  @override
  String get menuContent => 'Contenidos';

  @override
  String get profileMustKeepOne =>
      'Debe quedar al menos un perfil en el dispositivo';

  @override
  String profileDeleteBody(String name) {
    return '«$name» y sus preferencias se eliminarán permanentemente. Esta acción no se puede deshacer.';
  }

  @override
  String get profileChange => 'Cambiar de perfil';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileDelete => 'Eliminar';

  @override
  String get profileBack => 'Volver';

  @override
  String get profileAdult => 'adulto';

  @override
  String get profileChild => 'infantil';

  @override
  String get profileExpert => 'experto';

  @override
  String get categoryTitle => 'Categorías';

  @override
  String get categoryShowAll => 'Mostrar todas';

  @override
  String get categoryScanFailed =>
      'No se pudo analizar: el proveedor no responde.';

  @override
  String get categoryEmptyLive =>
      'Este proveedor no tiene categorías de TV en directo.';

  @override
  String get categoryEmptyMovies =>
      'Este proveedor no tiene categorías de películas.';

  @override
  String get categoryEmptySeries =>
      'Este proveedor no tiene categorías de series.';

  @override
  String categoryHidden(String label, int count) {
    return '$label ($count ocultas)';
  }

  @override
  String get categoryNeverScanned => 'Sin analizar';

  @override
  String get categoryScannedToday => 'Analizado hoy';

  @override
  String get categoryScannedYesterday => 'Analizado ayer';

  @override
  String categoryScannedDaysAgo(int days) {
    return 'Analizado hace $days días';
  }

  @override
  String categorySubscriptionSettings(String status) {
    return 'Ajustes de esta suscripción — $status';
  }

  @override
  String get categoryScanning => 'Analizando…';

  @override
  String get categoryRescan => 'Volver a analizar categorías';

  @override
  String categoryChannelsCount(int count) {
    return '$count canales';
  }

  @override
  String categoryTitlesCount(int count) {
    return '$count títulos';
  }

  @override
  String get liveWatchAction => 'Ver';

  @override
  String get livePreviewDisabled =>
      'La vista previa de vídeo está desactivada. Pulsa Ver para abrir el canal.';

  @override
  String get livePreviewFrozen => 'Vista previa congelada';

  @override
  String get livePreviewRetry => 'Reintentar';

  @override
  String get episodeMarkWatchedFailed =>
      'No se pudo marcar este episodio como visto.';

  @override
  String get episodeAlreadyWatched => 'Episodio ya visto';

  @override
  String get episodeMarkWatched => 'Marcar como visto';

  @override
  String episodeResumeAt(String position) {
    return 'Continuar en $position';
  }

  @override
  String get episodeActionsHelp =>
      'Mantén pulsado OK para marcar como visto o restablecer.';

  @override
  String episodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodios',
      one: '1 episodio',
    );
    return '$_temp0';
  }

  @override
  String episodesInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodios en curso',
      one: '1 episodio en curso',
    );
    return '$_temp0';
  }

  @override
  String episodesWatchedCount(int seen, int total) {
    return '$seen/$total vistos';
  }

  @override
  String get episodeWatched => 'Visto';

  @override
  String get homeRefreshFailed =>
      'Error de actualización: ninguna fuente respondió.';

  @override
  String get homeRefreshDone => 'Actualización completada.';

  @override
  String get homeRefreshEmpty =>
      'Actualización completada; no hay datos disponibles.';

  @override
  String get homeChangeSubscription => 'Cambiar suscripción';

  @override
  String get homeManageSubscription => 'Gestionar suscripción';

  @override
  String get homeNoSubscription => 'Sin suscripción';

  @override
  String get homeAddOrChangeSubscription => 'Añadir o cambiar suscripción';

  @override
  String get homeMultiStream => 'Hasta 4 transmisiones a la vez';

  @override
  String get homeRadioStations => 'Emisoras en directo';

  @override
  String get homeRefreshUnknown => 'Última actualización desconocida';

  @override
  String homeRefreshMinutes(int minutes) {
    return 'Actualizado hace $minutes min';
  }

  @override
  String get catalogAll => 'Todos';

  @override
  String get catalogUngrouped => 'Sin grupo';

  @override
  String get catalogSort => 'Ordenar';

  @override
  String get browseLoading => 'Cargando…';

  @override
  String get startupRadio => 'Radios';

  @override
  String get profileCreateFirstHint =>
      'Crea tu primer perfil para empezar a ver contenido.';

  @override
  String downloadDirectoryMissing(String path) {
    return 'Directorio no encontrado: $path';
  }

  @override
  String downloadFileMissing(String path, String names) {
    return 'Archivo no encontrado: $path. Archivos presentes: $names';
  }

  @override
  String get widevineSelectSubscription => 'Selecciona una suscripción activa';

  @override
  String get widevineLoading => 'Cargando configuración';

  @override
  String get widevineLoadFailed => 'No se pudo cargar la configuración';

  @override
  String widevineNoLicense(String subscription) {
    return '$subscription: ninguna licencia configurada';
  }

  @override
  String get widevineSelectFirst =>
      'Selecciona primero una suscripción activa.';

  @override
  String get widevineUnavailable =>
      'La configuración de Widevine no está disponible.';

  @override
  String widevineSaveFailed(String error) {
    return 'No se pudo guardar Widevine: $error';
  }

  @override
  String widevineClearFailed(String error) {
    return 'No se pudo borrar Widevine: $error';
  }

  @override
  String get widevineLicenseUrl => 'URL del servidor de licencias';

  @override
  String get widevineInvalidUrl => 'Introduce una URL HTTPS válida.';

  @override
  String get widevineHeaders => 'Encabezados HTTP (JSON, opcional)';

  @override
  String get widevineInvalidHeaders =>
      'Los encabezados deben ser un objeto JSON de cadenas.';

  @override
  String get widevineCertificate => 'Certificado base64 (opcional)';

  @override
  String get widevineStorageHelp =>
      'La configuración se guarda de forma segura y está vinculada a esta suscripción. No hace compatible un reproductor que no admita Widevine.';

  @override
  String get widevineCopyLegacy => 'Copiar configuración global anterior';

  @override
  String get widevineClear => 'Borrar';

  @override
  String get preferenceMultiTvFailed =>
      'No se pudo guardar el ajuste de Multi TV.';

  @override
  String get preferenceLight => 'Claro';

  @override
  String get preferenceDark => 'Oscuro';

  @override
  String get preferenceDisabled => 'Desactivado';

  @override
  String preferenceParentalEnabled(String restriction) {
    return 'Activado · Restricción $restriction';
  }

  @override
  String get preferenceMultiTvHelp =>
      'Mostrar y permitir la reproducción multipantalla para este perfil.';

  @override
  String get preferenceAllowRecording => 'Permitir grabación';

  @override
  String get preferenceRecordingHelp =>
      'Permitir la grabación de mis contenidos favoritos';

  @override
  String get preferenceLivePreview => 'Vista previa de vídeo en directo';

  @override
  String get preferenceLivePreviewHelp =>
      'Muestra vídeo en directo al explorar canales. Este ajuste es común al dispositivo.';

  @override
  String get preferenceProfileHelp =>
      'Tus preferencias se aplican a tu perfil.';

  @override
  String get parentalAgeLimit => 'Restricción de edad';

  @override
  String get parentalNone => 'Ninguna';

  @override
  String get parentalHideAdult => 'Ocultar contenido para adultos';

  @override
  String get parentalHideAdultHelp =>
      'Películas, series y canales clasificados para mayores de 18 años o eróticos';

  @override
  String get parentalHideViolence => 'Ocultar violencia';

  @override
  String get parentalHideViolenceHelp =>
      'Contenido gore / terror / suspense / asesinato';

  @override
  String get parentalCurrentPin => 'PIN actual: ••••';

  @override
  String get parentalSetPin => 'Establecer un PIN';

  @override
  String get parentalNewPin => 'Nuevo PIN (4 dígitos)';

  @override
  String get parentalPin => 'PIN (4 dígitos)';

  @override
  String get parentalShowPin => 'Mostrar PIN';

  @override
  String get parentalHidePin => 'Ocultar PIN';

  @override
  String get parentalUpdatePin => 'Actualizar PIN';

  @override
  String get subtitleAvailableTracks => 'Pistas disponibles';

  @override
  String get subtitleAddUrl => 'Añadir subtítulos (URL .srt/.vtt)';

  @override
  String get subtitleLoadAction => 'Cargar';

  @override
  String subtitleTrackCues(String language, int count) {
    return '$language · $count segmentos';
  }

  @override
  String multiMaxStreams(int count) {
    return 'Máximo: $count transmisiones en este dispositivo.';
  }

  @override
  String get multiDisabledProfile =>
      'Multi TV está desactivado para este perfil. Actívalo en las preferencias del perfil.';

  @override
  String get multiAnalyzingDevice => 'Analizando el dispositivo…';

  @override
  String get multiDeviceAnalysisFailed => 'No se pudo analizar el dispositivo';

  @override
  String get multiDisabledEconomy =>
      'La multivista está desactivada por el perfil Económico.\nCambia el perfil en Configurar dispositivo.';

  @override
  String engineInternal(String name) {
    return '$name (Interno)';
  }

  @override
  String engineExternal(String name) {
    return '$name (Externo)';
  }

  @override
  String get engineSelectionHelp =>
      'Elige el reproductor para cada tipo de contenido y el reproductor alternativo si falla la reproducción.';

  @override
  String get engineVideoDecoding => 'Decodificación de vídeo';

  @override
  String get engineAutoRecommended => 'Auto (recomendado)';

  @override
  String get engineHardware => 'Hardware';

  @override
  String get engineSoftware => 'Software';

  @override
  String get engineAutoSoftware =>
      'Auto: software seleccionado para este dispositivo';

  @override
  String get engineSubtitleDefault => 'Predeterminado';

  @override
  String get engineSubtitleDisabled => 'Sin subtítulos';

  @override
  String get engineSubtitleForced => 'Subtítulos forzados';

  @override
  String get engineVodSubtitles => 'Subtítulos de películas y series';

  @override
  String get profilePinsNone => 'Ningún perfil tiene un PIN.';

  @override
  String get profilePinsRemoveQuestion => '¿Eliminar los PIN de los perfiles?';

  @override
  String profilePinsRemoveConfirmation(int count) {
    return 'Se eliminarán los PIN de $count perfil(es). Los perfiles y sus datos permanecerán en este dispositivo. Los cambios podrán sincronizarse con los dispositivos compartidos en la nube.';
  }

  @override
  String get profilePinsRemove => 'Eliminar PIN';

  @override
  String get profilePinsNothingToRemove => 'No hay PIN que eliminar.';

  @override
  String profilePinsRemoved(int count) {
    return 'PIN eliminados de $count perfil(es).';
  }

  @override
  String get profilePinsRemoveFailed =>
      'No se pudieron eliminar los PIN. Inténtalo de nuevo.';

  @override
  String get profilePinsLocked =>
      'Un perfil está bloqueado temporalmente tras tres PIN incorrectos. Espera a que termine el bloqueo antes de cambiar o eliminar su PIN.';

  @override
  String get profileProtection => 'Protección de perfiles';

  @override
  String get profilePinsRemoveHelp =>
      'Elimina los PIN de todos los perfiles de este dispositivo. No se eliminarán los perfiles ni sus datos.';

  @override
  String get profilePinsRemoving => 'Eliminando PIN…';

  @override
  String get profilePinsRemoveAll => 'Eliminar los PIN de los perfiles';

  @override
  String get radioEmptyHint => 'Añade emisoras de radio en los ajustes.';

  @override
  String get radioStations => 'Emisoras';

  @override
  String radioStationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count emisoras',
      one: '1 emisora',
    );
    return '$_temp0';
  }

  @override
  String get radioStreamUnavailable =>
      'La transmisión de esta emisora no está disponible';

  @override
  String get livePreviousCategory => 'Categoría anterior';

  @override
  String get liveNextCategory => 'Categoría siguiente';

  @override
  String get liveGuideUnavailable => 'Guía no disponible';

  @override
  String get liveNoPrograms => 'No hay programas disponibles';

  @override
  String get liveNoUpcomingPrograms => 'No hay próximos programas';

  @override
  String get liveNoDescription => 'No hay resumen disponible.';

  @override
  String get recommendationSubscriptionChanged =>
      'La suscripción ha cambiado. Empieza de nuevo.';

  @override
  String get recommendationCannotFavorite =>
      'Este contenido no se puede añadir a favoritos.';

  @override
  String get recommendationFavoriteFailed =>
      'No se pudo añadir este contenido a favoritos.';

  @override
  String get recommendationMovieQuestion => '¿Esta película te pertenece?';

  @override
  String get recommendationSeriesQuestion => '¿Esta serie te pertenece?';

  @override
  String get recommendationMovieSeen => 'Película ya vista';

  @override
  String get recommendationSeriesSeen => 'Serie ya vista';

  @override
  String get recommendationRemovedFuture =>
      'Se eliminará de las próximas sugerencias';

  @override
  String get recommendationNotInterested => 'No me interesa';

  @override
  String get recommendationExcluded =>
      'Se excluirá definitivamente de las sugerencias';

  @override
  String get recommendationFavoriteProfile =>
      'Se añadirá a los favoritos del perfil actual';

  @override
  String get startupParsingPlaylist => 'Analizando la lista M3U…';

  @override
  String get startupProviderSlow =>
      'El proveedor responde lentamente (puede estar realizando una comprobación de seguridad). Espera…';

  @override
  String get startupLoadingRemaining => 'Cargando radios y repeticiones';

  @override
  String get startupLoadingInitial =>
      'Cargando canales en directo, películas, series y guía de TV';

  @override
  String get startupCheckingSubscription => 'La comprobación de la suscripción';

  @override
  String get startupRefresh => 'La actualización';

  @override
  String startupStalled(String step, int seconds) {
    return '$step no muestra progreso desde hace $seconds segundos. El servidor puede estar lento o no disponible.';
  }

  @override
  String startupRefreshStalled(String step, int seconds) {
    return '$step no muestra progreso desde hace $seconds segundos. El servidor puede estar lento o no disponible; puedes comprobar la suscripción.';
  }

  @override
  String get startupMovies => 'Películas y VOD';

  @override
  String get startupLive => 'Canales en directo';

  @override
  String get startupReady => '¡Listo!';

  @override
  String get startupBackHome => 'Volver al inicio';

  @override
  String get startupCheckSubscription => 'Comprobar suscripción';

  @override
  String get browseRankings => 'Clasificaciones';

  @override
  String get browsePopularRankings => 'Clasificaciones populares';

  @override
  String get browseRankingsUnavailableHint =>
      'Las tendencias de TMDB no están disponibles. Añade una clave API de TMDB en Ajustes (o TMDB_API_KEY en assets/config/runtime.env).';

  @override
  String get browseTmdbData => 'Datos © TMDB';

  @override
  String get browsePopular => 'Popular';

  @override
  String get browseNowPlaying => 'En cartelera';

  @override
  String get browseTopRated => 'Mejor valorados';

  @override
  String get browseUpcoming => 'Próximamente';

  @override
  String get browseTrendingWeek => 'Tendencias de la semana';

  @override
  String get browseOnTheAir => 'En emisión';

  @override
  String get browseAiringToday => 'Emisión hoy';

  @override
  String get browseSeriesType => 'Serie';

  @override
  String get browseSynopsis => 'Sinopsis';

  @override
  String get browseNotInSubscription =>
      'Este título no está en tu suscripción activa. Descúbrelo en una de las plataformas indicadas por TMDB.';

  @override
  String get browseExploreCategories => 'Explorar por categoría';

  @override
  String get browseFavoriteHint =>
      'Mantén pulsado un elemento para encontrarlo aquí.';

  @override
  String get browseRecentHint => 'Los contenidos vistos aparecerán aquí.';

  @override
  String get browseSearchEmpty =>
      'Ningún contenido coincide con esta búsqueda.';

  @override
  String browseTitlesCount(int visible, int total) {
    return '$visible títulos (de $total)';
  }

  @override
  String get catalogSearchMovies => 'Buscar película o género…';

  @override
  String get catalogSearchSeries => 'Buscar serie o género…';

  @override
  String get catalogLoading => 'Cargando el catálogo…\nEspera unos segundos.';

  @override
  String get catalogNoMovies =>
      'La biblioteca de películas está vacía por ahora.';

  @override
  String get catalogNoSeries => 'La biblioteca de series está vacía por ahora.';

  @override
  String get catalogNoRecentMovies => 'No hay películas recientes';

  @override
  String get catalogNoRecentSeries => 'No hay series recientes';

  @override
  String get catalogNoResults => 'Sin resultados';

  @override
  String get catalogNoMoviesInCategory => 'No hay películas en esta categoría';

  @override
  String get catalogMovieFavoriteHint =>
      'Selecciona el corazón de una película para encontrarla aquí.';

  @override
  String get catalogSeriesFavoriteHint =>
      'Selecciona el corazón de una serie para encontrarla aquí.';

  @override
  String get catalogRecentMoviesHint => 'Las películas vistas aparecerán aquí.';

  @override
  String get catalogRecentSeriesHint => 'Las series vistas aparecerán aquí.';

  @override
  String get catalogMovieSearchEmpty =>
      'Ninguna película coincide con esta búsqueda.';

  @override
  String get catalogSeriesSearchEmpty =>
      'Ninguna serie coincide con esta búsqueda.';

  @override
  String get catalogMovieCategoryEmpty =>
      'Ninguna película coincide con esta categoría.';

  @override
  String removedFromFavorites(String title) {
    return '«$title» eliminado de favoritos';
  }

  @override
  String get liveBackToChannels => 'Volver a los canales';

  @override
  String get liveAddSourceHint => 'Añade una fuente de canales en los ajustes.';

  @override
  String get liveNoChannelFound => 'No se encontraron canales';

  @override
  String get liveNoRecentChannel => 'No hay canales recientes';

  @override
  String get liveNoChannelInGroup => 'No hay canales en este grupo';

  @override
  String get liveTryAnotherSearch => 'Prueba con otro término de búsqueda.';

  @override
  String get liveFavoriteHint =>
      'Selecciona el corazón de un canal para encontrarlo aquí.';

  @override
  String get liveRecentHint => 'Los canales vistos aparecerán aquí.';

  @override
  String get liveEmptyGroupHint => 'Este grupo no contiene canales.';

  @override
  String get liveLoadingHint =>
      'Cargando canales…\nEspera antes de iniciar una transmisión.';

  @override
  String get replayNoChannels =>
      'Ningún canal de esta suscripción indica que ofrezca contenido en diferido.';

  @override
  String get replayEmptyGroup =>
      'Este grupo no contiene canales con contenido en diferido.';

  @override
  String get epgLoadingBanner =>
      'Cargando la guía de TV… los programas aparecerán en breve.';

  @override
  String get epgNoChannelsInCategory => 'No hay canales en esta categoría';

  @override
  String get epgLoadingChannels => 'Cargando canales…';

  @override
  String get epgChannelsLoadFailed => 'No se pudieron cargar los canales.';

  @override
  String get replayToday => 'Hoy';

  @override
  String get replayYesterday => 'Ayer';

  @override
  String searchWithinHint(String type) {
    return 'Buscar en $type…';
  }

  @override
  String get searchAllHint =>
      'Buscar TV en directo, películas, series, replay y guía…';

  @override
  String get searchHint => 'Buscar…';

  @override
  String searchWithinTitle(String type) {
    return 'Buscar en $type';
  }

  @override
  String get searchUnifiedTitle => 'Búsqueda unificada';

  @override
  String searchWithinHelp(String type) {
    return 'Escribe para buscar solo en $type.';
  }

  @override
  String get searchUnifiedHelp =>
      'Busca canales en directo, películas, series, replays o programas de TV.';

  @override
  String get searchOffline => 'Modo sin conexión — solo resultados locales';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultsHelp =>
      'Prueba con otros términos o comprueba la ortografía.';

  @override
  String get searchAllCategories => 'Todas';

  @override
  String get searchClearHistory => 'Borrar historial';

  @override
  String get settingsPlaybackEngines => 'Motores de reproducción';

  @override
  String get settingsCloudAccount => 'Cuenta en la nube';

  @override
  String get settingsCloudSignIn => 'Acceso con Google o correo';

  @override
  String get settingsSyncUnavailable => 'Sincronización completa no disponible';

  @override
  String get settingsSyncUnavailableHelp =>
      'La antigua sincronización sin cifrar está desactivada. Los perfiles se pueden guardar manualmente desde Cuenta en la nube; los demás datos no se sincronizan.';

  @override
  String get settingsSystemAutomatic => 'Automático (sistema)';

  @override
  String get settingsSubtitleDefault => 'Subtítulos predeterminados';

  @override
  String get settingsSubtitleForced => 'Subtítulos forzados';

  @override
  String get settingsSubtitleOff => 'Sin subtítulos';

  @override
  String get settingsSubtitles => 'Subtítulos';

  @override
  String get settingsProtectedPlayback => 'Reproducción protegida';

  @override
  String get settingsCategoryFilters => 'Filtros de categorías';

  @override
  String get settingsCategoryFiltersHelp =>
      'Categorías ocultas por suscripción';

  @override
  String get episodeSelectProfile =>
      'Selecciona un perfil para modificar este episodio.';

  @override
  String get episodeProfileChanged =>
      'El perfil ha cambiado. Inténtalo de nuevo.';

  @override
  String get episodeStatusFailed =>
      'No se pudo cambiar el estado de este episodio.';

  @override
  String get episodeResetQuestion => '¿Restablecer episodio?';

  @override
  String get episodeMarkWatchedQuestion => '¿Marcar como visto?';

  @override
  String episodeResetProgressMessage(String title) {
    return '«$title» se marcará como no visto y se borrará su progreso de reproducción.';
  }

  @override
  String episodeMarkUnwatchedMessage(String title) {
    return '«$title» se marcará como no visto para este perfil.';
  }

  @override
  String episodeMarkWatchedMessage(String title) {
    return '«$title» se marcará como visto para este perfil.';
  }

  @override
  String get episodeMarkUnwatched => 'Marcar como no visto';

  @override
  String get detailAiData => 'Datos generados por IA';

  @override
  String detailSourceData(String source) {
    return 'Datos de $source';
  }

  @override
  String get detailUnavailableValue => 'No disponible';

  @override
  String get detailKeywords => 'Palabras clave';

  @override
  String get detailGenres => 'Géneros';

  @override
  String get detailCast => 'Reparto';

  @override
  String get detailTrailerFailed => 'No se pudo abrir el tráiler';

  @override
  String get detailShowCrew => 'Mostrar equipo técnico';

  @override
  String get detailHideCrew => 'Ocultar equipo técnico';

  @override
  String seriesRuntimePerEpisode(int minutes) {
    return '$minutes min/episodio';
  }

  @override
  String seriesNetwork(String network) {
    return 'Cadena: $network';
  }

  @override
  String seriesFirstAired(String date) {
    return 'Primera emisión: $date';
  }

  @override
  String seriesSeasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas',
      one: '1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get profileDiscardHelp =>
      'Se perderán los cambios sin guardar. ¿Salir de todos modos?';

  @override
  String get profileLeave => 'Salir';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileAvatarTheme => 'Tema del avatar';

  @override
  String get profileAvatarThemeHelp =>
      'Elige un estilo y después un avatar de la cuadrícula';

  @override
  String get profileAvatars => 'Avatares';

  @override
  String profileCurrentTheme(String theme) {
    return 'Tema actual: $theme';
  }

  @override
  String get profileRequired => 'Obligatorio';

  @override
  String get profileFavoriteMovieGenres => 'Géneros de películas favoritos';

  @override
  String get profileGenresHelp =>
      'Elige uno o más estilos para las recomendaciones';

  @override
  String get profilePinMismatch => 'Los PIN no coinciden.';

  @override
  String get profilePinCreateFailed => 'No se pudo crear el PIN.';

  @override
  String get profilePinActive => 'Hay un PIN de 4 dígitos activo';

  @override
  String get profilePinPending =>
      'PIN confirmado. Guarda el perfil para activarlo.';

  @override
  String get profilePinRequest => 'Solicitar un PIN al seleccionar el perfil';

  @override
  String get profilePinCreating => 'Creando PIN…';

  @override
  String get profileNotFound => 'No hay ningún perfil para editar';

  @override
  String get profileSaveActivate => 'Guardar y activar la protección';

  @override
  String get profileCreateActivate => 'Crear perfil y activar la protección';

  @override
  String get profileSaveAction => 'Guardar';

  @override
  String get profileCreateAction => 'Crear perfil';

  @override
  String get genreAction => 'Acción';

  @override
  String get genreAdventure => 'Aventura';

  @override
  String get genreAnimation => 'Animación';

  @override
  String get genreComedy => 'Comedia';

  @override
  String get genreRomanticComedy => 'Comedia romántica';

  @override
  String get genreDrama => 'Drama';

  @override
  String get genreHorror => 'Terror';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreDetective => 'Policíaco';

  @override
  String get genreCrime => 'Crimen';

  @override
  String get genreWar => 'Bélico';

  @override
  String get genreHistorical => 'Histórico';

  @override
  String get genreWestern => 'Western';

  @override
  String get genreSciFi => 'Ciencia ficción';

  @override
  String get genreFantasy => 'Fantasía';

  @override
  String get genreSuperheroes => 'Superhéroes';

  @override
  String get genreMystery => 'Misterio';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreMusical => 'Musical';

  @override
  String get genreMusic => 'Música';

  @override
  String get genreBiopic => 'Biografía';

  @override
  String get genreDocumentary => 'Documental';

  @override
  String get genreTournament => 'Torneo';

  @override
  String get genreChildren => 'Infantil';

  @override
  String get genreFamily => 'Familiar';

  @override
  String get genreSuspense => 'Suspense';

  @override
  String get genreBlackWhite => 'Blanco y negro';

  @override
  String get genreClassic => 'Clásico';

  @override
  String get cloudConfirm => 'Confirmar';

  @override
  String get cloudShareProfilesTitle => '¿Compartir estos perfiles?';

  @override
  String cloudDuplicateProfileId(String id) {
    return 'Mismo nombre — identificador: $id';
  }

  @override
  String get cloudShareProfilesHelp =>
      'Los perfiles que falten se añadirán sin reemplazar los existentes. Se compartirán sus favoritos y actividad, así como preferencias y suscripciones, incluidas las credenciales IPTV. Estos datos están cifrados.\n\nLos perfiles con el mismo nombre permanecen separados. Si hay diferencias, elegirás qué datos conservar.';

  @override
  String get cloudChooseSourceTitle => 'Elegir el origen en caso de conflicto';

  @override
  String get cloudChooseSourceHelp =>
      'Las adiciones diferentes se combinarán en ambos dispositivos. Si un mismo dato cambió en ambos lados, se conservará el origen elegido aquí y se enviará al otro dispositivo. Esta elección se aplica a todos los conflictos iniciales.';

  @override
  String get cloudSourceLocal => 'Usar este dispositivo como origen';

  @override
  String get cloudSourceRemote => 'Usar la nube como origen';

  @override
  String get cloudResetTitle => '¿Empezar de cero en la nube?';

  @override
  String get cloudResetHelp =>
      'Se eliminarán de la nube todos los perfiles y sus datos compartidos. Los perfiles locales se conservarán. Los demás dispositivos deberán introducir el nuevo código. Esta acción es irreversible.';

  @override
  String get cloudNewCode => 'Nuevo código';

  @override
  String get cloudConfirmCode => 'Confirmar código';

  @override
  String get cloudResetCodeError =>
      'Introduce un código nuevo de 3 a 10 dígitos y confírmalo exactamente.';

  @override
  String get cloudRestoreTitle => '¿Recuperar este perfil?';

  @override
  String cloudRestoreHelp(String name) {
    return 'Se añadirá el perfil de $name sin reemplazar los perfiles locales. No se restaurarán favoritos, historiales, suscripciones ni preferencias.';
  }

  @override
  String cloudDeleteTitle(String name) {
    return '¿Eliminar a $name de la nube?';
  }

  @override
  String get cloudDeleteHelp =>
      'El perfil y sus datos sincronizados se eliminarán de la nube. El perfil local de este dispositivo no se eliminará. Los demás dispositivos quedarán en pausa y deberán actualizar su lista.';

  @override
  String get cloudSyncFinished => 'Sincronización terminada';

  @override
  String get cloudSyncFinishedHelp =>
      'Los perfiles seleccionados y sus datos se han sincronizado con la nube.';

  @override
  String get cloudResolveTitle => '¿Resolver el conflicto?';

  @override
  String get cloudResolveLocalHelp =>
      'Para los elementos en conflicto de esta categoría se conservará la versión de este dispositivo. La otra versión, incluida cualquier eliminación, se sobrescribirá.';

  @override
  String get cloudResolveRemoteHelp =>
      'Para los elementos en conflicto de esta categoría se conservará la versión de la nube. La otra versión, incluida cualquier eliminación, se sobrescribirá.';

  @override
  String get cloudProfilesTitle => 'Mis perfiles en mis dispositivos';

  @override
  String get cloudSignInToContinue =>
      'Inicia sesión en una cuenta de la nube para continuar.';

  @override
  String get cloudFirebaseUnavailable =>
      'Firebase no está disponible en este dispositivo.';

  @override
  String get cloudGoogleCanceled =>
      'El inicio de sesión con Google se canceló o falló. Si el problema continúa, comprueba la configuración de Google de esta aplicación.';

  @override
  String get cloudGoogleConfiguration =>
      'Configuración de Google incorrecta: comprueba el cliente OAuth y la firma de esta aplicación.';

  @override
  String get cloudGoogleUnavailable =>
      'El inicio de sesión con Google no está disponible en este dispositivo.';

  @override
  String get cloudSignInUnavailable =>
      'El servicio de inicio de sesión no está disponible en este dispositivo.';

  @override
  String get cloudSignInRetry =>
      'No se puede iniciar sesión. Inténtalo de nuevo.';

  @override
  String get cloudInvalidEmail => 'Dirección de correo electrónico no válida.';

  @override
  String get cloudWeakPassword => 'La contraseña es demasiado débil.';

  @override
  String get cloudEmailInUse => 'Esta dirección ya está en uso.';

  @override
  String get cloudInvalidCredentials =>
      'Correo electrónico o contraseña incorrectos.';

  @override
  String get cloudNetworkUnavailable => 'Conexión de red no disponible.';

  @override
  String get cloudTooManyAttempts =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get cloudMethodDisabled =>
      'Este método de inicio de sesión no está activado.';

  @override
  String get cloudGoogleAlreadyLinked =>
      'Esta cuenta ya está vinculada a Google.';

  @override
  String get cloudGoogleOtherAccount =>
      'Esta cuenta de Google ya está asociada a otra cuenta de Firebase. No se han fusionado cuentas ni datos. Para usar la otra cuenta, cierra sesión e inicia sesión con Google.';

  @override
  String get cloudFirebaseSignInFailed =>
      'No se puede iniciar sesión. Inténtalo de nuevo o comprueba la configuración de Firebase.';

  @override
  String get cloudAccountIntro =>
      'Inicia sesión para acceder a tus perfiles y sus datos en tus dispositivos. Tus datos están cifrados.';

  @override
  String get cloudAccountLinkHelp =>
      'Si ya hay una cuenta conectada, Google se vinculará a ella sin cambiar su identificador. Las cuentas distintas no se fusionan.';

  @override
  String get cloudAccountStateError =>
      'No se puede leer el estado de la cuenta.';

  @override
  String get cloudAccountChecking => 'Comprobando cuenta…';

  @override
  String get cloudAccountNone => 'No hay ninguna cuenta de la nube conectada.';

  @override
  String get cloudPairingCleanupFailed =>
      'Cuenta vinculada, pero falló la limpieza de la sesión temporal.';

  @override
  String get cloudPairTv => 'Vincular una TV mediante código QR';

  @override
  String get pairSignOutFirst =>
      'Cierra la sesión de la cuenta en la nube antes de vincular.';

  @override
  String get pairScannerAccountChanged =>
      'La cuenta de la nube ha cambiado. Cierra esta pantalla y empieza de nuevo.';

  @override
  String get pairScannerAccountCheckFailed =>
      'No se pudo verificar la cuenta de la nube.';

  @override
  String get pairScannerCameraFailed => 'No se pudo usar la cámara.';

  @override
  String get pairScannerInvalidQr =>
      'Este código QR no corresponde a una sesión de Orbit 3D.';

  @override
  String get pairScannerAssociationFailed =>
      'No se pudo vincular. Comprueba la red o crea otro código QR en la TV.';

  @override
  String get pairScannerTitle => 'Vincular una TV';

  @override
  String get pairScannerSent =>
      'Solicitud enviada. Confirma la cuenta mostrada en la TV.';

  @override
  String get pairScannerCameraPermission =>
      'Cámara no disponible. Permite el acceso en los ajustes.';

  @override
  String get pairScannerCompareCode =>
      'Compara este código con el que aparece en la TV:';

  @override
  String get pairScannerVerifyWarning =>
      'Acepta solo si ambos códigos coinciden y controlas la TV.';

  @override
  String pairScannerSelectedProfiles(String profiles) {
    return 'La TV seleccionará automáticamente: $profiles.';
  }

  @override
  String get pairScannerConfirm => 'Confirmar y vincular';

  @override
  String get pairScannerRescan => 'Escanear de nuevo';

  @override
  String get pairTemporaryUnavailable =>
      'La sesión temporal no está disponible.';

  @override
  String get pairCleanupIncomplete =>
      'Limpieza incompleta: la sesión caducará automáticamente.';

  @override
  String get pairCleanupFailed =>
      'No se pudo limpiar: la sesión caducará automáticamente.';

  @override
  String get pairUnavailable =>
      'Vinculación no disponible. Comprueba la red y la configuración de Firebase.';

  @override
  String get pairRestart => 'Vuelve a iniciar la vinculación.';

  @override
  String get pairTvTitle => 'Vincular esta TV';

  @override
  String get pairInstructions =>
      'En el teléfono conectado, abre la sincronización cifrada y escanea este código QR. Compara los códigos mostrados antes de confirmar.';

  @override
  String get pairCreateQr => 'Crear un código QR';

  @override
  String pairVerificationCode(String code) {
    return 'Código de verificación: $code';
  }

  @override
  String get pairExpires => 'El código QR caduca después de cinco minutos.';

  @override
  String pairAccount(String account) {
    return 'Cuenta para vincular: $account';
  }

  @override
  String get pairConfirmAccount => 'Confirmar esta cuenta';

  @override
  String get pairWaiting => 'Esperando la confirmación en el teléfono…';

  @override
  String get cloudTemporaryAccount =>
      'Hay una cuenta temporal conectada en este dispositivo.';

  @override
  String cloudAccountConnected(String account) {
    return 'Cuenta conectada: $account';
  }

  @override
  String get cloudRecoverProfiles =>
      'Encontrar mis perfiles en mis dispositivos';

  @override
  String get cloudEmail => 'Correo electrónico';

  @override
  String get cloudSignIn => 'Iniciar sesión';

  @override
  String get cloudCreateAccount => 'Crear una cuenta';

  @override
  String get cloudResetEmailSent =>
      'Si la cuenta existe, puede enviarse un correo para restablecer la contraseña.';

  @override
  String get cloudForgotPassword => 'He olvidado mi contraseña';

  @override
  String get cloudGoogleLinked => 'Cuenta de Google ya vinculada';

  @override
  String get cloudSignInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get cloudLinkGoogle => 'Vincular una cuenta de Google';

  @override
  String get cloudSignOut => 'Cerrar sesión';

  @override
  String get cloudPrepareCodeHelp =>
      'Un adulto prepara el código. Después, elige los perfiles que compartirás.';

  @override
  String get cloudChooseProfilesHelp =>
      'Marca los perfiles que quieres en tus dispositivos y pulsa Compartir.';

  @override
  String get cloudFirstSyncHelp =>
      'La primera actualización puede tardar más de 10 minutos. Mantén Orbit abierto hasta que termine.';

  @override
  String get cloudLegacyPhrase => 'Frase secreta (formato anterior)';

  @override
  String get cloudAdultCode => 'Código proporcionado por un adulto';

  @override
  String get cloudSamePhraseHelp =>
      'Introduce la misma frase en ambos dispositivos.';

  @override
  String get cloudSameCodeHelp =>
      'Introduce el mismo código en ambos dispositivos.';

  @override
  String get cloudShowPhrase => 'Mostrar frase secreta';

  @override
  String get cloudHidePhrase => 'Ocultar frase secreta';

  @override
  String get cloudShowCode => 'Mostrar código de la nube';

  @override
  String get cloudHideCode => 'Ocultar código de la nube';

  @override
  String get cloudSeeProfiles => 'Ver mis perfiles';

  @override
  String get cloudRefreshList => 'Actualizar lista';

  @override
  String get cloudAdultOptions => 'Opciones para adultos';

  @override
  String get cloudUseLegacyPhrase => 'Usar una frase secreta antigua';

  @override
  String get cloudResetAction => 'Eliminar toda la nube y empezar de cero';

  @override
  String get cloudShareBeforePairing =>
      'Comparte primero los perfiles seleccionados para que estén disponibles en la TV.';

  @override
  String get cloudConfirmYourCode => 'Confirma tu código';

  @override
  String get cloudBackupTitle => '¿Guardar este perfil?';

  @override
  String cloudConfirmProfilesHelp(String name) {
    return 'Confirma tu código para los perfiles $name. Guárdalo en un lugar seguro: sin él no podrás recuperar tus datos.';
  }

  @override
  String cloudBackupHelp(String name) {
    return 'Solo se guardará el perfil de $name, cifrado. No se incluyen favoritos, historiales, suscripciones ni preferencias. Si pierdes el secreto, no podrás recuperar la copia.';
  }

  @override
  String get cloudConfirmPhrase => 'Confirmar frase secreta';

  @override
  String get cloudConfirmCloudCode => 'Confirmar código de la nube';

  @override
  String get cloudShowConfirmation => 'Mostrar confirmación';

  @override
  String get cloudHideConfirmation => 'Ocultar confirmación';

  @override
  String get cloudSecretsMismatch => 'Los secretos no coinciden.';

  @override
  String get cloudSyncProfileTitle => '¿Sincronizar este perfil?';

  @override
  String get cloudSyncProfileHelp =>
      'El perfil activo, sus favoritos de vídeo y radio, historiales recientes, episodios vistos y posiciones de reproducción, así como preferencias y suscripciones, se sincronizarán de forma cifrada durante esta sesión. Se incluyen las credenciales IPTV. La suscripción activa se elige en cada dispositivo.';

  @override
  String get cloudUpdating => 'Actualizando…';

  @override
  String get cloudAdultMustChoose =>
      'Un adulto debe elegir qué datos conservar.';

  @override
  String get cloudSharingEnabled => 'La compartición está activada.';

  @override
  String get cloudKeepOpen =>
      'Esto puede tardar más de 10 minutos. Mantén Orbit abierto.';

  @override
  String get cloudAutoSharing => 'Los cambios se comparten automáticamente.';

  @override
  String get cloudConflictHelp =>
      'Este dispositivo y el otro no coinciden. Pide a un adulto que elija la versión correcta.';

  @override
  String get cloudKeepLocal => 'Conservar los datos de este dispositivo';

  @override
  String get cloudKeepRemote => 'Conservar los datos del otro dispositivo';

  @override
  String get cloudShareSettings => 'Ajustes de compartición (adulto)';

  @override
  String get cloudUpdateNow => 'Actualizar ahora';

  @override
  String get cloudPause => 'Pausar';

  @override
  String get cloudSelectProfiles => 'Elige los perfiles que compartir';

  @override
  String get cloudWhichProfiles => '¿Qué perfiles quieres en tus dispositivos?';

  @override
  String get cloudLocalProfilesUnavailable =>
      'Los perfiles locales no están disponibles.';

  @override
  String get cloudUnselectAll => 'Desmarcar todo';

  @override
  String get cloudSelectAll => 'Marcar todo';

  @override
  String get cloudShareSelected => 'Compartir perfiles seleccionados';

  @override
  String get cloudShareAll => 'Compartir todos los perfiles';

  @override
  String get cloudProfilesToAdd => 'Perfiles que añadir';

  @override
  String get cloudOtherOptions => 'Otras opciones (adulto)';

  @override
  String get cloudShareActiveOnly => 'Compartir solo el perfil activo';

  @override
  String get cloudLocalProfileKept => 'Se conserva el perfil local.';

  @override
  String get cloudRecover => 'Recuperar';

  @override
  String get cloudDeleteAction => 'Eliminar de la nube';

  @override
  String get cloudBackupAction => 'Guardar';

  @override
  String get cloudScopeFavorites => 'favoritos';

  @override
  String get cloudScopeRadioFavorites => 'favoritos de radio';

  @override
  String get cloudScopeRecents => 'historial reciente';

  @override
  String get cloudScopeWatched => 'episodios vistos';

  @override
  String get cloudScopePlayback => 'posiciones de reproducción';

  @override
  String get cloudScopePreferences => 'preferencias generales';

  @override
  String get cloudScopeProfile => 'datos del perfil';

  @override
  String get cloudProfileFallback => 'perfil';

  @override
  String get cloudScopeSubscriptions => 'suscripciones';

  @override
  String get cloudScopeData => 'datos';

  @override
  String cloudProgressPercent(int percent) {
    return 'Completado: $percent %';
  }

  @override
  String cloudProgressScope(String scope) {
    return 'Ahora: $scope.';
  }

  @override
  String cloudProgressProfile(String scope, String profile) {
    return 'Ahora: $scope — $profile.';
  }

  @override
  String cloudConflictProfile(String name, String id) {
    return 'Perfil en conflicto: $name ($id)';
  }

  @override
  String cloudConflictData(String scope) {
    return 'Datos: $scope';
  }

  @override
  String get cloudChangedElsewhere =>
      'La nube cambió en otro lugar. Recarga antes de volver a intentarlo.';

  @override
  String get cloudBadPhrase =>
      'Frase secreta incorrecta o datos de la nube dañados.';

  @override
  String get cloudBadCode =>
      'Código de la nube incorrecto o datos de la nube dañados.';

  @override
  String get cloudAccessFailed =>
      'No se puede acceder a la nube. Comprueba la red y la configuración de Firebase.';

  @override
  String get cloudInvalidData =>
      'Datos de la nube inválidos o incompatibles; no se ha restaurado nada.';

  @override
  String get cloudOperationFailed =>
      'Operación fallida. Comprueba la red y actualiza la nube.';

  @override
  String get cloudAskAdult => 'Pide el código a un adulto.';

  @override
  String get cloudCodeLength => 'El código debe contener de 3 a 10 dígitos.';

  @override
  String get cloudAccountChanged =>
      'La cuenta o el secreto han cambiado. Empieza de nuevo.';

  @override
  String get cloudPhraseChanged =>
      'La cuenta o la frase han cambiado. Empieza de nuevo.';

  @override
  String get cloudBackupRefreshed => 'Perfil guardado. Catálogo actualizado.';

  @override
  String get cloudAccessEmpty =>
      'Acceso confirmado. No hay perfiles guardados.';

  @override
  String get cloudCodeUnverified =>
      'No se encontró ninguna copia: todavía no se puede verificar tu código.';

  @override
  String get cloudAccessChoose =>
      'Acceso confirmado. Elige los perfiles que compartirás.';

  @override
  String get cloudBackupRefreshFailed =>
      'Perfil guardado, pero no se pudo actualizar el catálogo.';

  @override
  String get cloudPhoneProfilesMissing =>
      'Los perfiles seleccionados en el teléfono ya no están disponibles. Actualiza la lista y vuelve a seleccionarlos.';

  @override
  String get cloudPhoneProfilesReceived =>
      'Perfiles recibidos del teléfono. Iniciando la compartición…';

  @override
  String get cloudProfileRestored =>
      'Perfil recuperado. Selecciónalo en la aplicación y vuelve aquí para activar su sincronización.';

  @override
  String get cloudWaitDelete =>
      'Espera a que termine la sincronización antes de eliminar.';

  @override
  String get cloudWaitReset =>
      'Espera a que termine la sincronización antes de restablecer.';

  @override
  String get cloudResetComplete =>
      'Nube restablecida. El nuevo código está activo; los perfiles locales se han conservado.';

  @override
  String get cloudWaitSelection =>
      'Hay una sincronización en curso. Espera a que termine antes de cambiar la selección.';

  @override
  String get cloudProfilesChanged =>
      'Los perfiles han cambiado. Comprueba tu selección.';

  @override
  String get cloudRestoredProfileMissing =>
      'No se encontró un perfil recuperado. Inténtalo de nuevo.';

  @override
  String cloudRestoringProfiles(int current, int total) {
    return 'Recuperando perfiles: $current / $total.';
  }

  @override
  String get cloudCheckingProfiles =>
      'Comprobando y guardando perfiles de la nube.';

  @override
  String get cloudPartialRestore =>
      'Es posible que se hayan recuperado algunos perfiles. Comprueba la lista antes de volver a intentarlo.';

  @override
  String get cloudStartingSync => 'Iniciando la sincronización.';

  @override
  String get cloudProfilesBackedUp => 'Los perfiles se han guardado.';

  @override
  String get subscriptionTitle => 'Suscripciones';

  @override
  String get subscriptionRefreshSuccess =>
      'Actualización terminada: se actualizó al menos una fuente.';

  @override
  String get subscriptionRefreshFailed =>
      'Actualización fallida: no se recibieron datos.';

  @override
  String get subscriptionConnectionHelp =>
      'La conexión falló o se rechazaron las credenciales. Comprueba la dirección del servidor, el usuario, la contraseña y la conexión a Internet.';

  @override
  String get subscriptionDuplicateHelp =>
      'Posible duplicado: varias suscripciones tienen la misma configuración. No se ha eliminado ninguna; sus favoritos pueden ser distintos.';

  @override
  String get subscriptionRefreshActive =>
      'Forzar actualización de la suscripción activa';

  @override
  String get subscriptionActivationFailed =>
      'No se pudo activar la suscripción.';

  @override
  String get subscriptionDeleteTitle => '¿Eliminar la suscripción?';

  @override
  String subscriptionDeleteHelp(String name) {
    return '¿Eliminar «$name»? Esta acción es irreversible.';
  }

  @override
  String get subscriptionNoActive =>
      'No hay suscripción activa. Selecciona una o añade una nueva.';

  @override
  String get subscriptionActivate => 'Activar';

  @override
  String get subscriptionNone => 'No hay suscripciones';

  @override
  String get subscriptionEmptyHelp =>
      'Añade tu primera suscripción Xtream Codes o M3U para empezar.';

  @override
  String get subscriptionFilterHelp =>
      'Las categorías que ocultar se configuran en Configuración > Accesibilidad > Filtros de categorías.';

  @override
  String get subscriptionPossibleDuplicate => 'Posible duplicado';

  @override
  String get subscriptionInactive => 'Inactiva';

  @override
  String get subscriptionTesting => 'Probando…';

  @override
  String get subscriptionUntested => 'Sin probar';

  @override
  String get subscriptionTestOk => 'Prueba correcta';

  @override
  String subscriptionTestLatency(int latency) {
    return 'Prueba correcta • $latency ms';
  }

  @override
  String get subscriptionTestFailed => 'Falló';

  @override
  String get subscriptionTestAction => 'Probar';

  @override
  String get subscriptionIncomplete => 'Configuración incompleta';

  @override
  String get connectionInvalidConfiguration =>
      'Faltan los ajustes de esta suscripción o no son válidos.';

  @override
  String get connectionCheckServerOrPlaylist =>
      'Comprueba la URL del servidor o de la lista.';

  @override
  String get connectionCheckCredentials =>
      'Comprueba también el usuario y la contraseña.';

  @override
  String get connectionCertificateExpired => 'Certificado SSL caducado';

  @override
  String get connectionSslError => 'Error SSL/TLS';

  @override
  String get connectionCertificateExpiredHelp =>
      'El certificado de seguridad del servidor ha caducado.';

  @override
  String get connectionSslHelp =>
      'No se pudo establecer una conexión segura con el servidor.';

  @override
  String get connectionCheckDateTime =>
      'Comprueba la fecha y la hora del dispositivo.';

  @override
  String get connectionContactProvider =>
      'Contacta con tu proveedor si el problema continúa.';

  @override
  String get connectionDnsFailure => 'Servidor no encontrado (DNS)';

  @override
  String get connectionDnsFailureHelp =>
      'No se encuentra el servidor. Comprueba su dirección y tu conexión a Internet.';

  @override
  String get connectionNetworkUnavailable => 'Red inaccesible';

  @override
  String get connectionNetworkUnavailableHelp =>
      'No se puede acceder a la red del servidor. Comprueba tu conexión a Internet.';

  @override
  String get connectionServerError => 'Servidor temporalmente no disponible';

  @override
  String get connectionServerUnreachable => 'Servidor inaccesible';

  @override
  String get connectionServerUnreachableHelp =>
      'No se puede acceder al servidor. Comprueba la dirección y tu conexión a Internet.';

  @override
  String get connectionCheckUrl => 'Comprueba que la URL esté bien escrita.';

  @override
  String get connectionTryAnotherNetwork => 'Prueba con otra red.';

  @override
  String get connectionContactUnreachableProvider =>
      'Contacta con tu proveedor si el servidor sigue inaccesible.';

  @override
  String get connectionTimeout => 'Tiempo de espera agotado';

  @override
  String get connectionTimeoutHelp =>
      'El servidor no respondió a tiempo. Puede estar lento o temporalmente saturado.';

  @override
  String get connectionTryLater => 'Vuelve a intentarlo en unos minutos.';

  @override
  String get connectionCheckInternet => 'Comprueba tu conexión a Internet.';

  @override
  String get connectionInvalidCredentials => 'Credenciales no válidas';

  @override
  String get connectionAccessDenied => 'Acceso denegado';

  @override
  String get connectionXtreamRejected =>
      'El servidor ha rechazado el usuario o la contraseña de Xtream.';

  @override
  String get connectionM3uAuthorization =>
      'La lista M3U requiere autorización o una URL válida.';

  @override
  String get connectionCheckCredentialsCase =>
      'Comprueba el usuario y la contraseña, incluidas las mayúsculas.';

  @override
  String get connectionConfirmCredentials =>
      'Pide a tu proveedor que confirme los datos de acceso.';

  @override
  String get connectionAccountUnavailable =>
      'Suscripción o cuenta no disponible';

  @override
  String get connectionAccountUnavailableHelp =>
      'La cuenta puede haber caducado, estar desactivada o haber alcanzado el límite de conexiones.';

  @override
  String get connectionCheckSubscription =>
      'Comprueba el estado de la suscripción con tu proveedor.';

  @override
  String get connectionCloseOtherDevices =>
      'Cierra las conexiones en otros dispositivos y vuelve a intentarlo.';

  @override
  String get connectionForbidden => 'Acceso prohibido';

  @override
  String get connectionForbiddenHelp =>
      'El servidor rechaza la conexión. La cuenta o la dirección IP pueden estar bloqueadas.';

  @override
  String get connectionCheckActiveSubscription =>
      'Comprueba que la suscripción siga activa.';

  @override
  String get connectionCheckProviderAccess =>
      'Contacta con tu proveedor para comprobar el acceso.';

  @override
  String get connectionNotFound => 'Dirección no encontrada (404)';

  @override
  String get connectionInvalidRequest => 'Solicitud no válida';

  @override
  String get connectionInvalidAddress =>
      'La dirección del servidor o el punto de acceso parecen incorrectos.';

  @override
  String get connectionCheckBaseUrl =>
      'Comprueba la URL base del servidor o la URL M3U.';

  @override
  String get connectionUseXtreamPanel =>
      'Usa la dirección del panel Xtream sin añadir player_api.php.';

  @override
  String connectionServerUnavailable(int status) {
    return 'Servidor temporalmente no disponible ($status)';
  }

  @override
  String get connectionServerProblem =>
      'El servidor del proveedor tiene un problema.';

  @override
  String get connectionInvalidPlaylist => 'Lista M3U no válida o vacía';

  @override
  String get connectionInvalidPlaylistHelp =>
      'La lista no contiene datos legibles en el formato esperado.';

  @override
  String get connectionCheckPlaylistUrl =>
      'Comprueba que la URL apunte a una lista M3U actualizada.';

  @override
  String get connectionRequestNewUrl => 'Pide una nueva URL a tu proveedor.';

  @override
  String get connectionTestFailed => 'Error de prueba de conexión';

  @override
  String get connectionUnexpectedError =>
      'Un error inesperado impidió conectar con esta suscripción.';

  @override
  String get connectionCheckSubscriptionAndInternet =>
      'Comprueba los datos de la suscripción y tu conexión a Internet.';

  @override
  String get connectionRetryOrContact =>
      'Vuelve a intentarlo o contacta con tu proveedor si el problema continúa.';

  @override
  String get connectionThingsToCheck => 'Qué comprobar';

  @override
  String get connectionTechnicalDetails => 'Detalles técnicos';

  @override
  String subscriptionSemantic(String name) {
    return 'Suscripción $name';
  }

  @override
  String get subscriptionSemanticActive => 'activa';

  @override
  String get subscriptionSemanticDuplicate => 'posible duplicado';

  @override
  String get subscriptionAdded => 'Suscripción añadida';

  @override
  String subscriptionAddedHelp(String name) {
    return '«$name» se ha guardado. Puedes probar la conexión y después activar la suscripción.';
  }

  @override
  String get subscriptionTestRunning => 'Probando conexión…';

  @override
  String get subscriptionTestSuccess => 'Prueba de conexión correcta.';

  @override
  String get subscriptionTestUnavailable =>
      'El resultado de la prueba no está disponible.';

  @override
  String get subscriptionTestError =>
      'No se pudo completar la prueba de conexión.';

  @override
  String get subscriptionEditTitle => 'Editar suscripción';

  @override
  String get subscriptionNewTitle => 'Nueva suscripción';

  @override
  String get subscriptionName => 'Nombre de la suscripción';

  @override
  String get subscriptionUsername => 'Nombre de usuario';

  @override
  String get subscriptionPassword => 'Contraseña';

  @override
  String get subscriptionShowPassword => 'Mostrar contraseña';

  @override
  String get subscriptionHidePassword => 'Ocultar contraseña';

  @override
  String get subscriptionAdd => 'Añadir';

  @override
  String get playerExternalOpened =>
      'Reproducción abierta en un reproductor externo';

  @override
  String get playerExternalTrackHelp =>
      'Elige las pistas de audio y los subtítulos en el reproductor externo: las preferencias de Orbit no se transfieren.';

  @override
  String get playerProviderBlocked =>
      'Transmisión bloqueada temporalmente por el proveedor';

  @override
  String get playerStreamNotStarting =>
      'La transmisión se recibe, pero la reproducción no comienza. Es posible que la pista sea demasiado exigente para este dispositivo.';

  @override
  String get playerStreamFrozen =>
      'La transmisión se recibe, pero la reproducción está congelada.';

  @override
  String get playerStreamRecovering =>
      'La transmisión ha dejado de avanzar. Intentando recuperarla…';

  @override
  String playerCooldown(int seconds) {
    return 'Servidor protegido (anti-leech), nuevo intento en ${seconds}s';
  }

  @override
  String get playerProviderBlockedHelp =>
      'La protección anti-leech del servidor ha detenido la reproducción. Espera de 3 a 5 minutos sin reproducir y vuelve a iniciar este canal sin cambiar de canal.';

  @override
  String get playerLiveUnavailable => 'Transmisión no disponible';

  @override
  String get playerLiveUnavailableHelp =>
      'No se puede iniciar este canal. Comprueba tu suscripción o inténtalo de nuevo.';

  @override
  String playerNextEpisode(String title) {
    return 'Siguiente episodio: $title';
  }

  @override
  String playerNextEpisodeCountdown(String title, int seconds) {
    return 'Siguiente episodio: $title ($seconds s)';
  }

  @override
  String get profileSelectToContinue => 'Selecciona un perfil para continuar';

  @override
  String get profileCreateToWatch =>
      'Crea tu primer perfil para empezar a ver contenido.';

  @override
  String get profileNavigationHelp =>
      'Flechas + OK para navegar · Toca una tarjeta para seleccionar';

  @override
  String get profileActive => 'Activo';

  @override
  String get resumeAction => 'Continuar';

  @override
  String get refreshRecommendations => 'Actualizar recomendaciones';

  @override
  String get localVideoProxy => 'Proxy de vídeo local experimental';

  @override
  String get localVideoProxySubtitle =>
      'Para películas y series en el reproductor interno, con caché de disco limitado.';

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
  String get accountPreferencesSubtitle => 'Idioma, PIN';

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
  String get deleteDownload => 'Eliminar';

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
    return 'Última sincronización (esta instalación): $time';
  }

  @override
  String get cloudSyncNow => 'Sincronizar ahora';

  @override
  String get cloudSyncNowSubtitle =>
      'Sincroniza favoritos, historial y progreso de reproducción de esta instalación';

  @override
  String get cloudSyncSubtitleOff =>
      'Sincroniza favoritos, episodios vistos, recientes y progreso de reproducción de esta instalación';

  @override
  String get cloudflareReset => 'Restablecer sesión de Cloudflare';

  @override
  String get cloudflareResetSubtitle =>
      'Renueva la sesión activa de Cloudflare.';

  @override
  String get cloudflareNoActiveSession =>
      'No hay ninguna sesión activa de Cloudflare para renovar.';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get settingsContact => 'Contacto';

  @override
  String get settingsActivateApp => 'Activar aplicación';

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
  String get dataAlreadyFresh => 'Datos ya actualizados (menos de 8 horas)';

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
  String downloadAdded(String title) {
    return '«$title» añadido a las descargas';
  }

  @override
  String get downloadCompleted => 'Descargado';

  @override
  String get downloadInProgress => 'Descarga en curso';

  @override
  String get downloadOffline => 'Descargar para usar sin conexión';

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
  String get noneOption => 'Ninguno';

  @override
  String get play => 'Reproducir';

  @override
  String get newAnd4K => 'Películas a la carta';

  @override
  String get seasonsAndEpisodes => 'Series a la carta';

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
  String get historyLoading => 'Cargando historial…';

  @override
  String get historyEmptyHint =>
      'Tus reproducciones recientes aparecerán aquí.';

  @override
  String get refreshAction => 'Actualizar';

  @override
  String get favoritesAdd => 'Añadir a favoritos';

  @override
  String get favoritesRemove => 'Quitar de favoritos';

  @override
  String get favoritesNeedScope =>
      'Se necesitan un perfil y una suscripción activos.';

  @override
  String get favoritesReplayHint =>
      'Pulsa el corazón de una repetición para encontrarla aquí.';

  @override
  String favoritesClearPrompt(int total) {
    return '¿Quitar los $total favoritos guardados? Se vaciará la lista de favoritos.';
  }

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
  String get pinCode => 'Código PIN';

  @override
  String get pinRequired => 'Se requiere un PIN';

  @override
  String get pinSet => 'Crear un PIN';

  @override
  String get pinThisProfile => 'este perfil';

  @override
  String pinEnterForProfile(String name) {
    return 'Introduce el PIN de $name';
  }

  @override
  String get pinConfirmFourDigits => 'Confirma tu código de 4 dígitos';

  @override
  String get pinChooseFourDigits => 'Elige un código de 4 dígitos';

  @override
  String get pinVerifyFailed => 'No se pudo verificar el PIN.';

  @override
  String get pinConfirmInstruction =>
      'Después de 4 dígitos, pulsa ✓ para confirmar.';

  @override
  String pinIncorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count intentos',
      one: 'queda 1 intento',
    );
    return 'Código incorrecto — $_temp0. Tras 3 errores, el acceso se bloquea durante 2 horas.';
  }

  @override
  String pinTemporarilyLocked(int minutes) {
    return 'Demasiados PIN incorrectos. Inténtalo de nuevo en $minutes min.';
  }

  @override
  String get pinChecking => 'Comprobando…';

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
      'Se borrarán los historiales locales de reproducción y búsqueda. Se conservarán los perfiles, suscripciones, datos de API, ajustes de TLS y de reproducción, Cloudflare y los demás ajustes. Esta acción no se puede deshacer.';

  @override
  String get resetAppDialogConfirm => 'Restablecer';

  @override
  String get resetAppDialogTitle => '¿Restablecer la aplicación?';

  @override
  String get resetAppSubtitle =>
      'Borra el historial local y conserva los perfiles y la configuración';

  @override
  String get resetFailed => 'Restablecimiento incompleto. Inténtalo de nuevo.';

  @override
  String get resetCompleted => 'Restablecimiento completado';

  @override
  String get resumePlayback => '¿Reanudar la reproducción?';

  @override
  String get retry => 'Reintentar';

  @override
  String get tmdbMovieRecommendations => 'Recomendaciones de TMDB';

  @override
  String get tmdbRecommendationsEmpty =>
      'No hay recomendaciones de TMDB para esta película.';

  @override
  String get tmdbRecommendationsError =>
      'No se pudieron cargar las recomendaciones de TMDB.';

  @override
  String get tmdbRecommendationsUnavailable =>
      'Las recomendaciones de TMDB no están disponibles para esta película.';

  @override
  String get playbackDelayedTitle => 'La reproducción tarda demasiado';

  @override
  String get playbackDelayedMessage =>
      'La reproducción no comienza ni se reanuda. La causa puede ser el contenido, la conexión o el formato de vídeo.';

  @override
  String get playbackContinueWaiting => 'Seguir esperando';

  @override
  String get playbackUnavailableTitle => 'Reproducción no disponible';

  @override
  String get playbackUnavailableMessage =>
      'No se puede reproducir esta película o episodio ahora. Reinténtalo o comprueba la conexión y el formato del archivo.';

  @override
  String get protectedPlaybackUnsupportedMessage =>
      'El reproductor integrado no puede reproducir de forma segura este flujo DASH o retransmitido con cabeceras protegidas.';

  @override
  String get greenScreenDetectedTitle => 'Problema de imagen detectado';

  @override
  String get externalPlayerLimitationsTitle =>
      'Limitaciones de reproductores externos';

  @override
  String get externalPlayerLimitationsDescription =>
      'Orbit no transmite las preferencias de audio y subtítulos a VLC ni a MX Player: selecciona las pistas en el reproductor externo. En series, el siguiente episodio solo se inicia automáticamente si MX Player confirma el final; de lo contrario, inícialo manualmente al volver a Orbit. Esto también se aplica al reproductor alternativo.';

  @override
  String get actorShowFilmography => 'Ver filmografía';

  @override
  String get actorFilmographyUnavailable => 'Filmografía no disponible.';

  @override
  String get actorCreditFilm => 'Película';

  @override
  String get actorCreditSeries => 'Serie';

  @override
  String actorCreditRole(String role) {
    return 'Papel: $role';
  }

  @override
  String get actorCreditTmdbUnavailable => 'Detalles de TMDB no disponibles.';

  @override
  String get actorCreditSynopsisUnavailable => 'Sinopsis no disponible.';

  @override
  String get actorCreditCatalogUnconfirmed =>
      'No hay coincidencia confirmada en el catálogo.';

  @override
  String get actorCreditOpenCatalog => 'Ver en el catálogo';

  @override
  String get greenScreenDetectedMessage =>
      'Se detectó un problema de imagen (pantalla verde). Es posible que el reproductor actual no pueda decodificar este flujo correctamente. Prueba otro reproductor en Ajustes > Reproductor > Motores de reproducción y vuelve a iniciar la reproducción.';

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
  String get seriesMissingId =>
      'Falta el identificador de la serie (navegación incorrecta). Vuelve a la lista y vuelve a intentarlo.';

  @override
  String get seriesEnriching => 'Enriqueciendo metadatos…';

  @override
  String get seriesLoading => 'Cargando serie…';

  @override
  String get seriesNoEpisodesHint => 'Esta serie aún no tiene episodios.';

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
  String get snackCloudflareReset => 'Sesión de Cloudflare renovada';

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
  String get tmdbKeyValid => 'La clave de TMDB es válida';

  @override
  String get tmdbKeyValidationFailed =>
      'TMDB ha rechazado la clave o la red no está disponible: comprueba la clave';

  @override
  String get tvChannels => 'Canales TV';

  @override
  String get unableToBuildReplayUrl =>
      'No se pudo construir la URL del replay.';

  @override
  String get unlockCloudflare => 'Desbloquear (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'Se requiere verificar el proveedor';

  @override
  String get cloudflareChallengeHelp =>
      'El proveedor solicita una comprobación de Cloudflare. Complétela en esta ventana, ciérrela y vuelva a intentarlo. Las cookies de esta página no se envían al reproductor, por lo que la reproducción podría seguir bloqueada.';

  @override
  String get openProviderWebsite => 'Abrir el sitio web del proveedor';

  @override
  String get providerWebsiteUnavailable =>
      'No se pudo abrir el sitio web del proveedor. Compruebe la dirección de la suscripción e inténtelo de nuevo.';

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
  String get seriesDefaultAudioLanguage => 'Idioma de audio predeterminado';

  @override
  String get seriesDefaultSubtitleLanguage =>
      'Idioma de subtítulos predeterminado';

  @override
  String get seriesSelectLanguage => 'Seleccionar un idioma';

  @override
  String get seriesStreamDefault => '(Predeterminado de la transmisión)';

  @override
  String get seriesChooseLanguageFirst => 'Elige primero un idioma';

  @override
  String get seriesDefaultAllEpisodes =>
      'Usar el valor de la transmisión para todos los episodios';

  @override
  String get seriesDefaultUnlessEpisodeChoice =>
      'Usar el valor de la transmisión salvo elección por episodio';

  @override
  String get seriesForceLanguageAllEpisodes =>
      'Forzar este idioma en todos los episodios';

  @override
  String get seriesApplyIfAvailable => 'Aplicar si está disponible';

  @override
  String get seriesSearchingAudio => 'Buscando pistas de audio…';

  @override
  String get seriesSubtitlesDisabled => '(Desactivados)';

  @override
  String get seriesDisableSubtitlesAll =>
      'Desactivar subtítulos en todos los episodios';

  @override
  String get seriesDisableSubtitlesDefault =>
      'Desactivar subtítulos de forma predeterminada';

  @override
  String get seriesSearchingSubtitles => 'Buscando pistas de subtítulos…';

  @override
  String get seriesNoSubtitleTracks =>
      'No se detectaron pistas: elige un idioma y se usará si está disponible.';

  @override
  String get seriesLanguageFrench => 'Francés';

  @override
  String get seriesLanguageEnglish => 'Inglés';

  @override
  String get seriesLanguageSpanish => 'Español';

  @override
  String get seriesLanguageGerman => 'Alemán';

  @override
  String get seriesLanguageItalian => 'Italiano';

  @override
  String get seriesLanguageArabic => 'Árabe';

  @override
  String get subtitleEmbeddedSection => 'Subtítulos integrados';

  @override
  String get subtitleForcedLabel => 'Forzado';

  @override
  String get subtitleEmbeddedLabel => 'Integrado';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'Vídeo';

  @override
  String get autoQuality => 'Automático';

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
  String get removeChannel => 'Quitar canal';

  @override
  String get avatarCategoryAll => 'Todas';

  @override
  String get avatarCategoryCharacters => 'Personajes';

  @override
  String get avatarCategorySuperheroes => 'Superhéroes';

  @override
  String get avatarCategoryAnimals => 'Animales';

  @override
  String get avatarCategoryFlowers => 'Flores';

  @override
  String get avatarCategoryNature => 'Naturaleza';

  @override
  String get avatarCategoryYouth => 'Infantil';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Negro y Blanco';

  @override
  String get updateTitle => 'Actualizaciones';

  @override
  String get updateSettingsSubtitle =>
      'Buscar la última versión oficial en GitHub';

  @override
  String get updateChecking => 'Buscando actualizaciones…';

  @override
  String get updateCurrent => 'Ya tienes la última versión disponible.';

  @override
  String get updateAvailable => 'Hay una nueva versión disponible:';

  @override
  String get updateDownloading => 'Descargando y verificando el APK…';

  @override
  String get updateReady => 'Abriendo el instalador de Android…';

  @override
  String get updatePermission =>
      'Permite que Orbit instale aplicaciones desconocidas en los ajustes de Android, vuelve aquí e inténtalo de nuevo.';

  @override
  String get updateNoRelease =>
      'No hay ninguna versión estable disponible en GitHub.';

  @override
  String get updateAssetError =>
      'La versión no contiene el APK universal oficial o sus datos de verificación.';

  @override
  String get updateInvalidApk =>
      'El APK es incompatible, está firmado con otra clave o no tiene una versión Android superior. Instalación cancelada.';

  @override
  String get updateIntegrityError =>
      'Falló la verificación del archivo descargado. Instalación cancelada.';

  @override
  String get updateGenericError =>
      'La actualización falló. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateInstall => 'Actualizar';

  @override
  String get updateRetryInstall => 'Reintentar instalación';

  @override
  String get updateRetry => 'Reintentar';

  @override
  String get avatarCategoryPixels => 'Pixels';

  @override
  String get unassignedLegacyLibraryItems =>
      'Algunos favoritos o descargas antiguos no se muestran porque se desconoce su suscripción original. Se conservan.';

  @override
  String get forceNoSubtitlesSubtitle =>
      'Desactiva automáticamente los subtítulos al iniciar una película o serie';

  @override
  String get backTooltip => 'Volver';

  @override
  String get categoryFilters => 'Filtros de categorías';

  @override
  String get categoryFiltersSubtitle => 'Categorías ocultas por suscripción';

  @override
  String get memoryCacheTitle => 'Gestión de memoria y caché';

  @override
  String get memoryCacheSubtitle =>
      'Libera espacio y limpia los datos locales.';

  @override
  String get clearWatchHistoryTitle => 'Borrar el historial de reproducción';

  @override
  String get clearWatchHistorySubtitle =>
      'Borra la lista de vistos recientemente y las posiciones de reanudación.';

  @override
  String get clearWatchHistoryAction => 'Borrar';

  @override
  String get clearCoverCacheTitle => 'Limpiar la caché de carátulas';

  @override
  String get clearCoverCacheSubtitle =>
      'Libera el espacio en disco ocupado por las miniaturas VOD/EPG almacenadas localmente.';

  @override
  String get clearCoverCacheAction => 'Purgar';

  @override
  String get enginesDescription =>
      'Elija el motor usado para cada tipo de contenido y el motor de respaldo cuando la reproducción falle.';

  @override
  String get sortAdvancedTitle => 'Opciones de ordenación avanzadas';

  @override
  String get sortAdvancedSubtitle => 'Seleccione un modo con el mando:';

  @override
  String get sortDescRecentlyAdded =>
      'Contenidos añadidos recientemente a la lista';

  @override
  String get sortDescResumePriority =>
      'Coloca arriba los contenidos empezados sin terminar';

  @override
  String get sortDescByRating => 'Clasificación según las notas asignadas';

  @override
  String get sortDescByYear => 'Orden cronológico por año de producción';

  @override
  String get sortDescByDuration => 'Ordenación por duración del contenido';

  @override
  String get sortOptionActive => 'Activo';

  @override
  String get showAll => 'Mostrar todo';

  @override
  String get noActiveSubscription => 'Ninguna suscripción activa';

  @override
  String get noVodCategories => 'Ninguna categoría de películas en este panel.';

  @override
  String get noSeriesCategories => 'Ninguna categoría de series en este panel.';

  @override
  String get neverScanned => 'Nunca analizado';

  @override
  String get scannedToday => 'Analizado hoy';

  @override
  String get scannedYesterday => 'Analizado ayer';

  @override
  String scannedDaysAgo(int days) {
    return 'Analizado hace $days días';
  }

  @override
  String subscriptionSettingsNote(String scanned) {
    return 'Ajustes propios de esta suscripción — $scanned';
  }

  @override
  String get rescanCategories => 'Reanalizar las categorías';

  @override
  String get scanningCategories => 'Análisis…';
}
